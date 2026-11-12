import Foundation
#if os(iOS)
import Flutter
import UIKit
#elseif os(macOS)
import FlutterMacOS
#endif
#if canImport(RealityKit)
import RealityKit
import SwiftUI
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

  #if os(iOS) && canImport(RealityKit)
  private let captureCoordinator = ObjectCaptureCoordinator()
  #endif

  var isSupported: Bool {
    #if canImport(RealityKit)
    // `isSupported` exists from macOS 13; macOS 12 reports unsupported.
    if #available(macOS 13.0, *) { return PhotogrammetrySession.isSupported }
    return false
    #else
    return false
    #endif
  }

  func getLimits() -> [String: Any]? {
    #if canImport(RealityKit)
    guard #available(macOS 14.0, *) else { return nil }
    let limits = PhotogrammetrySession.limits
    return [
      "maxImages": limits.maximumNumberOfInputImages,
      "maxImageDimension": limits.maximumInputImageDimension,
    ]
    #else
    return nil
    #endif
  }

  var isGuidedCaptureSupported: Bool {
    #if os(iOS) && canImport(RealityKit)
    return MainActor.assumeIsolated { ObjectCaptureSession.isSupported }
    #else
    return false
    #endif
  }

  /// Presents the guided capture UI and resolves `result` once with the captured folder.
  @MainActor
  func captureImages(arguments: Any?, result: @escaping FlutterResult) {
    #if os(iOS) && canImport(RealityKit)
    guard ObjectCaptureSession.isSupported else {
      return result(Self.flutterError(ObjectCaptureErrorMapper.notSupported))
    }
    guard !captureCoordinator.isActive else {
      return result(Self.flutterError(ObjectCaptureErrorMapper.captureInProgress))
    }
    guard let args = arguments as? [String: Any],
      let imagesPath = args["imagesDirectory"] as? String,
      let isOverCaptureEnabled = args["isOverCaptureEnabled"] as? Bool,
      let areaMode = args["areaMode"] as? Bool
    else {
      return result(
        FlutterError(
          code: "invalid_arguments",
          message: "imagesDirectory, isOverCaptureEnabled and areaMode are required.",
          details: nil))
    }
    guard let presenter = Self.topViewController() else {
      return result(
        FlutterError(
          code: "capture_failed", message: "No view controller to present the capture UI.",
          details: nil))
    }
    let imagesDirectory = URL(fileURLWithPath: imagesPath, isDirectory: true)
    let checkpointPath = args["checkpointDirectory"] as? String
    let checkpointDirectory = checkpointPath.map { URL(fileURLWithPath: $0, isDirectory: true) }
    do {
      try FileManager.default.createDirectory(
        at: imagesDirectory, withIntermediateDirectories: true)
      if let checkpointDirectory {
        try FileManager.default.createDirectory(
          at: checkpointDirectory, withIntermediateDirectories: true)
      }
    } catch {
      return result(Self.flutterError(ObjectCaptureErrorMapper.mapCapture(error)))
    }

    captureCoordinator.begin(
      imagesDirectory: imagesDirectory,
      checkpointDirectory: checkpointDirectory,
      isOverCaptureEnabled: isOverCaptureEnabled,
      areaMode: areaMode,
      presenter: presenter
    ) { outcome in
      switch outcome {
      case .completed(let imageCount):
        var payload: [String: Any] = [
          "imagesDirectory": imagesDirectory.path, "imageCount": imageCount,
        ]
        if let checkpointDirectory { payload["checkpointDirectory"] = checkpointDirectory.path }
        result(payload)
      case .failed(let error):
        result(Self.flutterError(ObjectCaptureErrorMapper.mapCapture(error)))
      }
    }
    #else
    result(Self.flutterError(ObjectCaptureErrorMapper.notSupported))
    #endif
  }

  #if os(iOS)
  private static func topViewController() -> UIViewController? {
    guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
      let window = scene.windows.first(where: { $0.isKeyWindow })
    else { return nil }
    var top = window.rootViewController
    while let presented = top?.presentedViewController { top = presented }
    return top
  }
  #endif

  func startReconstruction(arguments: Any?, result: @escaping FlutterResult) {
    #if canImport(RealityKit)
    guard isSupported else {
      return result(Self.flutterError(ObjectCaptureErrorMapper.notSupported))
    }
    guard session == nil else {
      return result(Self.flutterError(ObjectCaptureErrorMapper.sessionInProgress))
    }
    guard let args = arguments as? [String: Any],
      let imagesDirectory = args["imagesDirectory"] as? String,
      let outputPath = args["outputPath"] as? String,
      let featureSensitivity = args["featureSensitivity"] as? String,
      let sampleOrdering = args["sampleOrdering"] as? String,
      let detailName = args["detail"] as? String,
      let outputFormat = args["outputFormat"] as? String
    else {
      return result(
        FlutterError(
          code: "invalid_arguments",
          message:
            "imagesDirectory, outputPath, featureSensitivity, sampleOrdering, detail and outputFormat are required.",
          details: nil))
    }

    guard let detail = Self.detail(named: detailName) else {
      return result(Self.flutterError(ObjectCaptureErrorMapper.unsupportedDetail(detailName)))
    }
    let isObjDirectory = outputFormat == "objDirectory"
    #if os(iOS)
    if isObjDirectory {
      return result(Self.flutterError(ObjectCaptureErrorMapper.unsupportedOutputFormat))
    }
    #endif
    let outputURL = URL(fileURLWithPath: outputPath, isDirectory: isObjDirectory)
    if isObjDirectory {
      do {
        try FileManager.default.createDirectory(at: outputURL, withIntermediateDirectories: true)
      } catch {
        return result(Self.flutterError(ObjectCaptureErrorMapper.map(error)))
      }
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
    Self.setIdleTimerDisabled(true)
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
      try newSession.process(requests: [.modelFile(url: outputURL, detail: detail)])
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
    Self.setIdleTimerDisabled(false)
  }

  /// iOS accepts only `reduced`; macOS accepts every level. Nil = unsupported here.
  private static func detail(named name: String) -> PhotogrammetrySession.Request.Detail? {
    if name == "reduced" { return .reduced }
    #if os(macOS)
    switch name {
    case "preview": return .preview
    case "medium": return .medium
    case "full": return .full
    case "raw": return .raw
    default: return nil
    }
    #else
    return nil
    #endif
  }

  private static func setIdleTimerDisabled(_ disabled: Bool) {
    #if os(iOS)
    UIApplication.shared.isIdleTimerDisabled = disabled
    #endif
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
