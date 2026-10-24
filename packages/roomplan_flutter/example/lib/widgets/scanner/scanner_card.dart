import 'package:flutter/material.dart';

/// The main scanner interface card.
class ScannerCard extends StatelessWidget {
  final String status;
  final bool isScanning;
  final VoidCallback onStartScan;

  const ScannerCard({
    super.key,
    required this.status,
    required this.isScanning,
    required this.onStartScan,
  });

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
              status,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isScanning ? null : onStartScan,
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
