import 'package:example/widgets/objects_details_view.dart';
import 'package:example/widgets/openings_details_view.dart';
import 'package:example/widgets/paint_area_details_view.dart';
import 'package:example/widgets/room_details_view.dart';
import 'package:example/widgets/walls_details_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Import provider
import 'package:example/viewmodels/results_view_model.dart'; // Import ResultsViewModel

/// A page that displays the detailed results of a room scan.
class ResultsPage extends StatelessWidget {
  const ResultsPage({super.key}); // Remove scanResult from constructor

  @override
  Widget build(BuildContext context) {
    return Consumer<ResultsViewModel>( // Use Consumer to access ViewModel
      builder: (context, viewModel, child) {
        final scanResult = viewModel.scanResult; // Get scanResult from ViewModel
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
      },
    );
  }
}
