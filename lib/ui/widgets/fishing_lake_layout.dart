import 'package:flutter/painting.dart';

/// Coordinates inside the scenery viewport, excluding the bottom controls.
class FishingLakeLayout {
  static const water = Rect.fromLTWH(.08, .24, .84, .66);

  static Offset fromLake(Offset p) =>
      Offset(water.left + p.dx * water.width, water.top + p.dy * water.height);

  static Offset toLake(Offset p) => Offset(
      (p.dx - water.left) / water.width, (p.dy - water.top) / water.height);

  static bool contains(Offset point) {
    final dx = (point.dx - water.center.dx) / (water.width / 2 - .012);
    final dy = (point.dy - water.center.dy) / (water.height / 2 - .01);
    return dx * dx + dy * dy <= 1;
  }
}
