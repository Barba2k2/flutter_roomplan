import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:example/viewmodels/object_capture_view_model.dart';
import 'package:example/widgets/error_card.dart';
import 'package:example/widgets/object_capture_event_card.dart';
import 'package:example/widgets/object_capture_result_card.dart';
import 'package:example/widgets/object_capture_support_card.dart';
import 'package:example/widgets/photogrammetry_result_card.dart';

/// Demo page for `flutter_object_capture`. All state and side-effects live in
/// [ObjectCaptureViewModel]; this widget purely renders that state.
class ObjectCapturePage extends StatelessWidget {
  const ObjectCapturePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Object Capture')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Consumer<ObjectCaptureViewModel>(
          builder: (context, viewModel, _) {
            return ListView(
              children: [
                ObjectCaptureSupportCard(isSupported: viewModel.isSupported),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: viewModel.canCapture ? viewModel.capture : null,
                  icon: const Icon(Icons.center_focus_strong),
                  label: const Text('Capture object'),
                ),
                const SizedBox(height: 8),
                FilledButton.tonalIcon(
                  onPressed:
                      viewModel.canReconstruct ? viewModel.reconstruct : null,
                  icon: const Icon(Icons.view_in_ar),
                  label: const Text('Reconstruct USDZ'),
                ),
                if (viewModel.isBusy) ...[
                  const SizedBox(height: 16),
                  const Center(child: CircularProgressIndicator()),
                ],
                const SizedBox(height: 24),
                if (viewModel.latestEvent != null)
                  ObjectCaptureEventCard(event: viewModel.latestEvent!),
                if (viewModel.captureResult != null)
                  ObjectCaptureResultCard(result: viewModel.captureResult!),
                if (viewModel.reconstructionResult != null)
                  PhotogrammetryResultCard(
                    result: viewModel.reconstructionResult!,
                  ),
                if (viewModel.errorMessage != null)
                  ErrorCard(message: viewModel.errorMessage!),
              ],
            );
          },
        ),
      ),
    );
  }
}
