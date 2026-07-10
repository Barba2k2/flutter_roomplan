import ARKit
import AVFoundation
import Darwin
import Flutter
import Foundation
import RoomPlan

/// Comprehensive error types for RoomPlan operations with detailed debugging information
@available(iOS 16.0, *)
enum RoomPlanError: Error {
    case unsupportedVersion
    case roomPlanNotSupported
    case cameraPermissionDenied
    case cameraPermissionNotDetermined
    case cameraPermissionUnknown
    case arKitNotSupported
    case insufficientHardware
    case lowPowerMode
    case insufficientStorage
    case sessionInProgress
    case sessionNotRunning
    case worldTrackingFailed
    case memoryPressure
    case backgroundModeActive
    case deviceOverheating
    case networkRequired
    case processingFailed(String)
    case dataCorrupted(String)
    case exportFailed(String)
    case timeout(String)
    
    /// Error code for Flutter communication
    var code: String {
        switch self {
        case .unsupportedVersion:
            return "unsupported_version"
        case .roomPlanNotSupported:
            return "roomplan_not_supported"
        case .cameraPermissionDenied:
            return "camera_permission_denied"
        case .cameraPermissionNotDetermined:
            return "camera_permission_not_determined"
        case .cameraPermissionUnknown:
            return "camera_permission_unknown"
        case .arKitNotSupported:
            return "arkit_not_supported"
        case .insufficientHardware:
            return "insufficient_hardware"
        case .lowPowerMode:
            return "low_power_mode"
        case .insufficientStorage:
            return "insufficient_storage"
        case .sessionInProgress:
            return "session_in_progress"
        case .sessionNotRunning:
            return "session_not_running"
        case .worldTrackingFailed:
            return "world_tracking_failed"
        case .memoryPressure:
            return "memory_pressure"
        case .backgroundModeActive:
            return "background_mode_active"
        case .deviceOverheating:
            return "device_overheating"
        case .networkRequired:
            return "network_required"
        case .processingFailed:
            return "processing_failed"
        case .dataCorrupted:
            return "data_corrupted"
        case .exportFailed:
            return "export_failed"
        case .timeout:
            return "timeout"
        }
    }
    
    /// Human-readable error message
    var message: String {
        switch self {
        case .unsupportedVersion:
            return "iOS 16.0 or later is required for RoomPlan functionality."
        case .roomPlanNotSupported:
            return "RoomPlan is not supported on this device. A LiDAR sensor is required."
        case .cameraPermissionDenied:
            return "Camera access has been denied. Please enable camera permission in Settings."
        case .cameraPermissionNotDetermined:
            return "Camera permission has not been requested. Please grant camera access when prompted."
        case .cameraPermissionUnknown:
            return "Camera permission status is unknown. Please check app permissions in Settings."
        case .arKitNotSupported:
            return "ARKit is not supported on this device. World tracking capability is required."
        case .insufficientHardware:
            return "This device lacks the necessary hardware for room scanning. A LiDAR sensor or ARKit scene reconstruction is required."
        case .lowPowerMode:
            return "Room scanning is disabled while Low Power Mode is active. Please disable Low Power Mode in Settings."
        case .insufficientStorage:
            return "Insufficient storage space available. At least 100MB of free space is required for room scanning."
        case .sessionInProgress:
            return "A room scanning session is already in progress. Please complete or cancel the current session before starting a new one."
        case .sessionNotRunning:
            return "No room scanning session is currently running. Please start a session before attempting to stop it."
        case .worldTrackingFailed:
            return "World tracking failed. Please ensure adequate lighting and try scanning in a different area."
        case .memoryPressure:
            return "The device is experiencing memory pressure. Please close other apps and try again."
        case .backgroundModeActive:
            return "Room scanning cannot continue while the app is in the background."
        case .deviceOverheating:
            return "The device is overheating. Please let it cool down before continuing room scanning."
        case .networkRequired:
            return "A network connection is required for this operation."
        case .processingFailed(let details):
            return "Failed to process scan data: \(details)"
        case .dataCorrupted(let details):
            return "Scan data appears to be corrupted: \(details)"
        case .exportFailed(let details):
            return "Failed to export scan results: \(details)"
        case .timeout(let operation):
            return "The operation '\(operation)' timed out. Please try again."
        }
    }
    
    /// Additional debugging details
    var details: String? {
        switch self {
        case .unsupportedVersion:
            return "Current iOS version: \(UIDevice.current.systemVersion). Minimum required: 16.0"
        case .roomPlanNotSupported:
            return "Device model: \(UIDevice.current.model). RoomCaptureSession.isSupported: \(RoomCaptureSession.isSupported)"
        case .cameraPermissionDenied, .cameraPermissionNotDetermined, .cameraPermissionUnknown:
            return "Current camera authorization status: \(AVCaptureDevice.authorizationStatus(for: .video).debugDescription)"
        case .arKitNotSupported:
            return "ARWorldTrackingConfiguration.isSupported: \(ARWorldTrackingConfiguration.isSupported)"
        case .insufficientHardware:
            let supportsSceneReconstruction = ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh)
            return "Scene reconstruction support: \(supportsSceneReconstruction), Device model: \(getDeviceModel())"
        case .lowPowerMode:
            return "Low Power Mode enabled: \(ProcessInfo.processInfo.isLowPowerModeEnabled)"
        case .insufficientStorage:
            return "Available storage: \(getAvailableStorageString())"
        case .memoryPressure:
            return "Available memory: \(getAvailableMemoryString())"
        case .deviceOverheating:
            return "Thermal state: \(ProcessInfo.processInfo.thermalState.debugDescription)"
        case .processingFailed(let details), .dataCorrupted(let details), .exportFailed(let details), .timeout(let details):
            return details
        default:
            return nil
        }
    }
    
    /// Recovery suggestions for the user
    var recoverySuggestion: String? {
        switch self {
        case .unsupportedVersion:
            return "Update your device to iOS 16.0 or later to use room scanning."
        case .roomPlanNotSupported:
            return "Use a device with a LiDAR sensor (iPhone 12 Pro or newer Pro models, iPad Pro with LiDAR)."
        case .cameraPermissionDenied:
            return "Go to Settings > Privacy & Security > Camera and enable access for this app."
        case .cameraPermissionNotDetermined:
            return "Grant camera permission when prompted to enable room scanning."
        case .arKitNotSupported:
            return "Use a newer device that supports ARKit world tracking."
        case .insufficientHardware:
            return "Use a device with LiDAR sensor or better ARKit capabilities."
        case .lowPowerMode:
            return "Go to Settings > Battery and turn off Low Power Mode."
        case .insufficientStorage:
            return "Free up at least 100MB of storage space and try again."
        case .sessionInProgress:
            return "Complete or cancel the current scanning session before starting a new one."
        case .worldTrackingFailed:
            return "Ensure good lighting conditions and try scanning a different area with more distinct features."
        case .memoryPressure:
            return "Close other apps and restart the room scanning process."
        case .backgroundModeActive:
            return "Return to the app to continue room scanning."
        case .deviceOverheating:
            return "Let your device cool down for a few minutes before continuing."
        default:
            return "Please try again or contact support if the issue persists."
        }
    }
}

// MARK: - Helper Functions

private func getDeviceModel() -> String {
    var systemInfo = utsname()
    uname(&systemInfo)
    return withUnsafePointer(to: &systemInfo.machine) {
        $0.withMemoryRebound(to: CChar.self, capacity: 1) {
            String(cString: $0)
        }
    }
}

private func getAvailableStorageString() -> String {
    do {
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let values = try documentDirectory.resourceValues(forKeys: [.volumeAvailableCapacityKey])
        let bytes = values.volumeAvailableCapacity ?? 0
        return ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)
    } catch {
        return "Unknown"
    }
}

private func getAvailableMemoryString() -> String {
    let physicalMemory = ProcessInfo.processInfo.physicalMemory
    return ByteCountFormatter.string(fromByteCount: Int64(physicalMemory), countStyle: .memory)
}

// MARK: - Extensions for debugging

extension AVAuthorizationStatus {
    var debugDescription: String {
        switch self {
        case .authorized: return "authorized"
        case .denied: return "denied"
        case .notDetermined: return "notDetermined"
        case .restricted: return "restricted"
        @unknown default: return "unknown"
        }
    }
}

extension ProcessInfo.ThermalState {
    var debugDescription: String {
        switch self {
        case .nominal: return "nominal"
        case .fair: return "fair"
        case .serious: return "serious"
        case .critical: return "critical"
        @unknown default: return "unknown"
        }
    }
}

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
    return Int64(values.volumeAvailableCapacity ?? 0)
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
