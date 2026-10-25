import 'package:flutter/foundation.dart';
import 'package:flutter_object_capture/flutter_object_capture.dart';

/// Detail levels the current platform can reconstruct.
class SupportedDetailsHelper {
  SupportedDetailsHelper._();

  /// macOS supports every level; iOS only `reduced`.
  static List<ObjectDetail> forCurrentPlatform() {
    return defaultTargetPlatform == TargetPlatform.macOS
        ? ObjectDetail.values
        : const [ObjectDetail.reduced];
  }
}
