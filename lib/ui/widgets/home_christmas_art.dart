import 'dart:math' as math;

import 'package:flutter/painting.dart';

/// A cleared trail widens toward the viewer and ends at the cottage door.
void paintWinterPath(Canvas canvas, double width) {
  final door = Offset(width - 95, 486);
  final trail = Path()
    ..moveTo(width * .10, 610)
    ..cubicTo(width * .28, 524, width * .59, 598, width * .76, 534)
    ..quadraticBezierTo(width * .87, 493, door.dx - 12, door.dy)
    ..lineTo(door.dx + 12, door.dy)
    ..quadraticBezierTo(width * .88, 515, width * .78, 552)
    ..cubicTo(width * .60, 623, width * .35, 562, width * .22, 610)
    ..close();
  canvas.drawPath(trail.shift(const Offset(0, 4)),
      Paint()..color = const Color(0xFFBACFD9));
  canvas.drawPath(
      trail,
      Paint()
        ..shader = const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFD2C9BB), Color(0xFFB4BEC5)])
            .createShader(const Rect.fromLTWH(0, 480, 100, 130)));
  // Snow banks form a soft lip rather than a uniform grey stroke.
  final bank = Paint()
    ..color = const Color(0xFFF9FCF8)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 5
    ..strokeCap = StrokeCap.round;
  final center = Path()
    ..moveTo(width * .16, 610)
    ..cubicTo(width * .32, 542, width * .60, 610, width * .77, 543)
    ..quadraticBezierTo(width * .88, 504, door.dx, door.dy);
  canvas.save();
  canvas.clipPath(trail);
  final random = math.Random(1225);
  for (var i = 0; i < 100; i++) {
    final p =
        Offset(random.nextDouble() * width, 492 + random.nextDouble() * 118);
    canvas.drawOval(Rect.fromCenter(center: p, width: 3, height: 1.2),
        Paint()..color = const Color(0x33546A7C));
  }
  for (final metric in center.computeMetrics()) {
    for (var d = 26.0; d < metric.length - 24; d += 27) {
      final t = metric.getTangentForOffset(d)!;
      final side = (d ~/ 27).isEven ? 4.0 : -4.0;
      canvas.save();
      canvas.translate(t.position.dx - t.vector.dy * side,
          t.position.dy + t.vector.dx * side);
      canvas.rotate(math.atan2(t.vector.dy, t.vector.dx));
      final paw = Paint()..color = const Color(0x66566F83);
      canvas.drawOval(const Rect.fromLTWH(-3, -2, 6, 4), paw);
      for (var toe = 0; toe < 3; toe++) {
        canvas.drawCircle(Offset(3, -2.3 + toe * 2.3), 1.1, paw);
      }
      canvas.restore();
    }
  }
  canvas.restore();
  canvas.drawPath(
      Path()
        ..moveTo(width * .10, 603)
        ..cubicTo(width * .28, 524, width * .59, 598, width * .76, 534)
        ..quadraticBezierTo(width * .87, 493, door.dx - 12, door.dy),
      bank);
}

/// Warm timber cottage on the snowy bank, with a wreath and roof lights.
void paintWinterShelter(Canvas canvas, Offset door) {
  canvas.save();
  canvas.translate(door.dx, door.dy);
  canvas.drawOval(const Rect.fromLTWH(-88, -2, 178, 22),
      Paint()..color = const Color(0x44678096));
  // Chimney and the faint smoke behind the roof.
  final smoke = Paint()..color = const Color(0x33F8F4E7);
  for (var i = 0; i < 4; i++) {
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(39 + i * 5, -128 - i * 13),
            width: 14 + i * 5,
            height: 12 + i * 3),
        smoke);
  }
  canvas.drawRect(const Rect.fromLTWH(30, -117, 19, 39),
      Paint()..color = const Color(0xFF9E665B));
  canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(27, -121, 25, 7), const Radius.circular(3)),
      Paint()..color = const Color(0xFFF7FBF6));
  // The shaded side makes the building feel grounded in the scene.
  canvas.drawPath(
      Path()
        ..moveTo(59, -71)
        ..lineTo(78, -60)
        ..lineTo(78, -1)
        ..lineTo(59, 6)
        ..close(),
      Paint()..color = const Color(0xFFA77F62));
  const wall = Rect.fromLTWH(-63, -73, 126, 77);
  canvas.drawRect(
      wall,
      Paint()
        ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFEBC69E), Color(0xFFCFA57E)]).createShader(wall));
  final timber = Paint()
    ..color = const Color(0x447E573E)
    ..strokeWidth = 1;
  for (var y = -66.0; y < 0; y += 11) {
    canvas.drawLine(Offset(-61, y), Offset(61, y), timber);
  }
  final roof = Path()
    ..moveTo(-80, -69)
    ..lineTo(-4, -129)
    ..quadraticBezierTo(0, -132, 4, -129)
    ..lineTo(80, -69)
    ..close();
  canvas.drawPath(
      roof.shift(const Offset(1, 5)), Paint()..color = const Color(0x66412F36));
  canvas.drawPath(roof, Paint()..color = const Color(0xFF9B4550));
  final snow = Path()
    ..moveTo(-82, -71)
    ..lineTo(-4, -133)
    ..quadraticBezierTo(0, -136, 5, -132)
    ..lineTo(82, -71)
    ..quadraticBezierTo(72, -64, 62, -76)
    ..lineTo(6, -115)
    ..quadraticBezierTo(0, -120, -6, -114)
    ..lineTo(-62, -74)
    ..quadraticBezierTo(-75, -63, -82, -71)
    ..close();
  canvas.drawPath(
      snow.shift(const Offset(0, 3)), Paint()..color = const Color(0xFFBAD1DB));
  canvas.drawPath(snow, Paint()..color = const Color(0xFFF9FCF7));
  // Paw plaque marks this as the cats' shelter, even at background scale.
  canvas.drawCircle(
      const Offset(0, -94), 12, Paint()..color = const Color(0xFFF2D6AD));
  final sign = Paint()..color = const Color(0xFF995260);
  canvas.drawOval(const Rect.fromLTWH(-5, -94, 10, 8), sign);
  for (final p in const [Offset(-6, -98), Offset(0, -101), Offset(6, -98)]) {
    canvas.drawCircle(p, 2.3, sign);
  }
  // Warm window glow falls onto the snow.
  for (final x in [-39.0, 39.0]) {
    final glow = Rect.fromCircle(center: Offset(x, -30), radius: 38);
    canvas.drawOval(
        glow,
        Paint()
          ..shader = const RadialGradient(
                  colors: [Color(0x55FFC46A), Color(0x00FFC46A)])
              .createShader(glow));
    final window = RRect.fromRectAndRadius(
        Rect.fromLTWH(x - 14, -53, 28, 30), const Radius.circular(4));
    canvas.drawRRect(
        window.inflate(3), Paint()..color = const Color(0xFF745747));
    canvas.drawRRect(
        window,
        Paint()
          ..shader = const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFFFE6A0), Color(0xFFEEAD55)])
              .createShader(window.outerRect));
    canvas.drawLine(Offset(x, -53), Offset(x, -23), timber..strokeWidth = 2);
    canvas.drawLine(Offset(x - 14, -38), Offset(x + 14, -38), timber);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(x - 18, -22, 36, 5), const Radius.circular(2)),
        Paint()..color = const Color(0xFFF9FCF7));
  }
  final entry = RRect.fromRectAndCorners(const Rect.fromLTWH(-15, -43, 30, 47),
      topLeft: const Radius.circular(14), topRight: const Radius.circular(14));
  canvas.drawRRect(entry.inflate(3), Paint()..color = const Color(0xFF926849));
  canvas.drawRRect(entry, Paint()..color = const Color(0xFF6A493E));
  canvas.drawCircle(
      const Offset(9, -13), 1.8, Paint()..color = const Color(0xFFFFD378));
  // Wreath and red bow on the door.
  canvas.drawCircle(
      const Offset(0, -27),
      8,
      Paint()
        ..color = const Color(0xFF2E725A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5);
  for (var i = 0; i < 5; i++) {
    final a = i * math.pi * 2 / 5;
    canvas.drawCircle(Offset(math.cos(a) * 8, -27 + math.sin(a) * 8), 1.5,
        Paint()..color = const Color(0xFFD95560));
  }
  canvas.drawPath(
      Path()
        ..moveTo(0, -21)
        ..lineTo(-7, -25)
        ..lineTo(-7, -17)
        ..lineTo(7, -25)
        ..lineTo(7, -17)
        ..close(),
      Paint()..color = const Color(0xFFE36669));
  // Tiny roof bulbs follow the slopes, under the snow lip.
  for (var i = 0; i < 11; i++) {
    final x = -65.0 + i * 13;
    final y = -120 + x.abs() * .72;
    final c = i.isEven ? const Color(0xFFFFD585) : const Color(0xFFFF9290);
    canvas.drawCircle(Offset(x, y), 6, Paint()..color = c.withOpacity(.15));
    canvas.drawCircle(Offset(x, y), 2, Paint()..color = c);
  }
  // Snow-lined doorstep joins the end of the trail.
  canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(-22, 1, 44, 7), const Radius.circular(3)),
      Paint()..color = const Color(0xFFB8CCD4));
  canvas.drawLine(
      const Offset(-23, 1),
      const Offset(23, 1),
      Paint()
        ..color = const Color(0xFFF9FCF7)
        ..strokeWidth = 3);
  canvas.restore();
}

void _paintChristmasTree(Canvas canvas, Offset base) {
  canvas.save();
  canvas.translate(base.dx, base.dy);
  canvas.drawOval(const Rect.fromLTWH(-66, -5, 138, 24),
      Paint()..color = const Color(0x3364879B));
  canvas.drawOval(const Rect.fromLTWH(-62, -9, 125, 22),
      Paint()..color = const Color(0xFFF7FBF6));
  canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(-7, -35, 14, 40), const Radius.circular(3)),
      Paint()..color = const Color(0xFF795D49));
  // Build from the wide bottom bough upward so the upper tiers overlap.
  for (var tier = 3; tier >= 0; tier--) {
    final top = -198.0 + tier * 36;
    final half = 25.0 + tier * 13;
    final bottom = top + 73;
    final branch = Path()
      ..moveTo(0, top)
      ..cubicTo(-half * .20, top + 22, -half * .65, bottom - 12, -half, bottom)
      ..quadraticBezierTo(-half * .66, bottom + 3, -half * .42, bottom - 3)
      ..quadraticBezierTo(-half * .12, bottom + 8, half * .16, bottom + 1)
      ..quadraticBezierTo(half * .60, bottom + 7, half, bottom)
      ..cubicTo(half * .65, bottom - 12, half * .20, top + 22, 0, top)
      ..close();
    canvas.drawPath(branch.shift(const Offset(0, 4)),
        Paint()..color = const Color(0x66314D4B));
    canvas.drawPath(
        branch,
        Paint()
          ..shader = const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF5B9D83),
                Color(0xFF246451),
                Color(0xFF194C43)
              ]).createShader(Rect.fromLTRB(-half, top, half, bottom)));
    // Uneven little snow pillows on the outer boughs.
    final cap = Path()
      ..moveTo(-half * .91, bottom - 3)
      ..quadraticBezierTo(-half * .62, bottom - 18, -half * .48, bottom - 16)
      ..quadraticBezierTo(-half * .38, bottom - 6, -half * .16, bottom - 9)
      ..quadraticBezierTo(half * .11, bottom - 18, half * .28, bottom - 10)
      ..quadraticBezierTo(half * .57, bottom - 7, half * .76, bottom - 14)
      ..lineTo(half * .97, bottom - 1)
      ..quadraticBezierTo(half * .57, bottom + 6, half * .18, bottom + 1)
      ..quadraticBezierTo(-half * .12, bottom + 8, -half * .45, bottom - 1)
      ..quadraticBezierTo(-half * .68, bottom + 5, -half * .91, bottom - 3)
      ..close();
    canvas.drawPath(cap.shift(const Offset(0, 2)),
        Paint()..color = const Color(0xFFA6C6D2));
    canvas.drawPath(cap, Paint()..color = const Color(0xFFF5FAF5));
    final garland = Path()
      ..moveTo(-half * .65, bottom - 23)
      ..quadraticBezierTo(0, bottom - 5, half * .66, bottom - 22);
    canvas.drawPath(
        garland,
        Paint()
          ..color = const Color(0xFFCEB47A)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.3);
    for (var j = 0; j < 5; j++) {
      final t = j / 4;
      final x = -half * .65 + half * 1.31 * t;
      final y = bottom - 23 + 30 * t * (1 - t);
      final c = j.isEven ? const Color(0xFFFFDB8B) : const Color(0xFFFFA29B);
      canvas.drawCircle(Offset(x, y), 6, Paint()..color = c.withOpacity(.13));
      canvas.drawCircle(Offset(x, y), 1.8, Paint()..color = c);
    }
    // Glass baubles with a tiny reflected highlight.
    for (final side in [-1.0, 1.0]) {
      final p = Offset(side * half * .42, bottom - 31 + side * 3);
      canvas.drawLine(
          p - const Offset(0, 7),
          p,
          Paint()
            ..color = const Color(0xFFCEB47A)
            ..strokeWidth = 1);
      canvas.drawCircle(p + const Offset(1, 1), 4.5,
          Paint()..color = const Color(0x66324643));
      canvas.drawCircle(
          p,
          4.4,
          Paint()
            ..color =
                side < 0 ? const Color(0xFFD95665) : const Color(0xFFE9BD67));
      canvas.drawCircle(p - const Offset(1.3, 1.6), 1.2,
          Paint()..color = const Color(0xFFFFE9C4));
    }
  }
  final star = Path();
  for (var i = 0; i < 10; i++) {
    final a = -math.pi / 2 + i * math.pi / 5;
    final r = i.isEven ? 12.0 : 5.4;
    final p = Offset(math.cos(a) * r, -204 + math.sin(a) * r);
    i == 0 ? star.moveTo(p.dx, p.dy) : star.lineTo(p.dx, p.dy);
  }
  final glow = Rect.fromCircle(center: const Offset(0, -204), radius: 26);
  canvas.drawCircle(
      const Offset(0, -204),
      26,
      Paint()
        ..shader =
            const RadialGradient(colors: [Color(0x66FFDE9A), Color(0x00FFDE9A)])
                .createShader(glow));
  canvas.drawPath(star..close(), Paint()..color = const Color(0xFFFFDC8E));
  canvas.drawPath(
      Path()
        ..moveTo(0, -214)
        ..lineTo(0, -204)
        ..lineTo(-10, -201),
      Paint()
        ..color = const Color(0xFFFFF3C6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1);
  // Wrapped gifts partially nestle into the snow.
  for (var i = 0; i < 3; i++) {
    final x = -46.0 + i * 34;
    final h = i == 1 ? 31.0 : 23.0;
    final rect = Rect.fromLTWH(x, 7 - h, 29, h);
    final c = [
      const Color(0xFFBD4B5E),
      const Color(0xFF3F8191),
      const Color(0xFF977597)
    ][i];
    canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(2)),
        Paint()
          ..shader = LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color.lerp(c, const Color(0xFFFFFFFF), .2)!, c])
              .createShader(rect));
    final ribbon = Paint()..color = const Color(0xFFF1D599);
    canvas.drawRect(Rect.fromLTWH(x + 12, 7 - h, 4, h), ribbon);
    canvas.drawRect(Rect.fromLTWH(x, 12 - h, 29, 3), ribbon);
    final bow = Paint()
      ..color = const Color(0xFFF1D599)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawOval(Rect.fromLTWH(x + 5, 1 - h, 9, 6), bow);
    canvas.drawOval(Rect.fromLTWH(x + 14, 1 - h, 9, 6), bow);
  }
  canvas.restore();
}

/// Decorations stay along the edges, leaving the menu readable.
void paintHomeChristmas(Canvas canvas, double width) {
  const cream = Color(0xFFFFFCF2);
  const gold = Color(0xFFFFD578);
  const red = Color(0xFFD94B59);
  final wire = Path()..moveTo(0, 12);
  double wireY(double x) => 12 + 23 * math.sin(x / width * math.pi);
  for (var x = 0.0; x <= width; x += 8) {
    wire.lineTo(x, wireY(x));
  }
  canvas.drawPath(
      wire,
      Paint()
        ..color = const Color(0xFF234F48)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round);
  const lights = [gold, red, Color(0xFF8FE2BD), cream];
  var index = 0;
  for (var x = 20.0; x < width; x += 38) {
    final y = wireY(x);
    final color = lights[index++ % lights.length];
    canvas.drawLine(
        Offset(x, y),
        Offset(x, y + 9),
        Paint()
          ..color = const Color(0xFF234F48)
          ..strokeWidth = 2);
    canvas.drawCircle(
        Offset(x, y + 14), 12, Paint()..color = color.withOpacity(.12));
    canvas.drawOval(
        Rect.fromCenter(center: Offset(x, y + 14), width: 7, height: 11),
        Paint()..color = color);
    canvas.drawCircle(Offset(x - 1, y + 12), 1.5, Paint()..color = cream);
  }

  _paintChristmasTree(canvas, const Offset(69, 520));

  // Fixed seed prevents snow from jumping whenever the menu rebuilds.
  final random = math.Random(2512);
  for (var i = 0; i < 85; i++) {
    final p = Offset(random.nextDouble() * width, random.nextDouble() * 600);
    final r = 1.2 + random.nextDouble() * 2.1;
    canvas.drawCircle(p, r,
        Paint()..color = cream.withOpacity(.35 + random.nextDouble() * .5));
    if (i % 13 == 0) {
      final pen = Paint()
        ..color = cream.withOpacity(.7)
        ..strokeWidth = 1.3;
      for (var arm = 0; arm < 3; arm++) {
        final a = arm * math.pi / 3;
        final d = Offset(math.cos(a), math.sin(a)) * 5;
        canvas.drawLine(p - d, p + d, pen);
      }
    }
  }
}
