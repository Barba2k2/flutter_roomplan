import Flutter
import Foundation
import UIKit
import os.log
#if canImport(RealityKit)
import RealityKit
#endif

/// Central dispatcher for `flutter_object_capture`.
///
/// Owns the active `CaptureCoordinator` and `PhotogrammetryRunner`, the
/// Flutter event sink, and the bridge between Swift session state and the
/// Dart `CaptureEvent` payloads.
final class ObjectCaptureController: NSObject, FlutterStreamHandler {
  static let shared = ObjectCaptureController()

  /// Method channel set by the plugin's `register(with:)`. Held weakly to
  /// avoid extending the channel's lifetime past the plugin registrar.
  weak var methodChannel: FlutterMethodChannel?

  private var eventSink: FlutterEventSink?

  private let log = Logger(
    subsystem: "com.paintpro.flutter_object_capture",
    category: "ObjectCaptureController")

  // The coordinator and runner are only meaningful on iOS 17+. They are kept
  // as `Any?` here so this type itself does not need an availability bound;
  // the typed accessors below add the correct guards.
  private var _coordinator: Any?
  private var _runner: Any?

  @available(iOS 17.0, *)
  private var coordinator: CaptureCoordinator? {
    get { _coordinator as? CaptureCoordinator }
    set { _coordinator = newValue }
  }

  @available(iOS 17.0, *)
  private var runner: PhotogrammetryRunner? {
    get { _runner as? PhotogrammetryRunner }
    set { _runner = newValue }
  }

  private override init() {}

  // MARK: - FlutterStreamHandler

  func onListen(
    withArguments arguments: Any?,
    eventSink events: @escaping FlutterEventSink
  ) -> FlutterError? {
    eventSink = events
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    return nil
  }

  // MARK: - Capture

  /// Starts a guided object-capture session.
  func startCapture(arguments: [String: Any]?, result: @escaping FlutterResult) {
    guard #available(iOS 17.0, *) else {
      result(unsupportedError())
      return
    }

    guard ObjectCaptureSession.isSupported else {
      result(unsupportedError())
      return
    }

    if coordinator != nil {
      result(
        FlutterError(
          code: "session_busy",
          message: "An object capture session is already in progress.",
          details: nil))
      return
    }

    guard let presenter = topViewController() else {
      result(
        FlutterError(
          code: "no_presenter",
          message: "No view controller available to present the capture UI.",
          details: nil))
      return
    }

    let isOverCaptureEnabled = (arguments?["isOverCaptureEnabled"] as? Bool) ?? false
    let checkpointArg = arguments?["checkpointDirectory"] as? String

    let imagesURL = makeTempDirectory(name: "images")
    let checkpointURL =
      checkpointArg.map { URL(fileURLWithPath: $0) }
      ?? makeTempDirectory(name: "checkpoint")

    var configuration = ObjectCaptureSession.Configuration()
    configuration.isOverCaptureEnabled = isOverCaptureEnabled

    let startedAt = Date()

    let coordinator = CaptureCoordinator(
      imagesDirectory: imagesURL,
      checkpointDirectory: checkpointURL,
      configuration: configuration,
      onStateChange: { [weak self] state in
        self?.emit(state: state)
      },
      onCompletion: { [weak self] outcome in
        guard let self else { return }
        self.coordinator = nil
        switch outcome {
        case .success(let imagesDirectory):
          let payload: [String: Any] = [
            "imagesFolderPath": imagesDirectory.path,
            "captureCount": Self.countFiles(in: imagesDirectory),
            "startedAt": Self.iso8601(startedAt),
            "completedAt": Self.iso8601(Date()),
          ]
          result(payload)
        case .failure(let error):
          self.log.error(
            "Capture failed: \(String(describing: error), privacy: .public)")
          result(
            FlutterError(
              code: "capture_failed",
              message: error.localizedDescription,
              details: nil))
        }
      })

    do {
      try coordinator.start(presentingFrom: presenter)
      self.coordinator = coordinator
    } catch {
      log.error(
        "Failed to start capture: \(String(describing: error), privacy: .public)")
      result(
        FlutterError(
          code: "capture_start_failed",
          message: error.localizedDescription,
          details: nil))
    }
  }

  /// Runs photogrammetry over a folder of images.
  func reconstruct(arguments: [String: Any]?, result: @escaping FlutterResult) {
    guard #available(iOS 17.0, *) else {
      result(unsupportedError())
      return
    }

    if runner != nil {
      result(
        FlutterError(
          code: "session_busy",
          message: "A photogrammetry session is already in progress.",
          details: nil))
      return
    }

    guard let imagesPath = arguments?["imagesPath"] as? String else {
      result(
        FlutterError(
          code: "invalid_arguments",
          message: "imagesPath is required.",
          details: nil))
      return
    }

    let detailName = (arguments?["detailLevel"] as? String) ?? "medium"
    guard let detail = PhotogrammetryRunner.detail(from: detailName) else {
      result(
        FlutterError(
          code: "invalid_arguments",
          message: "Unknown detail level: \(detailName).",
          details: nil))
      return
    }

    let imagesURL = URL(fileURLWithPath: imagesPath)
    let outputURL: URL
    if let outputPath = arguments?["outputPath"] as? String {
      outputURL = URL(fileURLWithPath: outputPath)
    } else {
      outputURL = FileManager.default.temporaryDirectory
        .appendingPathComponent("\(UUID().uuidString).usdz")
    }

    let runner = PhotogrammetryRunner()
    self.runner = runner

    emit(stateName: "reconstructing", progress: 0, message: "Starting reconstruction")

    runner.run(
      inputURL: imagesURL,
      outputURL: outputURL,
      detail: detail,
      progressHandler: { [weak self] fraction in
        self?.emit(
          stateName: "reconstructing",
          progress: fraction,
          message: nil)
      },
      completion: { [weak self] outcome in
        guard let self else { return }
        self.runner = nil

        switch outcome {
        case .success(let duration):
          self.emit(stateName: "completed", progress: 1.0, message: nil)
          result([
            "modelPath": outputURL.path,
            "detailLevel": detailName,
            "processingTimeMs": Int(duration * 1000),
          ] as [String: Any])

        case .failure(let error):
          let cancelled =
            (error as? PhotogrammetryRunner.RunnerError) == .cancelled
            || error is CancellationError
          let payloadError =
            cancelled
            ? FlutterError(
              code: "cancelled",
              message: "Reconstruction cancelled.",
              details: nil)
            : FlutterError(
              code: "reconstruction_failed",
              message: error.localizedDescription,
              details: nil)
          self.emit(
            stateName: "failed",
            progress: nil,
            message: nil,
            error: error.localizedDescription)
          result(payloadError)
        }
      })
  }

  // MARK: - Helpers

  private func unsupportedError() -> FlutterError {
    FlutterError(
      code: "unsupported",
      message:
        "Object Capture requires iOS 17.0 or later on a device with an A14 Bionic chip or newer.",
      details: nil)
  }

  private func makeTempDirectory(name: String) -> URL {
    let url = FileManager.default.temporaryDirectory
      .appendingPathComponent("flutter_object_capture")
      .appendingPathComponent(UUID().uuidString)
      .appendingPathComponent(name, isDirectory: true)
    try? FileManager.default.createDirectory(
      at: url, withIntermediateDirectories: true)
    return url
  }

  private static func countFiles(in url: URL) -> Int {
    let contents =
      (try? FileManager.default.contentsOfDirectory(
        at: url,
        includingPropertiesForKeys: [.isDirectoryKey])) ?? []
    return contents.filter { item in
      let isDir = (try? item.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
      return !isDir
    }.count
  }

  private static let iso8601Formatter: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter
  }()

  private static func iso8601(_ date: Date) -> String {
    iso8601Formatter.string(from: date)
  }

  private func topViewController() -> UIViewController? {
    let scene =
      UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .first(where: { $0.activationState == .foregroundActive })
      ?? UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .first

    guard let window = scene?.windows.first(where: { $0.isKeyWindow }) ?? scene?.windows.first,
      var top = window.rootViewController
    else {
      return nil
    }

    while let presented = top.presentedViewController {
      top = presented
    }
    return top
  }

  // MARK: - Event emission

  @available(iOS 17.0, *)
  private func emit(state: ObjectCaptureSession.CaptureState) {
    switch state {
    case .initializing:
      emit(stateName: "initializing", progress: nil, message: nil)
    case .ready:
      emit(stateName: "ready", progress: nil, message: nil)
    case .detecting:
      emit(stateName: "detecting", progress: nil, message: nil)
    case .capturing:
      emit(stateName: "capturing", progress: nil, message: nil)
    case .finishing:
      emit(stateName: "finishing", progress: nil, message: nil)
    case .completed:
      emit(stateName: "completed", progress: 1.0, message: nil)
    case .failed(let error):
      emit(
        stateName: "failed",
        progress: nil,
        message: nil,
        error: error.localizedDescription)
    @unknown default:
      emit(stateName: "ready", progress: nil, message: nil)
    }
  }

  private func emit(
    stateName: String,
    progress: Double?,
    message: String?,
    error: String? = nil
  ) {
    var payload: [String: Any] = ["state": stateName]
    if let progress { payload["progress"] = progress }
    if let message { payload["message"] = message }
    if let error { payload["error"] = error }

    if Thread.isMainThread {
      eventSink?(payload)
    } else {
      DispatchQueue.main.async { [weak self] in
        self?.eventSink?(payload)
      }
    }
  }
}
