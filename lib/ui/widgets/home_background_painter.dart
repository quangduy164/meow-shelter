import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../game/world/nature_art.dart';
import '../home_theme.dart';
import 'home_christmas_art.dart';

/// Home background: a soft dusk sky, layered hills and a winding path that
/// leads to the shelter on the far right. Details stay near the edges so the
/// logo, the play button and the mode tiles always sit on calm areas.
///
/// Drawn in a 600-high space; width follows the screen ratio so shapes keep
/// their proportions on every device.
class HomeBackgroundPainter extends CustomPainter {
  const HomeBackgroundPainter({this.christmas = christmasEnabled});

  final bool christmas;

  static const _h = 600.0;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.height / _h;
    final w = size.width / s;
    canvas.save();
    canvas.scale(s, s);
    _sky(canvas, w);
    _stars(canvas, w);
    _sun(canvas, Offset(w * .42, 360));
    paintPuffyCloud(canvas, Offset(w * .09, 92), 190,
        seed: 1, palette: CloudPalette.dusk, opacity: .85);
    paintPuffyCloud(canvas, Offset(w * .5, 58), 130,
        seed: 2, palette: CloudPalette.dusk, opacity: .75);
    paintPuffyCloud(canvas, Offset(w * .9, 122), 160,
        seed: 3, palette: CloudPalette.dusk, opacity: .82);
    _hills(canvas, w, 360, 70,
        christmas ? const Color(0xFF8EAEC8) : const Color(0xFFB59BC8), 0);
    _hills(canvas, w, 410, 50,
        christmas ? const Color(0xFFBCD4DF) : const Color(0xFF9DB98F), 1.4);
    _hills(canvas, w, 460, 34,
        christmas ? const Color(0xFFDBEAF0) : const Color(0xFF7FAA6E), 2.7);
    _hills(canvas, w, 520, 14,
        christmas ? const Color(0xFFF0F7F6) : const Color(0xFF6A9A5C), 4.1);
    if (!christmas) {
      paintLeafyTree(canvas, const Offset(104, 482), 104,
          seed: 5, palette: TreePalette.dusk);
      paintLeafyTree(canvas, const Offset(40, 476), 160,
          seed: 4, palette: TreePalette.dusk);
    }
    _path(canvas, w);
    if (christmas) {
      paintWinterShelter(canvas, Offset(w - 95, 486));
    } else {
      _shelter(canvas, Offset(w - 95, 486));
    }
    if (!christmas) _flowers(canvas, w);
    _vignette(canvas, w);
    if (christmas) paintHomeChristmas(canvas, w);
    canvas.restore();
  }

  void _sky(Canvas canvas, double w) {
    final rect = Rect.fromLTWH(0, 0, w, _h);
    canvas.drawRect(
        rect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: christmas
                ? const [
                    Color(0xFF254C73),
                    Color(0xFF588BA9),
                    Color(0xFFB1CCD9),
                    Color(0xFFECDCC2),
                  ]
                : const [
                    Color(0xFF6E6BB0),
                    Color(0xFFB08DC4),
                    Color(0xFFF2B6A0),
                    Color(0xFFFFD9A0),
                  ],
            stops: const [0, .32, .55, .7],
          ).createShader(rect));
  }

  void _stars(Canvas canvas, double w) {
    final random = math.Random(3);
    final p = Paint()..color = const Color(0xCCFFF4DA);
    for (var i = 0; i < 40; i++) {
      final o = Offset(random.nextDouble() * w, random.nextDouble() * 160);
      canvas.drawCircle(o, random.nextDouble() * 1.6 + .6, p);
    }
  }

  void _sun(Canvas canvas, Offset c) {
    canvas.drawCircle(
        c,
        230,
        Paint()
          ..shader = const RadialGradient(colors: [
            Color(0x88FFF1C4),
            Color(0x00FFE0A8),
          ]).createShader(Rect.fromCircle(center: c, radius: 230)));
    canvas.drawCircle(c, 70, Paint()..color = const Color(0xFFFFE3A6));
  }

  void _hills(Canvas canvas, double w, double top, double amp, Color color,
      double phase) {
    final path = Path()..moveTo(0, _h);
    for (var x = 0.0; x <= w + 20; x += 16) {
      path.lineTo(
          x,
          top +
              math.sin(x / 230 + phase) * amp * .6 +
              math.sin(x / 90 + phase * 2) * amp * .15);
    }
    path
      ..lineTo(w, _h)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  void _path(Canvas canvas, double w) {
    if (christmas) {
      paintWinterPath(canvas, w);
      return;
    }
    final door = Offset(w - 95, 486);
    final path = Path()
      ..moveTo(w * .08, 610)
      ..cubicTo(w * .26, 523, w * .57, 594, w * .76, 531)
      ..quadraticBezierTo(w * .87, 494, door.dx - 13, door.dy)
      ..lineTo(door.dx + 13, door.dy)
      ..quadraticBezierTo(w * .88, 510, w * .78, 550)
      ..cubicTo(w * .60, 623, w * .35, 568, w * .23, 610)
      ..close();
    canvas.drawPath(path.shift(const Offset(0, 5)),
        Paint()..color = const Color(0x44516F43));
    canvas.drawPath(
        path,
        Paint()
          ..shader = const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFCCAA76), Color(0xFFF0D9AF)])
              .createShader(const Rect.fromLTWH(0, 480, 100, 130)));
    final center = Path()
      ..moveTo(w * .155, 610)
      ..cubicTo(w * .31, 545, w * .59, 610, w * .77, 541)
      ..quadraticBezierTo(w * .88, 502, door.dx, door.dy);
    canvas.save();
    canvas.clipPath(path);
    final random = math.Random(38);
    for (var i = 0; i < 140; i++) {
      final p =
          Offset(random.nextDouble() * w, 490 + random.nextDouble() * 120);
      canvas.drawOval(
          Rect.fromCenter(
              center: p, width: 1.5 + random.nextDouble() * 3, height: 1.4),
          Paint()..color = const Color(0x448F7550));
    }
    final paw = Paint()..color = const Color(0x668B7050);
    for (final metric in center.computeMetrics()) {
      for (var d = 24.0; d < metric.length - 25; d += 30) {
        final t = metric.getTangentForOffset(d)!;
        final side = (d ~/ 30).isEven ? 4.5 : -4.5;
        canvas.save();
        canvas.translate(t.position.dx - t.vector.dy * side,
            t.position.dy + t.vector.dx * side);
        canvas.rotate(math.atan2(t.vector.dy, t.vector.dx));
        canvas.drawOval(const Rect.fromLTWH(-3, -2, 6, 4), paw);
        for (var toe = 0; toe < 3; toe++) {
          canvas.drawCircle(Offset(3, -2.4 + toe * 2.4), 1.1, paw);
        }
        canvas.restore();
      }
    }
    canvas.restore();
    // Small stones and tufts break up the edges of the cleared dirt trail.
    for (final metric in path.computeMetrics()) {
      for (var d = 18.0; d < metric.length; d += 38) {
        final t = metric.getTangentForOffset(d)!;
        if (t.position.dy > 598) continue;
        canvas.drawOval(
            Rect.fromCenter(
                center: t.position + const Offset(0, 2), width: 7, height: 4),
            Paint()..color = const Color(0xFF8B9A75));
        canvas.drawLine(
            t.position - const Offset(6, 0),
            t.position - const Offset(9, 6),
            Paint()
              ..color = const Color(0xFF73935A)
              ..strokeWidth = 1.4
              ..strokeCap = StrokeCap.round);
      }
    }
  }

  /// A timber cottage with a tiled roof and a porch at the end of the trail.
  void _shelter(Canvas canvas, Offset base) {
    canvas.save();
    canvas.translate(base.dx, base.dy);
    const wood = Color(0xFF79543F);
    const cream = Color(0xFFFFE9BB);
    canvas.drawOval(const Rect.fromLTWH(-88, -5, 180, 24),
        Paint()..color = const Color(0x44516A42));
    // Side wall and shaded eaves give the cottage depth.
    canvas.drawPath(
        Path()
          ..moveTo(61, -72)
          ..lineTo(80, -60)
          ..lineTo(80, 0)
          ..lineTo(61, 6)
          ..close(),
        Paint()..color = const Color(0xFFB38D68));
    const wall = Rect.fromLTWH(-62, -75, 124, 78);
    canvas.drawRect(
        wall,
        Paint()
          ..shader = const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFFFEAC1), Color(0xFFE6C293)])
              .createShader(wall));
    final plank = Paint()
      ..color = const Color(0x33835B3D)
      ..strokeWidth = 1;
    for (var y = -65.0; y < 0; y += 12) {
      canvas.drawLine(Offset(-60, y), Offset(60, y), plank);
    }
    for (final x in [-60.0, 59.0]) {
      canvas.drawRect(Rect.fromLTWH(x, -70, 3, 73),
          Paint()..color = const Color(0xFFB18960));
    }
    final roof = Path()
      ..moveTo(-80, -71)
      ..quadraticBezierTo(-43, -91, -4, -128)
      ..quadraticBezierTo(0, -131, 5, -128)
      ..quadraticBezierTo(44, -93, 81, -71)
      ..quadraticBezierTo(48, -68, 0, -73)
      ..quadraticBezierTo(-48, -68, -80, -71)
      ..close();
    canvas.drawPath(roof.shift(const Offset(0, 5)),
        Paint()..color = const Color(0x775C4136));
    canvas.drawPath(
        roof,
        Paint()
          ..shader = const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFDB8965),
                Color(0xFFB65C4F),
                Color(0xFF8C4546)
              ]).createShader(const Rect.fromLTWH(-80, -130, 160, 60)));
    canvas.save();
    canvas.clipPath(roof);
    final tile = Paint()
      ..color = const Color(0x557A3D38)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var row = 0; row < 5; row++) {
      final y = -122.0 + row * 12;
      for (var col = 0; col < 10; col++) {
        final x = -90.0 + col * 19 + (row.isEven ? 0 : 9);
        canvas.drawPath(
            Path()
              ..moveTo(x, y)
              ..quadraticBezierTo(x + 9, y + 6, x + 19, y)
              ..lineTo(x + 19, y - 9),
            tile);
      }
    }
    canvas.restore();
    canvas.drawPath(
        Path()
          ..moveTo(-79, -71)
          ..quadraticBezierTo(-44, -93, -2, -129)
          ..quadraticBezierTo(0, -131, 3, -129)
          ..quadraticBezierTo(44, -93, 80, -71),
        Paint()
          ..color = const Color(0xFFF0AF7B)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round);
    // Paw plaque at the centre of the roof.
    canvas.drawCircle(const Offset(0, -94), 12.5, Paint()..color = wood);
    canvas.drawCircle(const Offset(0, -95), 10.5, Paint()..color = cream);
    final pad = Paint()..color = const Color(0xFFAC5B4A);
    canvas.drawOval(const Rect.fromLTWH(-4.5, -96, 9, 7), pad);
    for (final d in const [
      Offset(-5, -100),
      Offset(0, -103),
      Offset(5, -100)
    ]) {
      canvas.drawCircle(d, 2.1, pad);
    }
    // Lit windows, green shutters and flower boxes.
    for (final x in [-39.0, 39.0]) {
      final light = Rect.fromCircle(center: Offset(x, -37), radius: 28);
      canvas.drawCircle(
          Offset(x, -37),
          28,
          Paint()
            ..shader = const RadialGradient(
                    colors: [Color(0x44FFE1A0), Color(0x00FFE1A0)])
                .createShader(light));
      final window = RRect.fromRectAndRadius(
          Rect.fromLTWH(x - 12, -55, 24, 29), const Radius.circular(4));
      canvas.drawRRect(window.inflate(2.5), Paint()..color = wood);
      canvas.drawRRect(
          window,
          Paint()
            ..shader = const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFFEDB6), Color(0xFFEAB96D)])
                .createShader(window.outerRect));
      final frame = Paint()
        ..color = wood
        ..strokeWidth = 1.6;
      canvas.drawLine(Offset(x, -55), Offset(x, -26), frame);
      canvas.drawLine(Offset(x - 12, -41), Offset(x + 12, -41), frame);
      for (final side in [-1.0, 1.0]) {
        final sx = x + side * 17;
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromCenter(center: Offset(sx, -40), width: 6, height: 29),
                const Radius.circular(1)),
            Paint()..color = const Color(0xFF5B8068));
        for (var y = -49.0; y < -28; y += 6) {
          canvas.drawLine(
              Offset(sx - 2, y),
              Offset(sx + 2, y),
              Paint()
                ..color = const Color(0xFF85A083)
                ..strokeWidth = 1);
        }
      }
      final leaves = Paint()..color = const Color(0xFF648457);
      for (var i = 0; i < 5; i++) {
        final p = Offset(x - 12 + i * 6, -21.0 - (i.isEven ? 3 : 0));
        canvas.drawOval(
            Rect.fromCenter(center: p, width: 8, height: 6), leaves);
        canvas.drawCircle(p - const Offset(0, 3), 2.4,
            Paint()..color = i.isEven ? const Color(0xFFEBA5A1) : cream);
      }
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(x - 16, -21, 32, 9), const Radius.circular(2)),
          Paint()..color = const Color(0xFFAC7153));
      canvas.drawLine(
          Offset(x - 16, -21),
          Offset(x + 16, -21),
          Paint()
            ..color = const Color(0xFFD69E70)
            ..strokeWidth = 2);
    }
    final entry = RRect.fromRectAndCorners(
        const Rect.fromLTWH(-14, -43, 28, 46),
        topLeft: const Radius.circular(14),
        topRight: const Radius.circular(14));
    canvas.drawRRect(
        entry.inflate(3), Paint()..color = const Color(0xFFB3875A));
    canvas.drawRRect(
        entry,
        Paint()
          ..shader = const LinearGradient(
                  colors: [Color(0xFF98724F), Color(0xFF684B3C)])
              .createShader(entry.outerRect));
    for (final x in [-6.0, 2.0]) {
      canvas.drawLine(
          Offset(x, -32),
          Offset(x, 1),
          Paint()
            ..color = const Color(0x44714A34)
            ..strokeWidth = 1);
    }
    canvas.drawCircle(
        const Offset(8, -14), 1.8, Paint()..color = const Color(0xFFF2CE7F));
    // A low awning and porch step connect the doorway to the path.
    canvas.drawPath(
        Path()
          ..moveTo(-22, -44)
          ..lineTo(-16, -51)
          ..lineTo(16, -51)
          ..lineTo(22, -44)
          ..close(),
        Paint()..color = const Color(0xFFB96F50));
    canvas.drawLine(
        const Offset(-22, -44),
        const Offset(22, -44),
        Paint()
          ..color = const Color(0xFFE2A174)
          ..strokeWidth = 2);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(-23, 1, 46, 8), const Radius.circular(3)),
        Paint()..color = const Color(0xFFAB9477));
    canvas.drawLine(
        const Offset(-22, 1),
        const Offset(22, 1),
        Paint()
          ..color = const Color(0xFFDDCAA4)
          ..strokeWidth = 2);
    for (final side in [-1.0, 1.0]) {
      final x = side * 70;
      canvas.drawOval(
          Rect.fromCenter(center: Offset(x, 0), width: 28, height: 16),
          Paint()..color = const Color(0xFF648653));
      canvas.drawOval(
          Rect.fromCenter(center: Offset(x - 3, -4), width: 20, height: 14),
          Paint()..color = const Color(0xFF829F61));
      for (var i = 0; i < 3; i++) {
        canvas.drawCircle(Offset(x - 7 + i * 6, -5 + (i.isEven ? 2 : -2)), 2,
            Paint()..color = const Color(0xFFE6B1A2));
      }
    }
    canvas.restore();
  }

  void _flowers(Canvas canvas, double w) {
    final random = math.Random(11);
    const colors = [Color(0xFFFFF4DA), Color(0xFFF7A9B8), Color(0xFFFFD36B)];
    for (var i = 0; i < 46; i++) {
      final x = random.nextDouble() * w;
      final y = 510 + random.nextDouble() * 85;
      canvas.drawCircle(
          Offset(x, y), 3, Paint()..color = colors[i % colors.length]);
    }
  }

  void _vignette(Canvas canvas, double w) {
    final rect = Rect.fromLTWH(0, 0, w, _h);
    canvas.drawRect(
        rect,
        Paint()
          ..shader = const RadialGradient(
            radius: 1.05,
            colors: [Color(0x00000000), Color(0x40301830)],
            stops: [.62, 1],
          ).createShader(rect));
  }

  @override
  bool shouldRepaint(covariant HomeBackgroundPainter oldDelegate) =>
      christmas != oldDelegate.christmas;
}
