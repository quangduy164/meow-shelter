import 'dart:math' as math;
import 'package:flutter/painting.dart';
import 'herd_map.dart';
import 'herd_round.dart';
import 'herd_route_painter.dart';

/// Exclusive art for the herd mode. Geometry comes from HerdMap.
void paintHerdMap(Canvas canvas, Size size, HerdRound r) {
  canvas.save();
  canvas.scale(size.width / 800, size.height / 375);
  switch (r.map.kind) {
    case HerdMapKind.tutorial:
      _tutorial(canvas, r);
    case HerdMapKind.playground:
      _playground(canvas, r);
    case HerdMapKind.nightMarket:
      _market(canvas, r);
    case HerdMapKind.dunes:
      _desert(canvas, r);
    case HerdMapKind.snow:
      _snow(canvas, r);
  }
  canvas.restore();
  paintHerdRoute(canvas, size, r);
}

Rect _rect(Rect r) =>
    Rect.fromLTWH(r.left * 800, r.top * 375, r.width * 800, r.height * 375);
void _fill(Canvas c, Rect r, Color color, [double radius = 0]) => c.drawRRect(
    RRect.fromRectAndRadius(r, Radius.circular(radius)),
    Paint()..color = color);
void _line(Canvas c, Offset a, Offset b, Color color, double width) =>
    c.drawLine(
        a,
        b,
        Paint()
          ..color = color
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round);
void _base(Canvas c, Color top, Color bottom) {
  c.drawRect(
      const Rect.fromLTWH(0, 0, 800, 375),
      Paint()
        ..shader = LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [top, bottom])
            .createShader(const Rect.fromLTWH(0, 0, 800, 375)));
}

void _market(Canvas c, HerdRound r) {
  _base(c, const Color(0xFF383C61), const Color(0xFF655374));
  final random = math.Random(9);
  for (var i = 0; i < 45; i++) {
    final p = Offset(random.nextDouble() * 800, random.nextDouble() * 55);
    c.drawCircle(p, 1, Paint()..color = const Color(0xFFDFD8B5));
  }
  for (var row = 0; row < 12; row++) {
    for (var col = 0; col < 28; col++) {
      final x = col * 30.0 + (row.isEven ? 0 : 15);
      _fill(c, Rect.fromLTWH(x, 62 + row * 28.0, 28, 26),
          const Color(0x225E6384), 3);
    }
  }
  // One main street separates two broad pedestrian pavements.
  const road = Rect.fromLTWH(0, 375 * .44, 800, 375 * .18);
  _fill(c, road, const Color(0xFF353B50));
  for (final y in [road.top, road.bottom]) {
    _line(c, Offset(0, y), Offset(800, y), const Color(0xFFA9A0A2), 4);
  }
  for (var x = 12.0; x < 800; x += 38) {
    _fill(c, Rect.fromLTWH(x, road.center.dy - 1, 18, 2),
        const Color(0x887E8395));
  }
  const crossingX = 800 * .45;
  for (var y = road.top + 5; y < road.bottom - 3; y += 10) {
    _fill(
        c, Rect.fromLTWH(crossingX - 26, y, 52, 6), const Color(0xFFD6CDB8), 1);
  }
  // Keep the alley surface distinct from the traffic road.
  _fill(c, const Rect.fromLTWH(372, 82, 224, 75), const Color(0x225AB0A6), 7);
  // Hanging lanterns stay above the play area.
  final rope = Path()
    ..moveTo(0, 48)
    ..quadraticBezierTo(400, 84, 800, 48);
  c.drawPath(
      rope,
      Paint()
        ..color = const Color(0xFF25233C)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2);
  for (var i = 0; i < 11; i++) {
    final x = 28 + i * 73.0, y = 51 + math.sin(i / 10 * math.pi) * 16;
    c.drawCircle(
        Offset(x, y + 6), 16, Paint()..color = const Color(0x18FFBE6A));
    _fill(c, Rect.fromLTWH(x - 7, y - 2, 14, 17), const Color(0xFFECA25D), 5);
    _line(c, Offset(x - 4, y + 3), Offset(x + 4, y + 3),
        const Color(0xFFF9D18F), 1);
    _line(c, Offset(x, y + 15), Offset(x, y + 21), const Color(0xFFECA25D), 1);
  }
  for (var i = 0; i < r.map.walls.length; i++) {
    final box = _rect(r.map.walls[i]);
    if (i == 0) {
      _stall(c, box);
      // Fish on ice replace generic produce on the fish stall.
      _fill(c, box.deflate(3), const Color(0xFFC8E3DF), 2);
      for (var j = 0; j < 5; j++) {
        final p =
            Offset(box.left + 14 + j * (box.width - 28) / 4, box.center.dy);
        c.drawOval(Rect.fromCenter(center: p, width: 16, height: 6),
            Paint()..color = const Color(0xFF7AABB6));
        c.drawPath(
            Path()
              ..moveTo(p.dx - 7, p.dy)
              ..lineTo(p.dx - 12, p.dy - 4)
              ..lineTo(p.dx - 12, p.dy + 4)
              ..close(),
            Paint()..color = const Color(0xFF7AABB6));
        c.drawCircle(p + const Offset(5, -1), 1,
            Paint()..color = const Color(0xFF304A58));
      }
    } else if (i == 1) {
      _fill(c, box.shift(const Offset(2, 3)), const Color(0x4420192C), 3);
      _fill(c, box, const Color(0xFFAA7951), 3);
      c.drawRect(
          box.deflate(3),
          Paint()
            ..color = const Color(0xFF755338)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
      _line(c, box.topLeft + const Offset(4, 4),
          box.bottomRight + const Offset(-4, -4), const Color(0xFFE0B982), 3);
    } else if (i == 2 || i == 3) {
      // Narrow storefronts flank the alley, with shutters and fabric canopies.
      _fill(c, box.shift(const Offset(3, 3)), const Color(0x4420192C), 3);
      _fill(c, box, const Color(0xFFAA7951), 3);
      for (var y = box.top + 7; y < box.bottom - 3; y += 8) {
        _line(c, Offset(box.left + 3, y), Offset(box.right - 3, y),
            const Color(0xFFE3C089), 2);
      }
      _fill(c, Rect.fromLTWH(box.left - 2, box.top - 4, box.width + 4, 12),
          const Color(0xFF789F9D), 3);
    } else {
      // Dinner tables and stools make a small optional courtyard.
      _fill(c, box.shift(const Offset(2, 4)), const Color(0x4420192C), 8);
      _fill(c, box, const Color(0xFFB8875F), 8);
      _line(c, box.topLeft + const Offset(8, 4),
          box.topRight + const Offset(-8, 4), const Color(0xFFDAB48B), 2);
      for (final dx in [-10.0, 10.0]) {
        c.drawOval(
            Rect.fromCenter(
                center: box.center + Offset(dx, 0), width: 13, height: 9),
            Paint()..color = const Color(0xFFFFE6B4));
        c.drawOval(
            Rect.fromCenter(
                center: box.center + Offset(dx, 0), width: 7, height: 4),
            Paint()..color = const Color(0xFF986B4F));
      }
      for (final x in [box.left + 8, box.right - 8]) {
        _fill(c, Rect.fromLTWH(x - 4, box.bottom + 2, 8, 5),
            const Color(0xFF986749), 2);
      }
    }
  }
  final green = r.map.green(r.time);
  final signal = Offset(crossingX + 37, road.top - 36);
  _fill(c, Rect.fromLTWH(signal.dx + 9, signal.dy + 26, 5, 17),
      const Color(0xFF252B3F));
  _fill(c, Rect.fromLTWH(signal.dx, signal.dy, 23, 31), const Color(0xFF202538),
      5);
  c.drawCircle(
      signal + const Offset(11.5, 9),
      5,
      Paint()
        ..color = green ? const Color(0xFF593E48) : const Color(0xFFFF7667));
  c.drawCircle(
      signal + const Offset(11.5, 22),
      5,
      Paint()
        ..color = green ? const Color(0xFF85E6AC) : const Color(0xFF304D45));
}

void _stall(Canvas c, Rect r) {
  _fill(c, r.shift(const Offset(3, 5)), const Color(0x44201B2E), 5);
  _fill(c, r, const Color(0xFFAA744D), 4);
  _fill(
      c, Rect.fromLTWH(r.left, r.top, r.width, 12), const Color(0xFFE8C281), 3);
  for (var i = 0; i < 6; i++) {
    _fill(
        c,
        Rect.fromLTWH(r.left + i * r.width / 6, r.top - 6, r.width / 6, 17),
        i.isEven ? const Color(0xFFCA6666) : const Color(0xFFFFE4B1),
        2);
  }
  for (var i = 0; i < 5; i++) {
    final p = Offset(r.left + 10 + i * (r.width - 20) / 4, r.top + 24);
    c.drawCircle(
        p,
        4,
        Paint()
          ..color =
              i.isEven ? const Color(0xFFE9B751) : const Color(0xFFA5BB67));
  }
  _line(c, r.bottomLeft + const Offset(4, -4),
      r.bottomRight + const Offset(-4, -4), const Color(0xFF76452F), 3);
}

void _desert(Canvas c, HerdRound r) {
  _base(c, const Color(0xFFF0CA89), const Color(0xFFE6B775));
  c.drawCircle(
      const Offset(115, 60), 28, Paint()..color = const Color(0xFFFFE1A0));
  for (var i = 0; i < 4; i++) {
    final y = 45 + i * 8.0;
    c.drawPath(
        Path()
          ..moveTo(0, y + 22)
          ..quadraticBezierTo(140, y - 15, 300, y + 15)
          ..quadraticBezierTo(530, y - 15, 800, y + 13)
          ..lineTo(800, 0)
          ..lineTo(0, 0)
          ..close(),
        Paint()
          ..color = Color.lerp(
              const Color(0xFFBF8758), const Color(0xFFF0CA89), i / 4)!);
  }
  for (var i = 0; i < 16; i++) {
    final y = 85 + i * 19.0;
    c.drawPath(
        Path()
          ..moveTo(0, y)
          ..cubicTo(230, y - 13, 550, y + 17, 800, y - 4),
        Paint()
          ..color = const Color(0x337D512C)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1);
  }
  for (final patch in r.map.softSand) {
    final box = _rect(patch);
    _fill(c, box, const Color(0xFFC99A5E), 22);
    final rand = math.Random(4);
    for (var i = 0; i < 50; i++) {
      final p = Offset(box.left + 8 + rand.nextDouble() * (box.width - 16),
          box.top + 8 + rand.nextDouble() * (box.height - 16));
      c.drawCircle(p, 1, Paint()..color = const Color(0x887E5B39));
    }
  }
  for (final patch in r.map.slopes) {
    final box = _rect(patch);
    _fill(c, box, const Color(0xFFF7D89B), 24);
    c.drawArc(
        box,
        -math.pi,
        math.pi,
        false,
        Paint()
          ..color = const Color(0xFFB77D45)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3);
    for (var i = 0; i < 3; i++) {
      final p = Offset(box.left + 30 + i * 35, box.top + 30);
      _line(c, p, p + const Offset(12, 20), const Color(0xFFBB8652), 2);
      _line(c, p + const Offset(12, 20), p + const Offset(4, 17),
          const Color(0xFFBB8652), 2);
      _line(c, p + const Offset(12, 20), p + const Offset(14, 11),
          const Color(0xFFBB8652), 2);
    }
  }
  // Cool shade patches: same rectangles as the heat rule.
  for (final patch in r.map.shade) {
    final box = _rect(patch);
    c.drawOval(
        box,
        Paint()
          ..color = const Color(0x557A5634)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
    c.drawOval(
        box.deflate(4),
        Paint()
          ..color = const Color(0x55FFF3D2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);
  }
  // A lone palm marks the shade stop between the oasis and the home.
  for (final i in [1, 5]) {
    final box = _rect(r.map.shade[i]);
    final root = Offset(box.center.dx - 4, box.center.dy + 6);
    final crown = root + const Offset(6, -40);
    _line(c, root, crown, const Color(0xFF957047), 4);
    for (var leaf = 0; leaf < 5; leaf++) {
      final end = crown +
          Offset(-22 + leaf * 11.0, -8 + ((leaf - 2) * (leaf - 2)) * 3.5);
      c.drawPath(
          Path()
            ..moveTo(crown.dx, crown.dy)
            ..quadraticBezierTo(
                (crown.dx + end.dx) / 2, end.dy - 9, end.dx, end.dy),
          Paint()
            ..color = const Color(0xFF71975B)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4
            ..strokeCap = StrokeCap.round);
    }
  }
  for (final patch in r.map.landings) {
    final box = _rect(patch);
    _fill(c, box, const Color(0xFFE9C891), 18);
    for (var i = 0; i < 4; i++) {
      c.drawArc(
          box.deflate(4 + i * 3.0),
          0,
          math.pi,
          false,
          Paint()
            ..color = const Color(0x557E5B39)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1);
    }
  }
  for (var i = 0; i < r.map.walls.length; i++) {
    final box = _rect(r.map.walls[i]);
    if (i == 0) {
      // Tiny oasis: the water itself is solid, the shaded sand stays walkable.
      _fill(c, box.inflate(5), const Color(0xFFD5BA7D), 18);
      _fill(c, box, const Color(0xFF6FAFB4), 14);
      _line(c, box.topLeft + const Offset(12, 9),
          box.topRight + const Offset(-10, 9), const Color(0xFFBDE7DC), 2);
      _line(
          c,
          box.bottomLeft + const Offset(10, -8),
          box.bottomRight + const Offset(-16, -8),
          const Color(0xFF9CCFC7),
          1.5);
      final root = box.topLeft + const Offset(3, 3),
          crown = box.topLeft + const Offset(-3, -24);
      _line(c, root, crown, const Color(0xFF957047), 5);
      for (var leaf = 0; leaf < 5; leaf++) {
        final end = crown +
            Offset(-26 + leaf * 13.0, -12 + ((leaf - 2) * (leaf - 2)) * 4);
        c.drawPath(
            Path()
              ..moveTo(crown.dx, crown.dy)
              ..quadraticBezierTo(
                  (crown.dx + end.dx) / 2, end.dy - 11, end.dx, end.dy),
            Paint()
              ..color = const Color(0xFF71975B)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 5
              ..strokeCap = StrokeCap.round);
      }
      c.drawCircle(crown + const Offset(2, 2), 3,
          Paint()..color = const Color(0xFF9F7246));
    } else if (i == 3) {
      // Abandoned canvas shelter; cats wait on the sand in front.
      _fill(c, box.shift(const Offset(3, 5)), const Color(0x3367472C), 4);
      final peak = Offset(box.center.dx, box.top - 23);
      c.drawPath(
          Path()
            ..moveTo(box.left - 7, box.bottom)
            ..lineTo(peak.dx, peak.dy)
            ..lineTo(box.right + 7, box.bottom)
            ..close(),
          Paint()..color = const Color(0xFFBD8961));
      c.drawPath(
          Path()
            ..moveTo(peak.dx, peak.dy)
            ..lineTo(box.center.dx + 4, box.bottom)
            ..lineTo(box.right + 7, box.bottom)
            ..close(),
          Paint()..color = const Color(0xFF9D7153));
      c.drawPath(
          Path()
            ..moveTo(box.center.dx - 14, box.bottom)
            ..lineTo(box.center.dx, box.top)
            ..lineTo(box.center.dx + 13, box.bottom)
            ..close(),
          Paint()..color = const Color(0xFF67503F));
      _line(c, peak, Offset(box.left - 15, box.bottom + 3),
          const Color(0xFFDEBE8C), 1);
      _line(c, peak, Offset(box.right + 15, box.bottom + 3),
          const Color(0xFFDEBE8C), 1);
      for (final x in [box.left - 15, box.right + 15]) {
        _line(c, Offset(x, box.bottom), Offset(x + 2, box.bottom + 6),
            const Color(0xFF8A6845), 2);
      }
    } else {
      _rock(c, box, const Color(0xFFB37D54));
      for (var y = box.top + 14; y < box.bottom - 4; y += 11) {
        _line(c, Offset(box.left + 4, y), Offset(box.right - 3, y - 2),
            const Color(0x66956B47), 1.5);
      }
    }
  }
  for (final x in [20.0, 760.0]) {
    _line(c, Offset(x, 300), Offset(x, 260), const Color(0xFF648259), 8);
    _line(c, Offset(x, 283), Offset(x - 10, 283), const Color(0xFF648259), 6);
    _line(c, Offset(x - 10, 283), Offset(x - 10, 271), const Color(0xFF648259),
        6);
    _line(c, Offset(x, 274), Offset(x + 12, 274), const Color(0xFF648259), 6);
    _line(c, Offset(x + 12, 274), Offset(x + 12, 263), const Color(0xFF648259),
        6);
  }
}

void _snow(Canvas c, HerdRound r) {
  _base(c, const Color(0xFFBFDCE5), const Color(0xFFF3F6EE));
  c.drawPath(
      Path()
        ..moveTo(0, 64)
        ..lineTo(85, 6)
        ..lineTo(160, 65)
        ..lineTo(245, 13)
        ..lineTo(330, 67)
        ..lineTo(420, 4)
        ..lineTo(520, 68)
        ..lineTo(610, 15)
        ..lineTo(710, 66)
        ..lineTo(800, 20)
        ..lineTo(800, 80)
        ..lineTo(0, 80)
        ..close(),
      Paint()..color = const Color(0xFF8CAFC0));
  for (final x in [85.0, 245.0, 420.0, 610.0]) {
    c.drawPath(
        Path()
          ..moveTo(x - 20, 30)
          ..lineTo(x, 7)
          ..lineTo(x + 25, 36)
          ..lineTo(x + 9, 30)
          ..lineTo(x, 35)
          ..close(),
        Paint()..color = const Color(0xFFE6F2F3));
  }
  for (final patch in r.map.ice) {
    final box = _rect(patch);
    _fill(c, box.inflate(4), const Color(0xFFFDFEFA), 25);
    _fill(c, box, const Color(0xFF99D5E6), 24);
    c.drawRRect(
        RRect.fromRectAndRadius(box.deflate(4), const Radius.circular(20)),
        Paint()
          ..color = const Color(0xFFCDF3F6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
    for (var i = 0; i < 4; i++) {
      final x = box.left + 20 + i * box.width / 5;
      _line(c, Offset(x, box.top + 14), Offset(x + 13, box.top + 26),
          const Color(0xFFCEF2F6), 2);
    }
    c.drawPath(
        Path()
          ..moveTo(box.left + 20, box.bottom - 18)
          ..lineTo(box.center.dx, box.center.dy)
          ..lineTo(box.center.dx + 12, box.center.dy + 13)
          ..lineTo(box.right - 18, box.top + 20),
        Paint()
          ..color = const Color(0x8861A5BD)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);
  }
  // Dry islands and braking pads use the same rectangles as the physics.
  for (final patch in r.map.snowPads) {
    final box = _rect(patch);
    _fill(c, box.inflate(3), const Color(0xFFB7D8DE), 18);
    _fill(c, box, const Color(0xFFF9FCF5), 16);
    c.drawArc(
        box.deflate(6),
        0,
        math.pi,
        false,
        Paint()
          ..color = const Color(0x887FA6B2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);
    for (var i = 0; i < 3; i++) {
      c.drawCircle(
          Offset(box.left + 10 + i * (box.width - 20) / 3, box.top + 10),
          1,
          Paint()..color = const Color(0xFFCADFE1));
    }
  }
  // The snow hollow is open ground, with solid outcrops at its sides.
  c.drawOval(const Rect.fromLTWH(262, 255, 150, 44),
      Paint()..color = const Color(0xFFCDDFDF));
  c.drawOval(const Rect.fromLTWH(266, 250, 142, 38),
      Paint()..color = const Color(0xFFF6FAF1));
  for (var index = 0; index < r.map.walls.length; index++) {
    final box = _rect(r.map.walls[index]);
    if (index < 2) {
      final vertical = box.height > box.width;
      _fill(c, box.shift(const Offset(3, 4)), const Color(0x334D6975), 4);
      _fill(c, box, const Color(0xFF997557), 4);
      final count = ((vertical ? box.height : box.width) / 15).ceil();
      for (var i = 0; i < count; i++) {
        final section = vertical
            ? Rect.fromLTWH(box.left, box.top + i * box.height / count,
                box.width, box.height / count)
            : Rect.fromLTWH(box.left + i * box.width / count, box.top,
                box.width / count, box.height);
        c.drawOval(
            section.deflate(2), Paint()..color = const Color(0xFFC9A77B));
        c.drawOval(
            section.deflate(4),
            Paint()
              ..color = const Color(0xFF997557)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1);
      }
      _fill(c, Rect.fromLTWH(box.left - 2, box.top - 3, box.width + 4, 5),
          const Color(0xFFFAFCF4), 3);
    } else if (index == 4) {
      // An abandoned fishing hut stands beside the optional frozen bay.
      _fill(c, box.shift(const Offset(3, 5)), const Color(0x334D6975), 4);
      _fill(c, box, const Color(0xFF8E7060), 3);
      for (var y = box.top + 5; y < box.bottom; y += 6) {
        _line(c, Offset(box.left + 3, y), Offset(box.right - 3, y),
            const Color(0xFFB1987B), 2);
      }
      final roof = Path()
        ..moveTo(box.left - 7, box.top + 2)
        ..lineTo(box.center.dx, box.top - 24)
        ..lineTo(box.right + 7, box.top + 2)
        ..close();
      c.drawPath(roof, Paint()..color = const Color(0xFF6F8993));
      _line(c, Offset(box.left - 7, box.top),
          Offset(box.center.dx, box.top - 26), const Color(0xFFF7FCF4), 5);
      _line(c, Offset(box.center.dx, box.top - 26),
          Offset(box.right + 7, box.top), const Color(0xFFF7FCF4), 5);
      _fill(
          c,
          Rect.fromLTWH(box.center.dx - 9, box.top + 3, 18, box.height - 3),
          const Color(0xFF554940),
          3);
      _fill(c, Rect.fromLTWH(box.left + 8, box.top + 5, 12, 10),
          const Color(0xFFAFD2D9), 2);
      final hole = Offset(box.right + 14, box.bottom + 30);
      c.drawOval(Rect.fromCenter(center: hole, width: 23, height: 12),
          Paint()..color = const Color(0xFFE9F6F4));
      c.drawOval(Rect.fromCenter(center: hole, width: 16, height: 7),
          Paint()..color = const Color(0xFF709CAC));
      _line(c, Offset(box.right + 4, box.bottom + 5),
          hole + const Offset(0, -9), const Color(0xFF8B7154), 2);
      _line(c, hole + const Offset(0, -9), hole, const Color(0xFF637A84), 1);
    } else {
      _rock(c, box, const Color(0xFF8EA3AC));
      _fill(c, Rect.fromLTWH(box.left - 2, box.top - 4, box.width + 4, 13),
          const Color(0xFFF9FCF5), 8);
    }
  }
  for (final x in [20.0, 775.0]) {
    for (var i = 0; i < 3; i++) {
      final y = 120 + i * 90.0;
      _line(c, Offset(x, y), Offset(x, y + 25), const Color(0xFF796659), 5);
      c.drawPath(
          Path()
            ..moveTo(x, y - 25)
            ..lineTo(x - 18, y + 13)
            ..lineTo(x + 18, y + 13)
            ..close(),
          Paint()..color = const Color(0xFF588C87));
      c.drawPath(
          Path()
            ..moveTo(x, y - 25)
            ..lineTo(x - 10, y - 4)
            ..lineTo(x + 10, y - 4)
            ..close(),
          Paint()..color = const Color(0xFFF0F6ED));
    }
  }
  for (var i = 0; i < 25; i++) {
    final x = (i * 71.0 + r.time * 9) % 800,
        y = 65 + (i * 31.0 + r.time * 12) % 300;
    c.drawCircle(Offset(x, y), 1.5, Paint()..color = const Color(0xCCFFFFFF));
  }
}

void _rock(Canvas c, Rect r, Color color) {
  _fill(c, r.shift(const Offset(3, 4)), const Color(0x33402A14), 12);
  c.drawPath(
      Path()
        ..moveTo(r.left, r.bottom)
        ..lineTo(r.left + 5, r.top + 10)
        ..lineTo(r.center.dx, r.top)
        ..lineTo(r.right - 5, r.top + 8)
        ..lineTo(r.right, r.bottom)
        ..close(),
      Paint()..color = color);
  _line(c, Offset(r.left + 10, r.top + 13), Offset(r.center.dx, r.top + 5),
      const Color(0x55FFFFFF), 3);
}

void _playground(Canvas c, HerdRound r) {
  _base(c, const Color(0xFF9BD2B4), const Color(0xFFC4DA94));
  // The track is the exact ellipse used by the looping cars.
  if (r.patrols.isNotEmpty) {
    final car = r.patrols.first;
    final track = Rect.fromLTRB(
        car.from.x / r.field.x * 800,
        car.from.y / r.field.y * 375,
        car.to.x / r.field.x * 800,
        car.to.y / r.field.y * 375);
    c.drawOval(
        track,
        Paint()
          ..color = const Color(0xFFC6AA7F)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 40);
    c.drawOval(
        track.inflate(20),
        Paint()
          ..color = const Color(0xFFF5E6B9)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
    c.drawOval(
        track.deflate(20),
        Paint()
          ..color = const Color(0xFFF5E6B9)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
    for (var i = 0; i < 28; i++) {
      final a = i * math.pi * 2 / 28;
      final p = track.center +
          Offset(math.cos(a) * track.width / 2, math.sin(a) * track.height / 2);
      c.save();
      c.translate(p.dx, p.dy);
      c.rotate(
          math.atan2(math.cos(a) * track.height, -math.sin(a) * track.width));
      _fill(c, const Rect.fromLTWH(-5, -1, 10, 2), const Color(0xFFFAEDC8));
      c.restore();
    }
  }
  // Coloured wooden blocks form an open U around the first cat group.
  for (var wallIndex = 0; wallIndex < r.map.walls.length; wallIndex++) {
    final wall = _rect(r.map.walls[wallIndex]);
    final vertical = wall.height > wall.width;
    final count = ((vertical ? wall.height : wall.width) / 22).ceil();
    for (var i = 0; i < count; i++) {
      final box = vertical
          ? Rect.fromLTWH(wall.left, wall.top + i * wall.height / count,
              wall.width, wall.height / count)
          : Rect.fromLTWH(wall.left + i * wall.width / count, wall.top,
              wall.width / count, wall.height);
      final color = [
        const Color(0xFFE5A262),
        const Color(0xFF86ACC0),
        const Color(0xFFD28A9A)
      ][(i + wallIndex) % 3];
      _fill(c, box.shift(const Offset(2, 4)), const Color(0x33402A14), 2);
      _fill(c, box.deflate(.5), color, 2);
      c.drawRRect(
          RRect.fromRectAndRadius(box.deflate(2), const Radius.circular(2)),
          Paint()
            ..color = const Color(0x99FFE4B9)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1);
      _line(c, box.topLeft + const Offset(3, 3),
          box.topRight + const Offset(-3, 3), const Color(0x66FFFFFF), 1.5);
    }
  }
  // Rubber mat marks the bouncing-ball zone without restricting movement.
  _fill(c, const Rect.fromLTWH(430, 208, 295, 39), const Color(0x447EBAA8), 15);
  // Low bright perimeter fence; the centre stays clear for the whole herd.
  for (var x = 12.0; x < 800; x += 23) {
    _fill(c, Rect.fromLTWH(x, 54, 13, 19), const Color(0xFFFFE8A9), 4);
  }
  _line(c, const Offset(0, 68), const Offset(800, 68), const Color(0xFFBA935D),
      3);
  // Toy blocks and a little slide sit outside the traffic lanes.
  for (var i = 0; i < 3; i++) {
    final x = 25 + i * 24.0;
    _fill(
        c,
        Rect.fromLTWH(x, 92 + (i.isEven ? 0 : 8), 22, 22),
        [
          const Color(0xFFE9A469),
          const Color(0xFF7DA7C0),
          const Color(0xFFD68E9E)
        ][i],
        3);
    _line(c, Offset(x + 5, 98 + (i.isEven ? 0 : 8)),
        Offset(x + 15, 98 + (i.isEven ? 0 : 8)), const Color(0x66FFFFFF), 2);
  }
  _line(c, const Offset(735, 310), const Offset(735, 260),
      const Color(0xFF827596), 4);
  _line(c, const Offset(758, 310), const Offset(758, 260),
      const Color(0xFF827596), 4);
  for (var i = 0; i < 4; i++) {
    _line(c, Offset(735, 270 + i * 10.0), Offset(758, 270 + i * 10.0),
        const Color(0xFFB2A5C2), 3);
  }
  c.drawPath(
      Path()
        ..moveTo(730, 261)
        ..lineTo(716, 261)
        ..quadraticBezierTo(704, 304, 677, 312)
        ..lineTo(677, 321)
        ..quadraticBezierTo(713, 319, 730, 261)
        ..close(),
      Paint()..color = const Color(0xFFEEA262));
  _line(c, const Offset(717, 261), const Offset(700, 301),
      const Color(0xFFFFCF8B), 3);
  for (final p in [const Offset(125, 345), const Offset(670, 90)]) {
    c.drawCircle(p, 10, Paint()..color = const Color(0xFFE6A1B4));
    c.drawArc(
        Rect.fromCircle(center: p, radius: 7),
        0,
        4,
        false,
        Paint()
          ..color = const Color(0xFFAB758D)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);
  }
}

void _tutorial(Canvas c, HerdRound r) {
  _base(c, const Color(0xFFB5DBC3), const Color(0xFFDBE8B2));
  _fill(c, const Rect.fromLTWH(0, 65, 800, 8), const Color(0xFFD6C39A));
  for (var x = 12.0; x < 800; x += 25) {
    _fill(c, Rect.fromLTWH(x, 51, 14, 24), const Color(0xFFFFF1CC), 4);
  }
  // A gentle slalom suggests a route; the yard remains open on both sides.
  final path = Path();
  for (var i = 0; i < r.map.route.main.length; i++) {
    final p = r.map.route.main[i];
    if (i == 0) {
      path.moveTo(p.dx * 800, p.dy * 375);
    } else {
      path.lineTo(p.dx * 800, p.dy * 375);
    }
  }
  c.drawPath(
      path,
      Paint()
        ..color = const Color(0x66E8D6AA)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 40
        ..strokeCap = StrokeCap.round);
  for (final wall in r.map.walls) {
    final box = _rect(wall);
    _rock(c, box, const Color(0xFF9BA69A));
    _line(c, box.topLeft + const Offset(5, 14), box.center,
        const Color(0xFFCFD4BC), 2);
    c.drawOval(
        Rect.fromCenter(
            center: box.bottomRight + const Offset(-6, -4),
            width: 14,
            height: 6),
        Paint()..color = const Color(0xFF8DA76D));
  }
  for (final p in [const Offset(25, 125), const Offset(765, 300)]) {
    _fill(c, Rect.fromCenter(center: p, width: 22, height: 20),
        const Color(0xFFD59B78), 4);
    for (var i = 0; i < 3; i++) {
      final flower = p + Offset((i - 1) * 7, -20 - (i % 2) * 5.0);
      _line(c, p + Offset((i - 1) * 7, -7), flower, const Color(0xFF729564), 2);
      c.drawCircle(flower, 5, Paint()..color = const Color(0xFFF2B2AE));
      c.drawCircle(flower, 2, Paint()..color = const Color(0xFFFFE9A6));
    }
  }
}
