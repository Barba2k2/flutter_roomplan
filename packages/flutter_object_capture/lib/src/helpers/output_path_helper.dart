import 'package:flutter_object_capture/api/exceptions.dart';

class OutputPathHelper {
  OutputPathHelper._();

  static const _extension = '.usdz';

  /// Throws [InvalidOutputPathException] unless [path] names a `.usdz` file.
  static void validate(String path) {
    final fileName = path.trim().split('/').last;
    final hasName = fileName.length > _extension.length;
    if (!hasName || !fileName.toLowerCase().endsWith(_extension)) {
      throw InvalidOutputPathException(path);
    }
  }
}
