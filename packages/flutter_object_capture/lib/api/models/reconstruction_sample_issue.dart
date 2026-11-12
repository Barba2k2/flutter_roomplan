part of 'reconstruction_event.dart';

/// An input image was rejected (`invalidSample`) or skipped (`skippedSample`).
class ReconstructionSampleIssue extends ReconstructionEvent {
  final int sampleId;
  final String? reason;
  final bool skipped;

  const ReconstructionSampleIssue({
    required this.sampleId,
    this.reason,
    this.skipped = false,
  });

  @override
  bool operator ==(Object other) =>
      other is ReconstructionSampleIssue &&
      other.sampleId == sampleId &&
      other.reason == reason &&
      other.skipped == skipped;

  @override
  int get hashCode => Object.hash(sampleId, reason, skipped);
}
