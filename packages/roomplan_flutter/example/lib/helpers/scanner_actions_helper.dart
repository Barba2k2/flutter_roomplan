import 'package:example/viewmodels/results_view_model.dart';
import 'package:example/viewmodels/scanner_view_model.dart';
import 'package:example/views/results_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ScannerActionsHelper {
  ScannerActionsHelper._();

  /// Runs a scan and opens the detailed results page when one was produced.
  static Future<void> startScan(
    BuildContext context,
    ScannerViewModel viewModel,
  ) async {
    final result = await viewModel.startScanning();
    if (result == null || !context.mounted) return;
    await Navigator.push(
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
