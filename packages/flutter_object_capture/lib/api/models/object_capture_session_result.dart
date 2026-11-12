/// Result of a guided capture: the folder that now holds the photos.
class ObjectCaptureSessionResult {
  final String imagesDirectory;
  final String? checkpointDirectory;
  final int imageCount;

  const ObjectCaptureSessionResult({
    required this.imagesDirectory,
    this.checkpointDirectory,
    required this.imageCount,
  });

  @override
  bool operator ==(Object other) =>
      other is ObjectCaptureSessionResult &&
      other.imagesDirectory == imagesDirectory &&
      other.checkpointDirectory == checkpointDirectory &&
      other.imageCount == imageCount;

  @override
  int get hashCode =>
      Object.hash(imagesDirectory, checkpointDirectory, imageCount);
}
