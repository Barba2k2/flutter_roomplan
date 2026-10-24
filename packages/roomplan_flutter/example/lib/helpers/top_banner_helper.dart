import 'package:example/widgets/feedback/top_banner.dart';
import 'package:flutter/material.dart';

class TopBannerHelper {
  TopBannerHelper._();

  static OverlayEntry? _current;

  static void show(
    BuildContext context, {
    required String message,
    required IconData icon,
  }) {
    dismiss();
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => TopBanner(
        message: message,
        icon: icon,
        onDismissed: () {
          if (_current == entry) dismiss();
        },
      ),
    );
    _current = entry;
    Overlay.of(context).insert(entry);
  }

  static void dismiss() {
    _current?.remove();
    _current?.dispose();
    _current = null;
  }
}
