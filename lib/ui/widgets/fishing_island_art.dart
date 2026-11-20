import 'dart:math' as math;
import 'package:material_ui/material_ui.dart';
import '../../fishing/fishing_island.dart';
import '../../fishing/fishing_river.dart';
import '../../fishing/river_sea_land.dart';

void paintIslandDock(Canvas c) {
  final p = FishingIslandVisit.dockTap - const Offset(18, 19);
  c.drawRect(Rect.fromLTWH(p.dx, p.dy + 6, 65, 38),
      Paint()..color = const Color(0x33436560));
  for (var i = 0; i < 9; i++) {
    c.drawRect(
        Rect.fromLTWH(p.dx + i * 7.0, p.dy, 6, 38),
        Paint()
          ..color =
              i.isEven ? const Color(0xFFC69C65) : const Color(0xFFAC8051));
  }
  for (final x in [0.0, 60.0]) {
    for (final y in [0.0, 38.0]) {
      c.drawCircle(
          p + Offset(x, y), 4, Paint()..color = const Color(0xFF785B40));
      c.drawCircle(
          p + Offset(x, y - 2), 3, Paint()..color = const Color(0xFFE1BB80));
    }
  }
}

class FishingIslandPainter extends CustomPainter {
  FishingIslandPainter(this.round, Listenable frames) : super(repaint: frames);
  final FishingRiverRound round;
  @override
  void paint(Canvas c, Size size) {
    final island = round.island;
    final visible = Rect.fromLTWH(round.cameraLeft, round.cameraTop,
        round.visibleWidth, round.visibleHeight);
    if (!visible
        .inflate(fishingSeaIsland.radius + 80)
        .contains(fishingSeaIsland.center)) {
      return;
    }
    c.save();
    c.clipRect(Offset.zero & size);
    c.scale(round.scale);
    c.translate(-round.cameraLeft, -round.cameraTop);
    if (!island.ashore) {
      final pulse = math.sin(round.clock * 3) * 2;
      c.drawOval(
          Rect.fromCenter(
              center: FishingIslandVisit.dockTap,
              width: 36 + pulse,
              height: 22 + pulse),
          Paint()
            ..color = const Color(0xAAFFF3B7)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
    }
    for (var i = 0; i < FishingIslandVisit.shellOffsets.length; i++) {
      if (island.collectedShells.contains(i)) continue;
      final p = fishingSeaIsland.center + FishingIslandVisit.shellOffsets[i];
      c.drawOval(
          Rect.fromCenter(center: p + const Offset(1, 3), width: 15, height: 6),
          Paint()..color = const Color(0x3386755A));
      final shell = Path()
        ..moveTo(p.dx, p.dy + 5)
        ..lineTo(p.dx - 8, p.dy - 2)
        ..quadraticBezierTo(p.dx, p.dy - 12, p.dx + 8, p.dy - 2)
        ..close();
      c.drawPath(
          shell,
          Paint()
            ..color =
                i.isEven ? const Color(0xFFF9BFA8) : const Color(0xFFFFF0CC));
      for (final dx in [-4.0, 0.0, 4.0]) {
        c.drawLine(
            p + const Offset(0, 4),
            p + Offset(dx, -4),
            Paint()
              ..color = const Color(0xFFC68E7A)
              ..strokeWidth = 1);
      }
      if ((round.clock + i) % 3 < .7) {
        c.drawCircle(p + const Offset(7, -7), 2,
            Paint()..color = const Color(0xFFFFF8DE));
      }
    }
    for (final crab in island.crabs) {
      final p = crab.position;
      final leg =
          math.sin(round.clock * (crab.fleeing ? 22 : 8) + crab.seed) * 3;
      final paint = Paint()
        ..color = const Color(0xFFB76F4B)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
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
          Paint()..color = const Color(0xFFD98558));
      for (final x in [-4.0, 4.0]) {
        c.drawCircle(
            p + Offset(x, -6), 2.5, Paint()..color = const Color(0xFFFFE4AA));
        c.drawCircle(
            p + Offset(x, -7), 1.3, Paint()..color = const Color(0xFF534A3D));
      }
    }
    c.restore();
  }

  @override
  bool shouldRepaint(FishingIslandPainter old) => old.round != round;
}
