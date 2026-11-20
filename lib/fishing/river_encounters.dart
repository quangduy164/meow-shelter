import 'dart:math' as math;
import 'package:flutter/painting.dart';
import 'fishing_river.dart';

enum TurtlePhase { basking, diving, hidden, returning }

class RiverTurtle {
  RiverTurtle(this.rock, this.radius, this.seed) : position = rock;
  final Offset rock;
  final double radius;
  final int seed;
  TurtlePhase phase = TurtlePhase.basking;
  Offset position, water = Offset.zero;
  double elapsed = 0;
  void update(double dt, Offset boat, bool Function(Offset) clearWater) {
    elapsed += dt;
    switch (phase) {
      case TurtlePhase.basking:
        position = rock;
        if ((boat - rock).distance < 195) {
          final away = rock - boat;
          final angle = away.distance > .01 ? away.direction : 0.0;
          for (var i = 0; i < 12; i++) {
            final target = FishingRiver.constrain(rock +
                Offset.fromDirection(angle + i * math.pi / 6, radius + 90));
            if (!clearWater(target)) continue;
            water = target;
            phase = TurtlePhase.diving;
            elapsed = 0;
            break;
          }
        }
      case TurtlePhase.diving:
        position = Offset.lerp(rock, water, (elapsed / .65).clamp(0.0, 1.0))!;
        if (elapsed >= .65) {
          phase = TurtlePhase.hidden;
          elapsed = 0;
        }
      case TurtlePhase.hidden:
        if (elapsed > 10 + seed % 6 && (boat - rock).distance > 290) {
          phase = TurtlePhase.returning;
          elapsed = 0;
        }
      case TurtlePhase.returning:
        position = Offset.lerp(water, rock, (elapsed / 1.3).clamp(0.0, 1.0))!;
        if ((boat - rock).distance < 195) {
          phase = TurtlePhase.diving;
          elapsed = (1 - elapsed / 1.3).clamp(0.0, 1.0) * .65;
        } else if (elapsed >= 1.3) {
          phase = TurtlePhase.basking;
          elapsed = 0;
        }
    }
  }
}

/// Sparse local events: world timers do not reroll when the camera scrolls.
class RiverJumpFish {
  RiverJumpFish(this.homeX, this.seed) : wait = 3.0 + seed % 7;
  final double homeX;
  final int seed;
  double wait, elapsed = 0;
  bool active = false;
  Offset start = Offset.zero, end = Offset.zero;
  static const airTime = .8;
  bool get airborne => active && elapsed < airTime;
  Offset get position =>
      Offset.lerp(start, end, (elapsed / airTime).clamp(0.0, 1.0))!;
  double get height =>
      airborne ? math.sin(elapsed / airTime * math.pi) * 60 : 0;
  void update(double dt, Offset boat, bool Function(Offset) clearWater) {
    if (active) {
      elapsed += dt;
      if (elapsed > airTime + 1.2) {
        active = false;
        wait = 18.0 + seed % 11;
      }
      return;
    }
    wait = math.max(0, wait - dt);
    if (wait > 0 || (boat.dx - homeX).abs() > 420) return;
    final direction = seed.isEven ? 1.0 : -1.0;
    final from = FishingRiver.constrain(
        boat + Offset(direction * 155, seed.isEven ? -65 : 75));
    final to = FishingRiver.constrain(from + Offset(direction * 100, 20));
    for (var i = 0; i <= 6; i++) {
      if (!clearWater(Offset.lerp(from, to, i / 6)!)) {
        wait = 3;
        return;
      }
    }
    start = from;
    end = to;
    elapsed = 0;
    active = true;
  }
}
