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
      length: 4,
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
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildRoomDetails(),
            _buildWallsDetails(),
            _buildObjectsDetails(),
            _buildOpeningsDetails(),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomDetails() {
    final dimensions = scanResult.room.dimensions;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (dimensions != null)
          _buildMeasurementCard(
            'Room Dimensions',
            {
              'Length': '${dimensions.length.toStringAsFixed(2)} m',
              'Width': '${dimensions.width.toStringAsFixed(2)} m',
              'Height': '${dimensions.height.toStringAsFixed(2)} m',
            },
          ),
      ],
    );
  }

  Widget _buildWallsDetails() {
    final walls = scanResult.room.walls;
    if (walls.isEmpty) {
      return const Center(child: Text('No walls detected.'));
    }
    return ListView.builder(
      itemCount: walls.length,
      itemBuilder: (context, index) {
        final wall = walls[index];
        return _buildMeasurementCard(
          'Wall ${index + 1}',
          {
            'Width': '${wall.width.toStringAsFixed(2)} m',
            'Height': '${wall.height.toStringAsFixed(2)} m',
            'Confidence': wall.confidence.name,
          },
        );
      },
    );
  }

  Widget _buildObjectsDetails() {
    final objects = scanResult.room.objects;
    if (objects.isEmpty) {
      return const Center(child: Text('No objects detected.'));
    }
    return ListView.builder(
      itemCount: objects.length,
      itemBuilder: (context, index) {
        final object = objects[index];
        return _buildMeasurementCard(
          object.category.name,
          {
            'Length': '${object.length.toStringAsFixed(2)} m',
            'Width': '${object.width.toStringAsFixed(2)} m',
            'Height': '${object.height.toStringAsFixed(2)} m',
            'Confidence': object.confidence.name,
          },
        );
      },
    );
  }

  Widget _buildOpeningsDetails() {
    final doors = scanResult.room.doors;
    final windows = scanResult.room.windows;

    if (doors.isEmpty && windows.isEmpty) {
      return const Center(child: Text('No doors or windows detected.'));
    }

    return ListView(
      children: [
        ...doors.map(
          (door) => _buildMeasurementCard(
            'Door',
            {
              'Width': '${door.width.toStringAsFixed(2)} m',
              'Height': '${door.height.toStringAsFixed(2)} m',
            },
          ),
        ),
        ...windows.map(
          (window) => _buildMeasurementCard(
            'Window',
            {
              'Width': '${window.width.toStringAsFixed(2)} m',
              'Height': '${window.height.toStringAsFixed(2)} m',
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMeasurementCard(String title, Map<String, String> details) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title.toUpperCase(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(height: 20),
            ...details.entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      entry.key,
                      style: const TextStyle(fontSize: 16),
                    ),
                    Text(
                      entry.value,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
