import 'dart:async';
import 'package:flutter/services.dart';
import 'package:roomplan_flutter/roomplan_flutter.dart';

/// Handles communication with the native iOS RoomPlan platform code.
///
/// This class uses a [MethodChannel] to invoke methods on the native side
/// and receives callbacks from the native side.
class RoomPlanChannel {
  final MethodChannel _channel;

  final StreamController<Map<String, dynamic>> _scanResultController =
      StreamController.broadcast();

  final StreamController<Map<String, dynamic>> _scanUpdateController =
      StreamController.broadcast();

  /// A stream for the final scan result, emitted when the user finishes.
  Stream<Map<String, dynamic>> get scanResultStream =>
      _scanResultController.stream;

  /// A stream for real-time updates during an active scan.
  Stream<Map<String, dynamic>> get scanUpdateStream =>
      _scanUpdateController.stream;

  /// Creates a [RoomPlanChannel].
  ///
  /// A custom [MethodChannel] can be provided for testing purposes.
  RoomPlanChannel({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel('room_plan_channel') {
    _channel.setMethodCallHandler(_handleMethod);
  }

  /// Handles incoming method calls from the native platform.
  Future<void> _handleMethod(MethodCall call) async {
    switch (call.method) {
      case 'onScanResult':
        if (call.arguments is Map) {
          final result = Map<String, dynamic>.from(call.arguments);
          _scanResultController.add(result);
        }
        break;
      case 'onScanUpdate':
        if (call.arguments is Map) {
          final result = Map<String, dynamic>.from(call.arguments);
          _scanUpdateController.add(result);
        }
        break;
      default:
        // Other methods are not expected from the native side.
        break;
    }
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
  Future<void> startRoomCapture() async {
    try {
      await _channel.invokeMethod('startRoomCapture');
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
