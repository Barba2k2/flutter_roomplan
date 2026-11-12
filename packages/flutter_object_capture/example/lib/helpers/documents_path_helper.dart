import 'package:path_provider/path_provider.dart';

class DocumentsPathHelper {
  DocumentsPathHelper._();

  static Future<String> path() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }
}
