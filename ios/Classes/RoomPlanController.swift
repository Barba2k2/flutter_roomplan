import ARKit
import AVFoundation
import Darwin
import Flutter
import Foundation
import RoomPlan

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

  /// Starts a new RoomPlan session with optional configuration.
  ///
  /// This method presents the `RoomCaptureView` and starts the scanning process.
  /// The `result` closure is called when the scan is finished or an error occurs.
  func startSession(with configuration: [String: Any]? = nil, result: @escaping FlutterResult) {
    self.flutterResult = result
    self.finalResults = nil

    // Pre-flight checks with detailed error codes
    do {
      try performPreflightChecks()
    } catch let error as RoomPlanError {
      result(FlutterError(code: error.code, message: error.message, details: error.details))
      return
    } catch {
      result(FlutterError(code: "unknown_error", message: "An unexpected error occurred.", details: error.localizedDescription))
      return
    }

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
    
    guard let rootViewController = rootViewController else {
      result(FlutterError(code: "ui_error", message: "Unable to access root view controller.", details: "The app's UI hierarchy might not be properly initialized."))
      return
    }
    
    rootViewController.present(navVC, animated: true) { [weak self] in
      self?.startCaptureSession(with: configuration, result: result)
    }
  }
  
  /// Starts the actual capture session after UI is presented
  private func startCaptureSession(with configDict: [String: Any]? = nil, result: @escaping FlutterResult) {
    let configuration = createConfiguration(from: configDict)

    do {
      roomCaptureView?.captureSession.run(configuration: configuration)
    } catch {
      result(FlutterError(code: "session_start_failed", message: "Failed to start capture session.", details: error.localizedDescription))
    }
  }
  
  /// Creates a RoomCaptureSession.Configuration from Flutter configuration dictionary
  private func createConfiguration(from configDict: [String: Any]?) -> RoomCaptureSession.Configuration {
    let configuration = RoomCaptureSession.Configuration()
    
    guard let configDict = configDict else {
      return configuration
    }
    
    // Apply quality settings
    if let qualityString = configDict["quality"] as? String {
      switch qualityString {
      case "fast":
        // Optimize for speed - disable some features if possible
        break
      case "high":
        // Optimize for accuracy - enable all features
        break
      case "balanced":
        // Default balanced settings
        break
      default:
        break
      }
    }
    
    // Note: RoomCaptureSession.Configuration in iOS 16.0 has limited customization options
    // Most configuration will be handled at the app level for now
    
    return configuration
  }
  
  /// Performs comprehensive pre-flight checks before starting a scan
  private func performPreflightChecks() throws {
    // Check iOS version
    guard #available(iOS 16.0, *) else {
      throw RoomPlanError.unsupportedVersion
    }
    
    // Check RoomPlan availability
    guard RoomCaptureSession.isSupported else {
      throw RoomPlanError.roomPlanNotSupported
    }
    
    // Check camera permission
    let cameraAuthStatus = AVCaptureDevice.authorizationStatus(for: .video)
    switch cameraAuthStatus {
    case .denied, .restricted:
      throw RoomPlanError.cameraPermissionDenied
    case .notDetermined:
      throw RoomPlanError.cameraPermissionNotDetermined
    case .authorized:
      break
    @unknown default:
      throw RoomPlanError.cameraPermissionUnknown
    }
    
    // Check ARKit availability
    guard ARWorldTrackingConfiguration.isSupported else {
      throw RoomPlanError.arKitNotSupported
    }
    
    // Check device capabilities
    let hasRequiredFeatures = ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) || isLiDARDevice()
    guard hasRequiredFeatures else {
      throw RoomPlanError.insufficientHardware
    }
    
    // Check system resources
    if ProcessInfo.processInfo.isLowPowerModeEnabled {
      throw RoomPlanError.lowPowerMode
    }
    
    // Check available storage (need at least 100MB for scan data)
    let freeSpace = try getAvailableStorage()
    if freeSpace < 100 * 1024 * 1024 { // 100MB in bytes
      throw RoomPlanError.insufficientStorage
    }
  }
  
  /// Gets available storage space in bytes
  private func getAvailableStorage() throws -> Int64 {
    let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    let values = try documentDirectory.resourceValues(forKeys: [.volumeAvailableCapacityKey])
    return values.volumeAvailableCapacity ?? 0
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

    let hasLidar = detectLiDAR()
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
    let roomPlanError = classifyError(error)
    flutterResult?(
      FlutterError(
        code: roomPlanError.code,
        message: roomPlanError.message,
        details: roomPlanError.details
      )
    )
  }
  
  /// Classifies native errors into specific RoomPlanError types
  private func classifyError(_ error: Error) -> RoomPlanError {
    let errorDescription = error.localizedDescription.lowercased()
    
    // Check for specific error patterns
    if errorDescription.contains("world tracking") || errorDescription.contains("not available") {
      return .worldTrackingFailed
    } else if errorDescription.contains("memory") || errorDescription.contains("resources") {
      return .memoryPressure
    } else if errorDescription.contains("permission") || errorDescription.contains("camera") {
      return .cameraPermissionDenied
    } else if errorDescription.contains("background") {
      return .backgroundModeActive
    } else if errorDescription.contains("thermal") || errorDescription.contains("overheat") {
      return .deviceOverheating
    } else if errorDescription.contains("timeout") {
      return .timeout("Room scanning session")
    } else if errorDescription.contains("corrupt") || errorDescription.contains("invalid") {
      return .dataCorrupted(error.localizedDescription)
    } else {
      return .processingFailed(error.localizedDescription)
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

  /// Detects LiDAR capability using multiple methods for better accuracy
  private func detectLiDAR() -> Bool {
    let supportsSceneReconstruction = ARWorldTrackingConfiguration.supportsSceneReconstruction(
      .mesh)
    let hasLidarByModel = isLiDARDevice()

    return supportsSceneReconstruction || hasLidarByModel
  }

  /// Checks if the current device model supports LiDAR
  private func isLiDARDevice() -> Bool {
    var systemInfo = utsname()
    uname(&systemInfo)
    let modelCode = withUnsafePointer(to: &systemInfo.machine) {
      $0.withMemoryRebound(to: CChar.self, capacity: 1) {
        ptr in String(cString: ptr)
      }
    }

    let model = modelCode

    // iPhone models with LiDAR
    let lidarIPhones = [
      "iPhone13,2", "iPhone13,3", "iPhone13,4",  // iPhone 12 Pro, 12 Pro Max
      "iPhone14,2", "iPhone14,3",  // iPhone 13 Pro, 13 Pro Max
      "iPhone15,2", "iPhone15,3",  // iPhone 14 Pro, 14 Pro Max
      "iPhone16,1", "iPhone16,2",  // iPhone 15 Pro, 15 Pro Max
      "iPhone17,1", "iPhone17,2",  // iPhone 16 Pro, 16 Pro Max
    ]

    // iPad models with LiDAR
    let lidarIPads = [
      "iPad8,9", "iPad8,10", "iPad8,11", "iPad8,12",  // iPad Pro 11" (4th gen), 12.9" (4th gen)
      "iPad13,4", "iPad13,5", "iPad13,6", "iPad13,7", "iPad13,8", "iPad13,9", "iPad13,10",
      "iPad13,11",  // iPad Pro 11" (5th gen), 12.9" (5th gen)
      "iPad14,3", "iPad14,4", "iPad14,5", "iPad14,6",  // iPad Pro 11" (6th gen), 12.9" (6th gen)
    ]

    return lidarIPhones.contains(model) || lidarIPads.contains(model)
  }
}
