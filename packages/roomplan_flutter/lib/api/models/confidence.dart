/// Represents the confidence level of a scanned element.
enum Confidence {
  /// High confidence.
  high,

  /// Medium confidence.
  medium,

  /// Low confidence.
  low;
  
  /// Creates a [Confidence] from a JSON string.
  static Confidence fromJson(String json) {
    switch (json.toLowerCase()) {
      case 'high':
        return Confidence.high;
      case 'medium':
        return Confidence.medium;
      case 'low':
        return Confidence.low;
      default:
        return Confidence.low;
    }
  }
  
  /// Converts this [Confidence] to a JSON string.
  String toJson() => name;
}

/// A fallback for unknown confidence values.
const unknownConfidence = Confidence.low;
