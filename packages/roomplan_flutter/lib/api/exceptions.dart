/// Base exception for RoomPlan errors.
abstract class RoomPlanException implements Exception {
  final String message;
  RoomPlanException(this.message);

  @override
  String toString() => 'RoomPlanException: $message';
}

/// Thrown when the RoomPlan feature is not available on the device.
class RoomPlanNotAvailableException extends RoomPlanException {
  RoomPlanNotAvailableException()
      : super(
          'RoomPlan is not available on this device. Requires a device with LiDAR sensor and iOS 16 or newer.',
        );
}

/// Thrown when there is an error during the scanning process.
class RoomPlanScanningErrorException extends RoomPlanException {
  RoomPlanScanningErrorException(super.message);
}

/// Thrown when camera permissions are denied by the user.
class RoomPlanPermissionsException extends RoomPlanException {
  RoomPlanPermissionsException()
      : super(
          'Camera permission is required to use RoomPlan. Please grant permission in settings.',
        );
}

/// Thrown when the scan is cancelled by the user.
class ScanCancelledException extends RoomPlanException {
  ScanCancelledException() : super('Scan was cancelled by the user.');
}

/// Thrown when the scan fails.
class ScanFailedException extends RoomPlanException {
  ScanFailedException(String details) : super('Scan failed: $details');
}

/// Thrown when processing the scan data fails.
class ProcessingFailedException extends RoomPlanException {
  ProcessingFailedException(String details)
      : super('Processing failed: $details');
}

/// Thrown when there is an error in the native channel.
class NativeChannelException extends RoomPlanException {
  NativeChannelException(String details)
      : super('Error in native channel: $details');
}

/// Thrown when there is an error parsing JSON data.
class DataParsingException extends RoomPlanException {
  DataParsingException(String details) : super('Error parsing data: $details');
}

/// Thrown when the iOS version is not supported.
class UnsupportedVersionException extends RoomPlanException {
  UnsupportedVersionException() 
      : super('iOS 16.0 or later is required for RoomPlan functionality.');
}

/// Thrown when camera permission is not yet determined.
class CameraPermissionNotDeterminedException extends RoomPlanException {
  CameraPermissionNotDeterminedException()
      : super('Camera permission has not been requested. Please grant camera access when prompted.');
}

/// Thrown when camera permission status is unknown.
class CameraPermissionUnknownException extends RoomPlanException {
  CameraPermissionUnknownException()
      : super('Camera permission status is unknown. Please check app permissions in Settings.');
}

/// Thrown when ARKit is not supported on the device.
class ARKitNotSupportedException extends RoomPlanException {
  ARKitNotSupportedException()
      : super('ARKit is not supported on this device. World tracking capability is required.');
}

/// Thrown when device lacks necessary hardware for room scanning.
class InsufficientHardwareException extends RoomPlanException {
  InsufficientHardwareException()
      : super('This device lacks the necessary hardware for room scanning. A LiDAR sensor or ARKit scene reconstruction is required.');
}

/// Thrown when Low Power Mode is enabled.
class LowPowerModeException extends RoomPlanException {
  LowPowerModeException()
      : super('Room scanning is disabled while Low Power Mode is active. Please disable Low Power Mode in Settings.');
}

/// Thrown when there is insufficient storage space.
class InsufficientStorageException extends RoomPlanException {
  InsufficientStorageException()
      : super('Insufficient storage space available. At least 100MB of free space is required for room scanning.');
}

/// Thrown when a scanning session is already in progress.
class SessionInProgressException extends RoomPlanException {
  SessionInProgressException()
      : super('A room scanning session is already in progress. Please complete or cancel the current session before starting a new one.');
}

/// Thrown when trying to stop a session that is not running.
class SessionNotRunningException extends RoomPlanException {
  SessionNotRunningException()
      : super('No room scanning session is currently running. Please start a session before attempting to stop it.');
}

/// Thrown when world tracking fails.
class WorldTrackingFailedException extends RoomPlanException {
  WorldTrackingFailedException()
      : super('World tracking failed. Please ensure adequate lighting and try scanning in a different area.');
}

/// Thrown when the device is experiencing memory pressure.
class MemoryPressureException extends RoomPlanException {
  MemoryPressureException()
      : super('The device is experiencing memory pressure. Please close other apps and try again.');
}

/// Thrown when the app goes into background mode during scanning.
class BackgroundModeActiveException extends RoomPlanException {
  BackgroundModeActiveException()
      : super('Room scanning cannot continue while the app is in the background.');
}

/// Thrown when the device is overheating.
class DeviceOverheatingException extends RoomPlanException {
  DeviceOverheatingException()
      : super('The device is overheating. Please let it cool down before continuing room scanning.');
}

/// Thrown when a network connection is required but not available.
class NetworkRequiredException extends RoomPlanException {
  NetworkRequiredException()
      : super('A network connection is required for this operation.');
}

/// Thrown when an operation times out.
class TimeoutException extends RoomPlanException {
  final String operation;
  TimeoutException(this.operation)
      : super('The operation \'$operation\' timed out. Please try again.');
}

/// Thrown when scan data is corrupted.
class DataCorruptedException extends RoomPlanException {
  DataCorruptedException(String details)
      : super('Scan data appears to be corrupted: $details');
}

/// Thrown when export operations fail.
class ExportFailedException extends RoomPlanException {
  ExportFailedException(String details)
      : super('Failed to export scan results: $details');
}

/// Thrown when there's a UI-related error.
class UIErrorException extends RoomPlanException {
  UIErrorException(String details)
      : super('UI error occurred: $details');
}

/// Thrown when session start fails.
class SessionStartFailedException extends RoomPlanException {
  SessionStartFailedException(String details)
      : super('Failed to start capture session: $details');
}
