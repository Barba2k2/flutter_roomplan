import 'package:flutter/services.dart';

/// Channel name shared with [SwiftFlutterObjectCapturePlugin] on the iOS side
/// for one-shot method invocations (start capture, reconstruct, isSupported).
const MethodChannel objectCaptureMethodChannel =
    MethodChannel('flutter_object_capture/method_channel');

/// Channel name shared with the iOS side for streaming session progress and
/// state transitions back to Dart.
const EventChannel objectCaptureEventChannel =
    EventChannel('flutter_object_capture/event_channel');
