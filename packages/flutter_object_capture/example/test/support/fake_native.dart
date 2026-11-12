import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mocks both plugin channels. One instance per test.
class FakeNative {
  static const methodChannel = MethodChannel(
    'flutter_object_capture/method_channel',
  );
  static const eventChannel = EventChannel(
    'flutter_object_capture/event_channel',
  );

  final calls = <MethodCall>[];
  MockStreamHandlerEventSink? sink;
  bool supported = true;
  Object? startError;
  Object? limitsError;
  bool guidedSupported = true;
  Object? captureError;
  Object? captureResult = {'imagesDirectory': '/captured', 'imageCount': 12};

  TestDefaultBinaryMessenger get _messenger =>
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  int get startCalls =>
      calls.where((c) => c.method == 'startReconstruction').length;
  int get cancelCalls =>
      calls.where((c) => c.method == 'cancelReconstruction').length;

  int get captureCalls =>
      calls.where((c) => c.method == 'captureImages').length;

  void install() {
    _messenger.setMockMethodCallHandler(methodChannel, (call) async {
      calls.add(call);
      switch (call.method) {
        case 'isSupported':
          return supported;
        case 'getLimits':
          if (limitsError != null) throw limitsError!;
          return {'maxImages': 100, 'maxImageDimension': 4096};
        case 'isGuidedCaptureSupported':
          return guidedSupported;
        case 'captureImages':
          if (captureError != null) throw captureError!;
          return captureResult;
        case 'startReconstruction':
          if (startError != null) throw startError!;
          return null;
        default:
          return null;
      }
    });
    _messenger.setMockStreamHandler(
      eventChannel,
      MockStreamHandler.inline(
        onListen: (arguments, events) {
          sink = events;
        },
        onCancel: (arguments) {
          sink = null;
        },
      ),
    );
  }

  void uninstall() {
    _messenger.setMockMethodCallHandler(methodChannel, null);
    _messenger.setMockStreamHandler(eventChannel, null);
  }

  void progress(double fraction, {int? seconds}) => sink?.success({
        'type': 'progress',
        'fraction': fraction,
        if (seconds != null) 'estimatedRemainingSeconds': seconds,
      });

  void sampleIssue(int id, {String? reason, bool skipped = false}) =>
      sink?.success({
        'type': 'sampleIssue',
        'sampleId': id,
        if (reason != null) 'reason': reason,
        'skipped': skipped,
      });

  void notice(String name) => sink?.success({'type': 'notice', 'notice': name});

  void completed(String path, int size) => sink?.success({
        'type': 'completed',
        'modelPath': path,
        'fileSizeBytes': size,
      });

  void nativeError(String code, {String? message, Object? details}) =>
      sink?.error(code: code, message: message, details: details);
}
