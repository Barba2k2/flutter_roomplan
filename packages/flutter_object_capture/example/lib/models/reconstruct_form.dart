import 'package:flutter_object_capture/flutter_object_capture.dart';

/// What the user typed or picked before starting.
class ReconstructForm {
  final String? imagesDirectory;
  final String outputName;
  final ObjectDetail detail;

  const ReconstructForm({
    this.imagesDirectory,
    this.outputName = 'model',
    this.detail = ObjectDetail.reduced,
  });

  ReconstructForm copyWith({
    String? imagesDirectory,
    String? outputName,
    ObjectDetail? detail,
  }) {
    return ReconstructForm(
      imagesDirectory: imagesDirectory ?? this.imagesDirectory,
      outputName: outputName ?? this.outputName,
      detail: detail ?? this.detail,
    );
  }
}
