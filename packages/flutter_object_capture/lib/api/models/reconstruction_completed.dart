part of 'reconstruction_event.dart';

/// Terminal event: the USDZ was written. The stream closes after it.
class ReconstructionCompleted extends ReconstructionEvent {
  final String modelPath;
  final int fileSizeBytes;

  const ReconstructionCompleted({
    required this.modelPath,
    required this.fileSizeBytes,
  });

  @override
  bool operator ==(Object other) =>
      other is ReconstructionCompleted &&
      other.modelPath == modelPath &&
      other.fileSizeBytes == fileSizeBytes;

  @override
  int get hashCode => Object.hash(modelPath, fileSizeBytes);
}
