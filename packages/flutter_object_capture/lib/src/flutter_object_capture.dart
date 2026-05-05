import 'dart:async';

import 'package:flutter/services.dart';

import 'exceptions.dart';
import 'models/capture_event.dart';
import 'models/capture_state.dart';
import 'models/detail_level.dart';
import 'models/object_capture_configuration.dart';
import 'models/object_capture_result.dart';
import 'models/photogrammetry_result.dart';
import 'services/method_channel.dart';

/// Public entry point for the `flutter_object_capture` plugin.
///
/// All methods are static; the class itself is not meant to be instantiated.
/// See the package README for high-level usage examples.
class FlutterObjectCapture {
  FlutterObjectCapture._();

  static Stream<CaptureEvent>? _events;

  /// Returns whether the running device supports Apple's on-device Object
  /// Capture pipeline.
  ///
  /// Requires iOS 17.0+ and an A14 Bionic chip or newer (iPhone 12 Pro / iPad
  /// Pro 2020 and later).
  static Future<bool> isSupported() async {
    try {
      final result =
          await objectCaptureMethodChannel.invokeMethod<bool>('isSupported');
      return result ?? false;
    } on PlatformException catch (e) {
      throw ObjectCaptureException(
        e.message ?? 'Failed to query Object Capture support.',
        code: e.code,
        details: e.details,
      );
    }
  }

  /// Starts a guided object-capture session on iOS.
  ///
  /// The user is walked through capturing photos around the target object.
  /// On success the returned [ObjectCaptureResult] points at the folder of
  /// captured images, ready to be passed to [reconstruct].
  ///
  /// Throws [ObjectCaptureUnsupportedException] when the device cannot run
  /// Object Capture, or [ObjectCaptureException] for any other failure.
  static Future<ObjectCaptureResult> captureObject({
    ObjectCaptureConfiguration configuration =
        const ObjectCaptureConfiguration(),
  }) async {
    try {
      final raw = await objectCaptureMethodChannel
          .invokeMapMethod<String, Object?>(
        'captureObject',
        configuration.toJson(),
      );
      if (raw == null) {
        throw const ObjectCaptureException(
          'Native side returned no result for captureObject.',
        );
      }
      return ObjectCaptureResult.fromJson(raw);
    } on PlatformException catch (e) {
      if (e.code == 'unsupported') {
        throw ObjectCaptureUnsupportedException(
          e.message ?? 'Object Capture is not available on this device.',
        );
      }
      throw ObjectCaptureException(
        e.message ?? 'Object capture failed.',
        code: e.code,
        details: e.details,
      );
    }
  }

  /// Reconstructs a textured 3D model from a folder of photos previously
  /// produced by [captureObject] (or any other source of overlapping images).
  ///
  /// Writes a `.usdz` file at the path returned by [PhotogrammetryResult.modelPath].
  /// When [outputPath] is null, the native side picks a temporary location.
  static Future<PhotogrammetryResult> reconstruct({
    required String imagesPath,
    DetailLevel detailLevel = DetailLevel.medium,
    String? outputPath,
  }) async {
    try {
      final raw = await objectCaptureMethodChannel
          .invokeMapMethod<String, Object?>('reconstruct', {
        'imagesPath': imagesPath,
        'detailLevel': detailLevel.name,
        if (outputPath != null) 'outputPath': outputPath,
      });
      if (raw == null) {
        throw const ObjectCaptureException(
          'Native side returned no result for reconstruct.',
        );
      }
      return PhotogrammetryResult.fromJson(raw);
    } on PlatformException catch (e) {
      if (e.code == 'unsupported') {
        throw ObjectCaptureUnsupportedException(
          e.message ?? 'Photogrammetry is not available on this device.',
        );
      }
      throw ObjectCaptureException(
        e.message ?? 'Reconstruction failed.',
        code: e.code,
        details: e.details,
      );
    }
  }

  /// Stream of progress events emitted while a capture or reconstruction
  /// session is active.
  ///
  /// The stream is single-shot: it emits until the underlying session reaches
  /// [CaptureState.completed] or [CaptureState.failed], then closes.
  static Stream<CaptureEvent> get events {
    return _events ??= objectCaptureEventChannel
        .receiveBroadcastStream()
        .map((event) => _decodeEvent(event as Map<Object?, Object?>));
  }

  static CaptureEvent _decodeEvent(Map<Object?, Object?> raw) {
    final stateName = raw['state']! as String;
    return CaptureEvent(
      state: CaptureState.values.byName(stateName),
      progress: (raw['progress'] as num?)?.toDouble(),
      message: raw['message'] as String?,
      error: raw['error'],
    );
  }
}
