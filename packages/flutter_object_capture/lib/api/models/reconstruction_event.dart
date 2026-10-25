import 'reconstruction_notice_type.dart';

part 'reconstruction_completed.dart';
part 'reconstruction_notice.dart';
part 'reconstruction_progress.dart';
part 'reconstruction_sample_issue.dart';

/// An event emitted while a reconstruction runs.
///
/// Subtypes: [ReconstructionProgress], [ReconstructionSampleIssue],
/// [ReconstructionNotice] and the terminal [ReconstructionCompleted].
/// They are `part` files because a sealed class's subtypes must share its
/// library.
sealed class ReconstructionEvent {
  const ReconstructionEvent();
}
