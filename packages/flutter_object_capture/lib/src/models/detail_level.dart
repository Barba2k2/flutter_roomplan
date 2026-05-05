/// Quality preset applied during photogrammetry reconstruction.
///
/// Mirrors `PhotogrammetrySession.Request.Detail` from RealityKit. Higher
/// levels produce denser meshes and larger textures at the cost of processing
/// time and output size.
enum DetailLevel {
  /// Lowest detail. Fast preview suitable for thumbnails or quick checks.
  preview,

  /// Reduced detail. Good for mobile AR rendering.
  reduced,

  /// Default balance between detail and size. Recommended for most apps.
  medium,

  /// High detail. Suitable for desktop or high-end visualization.
  full,

  /// Unprocessed data. Maximum fidelity for post-processing pipelines.
  raw,
}
