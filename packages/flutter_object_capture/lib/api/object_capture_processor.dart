import 'dart:async';
import 'dart:developer';

import 'package:flutter_object_capture/api/exceptions.dart';
import 'package:flutter_object_capture/api/models/object_capture_configuration.dart';
import 'package:flutter_object_capture/api/models/object_capture_limits.dart';
import 'package:flutter_object_capture/api/models/reconstruction_event.dart';
import 'package:flutter_object_capture/src/helpers/output_path_helper.dart';
import 'package:flutter_object_capture/src/helpers/reconstruction_event_helper.dart';
import 'package:flutter_object_capture/src/services/object_capture_channel.dart';

/// Turns a folder of photos into a USDZ model using RealityKit Object Capture.
///
/// One reconstruction runs at a time per processor. Call [dispose] when done.
class ObjectCaptureProcessor {
  final ObjectCaptureChannel _channel = ObjectCaptureChannel();
  StreamController<ReconstructionEvent>? _controller;
  StreamSubscription<Object?>? _nativeSubscription;

  /// Whether this device can run Object Capture. False off iOS.
  static Future<bool> isSupported() => ObjectCaptureChannel().isSupported();

  Future<ObjectCaptureLimits> getLimits() => _channel.getLimits();

  /// Starts a reconstruction when the returned stream is listened to.
  ///
  /// Emits events until [ReconstructionCompleted], then closes. Failures are
  /// stream errors ([ObjectCaptureException]). Cancelling the subscription
  /// cancels the native job.
  ///
  /// Throws synchronously: [InvalidImagesDirectoryException],
  /// [InvalidOutputPathException], [ReconstructionInProgressException].
  Stream<ReconstructionEvent> reconstruct({
    required String imagesDirectory,
    required String outputPath,
    ObjectCaptureConfiguration configuration =
        const ObjectCaptureConfiguration(),
  }) {
    if (imagesDirectory.trim().isEmpty) {
      throw InvalidImagesDirectoryException('path is empty');
    }
    OutputPathHelper.validate(outputPath);
    if (_controller != null) {
      throw ReconstructionInProgressException();
    }
    final arguments = <String, Object?>{
      'imagesDirectory': imagesDirectory,
      'outputPath': outputPath,
      'featureSensitivity': configuration.featureSensitivity.name,
      'sampleOrdering': configuration.sampleOrdering.name,
    };
    late final StreamController<ReconstructionEvent> controller;
    controller = StreamController<ReconstructionEvent>(
      onListen: () => unawaited(_begin(controller, arguments)),
      onCancel: () => _abort(controller),
    );
    _controller = controller;
    return controller.stream;
  }

  /// Asks native to cancel. The stream then ends with
  /// [ReconstructionCancelledException]. No-op when nothing is running.
  Future<void> cancel() async {
    final controller = _controller;
    if (controller == null) return;
    if (!controller.hasListener) {
      _controller = null;
      unawaited(controller.close());
      return;
    }
    await _channel.cancelReconstruction();
  }

  void dispose() {
    final controller = _controller;
    if (controller == null) return;
    unawaited(_abort(controller));
    unawaited(controller.close());
  }

  Future<void> _begin(
    StreamController<ReconstructionEvent> controller,
    Map<String, Object?> arguments,
  ) async {
    _nativeSubscription = _channel.events.listen(
      (payload) => _onPayload(controller, payload),
      onError: (Object error, StackTrace stackTrace) =>
          _finish(controller, error, stackTrace),
    );
    try {
      await _channel.startReconstruction(arguments);
    } catch (error, stackTrace) {
      _finish(controller, error, stackTrace);
    }
  }

  void _onPayload(
    StreamController<ReconstructionEvent> controller,
    Object? payload,
  ) {
    if (_controller != controller) return;
    final ReconstructionEvent event;
    try {
      event = ReconstructionEventHelper.parse(payload);
    } on PayloadParsingException catch (error, stackTrace) {
      _finish(controller, error, stackTrace);
      return;
    }
    controller.add(event);
    if (event is ReconstructionCompleted) _finish(controller);
  }

  void _finish(
    StreamController<ReconstructionEvent> controller, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    if (_controller != controller) return;
    _controller = null;
    unawaited(_nativeSubscription?.cancel());
    _nativeSubscription = null;
    if (error != null) controller.addError(error, stackTrace);
    unawaited(controller.close());
  }

  /// Listener cancelled or processor disposed while the job may still run.
  Future<void> _abort(StreamController<ReconstructionEvent> controller) async {
    if (_controller != controller) return;
    _controller = null;
    unawaited(_nativeSubscription?.cancel());
    _nativeSubscription = null;
    try {
      await _channel.cancelReconstruction();
    } on ObjectCaptureException catch (e) {
      log('cancelReconstruction failed: $e', name: 'ObjectCaptureProcessor');
    }
  }
}
