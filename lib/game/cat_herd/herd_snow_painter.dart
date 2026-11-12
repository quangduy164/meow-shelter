import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/painting.dart';
import 'herd_map.dart';
import 'herd_round.dart';

/// Thin-ice cracks, fall ripples and chute lanes, in pixel space.
void paintSnowHazards(Canvas canvas, HerdRound round) {
  final map = round.map, field = round.field;
  for (final chute in map.chutes) {
    _chute(canvas, map.pixels(chute.area, field), chute.direction, round.time);
  }
  for (var z = 0; z < map.thinIce.length; z++) {
    final sheet = map.pixels(map.thinIce[z], field);
    final pads = [
      for (final pad in map.snowPads) map.pixels(pad, field).inflate(4)
    ];
    final crack = z < round.iceCrack.length ? round.iceCrack[z] : 0.0;
    // Dark water shows through thin ice; it pulses red when about to break.
    final danger =
        crack > HerdThinIce.warnAt ? .5 + .5 * math.sin(round.time * 14) : 0.0;
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(sheet, const Radius.circular(24)));
    for (final pad in pads) {
      canvas.clipPath(Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(sheet.inflate(10))
        ..addRRect(RRect.fromRectAndRadius(pad, const Radius.circular(16))));
    }
    canvas.drawRect(
        sheet,
        Paint()
          ..color = Color.lerp(const Color(0x553C7FA6), const Color(0x44D9534A),
              danger * crack)!);
    final random = math.Random(z * 31 + 7);
    final hair = Paint()
      ..color = const Color(0xAAFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final deep = Paint()
      ..color =
          Color.lerp(const Color(0xCC2D5D79), const Color(0xFFB8463E), danger)!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeJoin = StrokeJoin.round;
    // Fixed seeds keep the cracks in place; the load only reveals more.
    const total = 16;
    final shown = (crack * total).ceil();
    for (var i = 0; i < total; i++) {
      var p = Offset(sheet.left + random.nextDouble() * sheet.width,
          sheet.top + random.nextDouble() * sheet.height);
      final path = Path()..moveTo(p.dx, p.dy);
      var angle = random.nextDouble() * math.pi * 2;
      for (var k = 0; k < 4; k++) {
        angle += (random.nextDouble() - .5) * 1.4;
        p += Offset.fromDirection(angle, 9 + random.nextDouble() * 9);
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, i < shown ? deep : hair);
    }
    canvas.restore();
    // Little warning posts on the shore mark the thin sheet.
    for (final post in [sheet.bottomLeft, sheet.topRight]) {
      final at = post + Offset(post.dx > sheet.center.dx ? -6 : 6, -4);
      canvas.drawLine(
          at,
          at + const Offset(0, -18),
          Paint()
            ..color = const Color(0xFF7A5A41)
            ..strokeWidth = 2.5);
      canvas.drawPath(
          Path()
            ..moveTo(at.dx, at.dy - 30)
            ..lineTo(at.dx + 9, at.dy - 16)
            ..lineTo(at.dx - 9, at.dy - 16)
            ..close(),
          Paint()..color = const Color(0xFFE9B13F));
      _text(
          canvas, '!', at + const Offset(-2, -28), 10, const Color(0xFF5A3214));
    }
  }
  for (final splash in round.splashes) {
    final t = splash.age / HerdThinIce.splashSeconds;
    final at = splash.at.toOffset();
    canvas.drawOval(Rect.fromCenter(center: at, width: 30, height: 15),
        Paint()..color = Color.fromRGBO(43, 92, 122, .8 * (1 - t)));
    for (var i = 0; i < 2; i++) {
      final grow = 22 + (t + i * .3) * 40;
      canvas.drawOval(
          Rect.fromCenter(center: at, width: grow, height: grow * .45),
          Paint()
            ..color = Color.fromRGBO(220, 244, 250, (1 - t) * .9)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
    }
    for (var i = 0; i < 5; i++) {
      final drop =
          at + Offset(math.cos(i * 1.26) * 18 * t, -30 * t * (1 - t) * 4 + 3);
      canvas.drawCircle(
          drop, 2.5 * (1 - t), Paint()..color = const Color(0xDDBFE6F2));
    }
  }
}

void _chute(Canvas canvas, Rect lane, Offset dir, double time) {
  final box = RRect.fromRectAndRadius(lane, const Radius.circular(12));
  canvas.drawRRect(box.inflate(4), Paint()..color = const Color(0xFFF7FBF5));
  canvas.drawRRect(
      box,
      Paint()
        ..shader = LinearGradient(
                begin: Alignment(-dir.dx, -dir.dy),
                end: Alignment(dir.dx, dir.dy),
                colors: const [Color(0xFF8CCDE2), Color(0xFF5AA9C9)])
            .createShader(lane));
  canvas.drawRRect(
      box,
      Paint()
        ..color = const Color(0xFFB9E4EE)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2);
  // Chevrons stream in the only direction the lane allows.
  final along = dir.dx != 0 ? lane.width : lane.height;
  final across = dir.dx != 0 ? lane.height : lane.width;
  final arrow = Paint()
    ..color = const Color(0xDDFFFFFF)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  canvas.save();
  canvas.clipRRect(box);
  const gap = 34.0;
  final shift = (time * 60) % gap;
  final side = Offset(-dir.dy, dir.dx) * (across * .28);
  for (var d = -gap + shift; d < along + gap; d += gap) {
    final start = dir.dx > 0 || dir.dy > 0 ? lane.topLeft : lane.bottomRight;
    final centerLine = dir.dx != 0
        ? Offset(start.dx + dir.dx * d, lane.center.dy)
        : Offset(lane.center.dx, start.dy + dir.dy * d);
    final tip = centerLine + dir * 6;
    canvas.drawPath(
        Path()
          ..moveTo((tip - dir * 9 + side).dx, (tip - dir * 9 + side).dy)
          ..lineTo(tip.dx, tip.dy)
          ..lineTo((tip - dir * 9 - side).dx, (tip - dir * 9 - side).dy),
        arrow);
  }
  canvas.restore();
}

/// Wet, shivering cat after a fall, with a countdown ring until it rejoins.
void paintCatChill(Canvas canvas, HerdCat cat, double time) {
  if (cat.chill <= 0) return;
  final at = cat.position.toOffset();
  final left = cat.chill / HerdThinIce.chillSeconds;
  canvas.drawArc(
      Rect.fromCircle(center: at + const Offset(0, -31), radius: 7),
      -math.pi / 2,
      math.pi * 2 * left,
      false,
      Paint()
        ..color = const Color(0xFF6FB8DA)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3);
  for (var i = 0; i < 3; i++) {
    final fall = (time * 1.6 + i / 3) % 1;
    canvas.drawCircle(at + Offset(-10 + i * 10.0, -6 + fall * 16),
        2.2 * (1 - fall), Paint()..color = const Color(0xCC79C2E3));
  }
  _text(canvas, 'brr', at + Offset(12 + math.sin(time * 30), -26), 10,
      const Color(0xFF3E7EA3));
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
