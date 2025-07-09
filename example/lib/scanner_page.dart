import 'package:example/results_page.dart';
import 'package:flutter/material.dart';
import 'package:roomplan_flutter/roomplan_flutter.dart';

/// A page that demonstrates how to use the `RoomPlanScanner`.
///
/// It provides a simple interface to start a room scan and
/// navigates to the results page upon completion.
class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  late final RoomPlanScanner _roomPlanScanner;

  /// Whether a scan is currently in progress.
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _roomPlanScanner = RoomPlanScanner();
    _startScan();
  }

  @override
  void dispose() {
    _roomPlanScanner.dispose();
    super.dispose();
  }

  /// Starts a new room scan session.
  ///
  /// Sets the state to `_isScanning = true` and waits for the user to
  /// complete the scan. Then navigates to the results page.
  Future<void> _startScan() async {
    setState(() {
      _isScanning = true;
    });

    // `startScanning` now returns a `Future` that completes with the final result
    // when the native view is dismissed.
    final result = await _roomPlanScanner.startScanning();

    setState(() {
      _isScanning = false;
    });

    if (result != null && mounted) {
      // Use pushReplacement to avoid building up a stack of pages.
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => ResultsPage(scanResult: result),
        ),
      );
    } else if (mounted) {
      // If the result is null (e.g., user cancelled), just go back to the previous page.
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RoomPlan Scan'),
      ),
      body: Center(
        child: _isScanning
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("Scanning in progress..."),
                ],
              )
            : const Text("Scan finished. Awaiting result..."),
      ),
    );
  }
}
