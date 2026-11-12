import 'package:flutter_object_capture/flutter_object_capture.dart';
import '../strings/app_strings.dart';

class DetailLabelHelper {
  DetailLabelHelper._();

  static String label(ObjectDetail detail) {
    return switch (detail) {
      ObjectDetail.preview => AppStrings.detailPreview,
      ObjectDetail.reduced => AppStrings.detailReduced,
      ObjectDetail.medium => AppStrings.detailMedium,
      ObjectDetail.full => AppStrings.detailFull,
      ObjectDetail.raw => AppStrings.detailRaw,
    };
  }
}
