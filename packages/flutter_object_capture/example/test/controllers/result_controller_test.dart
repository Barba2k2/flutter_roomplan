import 'dart:io';

import 'package:flutter_object_capture_example/controllers/result_controller.dart';
import 'package:flutter_object_capture_example/models/result_info.dart';
import 'package:flutter_object_capture_example/strings/app_strings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('existing file is reported as present', () async {
    final dir = await Directory.systemTemp.createTemp('result_ctrl');
    final file = File('${dir.path}/m.usdz')..writeAsStringSync('x');
    final controller = ResultController(
      ResultInfo(path: file.path, fileSizeBytes: 1),
    );
    await controller.checkFile();
    expect(controller.fileExists, isTrue);
    expect(controller.errorMessage, isNull);
    controller.dispose();
    await dir.delete(recursive: true);
  });

  test('missing file disables sharing with a message', () async {
    final controller = ResultController(
      const ResultInfo(path: '/nope/m.usdz', fileSizeBytes: 1),
    );
    await controller.checkFile();
    expect(controller.fileExists, isFalse);
    expect(controller.errorMessage, AppStrings.resultMissing);
    controller.dispose();
  });

  test('share failure is reported', () {
    final controller = ResultController(
      const ResultInfo(path: '/x.usdz', fileSizeBytes: 1),
    )..reportShareFailed();
    expect(controller.errorMessage, AppStrings.resultShareFailed);
    controller.dispose();
  });
}
