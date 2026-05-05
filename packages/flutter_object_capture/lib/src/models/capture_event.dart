import 'capture_state.dart';

/// A snapshot of progress emitted by an active object-capture or
/// photogrammetry session.
///
/// Events are delivered through [FlutterObjectCapture.events] while a session
/// is running.
class CaptureEvent {
  const CaptureEvent({
    required this.state,
    this.progress,
    this.message,
    this.error,
  });

  /// Current lifecycle state of the underlying iOS session.
  final CaptureState state;

  /// Progress in the range `[0.0, 1.0]`, when meaningful.
  ///
  /// Null when the current [state] does not produce a progress value
  /// (e.g. while detecting the object).
  final double? progress;

  /// Optional human-readable message describing the current step.
  final String? message;

  /// Populated when [state] is [CaptureState.failed].
  final Object? error;

  @override
  String toString() =>
      'CaptureEvent(state: $state, progress: $progress, message: $message, '
      'error: $error)';
}
