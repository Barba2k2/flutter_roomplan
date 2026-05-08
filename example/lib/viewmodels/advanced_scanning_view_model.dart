import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:roomplan_flutter/roomplan_flutter.dart';

/// View model for `AdvancedScanningPage`.
///
/// Owns the `RoomPlanScanner` instance, the duration timer, the live scan
/// statistics derived from `ScanResult` updates, the active
/// `ScanConfiguration`, the user's preferred [MeasurementUnit], and the
/// translation of plugin exceptions into human-readable status messages.
class AdvancedScanningViewModel extends ChangeNotifier {
  AdvancedScanningViewModel() {
    _checkSupport();
  }

  RoomPlanScanner? _scanner;
  StreamSubscription<ScanResult?>? _scanSubscription;
  Timer? _durationTimer;
  Timer? _statisticsRefreshTimer;
  DateTime? _scanStartTime;

  bool _isSupported = false;
  bool _isScanning = false;
  ScanResult? _currentResult;
  String _statusMessage = 'Checking compatibility…';
  ScanConfiguration _selectedConfig = const ScanConfiguration();
  MeasurementUnit _selectedUnit = MeasurementUnit.metric;

  int _wallsDetected = 0;
  int _objectsDetected = 0;
  int _doorsDetected = 0;
  int _windowsDetected = 0;
  String _scanDuration = '00:00';

  bool get isSupported => _isSupported;
  bool get isScanning => _isScanning;
  ScanResult? get currentResult => _currentResult;
  String get statusMessage => _statusMessage;
  ScanConfiguration get selectedConfig => _selectedConfig;
  MeasurementUnit get selectedUnit => _selectedUnit;
  int get wallsDetected => _wallsDetected;
  int get objectsDetected => _objectsDetected;
  int get doorsDetected => _doorsDetected;
  int get windowsDetected => _windowsDetected;
  String get scanDuration => _scanDuration;

  Future<void> _checkSupport() async {
    try {
      final supported = await RoomPlanScanner.isSupported();
      _isSupported = supported;
      _statusMessage = supported
          ? 'Device is compatible with RoomPlan'
          : 'Device is not compatible with RoomPlan';
      if (supported) {
        _initialiseScanner();
      }
    } catch (e) {
      _statusMessage = 'Error checking compatibility: $e';
    }
    notifyListeners();
  }

  void _initialiseScanner() {
    final scanner = RoomPlanScanner();
    _scanner = scanner;

    _scanSubscription =
        scanner.onScanResult.where((result) => result != null).listen((result) {
      _ingestResult(result!, notify: false);
    });

    // Coalesce notifications so live ScanResult bursts don't trigger a rebuild
    // per frame.
    _statisticsRefreshTimer =
        Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (_isScanning) {
        notifyListeners();
      }
    });
  }

  void _ingestResult(ScanResult result, {required bool notify}) {
    _currentResult = result;
    _wallsDetected = result.room.walls.length;
    _objectsDetected = result.room.objects.length;
    _doorsDetected = result.room.doors.length;
    _windowsDetected = result.room.windows.length;
    if (notify) notifyListeners();
  }

  Future<void> startScan() async {
    final scanner = _scanner;
    if (scanner == null || !_isSupported || _isScanning) return;

    _isScanning = true;
    _statusMessage = 'Starting scan…';
    _scanStartTime = DateTime.now();
    _wallsDetected = 0;
    _objectsDetected = 0;
    _doorsDetected = 0;
    _windowsDetected = 0;
    notifyListeners();

    _startDurationTimer();

    try {
      final result = await scanner.startScanning(configuration: _selectedConfig);
      if (result != null) {
        _ingestResult(result, notify: false);
        _statusMessage = 'Scan completed successfully!';
      } else {
        _statusMessage = 'Scan completed but no data received';
      }
    } catch (e) {
      _statusMessage = mapErrorToMessage(e);
    } finally {
      _isScanning = false;
      _durationTimer?.cancel();
      _durationTimer = null;
      notifyListeners();
    }
  }

  Future<void> stopScan() async {
    final scanner = _scanner;
    if (scanner == null || !_isScanning) return;
    try {
      await scanner.stopScanning();
      _statusMessage = 'Scan stopped by user';
    } catch (e) {
      _statusMessage = 'Error stopping scan: $e';
    } finally {
      _isScanning = false;
      _durationTimer?.cancel();
      _durationTimer = null;
      notifyListeners();
    }
  }

  void updateConfiguration(ScanConfiguration configuration) {
    _selectedConfig = configuration;
    notifyListeners();
  }

  void toggleUnit() {
    _selectedUnit = _selectedUnit == MeasurementUnit.metric
        ? MeasurementUnit.imperial
        : MeasurementUnit.metric;
    notifyListeners();
  }

  void _startDurationTimer() {
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final start = _scanStartTime;
      if (start == null) return;
      final duration = DateTime.now().difference(start);
      _scanDuration = '${duration.inMinutes.toString().padLeft(2, '0')}:'
          '${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
      notifyListeners();
    });
  }

  /// Maps known `RoomPlan` exceptions to user-facing messages. Visible for
  /// reuse in dialogs.
  static String mapErrorToMessage(Object error) {
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
    }
    return 'Scan failed: $error';
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _durationTimer?.cancel();
    _statisticsRefreshTimer?.cancel();
    if (_isSupported) {
      _scanner?.dispose();
    }
    super.dispose();
  }
}
