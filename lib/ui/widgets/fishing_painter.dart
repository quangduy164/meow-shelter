import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../fishing/fishing_controller.dart';
import '../../collection/fish_species.dart';

class FishingPainter extends CustomPainter {
  const FishingPainter(
      {required this.phase,
      required this.fish,
      required this.spot,
      required this.clock,
      required this.elapsed,
      required this.progress,
      required this.tension,
      required this.pulling});
  final FishingPhase phase;
  final FishSpecies fish;
  final Offset spot;
  final double clock, elapsed, progress, tension;
  final bool pulling;

  @override
  void paint(Canvas canvas, Size size) {
    final tip = _drawRod(canvas, size);
    if (phase == FishingPhase.ready || phase == FishingPhase.lost) return;
    var bobber = Offset(spot.dx * size.width, spot.dy * size.height);
    if (phase == FishingPhase.casting) {
      final t = (elapsed / .65).clamp(0.0, 1.0);
      bobber =
          Offset.lerp(tip, bobber, t)! - Offset(0, math.sin(t * math.pi) * 80);
    } else if (phase == FishingPhase.reeling) {
      bobber += Offset(math.sin(clock * 8) * 7, math.cos(clock * 7) * 3);
    } else {
      bobber += Offset(
          0,
          math.sin(clock * (phase == FishingPhase.bite ? 22 : 3)) *
              (phase == FishingPhase.bite ? 7 : 2));
    }
    final line = Paint()
      ..color = const Color(0xCCF4F5DB)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    final taut = phase == FishingPhase.reeling && progress > .78;
    if (taut) {
      canvas.drawLine(tip, bobber, line);
    } else {
      canvas.drawPath(
          Path()
            ..moveTo(tip.dx, tip.dy)
            ..quadraticBezierTo((tip.dx + bobber.dx) / 2,
                bobber.dy - (pulling ? 30 : 0), bobber.dx, bobber.dy),
          line);
    }
    final ripple = Paint()
      ..color = const Color(0xAACFF8EF)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < 3; i++) {
      final t = (clock * .7 + i / 3) % 1;
      canvas.drawOval(
          Rect.fromCenter(
              center: bobber + const Offset(0, 5),
              width: 12 + t * 45,
              height: 4 + t * 12),
          ripple..color = Color.fromRGBO(215, 255, 246, (1 - t) * .7));
    }
    canvas.drawLine(
        bobber - const Offset(0, 15),
        bobber + const Offset(0, 4),
        Paint()
          ..color = const Color(0xFF593822)
          ..strokeWidth = 2);
    canvas.drawOval(Rect.fromCenter(center: bobber, width: 9, height: 15),
        Paint()..color = Colors.white);
    canvas.drawOval(
        Rect.fromCenter(
            center: bobber - const Offset(0, 3), width: 9, height: 9),
        Paint()..color = const Color(0xFFE25536));
    if (phase == FishingPhase.bite || phase == FishingPhase.caught) {
      final painter = TextPainter(
          text: TextSpan(
              text: phase == FishingPhase.bite ? '!' : '+1',
              style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFFFF0AF),
                  shadows: [Shadow(color: Color(0xFF573215), blurRadius: 3)])),
          textDirection: TextDirection.ltr)
        ..layout();
      painter.paint(canvas, bobber - Offset(painter.width / 2, 58));
    }
  }

  Offset _drawRod(Canvas canvas, Size size) {
    Offset point(double x, double y) => Offset(x * size.width, y * size.height);
    final load = phase == FishingPhase.reeling ? tension : 0.0;
    final base = point(.73, .88);
    final control = point(.65, .45 - (pulling ? .025 : 0));
    final tip = point(.595 - load * .025,
        .43 + load * .10 + (pulling ? math.sin(clock * 9) * .004 : 0));
    Offset shaft(double t) =>
        base * ((1 - t) * (1 - t)) +
        control * (2 * (1 - t) * t) +
        tip * (t * t);
    Offset tangent(double t) =>
        (control - base) * (1 - t) + (tip - control) * t;
    Offset guide(double t) {
      final direction = tangent(t);
      return shaft(t) +
          Offset(direction.dy, -direction.dx) / direction.distance * 3.5;
    }

    final handleAngle =
        math.atan2(control.dy - base.dy, control.dx - base.dx) + math.pi / 2;
    final reel = base +
        Offset(-12 * math.cos(handleAngle) + 17 * math.sin(handleAngle),
            -12 * math.sin(handleAngle) - 17 * math.cos(handleAngle));
    const guides = [.30, .52, .73, .90, 1.0];
    final stroke = Paint()..strokeCap = StrokeCap.round;
    for (var i = 0; i < 24; i++) {
      final t = i / 24;
      canvas.drawLine(
          shaft(t),
          shaft((i + 1) / 24),
          stroke
            ..color = const Color(0xFF254D49)
            ..strokeWidth = 4.5 - t * 3);
      canvas.drawLine(
          shaft(t) + const Offset(-.6, 0),
          shaft((i + 1) / 24) + const Offset(-.6, 0),
          stroke
            ..color = const Color(0xFF8FB8A2)
            ..strokeWidth = 1.2 - t * .7);
    }
    final threadedLine = Path()..moveTo(reel.dx, reel.dy);
    for (final t in guides) {
      final eye = guide(t);
      threadedLine.lineTo(eye.dx, eye.dy);
    }
    canvas.drawPath(
        threadedLine,
        Paint()
          ..color = const Color(0xCCF4F5DB)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1);
    for (final t in guides) {
      final center = shaft(t);
      final direction = tangent(t);
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(math.atan2(direction.dy, direction.dx));
      canvas.drawLine(
          const Offset(-2, 0),
          const Offset(2, 0),
          stroke
            ..color = const Color(0xFFD7B76C)
            ..strokeWidth = 3);
      canvas.drawOval(
          const Rect.fromLTWH(-2, -6, 4, 5),
          Paint()
            ..color = const Color(0xFFDFE4D4)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1);
      canvas.restore();
    }
    canvas.save();
    canvas.translate(base.dx, base.dy);
    canvas.rotate(handleAngle);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(-4, -34, 8, 40), const Radius.circular(3)),
        Paint()..color = const Color(0xFF725338));
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(-3, -32, 5, 35), const Radius.circular(2)),
        Paint()..color = const Color(0xFFD5AF75));
    for (var i = 0; i < 7; i++) {
      canvas.drawLine(
          Offset(-3, -28 + i * 4.0),
          Offset(3, -27 + i * 4.0),
          stroke
            ..color = const Color(0x887A5D3D)
            ..strokeWidth = .8);
    }
    canvas.drawRect(const Rect.fromLTWH(-4, -38, 8, 5),
        Paint()..color = const Color(0xFFDBD5BA));
    canvas.scale(-1, 1);
    canvas.drawLine(
        const Offset(3, -24),
        const Offset(11, -20),
        stroke
          ..color = const Color(0xFF3B5350)
          ..strokeWidth = 3);
    canvas.drawCircle(
        const Offset(12, -17), 8, Paint()..color = const Color(0xFF284C49));
    canvas.drawCircle(
        const Offset(12, -17), 6, Paint()..color = const Color(0xFFE1C486));
    canvas.drawCircle(
        const Offset(12, -17),
        3.5,
        Paint()
          ..color = const Color(0xFF91AAA0)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
    final crank = const Offset(12, -17) +
        Offset.fromDirection(pulling ? clock * 8 : .6, 10);
    canvas.drawLine(
        const Offset(12, -17),
        crank,
        stroke
          ..color = const Color(0xFFE7DEBC)
          ..strokeWidth = 2);
    canvas.drawCircle(crank, 2.5, Paint()..color = const Color(0xFF725338));
    canvas.restore();
    return guide(1);
  }

  @override
  bool shouldRepaint(covariant FishingPainter oldDelegate) => true;
}
