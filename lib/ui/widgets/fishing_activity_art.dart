import 'dart:math' as math;
import 'package:flutter/painting.dart';
import '../../fishing/fishing_activity.dart';

// Reused every frame; colours are set right before each draw.
final _stroke = Paint()
  ..style = PaintingStyle.stroke
  ..strokeWidth = 1.8;
final _thinStroke = Paint()
  ..style = PaintingStyle.stroke
  ..strokeWidth = 1;
final _fill = Paint();
final _line = Paint()..strokeWidth = 1.5;

/// Fades by scaling each colour's alpha instead of an offscreen saveLayer.
void paintFishingActivity(
    Canvas canvas, FishingActivity activity, double clock) {
  final age = activity.age;
  final fade = math
      .min(1.0, math.min(age / .7, (FishingActivities.duration - age) / 1.2))
      .clamp(0.0, 1.0);
  if (fade <= 0) return;
  Color a(Color c) => c.withValues(alpha: c.a * fade);
  final p = activity.position;
  canvas.save();
  canvas.translate(p.dx, p.dy);
  switch (activity.kind) {
    case FishingActivityKind.splash:
      final cycle = age % 3.4;
      for (var i = 0; i < 3; i++) {
        final t = (cycle - i * .28) / 2.1;
        if (t < 0 || t > 1) continue;
        canvas.drawOval(
            Rect.fromCenter(
                center: const Offset(0, 3),
                width: 12 + t * 100,
                height: 5 + t * 33),
            _stroke..color = a(Color.fromRGBO(230, 255, 241, (1 - t) * .9)));
      }
      if (cycle < .85) {
        final t = cycle / .85;
        canvas.save();
        canvas.translate(-18 + t * 36, -math.sin(t * math.pi) * 28);
        canvas.rotate(-.5 + t * 1.4);
        canvas.drawOval(const Rect.fromLTWH(-12, -5, 24, 10),
            _fill..color = a(const Color(0xFF7299A4)));
        canvas.drawPath(_splashTail, _fill..color = a(const Color(0xFF5B7F91)));
        canvas.drawLine(const Offset(-6, -2), const Offset(5, -2),
            _line..color = a(const Color(0xFFCBDFCA)));
        canvas.restore();
        _fill.color = a(const Color(0xDDDBFFF0));
        for (var i = 0; i < 4; i++) {
          canvas.drawCircle(
              Offset((i - 1.5) * 15 * t, -math.sin(t * math.pi) * (12 + i * 4)),
              2 * (1 - t),
              _fill);
        }
      }
    case FishingActivityKind.bubbles:
      _thinStroke.color = a(const Color(0x88FFFFFF));
      for (var i = 0; i < 7; i++) {
        final t = (age * .48 + i * .17) % 1;
        final point = Offset(math.sin(i * 2.4) * 24 + math.sin(clock + i) * 3,
            math.cos(i * 1.6) * 10 - t * 18);
        canvas.drawCircle(
            point,
            2 + t * 4,
            _stroke
              ..color = a(
                  Color.fromRGBO(221, 255, 241, math.sin(t * math.pi) * .85)));
        canvas.drawArc(Rect.fromCircle(center: point, radius: 2 + t * 4), 3.6,
            1.2, false, _thinStroke);
      }
      canvas.drawOval(const Rect.fromLTWH(-25, 5, 50, 13),
          _fill..color = a(const Color(0x22406465)));
    case FishingActivityKind.shadow:
      canvas.save();
      canvas.translate(math.sin(age * .7) * 14, math.cos(age * .8) * 5);
      canvas.rotate(math.sin(age * .6) * .22);
      canvas.drawOval(const Rect.fromLTWH(-33, -10, 66, 20),
          _fill..color = a(const Color(0x88325262)));
      final wag = math.sin(age * 4) * 4;
      canvas.drawPath(
          Path()
            ..moveTo(-25, 0)
            ..lineTo(-49, -13 + wag)
            ..quadraticBezierTo(-42, wag, -49, 13 + wag)
            ..close(),
          _fill);
      canvas.drawPath(_shadowFin, _fill..color = a(const Color(0x55325262)));
      canvas.restore();
      for (var i = 0; i < 2; i++) {
        final t = (age * .3 + i * .5) % 1;
        canvas.drawArc(
            Rect.fromCenter(
                center: Offset(27 + t * 7, 1),
                width: 25 + t * 40,
                height: 10 + t * 14),
            -.9,
            1.8,
            false,
            _stroke..color = a(Color.fromRGBO(220, 255, 241, (1 - t) * .6)));
      }
  }
  canvas.restore();
}

final _splashTail = Path()
  ..moveTo(-9, 0)
  ..lineTo(-19, -6)
  ..lineTo(-19, 6)
  ..close();

final _shadowFin = Path()
  ..moveTo(-9, -5)
  ..lineTo(0, -17)
  ..lineTo(12, -6)
  ..close();
