import '../../api/exceptions.dart';
import '../../api/models/object_output_format.dart';

class OutputPathHelper {
  OutputPathHelper._();

  static const _extension = '.usdz';

  /// Throws [InvalidOutputPathException] unless [path] fits [format]: a
  /// `.usdz` file for [ObjectOutputFormat.usdz], an extension-less directory
  /// path for [ObjectOutputFormat.objDirectory].
  static void validate(
    String path, [
    ObjectOutputFormat format = ObjectOutputFormat.usdz,
  ]) {
    final fileName = path.trim().split('/').last;
    final isValid = switch (format) {
      ObjectOutputFormat.usdz => fileName.length > _extension.length &&
          fileName.toLowerCase().endsWith(_extension),
      ObjectOutputFormat.objDirectory =>
        fileName.isNotEmpty && !fileName.contains('.'),
    };
    if (!isValid) throw InvalidOutputPathException(path, format);
  }
}
