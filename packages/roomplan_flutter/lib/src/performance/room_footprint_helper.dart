import 'dart:math' as math;

/// Room footprint (length x width) measured in the room's own axes.
///
/// The native side measures the room as the world-axis bounding box of the
/// wall endpoints, which overestimates any room not aligned with the ARKit
/// world axes (a 4x3 room rotated 30 degrees reads ~4.96x4.60). This rotates
/// the endpoints into the frame of the longest wall first.
class RoomFootprintHelper {
  RoomFootprintHelper._();

  /// Returns `(length, width)` in meters, or null when no wall has a usable
  /// transform and width. Each wall is a raw JSON map with `dimensions.x`
  /// (wall width) and a column-major 4x4 `transform`.
  // ponytail: oriented to the longest wall; non-orthogonal rooms get that
  // wall's frame, not a minimum-area box. Use CapturedRoom.floors polygonCorners
  // natively if that ever matters.
  static (double, double)? measure(List<dynamic> walls) {
    final endpoints = <(double, double)>[];
    var longest = 0.0;
    var angle = 0.0;
    for (final wall in walls.whereType<Map<String, dynamic>>()) {
      final t = wall['transform'] as List<dynamic>?;
      final dims = wall['dimensions'] as Map<String, dynamic>?;
      final width = (dims?['x'] as num?)?.toDouble() ?? 0;
      if (t == null || t.length != 16 || width <= 0) continue;
      final ax = (t[0] as num).toDouble();
      final az = (t[2] as num).toDouble();
      final norm = math.sqrt(ax * ax + az * az);
      if (norm == 0) continue;
      final ux = ax / norm;
      final uz = az / norm;
      final cx = (t[12] as num).toDouble();
      final cz = (t[14] as num).toDouble();
      final half = width / 2;
      endpoints
        ..add((cx + ux * half, cz + uz * half))
        ..add((cx - ux * half, cz - uz * half));
      if (width > longest) {
        longest = width;
        angle = math.atan2(uz, ux);
      }
    }
    if (endpoints.isEmpty) return null;
    final c = math.cos(angle);
    final s = math.sin(angle);
    var minU = double.infinity, maxU = -double.infinity;
    var minV = double.infinity, maxV = -double.infinity;
    for (final (x, z) in endpoints) {
      final u = x * c + z * s;
      final v = -x * s + z * c;
      minU = math.min(minU, u);
      maxU = math.max(maxU, u);
      minV = math.min(minV, v);
      maxV = math.max(maxV, v);
    }
    return (maxU - minU, maxV - minV);
  }
}
