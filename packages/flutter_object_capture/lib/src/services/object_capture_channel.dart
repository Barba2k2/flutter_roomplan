import 'dart:async';
import 'dart:developer';

import 'package:flutter/services.dart';
import '../../api/exceptions.dart';
import '../../api/models/object_capture_limits.dart';
import '../../api/models/object_capture_session_result.dart';

/// Thin wrapper over the plugin channels. Maps native errors to exceptions.
class ObjectCaptureChannel {
  static const _methodChannel = MethodChannel(
    'flutter_object_capture/method_channel',
  );
  static const _eventChannel = EventChannel(
    'flutter_object_capture/event_channel',
  );

  /// Raw event payloads. Native errors arrive as mapped exceptions.
  Stream<Object?> get events {
    return _eventChannel.receiveBroadcastStream().transform(
      StreamTransformer<Object?, Object?>.fromHandlers(
        handleError: (error, stackTrace, sink) {
          sink.addError(
            error is PlatformException ? mapPlatformException(error) : error,
            stackTrace,
          );
        },
      ),
    );
  }

  Future<bool> isSupported() => _invokeSupport('isSupported');

  Future<bool> isGuidedCaptureSupported() =>
      _invokeSupport('isGuidedCaptureSupported');

  Future<ObjectCaptureLimits> getLimits() async {
    final result = await _invoke<Object?>('getLimits');
    final maxImages = result is Map ? result['maxImages'] : null;
    final maxImageDimension =
        result is Map ? result['maxImageDimension'] : null;
    if (maxImages is! int || maxImageDimension is! int) {
      throw PayloadParsingException('invalid limits: $result');
    }
    return ObjectCaptureLimits(
      maxImages: maxImages,
      maxImageDimension: maxImageDimension,
    );
  }

  Future<void> startReconstruction(Map<String, Object?> arguments) {
    return _invoke<void>('startReconstruction', arguments);
  }

  Future<ObjectCaptureSessionResult> captureImages(
    Map<String, Object?> arguments,
  ) async {
    final result = await _invoke<Object?>('captureImages', arguments);
    final imagesDirectory = result is Map ? result['imagesDirectory'] : null;
    final checkpointDirectory =
        result is Map ? result['checkpointDirectory'] : null;
    final imageCount = result is Map ? result['imageCount'] : null;
    if (imagesDirectory is! String ||
        imageCount is! int ||
        (checkpointDirectory != null && checkpointDirectory is! String)) {
      throw PayloadParsingException('invalid capture result: $result');
    }
    return ObjectCaptureSessionResult(
      imagesDirectory: imagesDirectory,
      checkpointDirectory: checkpointDirectory as String?,
      imageCount: imageCount,
    );
  }

  Future<void> cancelReconstruction() => _invoke<void>('cancelReconstruction');

  static ObjectCaptureException mapPlatformException(PlatformException e) {
    final message = e.message ?? 'Unknown error';
    return switch (e.code) {
      'invalid_images' => InvalidImagesDirectoryException(message),
      'invalid_output' => InvalidOutputPathException(message),
      'unsupported_detail' => UnsupportedDetailException(message),
      'insufficient_storage' => InsufficientStorageException(
          requiredBytes: switch (e.details) {
            {'requiredBytes': final int bytes} => bytes,
            _ => null,
          },
        ),
      'session_in_progress' => ReconstructionInProgressException(),
      'cancelled' => ReconstructionCancelledException(),
      'reconstruction_failed' => ReconstructionFailedException(message),
      'not_supported' => ObjectCaptureNotSupportedException(),
      'directory_not_empty' => DirectoryNotEmptyException(),
      'sensor_failed' => CaptureSensorFailedException(),
      'tracking_failed' => CaptureTrackingFailedException(),
      'capture_failed' => CaptureFailedException(message),
      _ => NativeChannelException('${e.code}: $message'),
    };
  }

  Future<bool> _invokeSupport(String method) async {
    try {
      return await _methodChannel.invokeMethod<bool>(method) ?? false;
    } on PlatformException catch (e) {
      log('$method failed: ${e.code}', name: 'ObjectCaptureChannel');
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<T?> _invoke<T>(String method, [Object? arguments]) async {
    try {
      return await _methodChannel.invokeMethod<T>(method, arguments);
    } on PlatformException catch (e) {
      throw mapPlatformException(e);
    } on MissingPluginException {
      throw ObjectCaptureNotSupportedException();
    }
  }
}
