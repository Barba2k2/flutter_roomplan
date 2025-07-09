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
    // Starting the scan is a non-blocking call. The view is presented natively.
    await _roomPlanScanner.startScanning();
    // `finishScanning` returns a `Future` that completes when the native view is dismissed.
    final result = await _roomPlanScanner.finishScanning();
    setState(() {
      _isScanning = false;
    });

    if (result != null && mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ResultsPage(scanResult: result),
        ),
      );
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
            ? const CircularProgressIndicator()
            : const Text("Scan finished. Awaiting result..."),
      ),
    );
  }
}
