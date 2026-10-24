import 'dart:async';
import 'package:flutter/material.dart';
import 'package:roomplan_flutter/roomplan_flutter.dart';

class AdvancedScanningViewModel extends ChangeNotifier {
  late final RoomPlanScanner _scanner;
  StreamSubscription<ScanResult?>? _scanSubscription;
  Timer? _statisticsUpdateTimer;
  Timer? _durationTimer;

  bool _isSupported = false;
  bool _isScanning = false;
  ScanResult? _currentResult;
  String _statusMessage = 'Checking compatibility...';
  ScanConfiguration _selectedConfig = const ScanConfiguration();

  int _wallsDetected = 0;
  int _objectsDetected = 0;
  int _doorsDetected = 0;
  int _windowsDetected = 0;
  DateTime? _scanStartTime;
  String _scanDuration = '00:00';
  MeasurementUnit _selectedUnit = MeasurementUnit.metric;

  bool get isSupported => _isSupported;
  bool get isScanning => _isScanning;
  ScanResult? get currentResult => _currentResult;
  String get statusMessage => _statusMessage;
  ScanConfiguration get selectedConfig => _selectedConfig;
  int get wallsDetected => _wallsDetected;
  int get objectsDetected => _objectsDetected;
  int get doorsDetected => _doorsDetected;
  int get windowsDetected => _windowsDetected;
  String get scanDuration => _scanDuration;
  MeasurementUnit get selectedUnit => _selectedUnit;

  AdvancedScanningViewModel() {
    unawaited(_checkSupport()); // errors are reported through statusMessage
  }

  @override
  void dispose() {
    // Performance optimization: Proper cleanup order to prevent memory leaks
    _scanSubscription?.cancel();
    _durationTimer?.cancel();
    _statisticsUpdateTimer?.cancel();
    if (_isSupported) {
      _scanner.dispose();
    }
    super.dispose();
  }

  void setConfiguration(ScanConfiguration config) {
    _selectedConfig = config;
    notifyListeners();
  }

  void toggleUnit() {
    _selectedUnit = _selectedUnit == MeasurementUnit.metric
        ? MeasurementUnit.imperial
        : MeasurementUnit.metric;
    notifyListeners();
  }

  Future<void> _checkSupport() async {
    try {
      final supported = await RoomPlanScanner.isSupported();
      _isSupported = supported;
      _statusMessage = supported
          ? 'Device is compatible with RoomPlan'
          : 'Device is not compatible with RoomPlan';
      notifyListeners();

      if (supported) {
        _initializeScanner();
      }
    } catch (e) {
      _statusMessage = 'Error checking compatibility: $e';
      notifyListeners();
    }
  }

  void _initializeScanner() {
    _scanner = RoomPlanScanner();

    // Performance optimization: Throttle UI updates to prevent excessive rebuilds
    _scanSubscription = _scanner.onScanResult
        .where((result) => result != null)
        .listen((result) {
      _updateStatistics(result!);
    });

    // Performance optimization: Update statistics on a timer to reduce UI rebuilds
    _statisticsUpdateTimer =
        Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (_isScanning) {
        notifyListeners();
      }
    });
  }

  void _updateStatistics(ScanResult result) {
    // Performance optimization: Update statistics without notifying to avoid excessive rebuilds
    _currentResult = result;
    _wallsDetected = result.room.walls.length;
    _objectsDetected = result.room.objects.length;
    _doorsDetected = result.room.doors.length;
    _windowsDetected = result.room.windows.length;
  }

  Future<void> startScan() async {
    if (!_isSupported || _isScanning) return;

    _isScanning = true;
    _statusMessage = 'Starting scan...';
    _scanStartTime = DateTime.now();
    _wallsDetected = 0;
    _objectsDetected = 0;
    _doorsDetected = 0;
    _windowsDetected = 0;
    notifyListeners();

    _startDurationTimer();

    try {
      final result =
          await _scanner.startScanning(configuration: _selectedConfig);

      _isScanning = false;
      if (result != null) {
        _currentResult = result;
        _statusMessage = 'Scan completed successfully!';
        _wallsDetected = result.room.walls.length;
        _objectsDetected = result.room.objects.length;
        _doorsDetected = result.room.doors.length;
        _windowsDetected = result.room.windows.length;
      } else {
        _statusMessage = 'Scan completed but no data received';
      }
      notifyListeners();
    } catch (e) {
      _isScanning = false;
      _statusMessage = _getErrorMessage(e);
      notifyListeners();
    } finally {
      _durationTimer?.cancel();
    }
  }

  Future<void> stopScan() async {
    if (!_isScanning) return;

    try {
      await _scanner.stopScanning();
      _isScanning = false;
      _statusMessage = 'Scan stopped by user';
      notifyListeners();
    } catch (e) {
      _statusMessage = 'Error stopping scan: $e';
      notifyListeners();
    } finally {
      _durationTimer?.cancel();
    }
  }

  void _startDurationTimer() {
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_scanStartTime != null) {
        final duration = DateTime.now().difference(_scanStartTime!);
        _scanDuration = '${duration.inMinutes.toString().padLeft(2, '0')}:'
            '${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
        notifyListeners();
      }
    });
  }

  String _getErrorMessage(dynamic error) {
    if (error is RoomPlanPermissionsException) {
      return 'Camera permission denied. Please enable in Settings.';
    } else if (error is ScanCancelledException) {
      return 'Scan was cancelled by user.';
    } else if (error is LowPowerModeException) {
      return 'Scanning disabled in Low Power Mode. Please disable and try again.';
    } else if (error is InsufficientStorageException) {
      return 'Not enough storage space. Please free up space and try again.';
    } else if (error is WorldTrackingFailedException) {
      return 'World tracking failed. Ensure good lighting and try again.';
    } else {
      return 'Scan failed: $error';
    }
  }
}
