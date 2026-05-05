import 'detail_level.dart';

/// Outcome of a photogrammetry reconstruction.
///
/// Returned by [FlutterObjectCapture.reconstruct].
class PhotogrammetryResult {
  const PhotogrammetryResult({
    required this.modelPath,
    required this.detailLevel,
    required this.processingTime,
  });

  /// Filesystem path to the generated `.usdz` file.
  final String modelPath;

  /// Quality preset used during reconstruction.
  final DetailLevel detailLevel;

  /// Wall-clock time spent generating the model.
  final Duration processingTime;

  factory PhotogrammetryResult.fromJson(Map<String, Object?> json) {
    return PhotogrammetryResult(
      modelPath: json['modelPath']! as String,
      detailLevel: DetailLevel.values.byName(json['detailLevel']! as String),
      processingTime:
          Duration(milliseconds: (json['processingTimeMs']! as num).toInt()),
    );
  }
}
