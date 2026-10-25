part of 'reconstruction_event.dart';

/// A non-fatal milestone, see [ReconstructionNoticeType].
class ReconstructionNotice extends ReconstructionEvent {
  final ReconstructionNoticeType type;

  const ReconstructionNotice({required this.type});

  @override
  bool operator ==(Object other) =>
      other is ReconstructionNotice && other.type == type;

  @override
  int get hashCode => type.hashCode;
}
