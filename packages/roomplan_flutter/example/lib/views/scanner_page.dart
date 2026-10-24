import 'package:example/helpers/scanner_actions_helper.dart';
import 'package:example/viewmodels/scanner_view_model.dart';
import 'package:example/widgets/scanner/instructions_card.dart';
import 'package:example/widgets/scanner/scan_data_card.dart';
import 'package:example/widgets/scanner/scanner_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// A comprehensive example demonstrating how to use the RoomPlanScanner.
///
/// This widget shows:
/// - How to listen to real-time scan updates
/// - How to start and handle scan results
/// - How to access room data (walls, doors, windows, objects)
class ScannerPage extends StatelessWidget {
  const ScannerPage({super.key});

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
          builder: (context, viewModel, child) {
            final result = viewModel.currentScanResult;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ScannerCard(
                  status: viewModel.scanStatus,
                  isScanning: viewModel.isScanning,
                  onStartScan: () {
                    ScannerActionsHelper.startScan(context, viewModel);
                  },
                ),
                const SizedBox(height: 20),
                if (result != null) ScanDataCard(result: result),
                const Spacer(),
                const InstructionsCard(),
              ],
            );
          },
        ),
      ),
    );
  }
}
