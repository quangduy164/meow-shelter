import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../fishing/fishing_controller.dart';
import '../../fishing/fishing_lighting.dart';
import '../../collection/fish_species.dart';
import 'fishing_lake_layout.dart';

class FishingWaterPainter extends CustomPainter {
  const FishingWaterPainter(
      {required this.clock,
      required this.lighting,
      required this.fish,
      required this.phase,
      required this.spot,
      required this.progress});
  final double clock, progress;
  final FishingPhase phase;
  final FishSpecies fish;
  final FishingLighting lighting;
  final Offset spot;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 1000, size.height / 600);
    canvas.clipPath(Path()..addOval(const Rect.fromLTWH(214, 293, 572, 212)));
    canvas.saveLayer(const Rect.fromLTWH(214, 293, 572, 212),
        Paint()..colorFilter = lighting.terrainFilter);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    _surfaceRipples(canvas, const Offset(375, 371), 7.5, 0, 112);
    _surfaceRipples(canvas, const Offset(615, 427), 9.3, 3.1, 145);
    for (var row = 0; row < 18; row++) {
      final y = 303 + row * 11.0;
      for (var segment = 0; segment < 4; segment++) {
        final x = 220 + segment * 150 + math.sin(row * 3.2) * 22;
        final wave = Path();
        for (var step = 0; step <= 12; step++) {
          final px = x + step * 7;
          final py = y + math.sin(px * .035 + clock * 1.5 + row) * 2.5;
          if (step == 0) {
            wave.moveTo(px, py);
          } else {
            wave.lineTo(px, py);
          }
        }
        canvas.drawPath(
            wave,
            stroke
              ..strokeWidth = 1.2
              ..color = Color.fromRGBO(
                  207, 255, 239, .12 + .07 * math.sin(clock + row).abs()));
      }
    }
    for (var i = 0; i < 7; i++) {
      final speed = .12 + (i % 3) * .035;
      final angle = clock * speed + i * 2.3;
      final rx = 125 + (i % 3) * 35.0;
      final ry = 35 + (i % 2) * 22.0;
      final position =
          Offset(500 + math.cos(angle) * rx, 400 + math.sin(angle) * ry);
      final heading = math.atan2(math.cos(angle) * ry, -math.sin(angle) * rx);
      _fish(canvas, position, heading, clock * 7 + i, 14 + i % 3 * 3.0,
          i.isEven ? const Color(0x55305762) : const Color(0x557B9A69));
      final bubbleTime = (clock * .24 + i * .19) % 1;
      if (bubbleTime < .35) {
        canvas.drawOval(
            Rect.fromCenter(
                center: position + const Offset(0, -8),
                width: 4 + bubbleTime * 60,
                height: 2 + bubbleTime * 20),
            stroke
              ..strokeWidth = 1
              ..color =
                  Color.fromRGBO(225, 255, 246, (.35 - bubbleTime) * .65));
      }
    }
    final fighting =
        phase == FishingPhase.bite || phase == FishingPhase.reeling;
    if (fighting) {
      var target = FishingLakeLayout.toScene(spot);
      if (phase == FishingPhase.reeling) {
        target = Offset.lerp(target, const Offset(680, 468), progress)!;
      }
      if (!fish.isJunk) {
        _fish(canvas, target + Offset(math.sin(clock * 8) * 13, 9),
            math.sin(clock * 5) * .6, clock * 14, 24, const Color(0x8832535B));
      }
      for (var i = 0; i < 4; i++) {
        final t = (clock * 1.6 + i / 4) % 1;
        canvas.drawOval(
            Rect.fromCenter(
                center: target, width: 12 + t * 95, height: 5 + t * 30),
            stroke
              ..strokeWidth = 2
              ..color = Color.fromRGBO(238, 255, 246, (1 - t) * .75));
        final angle = i * math.pi / 2 + clock;
        canvas.drawCircle(
            target +
                Offset(math.cos(angle) * 22 * t,
                    -math.sin(t * math.pi) * 17 + math.sin(angle) * 6),
            (1 - t) * 2.5,
            Paint()..color = const Color(0xBBE8FFF3));
      }
    }
    canvas.restore();
    final reflectionX = lighting.celestialPosition.dx * 1000;
    final opacity = lighting.moonVisible
        ? lighting.night * .36
        : .16 + lighting.warmth * .22;
    for (var i = 0; i < 24; i++) {
      final t = i / 24;
      final shimmer = math.sin(clock * 1.3 + i * 2.1);
      canvas.drawOval(
          Rect.fromCenter(
              center:
                  Offset(reflectionX + shimmer * (3 + t * 10), 307 + t * 172),
              width: (9 + t * 62) * (.75 + shimmer.abs() * .25),
              height: 1.5 + t * 1.5),
          Paint()
            ..color = lighting.reflection.withOpacity(opacity * (1 - t) * .8));
    }
    canvas.restore();
  }

  void _surfaceRipples(
      Canvas canvas, Offset origin, double period, double delay, double width) {
    final time = clock - delay;
    if (time < 0) return;
    final cycle = (time / period).floor();
    final elapsed = time % period;
    // Each surfacing stays at one position, followed by a quiet interval.
    final center =
        origin + Offset(math.sin(cycle * 2.4) * 20, math.cos(cycle * 1.8) * 7);
    for (var ring = 0; ring < 3; ring++) {
      final t = (elapsed - ring * .65) / 2.8;
      if (t <= 0 || t >= 1) continue;
      final opacity = math.sin(math.pi * t) * (1 - t) * .8;
      canvas.drawOval(
          Rect.fromCenter(
              center: center,
              width: 5 + width * t,
              height: 2 + width * .22 * t),
          Paint()
            ..color = Color.fromRGBO(224, 255, 245, opacity)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6 - t * .7);
    }
    if (elapsed < .7) {
      final t = elapsed / .7;
      canvas.drawOval(
          Rect.fromCenter(
              center: center, width: 7 + math.sin(t * math.pi) * 6, height: 4),
          Paint()
            ..color =
                Color.fromRGBO(39, 100, 112, math.sin(t * math.pi) * .45));
      for (var i = 0; i < 3; i++) {
        canvas.drawCircle(
            center +
                Offset((i - 1) * 6 * t, -math.sin(t * math.pi) * (7 + i * 3)),
            1.6 * (1 - t),
            Paint()..color = Color.fromRGBO(229, 255, 248, (1 - t) * .7));
      }
    }
  }

  void _fish(Canvas canvas, Offset position, double heading, double tailTime,
      double length, Color color) {
    canvas.save();
    canvas.translate(position.dx, position.dy);
    canvas.rotate(heading);
    canvas.scale(1, .7);
    final tail = math.sin(tailTime) * length * .17;
    final paint = Paint()..color = color;
    canvas.drawPath(
        Path()
          ..moveTo(length * .6, 0)
          ..cubicTo(length * .25, -length * .42, -length * .4, -length * .3,
              -length * .5, 0)
          ..cubicTo(-length * .4, length * .3, length * .25, length * .42,
              length * .6, 0)
          ..close(),
        paint);
    canvas.drawPath(
        Path()
          ..moveTo(-length * .4, 0)
          ..lineTo(-length, -length * .32 + tail)
          ..quadraticBezierTo(-length * .8, tail, -length, length * .32 + tail)
          ..close(),
        paint);
    canvas.drawPath(
        Path()
          ..moveTo(0, 0)
          ..lineTo(-length * .25, -length * .5)
          ..lineTo(length * .15, -length * .14)
          ..close(),
        paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant FishingWaterPainter oldDelegate) =>
      clock != oldDelegate.clock ||
      lighting.hour != oldDelegate.lighting.hour ||
      phase != oldDelegate.phase ||
      fish != oldDelegate.fish ||
      spot != oldDelegate.spot ||
      progress != oldDelegate.progress;
}
