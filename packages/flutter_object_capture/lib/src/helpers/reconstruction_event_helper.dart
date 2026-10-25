import 'package:flutter_object_capture/api/exceptions.dart';
import 'package:flutter_object_capture/api/models/reconstruction_event.dart';
import 'package:flutter_object_capture/api/models/reconstruction_notice_type.dart';

class ReconstructionEventHelper {
  ReconstructionEventHelper._();

  /// Converts a native event payload into a [ReconstructionEvent].
  ///
  /// Throws [PayloadParsingException] when the payload breaks the contract
  /// documented in the README ("Channel contract").
  static ReconstructionEvent parse(Object? payload) {
    if (payload is! Map) {
      throw PayloadParsingException('event is not a map: $payload');
    }
    final type = payload['type'];
    return switch (type) {
      'progress' => ReconstructionProgress(
          fraction: _fraction(payload),
          estimatedRemaining: _estimatedRemaining(payload),
        ),
      'sampleIssue' => ReconstructionSampleIssue(
          sampleId: _required<int>(payload, 'sampleId'),
          reason: _optional<String>(payload, 'reason'),
          skipped: _optional<bool>(payload, 'skipped') ?? false,
        ),
      'notice' => ReconstructionNotice(type: _noticeType(payload)),
      'completed' => ReconstructionCompleted(
          modelPath: _required<String>(payload, 'modelPath'),
          fileSizeBytes: _required<int>(payload, 'fileSizeBytes'),
        ),
      _ => throw PayloadParsingException('unknown event type: $type'),
    };
  }

  static double _fraction(Map payload) {
    final value = _required<num>(payload, 'fraction').toDouble();
    if (value.isNaN) {
      throw PayloadParsingException('fraction is NaN');
    }
    return value.clamp(0.0, 1.0);
  }

  static Duration? _estimatedRemaining(Map payload) {
    final seconds = _optional<num>(payload, 'estimatedRemainingSeconds');
    if (seconds == null) return null;
    return Duration(milliseconds: (seconds * 1000).round());
  }

  static ReconstructionNoticeType _noticeType(Map payload) {
    final name = _required<String>(payload, 'notice');
    for (final type in ReconstructionNoticeType.values) {
      if (type.name == name) return type;
    }
    throw PayloadParsingException('unknown notice: $name');
  }

  static T _required<T>(Map payload, String key) {
    final value = payload[key];
    if (value is! T) {
      throw PayloadParsingException('"$key" missing or not a $T: $value');
    }
    return value;
  }

  static T? _optional<T>(Map payload, String key) {
    final value = payload[key];
    if (value == null) return null;
    if (value is! T) {
      throw PayloadParsingException('"$key" is not a $T: $value');
    }
    return value;
  }
}
