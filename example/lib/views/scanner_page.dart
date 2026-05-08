import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roomplan_flutter/roomplan_flutter.dart';

import 'package:example/viewmodels/results_view_model.dart';
import 'package:example/viewmodels/scanner_view_model.dart';
import 'package:example/views/results_page.dart';
import 'package:example/widgets/scan_data_card.dart';
import 'package:example/widgets/scanner_card.dart';
import 'package:example/widgets/scanner_instructions_card.dart';

/// Comprehensive RoomPlan example. Hosts no business logic of its own — all
/// scan state lives in [ScannerViewModel] (provided at the app root).
class ScannerPage extends StatelessWidget {
  const ScannerPage({super.key});

  Future<void> _runScan(BuildContext context) async {
    final viewModel = context.read<ScannerViewModel>();
    await viewModel.startScanning();
    final result = viewModel.currentScanResult;
    if (result == null) return;
    if (!context.mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => ResultsViewModel(scanResult: result),
          child: const ResultsPage(),
        ),
      ),
    );
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
        child: Consumer<ScannerViewModel>(
          builder: (context, viewModel, _) {
            final ScanResult? result = viewModel.currentScanResult;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ScannerCard(
                  scanStatus: viewModel.scanStatus,
                  isScanning: viewModel.isScanning,
                  onStartScanning: () => _runScan(context),
                ),
                const SizedBox(height: 20),
                if (result != null) ScanDataCard(scanResult: result),
                const Spacer(),
                const ScannerInstructionsCard(),
              ],
            );
          },
        ),
      ),
    );
  }
}
