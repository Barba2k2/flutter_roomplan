import 'feature_sensitivity.dart';
import 'object_detail.dart';
import 'object_output_format.dart';
import 'sample_ordering.dart';

/// Options for a reconstruction job. Every field is sent to native.
class ObjectCaptureConfiguration {
  final FeatureSensitivity featureSensitivity;
  final SampleOrdering sampleOrdering;
  final ObjectDetail detail;
  final ObjectOutputFormat outputFormat;

  const ObjectCaptureConfiguration({
    this.featureSensitivity = FeatureSensitivity.normal,
    this.sampleOrdering = SampleOrdering.unordered,
    this.detail = ObjectDetail.reduced,
    this.outputFormat = ObjectOutputFormat.usdz,
  });

  @override
  bool operator ==(Object other) =>
      other is ObjectCaptureConfiguration &&
      other.featureSensitivity == featureSensitivity &&
      other.sampleOrdering == sampleOrdering &&
      other.detail == detail &&
      other.outputFormat == outputFormat;

  @override
  int get hashCode =>
      Object.hash(featureSensitivity, sampleOrdering, detail, outputFormat);
}
