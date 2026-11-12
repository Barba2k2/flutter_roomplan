import 'package:flutter_object_capture/flutter_object_capture.dart';

/// What the device reports about Object Capture.
class SupportInfo {
  final bool supported;
  final ObjectCaptureLimits? limits;

  const SupportInfo({required this.supported, this.limits});
}
