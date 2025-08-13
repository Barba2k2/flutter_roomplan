import 'dart:async';
import 'package:flutter/material.dart';
import 'package:roomplan_flutter/roomplan_flutter.dart';

class ScannerViewModel extends ChangeNotifier {
  final RoomPlanScanner _roomPlanScanner = RoomPlanScanner();
  StreamSubscription<ScanResult?>? _scanSubscription;

  String _scanStatus = 'Ready to scan';
  bool _isScanning = false;
  ScanResult? _currentScanResult;

  String get scanStatus => _scanStatus;
  bool get isScanning => _isScanning;
  ScanResult? get currentScanResult => _currentScanResult;

  ScannerViewModel() {
    _scanSubscription = _roomPlanScanner.onScanResult.listen((scanResult) {
      if (scanResult != null) {
        _currentScanResult = scanResult;
        _scanStatus = 'Scanning... (${scanResult.room.walls.length} walls detected)';
        notifyListeners();
      }
    });
  }

  Future<void> startScanning() async {
    _isScanning = true;
    _scanStatus = 'Starting scan...';
    _currentScanResult = null;
    notifyListeners();

    try {
      final result = await _roomPlanScanner.startScanning();

      if (result != null) {
        _currentScanResult = result;
        _scanStatus = 'Scan completed successfully!';
      } else {
        _scanStatus = 'Scan was cancelled by the user';
      }
    } catch (e) {
      _scanStatus = 'Error during scan: $e';
    } finally {
      _isScanning = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _roomPlanScanner.dispose();
    super.dispose();
  }
}