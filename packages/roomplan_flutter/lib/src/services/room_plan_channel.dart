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
  
  // Performance optimization: Use single subscription controllers to reduce memory overhead
  final StreamController<Map<String, dynamic>> _scanResultController =
      StreamController<Map<String, dynamic>>();

  final StreamController<dynamic> _scanUpdateController =
      StreamController<dynamic>();
      
  // Performance optimization: Stream subscription management
  StreamSubscription<dynamic>? _eventSubscription;
  Timer? _cleanupTimer;
  bool _isDisposed = false;
  
  // Performance optimization: Stream caching to avoid repeated broadcast stream creation
  Stream<Map<String, dynamic>>? _cachedScanResultStream;
  Stream<dynamic>? _cachedScanUpdateStream;

  /// A stream for the final scan result, emitted when the user finishes.
  /// Performance optimization: Cache broadcast streams to avoid repeated creation.
  Stream<Map<String, dynamic>> get scanResultStream {
    if (_isDisposed) {
      throw StateError('RoomPlanChannel has been disposed');
    }
    return _cachedScanResultStream ??= _scanResultController.stream.asBroadcastStream();
  }

  /// A stream for real-time updates during an active scan.
  /// Performance optimization: Cache broadcast streams to avoid repeated creation.
  Stream<dynamic> get scanUpdateStream {
    if (_isDisposed) {
      throw StateError('RoomPlanChannel has been disposed');
    }
    return _cachedScanUpdateStream ??= _scanUpdateController.stream.asBroadcastStream();
  }

  /// Creates a [RoomPlanChannel].
  ///
  /// A custom [MethodChannel] can be provided for testing purposes.
  RoomPlanChannel({MethodChannel? channel, EventChannel? eventChannel})
      : _channel =
            channel ?? const MethodChannel('roomplan_flutter/method_channel'),
        _eventChannel = eventChannel ??
            const EventChannel('roomplan_flutter/event_channel') {
    _initializeEventListener();
    _scheduleCleanupTimer();
  }
  
  /// Performance optimization: Initialize event listener with proper error handling and cleanup
  void _initializeEventListener() {
    if (_isDisposed) return;
    
    _eventSubscription = _eventChannel.receiveBroadcastStream().listen(
      (event) {
        if (!_isDisposed && !_scanUpdateController.isClosed) {
          _scanUpdateController.add(event);
        }
      },
      onError: (error) {
        if (!_isDisposed && !_scanUpdateController.isClosed) {
          _scanUpdateController.addError(error);
        }
      },
      cancelOnError: false,
    );
  }
  
  /// Performance optimization: Schedule automatic cleanup after inactivity
  void _scheduleCleanupTimer() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer(const Duration(minutes: 5), () {
      if (!_isDisposed) {
        _performMaintenanceCleanup();
      }
    });
  }
  
  /// Performance optimization: Periodic maintenance to free unused resources
  void _performMaintenanceCleanup() {
    if (_isDisposed) return;
    
    // Reset cached streams if no active listeners
    if (_cachedScanResultStream != null && !_scanResultController.hasListener) {
      _cachedScanResultStream = null;
    }
    if (_cachedScanUpdateStream != null && !_scanUpdateController.hasListener) {
      _cachedScanUpdateStream = null;
    }
    
    // Schedule next cleanup
    _scheduleCleanupTimer();
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

  /// Closes the stream controllers and cancels all subscriptions.
  /// Performance optimization: Comprehensive cleanup to prevent memory leaks.
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    
    // Cancel timers and subscriptions
    _cleanupTimer?.cancel();
    _eventSubscription?.cancel();
    
    // Clear cached streams
    _cachedScanResultStream = null;
    _cachedScanUpdateStream = null;
    
    // Close controllers
    if (!_scanResultController.isClosed) {
      _scanResultController.close();
    }
    if (!_scanUpdateController.isClosed) {
      _scanUpdateController.close();
    }
  }
}
