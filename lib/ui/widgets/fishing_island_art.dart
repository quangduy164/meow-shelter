import 'dart:math' as math;
import 'package:material_ui/material_ui.dart';
import '../../fishing/fishing_island.dart';
import '../../fishing/fishing_river.dart';
import '../../fishing/river_sea_land.dart';
import 'fishing_water_art.dart';
import 'fishing_volcano_art.dart';
import '../../fishing/fishing_lighting.dart';

void paintIslandDock(Canvas c) {
  final p = FishingIslandVisit.dockTap - const Offset(18, 19);
  c.drawRect(Rect.fromLTWH(p.dx, p.dy + 6, 65, 38), _kFishingIslandArt0);
  for (var i = 0; i < 9; i++) {
    c.drawRect(
        Rect.fromLTWH(p.dx + i * 7.0, p.dy, 6, 38),
        Paint()
          ..color =
              i.isEven ? const Color(0xFFC69C65) : const Color(0xFFAC8051));
  }
  for (final x in [0.0, 60.0]) {
    for (final y in [0.0, 38.0]) {
      c.drawCircle(p + Offset(x, y), 4, _kFishingIslandArt1);
      c.drawCircle(p + Offset(x, y - 2), 3, _kFishingIslandArt2);
    }
  }
}

/// World minus the mountain, so shore foam never runs across the peaks.
final _noMountain = Path.combine(
    PathOperation.difference,
    Path()..addRect(const Rect.fromLTWH(0, 0, 20000, 4000)),
    mountainSilhouette());

// Reused every frame by the shells and crabs; colours set before each draw.
final _fill = Paint();
final _shellLine = Paint()
  ..color = const Color(0xFFC68E7A)
  ..strokeWidth = 1;
final _crabLeg = Paint()
  ..strokeWidth = 2
  ..strokeCap = StrokeCap.round;
final _shell = Path()
  ..moveTo(0, 5)
  ..lineTo(-8, -2)
  ..quadraticBezierTo(0, -12, 8, -2)
  ..close();

class FishingIslandPainter extends CustomPainter {
  FishingIslandPainter(this.round, Listenable frames) : super(repaint: frames);
  final FishingRiverRound round;
  @override
  void paint(Canvas c, Size size) {
    final island = round.island;
    final visible = Rect.fromLTWH(round.cameraLeft, round.cameraTop,
        round.visibleWidth, round.visibleHeight);
    if (island.onBank && (island.ashore || island.dockRequested)) {
      c.save();
      c.clipRect(Offset.zero & size);
      c.scale(round.scale);
      c.translate(-round.cameraLeft, -round.cameraTop);
      final point = island.visitLanding;
      c.drawOval(Rect.fromCenter(center: point, width: 38, height: 20),
          _kFishingIslandArt3);
      final post = point + const Offset(24, -6);
      c.drawLine(post, post - const Offset(0, 30), _kFishingIslandArt4);
      c.drawPath(
          Path()
            ..moveTo(post.dx, post.dy - 30)
            ..lineTo(post.dx + 19, post.dy - 23)
            ..lineTo(post.dx, post.dy - 17)
            ..close(),
          _kFishingIslandArt5);
      c.restore();
    }
    if (!visible
        .inflate(fishingSeaIsland.maxRadius + 80)
        .contains(fishingSeaIsland.center)) {
      return;
    }
    c.save();
    c.clipRect(Offset.zero & size);
    c.scale(round.scale);
    c.translate(-round.cameraLeft, -round.cameraTop);
    c.save();
    c.clipPath(_noMountain);
    paintIslandWash(c, round.clock);
    c.restore();
    paintVolcanoLive(c, round.clock, FishingLighting.at(round.hour).daylight);
    // Campfire flame on the south beach.
    final fire = fishingSeaIsland.center + const Offset(-210, 236);
    final flick =
        math.sin(round.clock * 13) * .5 + math.sin(round.clock * 7.3) * .5;
    c.drawCircle(fire, 34 + flick * 3,
        Paint()..color = Color.fromRGBO(255, 190, 90, .16 + flick * .03));
    for (final (dx, h, color) in const [
      (-6.0, 22.0, Color(0xFFE8642E)),
      (6.0, 18.0, Color(0xFFF08A3A)),
      (0.0, 26.0, Color(0xFFF6B547)),
      (0.0, 14.0, Color(0xFFFFE08A)),
    ]) {
      final top = h + flick * 4 * (dx == 0 ? 1 : -1);
      c.drawPath(
          Path()
            ..moveTo(fire.dx + dx - 7, fire.dy)
            ..quadraticBezierTo(fire.dx + dx - 8, fire.dy - top * .5,
                fire.dx + dx + flick * 2, fire.dy - top)
            ..quadraticBezierTo(
                fire.dx + dx + 8, fire.dy - top * .5, fire.dx + dx + 7, fire.dy)
            ..close(),
          Paint()..color = color);
    }
    // Rotating lighthouse beam; brighter while the cat is up on the gallery.
    final lamp = FishingIslandVisit.lighthouse +
        const Offset(0, -124 * FishingIslandVisit.lighthouseScale);
    final sweep = round.clock * .9;
    final strength = island.lookout ? .32 : .14;
    for (final a in [sweep, sweep + math.pi]) {
      final reach = 520 * (.55 + .45 * math.cos(a).abs());
      final dir = Offset(math.cos(a), math.sin(a) * .45);
      final side = Offset(-dir.dy, dir.dx);
      c.drawPath(
          Path()
            ..moveTo(lamp.dx, lamp.dy)
            ..lineTo((lamp + dir * reach + side * 60).dx,
                (lamp + dir * reach + side * 60).dy)
            ..lineTo((lamp + dir * reach - side * 60).dx,
                (lamp + dir * reach - side * 60).dy)
            ..close(),
          Paint()
            ..shader = RadialGradient(colors: [
              Color.fromRGBO(255, 236, 160, strength),
              const Color(0x00FFECA0),
            ]).createShader(Rect.fromCircle(center: lamp, radius: reach)));
    }
    c.drawCircle(lamp, 16,
        Paint()..color = Color.fromRGBO(255, 230, 140, strength + .2));
    if (island.ashore &&
        !island.onBank &&
        !island.lookout &&
        !island.lookoutRequested) {
      final pulse = math.sin(round.clock * 3) * 2;
      c.drawOval(
          Rect.fromCenter(
              center: FishingIslandVisit.lighthouseDoor + const Offset(0, 6),
              width: 44 + pulse,
              height: 18 + pulse),
          _kFishingIslandArt6);
    }
    if (!island.ashore) {
      final pulse = math.sin(round.clock * 3) * 2;
      c.drawOval(
          Rect.fromCenter(
              center: FishingIslandVisit.dockTap,
              width: 36 + pulse,
              height: 22 + pulse),
          _kFishingIslandArt6);
    }
    for (var i = 0; i < FishingIslandVisit.shellOffsets.length; i++) {
      if (island.collectedShells.contains(i)) continue;
      final p = fishingSeaIsland.center + FishingIslandVisit.shellOffsets[i];
      c.drawOval(
          Rect.fromCenter(center: p + const Offset(1, 3), width: 15, height: 6),
          _fill..color = const Color(0x3386755A));
      c
        ..save()
        ..translate(p.dx, p.dy)
        ..drawPath(
            _shell,
            _fill
              ..color =
                  i.isEven ? const Color(0xFFF9BFA8) : const Color(0xFFFFF0CC))
        ..restore();
      for (final dx in [-4.0, 0.0, 4.0]) {
        c.drawLine(p + const Offset(0, 4), p + Offset(dx, -4), _shellLine);
      }
      if ((round.clock + i) % 3 < .7) {
        c.drawCircle(
            p + const Offset(7, -7), 2, _fill..color = const Color(0xFFFFF8DE));
      }
    }
    for (final crab in island.crabs) {
      final p = crab.position;
      final leg =
          math.sin(round.clock * (crab.fleeing ? 22 : 8) + crab.seed) * 3;
      final paint = _crabLeg..color = const Color(0xFFB76F4B);
      for (final side in [-1.0, 1.0]) {
        for (var j = 0; j < 3; j++) {
          c.drawLine(
              p + Offset(side * 5, j * 3 - 2.0),
              p + Offset(side * (12 + (j.isEven ? leg : -leg)), j * 4 - 3.0),
              paint);
        }
        c.drawLine(p + Offset(side * 5, -2), p + Offset(side * 11, -10), paint);
        c.drawCircle(p + Offset(side * 12, -10), 3,
            paint..color = const Color(0xFFE59A64));
        paint.color = const Color(0xFFB76F4B);
      }
      c.drawOval(Rect.fromCenter(center: p, width: 18, height: 12),
          _fill..color = const Color(0xFFD98558));
      for (final x in [-4.0, 4.0]) {
        c.drawCircle(
            p + Offset(x, -6), 2.5, _fill..color = const Color(0xFFFFE4AA));
        c.drawCircle(
            p + Offset(x, -7), 1.3, _fill..color = const Color(0xFF534A3D));
      }
    }
    c.restore();
  }

  @override
  bool shouldRepaint(FishingIslandPainter old) => old.round != round;
}

// Constant paints shared by every frame (hoisted out of the paint loops).
final _kFishingIslandArt0 = Paint()..color = const Color(0x33436560);
final _kFishingIslandArt1 = Paint()..color = const Color(0xFF785B40);
final _kFishingIslandArt2 = Paint()..color = const Color(0xFFE1BB80);
final _kFishingIslandArt3 = Paint()
  ..color = const Color(0x99FFF1B8)
  ..style = PaintingStyle.stroke
  ..strokeWidth = 2;
final _kFishingIslandArt4 = Paint()
  ..color = const Color(0xFF8D704A)
  ..strokeWidth = 4;
final _kFishingIslandArt5 = Paint()..color = const Color(0xFFE4AE61);
final _kFishingIslandArt6 = Paint()
  ..color = const Color(0xAAFFF3B7)
  ..style = PaintingStyle.stroke
  ..strokeWidth = 2;
