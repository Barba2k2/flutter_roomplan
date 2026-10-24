import 'package:example/helpers/advanced_scanning_actions_helper.dart';
import 'package:example/helpers/top_banner_helper.dart';
import 'package:example/viewmodels/advanced_scanning_view_model.dart';
import 'package:example/widgets/advanced_scanning/status_card.dart';
import 'package:example/widgets/advanced_scanning/statistics_card.dart';
import 'package:example/widgets/advanced_scanning/unsupported_card.dart';

import 'package:flutter/material.dart';
import 'package:roomplan_flutter/roomplan_flutter.dart';

/// Advanced scanning page demonstrating live statistics and unit switching.
class AdvancedScanningPage extends StatefulWidget {
  const AdvancedScanningPage({super.key});

  @override
  State<AdvancedScanningPage> createState() => _AdvancedScanningPageState();
}

class _AdvancedScanningPageState extends State<AdvancedScanningPage> {
  late final AdvancedScanningViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = AdvancedScanningViewModel();
  }

  @override
  void dispose() {
    TopBannerHelper.dismiss();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, child) {
        final vm = _viewModel;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Advanced Room Scanning'),
            actions: [
              if (vm.isSupported)
                IconButton(
                  icon: Icon(
                    vm.selectedUnit == MeasurementUnit.metric
                        ? Icons.straighten
                        : Icons.architecture,
                  ),
                  tooltip:
                      'Switch to ${vm.selectedUnit == MeasurementUnit.metric ? 'Imperial' : 'Metric'} units',
                  onPressed: () =>
                      AdvancedScanningActionsHelper.toggleUnit(context, vm),
                ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                StatusCard(
                  statusMessage: vm.statusMessage,
                  isScanning: vm.isScanning,
                  scanDuration: vm.scanDuration,
                ),
                if (vm.isSupported) ...[
                  const SizedBox(height: 16),
                  StatisticsCard(
                    wallsDetected: vm.wallsDetected,
                    objectsDetected: vm.objectsDetected,
                    doorsDetected: vm.doorsDetected,
                    windowsDetected: vm.windowsDetected,
                    currentResult: vm.currentResult,
                    unit: vm.selectedUnit,
                  ),
                ],
                const Spacer(),
                if (vm.isSupported) ...[
                  if (vm.isScanning)
                    ElevatedButton.icon(
                      onPressed: vm.stopScan,
                      icon: const Icon(Icons.stop),
                      label: const Text('Stop Scanning'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: vm.startScan,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Start Room Scan'),
                    ),
                  const SizedBox(height: 8),
                  if (vm.currentResult != null)
                    OutlinedButton.icon(
                      onPressed: () {
                        AdvancedScanningActionsHelper.showResultsDialog(
                          context,
                          vm.currentResult!,
                          vm.selectedUnit,
                        );
                      },
                      icon: const Icon(Icons.info),
                      label: const Text('View Detailed Results'),
                    ),
                ] else
                  const UnsupportedCard(),
              ],
            ),
          ),
        );
      },
    );
  }
}
