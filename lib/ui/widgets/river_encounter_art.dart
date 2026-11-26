import 'dart:math' as math;
import 'package:flutter/painting.dart';
import '../../fishing/fishing_river.dart';
import '../../fishing/river_encounters.dart';

void paintRiverEncounters(Canvas c, FishingRiverRound round, Rect visible) {
  final view = visible.inflate(100);
  for (final turtle in round.props.turtles) {
    if (!view.contains(turtle.position)) continue;
    if (turtle.phase == TurtlePhase.hidden) {
      if (turtle.elapsed < 1.2) _splash(c, turtle.water, turtle.elapsed / 1.2);
      continue;
    }
    final diving = turtle.phase == TurtlePhase.diving;
    final t = (turtle.elapsed / (diving ? .65 : 1.3)).clamp(0.0, 1.0);
    final size = diving
        ? 1 - t * .7
        : turtle.phase == TurtlePhase.returning
            ? .4 + t * .6
            : 1.0;
    c.save();
    c.translate(turtle.position.dx, turtle.position.dy - 8 * size);
    final face = turtle.phase == TurtlePhase.basking
        ? 1.0
        : (diving
                ? turtle.water.dx - turtle.rock.dx
                : turtle.rock.dx - turtle.water.dx)
            .sign;
    c.scale(size * (face == 0 ? 1 : face), size);
    final p = Paint()..color = const Color(0xFF79986B);
    for (final side in [-1.0, 1.0]) {
      for (final x in [-8.0, 8.0]) {
        c.drawOval(
            Rect.fromCenter(
                center:
                    Offset(x, side * (7 + math.sin(round.clock * 3 + x) * 1.2)),
                width: 9,
                height: 6),
            p);
      }
    }
    c.drawOval(const Rect.fromLTWH(-15, -10, 30, 20), _kRiverEncounterArt0);
    c.drawOval(const Rect.fromLTWH(-12, -9, 25, 16), _kRiverEncounterArt1);
    c.drawPath(
        Path()
          ..moveTo(-8, -4)
          ..lineTo(0, -7)
          ..lineTo(8, -3)
          ..lineTo(8, 3)
          ..lineTo(0, 6)
          ..lineTo(-8, 3)
          ..close(),
        _kRiverEncounterArt2);
    c.drawOval(const Rect.fromLTWH(11, -5, 13, 9), p);
    if ((round.clock + turtle.seed) % 6 < 5.7) {
      c.drawCircle(const Offset(20, -4), 1.4, _kRiverEncounterArt3);
    } else {
      c.drawLine(
          const Offset(18, -4), const Offset(21, -4), _kRiverEncounterArt4);
    }
    c.restore();
  }
  for (final fish in round.props.jumpingFish) {
    if (!fish.active || !view.contains(fish.position)) continue;
    if (!fish.airborne) {
      _splash(c, fish.end, (fish.elapsed - RiverJumpFish.airTime) / 1.2);
      continue;
    }
    final t = fish.elapsed / RiverJumpFish.airTime;
    final point = fish.position;
    c.drawOval(Rect.fromCenter(center: point, width: 22, height: 6),
        _kRiverEncounterArt5);
    c.save();
    c.translate(point.dx, point.dy - fish.height);
    final face = fish.end.dx > fish.start.dx ? 1.0 : -1.0;
    c.scale(face, 1);
    c.rotate((t - .5) * 1.3);
    final color = fish.homeX < FishingRiver.seaStart
        ? const Color(0xFFB3CAA1)
        : const Color(0xFFB4DBDC);
    c.drawOval(const Rect.fromLTWH(-17, -8, 34, 16), Paint()..color = color);
    c.drawPath(
        Path()
          ..moveTo(-12, 0)
          ..lineTo(-25, -9)
          ..lineTo(-23, 9)
          ..close(),
        _kRiverEncounterArt6);
    c.drawArc(const Rect.fromLTWH(-15, -8, 30, 16), math.pi, math.pi, false,
        _kRiverEncounterArt7);
    c.drawOval(const Rect.fromLTWH(-8, 1, 18, 5), _kRiverEncounterArt8);
    c.drawCircle(const Offset(11, -2), 2, _kRiverEncounterArt9);
    c.drawCircle(const Offset(11.5, -2.5), .6, _kRiverEncounterArt10);
    c.restore();
    if (t < .18) _splash(c, fish.start, t / .18 * .35);
  }
}

void _splash(Canvas c, Offset p, double t) {
  t = t.clamp(0.0, 1.0);
  for (var i = 0; i < 2; i++) {
    c.drawOval(
        Rect.fromCenter(
            center: p, width: 15 + t * 62 + i * 12, height: 7 + t * 24 + i * 5),
        Paint()
          ..color = Color.fromRGBO(224, 251, 233, (1 - t) * .7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);
  }
  if (t < .45) {
    for (var i = 0; i < 5; i++) {
      final a = i * math.pi / 4;
      c.drawCircle(
          p +
              Offset(math.cos(a) * t * 65,
                  -math.sin(a) * math.sin(t / .45 * math.pi) * 23),
          2,
          _kRiverEncounterArt11);
    }
  }
}

// Constant paints shared by every frame (hoisted out of the paint loops).
final _kRiverEncounterArt0 = Paint()..color = const Color(0xFF516B51);
final _kRiverEncounterArt1 = Paint()..color = const Color(0xFF91A66B);
final _kRiverEncounterArt2 = Paint()
  ..color = const Color(0xFF627E55)
  ..style = PaintingStyle.stroke
  ..strokeWidth = 1.3;
final _kRiverEncounterArt3 = Paint()..color = const Color(0xFF2D493D);
final _kRiverEncounterArt4 = Paint()
  ..color = const Color(0xFF2D493D)
  ..strokeWidth = 1;
final _kRiverEncounterArt5 = Paint()..color = const Color(0x334A7375);
final _kRiverEncounterArt6 = Paint()..color = const Color(0xFF638F91);
final _kRiverEncounterArt7 = Paint()
  ..color = const Color(0xFF608F91)
  ..strokeWidth = 3
  ..style = PaintingStyle.stroke;
final _kRiverEncounterArt8 = Paint()..color = const Color(0xFFE2E9CE);
final _kRiverEncounterArt9 = Paint()..color = const Color(0xFF314E55);
final _kRiverEncounterArt10 = Paint()..color = const Color(0xFFF9F1D0);
final _kRiverEncounterArt11 = Paint()..color = const Color(0xBBE0F2DE);
