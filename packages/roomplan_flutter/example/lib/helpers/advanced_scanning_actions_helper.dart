import 'package:example/helpers/top_banner_helper.dart';
import 'package:example/viewmodels/advanced_scanning_view_model.dart';
import 'package:example/widgets/advanced_scanning/scan_results_dialog.dart';
import 'package:flutter/material.dart';
import 'package:roomplan_flutter/roomplan_flutter.dart';

class AdvancedScanningActionsHelper {
  AdvancedScanningActionsHelper._();

  static void showResultsDialog(
    BuildContext context,
    ScanResult result,
    MeasurementUnit unit,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return ScanResultsDialog(
          result: result,
          unit: unit,
        );
      },
    );
  }

  static void toggleUnit(
    BuildContext context,
    AdvancedScanningViewModel vm,
  ) {
    vm.toggleUnit();
    final isMetric = vm.selectedUnit == MeasurementUnit.metric;
    TopBannerHelper.show(
      context,
      message: 'Units changed to ${isMetric ? 'Metric' : 'Imperial'}',
      icon: isMetric ? Icons.straighten_rounded : Icons.architecture_rounded,
    );
  }
}
