import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:roomplan_flutter/roomplan_flutter.dart';
import 'package:roomplan_flutter/src/mapper.dart';
import 'package:roomplan_flutter/src/services/room_plan_channel.dart';

/// The main class for interacting with the RoomPlan functionality.
///
/// Provides methods to start and stop scanning sessions, and streams for
/// receiving real-time updates during a scan.
class RoomPlanScanner {
  final RoomPlanChannel _channel;

  // Stream controllers
  final _onScanResultController = StreamController<ScanResult>.broadcast();

  /// A stream that emits [ScanResult] in real-time. This includes room data,
  /// metadata, and confidence levels as the scan progresses.
  Stream<ScanResult> get onScanResult => _onScanResultController.stream;

  /// Creates a new instance of the [RoomPlanScanner].
  RoomPlanScanner() : _channel = RoomPlanChannel() {
    _listenToUpdates();
  }

  /// A constructor for testing purposes, allowing a mock channel to be injected.
  @visibleForTesting
  RoomPlanScanner.withChannel(this._channel) {
    _listenToUpdates();
  }

  void _listenToUpdates() {
    _channel.scanUpdateStream.listen((event) {
      final scanResult = parseScanResult(event['result']);
      if (scanResult != null) {
        _onScanResultController.add(scanResult);
      }
    });
  }

  /// Disposes the scanner and closes all active streams.
  /// It's important to call this method when the scanner is no longer needed
  /// to prevent memory leaks.
  void dispose() {
    _onScanResultController.close();
    _channel.dispose();
  }

  /// Checks if the current device supports RoomPlan.
  ///
  /// RoomPlan requires a device with a LiDAR sensor running iOS 16 or newer.
  /// Returns `true` if supported, `false` otherwise.
  Future<bool> isSupported() => _channel.isRoomPlanSupported();

  /// Starts a new room scanning session.
  ///
  /// This method presents the native RoomPlan scanning interface to the user.
  /// The returned [Future] completes when the scanning UI is fully presented.
  ///
  /// Throws a [RoomPlanPermissionsException] if camera permissions are denied.
  Future<void> startScanning() {
    return _channel.startRoomCapture();
  }

  /// Finishes the current scanning session and returns the final results.
  ///
  /// This method should be called after the user completes the scan by tapping
  /// the "Done" button in the native UI. The returned [Future] completes with a
  /// [ScanResult] containing the full room data, metadata, and confidence levels.
  ///
  /// Returns `null` if the scan fails or is cancelled.
  /// Throws a [ScanFailedException] if an error occurs during processing.
  Future<ScanResult?> finishScanning() async {
    final result = await _channel.scanResultStream.first;
    if (result['error'] != null) {
      final error = result['error'] as String;
      if (error.toLowerCase().contains('cancel')) {
        throw ScanCancelledException();
      }
      throw ScanFailedException(error);
    }
    return parseScanResult(result['result']);
  }

  /// Immediately stops the current scanning session without processing the data.
  ///
  /// This is equivalent to the user tapping the "Cancel" button in the native UI.
  Future<void> stopScanning() => _channel.stopRoomCapture();
}
