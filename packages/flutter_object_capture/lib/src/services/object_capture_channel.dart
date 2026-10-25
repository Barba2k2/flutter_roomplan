import 'dart:async';
import 'dart:developer';

import 'package:flutter/services.dart';
import 'package:flutter_object_capture/api/exceptions.dart';
import 'package:flutter_object_capture/api/models/object_capture_limits.dart';

/// Thin wrapper over the plugin channels. Maps native errors to exceptions.
class ObjectCaptureChannel {
  static const _methodChannel = MethodChannel(
    'flutter_object_capture/method_channel',
  );
  static const _eventChannel = EventChannel(
    'flutter_object_capture/event_channel',
  );

  /// Raw event payloads. Native errors arrive as mapped exceptions.
  Stream<Object?> get events =>
      _eventChannel.receiveBroadcastStream().transform(
            StreamTransformer<Object?, Object?>.fromHandlers(
              handleError: (error, stackTrace, sink) => sink.addError(
                error is PlatformException
                    ? mapPlatformException(error)
                    : error,
                stackTrace,
              ),
            ),
          );

  Future<bool> isSupported() async {
    try {
      return await _methodChannel.invokeMethod<bool>('isSupported') ?? false;
    } on PlatformException catch (e) {
      log('isSupported failed: ${e.code}', name: 'ObjectCaptureChannel');
      return false;
    } on MissingPluginException {
      return false;
    }
  }

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

  Future<void> startReconstruction(Map<String, Object?> arguments) =>
      _invoke<void>('startReconstruction', arguments);

  Future<void> cancelReconstruction() => _invoke<void>('cancelReconstruction');

  static ObjectCaptureException mapPlatformException(PlatformException e) {
    final message = e.message ?? 'Unknown error';
    return switch (e.code) {
      'invalid_images' => InvalidImagesDirectoryException(message),
      'invalid_output' => InvalidOutputPathException(message),
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
      _ => NativeChannelException('${e.code}: $message'),
    };
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
