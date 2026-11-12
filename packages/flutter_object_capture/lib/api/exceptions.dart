import 'models/object_output_format.dart';

/// Base exception for Object Capture errors.
abstract class ObjectCaptureException implements Exception {
  final String message;
  ObjectCaptureException(this.message);

  @override
  String toString() => 'ObjectCaptureException: $message';
}

/// Thrown when the device or platform cannot run Object Capture.
class ObjectCaptureNotSupportedException extends ObjectCaptureException {
  ObjectCaptureNotSupportedException()
      : super(
          'Object Capture is not supported on this device. Requires iOS 17+ or macOS 12+ on supported hardware.',
        );
}

/// Thrown when the images directory is empty, missing or unreadable.
class InvalidImagesDirectoryException extends ObjectCaptureException {
  InvalidImagesDirectoryException([String? details])
      : super(
          details == null
              ? 'Invalid images directory.'
              : 'Invalid images directory: $details',
        );
}

/// Thrown when the output path does not fit the output format: a `.usdz`
/// file path, or an extension-less directory path for `objDirectory`.
class InvalidOutputPathException extends ObjectCaptureException {
  InvalidOutputPathException(
    String details, [
    ObjectOutputFormat format = ObjectOutputFormat.usdz,
  ]) : super(
          format == ObjectOutputFormat.usdz
              ? 'Invalid output path (expected a .usdz file): $details'
              : 'Invalid output path (expected a directory path without extension): $details',
        );
}

/// Thrown when the requested detail level is not supported on this platform
/// (iOS only supports `ObjectDetail.reduced`).
class UnsupportedDetailException extends ObjectCaptureException {
  UnsupportedDetailException(String details)
      : super('Unsupported detail level: $details');
}

/// Thrown when the device does not have enough free storage.
class InsufficientStorageException extends ObjectCaptureException {
  final int? requiredBytes;
  InsufficientStorageException({this.requiredBytes})
      : super(
          requiredBytes == null
              ? 'Not enough free storage to reconstruct the model.'
              : 'Not enough free storage to reconstruct the model. Required: $requiredBytes bytes.',
        );
}

/// Thrown when a reconstruction is already running.
class ReconstructionInProgressException extends ObjectCaptureException {
  ReconstructionInProgressException()
      : super('A reconstruction is already in progress.');
}

/// Thrown (as a stream error) when the reconstruction was cancelled.
class ReconstructionCancelledException extends ObjectCaptureException {
  ReconstructionCancelledException() : super('Reconstruction was cancelled.');
}

/// Thrown when the reconstruction fails for a reason Apple does not type.
class ReconstructionFailedException extends ObjectCaptureException {
  ReconstructionFailedException(String details)
      : super('Reconstruction failed: $details');
}

/// Thrown when the guided capture images directory already has files in it.
class DirectoryNotEmptyException extends ObjectCaptureException {
  DirectoryNotEmptyException()
      : super('The capture images directory must be empty.');
}

/// Thrown when the camera or LiDAR sensor fails during guided capture.
class CaptureSensorFailedException extends ObjectCaptureException {
  CaptureSensorFailedException()
      : super('The camera or LiDAR sensor failed during capture.');
}

/// Thrown when camera tracking is lost during guided capture.
class CaptureTrackingFailedException extends ObjectCaptureException {
  CaptureTrackingFailedException()
      : super('Camera tracking failed during capture.');
}

/// Thrown when guided capture fails for a reason Apple does not type.
class CaptureFailedException extends ObjectCaptureException {
  CaptureFailedException(String details) : super('Capture failed: $details');
}

/// Thrown when there is an unexpected error in the native channel.
class NativeChannelException extends ObjectCaptureException {
  NativeChannelException(String details)
      : super('Error in native channel: $details');
}

/// Thrown when a payload from native does not match the channel contract.
class PayloadParsingException extends ObjectCaptureException {
  PayloadParsingException(String details)
      : super('Error parsing native payload: $details');
}
