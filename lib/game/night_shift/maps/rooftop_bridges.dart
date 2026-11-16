import 'dart:math' as math;
import 'package:flutter/painting.dart';
import '../moonlight.dart';
import '../night_cards.dart';
import '../night_run.dart';
import '../night_variants.dart';

class RoofBridge {
  RoofBridge(this.gap, this.y, [this.row = 0]);
  final int row;
  final int gap;
  final double y;
  double open = 0, cool = 0, ember = 0, repair = 0;
  bool firstOpen = true, autoUsed = false;
  bool get active => open > 0 || ember > 0;
  bool get ready => open <= 0 && cool <= 0 && repair <= 0;
}

/// Rooftops are separated by gaps. Cats can walk across only while a plank is
/// lowered; the moon and safety lights on planks still calm cats.
class RooftopBridges {
  static const gaps = [
    Rect.fromLTWH(.34, .18, .06, .58),
    Rect.fromLTWH(.60, .18, .06, .58),
  ];
  static const restTime = 6.0;
  static const baitArea = Rect.fromLTRB(.40, .25, .60, .74);

  bool allowsBait(Offset point, Size field) => baitArea
      .contains(Offset(point.dx / field.width, point.dy / field.height));

  Offset spawnPosition(Size field, Size cat, math.Random random) {
    final roof = random.nextInt(3);
    final minX = field.width * const [.04, .40, .66][roof];
    final maxX = field.width * const [.34, .60, .96][roof] - cat.width;
    final minY = field.height * .25;
    final maxY = math.max(minY,
        math.min(field.height * .56, field.height * .76 - cat.height * .88));
    return Offset(minX + random.nextDouble() * math.max(0, maxX - minX),
        minY + random.nextDouble() * (maxY - minY));
  }

  Offset? lureWaypoint(Rect bounds, Offset target, Size field) {
    final foot = Offset(bounds.center.dx, bounds.bottom - bounds.height * .12);
    final x = foot.dx / field.width;
    if (x >= gaps[0].right && x <= gaps[1].left) return target;
    final gapIndex = x < gaps[0].right ? 0 : 1;
    final gap = gaps[gapIndex];
    final choices =
        bridges.where((b) => b.gap == gapIndex && b.active).toList();
    if (choices.isEmpty) return null;
    double cost(RoofBridge b) =>
        (Offset(gap.center.dx * field.width, b.y * field.height) - foot)
            .distance;
    choices.sort((a, b) => cost(a).compareTo(cost(b)));
    final bridge = choices.first;
    final y = bridge.y * field.height;
    final fromLeft = gapIndex == 0;
    final entryX =
        (fromLeft ? gap.left - .015 : gap.right + .015) * field.width;
    final exitX = (fromLeft ? gap.right + .015 : gap.left - .015) * field.width;
    final insideGap = x >= gap.left && x <= gap.right;
    final atEntry = (fromLeft
            ? foot.dx >= entryX - field.width * .007
            : foot.dx <= entryX + field.width * .007) &&
        (foot.dy - y).abs() <= corridor(bridge).height * field.height * .2;
    final nextFoot = Offset(insideGap || atEntry ? exitX : entryX, y);
    return nextFoot - Offset(0, bounds.height * .38);
  }

  final moon = Moonlight();
  final bridges = <RoofBridge>[];
  double openTime = 16, cooldown = restTime, widthScale = 1, afterglow = 0;
  bool safetyLights = false,
      paired = false,
      lastStep = false,
      automatic = false;
  final opened = <(RoofBridge, bool)>[];

  void begin(NightRun run,
      {required bool thickClouds, required double afterglowSeconds}) {
    moon.reset(fullMoon: run.has(NightCard.fullMoon), thickClouds: thickClouds);
    afterglow = afterglowSeconds;
    paired = run.has(NightCard.pairedBridges);
    lastStep = run.has(NightCard.lastStep);
    automatic = run.has(NightCard.autoBridge);
    opened.clear();
    openTime = (16 + 8 * run.count(NightCard.sturdyPlanks)) /
        (run.has(NightCard.stormyRoof) ? 2 : 1);
    cooldown = restTime * math.pow(.5, run.count(NightCard.quickCarpenter));
    widthScale = 1 + .5 * run.count(NightCard.widePlanks);
    safetyLights = run.has(NightCard.railLights);
    bridges
      ..clear()
      ..addAll([
        for (var gap = 0; gap < gaps.length; gap++)
          for (var row = 0; row < 2; row++)
            RoofBridge(
                gap,
                run.variant == NightVariant.roofStaggered
                    ? (gap == 0 ? const [.30, .56] : const [.40, .66])[row]
                    : const [.34, .58][row],
                row),
      ]);
    if (run.variant == NightVariant.roofRepair) {
      bridges[(run.night ~/ 3) % bridges.length].repair = 10;
    }
  }

  bool lower(RoofBridge bridge, {bool auto = false}) {
    if (!bridge.ready) return false;
    bridge.open = openTime;
    opened.add((bridge, auto));
    if (paired) {
      final other =
          bridges.firstWhere((b) => b.gap != bridge.gap && b.row == bridge.row);
      if (other.ready) {
        other.open = math.min(openTime, 6);
        opened.add((other, false));
      }
    }
    return true;
  }

  void update(double dt, {Iterable<Rect> occupied = const []}) {
    moon.update(dt);
    for (final bridge in bridges) {
      bridge.repair = math.max(0, bridge.repair - dt);
      if (bridge.open > 0) {
        if (lastStep &&
            occupied.any((bounds) {
              final foot =
                  Offset(bounds.center.dx, bounds.bottom - bounds.height * .12);
              return gaps[bridge.gap].contains(foot) &&
                  corridor(bridge).contains(foot);
            })) {
          bridge.open = math.max(bridge.open, dt + .1);
        }
        bridge.open = math.max(0, bridge.open - dt);
        if (bridge.open <= 0) {
          bridge.cool = cooldown;
          bridge.ember = afterglow;
        }
      } else {
        final wasCooling = bridge.cool > 0;
        bridge.cool = math.max(0, bridge.cool - dt);
        if (wasCooling && bridge.cool == 0 && automatic && !bridge.autoUsed) {
          bridge.autoUsed = true;
          lower(bridge, auto: true);
        }
        bridge.ember = math.max(0, bridge.ember - dt);
      }
    }
  }

  Rect corridor(RoofBridge bridge) {
    final gap = gaps[bridge.gap];
    return Rect.fromCenter(
        center: Offset(gap.center.dx, bridge.y),
        width: gap.width + .035,
        height: .11 * widthScale);
  }

  /// Uses a cat's foot point, so the 80px sprite can cross a narrow plank.
  bool blocks(Rect bounds) {
    final foot = Offset(bounds.center.dx, bounds.bottom - bounds.height * .12);
    for (final gap in gaps) {
      // Prevent walking around the top or bottom of a roof gap.
      if (foot.dx < gap.left || foot.dx >= gap.right) continue;
      return !bridges.any((bridge) =>
          bridge.active &&
          gaps[bridge.gap] == gap &&
          corridor(bridge).contains(foot));
    }
    return false;
  }

  Rect bridgeRect(RoofBridge bridge, Size size) {
    final r = corridor(bridge);
    return Rect.fromLTRB(r.left * size.width, r.top * size.height,
        r.right * size.width, r.bottom * size.height);
  }

  bool bridgeLit(Offset point, Size size) => bridges.any((bridge) =>
      bridge.active &&
      (bridgeRect(bridge, size).inflate(safetyLights ? 45 : 16))
          .contains(point));
  bool isLit(Offset point, Size size) =>
      moon.contains(point, size) || bridgeLit(point, size);
}
