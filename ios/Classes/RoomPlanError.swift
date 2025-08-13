import Foundation

/// Comprehensive error types for RoomPlan operations with detailed debugging information
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