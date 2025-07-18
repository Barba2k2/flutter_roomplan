import 'dart:async';
import 'package:flutter/material.dart';
import 'package:roomplan_flutter/roomplan_flutter.dart';
import 'package:roomplan_flutter/src/mapper.dart';
import 'package:roomplan_flutter/src/services/room_plan_channel.dart';

/// Central class for interacting with the RoomPlan feature.
///
/// This class provides methods to start and stop room scanning sessions
/// and streams for receiving real-time updates and the final scan result.
class RoomPlanScanner {
  final RoomPlanChannel _channel;

  /// A stream that emits [RoomPlanResult] during an active scan.
  ///
  /// The updates can be used to provide real-time feedback to the user.
  /// The result will be null if parsing of the native data fails.
  final Stream<ScanResult?> onScanResult;

  /// Private constructor for initializing the scanner.
  RoomPlanScanner._(this._channel, this.onScanResult);

  /// Creates and initializes a [RoomPlanScanner].
  ///
  /// A [RoomPlanChannel] can be provided for testing purposes.
  factory RoomPlanScanner({RoomPlanChannel? roomPlanChannel}) {
    final channel = roomPlanChannel ?? RoomPlanChannel();
    final onScanResult = channel.scanUpdateStream.map((result) {
      try {
        if (result is String) {
          return parseScanResult(result);
        }
        return null;
      } catch (e, stacktrace) {
        debugPrint('Error parsing scan update: $e');
        debugPrint(stacktrace.toString());
        return null;
      }
    }).asBroadcastStream();
    return RoomPlanScanner._(channel, onScanResult);
  }

  /// Starts a new room scanning session.
  ///
  /// Returns a [RoomPlanResult] upon completion, or null if the scan
  /// is cancelled or fails.
  Future<ScanResult?> startScan() async {
    final result = await _channel.startRoomCapture();
    if (result is String) {
      return parseScanResult(result);
    }
    return null;
  }

  /// Stops the current scanning session.
  ///
  /// The final result will be delivered via the Future returned by [startScan].
  Future<void> stopScan() async {
    return _channel.stopRoomCapture();
  }

  /// Disposes of the resources used by the scanner.
  void dispose() {
    _channel.dispose();
  }
}
