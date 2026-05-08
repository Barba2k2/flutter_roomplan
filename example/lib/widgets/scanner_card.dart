import 'package:flutter/material.dart';

/// Top card on the scanner page: status text, a primary action button, and
/// an optional progress indicator while a scan is running.
class ScannerCard extends StatelessWidget {
  const ScannerCard({
    super.key,
    required this.scanStatus,
    required this.isScanning,
    required this.onStartScanning,
  });

  final String scanStatus;
  final bool isScanning;
  final VoidCallback onStartScanning;

  @override
  Widget build(BuildContext context) {
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
              scanStatus,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isScanning ? null : onStartScanning,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  isScanning ? 'Scanning...' : 'Start Room Scan',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
            if (isScanning) ...[
              const SizedBox(height: 20),
              const CircularProgressIndicator(),
            ],
          ],
        ),
      ),
    );
  }
}
