import 'package:flutter/material.dart';
import '../controllers/reconstruct_controller.dart';
import '../views/reconstruct_page.dart';

class SupportActionsHelper {
  SupportActionsHelper._();

  static Future<void> openReconstruct(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) {
          return ReconstructPage(
            controller: ReconstructController(),
          );
        },
      ),
    );
  }
}
