import 'dart:async';
import 'package:flutter/material.dart';
import 'package:roomplan_flutter/roomplan_flutter.dart';

/// Advanced scanning page demonstrating various configuration options and scenarios.
class AdvancedScanningPage extends StatefulWidget {
  const AdvancedScanningPage({super.key});

  @override
  State<AdvancedScanningPage> createState() => _AdvancedScanningPageState();
}

class _AdvancedScanningPageState extends State<AdvancedScanningPage> {
  late final RoomPlanScanner _scanner;
  StreamSubscription<ScanResult?>? _scanSubscription;
  Timer? _statisticsUpdateTimer;
  
  bool _isSupported = false;
  bool _isScanning = false;
  ScanResult? _currentResult;
  String _statusMessage = 'Checking compatibility...';
  ScanConfiguration _selectedConfig = const ScanConfiguration();
  
  // Scanning statistics
  int _wallsDetected = 0;
  int _objectsDetected = 0;
  int _doorsDetected = 0;
  int _windowsDetected = 0;
  DateTime? _scanStartTime;
  String _scanDuration = '00:00';
  
  // Unit system preference
  MeasurementUnit _selectedUnit = MeasurementUnit.metric;
  
  Timer? _durationTimer;

  @override
  void initState() {
    super.initState();
    _checkSupport();
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

  Future<void> _checkSupport() async {
    try {
      final supported = await RoomPlanScanner.isSupported();
      setState(() {
        _isSupported = supported;
        _statusMessage = supported 
            ? 'Device is compatible with RoomPlan' 
            : 'Device is not compatible with RoomPlan';
      });
      
      if (supported) {
        _initializeScanner();
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error checking compatibility: $e';
      });
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
    _statisticsUpdateTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (_isScanning && mounted) {
        setState(() {
          // Force rebuild only when necessary
        });
      }
    });
  }
  
  void _updateStatistics(ScanResult result) {
    // Performance optimization: Update statistics without setState to avoid excessive rebuilds
    _currentResult = result;
    _wallsDetected = result.room.walls.length;
    _objectsDetected = result.room.objects.length;
    _doorsDetected = result.room.doors.length;
    _windowsDetected = result.room.windows.length;
  }

  Future<void> _startScan() async {
    if (!_isSupported || _isScanning) return;
    
    setState(() {
      _isScanning = true;
      _statusMessage = 'Starting scan...';
      _scanStartTime = DateTime.now();
      _wallsDetected = 0;
      _objectsDetected = 0;
      _doorsDetected = 0;
      _windowsDetected = 0;
    });
    
    _startDurationTimer();
    
    try {
      final result = await _scanner.startScanning(configuration: _selectedConfig);
      
      setState(() {
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
      });
    } catch (e) {
      setState(() {
        _isScanning = false;
        _statusMessage = _getErrorMessage(e);
      });
    } finally {
      _durationTimer?.cancel();
    }
  }

  Future<void> _stopScan() async {
    if (!_isScanning) return;
    
    try {
      await _scanner.stopScanning();
      setState(() {
        _isScanning = false;
        _statusMessage = 'Scan stopped by user';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error stopping scan: $e';
      });
    } finally {
      _durationTimer?.cancel();
    }
  }

  void _startDurationTimer() {
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_scanStartTime != null) {
        final duration = DateTime.now().difference(_scanStartTime!);
        setState(() {
          _scanDuration = '${duration.inMinutes.toString().padLeft(2, '0')}:'
                        '${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
        });
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

  void _showConfigurationDialog() {
    showDialog(
      context: context,
      builder: (context) => _ConfigurationDialog(
        currentConfig: _selectedConfig,
        onConfigurationChanged: (config) {
          setState(() {
            _selectedConfig = config;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Advanced Room Scanning'),
        actions: [
          // Unit toggle button
          if (_isSupported)
            IconButton(
              icon: Icon(_selectedUnit == MeasurementUnit.metric ? Icons.straighten : Icons.architecture),
              tooltip: 'Switch to ${_selectedUnit == MeasurementUnit.metric ? 'Imperial' : 'Metric'} units',
              onPressed: () {
                setState(() {
                  _selectedUnit = _selectedUnit == MeasurementUnit.metric 
                      ? MeasurementUnit.imperial 
                      : MeasurementUnit.metric;
                });
              },
            ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _isSupported && !_isScanning ? _showConfigurationDialog : null,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(_statusMessage),
                    if (_isScanning) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 8),
                          Text('Duration: $_scanDuration'),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            // Statistics Card
            if (_isSupported) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Detection Statistics',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _StatisticItem(
                            icon: Icons.crop_square,
                            label: 'Walls',
                            count: _wallsDetected,
                          ),
                          _StatisticItem(
                            icon: Icons.chair,
                            label: 'Objects',
                            count: _objectsDetected,
                          ),
                          _StatisticItem(
                            icon: Icons.door_front_door,
                            label: 'Doors',
                            count: _doorsDetected,
                          ),
                          _StatisticItem(
                            icon: Icons.window,
                            label: 'Windows',
                            count: _windowsDetected,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              // Configuration Card
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Configuration',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text('Units: ${_selectedUnit.displayName} (${_selectedUnit.lengthUnit}, ${_selectedUnit.areaUnit})'),
                      Text('Quality: ${_selectedConfig.quality.name}'),
                      Text('Timeout: ${_selectedConfig.timeoutSeconds ?? 'None'} seconds'),
                      Text('Real-time updates: ${_selectedConfig.enableRealtimeUpdates ? 'Enabled' : 'Disabled'}'),
                      Text('Detect furniture: ${_selectedConfig.detectFurniture ? 'Yes' : 'No'}'),
                    ],
                  ),
                ),
              ),
            ],
            
            const Spacer(),
            
            // Action Buttons
            if (_isSupported) ...[
              if (_isScanning)
                ElevatedButton.icon(
                  onPressed: _stopScan,
                  icon: const Icon(Icons.stop),
                  label: const Text('Stop Scanning'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                )
              else
                ElevatedButton.icon(
                  onPressed: _startScan,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Start Room Scan'),
                ),
              
              const SizedBox(height: 8),
              
              if (_currentResult != null)
                OutlinedButton.icon(
                  onPressed: () => _showResultsDialog(_currentResult!),
                  icon: const Icon(Icons.info),
                  label: const Text('View Detailed Results'),
                ),
            ] else
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'RoomPlan requires:\n'
                    '• iOS 16.0 or later\n'
                    '• Device with LiDAR sensor\n'
                    '• iPhone 12 Pro or newer Pro models\n'
                    '• iPad Pro with LiDAR',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showResultsDialog(ScanResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Scan Results'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Room Dimensions (${_selectedUnit.displayName}):'),
              if (result.room.dimensions != null) ...[
                Text('  Length: ${result.room.dimensions!.getFormattedLength(_selectedUnit)}'),
                Text('  Width: ${result.room.dimensions!.getFormattedWidth(_selectedUnit)}'),
                Text('  Height: ${result.room.dimensions!.getFormattedHeight(_selectedUnit)}'),
                Text('  Floor Area: ${result.room.dimensions!.getFormattedFloorArea(_selectedUnit)}'),
                Text('  Volume: ${result.room.dimensions!.getFormattedVolume(_selectedUnit)}'),
              ] else
                Text('  Not available'),
              
              const SizedBox(height: 16),
              Text('Scan Metadata:'),
              Text('  Duration: ${result.metadata.scanDuration.inSeconds}s'),
              Text('  Device: ${result.metadata.deviceModel}'),
              Text('  Has LiDAR: ${result.metadata.hasLidar ? 'Yes' : 'No'}'),
              
              const SizedBox(height: 16),
              Text('Confidence Scores:'),
              Text('  Overall: ${(result.confidence.overall * 100).toStringAsFixed(1)}%'),
              Text('  Wall Accuracy: ${(result.confidence.wallAccuracy * 100).toStringAsFixed(1)}%'),
              Text('  Dimension Accuracy: ${(result.confidence.dimensionAccuracy * 100).toStringAsFixed(1)}%'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _StatisticItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;

  const _StatisticItem({
    required this.icon,
    required this.label,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 32, color: Theme.of(context).primaryColor),
        const SizedBox(height: 4),
        Text(
          count.toString(),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _ConfigurationDialog extends StatefulWidget {
  final ScanConfiguration currentConfig;
  final Function(ScanConfiguration) onConfigurationChanged;

  const _ConfigurationDialog({
    required this.currentConfig,
    required this.onConfigurationChanged,
  });

  @override
  State<_ConfigurationDialog> createState() => _ConfigurationDialogState();
}

class _ConfigurationDialogState extends State<_ConfigurationDialog> {
  late ScanConfiguration _config;

  @override
  void initState() {
    super.initState();
    _config = widget.currentConfig;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Scan Configuration'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Quality Selection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Quality Level', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    ...ScanQuality.values.map((quality) => RadioListTile<ScanQuality>(
                      title: Text(quality.name),
                      subtitle: Text(quality.description),
                      value: quality,
                      groupValue: _config.quality,
                      onChanged: (value) {
                        setState(() {
                          _config = _config.copyWith(quality: value);
                        });
                      },
                    )),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Feature Toggles
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Detection Features', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      title: const Text('Real-time Updates'),
                      subtitle: const Text('Get updates during scanning'),
                      value: _config.enableRealtimeUpdates,
                      onChanged: (value) {
                        setState(() {
                          _config = _config.copyWith(enableRealtimeUpdates: value);
                        });
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Detect Furniture'),
                      subtitle: const Text('Include furniture in scan results'),
                      value: _config.detectFurniture,
                      onChanged: (value) {
                        setState(() {
                          _config = _config.copyWith(detectFurniture: value);
                        });
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Detect Doors'),
                      subtitle: const Text('Include doors in scan results'),
                      value: _config.detectDoors,
                      onChanged: (value) {
                        setState(() {
                          _config = _config.copyWith(detectDoors: value);
                        });
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Detect Windows'),
                      subtitle: const Text('Include windows in scan results'),
                      value: _config.detectWindows,
                      onChanged: (value) {
                        setState(() {
                          _config = _config.copyWith(detectWindows: value);
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            // Preset Buttons
            const SizedBox(height: 16),
            Text('Quick Presets', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _config = const ScanConfiguration.fast();
                    });
                  },
                  child: const Text('Fast'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _config = const ScanConfiguration.accurate();
                    });
                  },
                  child: const Text('Accurate'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _config = const ScanConfiguration.minimal();
                    });
                  },
                  child: const Text('Minimal'),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onConfigurationChanged(_config);
            Navigator.of(context).pop();
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
}