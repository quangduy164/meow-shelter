import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/painting.dart';
import 'herd_desert.dart';
import 'herd_round.dart';

/// Heat gauge and overheated rest, drawn on top of each desert cat.
void paintCatHeat(Canvas canvas, HerdCat cat) {
  if (cat.heat < .25 && cat.overheat == 0) return;
  final at = cat.position.toOffset();
  if (cat.overheat > 0) {
    // Wavy steam lines rise from an overheated, resting cat.
    for (var i = -1; i <= 1; i++) {
      final base = at + Offset(i * 7.0, -24);
      final path = Path()..moveTo(base.dx, base.dy);
      for (var k = 1; k <= 3; k++) {
        path.quadraticBezierTo(base.dx + (k.isOdd ? 3 : -3),
            base.dy - k * 4 + 2, base.dx, base.dy - k * 4);
      }
      canvas.drawPath(
          path,
          Paint()
            ..color = const Color(0xBBFFFFFF)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5
            ..strokeCap = StrokeCap.round);
    }
    return;
  }
  final bar =
      Rect.fromCenter(center: at + const Offset(0, -29), width: 24, height: 5);
  canvas.drawRRect(
      RRect.fromRectAndRadius(bar.inflate(1), const Radius.circular(3)),
      Paint()..color = const Color(0xCC5A3214));
  final color = Color.lerp(const Color(0xFFF6C453), const Color(0xFFE0533E),
      ((cat.heat - .25) / .75).clamp(0.0, 1.0))!;
  canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(bar.left, bar.top, bar.width * cat.heat.clamp(0.0, 1.0),
              bar.height),
          const Radius.circular(2)),
      Paint()..color = color);
  if (cat.heat > .7) {
    // Sweat drop warns that this cat is about to sit down.
    final drop = at + const Offset(13, -18);
    canvas.drawPath(
        Path()
          ..moveTo(drop.dx, drop.dy - 5)
          ..quadraticBezierTo(drop.dx + 4, drop.dy, drop.dx, drop.dy + 2)
          ..quadraticBezierTo(drop.dx - 4, drop.dy, drop.dx, drop.dy - 5),
        Paint()..color = const Color(0xFF8CCBE8));
  }
}

/// Approaching dust wall, then blowing sand over the whole field.
void paintDesertStorm(Canvas canvas, Size size, HerdRound round) {
  final t = round.time;
  final dir = HerdSandstorm.direction(t);
  if (HerdSandstorm.warning(t)) {
    final edge = dir > 0 ? 0.0 : size.width - 70;
    final band = Rect.fromLTWH(edge, 66, 70, size.height - 66);
    final pulse = .5 + .5 * math.sin(t * 10);
    canvas.drawRect(
        band,
        Paint()
          ..shader = LinearGradient(
              begin: dir > 0 ? Alignment.centerLeft : Alignment.centerRight,
              end: dir > 0 ? Alignment.centerRight : Alignment.centerLeft,
              colors: [
                Color.fromRGBO(196, 140, 80, .35 + .2 * pulse),
                const Color(0x00C48C50)
              ]).createShader(band));
    // Arrows show which way the wind will push.
    for (var i = 0; i < 3; i++) {
      final y = size.height * (.35 + i * .2);
      final x = dir > 0 ? 28.0 : size.width - 28;
      final paint = Paint()
        ..color = const Color(0xCC8A5A2E)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(x - 12 * dir, y), Offset(x + 10 * dir, y), paint);
      canvas.drawLine(
          Offset(x + 10 * dir, y), Offset(x + 3 * dir, y - 6), paint);
      canvas.drawLine(
          Offset(x + 10 * dir, y), Offset(x + 3 * dir, y + 6), paint);
    }
  }
  if (!HerdSandstorm.blowing(t)) return;
  canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0x5CC99A5E));
  final streak = Paint()
    ..color = const Color(0xD9F6E4BC)
    ..strokeWidth = 2.4
    ..strokeCap = StrokeCap.round;
  for (var i = 0; i < 64; i++) {
    final speed = 260 + (i % 5) * 40.0;
    final y = 70 + (i * 37.0) % (size.height - 70);
    var x = (i * 97.0 + t * speed) % (size.width + 60) - 30;
    if (dir < 0) x = size.width - x;
    canvas.drawLine(Offset(x, y), Offset(x - 28 * dir, y - 3), streak);
  }
}
