import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:roomplan_flutter/src/performance/optimized_mapper.dart';
import 'package:roomplan_flutter/src/performance/room_footprint_helper.dart';

/// Wall of [width] centred at ([cx], [cz]) whose local X axis points at
/// [angle] radians in the XZ plane (column-major, like the Swift side).
Map<String, dynamic> wall(double cx, double cz, double angle, double width) {
  final c = math.cos(angle);
  final s = math.sin(angle);
  return {
    'uuid': 'w',
    'dimensions': {'x': width, 'y': 2.5, 'z': 0.0},
    'transform': [
      c, 0, s, 0, //
      0, 1, 0, 0, //
      -s, 0, c, 0, //
      cx, 1.25, cz, 1,
    ],
    'confidence': 'high',
  };
}

/// Rectangle [l] x [w] rotated by [rot], built from its four walls.
List<Map<String, dynamic>> rect(double l, double w, double rot) {
  (double, double) at(double u, double v) => (
        u * math.cos(rot) - v * math.sin(rot),
        u * math.sin(rot) + v * math.cos(rot),
      );
  final a = at(0, -w / 2),
      b = at(0, w / 2),
      c = at(-l / 2, 0),
      d = at(l / 2, 0);
  return [
    wall(a.$1, a.$2, rot, l),
    wall(b.$1, b.$2, rot, l),
    wall(c.$1, c.$2, rot + math.pi / 2, w),
    wall(d.$1, d.$2, rot + math.pi / 2, w),
  ];
}

void main() {
  test('rotated 4x3 room measures 4x3', () {
    final r = RoomFootprintHelper.measure(rect(4, 3, math.pi / 6))!;
    expect(r.$1, closeTo(4, 1e-6));
    expect(r.$2, closeTo(3, 1e-6));
  });

  test('L-shaped room reports its outer 5x4 extents', () {
    // L: 5x4 minus the 2x2 top-right corner.
    final walls = [
      wall(2.5, 0, 0, 5),
      wall(0, 2, math.pi / 2, 4),
      wall(1.5, 4, 0, 3),
      wall(3, 3, math.pi / 2, 2),
      wall(4, 2, 0, 2),
      wall(5, 1, math.pi / 2, 2),
    ];
    final r = RoomFootprintHelper.measure(walls)!;
    expect(r.$1, closeTo(5, 1e-6));
    expect(r.$2, closeTo(4, 1e-6));
  });

  test('no usable walls returns null', () {
    expect(RoomFootprintHelper.measure(<dynamic>[]), isNull);
  });

  test('mapper overrides world-axis room and floor size', () {
    final jsonMap = {
      'room': {
        'walls': rect(4, 3, math.pi / 6),
        'dimensions': {'x': 4.96, 'y': 2.5, 'z': 4.6},
        'floor': {
          'uuid': 'f',
          'dimensions': {'x': 4.96, 'y': 0.0, 'z': 4.6},
          'confidence': 'high',
        },
      },
    };
    final room = OptimizedMapper.parseScanResult(json.encode(jsonMap))!.room;
    expect(room.dimensions!.length, closeTo(4, 1e-6));
    expect(room.dimensions!.width, closeTo(3, 1e-6));
    expect(room.dimensions!.height, 2.5);
    expect(room.floor!.dimensions!.floorArea, closeTo(12, 1e-6));
  });
}
