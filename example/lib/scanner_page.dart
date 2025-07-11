import 'dart:async';
import 'package:flutter/material.dart';
import 'package:roomplan_flutter/roomplan_flutter.dart';

import 'results_page.dart';

/// A comprehensive example demonstrating how to use the RoomPlanScanner.
///
/// This widget shows:
/// - How to initialize the RoomPlanScanner
/// - How to listen to real-time scan updates
/// - How to start and handle scan results
/// - How to access room data (walls, doors, windows, objects)
/// - Proper resource management and error handling
class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  // Core scanner instance
  late final RoomPlanScanner _roomPlanScanner;

  // Stream subscription for real-time updates
  StreamSubscription<ScanResult?>? _scanSubscription;

  // UI state variables
  String _scanStatus = 'Ready to scan';
  bool _isScanning = false;
  ScanResult? _currentScanResult;

  @override
  void initState() {
    super.initState();

    // Initialize the RoomPlan scanner
    _roomPlanScanner = RoomPlanScanner();

    // Listen to real-time scan updates
    // This stream emits ScanResult objects during the scanning process
    _scanSubscription = _roomPlanScanner.onScanResult.listen((scanResult) {
      if (scanResult != null) {
        setState(() {
          _currentScanResult = scanResult;
          _scanStatus =
              'Scanning... (${scanResult.room.walls.length} walls detected)';
        });
      }
    });
  }

  @override
  void dispose() {
    // Important: Always cancel subscriptions and dispose resources
    _scanSubscription?.cancel();
    _roomPlanScanner.dispose();
    super.dispose();
  }

  /// Starts a new room scanning session
  Future<void> _startScanning() async {
    setState(() {
      _isScanning = true;
      _scanStatus = 'Starting scan...';
      _currentScanResult = null;
    });

    try {
      // Start the room scanning session
      // This will open the native RoomPlan interface
      final result = await _roomPlanScanner.startScan();

      if (result != null) {
        setState(() {
          _currentScanResult = result;
          _scanStatus = 'Scan completed successfully!';
        });

        // Navigate to detailed results page
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ResultsPage(scanResult: result),
            ),
          );
        }
      } else {
        setState(() {
          _scanStatus = 'Scan was cancelled by the user';
        });
      }
    } catch (e) {
      // Handle any errors that might occur during scanning
      setState(() {
        _scanStatus = 'Error during scan: $e';
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
            // Main scanner interface
            _buildScannerCard(),

            const SizedBox(height: 20),

            // Real-time scan data display
            if (_currentScanResult != null) _buildScanDataCard(),

            const Spacer(),

            // Instructions for users
            _buildInstructionsCard(),
          ],
        ),
      ),
    );
  }

  /// Builds the main scanner interface card
  Widget _buildScannerCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
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
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isScanning ? null : _startScanning,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  _isScanning ? 'Scanning...' : 'Start Room Scan',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
            if (_isScanning) ...[
              const SizedBox(height: 20),
              const CircularProgressIndicator(),
            ],
          ],
        ),
      ),
    );
  }

  /// Builds the real-time scan data display card
  Widget _buildScanDataCard() {
    final result = _currentScanResult!;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics_outlined,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Real-time Scan Data',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Room structure data
            _buildDataRow(
                'Walls', '${result.room.walls.length}', Icons.square_outlined),
            _buildDataRow(
                'Doors', '${result.room.doors.length}', Icons.door_front_door),
            _buildDataRow(
                'Windows', '${result.room.windows.length}', Icons.window),
            _buildDataRow('Openings', '${result.room.openings.length}',
                Icons.open_in_new),
            _buildDataRow(
                'Objects', '${result.room.objects.length}', Icons.chair),

            const Divider(),

            // Device and scan metadata
            _buildDataRow('LiDAR Available',
                result.metadata.hasLidar ? 'Yes' : 'No', Icons.radar),
            _buildDataRow(
                'Device', result.metadata.deviceModel, Icons.phone_iphone),

            // Room dimensions (if available)
            if (result.room.dimensions != null)
              _buildDataRow(
                'Room Size',
                '${result.room.dimensions!.width.toStringAsFixed(1)}m × ${result.room.dimensions!.length.toStringAsFixed(1)}m',
                Icons.straighten,
              ),
          ],
        ),
      ),
    );
  }

  /// Builds the instructions card
  Widget _buildInstructionsCard() {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                const Text(
                  'How to Use:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text('1. Tap "Start Room Scan" to begin'),
            const Text('2. Point your device around the room slowly'),
            const Text('3. Follow the on-screen guidance from RoomPlan'),
            const Text('4. Tap "Done" when the room is fully captured'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .outline
                      .withValues(alpha: 0.5),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_outlined, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Requires iOS 16+ and a device with LiDAR sensor (iPhone 12 Pro or newer Pro models, iPad Pro)',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Helper method to build consistent data rows
  Widget _buildDataRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(label),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
