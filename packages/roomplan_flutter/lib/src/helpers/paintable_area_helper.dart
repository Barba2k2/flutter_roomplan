import 'package:roomplan_flutter/roomplan_flutter.dart';
import 'package:vector_math/vector_math_64.dart';

/// Wall paint-area math: gross wall area minus its openings and the
/// built-in storage (cabinets) standing against it. Areas in square meters.
class PaintableAreaHelper {
  PaintableAreaHelper._();

  /// Max gap between a storage object's back face and the wall plane.
  static const storageMaxGap = 0.3;

  static double grossArea(WallData wall) => wall.width * wall.height;

  /// Sum of `wall.openings` of [type].
  static double openingsArea(WallData wall, OpeningType type) {
    return wall.openings.where(
      (o) {
        return o.type == type;
      },
    ).fold(
      0.0,
      (sum, o) {
        return sum + o.width * o.height;
      },
    );
  }

  /// Gross minus all openings minus [storageArea], never below 0.
  static double paintableArea(WallData wall, {double storageArea = 0}) {
    final openings = OpeningType.values.fold(
      0.0,
      (sum, type) => sum + openingsArea(wall, type),
    );
    final area = grossArea(wall) - openings - storageArea;
    return area < 0 ? 0 : area;
  }

  /// Wall uuid -> wall area covered by [ObjectCategory.storage] objects.
  /// Each storage goes to the nearest wall whose plane is within
  /// [storageMaxGap] of its back face and whose width spans its center;
  /// covered = its extent along the wall x axis times min(its height, wall
  /// height). Walls with nothing assigned are absent.
  // ponytail: box against plane only, ignores overlap with openings or
  // between cabinets; fine for kitchen runs, revisit if counts double up.
  static Map<String, double> storageAreaByWall(
    List<WallData> walls,
    List<ObjectData> objects,
  ) {
    final covered = <String, double>{};
    for (final object in objects) {
      final t = object.transform;
      final dims = object.dimensions;
      if (object.category != ObjectCategory.storage ||
          t == null ||
          dims == null) {
        continue;
      }
      WallData? best;
      var bestGap = double.infinity;
      var bestExtent = 0.0;
      for (final wall in walls) {
        final wt = wall.transform;
        if (wt == null) continue;
        final xAxis = _axis(wt, 0);
        final normal = _axis(wt, 2);
        final d = t.getTranslation() - wt.getTranslation();
        if (d.dot(xAxis).abs() > wall.width / 2) continue;
        final gap = d.dot(normal).abs() - _extent(t, dims, normal) / 2;
        if (gap > storageMaxGap || gap >= bestGap) continue;
        best = wall;
        bestGap = gap;
        bestExtent = _extent(t, dims, xAxis);
      }
      if (best == null) continue;
      final width = bestExtent < best.width ? bestExtent : best.width;
      final height = dims.height < best.height ? dims.height : best.height;
      covered[best.uuid] = (covered[best.uuid] ?? 0) + width * height;
    }
    return covered;
  }

  static Vector3 _axis(Matrix4 m, int column) {
    return m.getColumn(column).xyz.normalized();
  }

  /// Object box size measured along [dir]. Object dims: x=length, y=height,
  /// z=width (mapper room convention).
  static double _extent(Matrix4 t, RoomDimensions dims, Vector3 dir) {
    return _axis(t, 0).dot(dir).abs() * dims.length +
        _axis(t, 1).dot(dir).abs() * dims.height +
        _axis(t, 2).dot(dir).abs() * dims.width;
  }
}
