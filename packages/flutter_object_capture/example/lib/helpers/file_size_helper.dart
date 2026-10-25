class FileSizeHelper {
  FileSizeHelper._();

  static String format(int bytes) {
    const kilo = 1024;
    if (bytes < kilo) return '$bytes B';
    if (bytes < kilo * kilo) return '${(bytes / kilo).toStringAsFixed(1)} KB';
    if (bytes < kilo * kilo * kilo) {
      return '${(bytes / (kilo * kilo)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (kilo * kilo * kilo)).toStringAsFixed(1)} GB';
  }
}
