import 'dart:math' as math;
import 'package:flutter/painting.dart';
import '../night_cards.dart';
import '../night_run.dart';
import '../night_variants.dart';

class ReedPatch {
  ReedPatch(this.index, this.area);
  final int index;
  final Rect area;
  bool occupied = false, baited = false, paid = false, chimed = false;
  double cool = 0, bait = 0, shake = 0;
  Offset get center => area.center;
}

class ReedTrail {
  ReedTrail(this.from, this.to, this.left, this.total);
  final ReedPatch from, to;
  double left;
  final double total;
}

/// Hidden-cat positions only. The scene owns sprites, fish stock and rewards.
class ReedGarden {
  static const rows = 3, columns = 4;
  final patches = <ReedPatch>[];
  final exits = <ReedPatch>[];
  final trails = <ReedTrail>[];
  double moveSeconds = 4.5, trailSeconds = 2.5, bellLeft = 0;
  bool softParting = false, bell = false;
  int baitReach = 1;

  void begin(NightRun run) {
    final windy = run.variant == NightVariant.reedWindy;
    moveSeconds = (windy ? 3.2 : 4.5) *
        math.pow(1.3, run.count(NightCard.stillReeds)).toDouble();
    trailSeconds = (run.variant == NightVariant.reedMist ? 1.6 : 2.5) +
        2.0 * run.count(NightCard.dewTracks);
    baitReach = run.variant == NightVariant.reedMist ? 2 : 1;
    softParting = run.has(NightCard.softParting);
    bell = run.has(NightCard.reedBell);
    bellLeft = 8;
    patches
      ..clear()
      ..addAll([
        for (var i = 0; i < rows * columns; i++)
          ReedPatch(
              i,
              Rect.fromCenter(
                  center: Offset(
                      .26 + (i % columns) * .16, .30 + (i ~/ columns) * .22),
                  width: .12,
                  height: .16))
      ]);
    exits
      ..clear()
      ..addAll([
        ReedPatch(
            -1,
            Rect.fromCenter(
                center: const Offset(.08, .52), width: .1, height: .5)),
        ReedPatch(
            -2,
            Rect.fromCenter(
                center: const Offset(.92, .52), width: .1, height: .5)),
      ]);
    trails.clear();
  }

  bool blocks(Rect bounds) =>
      patches.any((p) => p.area.deflate(.012).overlaps(bounds));
  ReedPatch? at(Offset point, Size field) => patches
      .where((p) => p.area
          .contains(Offset(point.dx / field.width, point.dy / field.height)))
      .firstOrNull;
  Iterable<ReedPatch> neighbors(ReedPatch patch, {int reach = 1}) =>
      patches.where((p) =>
          p != patch && (p.center - patch.center).distance <= .25 * reach);
  ReedPatch? emptyNear(ReedPatch from, math.Random random, {int reach = 1}) {
    final choices = neighbors(from, reach: reach)
        .where((p) => !p.occupied && !p.baited)
        .toList();
    return choices.isEmpty ? null : choices[random.nextInt(choices.length)];
  }

  Iterable<ReedPatch> exitsNear(ReedPatch patch) => [
        if (patch.index >= 0 && patch.index % columns == 0) exits[0],
        if (patch.index >= 0 && patch.index % columns == columns - 1) exits[1],
      ];

  /// A rustle pushes a neighbour one bush straight on, away from the sound.
  /// Past the outer column that is a basket; past the top or bottom row, or
  /// into a taken bush, the cat stays put.
  ReedPatch? fleeTarget(ReedPatch from, ReedPatch rustle) {
    final step = from.center - rustle.center;
    final target = from.center + step;
    for (final exit in exitsNear(from)) {
      if (step.dy.abs() < .01 &&
          (exit.center.dx - from.center.dx) * step.dx > 0) {
        return exit;
      }
    }
    return patches
        .where((p) =>
            (p.center - target).distance < .02 && !p.occupied && !p.baited)
        .firstOrNull;
  }

  void move(ReedPatch from, ReedPatch to) {
    from.occupied = false;
    to.occupied = to.index >= 0;
    from.shake = to.shake = .7;
    trails.add(ReedTrail(from, to, trailSeconds, trailSeconds));
  }

  bool bait(ReedPatch patch, {required bool paid}) {
    if (patch.occupied || patch.baited || patch.cool > 0) return false;
    patch
      ..baited = true
      ..paid = paid
      ..bait = 1.2;
    return true;
  }

  /// Returns a patch whose hidden cat should flash for Chuông lau.
  ReedPatch? update(double dt, math.Random random) {
    for (final p in patches) {
      p.cool = math.max(0, p.cool - dt);
      p.bait = math.max(0, p.bait - dt);
      p.shake = math.max(0, p.shake - dt);
    }
    for (final t in trails) {
      t.left -= dt;
    }
    trails.removeWhere((t) => t.left <= 0);
    if (!bell) return null;
    bellLeft -= dt;
    if (bellLeft > 0) return null;
    bellLeft = 8;
    final hidden = patches.where((p) => p.occupied).toList();
    if (hidden.isEmpty) return null;
    final patch = hidden[random.nextInt(hidden.length)]..shake = 1.4;
    return patch;
  }
}
