import Flutter
import Foundation

/// Singleton owner of the Object Capture / Photogrammetry sessions.
///
/// The current implementation is a placeholder: it acknowledges incoming
/// channel calls and rejects them with `FlutterError(code: "not_implemented")`
/// while the native pipeline is being implemented in subsequent commits.
final class ObjectCaptureController: NSObject, FlutterStreamHandler {
  static let shared = ObjectCaptureController()

  /// Method channel used for one-shot calls. Set by
  /// `SwiftFlutterObjectCapturePlugin.register(with:)`.
  weak var methodChannel: FlutterMethodChannel?

  /// Sink delivered by Flutter when the Dart side subscribes to the event
  /// channel. Future progress events will be emitted through this sink.
  private var eventSink: FlutterEventSink?

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
  ///
  /// TODO: wire `ObjectCaptureSession` (iOS 17+), expose progress through
  /// `eventSink`, and return the captured photo folder via `result`.
  func startCapture(arguments: [String: Any]?, result: @escaping FlutterResult) {
    result(
      FlutterError(
        code: "not_implemented",
        message:
          "captureObject is not implemented yet. The Dart API is scaffolded; "
          + "the iOS pipeline (ObjectCaptureSession) will land in a follow-up release.",
        details: nil))
  }

  /// Runs photogrammetry over a folder of images.
  ///
  /// TODO: wire `PhotogrammetrySession`, drive a `Request` for the requested
  /// detail level, and return the resulting USDZ file path via `result`.
  func reconstruct(arguments: [String: Any]?, result: @escaping FlutterResult) {
    result(
      FlutterError(
        code: "not_implemented",
        message:
          "reconstruct is not implemented yet. The Dart API is scaffolded; "
          + "the iOS pipeline (PhotogrammetrySession) will land in a follow-up release.",
        details: nil))
  }
}
