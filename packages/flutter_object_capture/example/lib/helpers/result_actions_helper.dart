import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../controllers/result_controller.dart';

class ResultActionsHelper {
  ResultActionsHelper._();

  static Future<void> share(
    BuildContext context,
    ResultController controller,
  ) async {
    final box = context.findRenderObject() as RenderBox?;
    final origin =
        box == null ? null : box.localToGlobal(Offset.zero) & box.size;
    try {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(controller.info.path)],
          sharePositionOrigin: origin,
        ),
      );
    } catch (error) {
      log('share failed: $error', name: 'ResultActionsHelper');
      controller.reportShareFailed();
    }
  }
}
