import 'dart:async';
import 'package:flutter/material.dart';
import 'package:roomplan_flutter/roomplan_flutter.dart';
import 'package:example/src/home_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RoomPlan Flutter Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const RoomScannerExample(),
    );
  }
}

/// A complete example demonstrating how to use the RoomPlanScanner.
///
/// This widget shows:
/// - How to initialize the RoomPlanScanner
/// - How to listen to real-time scan updates
/// - How to start and handle scan results
/// - How to access room data, walls, doors, windows, and objects
class RoomScannerExample extends StatefulWidget {
  const RoomScannerExample({super.key});

  @override
  State<RoomScannerExample> createState() => _RoomScannerExampleState();
}

class _RoomScannerExampleState extends State<RoomScannerExample> {
  late final RoomPlanScanner _roomScanner;
  StreamSubscription<ScanResult?>? _scanSubscription;

  String _scanStatus = 'Ready to scan';
  bool _isScanning = false;
  ScanResult? _lastScanResult;

  @override
  void initState() {
    super.initState();

    // Initialize the RoomPlan scanner
    _roomScanner = RoomPlanScanner();

    // Listen to real-time scan updates
    _scanSubscription = _roomScanner.onScanResult.listen((result) {
      if (result != null) {
        setState(() {
          _lastScanResult = result;
          _scanStatus =
              'Scanning... (${result.room.walls.length} walls detected)';
        });
      }
    });
  }

  @override
  void dispose() {
    // Always dispose of resources
    _scanSubscription?.cancel();
    _roomScanner.dispose();
    super.dispose();
  }

  Future<void> _startScan() async {
    setState(() {
      _isScanning = true;
      _scanStatus = 'Starting scan...';
    });

    try {
      // Start the room scanning session
      final result = await _roomScanner.startScan();

      if (result != null) {
        setState(() {
          _lastScanResult = result;
          _scanStatus = 'Scan completed successfully!';
        });

        // Navigate to detailed results page
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const HomePage(),
            ),
          );
        }
      } else {
        setState(() {
          _scanStatus = 'Scan was cancelled';
        });
      }
    } catch (e) {
      setState(() {
        _scanStatus = 'Error: $e';
      });
    } finally {
      setState(() {
        _isScanning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RoomPlan Flutter Example'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Scanner Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.view_in_ar,
                      size: 80,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _scanStatus,
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _isScanning ? null : _startScan,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                        child: Text(
                          _isScanning ? 'Scanning...' : 'Start Room Scan',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    if (_isScanning) ...[
                      const SizedBox(height: 16),
                      const CircularProgressIndicator(),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Real-time Results
            if (_lastScanResult != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Scan Data',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      _buildDataRow(
                          'Walls', '${_lastScanResult!.room.walls.length}'),
                      _buildDataRow(
                          'Doors', '${_lastScanResult!.room.doors.length}'),
                      _buildDataRow(
                          'Windows', '${_lastScanResult!.room.windows.length}'),
                      _buildDataRow(
                          'Objects', '${_lastScanResult!.room.objects.length}'),
                      _buildDataRow(
                          'Has LiDAR', '${_lastScanResult!.metadata.hasLidar}'),
                      if (_lastScanResult!.room.dimensions != null)
                        _buildDataRow(
                          'Dimensions',
                          '${_lastScanResult!.room.dimensions!.width.toStringAsFixed(1)}m × ${_lastScanResult!.room.dimensions!.length.toStringAsFixed(1)}m',
                        ),
                    ],
                  ),
                ),
              ),
            ],

            const Spacer(),

            // Instructions
            Card(
              color: Theme.of(context).colorScheme.surfaceContainerHigh,
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Instructions:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text('1. Tap "Start Room Scan" to begin'),
                    Text('2. Point your device around the room'),
                    Text('3. Follow the on-screen guidance'),
                    Text('4. Tap "Done" when finished'),
                    SizedBox(height: 8),
                    Text(
                      'Note: Requires iOS 16+ and a device with LiDAR sensor',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
