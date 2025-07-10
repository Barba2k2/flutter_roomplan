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
    setState(() => _isScanning = true);
    try {
      final result = await _roomPlanScanner.startScanning();
      if (result == null) {
        if (mounted) Navigator.of(context).pop();
        return;
      }
      if (mounted) {
        await Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => ResultsPage(scanResult: result),
          ),
        );
      }
    } on ScanCancelledException {
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting scan: $e')),
        );
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) {
        setState(() => _isScanning = false);
      }
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
                  Text("Initializing scanner..."),
                ],
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}
