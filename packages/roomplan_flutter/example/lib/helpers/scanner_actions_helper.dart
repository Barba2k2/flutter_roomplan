import 'package:example/viewmodels/results_view_model.dart';
import 'package:example/viewmodels/scanner_view_model.dart';
import 'package:example/views/results_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roomplan_flutter/roomplan_flutter.dart';

class ScannerActionsHelper {
  ScannerActionsHelper._();

  /// Runs a scan; the result is shown on the scanner page.
  static Future<void> startScan(ScannerViewModel viewModel) {
    return viewModel.startScanning();
  }

  /// Opens the detailed results page for a finished scan.
  static Future<void> openResults(BuildContext context, ScanResult result) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider(
          create: (context) => ResultsViewModel(scanResult: result),
          child: const ResultsPage(),
        ),
      ),
    );
  }
}
