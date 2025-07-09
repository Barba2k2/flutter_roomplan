/// Represents the confidence level of a scanned element.
enum Confidence {
  /// High confidence.
  high,

  /// Medium confidence.
  medium,

  /// Low confidence.
  low,
}

/// A fallback for unknown confidence values.
const unknownConfidence = Confidence.low;
