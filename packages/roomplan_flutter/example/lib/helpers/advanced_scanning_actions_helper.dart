import 'package:example/viewmodels/advanced_scanning_view_model.dart';
import 'package:example/widgets/advanced_scanning/configuration_dialog.dart';
import 'package:example/widgets/advanced_scanning/scan_results_dialog.dart';
import 'package:flutter/material.dart';
import 'package:roomplan_flutter/roomplan_flutter.dart';

class AdvancedScanningActionsHelper {
  AdvancedScanningActionsHelper._();

  static void showConfigurationDialog(
    BuildContext context,
    AdvancedScanningViewModel viewModel,
  ) {
    showDialog(
      context: context,
      builder: (context) => ConfigurationDialog(
        currentConfig: viewModel.selectedConfig,
        onConfigurationChanged: viewModel.setConfiguration,
      ),
    );
  }

  static void showResultsDialog(
    BuildContext context,
    ScanResult result,
    MeasurementUnit unit,
  ) {
    showDialog(
      context: context,
      builder: (context) => ScanResultsDialog(result: result, unit: unit),
    );
  }
}
