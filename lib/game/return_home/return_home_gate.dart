import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/painting.dart';
import 'return_home_game.dart';

/// The shelter entrance opens when the dragon is defeated.
class ReturnHomeGate extends Component with HasGameReference<ReturnHomeGame> {
  ReturnHomeGate() : super(priority: 3);

  double _open = 0;
  double _time = 0;
  double _celebration = 0;
  static const _ink = Color(0xFF68412D);

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    _open += ((game.bossDefeated ? 1.0 : 0.0) - _open) * (1 - exp(-5 * dt));
    if (game.finished) _celebration += dt;
  }

  void _wood(Canvas canvas, Rect rect, Color color, {double radius = 4}) {
    final shape = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    canvas.drawRRect(shape, Paint()..color = color);
    canvas.drawRRect(
        shape,
        Paint()
          ..color = _ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
  }

  void _paw(Canvas canvas, Offset center, double scale, Color color) {
    final paint = Paint()..color = color;
    canvas.drawOval(
        Rect.fromCenter(
            center: center + Offset(0, scale * .3),
            width: scale * 1.1,
            height: scale * .85),
        paint);
    for (final p in const [
      Offset(-.65, -.35),
      Offset(-.23, -.7),
      Offset(.23, -.7),
      Offset(.65, -.35)
    ]) {
      canvas.drawOval(
          Rect.fromCenter(
              center: center + p * scale,
              width: scale * .4,
              height: scale * .5),
          paint);
    }
  }

  @override
  void render(Canvas canvas) {
    final road = game.road;
    final x = road.endX + 24;
    final base = road.bottomEdge(x) + 8;
    final height = road.halfWidth(x) * 2 + 54;
    canvas.save();
    canvas.translate(x, base);
    canvas.drawOval(
        Rect.fromCenter(center: const Offset(0, 5), width: 154, height: 24),
        Paint()..color = const Color(0x33604432));
    // Fence extensions leave the center of the road open.
    for (final side in [-1.0, 1.0]) {
      _wood(canvas, Rect.fromLTWH(side < 0 ? -83 : 59, -51, 24, 7),
          const Color(0xFFE0BA7D));
      _wood(canvas, Rect.fromLTWH(side < 0 ? -83 : 59, -27, 24, 7),
          const Color(0xFFE0BA7D));
      for (var i = 0; i < 2; i++) {
        final px = side * (67 + i * 13.0);
        _wood(
            canvas, Rect.fromLTWH(px - 3, -62, 7, 68), const Color(0xFFF2D49A));
      }
    }
    // Warm pavers and a trail that appears after the boss fight.
    final path = RRect.fromRectAndRadius(
        const Rect.fromLTWH(-48, -65, 96, 60), const Radius.circular(12));
    canvas.drawRRect(path, Paint()..color = const Color(0x66E0C087));
    if (_open > .05) {
      for (var i = 0; i < 4; i++) {
        final p = Offset(-97 + i * 26.0, -44 + (i.isEven ? -7 : 7));
        final alpha = (_open * (.55 + .3 * sin(_time * 3 - i))).clamp(0.0, 1.0);
        _paw(
            canvas, p, 6, Color.fromARGB((alpha * 255).round(), 255, 246, 184));
      }
    }
    for (final side in [-1.0, 1.0]) {
      _wood(canvas, Rect.fromLTWH(side * 56 - 7, -height + 28, 14, height - 23),
          const Color(0xFFB67C4E));
      canvas.drawLine(
          Offset(side * 56 - 3, -height + 35),
          Offset(side * 56 - 3, -5),
          Paint()
            ..color = const Color(0xFFE5B77B)
            ..strokeWidth = 2);
      // Door leaves fold towards the posts as the gate opens.
      final width = 49 * (1 - _open) + 3;
      final leafX = side < 0 ? -49.0 : 49 - width;
      _wood(canvas, Rect.fromLTWH(leafX, -91, width, 77),
          const Color(0xFF79A878));
      if (width > 12) {
        canvas.save();
        canvas.clipRect(Rect.fromLTWH(leafX, -91, width, 77));
        for (var i = 1; i < 4; i++) {
          final sx = leafX + i * width / 4;
          canvas.drawLine(
              Offset(sx, -88),
              Offset(sx, -17),
              Paint()
                ..color = const Color(0xFF527F58)
                ..strokeWidth = 1.5);
        }
        canvas.restore();
      }
      // Hanging lantern.
      final lamp = Offset(side * 67, -height + 68);
      canvas.drawCircle(
          lamp,
          17,
          Paint()
            ..shader = const RadialGradient(
                    colors: [Color(0x99FFD764), Color(0x00FFD764)])
                .createShader(Rect.fromCircle(center: lamp, radius: 17)));
      canvas.drawLine(
          lamp - const Offset(0, 20),
          lamp - const Offset(0, 9),
          Paint()
            ..color = _ink
            ..strokeWidth = 2);
      _wood(canvas, Rect.fromCenter(center: lamp, width: 11, height: 17),
          const Color(0xFFFFD974),
          radius: 2);
      // Pots at the gate posts.
      _wood(canvas, Rect.fromLTWH(side * 61 - 9, -12, 18, 17),
          const Color(0xFFBB7155));
      for (var i = 0; i < 3; i++) {
        final flower = Offset(side * 61 + (i - 1) * 6, -19 - (i % 2) * 6);
        canvas.drawLine(
            flower,
            Offset(side * 61, -8),
            Paint()
              ..color = const Color(0xFF50864B)
              ..strokeWidth = 2);
        for (var petal = 0; petal < 5; petal++) {
          final a = petal * pi * 2 / 5;
          canvas.drawCircle(flower + Offset(cos(a), sin(a)) * 3, 3,
              Paint()..color = const Color(0xFFF6A1A7));
        }
        canvas.drawCircle(flower, 2, Paint()..color = const Color(0xFFFFE68A));
      }
    }
    // Broad roof and a readable shelter sign with a paw medallion.
    final roof = Path()
      ..moveTo(-78, -height + 25)
      ..lineTo(-62, -height + 8)
      ..quadraticBezierTo(0, -height - 17, 62, -height + 8)
      ..lineTo(78, -height + 25)
      ..close();
    canvas.drawPath(roof, Paint()..color = const Color(0xFF5F8F72));
    canvas.drawPath(
        roof,
        Paint()
          ..color = _ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5);
    _wood(canvas, Rect.fromLTWH(-70, -height + 22, 140, 31),
        const Color(0xFFFFE5AD),
        radius: 7);
    final title = TextPainter(
        text: const TextSpan(
            text: 'MEOW SHELTER',
            style: TextStyle(
                color: _ink, fontSize: 12, fontWeight: FontWeight.w900)),
        textDirection: TextDirection.ltr)
      ..layout(maxWidth: 132);
    title.paint(canvas, Offset(-title.width / 2, -height + 30));
    canvas.drawCircle(
        Offset(0, -height + 4), 13, Paint()..color = const Color(0xFFFFD478));
    canvas.drawCircle(
        Offset(0, -height + 4),
        13,
        Paint()
          ..color = _ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
    _paw(canvas, Offset(0, -height + 4), 10, _ink);
    if (game.finished && _celebration < 3) {
      for (var i = 0; i < 22; i++) {
        final age = (_celebration + i * .07) % 1.6;
        final spread = (i % 2 == 0 ? -1 : 1) * (12 + i * 2.0) * age;
        final c = Offset(spread, -height + 25 - age * 100 + age * age * 80);
        canvas.save();
        canvas.translate(c.dx, c.dy);
        canvas.rotate(age * 4 + i.toDouble());
        canvas.drawRect(
            const Rect.fromLTWH(-2, -4, 4, 8),
            Paint()
              ..color = [
                const Color(0xFFFFC24D),
                const Color(0xFFF194A6),
                const Color(0xFF85C8BD)
              ][i % 3]);
        canvas.restore();
      }
    }
    canvas.restore();
  }
}
