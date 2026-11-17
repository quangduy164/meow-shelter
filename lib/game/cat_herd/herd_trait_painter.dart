import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/painting.dart';
import 'herd_round.dart';
import 'herd_traits.dart';

/// Personality marks drawn over a cat: snores, crowns, butterflies, alarms.
void paintCatTrait(Canvas canvas, HerdCat cat, double time) {
  final at = cat.position.toOffset();
  switch (cat.trait) {
    case HerdTrait.sleepy:
      if (cat.awake) return;
      // Same drifting "z"s as camp naps; a ring fills while the leader waits.
      if (!cat.following) _snore(canvas, at, time + cat.id, cat.facingLeft);
      if (cat.wake > 0) {
        canvas.drawArc(
            Rect.fromCircle(center: at + const Offset(0, -33), radius: 8),
            -math.pi / 2,
            math.pi * 2 * cat.wake,
            false,
            Paint()
              ..color = const Color(0xFFF2B33D)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3.5
              ..strokeCap = StrokeCap.round);
      }
    case HerdTrait.curious:
      if (cat.lured && !cat.following) {
        // Happily batting the yarn / sniffing the fish: little hearts.
        for (var i = 0; i < 2; i++) {
          final rise = (time * .8 + i * .5) % 1;
          _heart(canvas, at + Offset(-8 + i * 16.0, -28 - rise * 14),
              Color.fromRGBO(232, 104, 128, 1 - rise));
        }
      } else if (cat.distracted > 0) {
        _butterfly(
            canvas, cat.wanderTo.toOffset() + const Offset(0, -22), time);
      } else if (cat.following && cat.itch < HerdTraits.warnBefore) {
        final shake = math.sin(time * 30) * 2;
        _bubble(canvas, at + Offset(shake, -34), '!', const Color(0xFFE0533E));
        _butterfly(canvas, at + Offset(26 + math.sin(time * 3) * 6, -30), time);
      } else if (!cat.following) {
        _bubble(
            canvas, at + const Offset(0, -34), '?', const Color(0xFF5B8FCF));
      }
    case HerdTrait.golden:
      _crown(canvas, at + const Offset(0, -27));
      for (var i = 0; i < 4; i++) {
        final angle = time * 1.5 + i * math.pi / 2;
        final twinkle = .5 + .5 * math.sin(time * 6 + i * 2);
        _sparkle(
            canvas,
            at + Offset(math.cos(angle) * 20, math.sin(angle) * 12 - 6),
            2.5 + twinkle * 2,
            Color.fromRGBO(255, 214, 90, .5 + twinkle * .5));
      }
    case HerdTrait.chubby:
      if (cat.stuck > 0) {
        // Squashed against the flap: alarm bubble and sweat drops.
        _bubble(
            canvas, at + const Offset(0, -36), '!', const Color(0xFFE0533E));
        _text(canvas, 'Kẹt!', at + const Offset(12, -32), 11,
            const Color(0xFFB8463E));
        for (var i = 0; i < 2; i++) {
          final fall = (time * 2 + i * .5) % 1;
          canvas.drawCircle(at + Offset(-14 + i * 28.0, -14 + fall * 10),
              2.4 * (1 - fall), Paint()..color = const Color(0xCC8CCBE8));
        }
      } else if (cat.following && cat.velocity.length > 20) {
        // Puffing clouds behind the slow, heavy walker.
        for (var i = 0; i < 2; i++) {
          final t = (time * 1.8 + i * .5) % 1;
          canvas.drawCircle(
              at + Offset((cat.facingLeft ? 16 : -16) * (1 + t), 6 - t * 6),
              3 + t * 3,
              Paint()..color = Color.fromRGBO(255, 255, 255, .7 * (1 - t)));
        }
      }
    case HerdTrait.shy:
      if (cat.fleeing) {
        // Panicked dash: speed lines and a yelp.
        for (var i = 0; i < 3; i++) {
          final dx = cat.facingLeft ? 16.0 : -16.0;
          canvas.drawLine(
              at + Offset(dx, -8 + i * 7.0),
              at + Offset(dx * 2, -8 + i * 7.0),
              Paint()
                ..color = const Color(0xAA5A3214)
                ..strokeWidth = 2
                ..strokeCap = StrokeCap.round);
        }
        _text(canvas, 'Aaa!', at + const Offset(-14, -40), 11,
            const Color(0xFF8E5BC9));
      } else if (cat.hidden) {
        // Trembling behind cover; the ring fills while the leader coaxes.
        _bubble(
            canvas, at + const Offset(0, -26), '…', const Color(0xFF8E5BC9));
        if (cat.coax > 0) {
          canvas.drawArc(
              Rect.fromCircle(center: at + const Offset(0, -26), radius: 11),
              -math.pi / 2,
              math.pi * 2 * cat.coax,
              false,
              Paint()
                ..color = const Color(0xFFF2B33D)
                ..style = PaintingStyle.stroke
                ..strokeWidth = 3
                ..strokeCap = StrokeCap.round);
        }
      } else if (!cat.following) {
        _bubble(
            canvas, at + const Offset(0, -34), '!?', const Color(0xFF8E5BC9));
      } else {
        // Ears back: a small purple worry mark while in the herd.
        _text(canvas, '~', at + Offset(-16, -30 + math.sin(time * 9) * 1.5), 12,
            const Color(0xFF8E5BC9));
      }
    case HerdTrait.sulky:
      if (cat.sulking) {
        // A little rain cloud over a cat with its back turned.
        final cloud = at + Offset(math.sin(time * 2) * 2, -36);
        for (final (dx, r) in [(-7.0, 6.0), (0.0, 8.0), (7.0, 6.0)]) {
          canvas.drawCircle(cloud + Offset(dx, 0), r,
              Paint()..color = const Color(0xFF8F98A6));
        }
        for (var i = 0; i < 3; i++) {
          final fall = (time * 2.5 + i / 3) % 1;
          canvas.drawLine(
              cloud + Offset(-6 + i * 6.0, 6 + fall * 10),
              cloud + Offset(-7 + i * 6.0, 10 + fall * 10),
              Paint()
                ..color = const Color(0xCC6FB8DA)
                ..strokeWidth = 1.6
                ..strokeCap = StrokeCap.round);
        }
        _text(canvas, 'Hứ!', at + const Offset(12, -24), 11,
            const Color(0xFFB8463E));
        if (cat.coax > 0) {
          canvas.drawArc(
              Rect.fromCircle(center: at + const Offset(0, -36), radius: 13),
              -math.pi / 2,
              math.pi * 2 * cat.coax,
              false,
              Paint()
                ..color = const Color(0xFFF2B33D)
                ..style = PaintingStyle.stroke
                ..strokeWidth = 3
                ..strokeCap = StrokeCap.round);
        }
      } else if (!cat.following) {
        // Small grumpy cloud: this one sulks if left behind.
        final cloud = at + const Offset(0, -34);
        for (final (dx, r) in [(-5.0, 4.5), (0.0, 6.0), (5.0, 4.5)]) {
          canvas.drawCircle(cloud + Offset(dx, 0), r,
              Paint()..color = const Color(0xFFA9B1BD));
        }
      }
    case HerdTrait.normal:
      return;
  }
}

void _snore(Canvas canvas, Offset c, double clock, bool left) {
  final side = left ? -1.0 : 1.0;
  final paint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  for (var i = 0; i < 3; i++) {
    final t = (clock * .45 + i / 3) % 1;
    final s = 5 + t * 5;
    final o = c + Offset(side * (12 + t * 14) - s / 2, -16 - t * 24);
    paint.color =
        const Color(0xFF5A3214).withValues(alpha: .85 * math.sin(math.pi * t));
    canvas.drawPath(
        Path()
          ..moveTo(o.dx, o.dy)
          ..lineTo(o.dx + s, o.dy)
          ..lineTo(o.dx, o.dy + s)
          ..lineTo(o.dx + s, o.dy + s),
        paint);
  }
}

/// Ring colour under a resting cat waiting to be picked up.
Color traitRing(HerdCat cat) => switch (cat.trait) {
      HerdTrait.golden => const Color(0x88FFD24A),
      HerdTrait.sleepy when !cat.awake => const Color(0x669FB4E6),
      _ => const Color(0x66FFF6CB),
    };

void _heart(Canvas canvas, Offset at, Color color) {
  canvas.drawPath(
      Path()
        ..moveTo(at.dx, at.dy + 3)
        ..cubicTo(at.dx - 7, at.dy - 3, at.dx - 3, at.dy - 7, at.dx, at.dy - 3)
        ..cubicTo(at.dx + 3, at.dy - 7, at.dx + 7, at.dy - 3, at.dx, at.dy + 3)
        ..close(),
      Paint()..color = color);
}

void _bubble(Canvas canvas, Offset at, String mark, Color color) {
  canvas.drawCircle(at, 8, Paint()..color = const Color(0xF2FFFFFF));
  canvas.drawCircle(
      at,
      8,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5);
  _text(canvas, mark, at + const Offset(-3, -7.5), 11, color);
}

void _butterfly(Canvas canvas, Offset at, double time) {
  final flap = .35 + .65 * math.sin(time * 18).abs();
  final wing = Paint()..color = const Color(0xFFF08BB4);
  final inner = Paint()..color = const Color(0xFFFFD36B);
  for (final side in [-1.0, 1.0]) {
    canvas.drawOval(
        Rect.fromCenter(
            center: at + Offset(side * 4.5 * flap, -2),
            width: 8 * flap,
            height: 8),
        wing);
    canvas.drawOval(
        Rect.fromCenter(
            center: at + Offset(side * 3.5 * flap, 3),
            width: 6 * flap,
            height: 5),
        inner);
  }
  canvas.drawLine(
      at + const Offset(0, -4),
      at + const Offset(0, 5),
      Paint()
        ..color = const Color(0xFF5A3214)
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round);
}

void _crown(Canvas canvas, Offset at) {
  final path = Path()
    ..moveTo(at.dx - 8, at.dy + 3)
    ..lineTo(at.dx - 9, at.dy - 5)
    ..lineTo(at.dx - 4, at.dy - 1)
    ..lineTo(at.dx, at.dy - 8)
    ..lineTo(at.dx + 4, at.dy - 1)
    ..lineTo(at.dx + 9, at.dy - 5)
    ..lineTo(at.dx + 8, at.dy + 3)
    ..close();
  canvas.drawPath(path, Paint()..color = const Color(0xFFFFCB3D));
  canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFB7791F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2);
  canvas.drawCircle(
      at + const Offset(0, -1), 1.6, Paint()..color = const Color(0xFFE0533E));
}

void _sparkle(Canvas canvas, Offset at, double r, Color color) {
  final paint = Paint()..color = color;
  canvas.drawPath(
      Path()
        ..moveTo(at.dx, at.dy - r * 2)
        ..lineTo(at.dx + r * .5, at.dy - r * .5)
        ..lineTo(at.dx + r * 2, at.dy)
        ..lineTo(at.dx + r * .5, at.dy + r * .5)
        ..lineTo(at.dx, at.dy + r * 2)
        ..lineTo(at.dx - r * .5, at.dy + r * .5)
        ..lineTo(at.dx - r * 2, at.dy)
        ..lineTo(at.dx - r * .5, at.dy - r * .5)
        ..close(),
      paint);
}

void _text(Canvas canvas, String value, Offset at, double size, Color color) {
  (TextPainter(
          text: TextSpan(
              text: value,
              style: TextStyle(
                  fontSize: size, color: color, fontWeight: FontWeight.w900)),
          textDirection: TextDirection.ltr)
        ..layout())
      .paint(canvas, at);
}
