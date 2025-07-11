import ARKit
import AVFoundation
import Flutter
import Foundation
import RoomPlan
import os

/// A singleton class that manages the RoomPlan session and communication with Flutter.
///
/// This class is responsible for:
/// - Starting and stopping the `RoomCaptureSession`.
/// - Handling the `RoomCaptureSessionDelegate` events.
/// - Acting as a `FlutterStreamHandler` to send real-time scan updates to Flutter.
@available(iOS 16.0, *)
class RoomPlanController: NSObject, RoomCaptureSessionDelegate, FlutterStreamHandler {
  /// The shared singleton instance.
  static let shared = RoomPlanController()
  private let logger = Logger(subsystem: "com.apple.RoomPlan", category: "RoomPlanController")

  /// The method channel used to communicate with Flutter.
  var channel: FlutterMethodChannel?
  private var roomCaptureView: RoomCaptureView?
  private var finalResults: CapturedRoom?
  private var flutterResult: FlutterResult?
  private var startTime: Date?
  private var endTime: Date?

  /// The event sink for the Flutter event channel.
  private var eventSink: FlutterEventSink?

  private override init() {}

  /// Starts a new RoomPlan session.
  ///
  /// This method presents the `RoomCaptureView` and starts the scanning process.
  /// The `result` closure is called when the scan is finished or an error occurs.
  func startSession(result: @escaping FlutterResult) {
    self.flutterResult = result
    self.finalResults = nil

    roomCaptureView = RoomCaptureView(frame: .zero)
    roomCaptureView?.captureSession.delegate = self

    let vc = UIViewController()
    vc.view = roomCaptureView

    let navVC = UINavigationController(rootViewController: vc)

    let doneButton = UIBarButtonItem(
      barButtonSystemItem: .done, target: self, action: #selector(doneScanning))
    let cancelButton = UIBarButtonItem(
      barButtonSystemItem: .cancel, target: self, action: #selector(cancelScanning))
    vc.navigationItem.rightBarButtonItem = doneButton
    vc.navigationItem.leftBarButtonItem = cancelButton
    vc.navigationItem.title = "Scanning Room..."

    let rootViewController = UIApplication.shared.windows.first(where: \.isKeyWindow)?
      .rootViewController
    rootViewController?.present(navVC, animated: true)

    let configuration = RoomCaptureSession.Configuration()

    roomCaptureView?.captureSession.run(configuration: configuration)
  }

  /// Called when the user taps the 'Done' button in the scanning UI.
  @objc func doneScanning() {
    roomCaptureView?.captureSession.stop()
    dismiss()
  }

  /// Called when the user taps the 'Cancel' button in the scanning UI.
  @objc func cancelScanning() {
    roomCaptureView?.captureSession.stop()
    dismiss()
  }

  /// Stops the current RoomPlan session.
  func stopSession(result: @escaping FlutterResult) {
    roomCaptureView?.captureSession.stop()
    dismiss()
  }

  /// Dismisses the presented view controller.
  func dismiss() {
    let rootViewController = UIApplication.shared.windows.first(where: \.isKeyWindow)?
      .rootViewController
    rootViewController?.dismiss(animated: true)
  }

  // MARK: - RoomCaptureSessionDelegate
  /// Called when the room layout is updated during a scan.
  public func captureSession(_ session: RoomCaptureSession, didUpdate room: CapturedRoom) {
    finalResults = room
    if let eventSink = eventSink {
      // Go to a background thread to do the heavy encoding work
      DispatchQueue.global(qos: .userInitiated).async {
        do {
          let json = try RoomPlanJSONConverter.convertToJSON(capturedRoom: room, metadata: [:])
          // Go back to the main thread to send the result to Flutter
          DispatchQueue.main.async {
            eventSink(json)
          }
        } catch {
          // Go back to the main thread to send the error to Flutter
          DispatchQueue.main.async {
            eventSink(
              FlutterError(
                code: "serialization_error", message: "Failed to serialize room data.",
                details: error.localizedDescription))
          }
        }
      }
    }
  }

  /// Called when the scanning session ends.
  public func captureSession(
    _ session: RoomCaptureSession, didEndWith data: CapturedRoomData, error: Error?
  ) {
    endTime = Date()
    if let error = error {
      flutterResult?(
        FlutterError(code: "native_error", message: error.localizedDescription, details: nil))
      return
    }

    guard let finalResults = finalResults else {
      flutterResult?(
        FlutterError(code: "data_not_found", message: "Final scan data is missing.", details: nil)
      )
      return
    }

    let hasLidar = ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh)
    let sessionDuration = endTime!.timeIntervalSince(startTime ?? Date())

    let metadata =
      [
        "session_duration": sessionDuration,
        "device_model": UIDevice.current.model,
        "has_lidar": hasLidar,
      ] as [String: Any]

    do {
      let json = try RoomPlanJSONConverter.convertToJSON(
        capturedRoom: finalResults, metadata: metadata)
      flutterResult?(json)
    } catch {
      flutterResult?(
        FlutterError(
          code: "serialization_error", message: "Failed to serialize final room data.",
          details: error.localizedDescription))
    }
  }

  /// Called when the scanning session starts.
  public func captureSession(
    _ session: RoomCaptureSession, didStartWith configuration: RoomCaptureSession.Configuration
  ) {
    startTime = Date()
  }

  /// Called when the scanning session fails.
  public func captureSession(
    _ session: RoomCaptureSession, didFailWith error: Error
  ) {
    if (error as? RoomCaptureSession.Error) == .worldTrackingNotAvailable {
      flutterResult?(
        FlutterError(
          code: "world_tracking_not_available",
          message: "World tracking is not available on this device.", details: nil))
    } else {
      flutterResult?(
        FlutterError(code: "native_error", message: error.localizedDescription, details: nil))
    }
  }

  // MARK: - FlutterStreamHandler
  /// Sets up the event channel stream.
  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink)
    -> FlutterError?
  {
    self.eventSink = events
    return nil
  }

  /// Tears down the event channel stream.
  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    self.eventSink = nil
    return nil
  }
}
