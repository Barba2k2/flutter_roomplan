import 'package:flutter/material.dart';
import 'package:roomplan_flutter/roomplan_flutter.dart';

class HomeViewModel extends ChangeNotifier {
  bool _isRoomPlanSupported = false;

  bool get isRoomPlanSupported => _isRoomPlanSupported;

  HomeViewModel() {
    _checkRoomPlanSupport();
  }

  Future<void> _checkRoomPlanSupport() async {
    _isRoomPlanSupported = await RoomPlanScanner.isSupported();
    notifyListeners();
  }

  void navigateToScannerPage(BuildContext context) {
    // Navigation logic will be handled by the view
  }
}