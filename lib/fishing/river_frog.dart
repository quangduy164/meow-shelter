import 'dart:math' as math;
import 'package:flutter/painting.dart';
import 'fishing_river.dart';

enum RiverFrogPhase { sitting, jumping, submerged, returning }

/// A frog follows its own moving lily and only returns after the boat leaves.
class RiverFrog {
  RiverFrog(this.lilyIndex, this.seed, Offset home)
      : position = home,
        from = home,
        landing = home;
  final int lilyIndex, seed;
  RiverFrogPhase phase = RiverFrogPhase.sitting;
  Offset position, from, landing;
  double elapsed = 0;
  static const leapTime = .55;
  bool get airborne =>
      phase == RiverFrogPhase.jumping || phase == RiverFrogPhase.returning;
  double get jumpHeight => airborne
      ? math.sin((elapsed / leapTime).clamp(0.0, 1.0) * math.pi) * 32
      : 0;

  void update(double dt, Offset lily, Offset boat) {
    elapsed += dt;
    switch (phase) {
      case RiverFrogPhase.sitting:
        position = lily;
        if ((boat - lily).distance < 155) {
          final away = lily - boat;
          final direction =
              away.distance > .01 ? away / away.distance : const Offset(1, 0);
          from = lily;
          landing = FishingRiver.constrain(lily + direction * 75);
          phase = RiverFrogPhase.jumping;
          elapsed = 0;
        }
      case RiverFrogPhase.jumping:
      case RiverFrogPhase.returning:
        if (phase == RiverFrogPhase.returning) landing = lily;
        position =
            Offset.lerp(from, landing, (elapsed / leapTime).clamp(0.0, 1.0))!;
        if (elapsed >= leapTime) {
          phase = phase == RiverFrogPhase.jumping
              ? RiverFrogPhase.submerged
              : RiverFrogPhase.sitting;
          elapsed = 0;
        }
      case RiverFrogPhase.submerged:
        if (elapsed > 7 + seed % 5 && (boat - lily).distance > 240) {
          from = position;
          landing = lily;
          phase = RiverFrogPhase.returning;
          elapsed = 0;
        }
    }
  }
}
