import 'dart:math' as math;
import 'package:flutter/painting.dart';
import 'river_sea_land.dart';
import 'fishing_river.dart';

enum IslandVisitPhase { aboard, landing, exploring, boarding }

class IslandCrab {
  IslandCrab(this.seed, this.position);
  final int seed;
  Offset position;
  bool fleeing = false;
}

/// A small, session-only island visit; it never writes fish or camp rewards.
class FishingIslandVisit {
  static Offset get mooring =>
      fishingSeaIsland.center + Offset(-fishingSeaIsland.radius - 65, 35);
  static Offset get landing =>
      fishingSeaIsland.center + Offset(-fishingSeaIsland.radius + 33, 30);
  static Offset get dockTap =>
      fishingSeaIsland.center + Offset(-fishingSeaIsland.radius - 11, 35);

  /// Lighthouse on the east headland: [lighthouse] is the tower base,
  /// [lighthouseDoor] where the cat starts climbing, [lighthouseTop] the
  /// gallery it stands on while looking out.
  static const lighthouseScale = 1.3;
  static Offset get lighthouse =>
      fishingSeaIsland.center + const Offset(395, -15);
  static Offset get lighthouseDoor => lighthouse + const Offset(0, 16);
  static Offset get lighthouseTop =>
      lighthouse + const Offset(0, -111 * lighthouseScale);
  static bool hitsLighthouse(Offset p) => Rect.fromLTRB(lighthouse.dx - 45,
          lighthouse.dy - 215, lighthouse.dx + 45, lighthouse.dy + 30)
      .contains(p);

  /// Dormant volcano in the middle of the island. Its jungle-covered
  /// footprint is an ellipse the cat walks around, never through.
  static Offset get mountain => fishingSeaIsland.center + const Offset(0, -40);
  static const mountainRadii = Size(290, 200);

  /// Cave mouth at the mountain's south-west foot; the cat walks here and
  /// enters the parkour cave.
  static Offset get caveMouth =>
      fishingSeaIsland.center + const Offset(-215, 150);

  static bool inMountain(Offset p, {double grow = 0}) {
    final d = p - mountain;
    final x = d.dx / (mountainRadii.width + grow),
        y = d.dy / (mountainRadii.height + grow);
    return x * x + y * y < 1;
  }

  /// Point on the mountain edge (grown by [grow]) in direction [angle].
  static Offset mountainEdge(double angle, double grow) =>
      mountain +
      Offset(math.cos(angle) * (mountainRadii.width + grow),
          math.sin(angle) * (mountainRadii.height + grow));

  static double _mountainAngle(Offset p) {
    final d = p - mountain;
    return math.atan2(d.dy / mountainRadii.height, d.dx / mountainRadii.width);
  }

  /// Keeps a ground point on the island and off the mountain.
  static Offset constrainGround(Offset p) {
    var q = constrain(p);
    if (inMountain(q, grow: 12)) q = mountainEdge(_mountainAngle(q), 14);
    return constrain(q);
  }

  /// True while the cat stands on a lookout (camera zooms out).
  bool lookout = false;
  bool lookoutRequested = false;

  Offset get lookoutDoor => lighthouseDoor;
  Offset get lookoutTop => lighthouseTop;

  /// Walks to the lighthouse door; the climb starts on arrival.
  void climbLighthouse() {
    if (phase != IslandVisitPhase.exploring || onBank || lookout) return;
    boardRequested = false;
    caveRequested = false;
    _routeTo(lookoutDoor);
    lookoutRequested = true;
  }

  /// Walking to the cave mouth; [caveArrived] fires once on arrival.
  bool caveRequested = false, caveArrived = false;

  void goToCave() {
    if (phase != IslandVisitPhase.exploring || onBank || lookout) return;
    boardRequested = false;
    lookoutRequested = false;
    _routeTo(caveMouth);
    caveRequested = true;
  }

  void climbDown() {
    if (!lookout) return;
    lookout = false;
    cat = lookoutDoor;
    facingRight = false;
  }

  static const shellOffsets = [
    Offset(-330, -130),
    Offset(280, -240),
    Offset(280, 200),
    Offset(-250, 250),
    Offset(40, -315),
    Offset(45, 330)
  ];
  // null means the island; otherwise the visit stays on one riverbank.
  bool? northBank;
  Offset? bankMooring, bankLanding;
  Offset get visitMooring => bankMooring ?? mooring;
  Offset get visitLanding => bankLanding ?? landing;
  bool get onBank => northBank != null;
  final _walkRoute = <Offset>[];
  bool landContains(Offset p) => onBank
      ? p.dx >= 55 &&
          p.dx <= FishingRiver.length - 55 &&
          p.dy >= 150 &&
          p.dy <= FishingRiver.height - 30 &&
          (northBank!
              ? p.dy <= FishingRiver.top(p.dx) - 18
              : p.dy >= FishingRiver.bottom(p.dx) + 18)
      : contains(p);
  Offset landConstrain(Offset p) {
    if (!onBank) return constrain(p);
    final x = p.dx.clamp(55.0, FishingRiver.length - 55);
    return Offset(
        x,
        northBank!
            ? p.dy.clamp(150.0, FishingRiver.top(x) - 22)
            : p.dy
                .clamp(FishingRiver.bottom(x) + 22, FishingRiver.height - 30));
  }

  void chooseIsland() {
    northBank = null;
    bankMooring = null;
    bankLanding = null;
  }

  void chooseBank(Offset point) {
    northBank = point.dy < FishingRiver.center(point.dx);
    final x = point.dx.clamp(80.0, FishingRiver.length - 80);
    final edge = northBank! ? FishingRiver.top(x) : FishingRiver.bottom(x);
    bankMooring = Offset(x, edge + (northBank! ? 60 : -60));
    bankLanding = Offset(x, edge + (northBank! ? -48 : 48));
  }

  void _routeTo(Offset target) {
    destination = landConstrain(target);
    _walkRoute.clear();
    if (!onBank) {
      destination = constrainGround(destination!);
      _walkRoute.addAll(_aroundMountain(cat, destination!));
      return;
    }
    bool clear(Offset a, Offset b) {
      final n = math.max(1, ((b - a).distance / 8).ceil());
      for (var i = 0; i <= n; i++) {
        if (!landContains(Offset.lerp(a, b, i / n)!)) return false;
      }
      return true;
    }

    // Shortest first: walk straight when the bank allows it.
    if (clear(cat, destination!)) {
      _walkRoute.add(destination!);
      return;
    }
    double edge(double x) =>
        northBank! ? FishingRiver.top(x) : FishingRiver.bottom(x);
    final startDepth = (cat.dy - edge(cat.dx)).abs();
    final endDepth = (destination!.dy - edge(destination!.dx)).abs();
    final steps = math.max(1, ((destination!.dx - cat.dx).abs() / 16).ceil());
    for (var i = 1; i <= steps; i++) {
      final t = i / steps;
      final x = cat.dx + (destination!.dx - cat.dx) * t;
      _walkRoute.add(landConstrain(Offset(
          x,
          edge(x) +
              (northBank! ? -1 : 1) *
                  (startDepth + (endDepth - startDepth) * t))));
    }
    final tight = FishingRiverRound.pullTight(cat, _walkRoute, clear);
    _walkRoute
      ..clear()
      ..addAll(tight);
  }

  IslandVisitPhase phase = IslandVisitPhase.aboard;
  bool dockRequested = false, boardRequested = false, facingRight = true;
  Offset cat = landing;
  Offset? destination;
  double elapsed = 0, clock = 0;
  final collectedShells = <int>{};
  final crabs = [
    for (var i = 0; i < 3; i++)
      IslandCrab(
          i,
          fishingSeaIsland.center +
              Offset(math.cos(i * 2.1) * 280, math.sin(i * 2.1) * 280))
  ];
  bool get ashore => phase != IslandVisitPhase.aboard;
  bool get walking =>
      phase == IslandVisitPhase.exploring && destination != null;

  /// 0..1 through the hop between boat and pier, or null when not hopping.
  double? get hopProgress =>
      phase == IslandVisitPhase.landing || phase == IslandVisitPhase.boarding
          ? (elapsed / .65).clamp(0.0, 1.0)
          : null;
  double get jump {
    final t = hopProgress;
    return t == null ? 0 : math.sin(t * math.pi) * 28;
  }

  static bool contains(Offset p) => fishingSeaIsland.contains(p);
  static Offset constrain(Offset p) {
    final delta = p - fishingSeaIsland.center;
    final radius = fishingSeaIsland.radiusTowards(p) - 22;
    return delta.distance > radius
        ? fishingSeaIsland.center + delta / delta.distance * radius
        : p;
  }

  void beginLanding() {
    dockRequested = false;
    boardRequested = false;
    destination = null;
    _walkRoute.clear();
    phase = IslandVisitPhase.landing;
    elapsed = 0;
    cat = visitMooring;
    facingRight = visitLanding.dx >= visitMooring.dx;
  }

  void walkTo(Offset point) {
    if (phase != IslandVisitPhase.exploring || lookout) return;
    boardRequested = false;
    lookoutRequested = false;
    caveRequested = false;
    _routeTo(point);
  }

  void stopWalking() {
    destination = null;
    _walkRoute.clear();
    boardRequested = false;
  }

  Offset get fishingEdge {
    if (onBank) {
      return landConstrain(Offset(
          cat.dx,
          northBank!
              ? FishingRiver.top(cat.dx) - 26
              : FishingRiver.bottom(cat.dx) + 26));
    }
    final delta = cat - fishingSeaIsland.center;
    return fishingSeaIsland.center +
        (delta.distance > .01 ? delta / delta.distance : const Offset(-1, 0)) *
            (fishingSeaIsland.radiusTowards(cat) - 24);
  }

  Offset fishingWater(Offset edge) {
    if (onBank) {
      return FishingRiver.constrain(
          edge + Offset(facingRight ? 120 : -120, northBank! ? 175 : -175));
    }
    final delta = edge - fishingSeaIsland.center;
    return FishingRiver.constrain(edge + delta / delta.distance * 220);
  }

  /// Straight line if clear, otherwise along the mountain foot the short way.
  static List<Offset> _aroundMountain(Offset from, Offset to) {
    var blocked = false;
    for (var i = 1; i < 24; i++) {
      if (inMountain(Offset.lerp(from, to, i / 24)!, grow: 8)) {
        blocked = true;
        break;
      }
    }
    if (!blocked) return [to];
    final a0 = _mountainAngle(from), a1 = _mountainAngle(to);
    var delta = a1 - a0;
    while (delta > math.pi) {
      delta -= math.pi * 2;
    }
    while (delta < -math.pi) {
      delta += math.pi * 2;
    }
    final steps = math.max(2, (delta.abs() / .22).ceil());
    return [
      for (var i = 0; i <= steps; i++)
        constrain(mountainEdge(a0 + delta * i / steps, 30)),
      to,
    ];
  }

  void returnToBoat() {
    if (phase != IslandVisitPhase.exploring) return;
    climbDown();
    lookoutRequested = false;
    boardRequested = true;
    _routeTo(visitLanding);
  }

  void update(double dt) {
    clock += dt;
    elapsed += dt;
    if (phase == IslandVisitPhase.landing ||
        phase == IslandVisitPhase.boarding) {
      final boarding = phase == IslandVisitPhase.boarding;
      cat = Offset.lerp(
          boarding ? visitLanding : visitMooring,
          boarding ? visitMooring : visitLanding,
          (elapsed / .65).clamp(0.0, 1.0))!;
      if (elapsed >= .65) {
        phase = boarding ? IslandVisitPhase.aboard : IslandVisitPhase.exploring;
        elapsed = 0;
        boardRequested = false;
      }
    } else if (phase == IslandVisitPhase.exploring) {
      final target = _walkRoute.isNotEmpty ? _walkRoute.first : destination;
      if (target != null) {
        final delta = target - cat;
        if (delta.dx.abs() > .1) facingRight = delta.dx > 0;
        if (delta.distance <= 100 * dt) {
          cat = target;
          if (_walkRoute.isNotEmpty) _walkRoute.removeAt(0);
          if (_walkRoute.isEmpty) destination = null;
        } else {
          cat += delta / delta.distance * 100 * dt;
        }
      }
      if (caveRequested &&
          destination == null &&
          (cat - caveMouth).distance < 1) {
        caveRequested = false;
        caveArrived = true;
      } else if (lookoutRequested &&
          destination == null &&
          (cat - lookoutDoor).distance < 1) {
        lookoutRequested = false;
        lookout = true;
        cat = lookoutTop;
        facingRight = true;
      } else if (boardRequested && destination == null) {
        phase = IslandVisitPhase.boarding;
        elapsed = 0;
        facingRight = false;
      } else if (!onBank) {
        for (var i = 0; i < shellOffsets.length; i++) {
          if ((cat - (fishingSeaIsland.center + shellOffsets[i])).distance <
              23) {
            collectedShells.add(i);
          }
        }
      }
    }
    for (final crab in crabs) {
      final desired = fishingSeaIsland.center +
          Offset(math.sin(clock * .18 + crab.seed * 2) * 290,
              math.cos(clock * .22 + crab.seed * 2.7) * 270);
      var velocity = (desired - crab.position) * .8;
      final away = crab.position - cat;
      crab.fleeing = ashore && !onBank && away.distance < 75;
      if (crab.fleeing) {
        velocity +=
            (away.distance > .01 ? away / away.distance : const Offset(0, 1)) *
                (75 - away.distance) *
                2.2;
      }
      if (velocity.distance > 85) velocity = velocity / velocity.distance * 85;
      crab.position = constrainGround(crab.position + velocity * dt);
    }
  }
}
