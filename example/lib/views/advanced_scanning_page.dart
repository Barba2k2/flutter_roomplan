import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roomplan_flutter/roomplan_flutter.dart';

import 'package:example/viewmodels/advanced_scanning_view_model.dart';
import 'package:example/widgets/advanced_action_buttons.dart';
import 'package:example/widgets/advanced_compatibility_notice.dart';
import 'package:example/widgets/advanced_configuration_card.dart';
import 'package:example/widgets/advanced_statistics_card.dart';
import 'package:example/widgets/advanced_status_card.dart';
import 'package:example/widgets/scan_configuration_dialog.dart';
import 'package:example/widgets/scan_results_dialog.dart';

/// Advanced scanning page. Renders [AdvancedScanningViewModel] state and
/// delegates user actions back to the view model. No business logic lives in
/// this widget tree.
class AdvancedScanningPage extends StatelessWidget {
  const AdvancedScanningPage({super.key});

  Future<void> _showConfigurationDialog(BuildContext context) async {
    final viewModel = context.read<AdvancedScanningViewModel>();
    await showDialog<void>(
      context: context,
      builder: (_) => ScanConfigurationDialog(
        currentConfig: viewModel.selectedConfig,
        onConfigurationChanged: viewModel.updateConfiguration,
      ),
    );
  }

  Future<void> _showResultsDialog(
    BuildContext context,
    ScanResult result,
    MeasurementUnit unit,
  ) {
    return showDialog<void>(
      context: context,
      builder: (_) => ScanResultsDialog(result: result, unit: unit),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Advanced Room Scanning'),
        actions: [
          Consumer<AdvancedScanningViewModel>(
            builder: (context, viewModel, _) {
              if (!viewModel.isSupported) return const SizedBox.shrink();
              final isMetric =
                  viewModel.selectedUnit == MeasurementUnit.metric;
              return IconButton(
                icon: Icon(
                  isMetric ? Icons.straighten : Icons.architecture,
                ),
                tooltip:
                    'Switch to ${isMetric ? 'Imperial' : 'Metric'} units',
                onPressed: viewModel.toggleUnit,
              );
            },
          ),
          Consumer<AdvancedScanningViewModel>(
            builder: (context, viewModel, _) {
              return IconButton(
                icon: const Icon(Icons.settings),
                onPressed: viewModel.isSupported && !viewModel.isScanning
                    ? () => _showConfigurationDialog(context)
                    : null,
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Consumer<AdvancedScanningViewModel>(
          builder: (context, viewModel, _) {
            final result = viewModel.currentResult;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AdvancedStatusCard(
                  statusMessage: viewModel.statusMessage,
                  isScanning: viewModel.isScanning,
                  scanDuration: viewModel.scanDuration,
                ),
                if (viewModel.isSupported) ...[
                  const SizedBox(height: 16),
                  AdvancedStatisticsCard(
                    wallsDetected: viewModel.wallsDetected,
                    objectsDetected: viewModel.objectsDetected,
                    doorsDetected: viewModel.doorsDetected,
                    windowsDetected: viewModel.windowsDetected,
                    unit: viewModel.selectedUnit,
                    currentResult: result,
                  ),
                  const SizedBox(height: 16),
                  AdvancedConfigurationCard(
                    configuration: viewModel.selectedConfig,
                    unit: viewModel.selectedUnit,
                  ),
                ],
                const Spacer(),
                if (viewModel.isSupported)
                  AdvancedActionButtons(
                    isScanning: viewModel.isScanning,
                    hasResult: result != null,
                    onStartScan: viewModel.startScan,
                    onStopScan: viewModel.stopScan,
                    onShowResults: () {
                      if (result != null) {
                        _showResultsDialog(
                          context,
                          result,
                          viewModel.selectedUnit,
                        );
                      }
                    },
                  )
                else
                  const AdvancedCompatibilityNotice(),
              ],
            );
          },
        ),
      ),
    );
  }
}
