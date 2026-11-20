import 'dart:math' as math;
import 'package:flutter/painting.dart';
import 'fishing_river.dart';

enum FishingActivityKind { splash, bubbles, shadow }

class FishingActivity {
  const FishingActivity(
      this.cell, this.cycle, this.position, this.age, this.kind);
  final int cell, cycle;
  final Offset position;
  final double age;
  final FishingActivityKind kind;
}

/// Timed sightings use world time, so scrolling cannot respawn or reroll them.
class FishingActivities {
  static const spacing = 520.0, period = 27.0, duration = 16.0;
  static const castDistance = 330.0;
  final _used = <int, int>{};

  Iterable<FishingActivity> visible(
      double clock, double left, double right) sync* {
    for (var cell = 0; cell * spacing < FishingRiver.length; cell++) {
      if (cell * spacing > right + 120 || (cell + 1) * spacing < left - 120) {
        continue;
      }
      final time = clock + cell * 4.7;
      final cycle = (time / period).floor();
      final age = time % period;
      if (age >= duration || _used[cell] == cycle) continue;
      final rng = math.Random(cell * 7919 + cycle * 103 + 71);
      final x = (cell * spacing + 250 + rng.nextDouble() * 140)
          .clamp(100.0, FishingRiver.length - 100);
      final position = FishingRiver.constrain(Offset(
          x,
          FishingRiver.center(x) +
              (rng.nextDouble() - .5) *
                  (FishingRiver.halfWidth(x) - FishingRiver.boatMargin) *
                  1.8));
      yield FishingActivity(
          cell,
          cycle,
          position,
          age,
          FishingActivityKind
              .values[(cell + cycle) % FishingActivityKind.values.length]);
    }
  }

  FishingActivity? nearby(double clock, Offset boat) {
    FishingActivity? best;
    var distance = castDistance;
    for (final activity
        in visible(clock, boat.dx - castDistance, boat.dx + castDistance)) {
      final d = (activity.position - boat).distance;
      if (d < distance) {
        best = activity;
        distance = d;
      }
    }
    return best;
  }

  void consume(FishingActivity activity) =>
      _used[activity.cell] = activity.cycle;
}
