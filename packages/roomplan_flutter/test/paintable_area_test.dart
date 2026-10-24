import 'package:flutter_test/flutter_test.dart';
import 'package:roomplan_flutter/roomplan_flutter.dart';
import 'package:roomplan_flutter/src/performance/optimized_mapper.dart';

// Wall along world X at z = 0, centered at x = 0, facing +z (identity basis).
const wallJson = '''
{
  "walls": [{
    "uuid": "w",
    "dimensions": {"x": 4.0, "y": 2.5, "z": 0.0},
    "transform": [1,0,0,0, 0,1,0,0, 0,0,1,0, 0,1.25,0,1],
    "doors": [{"uuid": "d", "dimensions": {"x": 0.9, "y": 2.0, "z": 0.0}}],
    "windows": [{"uuid": "n", "dimensions": {"x": 1.2, "y": 1.0, "z": 0.0}}],
    "openings": [{"uuid": "o", "dimensions": {"x": 0.5, "y": 0.4, "z": 0.0}}]
  }],
  "objects": [
    {"uuid": "near", "category": "storage",
     "dimensions": {"x": 2.0, "y": 2.4, "z": 0.6},
     "transform": [1,0,0,0, 0,1,0,0, 0,0,1,0, 0.5,1.2,0.35,1]},
    {"uuid": "far", "category": "storage",
     "dimensions": {"x": 1.0, "y": 2.0, "z": 0.6},
     "transform": [1,0,0,0, 0,1,0,0, 0,0,1,0, 0,1.0,2.0,1]},
    {"uuid": "outside", "category": "storage",
     "dimensions": {"x": 1.0, "y": 2.0, "z": 0.6},
     "transform": [1,0,0,0, 0,1,0,0, 0,0,1,0, 3.0,1.0,0.3,1]},
    {"uuid": "sofa", "category": "sofa",
     "dimensions": {"x": 2.0, "y": 0.9, "z": 0.9},
     "transform": [1,0,0,0, 0,1,0,0, 0,0,1,0, 0,0.45,0.45,1]}
  ]
}
''';

void main() {
  final room = OptimizedMapper.parseScanResult(wallJson)!.room;
  final wall = room.walls.single;

  test('nested doors, windows and openings fill wall.openings', () {
    expect(
      wall.openings.map((o) => (o.uuid, o.type, o.width, o.height)),
      [
        ('d', OpeningType.door, 0.9, 2.0),
        ('n', OpeningType.window, 1.2, 1.0),
        ('o', OpeningType.opening, 0.5, 0.4),
      ],
    );
  });

  test('door + window deducted: 10 - 1.8 - 1.2 = 7.0', () {
    expect(PaintableAreaHelper.grossArea(wall), 10.0);
    expect(
      PaintableAreaHelper.openingsArea(wall, OpeningType.door),
      closeTo(1.8, 1e-9),
    );
    expect(
      PaintableAreaHelper.openingsArea(wall, OpeningType.window),
      closeTo(1.2, 1e-9),
    );
    final doorAndWindow = WallData(
      uuid: 'w2',
      position: wall.position,
      points: const [],
      width: 4.0,
      height: 2.5,
      confidence: Confidence.high,
      openings:
          wall.openings.where((o) => o.type != OpeningType.opening).toList(),
    );
    expect(
      PaintableAreaHelper.paintableArea(doorAndWindow),
      closeTo(7.0, 1e-9),
    );
  });

  test('storage within 0.3 m assigned, far/outside/sofa ignored', () {
    final covered = PaintableAreaHelper.storageAreaByWall(
      room.walls,
      room.objects,
    );
    expect(covered.keys, ['w']);
    expect(covered['w'], closeTo(4.8, 1e-9));
    expect(
      PaintableAreaHelper.paintableArea(wall, storageArea: covered['w']!),
      closeTo(10 - 1.8 - 1.2 - 0.2 - 4.8, 1e-9),
    );
  });

  test('paintable area never below zero', () {
    expect(PaintableAreaHelper.paintableArea(wall, storageArea: 99), 0);
  });
}
