import 'dart:math' as math;
import 'package:flutter/painting.dart';
import 'fishing_river.dart';
import 'river_prop_kind.dart';

/// One row per interactive structure: art anchor, tap bounds, footprint and berth.
/// Geometry is independent of the shop/economy or interior it opens.
enum FishingVisit {
  boatHouse(108,
      bankOffset: 180,
      bounds: Rect.fromLTRB(-106, -178, 96, 18),
      tapPadding: 10,
      doorOffset: Offset(-24, 30),
      berthOffset: Offset(0, -214)),
  market(6050,
      y: 1250,
      radius: 150,
      depth: 80,
      bounds: Rect.fromLTRB(-200, -175, 200, 115),
      propKind: RiverPropKind.market),
  shrine(8100,
      y: 700,
      radius: 165,
      depth: 100,
      bounds: Rect.fromLTRB(-215, -300, 215, 80),
      propKind: RiverPropKind.shrine),
  baitHouse(4600,
      bankOffset: 90,
      northBank: true,
      radius: 70,
      depth: 45,
      bounds: Rect.fromLTRB(-110, -175, 110, 75),
      propKind: RiverPropKind.baitHouse),
  rodHouse(400,
      bankOffset: 180,
      bounds: Rect.fromLTRB(-104, -155, 104, 28),
      tapPadding: 8,
      doorOffset: Offset(0, 30),
      berthOffset: Offset(0, -214)),
  cabinShip(11500,
      y: 1000,
      radius: 130,
      depth: 95,
      bounds: Rect.fromLTRB(-150, -150, 150, 80),
      propKind: RiverPropKind.cabinShip);

  const FishingVisit(this.x,
      {this.y = 0,
      this.bankOffset,
      this.northBank = false,
      required Rect bounds,
      this.tapPadding = 0,
      this.radius = 0,
      this.depth = 0,
      this.propKind,
      this.doorOffset,
      this.berthOffset})
      : _bounds = bounds;
  final double x, y, radius, depth, tapPadding;
  final double? bankOffset;
  final bool northBank;
  final Rect _bounds;
  final Offset? doorOffset, berthOffset;
  final RiverPropKind? propKind;

  static final floating =
      values.where((p) => p.propKind != null).toList(growable: false);
  static FishingVisit? hitAt(Offset point) =>
      values.where((p) => p.hit(point)).firstOrNull;

  Offset get anchor => Offset(
      x,
      bankOffset == null
          ? y
          : (northBank ? FishingRiver.top(x) : FishingRiver.bottom(x)) +
              bankOffset!);
  Rect get bounds => _bounds.shift(anchor);
  bool hit(Offset point) => bounds.inflate(tapPadding).contains(point);
  Offset? get bankDoor => doorOffset == null ? null : anchor + doorOffset!;
  Offset get mooring => anchor + (berthOffset ?? Offset(0, depth + 55));
  double reachTowards(Offset point) {
    final delta = point - anchor;
    if (delta.distance < .001 || radius == depth) return radius;
    final unit = delta / delta.distance;
    return 1 /
        math.sqrt(unit.dx * unit.dx / (radius * radius) +
            unit.dy * unit.dy / (depth * depth));
  }
}
