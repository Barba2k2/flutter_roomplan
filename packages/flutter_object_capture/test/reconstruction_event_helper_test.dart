import 'package:flutter_object_capture/flutter_object_capture.dart';
import 'package:flutter_object_capture/src/helpers/reconstruction_event_helper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReconstructionEventHelper.parse', () {
    test('progress with estimated remaining time', () {
      final event = ReconstructionEventHelper.parse({
        'type': 'progress',
        'fraction': 0.25,
        'estimatedRemainingSeconds': 12.5,
      });
      expect(
        event,
        const ReconstructionProgress(
          fraction: 0.25,
          estimatedRemaining: Duration(milliseconds: 12500),
        ),
      );
    });

    test('progress without estimate has null remaining', () {
      final event = ReconstructionEventHelper.parse({
        'type': 'progress',
        'fraction': 1,
      });
      expect(event, const ReconstructionProgress(fraction: 1));
    });

    test('progress fraction is clamped to 0..1', () {
      final high = ReconstructionEventHelper.parse({
        'type': 'progress',
        'fraction': 1.7,
      }) as ReconstructionProgress;
      final low = ReconstructionEventHelper.parse({
        'type': 'progress',
        'fraction': -0.3,
      }) as ReconstructionProgress;
      expect(high.fraction, 1);
      expect(low.fraction, 0);
    });

    test('sampleIssue with reason, and skipped defaulting to false', () {
      expect(
        ReconstructionEventHelper.parse({
          'type': 'sampleIssue',
          'sampleId': 3,
          'reason': 'blurry',
        }),
        const ReconstructionSampleIssue(sampleId: 3, reason: 'blurry'),
      );
      expect(
        ReconstructionEventHelper.parse({
          'type': 'sampleIssue',
          'sampleId': 4,
          'skipped': true,
        }),
        const ReconstructionSampleIssue(sampleId: 4, skipped: true),
      );
    });

    test('every notice type', () {
      for (final type in ReconstructionNoticeType.values) {
        expect(
          ReconstructionEventHelper.parse(
              {'type': 'notice', 'notice': type.name}),
          ReconstructionNotice(type: type),
        );
      }
    });

    test('completed', () {
      expect(
        ReconstructionEventHelper.parse({
          'type': 'completed',
          'modelPath': '/tmp/model.usdz',
          'fileSizeBytes': 2048,
        }),
        const ReconstructionCompleted(
          modelPath: '/tmp/model.usdz',
          fileSizeBytes: 2048,
        ),
      );
    });

    test('accepts the Map<Object?, Object?> shape the platform delivers', () {
      final payload = <Object?, Object?>{'type': 'progress', 'fraction': 0.5};
      expect(
        ReconstructionEventHelper.parse(payload),
        const ReconstructionProgress(fraction: 0.5),
      );
    });

    test('malformed payloads throw PayloadParsingException', () {
      final malformed = <Object?>[
        null,
        'progress',
        <String, Object?>{},
        {'type': 'unknown'},
        {'type': 42},
        {'type': 'progress'},
        {'type': 'progress', 'fraction': 'half'},
        {'type': 'progress', 'fraction': double.nan},
        {'type': 'progress', 'fraction': 0.5, 'estimatedRemainingSeconds': 'x'},
        {'type': 'sampleIssue'},
        {'type': 'sampleIssue', 'sampleId': '3'},
        {'type': 'sampleIssue', 'sampleId': 3, 'skipped': 'yes'},
        {'type': 'sampleIssue', 'sampleId': 3, 'reason': 7},
        {'type': 'notice'},
        {'type': 'notice', 'notice': 'nope'},
        {'type': 'completed', 'fileSizeBytes': 1},
        {'type': 'completed', 'modelPath': '/a.usdz'},
        {'type': 'completed', 'modelPath': '/a.usdz', 'fileSizeBytes': 'big'},
      ];
      for (final payload in malformed) {
        expect(
          () => ReconstructionEventHelper.parse(payload),
          throwsA(isA<PayloadParsingException>()),
          reason: '$payload',
        );
      }
    });
  });
}
