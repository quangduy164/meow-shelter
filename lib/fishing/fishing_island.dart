import 'dart:math' as math;
import 'package:flutter/painting.dart';
import 'river_sea_land.dart';

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
  static const shellOffsets = [
    Offset(-330, -130),
    Offset(280, -240),
    Offset(280, 200),
    Offset(-250, 250),
    Offset(40, -315),
    Offset(45, 330)
  ];
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
  double get jump =>
      phase == IslandVisitPhase.landing || phase == IslandVisitPhase.boarding
          ? math.sin((elapsed / .65).clamp(0.0, 1.0) * math.pi) * 28
          : 0;
  static bool contains(Offset p) =>
      (p - fishingSeaIsland.center).distance <= fishingSeaIsland.radius;
  static Offset constrain(Offset p) {
    final delta = p - fishingSeaIsland.center;
    final radius = fishingSeaIsland.radius - 22;
    return delta.distance > radius
        ? fishingSeaIsland.center + delta / delta.distance * radius
        : p;
  }

  void beginLanding() {
    dockRequested = false;
    boardRequested = false;
    destination = null;
    phase = IslandVisitPhase.landing;
    elapsed = 0;
    cat = mooring;
    facingRight = true;
  }

  void walkTo(Offset point) {
    if (phase != IslandVisitPhase.exploring) return;
    boardRequested = false;
    destination = constrain(point);
  }

  void returnToBoat() {
    if (phase != IslandVisitPhase.exploring) return;
    boardRequested = true;
    destination = landing;
  }

  void update(double dt) {
    clock += dt;
    elapsed += dt;
    if (phase == IslandVisitPhase.landing ||
        phase == IslandVisitPhase.boarding) {
      final boarding = phase == IslandVisitPhase.boarding;
      cat = Offset.lerp(boarding ? landing : mooring,
          boarding ? mooring : landing, (elapsed / .65).clamp(0.0, 1.0))!;
      if (elapsed >= .65) {
        phase = boarding ? IslandVisitPhase.aboard : IslandVisitPhase.exploring;
        elapsed = 0;
        boardRequested = false;
      }
    } else if (phase == IslandVisitPhase.exploring) {
      final target = destination;
      if (target != null) {
        final delta = target - cat;
        if (delta.dx.abs() > .1) facingRight = delta.dx > 0;
        if (delta.distance <= 100 * dt) {
          cat = target;
          destination = null;
        } else {
          cat += delta / delta.distance * 100 * dt;
        }
      }
      if (boardRequested && destination == null) {
        phase = IslandVisitPhase.boarding;
        elapsed = 0;
        facingRight = false;
      } else {
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
      crab.fleeing = ashore && away.distance < 75;
      if (crab.fleeing) {
        velocity +=
            (away.distance > .01 ? away / away.distance : const Offset(0, 1)) *
                (75 - away.distance) *
                2.2;
      }
      if (velocity.distance > 85) velocity = velocity / velocity.distance * 85;
      crab.position = constrain(crab.position + velocity * dt);
    }
  }
}
