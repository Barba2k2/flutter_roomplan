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
