import 'package:flutter/painting.dart';

/// Coordinates inside the scenery viewport, excluding the bottom controls.
class FishingLakeLayout {
  static const water = Rect.fromLTWH(.214, 293 / 600, .572, 212 / 600);

  static Offset toScene(Offset point) =>
      Offset(point.dx * 1000, point.dy * 600);

  static bool contains(Offset point) {
    final dx = (point.dx - water.center.dx) / (water.width / 2 - .012);
    final dy = (point.dy - water.center.dy) / (water.height / 2 - .01);
    return dx * dx + dy * dy <= 1;
  }
}
