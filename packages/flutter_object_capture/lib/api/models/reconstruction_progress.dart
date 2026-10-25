part of 'reconstruction_event.dart';

/// Reconstruction progress. [fraction] is within 0..1.
class ReconstructionProgress extends ReconstructionEvent {
  final double fraction;
  final Duration? estimatedRemaining;

  const ReconstructionProgress({
    required this.fraction,
    this.estimatedRemaining,
  });

  @override
  bool operator ==(Object other) =>
      other is ReconstructionProgress &&
      other.fraction == fraction &&
      other.estimatedRemaining == estimatedRemaining;

  @override
  int get hashCode => Object.hash(fraction, estimatedRemaining);
}
