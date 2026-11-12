import 'package:flutter_object_capture/flutter_object_capture.dart';
import '../strings/app_strings.dart';

/// One line of text for each event shown in the log.
class EventLogTextHelper {
  EventLogTextHelper._();

  static String describe(ReconstructionEvent event) {
    return switch (event) {
      ReconstructionNotice(:final type) => switch (type) {
          ReconstructionNoticeType.inputComplete =>
            AppStrings.noticeInputComplete,
          ReconstructionNoticeType.automaticDownsampling =>
            AppStrings.noticeDownsampling,
          ReconstructionNoticeType.stitchingIncomplete =>
            AppStrings.noticeStitching,
        },
      ReconstructionSampleIssue(
        :final sampleId,
        :final reason,
        :final skipped
      ) =>
        '${skipped ? AppStrings.sampleSkipped : AppStrings.sampleInvalid} '
            '#$sampleId${reason == null ? '' : ': $reason'}',
      ReconstructionProgress() => '',
      ReconstructionCompleted() => '',
    };
  }
}
