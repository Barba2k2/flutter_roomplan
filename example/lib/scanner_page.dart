import 'package:flutter/material.dart';
import 'package:roomplan_flutter/roomplan_flutter.dart';

import 'results_page.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  String _scanStatus = 'Ready to scan';
  bool _isScanning = false;
  late final RoomPlanScanner _roomPlanScanner;

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

  void _startScanning() async {
    setState(() {
      _isScanning = true;
      _scanStatus = 'Scanning...';
    });

    try {
      // Listen to real-time updates from ScanResult objects
      _roomPlanScanner.onScanResult.listen((scanResult) {
        if (scanResult != null) {
          setState(() {
            _scanStatus = 'Scanning... (receiving updates)';
          });
        }
      });

      final result = await _roomPlanScanner.startScan();

      if (result != null) {
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
          _scanStatus = 'Scan cancelled';
        });
      }
    } catch (e) {
      setState(() {
        _scanStatus = 'Error: $e';
      });
    } finally {
      setState(() {
        _isScanning = false;
        if (_scanStatus != 'Error: $_scanStatus' &&
            _scanStatus != 'Scan cancelled') {
          _scanStatus = 'Scan completed';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Room Scanner'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.view_in_ar,
              size: 100,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 20),
            Text(
              _scanStatus,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _isScanning ? null : _startScanning,
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
              child: Text(
                _isScanning ? 'Scanning...' : 'Start Room Scan',
                style: const TextStyle(fontSize: 18),
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
}
