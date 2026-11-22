import 'dart:math' as math;
import 'package:flutter/painting.dart';

/// The sea island: an irregular coastline around [center]. [radius] is the
/// base size; the west side (dock and mooring) stays exactly at [radius],
/// elsewhere headlands and coves vary it between about 0.79x and 1.21x.
class FishingSeaIsland {
  const FishingSeaIsland({required this.center, required this.radius});
  final Offset center;
  final double radius;

  /// Largest coastline distance, for culling and broad checks.
  double get maxRadius => radius * 1.21;

  /// Coastline distance from [center] in direction [angle].
  double radiusAt(double angle) {
    final wobble = .12 * math.sin(2 * angle + .9) +
        .07 * math.sin(3 * angle + 2.3) +
        .045 * math.sin(5 * angle + .5) +
        .03 * math.sin(7 * angle + 1.3);
    // Flatten the wobble around the west dock (angle = pi).
    final fromWest =
        math.atan2(math.sin(angle - math.pi), math.cos(angle - math.pi)).abs();
    final t = ((fromWest - .12) / .45).clamp(0.0, 1.0);
    return radius * (1 + wobble * t * t * (3 - 2 * t));
  }

  /// Coastline distance in the direction of world point [p].
  double radiusTowards(Offset p) {
    final d = p - center;
    return radiusAt(d.distance < .001 ? math.pi : d.direction);
  }

  bool contains(Offset p, {double inset = 0}) =>
      (p - center).distance <= radiusTowards(p) - inset;

  /// Closed coastline, grown outward by [grow] (negative shrinks).
  Path outline({double grow = 0, double scale = 1}) {
    final path = Path();
    for (var i = 0; i <= 120; i++) {
      final a = i * math.pi * 2 / 120;
      final r = (radiusAt(a) + grow) * scale;
      final p = center + Offset(math.cos(a) * r, math.sin(a) * r);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    return path..close();
  }
}

/// Sea landmarks use these exact footprints for art, water queries and routing.
const fishingSeaIsland =
    FishingSeaIsland(center: Offset(10800, 1750), radius: 430.0);
const fishingSeaRocks = [
  (center: Offset(5800, 780), radius: 36.0),
  (center: Offset(5860, 805), radius: 24.0),
  (center: Offset(5825, 835), radius: 29.0),
  (center: Offset(6580, 1440), radius: 42.0),
  (center: Offset(6645, 1420), radius: 28.0),
  (center: Offset(6610, 1500), radius: 23.0),
  (center: Offset(6860, 650), radius: 46.0),
  (center: Offset(6925, 685), radius: 27.0),
  (center: Offset(9370, 2470), radius: 48.0),
  (center: Offset(9435, 2500), radius: 27.0),
  (center: Offset(7800, 2150), radius: 55.0),
  (center: Offset(7862, 2192), radius: 30.0),
  (center: Offset(8650, 1500), radius: 48.0),
  (center: Offset(8708, 1546), radius: 26.0),
  // Far sea east of the island.
  (center: Offset(11150, 1180), radius: 38.0),
  (center: Offset(11205, 1215), radius: 22.0),
  (center: Offset(11700, 2350), radius: 42.0),
  (center: Offset(11760, 2320), radius: 26.0),
  (center: Offset(12150, 1500), radius: 34.0),
  // Sea stacks spread across the wide rocky bay.
  (center: Offset(7480, 1760), radius: 46.0),
  (center: Offset(8280, 1960), radius: 44.0),
  (center: Offset(8322, 2002), radius: 24.0),
  (center: Offset(8860, 1960), radius: 50.0),
];
