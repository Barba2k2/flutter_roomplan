class RemainingTimeHelper {
  RemainingTimeHelper._();

  static String format(Duration remaining) {
    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds % 60;
    if (minutes == 0) return '$seconds s left';
    return '$minutes min $seconds s left';
  }
}
