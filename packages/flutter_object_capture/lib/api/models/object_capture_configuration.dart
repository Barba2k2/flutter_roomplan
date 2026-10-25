import 'package:flutter_object_capture/api/models/feature_sensitivity.dart';
import 'package:flutter_object_capture/api/models/sample_ordering.dart';

/// Options for a reconstruction job. Every field is sent to native.
class ObjectCaptureConfiguration {
  final FeatureSensitivity featureSensitivity;
  final SampleOrdering sampleOrdering;

  const ObjectCaptureConfiguration({
    this.featureSensitivity = FeatureSensitivity.normal,
    this.sampleOrdering = SampleOrdering.unordered,
  });

  @override
  bool operator ==(Object other) =>
      other is ObjectCaptureConfiguration &&
      other.featureSensitivity == featureSensitivity &&
      other.sampleOrdering == sampleOrdering;

  @override
  int get hashCode => Object.hash(featureSensitivity, sampleOrdering);
}
