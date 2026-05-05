import 'package:flutter/material.dart';
import 'package:roomplan_flutter/roomplan_flutter.dart';

class ResultsViewModel extends ChangeNotifier {
  final ScanResult _scanResult;

  ResultsViewModel({required ScanResult scanResult}) : _scanResult = scanResult;

  ScanResult get scanResult => _scanResult;

  // You can add more derived properties or logic here if needed
  // For example:
  // List<ObjectData> get objects => _scanResult.room.objects;
  // List<WallData> get walls => _scanResult.room.walls;
}