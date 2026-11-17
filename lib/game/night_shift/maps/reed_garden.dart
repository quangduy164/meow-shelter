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
        for (final (i, c) in const [
          Offset(.30, .36),
          Offset(.50, .36),
          Offset(.70, .36),
          Offset(.30, .68),
          Offset(.50, .68),
          Offset(.70, .68),
        ].indexed)
          ReedPatch(i, Rect.fromCenter(center: c, width: .14, height: .18))
      ]);
    exits
      ..clear()
      ..addAll([
        ReedPatch(
            -1,
            Rect.fromCenter(
                center: const Offset(.075, .52), width: .1, height: .2)),
        ReedPatch(
            -2,
            Rect.fromCenter(
                center: const Offset(.925, .52), width: .1, height: .2)),
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
          p != patch && (p.center - patch.center).distance <= .33 * reach);
  ReedPatch? emptyNear(ReedPatch from, math.Random random, {int reach = 1}) {
    final choices = neighbors(from, reach: reach)
        .where((p) => !p.occupied && !p.baited)
        .toList();
    return choices.isEmpty ? null : choices[random.nextInt(choices.length)];
  }

  Iterable<ReedPatch> exitsNear(ReedPatch patch) => [
        if (patch.index == 0 || patch.index == 3) exits[0],
        if (patch.index == 2 || patch.index == 5) exits[1],
      ];

  /// A rustle pushes a neighbour farther away; exits rescue the cat.
  ReedPatch? fleeTarget(ReedPatch from, ReedPatch rustle) {
    final start = (from.center - rustle.center).distance;
    final choices = [
      ...neighbors(from).where((p) => p != rustle && !p.occupied && !p.baited),
      ...exitsNear(from),
    ].where((p) => (p.center - rustle.center).distance > start + .01).toList()
      ..sort((a, b) {
        final exit = (b.index < 0 ? 1 : 0) - (a.index < 0 ? 1 : 0);
        if (exit != 0) return exit;
        return (b.center - rustle.center)
            .distance
            .compareTo((a.center - rustle.center).distance);
      });
    return choices.firstOrNull;
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
  ReedPatch? update(double dt) {
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
    final patch = hidden.first..shake = 1.4;
    return patch;
  }
}
