import 'package:flutter_object_capture/flutter_object_capture.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ObjectCaptureConfiguration', () {
    test('defaults are normal sensitivity and unordered samples', () {
      const configuration = ObjectCaptureConfiguration();
      expect(configuration.featureSensitivity, FeatureSensitivity.normal);
      expect(configuration.sampleOrdering, SampleOrdering.unordered);
    });

    test('equal when all fields match, different otherwise', () {
      const a = ObjectCaptureConfiguration(
        featureSensitivity: FeatureSensitivity.high,
      );
      const b = ObjectCaptureConfiguration(
        featureSensitivity: FeatureSensitivity.high,
      );
      const c = ObjectCaptureConfiguration(
        sampleOrdering: SampleOrdering.sequential,
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    });
  });

  group('ObjectCaptureLimits', () {
    test('value equality', () {
      const a = ObjectCaptureLimits(maxImages: 250, maxImageDimension: 4096);
      const b = ObjectCaptureLimits(maxImages: 250, maxImageDimension: 4096);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(
        a,
        isNot(const ObjectCaptureLimits(maxImages: 1, maxImageDimension: 4096)),
      );
      expect(
        a,
        isNot(const ObjectCaptureLimits(maxImages: 250, maxImageDimension: 1)),
      );
    });
  });

  group('ReconstructionEvent', () {
    test('progress value equality', () {
      const a = ReconstructionProgress(
        fraction: 0.5,
        estimatedRemaining: Duration(seconds: 3),
      );
      const b = ReconstructionProgress(
        fraction: 0.5,
        estimatedRemaining: Duration(seconds: 3),
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(const ReconstructionProgress(fraction: 0.5)));
      expect(
        a,
        isNot(
          const ReconstructionProgress(
            fraction: 0.6,
            estimatedRemaining: Duration(seconds: 3),
          ),
        ),
      );
    });

    test('sample issue value equality', () {
      const a = ReconstructionSampleIssue(
        sampleId: 4,
        reason: 'blurry',
        skipped: false,
      );
      const b = ReconstructionSampleIssue(
        sampleId: 4,
        reason: 'blurry',
        skipped: false,
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(
        a,
        isNot(const ReconstructionSampleIssue(sampleId: 4, skipped: true)),
      );
      expect(
        a,
        isNot(const ReconstructionSampleIssue(sampleId: 5, reason: 'blurry')),
      );
    });

    test('notice value equality', () {
      const a = ReconstructionNotice(
        type: ReconstructionNoticeType.inputComplete,
      );
      expect(
        a,
        const ReconstructionNotice(
            type: ReconstructionNoticeType.inputComplete),
      );
      expect(
        a,
        isNot(
          const ReconstructionNotice(
            type: ReconstructionNoticeType.automaticDownsampling,
          ),
        ),
      );
    });

    test('completed value equality', () {
      const a = ReconstructionCompleted(modelPath: '/a.usdz', fileSizeBytes: 9);
      expect(
        a,
        const ReconstructionCompleted(modelPath: '/a.usdz', fileSizeBytes: 9),
      );
      expect(
        a,
        isNot(
          const ReconstructionCompleted(modelPath: '/b.usdz', fileSizeBytes: 9),
        ),
      );
      expect(
        a,
        isNot(
          const ReconstructionCompleted(modelPath: '/a.usdz', fileSizeBytes: 8),
        ),
      );
    });

    test('different event types are never equal', () {
      const ReconstructionEvent notice = ReconstructionNotice(
        type: ReconstructionNoticeType.inputComplete,
      );
      const ReconstructionEvent issue = ReconstructionSampleIssue(sampleId: 1);
      expect(notice, isNot(issue));
    });

    test('switch over the sealed hierarchy is exhaustive', () {
      String describe(ReconstructionEvent event) => switch (event) {
            ReconstructionProgress() => 'progress',
            ReconstructionSampleIssue() => 'issue',
            ReconstructionNotice() => 'notice',
            ReconstructionCompleted() => 'completed',
          };
      expect(describe(const ReconstructionProgress(fraction: 0)), 'progress');
    });
  });

  group('exceptions', () {
    test('every exception is an ObjectCaptureException with a message', () {
      final all = <ObjectCaptureException>[
        ObjectCaptureNotSupportedException(),
        InvalidImagesDirectoryException(),
        InvalidOutputPathException('/x.png'),
        InsufficientStorageException(requiredBytes: 10),
        ReconstructionInProgressException(),
        ReconstructionCancelledException(),
        ReconstructionFailedException('boom'),
        NativeChannelException('oops'),
        PayloadParsingException('bad'),
      ];
      for (final exception in all) {
        expect(exception.message, isNotEmpty);
        expect(exception.toString(), contains(exception.message));
      }
    });

    test('details are carried into the message', () {
      expect(InvalidOutputPathException('/x.png').message, contains('/x.png'));
      expect(ReconstructionFailedException('boom').message, contains('boom'));
      expect(NativeChannelException('oops').message, contains('oops'));
      expect(PayloadParsingException('bad').message, contains('bad'));
      expect(InsufficientStorageException(requiredBytes: 10).requiredBytes, 10);
      expect(InsufficientStorageException().requiredBytes, isNull);
    });
  });
}
