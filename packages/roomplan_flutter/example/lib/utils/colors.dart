import 'package:material_ui/material_ui.dart';
import 'package:roomplan_flutter/roomplan_flutter.dart';

Color getColorForConfidence(Confidence confidence) {
  switch (confidence) {
    case Confidence.high:
      return Colors.green;
    case Confidence.medium:
      return Colors.yellow;
    case Confidence.low:
      return Colors.red;
  }
}
