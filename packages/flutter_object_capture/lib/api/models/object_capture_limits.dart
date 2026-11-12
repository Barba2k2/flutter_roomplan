/// Device-specific input limits reported by `PhotogrammetrySession.limits`.
class ObjectCaptureLimits {
  final int maxImages;
  final int maxImageDimension;

  const ObjectCaptureLimits({
    required this.maxImages,
    required this.maxImageDimension,
  });

  @override
  bool operator ==(Object other) =>
      other is ObjectCaptureLimits &&
      other.maxImages == maxImages &&
      other.maxImageDimension == maxImageDimension;

  @override
  int get hashCode => Object.hash(maxImages, maxImageDimension);
}
