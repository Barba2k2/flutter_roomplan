import 'package:example/src/widgets/objects_details_view.dart';
import 'package:example/src/widgets/openings_details_view.dart';
import 'package:example/src/widgets/paint_area_details_view.dart';
import 'package:example/src/widgets/room_details_view.dart';
import 'package:example/src/widgets/walls_details_view.dart';
import 'package:flutter/material.dart';
import 'package:roomplan_flutter/roomplan_flutter.dart';

/// A page that displays the detailed results of a room scan.
class ResultsPage extends StatelessWidget {
  /// The result of the completed scan.
  final ScanResult scanResult;

  const ResultsPage({super.key, required this.scanResult});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Scan Results'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Room'),
              Tab(text: 'Walls'),
              Tab(text: 'Objects'),
              Tab(text: 'Openings'),
              Tab(text: 'Paint Area'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            RoomDetailsView(scanResult: scanResult),
            WallsDetailsView(scanResult: scanResult),
            ObjectsDetailsView(scanResult: scanResult),
            OpeningsDetailsView(scanResult: scanResult),
            PaintAreaDetailsView(scanResult: scanResult),
          ],
        ),
      ),
    );
  }
}
