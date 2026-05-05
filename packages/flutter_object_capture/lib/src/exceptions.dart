/// Base exception for any failure raised by `flutter_object_capture`.
class ObjectCaptureException implements Exception {
  const ObjectCaptureException(this.message, {this.code, this.details});

  /// Human-readable description of the failure.
  final String message;

  /// Machine-readable error code propagated from the iOS side, when available.
  final String? code;

  /// Optional structured payload accompanying the error.
  final Object? details;

  @override
  String toString() {
    final buffer = StringBuffer('ObjectCaptureException');
    if (code != null) buffer.write('($code)');
    buffer.write(': $message');
    if (details != null) buffer.write(' (details: $details)');
    return buffer.toString();
  }
}

/// Thrown when the running device does not meet Object Capture requirements
/// (iOS version, A14+ chip, LiDAR availability).
class ObjectCaptureUnsupportedException extends ObjectCaptureException {
  const ObjectCaptureUnsupportedException([
    String message =
        'Object Capture is not available on this device. Requires iOS 17.0+ '
            'and an A14 Bionic or newer.',
  ]) : super(message, code: 'unsupported');
}
