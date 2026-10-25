import 'package:flutter_object_capture/flutter_object_capture.dart';
import 'package:flutter_object_capture/src/helpers/output_path_helper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OutputPathHelper.validate', () {
    test('accepts .usdz paths', () {
      expect(
          () => OutputPathHelper.validate('/tmp/model.usdz'), returnsNormally);
      expect(
          () => OutputPathHelper.validate('/tmp/MODEL.USDZ'), returnsNormally);
    });

    test('rejects other extensions', () {
      for (final path in [
        '/tmp/model.obj',
        '/tmp/model.usdz.zip',
        '/tmp/usdz'
      ]) {
        expect(
          () => OutputPathHelper.validate(path),
          throwsA(isA<InvalidOutputPathException>()),
          reason: path,
        );
      }
    });

    test('rejects empty and blank paths', () {
      for (final path in ['', '   ']) {
        expect(
          () => OutputPathHelper.validate(path),
          throwsA(isA<InvalidOutputPathException>()),
        );
      }
    });

    test('rejects a file name that is only the extension', () {
      expect(
        () => OutputPathHelper.validate('/tmp/.usdz'),
        throwsA(isA<InvalidOutputPathException>()),
      );
    });

    test('rejects a directory path ending in a slash', () {
      expect(
        () => OutputPathHelper.validate('/tmp/models.usdz/'),
        throwsA(isA<InvalidOutputPathException>()),
      );
    });
  });
}
