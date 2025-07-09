import 'dart:async';
import 'package:flutter/services.dart';
import 'package:roomplan_flutter/roomplan_flutter.dart';

/// Handles communication with the native iOS RoomPlan platform code.
///
/// This class uses a [MethodChannel] to invoke methods on the native side
/// and receives callbacks from the native side.
class RoomPlanChannel {
  final MethodChannel _channel;
  final EventChannel _eventChannel;

  final StreamController<Map<String, dynamic>> _scanResultController =
      StreamController.broadcast();

  final StreamController<dynamic> _scanUpdateController =
      StreamController.broadcast();

  /// A stream for the final scan result, emitted when the user finishes.
  Stream<Map<String, dynamic>> get scanResultStream =>
      _scanResultController.stream;

  /// A stream for real-time updates during an active scan.
  Stream<dynamic> get scanUpdateStream => _scanUpdateController.stream;

  /// Creates a [RoomPlanChannel].
  ///
  /// A custom [MethodChannel] can be provided for testing purposes.
  RoomPlanChannel({MethodChannel? channel, EventChannel? eventChannel})
      : _channel =
            channel ?? const MethodChannel('roomplan_flutter/method_channel'),
        _eventChannel = eventChannel ??
            const EventChannel('roomplan_flutter/event_channel') {
    _eventChannel.receiveBroadcastStream().listen((event) {
      _scanUpdateController.add(event);
    });
  }

  /// Calls the native side to check if RoomPlan is supported on the device.
  Future<bool> isRoomPlanSupported() async {
    try {
      final bool isSupported = await _channel.invokeMethod(
        'isRoomPlanSupported',
      );
      return isSupported;
    } on PlatformException {
      return false;
    }
  }

  /// Calls the native side to start a room scanning session.
  Future<dynamic> startRoomCapture() async {
    try {
      return await _channel.invokeMethod('startRoomCapture');
    } on PlatformException catch (e) {
      if (e.code == 'camera_permission_denied') {
        throw RoomPlanPermissionsException();
      }
      rethrow;
    }
  }

  /// Calls the native side to stop the current room scanning session.
  Future<void> stopRoomCapture() async {
    try {
      await _channel.invokeMethod('stopRoomCapture');
    } on PlatformException {
      rethrow;
    }
  }

  /// Closes the stream controllers.
  void dispose() {
    _scanResultController.close();
    _scanUpdateController.close();
  }
}
