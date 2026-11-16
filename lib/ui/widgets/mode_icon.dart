import '../design.dart';
import 'package:flutter/material.dart';

enum ModeIconKind { catchCat, fishing, nightShift, adventure, camp, herd }

/// Flat mode badges: one colored tile with a single white symbol.
class ModeIcon extends StatelessWidget {
  const ModeIcon(
      {super.key, required this.kind, this.size = 52, this.onColor = false});
  final ModeIconKind kind;
  final double size;

  /// On a coloured tile: draw a translucent white badge instead of a colour one.
  final bool onColor;

  @override
  Widget build(BuildContext context) => SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _ModeIconPainter(kind, onColor)));
}

class _ModeIconPainter extends CustomPainter {
  const _ModeIconPainter(this.kind, this.onColor);
  final ModeIconKind kind;
  final bool onColor;

  Color get _color => switch (kind) {
        ModeIconKind.catchCat => const Color(0xFFD9657B),
        ModeIconKind.fishing => DS.modeFishing,
        ModeIconKind.nightShift => DS.modeNightShift,
        ModeIconKind.adventure => DS.modeAdventure,
        ModeIconKind.camp => DS.modeCamp,
        ModeIconKind.herd => DS.modeHerd,
      };

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 56, size.height / 56);
    final color = _color;
    final tile = RRect.fromRectAndRadius(
        const Rect.fromLTWH(2, 2, 52, 52), const Radius.circular(15));
    if (onColor) {
      canvas.drawRRect(tile, Paint()..color = const Color(0x2EFFFFFF));
      canvas.drawRRect(
          tile.deflate(.8),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6
            ..color = const Color(0x55FFFFFF));
    } else {
      canvas.drawRRect(
          tile,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color.lerp(color, Colors.white, .22)!, color],
            ).createShader(tile.outerRect));
    }
    switch (kind) {
      case ModeIconKind.catchCat:
        _catchCat(canvas, color);
      case ModeIconKind.fishing:
        _fishing(canvas, color);
      case ModeIconKind.nightShift:
        _nightShift(canvas, color);
      case ModeIconKind.adventure:
        _adventure(canvas, color);
      case ModeIconKind.herd:
        _herd(canvas, color);
      case ModeIconKind.camp:
        _camp(canvas, color);
    }
    canvas.restore();
  }

  Paint get _white => Paint()..color = Colors.white;
  Paint _ink(Color color) =>
      Paint()..color = Color.lerp(color, DS.ink, .48)!.withOpacity(.88);
  Paint _stroke(Color color, double width) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  void _shape(Canvas canvas, Path path, Color color) {
    canvas.drawPath(path.shift(const Offset(0, 2)),
        Paint()..color = const Color(0x33000000));
    canvas.drawPath(path, _white);
    canvas.drawPath(path, _stroke(Color.lerp(color, DS.ink, .35)!, 1.4));
  }

  Path _catHead(Offset c, double s) => Path()
    ..moveTo(c.dx - 13 * s, c.dy - 1 * s)
    ..lineTo(c.dx - 11 * s, c.dy - 16 * s)
    ..lineTo(c.dx - 4 * s, c.dy - 9 * s)
    ..quadraticBezierTo(c.dx, c.dy - 11 * s, c.dx + 4 * s, c.dy - 9 * s)
    ..lineTo(c.dx + 11 * s, c.dy - 16 * s)
    ..lineTo(c.dx + 13 * s, c.dy - 1 * s)
    ..quadraticBezierTo(c.dx + 15 * s, c.dy + 15 * s, c.dx, c.dy + 15 * s)
    ..quadraticBezierTo(
        c.dx - 15 * s, c.dy + 15 * s, c.dx - 13 * s, c.dy - 1 * s)
    ..close();

  void _catFace(Canvas canvas, Offset c, double s, Color color) {
    final ink = _ink(color);
    canvas.drawCircle(c + Offset(-5 * s, 1 * s), 1.8 * s, ink);
    canvas.drawCircle(c + Offset(5 * s, 1 * s), 1.8 * s, ink);
    canvas.drawPath(
        Path()
          ..moveTo(c.dx - 2 * s, c.dy + 5 * s)
          ..lineTo(c.dx + 2 * s, c.dy + 5 * s)
          ..lineTo(c.dx, c.dy + 7 * s)
          ..close(),
        ink);
    final whisker = _stroke(ink.color.withOpacity(.65), .9 * s);
    canvas.drawLine(
        c + Offset(-7 * s, 6 * s), c + Offset(-13 * s, 5 * s), whisker);
    canvas.drawLine(
        c + Offset(7 * s, 6 * s), c + Offset(13 * s, 5 * s), whisker);
  }

  void _catchCat(Canvas canvas, Color color) {
    const c = Offset(25, 30);
    _shape(canvas, _catHead(c, 1), color);
    _catFace(canvas, c, 1, color);
    final paw = Paint()..color = const Color(0xCCFFFFFF);
    canvas.drawOval(
        Rect.fromCenter(center: const Offset(42, 18), width: 8, height: 7),
        paw);
    for (final toe in const [
      Offset(38, 12.5),
      Offset(41.2, 10.8),
      Offset(44.6, 11.4),
      Offset(46.6, 14.5),
    ]) {
      canvas.drawCircle(toe, 1.7, paw);
    }
  }

  void _fishing(Canvas canvas, Color color) {
    final fish = Path()
      ..moveTo(9, 31)
      ..quadraticBezierTo(21, 16, 35, 29)
      ..lineTo(46, 20)
      ..lineTo(43, 31)
      ..lineTo(47, 41)
      ..lineTo(35, 33)
      ..quadraticBezierTo(21, 46, 9, 31)
      ..close();
    _shape(canvas, fish, color);
    canvas.drawCircle(const Offset(17, 28), 2.2, _ink(color));
    canvas.drawArc(Rect.fromCircle(center: const Offset(24, 31), radius: 6),
        -1.1, 2.2, false, _stroke(color.withOpacity(.75), 1.6));
    final bubble = _stroke(Colors.white, 1.6);
    canvas.drawCircle(const Offset(39, 12), 3, bubble);
    canvas.drawCircle(const Offset(45, 8), 1.8, bubble);
  }

  Path _star(Offset c, double r) => Path()
    ..moveTo(c.dx, c.dy - r * 1.6)
    ..lineTo(c.dx + r * .45, c.dy - r * .45)
    ..lineTo(c.dx + r * 1.6, c.dy)
    ..lineTo(c.dx + r * .45, c.dy + r * .45)
    ..lineTo(c.dx, c.dy + r * 1.6)
    ..lineTo(c.dx - r * .45, c.dy + r * .45)
    ..lineTo(c.dx - r * 1.6, c.dy)
    ..lineTo(c.dx - r * .45, c.dy - r * .45)
    ..close();

  void _nightShift(Canvas canvas, Color color) {
    final moon = Path.combine(
        PathOperation.difference,
        Path()
          ..addOval(Rect.fromCircle(center: const Offset(23, 27), radius: 15)),
        Path()
          ..addOval(Rect.fromCircle(center: const Offset(31, 20), radius: 13)));
    _shape(canvas, moon, color);
    canvas.drawPath(_star(const Offset(38, 13), 2.6), _white);
    canvas.drawPath(_star(const Offset(14, 44), 2), _white);
    canvas.drawLine(
        const Offset(40, 22), const Offset(40, 27), _stroke(Colors.white, 1.8));
    final lantern = RRect.fromRectAndRadius(
        const Rect.fromLTWH(34, 27, 12, 15), const Radius.circular(5));
    canvas.drawRRect(lantern.shift(const Offset(0, 1.5)),
        Paint()..color = const Color(0x33000000));
    canvas.drawRRect(lantern, _white);
    canvas.drawRRect(
        lantern.deflate(3.2), Paint()..color = color.withOpacity(.2));
    canvas.drawRRect(lantern, _stroke(Color.lerp(color, DS.ink, .35)!, 1.3));
  }

  void _adventure(Canvas canvas, Color color) {
    final road = Path()
      ..moveTo(13, 43)
      ..cubicTo(27, 41, 31, 35, 23, 31)
      ..cubicTo(15, 27, 20, 19, 34, 17);
    canvas.drawPath(
        road.shift(const Offset(0, 2)), _stroke(const Color(0x33000000), 9));
    canvas.drawPath(road, _stroke(Colors.white, 9));
    final dash = _stroke(color.withOpacity(.7), 1.8);
    for (final segment in road.computeMetrics()) {
      for (var d = 4.0; d < segment.length; d += 8) {
        canvas.drawPath(segment.extractPath(d, d + 3), dash);
      }
    }
    canvas.drawLine(
        const Offset(38, 32), const Offset(38, 9), _stroke(Colors.white, 3));
    final flag = Path()
      ..moveTo(39, 9)
      ..lineTo(49, 13)
      ..lineTo(39, 18)
      ..close();
    canvas.drawPath(flag, _white);
    canvas.drawPath(flag, _stroke(Color.lerp(color, DS.ink, .35)!, 1.2));
    canvas.drawCircle(
        const Offset(15, 17), 3, Paint()..color = const Color(0xCCFFFFFF));
  }

  void _herd(Canvas canvas, Color color) {
    for (final (c, s) in const [
      (Offset(16, 38), .58),
      (Offset(39, 37), .58),
      (Offset(28, 27), .75),
    ]) {
      _shape(canvas, _catHead(c, s), color);
      _catFace(canvas, c, s, color);
    }
  }

  void _camp(Canvas canvas, Color color) {
    final house = Path()
      ..moveTo(9, 26)
      ..lineTo(28, 10)
      ..lineTo(47, 26)
      ..lineTo(42, 26)
      ..lineTo(42, 46)
      ..lineTo(14, 46)
      ..lineTo(14, 26)
      ..close();
    _shape(canvas, house, color);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(23, 34, 10, 12), const Radius.circular(4)),
        Paint()..color = color.withOpacity(.82));
    final window = Paint()..color = color.withOpacity(.28);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(18, 29, 7, 6), const Radius.circular(1.5)),
        window);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(31, 29, 7, 6), const Radius.circular(1.5)),
        window);
  }

  @override
  bool shouldRepaint(covariant _ModeIconPainter oldDelegate) =>
      kind != oldDelegate.kind || onColor != oldDelegate.onColor;
}
