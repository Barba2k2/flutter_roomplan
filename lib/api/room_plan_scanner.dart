import 'dart:async';

import 'package:roomplan_flutter/src/mapper.dart';
import 'package:roomplan_flutter/roomplan_flutter.dart';
import 'package:roomplan_flutter/src/services/room_plan_channel.dart';

/// The main class for interacting with the RoomPlan functionality.
///
/// Provides methods to start and stop scanning sessions, and streams for
/// receiving real-time updates during a scan.
class RoomPlanScanner {
  final RoomPlanChannel _channel;
  StreamSubscription<dynamic>? _subscription;

  // Stream controllers
  final _streamController = StreamController<ScanResult>.broadcast();

  /// A stream that emits [ScanResult] in real-time. This includes room data,
  /// metadata, and confidence levels as the scan progresses.
  Stream<ScanResult> get onScanResult => _streamController.stream;

  /// Creates a new instance of the [RoomPlanScanner].
  RoomPlanScanner() : _channel = RoomPlanChannel() {
    _listenToUpdates();
  }

  /// Closes the stream controller. It's important to call this when the scanner is no longer needed
  /// to prevent memory leaks.
  void dispose() {
    _streamController.close();
    _subscription?.cancel();
    _channel.dispose();
  }

  void _listenToUpdates() {
    _subscription = _channel.scanUpdateStream.listen((event) {
      if (event is String) {
        final scanResult = parseScanResult(event);
        if (scanResult != null) {
          _streamController.add(scanResult);
        }
      }
    });
  }

  /// Checks if the current device supports RoomPlan.
  ///
  /// RoomPlan requires a device with a LiDAR sensor running iOS 16 or newer.
  /// Returns `true` if supported, `false` otherwise.
  Future<bool> isSupported() => _channel.isRoomPlanSupported();

  /// Starts a new room scanning session.
  ///
  /// This method presents a full-screen view for the user to scan their room.
  /// You can listen to the [onScanResult] stream for real-time updates.
  ///
  /// The returned [Future] completes with the final [ScanResult] when the
  /// user closes the scanning view (either by tapping 'Done' or 'Cancel').
  /// A `null` value may be returned if the scan fails or is cancelled without
  /// producing any data.
  ///
  /// Throws a [RoomPlanPermissionsException] if camera permissions are denied.
  Future<ScanResult?> startScanning() async {
    final result = await _channel.startRoomCapture();
    if (result is String) {
      return parseScanResult(result);
    }
    return null;
  }

  /// Programmatically stops the current room scanning session.
  ///
  /// When this method is called, the native scanning view is dismissed.
  /// This will cause the [Future] returned by [startScanning] to complete.
  Future<void> stopScanning() => _channel.stopRoomCapture();
}
