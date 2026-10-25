import 'package:flutter_object_capture/flutter_object_capture.dart';

import '../strings/app_strings.dart';
import 'file_size_helper.dart';

/// Turns any error into one clear sentence for the user.
class ErrorMessageHelper {
  ErrorMessageHelper._();

  static String describe(Object error) {
    return switch (error) {
      ObjectCaptureNotSupportedException() => AppStrings.errorNotSupported,
      InvalidImagesDirectoryException() => AppStrings.errorInvalidImages,
      InvalidOutputPathException() => AppStrings.errorInvalidOutput,
      UnsupportedDetailException() => AppStrings.errorUnsupportedDetail,
      InsufficientStorageException(:final requiredBytes) =>
        requiredBytes == null
            ? AppStrings.errorStorage
            : '${AppStrings.errorStorage} Needs about '
                '${FileSizeHelper.format(requiredBytes)}.',
      ReconstructionInProgressException() => AppStrings.errorInProgress,
      ReconstructionCancelledException() => AppStrings.errorCancelled,
      ReconstructionFailedException(:final message) =>
        '${AppStrings.errorFailed}: $message',
      DirectoryNotEmptyException() => AppStrings.errorDirectoryNotEmpty,
      CaptureSensorFailedException() => AppStrings.errorSensor,
      CaptureTrackingFailedException() => AppStrings.errorTracking,
      CaptureFailedException(:final message) =>
        '${AppStrings.errorCapture}: $message',
      NativeChannelException(:final message) =>
        '${AppStrings.errorNative}: $message',
      PayloadParsingException(:final message) =>
        '${AppStrings.errorPayload}: $message',
      _ => '${AppStrings.errorUnknown}: $error',
    };
  }
}
