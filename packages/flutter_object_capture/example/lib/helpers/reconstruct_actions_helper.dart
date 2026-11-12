import 'dart:developer';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../controllers/reconstruct_controller.dart';
import '../controllers/result_controller.dart';
import '../strings/app_strings.dart';
import '../views/result_page.dart';

class ReconstructActionsHelper {
  ReconstructActionsHelper._();

  static Future<void> pickFolder(ReconstructController controller) async {
    final path = await FilePicker.getDirectoryPath(
      dialogTitle: AppStrings.chooseFolder,
    );
    log('folder picked: $path', name: 'ReconstructActionsHelper');
    if (path != null) controller.setImagesDirectory(path);
  }

  /// Starts the job and opens the result page when it finishes.
  static Future<void> start(
    BuildContext context,
    ReconstructController controller,
  ) async {
    await controller.start();
    final result = controller.result;
    if (result == null || !context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ResultPage(controller: ResultController(result)),
      ),
    );
  }
}
