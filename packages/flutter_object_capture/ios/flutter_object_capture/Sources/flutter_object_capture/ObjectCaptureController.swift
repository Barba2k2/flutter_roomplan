import Flutter
import UIKit
#if canImport(RealityKit)
import RealityKit
#endif

/// Owns the reconstruction job (one at a time) and the event channel sink.
/// Main-thread confined: Flutter calls it on main and the output Task runs on `@MainActor`.
class ObjectCaptureController: NSObject, FlutterStreamHandler {
  private var eventSink: FlutterEventSink?

  #if canImport(RealityKit)
  // Strong ref until a terminal output; also the job-identity token for stale outputs.
  private var session: PhotogrammetrySession?
  private var outputTask: Task<Void, Never>?
  private var lastFraction = 0.0
  #endif

  var isSupported: Bool {
    #if canImport(RealityKit)
    return PhotogrammetrySession.isSupported
    #else
    return false
    #endif
  }

  func getLimits() -> [String: Any]? {
    #if canImport(RealityKit)
    let limits = PhotogrammetrySession.limits
    return [
      "maxImages": limits.maximumNumberOfInputImages,
      "maxImageDimension": limits.maximumInputImageDimension,
    ]
    #else
    return nil
    #endif
  }

  func startReconstruction(arguments: Any?, result: @escaping FlutterResult) {
    #if canImport(RealityKit)
    guard PhotogrammetrySession.isSupported else {
      return result(Self.flutterError(ObjectCaptureErrorMapper.notSupported))
    }
    guard session == nil else {
      return result(Self.flutterError(ObjectCaptureErrorMapper.sessionInProgress))
    }
    guard let args = arguments as? [String: Any],
      let imagesDirectory = args["imagesDirectory"] as? String,
      let outputPath = args["outputPath"] as? String,
      let featureSensitivity = args["featureSensitivity"] as? String,
      let sampleOrdering = args["sampleOrdering"] as? String
    else {
      return result(
        FlutterError(
          code: "invalid_arguments",
          message: "imagesDirectory, outputPath, featureSensitivity and sampleOrdering are required.",
          details: nil))
    }

    var configuration = PhotogrammetrySession.Configuration()
    configuration.featureSensitivity = featureSensitivity == "high" ? .high : .normal
    configuration.sampleOrdering = sampleOrdering == "sequential" ? .sequential : .unordered

    let newSession: PhotogrammetrySession
    do {
      newSession = try PhotogrammetrySession(
        input: URL(fileURLWithPath: imagesDirectory, isDirectory: true),
        configuration: configuration)
    } catch {
      return result(Self.flutterError(ObjectCaptureErrorMapper.map(error)))
    }

    session = newSession
    lastFraction = 0
    UIApplication.shared.isIdleTimerDisabled = true
    outputTask = Task { @MainActor [weak self] in
      do {
        for try await output in newSession.outputs {
          guard let self, self.session === newSession else { return }
          self.handle(output)
        }
      } catch {
        guard let self, self.session === newSession else { return }
        self.fail(error)
      }
    }

    do {
      try newSession.process(requests: [.modelFile(url: URL(fileURLWithPath: outputPath), detail: .reduced)])
      result(nil)
    } catch {
      endJob()
      result(Self.flutterError(ObjectCaptureErrorMapper.map(error)))
    }
    #else
    result(Self.flutterError(ObjectCaptureErrorMapper.notSupported))
    #endif
  }

  func cancelReconstruction(result: @escaping FlutterResult) {
    #if canImport(RealityKit)
    if let session {
      session.cancel()
      endJob()
      emitError(ObjectCaptureErrorMapper.cancelled)
    }
    #endif
    result(nil)
  }

  // MARK: - FlutterStreamHandler

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink)
    -> FlutterError?
  {
    eventSink = events
    return nil
  }

  /// Listener gone: stop the job silently (nobody is left to receive the `cancelled` event).
  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    #if canImport(RealityKit)
    session?.cancel()
    endJob()
    #endif
    return nil
  }

  // MARK: - Job lifecycle

  #if canImport(RealityKit)
  private func handle(_ output: PhotogrammetrySession.Output) {
    switch output {
    case .processingComplete:
      // Reaching this with the job still open means no model was produced.
      fail(ObjectCaptureProcessingError.noModelProduced)
    case .processingCancelled:
      endJob()
      emitError(ObjectCaptureErrorMapper.cancelled)
    case .requestError(_, let error):
      fail(error)
    default:
      do {
        guard let payload = try ObjectCaptureOutputConverter.payload(for: output, lastFraction: lastFraction)
        else { return }
        if payload["type"] as? String == "progress", let fraction = payload["fraction"] as? Double {
          lastFraction = fraction
        }
        let isTerminal = payload["type"] as? String == "completed"
        eventSink?(payload)
        if isTerminal { endJob() }
      } catch {
        fail(error)
      }
    }
  }

  private func fail(_ error: Error) {
    endJob()
    emitError(ObjectCaptureErrorMapper.map(error))
  }

  private func endJob() {
    outputTask?.cancel()
    outputTask = nil
    session = nil
    // ponytail: the plan marks the need for this UNVERIFIED; harmless, keeps the screen awake during a long job.
    UIApplication.shared.isIdleTimerDisabled = false
  }
  #endif

  private func emitError(_ mapped: ObjectCaptureErrorMapper.Mapped) {
    eventSink?(Self.flutterError(mapped))
  }

  private static func flutterError(_ mapped: ObjectCaptureErrorMapper.Mapped) -> FlutterError {
    FlutterError(code: mapped.code, message: mapped.message, details: mapped.details)
  }
}

#if canImport(RealityKit)
private enum ObjectCaptureProcessingError: LocalizedError {
  case noModelProduced
  var errorDescription: String? { "Processing finished without producing a model." }
}
#endif
