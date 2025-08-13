import 'dart:async';
import 'dart:io';
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

  /// Calls the native side to start a room scanning session.
  Future<dynamic> startRoomCapture({ScanConfiguration? configuration}) async {
    try {
      final arguments = configuration?.toMap();
      return await _channel.invokeMethod('startRoomCapture', arguments);
    } on PlatformException catch (e) {
      switch (e.code) {
        case 'camera_permission_denied':
          throw RoomPlanPermissionsException();
        case 'camera_permission_not_determined':
          throw CameraPermissionNotDeterminedException();
        case 'camera_permission_unknown':
          throw CameraPermissionUnknownException();
        case 'CANCELED':
          throw ScanCancelledException();
        case 'not_available':
        case 'roomplan_not_supported':
          throw RoomPlanNotAvailableException();
        case 'unsupported_version':
          throw UnsupportedVersionException();
        case 'arkit_not_supported':
          throw ARKitNotSupportedException();
        case 'insufficient_hardware':
          throw InsufficientHardwareException();
        case 'low_power_mode':
          throw LowPowerModeException();
        case 'insufficient_storage':
          throw InsufficientStorageException();
        case 'session_in_progress':
          throw SessionInProgressException();
        case 'session_not_running':
          throw SessionNotRunningException();
        case 'world_tracking_failed':
          throw WorldTrackingFailedException();
        case 'memory_pressure':
          throw MemoryPressureException();
        case 'background_mode_active':
          throw BackgroundModeActiveException();
        case 'device_overheating':
          throw DeviceOverheatingException();
        case 'network_required':
          throw NetworkRequiredException();
        case 'timeout':
          throw TimeoutException(e.message ?? 'Unknown operation');
        case 'data_corrupted':
          throw DataCorruptedException(e.message ?? 'Unknown error');
        case 'export_failed':
          throw ExportFailedException(e.message ?? 'Unknown error');
        case 'ui_error':
          throw UIErrorException(e.message ?? 'Unknown error');
        case 'session_start_failed':
          throw SessionStartFailedException(e.message ?? 'Unknown error');
        case 'scan_failed':
          throw ScanFailedException(e.message ?? 'Unknown error');
        case 'processing_failed':
          throw ProcessingFailedException(e.message ?? 'Unknown error');
        default:
          throw NativeChannelException('${e.code}: ${e.message}');
      }
    } catch (e) {
      throw RoomPlanScanningErrorException('Unexpected error: $e');
    }
  }

  /// Calls the native side to stop the current room scanning session.
  Future<void> stopRoomCapture() async {
    try {
      await _channel.invokeMethod('stopRoomCapture');
    } on PlatformException catch (e) {
      throw NativeChannelException('Failed to stop scan: ${e.code}: ${e.message}');
    } catch (e) {
      throw RoomPlanScanningErrorException('Unexpected error stopping scan: $e');
    }
  }

  static Future<bool> isSupported() async {
    if (!Platform.isIOS) return false;
    
    try {
      // Directly use the MethodChannel for this static method
      const MethodChannel staticChannel = MethodChannel('roomplan_flutter/method_channel');
      final result = await staticChannel.invokeMethod('isSupported');
      return result as bool? ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Closes the stream controllers.
  void dispose() {
    _scanResultController.close();
    _scanUpdateController.close();
  }
}
