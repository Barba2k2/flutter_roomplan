import 'dart:async';

import 'package:flutter/material.dart';
import '../controllers/reconstruct_controller.dart';
import '../helpers/reconstruct_actions_helper.dart';
import '../strings/app_strings.dart';
import '../widgets/detail_selector/detail_selector.dart';
import '../widgets/error_banner/error_banner.dart';
import '../widgets/event_log_tile/event_log_tile.dart';
import '../widgets/progress_card/progress_card.dart';

class ReconstructPage extends StatefulWidget {
  const ReconstructPage({super.key, required this.controller});

  final ReconstructController controller;

  @override
  State<ReconstructPage> createState() => _ReconstructPageState();
}

class _ReconstructPageState extends State<ReconstructPage> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.controller.form.outputName,
    );
    unawaited(widget.controller.loadCapabilities());
  }

  @override
  void dispose() {
    _nameController.dispose();
    widget.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.reconstructTitle)),
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final running = controller.isRunning;
          final busy = controller.isBusy;
          final folder = controller.form.imagesDirectory;
          final errorMessage = controller.errorMessage;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(folder ?? AppStrings.noFolderChosen),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: busy
                    ? null
                    : () => ReconstructActionsHelper.pickFolder(controller),
                child: Text(
                  folder == null
                      ? AppStrings.chooseFolder
                      : AppStrings.changeFolder,
                ),
              ),
              if (controller.isGuidedCaptureAvailable) ...[
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: busy ? null : controller.capturePhotos,
                  child: const Text(AppStrings.capturePhotos),
                ),
              ],
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                enabled: !running,
                onChanged: controller.setOutputName,
                decoration: const InputDecoration(
                  labelText: AppStrings.outputNameLabel,
                  hintText: AppStrings.outputNameHint,
                  helperText: AppStrings.outputNameHelper,
                  border: OutlineInputBorder(),
                ),
              ),
              if (controller.showDetailSelector) ...[
                const SizedBox(height: 16),
                DetailSelector(
                  details: controller.supportedDetails,
                  selected: controller.form.detail,
                  onChanged: running ? null : controller.setDetail,
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: busy
                          ? null
                          : () {
                              ReconstructActionsHelper.start(
                                context,
                                controller,
                              );
                            },
                      child: const Text(AppStrings.start),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: running ? controller.cancel : null,
                      child: const Text(AppStrings.cancel),
                    ),
                  ),
                ],
              ),
              if (errorMessage != null) ...[
                const SizedBox(height: 16),
                ErrorBanner(message: errorMessage),
              ],
              if (running) ...[
                const SizedBox(height: 16),
                ProgressCard(
                  fraction: controller.progress,
                  remaining: controller.remaining,
                ),
              ],
              const SizedBox(height: 16),
              Text(
                AppStrings.eventsTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (controller.events.isEmpty) const Text(AppStrings.eventsEmpty),
              for (final event in controller.events) EventLogTile(event: event),
            ],
          );
        },
      ),
    );
  }
}
