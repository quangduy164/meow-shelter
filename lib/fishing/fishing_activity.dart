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

/// Active water ("cá động") on a square grid over the whole map, so open
/// sea, the bay and the island shores get sightings too, not just the main
/// channel. Cells on land are skipped.
///
/// Each cell runs its own [period]: visible for [duration], then gone. A
/// fixed random per (cell, cycle) decides whether it shows ([density]) and
/// where, so scrolling never rerolls a sighting. The clock is real time
/// ([worldClock]), so reopening the mode keeps the same sightings.
class FishingActivities {
  static const cell = 560.0, period = 27.0, duration = 16.0;
  static const castDistance = 330.0;
  static int get columns => (FishingRiver.length / cell).ceil();
  static int get rows => (FishingRiver.height / cell).ceil();

  /// Share of cells with a sighting this cycle; set from the hour and
  /// weather by [densityAt].
  double density = .55;

  /// Real seconds (wrapping every 10 days), shared by every session.
  static double worldClock([DateTime? now]) =>
      ((now ?? DateTime.now()).millisecondsSinceEpoch % 864000000) / 1000;

  /// Fish feed more at dawn and dusk and in the rain.
  static double densityAt(double hour, {double rain = 0}) {
    double bell(double at) =>
        math.max(0.0, 1 - (hour - at).abs() / 1.5).toDouble();
    final feeding = math.max(bell(6), bell(18));
    return (.5 + feeding * .25 + rain * .2).clamp(0.0, .85).toDouble();
  }

  final _used = <int, int>{};

  Iterable<FishingActivity> visible(double clock, double left, double right,
      {double top = 0, double bottom = FishingRiver.height}) sync* {
    final c0 = math.max(0, ((left - 120) / cell).floor());
    final c1 = math.min(columns - 1, ((right + 120) / cell).floor());
    final r0 = math.max(0, ((top - 120) / cell).floor());
    final r1 = math.min(rows - 1, ((bottom + 120) / cell).floor());
    for (var col = c0; col <= c1; col++) {
      for (var row = r0; row <= r1; row++) {
        final id = col * rows + row;
        final time = clock + col * 4.7 + row * 7.3;
        final cycle = (time / period).floor();
        final age = time % period;
        if (age >= duration || _used[id] == cycle) continue;
        final rng = math.Random(id * 7919 + cycle * 103 + 71);
        if (rng.nextDouble() > density) continue;
        // A few tries for open water inside the cell, away from the banks.
        Offset? spot;
        for (var k = 0; k < 4 && spot == null; k++) {
          final p = Offset(col * cell + 60 + rng.nextDouble() * (cell - 120),
              row * cell + 60 + rng.nextDouble() * (cell - 120));
          if (FishingRiver.contains(p) &&
              FishingRiver.contains(p + const Offset(0, 40)) &&
              FishingRiver.contains(p - const Offset(0, 40))) {
            spot = p;
          }
        }
        if (spot == null) continue;
        yield FishingActivity(
            id,
            cycle,
            spot,
            age,
            FishingActivityKind
                .values[(id + cycle) % FishingActivityKind.values.length]);
      }
    }
  }

  /// Closest reachable sighting, optionally inside a 120-degree forward cone.
  FishingActivity? nearby(double clock, Offset boat,
      {double reach = 1, Offset? direction, bool Function(Offset)? canReach}) {
    FishingActivity? best;
    final range = castDistance * reach;
    var distance = range;
    for (final activity in visible(clock, boat.dx - range, boat.dx + range,
        top: boat.dy - range, bottom: boat.dy + range)) {
      final delta = activity.position - boat;
      final d = delta.distance;
      if (direction != null &&
          direction.distance > .001 &&
          delta.dx * direction.dx + delta.dy * direction.dy <=
              .5 * d * direction.distance) {
        continue;
      }
      if (d < distance && (canReach == null || canReach(activity.position))) {
        best = activity;
        distance = d;
      }
    }
    return best;
  }

  void consume(FishingActivity activity) =>
      _used[activity.cell] = activity.cycle;
}
