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
          'Object Capture is not supported on this device. Requires iOS 17 or newer on supported hardware.',
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

/// Thrown when the output path is not a usable `.usdz` file path.
class InvalidOutputPathException extends ObjectCaptureException {
  InvalidOutputPathException(String details)
      : super('Invalid output path (expected a .usdz file): $details');
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
