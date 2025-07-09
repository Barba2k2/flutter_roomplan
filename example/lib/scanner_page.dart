import 'package:flutter/material.dart';
import 'package:roomplan_flutter/roomplan_flutter.dart';

/// A page that demonstrates how to use the `RoomPlanScanner`.
///
/// It provides a simple interface to start and stop a room scan,
/// and displays the result of the scan.
class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  late final RoomPlanScanner _roomPlanScanner;

  /// The result of the last completed scan. '-' indicates no result yet.
  String _scanResult = "-";

  /// Whether a scan is currently in progress.
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _roomPlanScanner = RoomPlanScanner();
  }

  @override
  void dispose() {
    _roomPlanScanner.dispose();
    super.dispose();
  }

  /// Starts a new room scan session.
  ///
  /// Sets the state to `_isScanning = true` and waits for the user to
  /// complete the scan. The result is then stored in `_scanResult`.
  Future<void> _startScan() async {
    setState(() {
      _isScanning = true;
      _scanResult = "-";
    });
    await _roomPlanScanner.startScanning();
    final result = await _roomPlanScanner.finishScanning();
    setState(() {
      _scanResult = result?.toString() ?? "No result";
      _isScanning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RoomPlan Scan'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (_isScanning)
            const Center(
              child: CircularProgressIndicator(),
            ),
          Expanded(
            child: SingleChildScrollView(
              child: Text(_scanResult),
            ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _startScan,
        tooltip: 'Start Scan',
        child: const Icon(Icons.scanner),
      ),
    );
  }
}
