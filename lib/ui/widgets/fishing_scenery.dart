import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:material_ui/material_ui.dart';
import '../../fishing/fishing_river.dart';

/// Cached scenic clusters, sorted around the walking cat by their ground anchor.
class FishingScenery extends StatefulWidget {
  const FishingScenery(
      {super.key,
      required this.round,
      required this.frames,
      required this.child});
  final FishingRiverRound round;
  final Listenable frames;
  final Widget child;
  @override
  State<FishingScenery> createState() => _FishingSceneryState();
}

class _Scenery {
  _Scenery(this.kind, this.point) {
    final r = ui.PictureRecorder();
    final c = Canvas(r);
    c.translate(point.dx, point.dy);
    _cluster(c, kind);
    picture = r.endRecording();
  }
  final int kind;
  final Offset point;
  late final ui.Picture picture;
  Rect get bounds => Rect.fromLTWH(point.dx - 160, point.dy - 175, 330, 210);
}

class _FishingSceneryState extends State<FishingScenery> {
  late final items = [
    for (final x in [760.0, 1260.0])
      _Scenery(0, Offset(x, FishingRiver.bottom(x) + 235)),
    for (final x in [650.0, 1640.0])
      _Scenery(0, Offset(x, FishingRiver.top(x) - 80)),
    for (final x in [2150.0, 2990.0])
      _Scenery(1, Offset(x, FishingRiver.top(x) - 75)),
    _Scenery(1, Offset(2700, FishingRiver.bottom(2700) + 255)),
    for (final x in [6000.0, 10300.0])
      _Scenery(2, Offset(x, FishingRiver.bottom(x) + 175)),
    _Scenery(4, Offset(2680, FishingRiver.bottom(2680) + 43)),
    for (final x in [330.0, 900.0, 1430.0])
      _Scenery(5, Offset(x + 34, FishingRiver.top(x) - 170)),
  ];
  @override
  void dispose() {
    for (final item in items) {
      item.picture.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(fit: StackFit.expand, children: [
        IgnorePointer(
            child: RepaintBoundary(
                child: CustomPaint(
                    painter: _SceneryPainter(
                        widget.round, items, widget.frames, false)))),
        widget.child,
        IgnorePointer(
            child: RepaintBoundary(
                child: CustomPaint(
                    painter: _SceneryPainter(
                        widget.round, items, widget.frames, true)))),
      ]);
}

class _SceneryPainter extends CustomPainter {
  _SceneryPainter(this.round, this.items, Listenable frames, this.front)
      : super(repaint: frames);
  final FishingRiverRound round;
  final List<_Scenery> items;
  final bool front;
  @override
  void paint(Canvas c, Size size) {
    c.save();
    c.clipRect(Offset.zero & size);
    c.scale(round.scale);
    c.translate(-round.cameraLeft, -round.cameraTop);
    final view = Rect.fromLTWH(round.cameraLeft, round.cameraTop,
        round.visibleWidth, round.visibleHeight);
    final cat = round.island.cat;
    for (final item in items) {
      if (!item.bounds.overlaps(view)) continue;
      final aboveCat = round.island.ashore && item.point.dy > cat.dy;
      if (aboveCat != front) continue;
      final fade = aboveCat &&
          item.bounds.overlaps(Rect.fromLTWH(cat.dx - 22, cat.dy - 58, 44, 65));
      if (fade) {
        c.saveLayer(item.bounds, Paint()..color = const Color(0x66FFFFFF));
      }
      c.drawPicture(item.picture);
      c.save();
      c.translate(item.point.dx, item.point.dy);
      _motion(c, item.kind, round.clock, item.point.dx);
      c.restore();
      if (fade) c.restore();
    }
    c.restore();
  }

  @override
  bool shouldRepaint(_SceneryPainter old) =>
      old.round != round || old.front != front;
}

void _line(Canvas c, Offset a, Offset b, Color color, double width) {
  c.drawLine(
      a,
      b,
      Paint()
        ..color = color
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round);
}

void _box(Canvas c, Rect r, Color color) {
  c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(3)),
      Paint()..color = color);
}

void _jar(Canvas c, Offset p) {
  c.drawOval(
      Rect.fromCenter(center: p + const Offset(0, 3), width: 27, height: 8),
      Paint()..color = const Color(0x33595C40));
  c.drawOval(
      Rect.fromCenter(center: p - const Offset(0, 13), width: 24, height: 30),
      Paint()..color = const Color(0xFFA87958));
  c.drawOval(
      Rect.fromCenter(center: p - const Offset(0, 26), width: 19, height: 7),
      Paint()..color = const Color(0xFF6D5843));
  c.drawArc(
      Rect.fromCenter(center: p - const Offset(3, 13), width: 12, height: 20),
      math.pi / 2,
      math.pi,
      false,
      Paint()
        ..color = const Color(0xFFC6A174)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2);
}

void _net(Canvas c, Offset p, double w, double h) {
  for (final x in [0.0, w]) {
    _line(c, p + Offset(x, 8), p + Offset(x, -h - 12), const Color(0xFF96754F),
        4);
  }
  _line(c, p + Offset(0, -h), p + Offset(w, -h), const Color(0xFFC3AE7F), 2);
  c.save();
  c.clipRect(Rect.fromLTWH(p.dx, p.dy - h, w, h));
  for (var i = -h; i < w + h; i += 12) {
    _line(
        c, p + Offset(i, -h), p + Offset(i + h, 0), const Color(0x998E9B84), 1);
    _line(
        c, p + Offset(i, 0), p + Offset(i + h, -h), const Color(0x998E9B84), 1);
  }
  c.restore();
}

void _shelter(Canvas c, {bool abandoned = false}) {
  for (final x in [-45.0, 45.0]) {
    _line(c, Offset(x, 0), Offset(x, -73), const Color(0xFF98794D), 6);
    _line(c, Offset(x, -50), Offset(-x, -70), const Color(0xFFB99A65), 2);
  }
  _box(c, const Rect.fromLTWH(-52, -7, 104, 12), const Color(0xFFB4925D));
  final roof = Path()
    ..moveTo(-70, -68)
    ..lineTo(-39, -111)
    ..lineTo(34, -111)
    ..lineTo(73, -68)
    ..close();
  c.drawPath(
      roof,
      Paint()
        ..color =
            abandoned ? const Color(0xFF9B9970) : const Color(0xFFB8A16A));
  for (var i = 0; i < 12; i++) {
    final x = -58 + i * 10.0;
    _line(c, Offset(x * .6, -106), Offset(x, -70 + (i % 3) * 2.0),
        const Color(0xFFD2BB80), 2);
  }
  if (abandoned) {
    _box(c, const Rect.fromLTWH(8, -50, 29, 37), const Color(0xFF8E805D));
    _line(c, const Offset(8, -45), const Offset(37, -25),
        const Color(0xFFB49B6D), 3);
  }
}

void _cluster(Canvas c, int kind) {
  if (kind < 4) {
    c.drawOval(const Rect.fromLTWH(-145, -25, 290, 55),
        Paint()..color = const Color(0x2292955F));
  }
  switch (kind) {
    case 0:
      // Trellis and vegetables sit beside the lane rather than across it.
      for (final x in [-115.0, -35.0]) {
        _line(c, Offset(x, 0), Offset(x, -92), const Color(0xFF9C8050), 5);
      }
      for (var i = 0; i < 7; i++) {
        _line(c, Offset(-127 + i * 16.0, -94), Offset(-127 + i * 16.0, -77),
            const Color(0xFFB59B64), 3);
      }
      for (var i = 0; i < 14; i++) {
        final p = Offset(-122 + (i % 7) * 15.0, -91 + (i ~/ 7) * 10.0);
        c.drawOval(
            Rect.fromCenter(center: p, width: 23, height: 13),
            Paint()
              ..color =
                  i.isEven ? const Color(0xFF769B5A) : const Color(0xFF91AC68));
        if (i % 4 == 0) {
          _line(c, p, p + const Offset(0, 20), const Color(0xFF86A064), 2);
          c.drawOval(
              Rect.fromCenter(
                  center: p + const Offset(0, 25), width: 9, height: 17),
              Paint()..color = const Color(0xFFB4C57E));
        }
      }
      _jar(c, const Offset(-15, 0));
      _jar(c, const Offset(12, 6));
      // Bicycle leaning near the garden.
      for (final x in [69.0, 117.0]) {
        c.drawCircle(
            Offset(x, -9),
            18,
            Paint()
              ..color = const Color(0xFF6D755F)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3);
      }
      final frame = Path()
        ..moveTo(69, -9)
        ..lineTo(84, -40)
        ..lineTo(97, -9)
        ..lineTo(69, -9)
        ..moveTo(84, -40)
        ..lineTo(108, -39)
        ..lineTo(97, -9)
        ..moveTo(108, -39)
        ..lineTo(117, -9);
      c.drawPath(
          frame,
          Paint()
            ..color = const Color(0xFF6A9F98)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3);
      _line(c, const Offset(78, -42), const Offset(90, -42),
          const Color(0xFF75624B), 4);
      _line(c, const Offset(107, -39), const Offset(109, -52),
          const Color(0xFF647563), 3);
      _line(c, const Offset(109, -52), const Offset(118, -52),
          const Color(0xFF647563), 3);
      _net(c, const Offset(-125, 28), 65, 36);
      for (final x in [38.0, 146.0]) {
        _line(c, Offset(x, -75), Offset(x, -147), const Color(0xFF8F8057), 4);
      }
    case 1:
      _shelter(c);
      _jar(c, const Offset(65, 0));
      // Narrow plank bridge across a dry drainage furrow.
      _box(c, const Rect.fromLTWH(-145, 13, 90, 20), const Color(0xFF8C9D7A));
      for (var i = 0; i < 8; i++) {
        _box(c, Rect.fromLTWH(-138 + i * 10.0, 6, 8, 33),
            i.isEven ? const Color(0xFFC6AC77) : const Color(0xFFB39A68));
      }
      for (var i = 0; i < 5; i++) {
        final x = 90 + i * 9.0;
        _line(c, Offset(x, 4), Offset(x - 8, -95 - (i % 3) * 15),
            const Color(0xFF6E945F), 4);
        for (var j = 0; j < 4; j++) {
          c.drawOval(
              Rect.fromCenter(
                  center: Offset(x - 8, -20 - j * 21.0), width: 26, height: 7),
              Paint()..color = const Color(0xFF84A56E));
        }
      }
      _box(c, const Rect.fromLTWH(-12, -18, 38, 10), const Color(0xFF92764E));
    case 2:
      _shelter(c);
      _net(c, const Offset(65, 5), 75, 77);
      for (var i = 0; i < 3; i++) {
        final x = -123 + i * 28.0;
        _box(c, Rect.fromLTWH(x, -9 - i % 2 * 12.0, 24, 25),
            const Color(0xFFB18C5D));
        _line(
            c, Offset(x + 2, 0), Offset(x + 22, 0), const Color(0xFFDBC08E), 2);
      }
      final hull = Path()
        ..moveTo(-134, -43)
        ..quadraticBezierTo(-95, -93, -50, -43)
        ..lineTo(-55, -30)
        ..lineTo(-130, -30)
        ..close();
      c.drawPath(hull, Paint()..color = const Color(0xFF8C9E97));
      for (var i = 0; i < 6; i++) {
        _line(c, Offset(-124 + i * 12.0, -36), Offset(-118 + i * 10.0, -52),
            const Color(0xFFC0C5A6), 2);
      }
      for (var i = 0; i < 3; i++) {
        c.drawCircle(
            Offset(68 + i * 24.0, 18),
            9,
            Paint()
              ..color =
                  i.isEven ? const Color(0xFFB98163) : const Color(0xFFD1BC87));
        c.drawCircle(Offset(68 + i * 24.0, 18), 4,
            Paint()..color = const Color(0xFF8F9D80));
      }
    case 4:
    case 5:
      break;
    case 3:
      _shelter(c, abandoned: true);
      _jar(c, const Offset(-70, 3));
      for (var i = 0; i < 12; i++) {
        final p = Offset(75 + (i % 4) * 13.0, (i ~/ 4) * 8 - 18.0);
        c.drawOval(
            Rect.fromCenter(center: p, width: 27, height: 16),
            Paint()
              ..color =
                  i.isEven ? const Color(0xFF88A267) : const Color(0xFF9BB67B));
        if (i % 3 == 0) {
          c.drawCircle(p - const Offset(0, 5), 3,
              Paint()..color = const Color(0xFFEAC0A0));
        }
      }
      _line(c, const Offset(-40, 22), const Offset(16, 32),
          const Color(0xFFB6A078), 7);
  }
}

void _motion(Canvas c, int kind, double time, double seed) {
  if (kind == 0) {
    final sway = math.sin(time * 1.1 + seed) * 4;
    final line = Path()
      ..moveTo(38, -142)
      ..quadraticBezierTo(95, -127, 146, -142);
    c.drawPath(
        line,
        Paint()
          ..color = const Color(0xFF96856A)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);
    for (var i = 0; i < 3; i++) {
      final x = 55 + i * 27.0;
      final y = -137.0 + (i == 1 ? 7 : 0);
      final cloth = Path()
        ..moveTo(x, y)
        ..lineTo(x + 20, y)
        ..lineTo(x + 20 + sway, y + 29)
        ..quadraticBezierTo(x + 9 + sway, y + 33, x + sway, y + 29)
        ..close();
      c.drawPath(
          cloth,
          Paint()
            ..color = [
              const Color(0xFFE4B3A0),
              const Color(0xFFDBD8B2),
              const Color(0xFF91B3AE)
            ][i]);
    }
  } else if (kind == 5) {
    for (var i = 0; i < 3; i++) {
      final t = (time * .14 + i / 3) % 1;
      c.drawOval(
          Rect.fromCenter(
              center: Offset(t * 22, -t * 42),
              width: 9 + t * 16,
              height: 7 + t * 10),
          Paint()..color = Color.fromRGBO(234, 235, 214, (1 - t) * .33));
    }
  } else if (kind == 4) {
    c.save();
    c.rotate(time * .35);
    c.drawCircle(
        Offset.zero,
        34,
        Paint()
          ..color = const Color(0xFF9C774E)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 7);
    c.drawCircle(
        Offset.zero,
        25,
        Paint()
          ..color = const Color(0xFFD1AF79)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
    for (var i = 0; i < 8; i++) {
      _line(c, Offset.zero, Offset.fromDirection(i * math.pi / 4, 33),
          const Color(0xFFBDA16C), 3);
    }
    c.drawCircle(Offset.zero, 6, Paint()..color = const Color(0xFF715A40));
    c.restore();
  } else if (kind == 1) {
    for (var i = 0; i < 5; i++) {
      final tip = Offset(
          90 + i * 9.0 + math.sin(time * .9 + i) * 4, -95 - (i % 3) * 15);
      _line(c, Offset(90 + i * 9.0, 4), tip, const Color(0xFF6E945F), 2);
      c.drawOval(
          Rect.fromCenter(
              center: tip + const Offset(5, 5), width: 25, height: 7),
          Paint()..color = const Color(0xFF96B57A));
    }
  } else if (kind == 2) {
    final sway = math.sin(time * .8 + seed) * 3;
    _line(c, const Offset(-10, -113), const Offset(-10, -149),
        const Color(0xFF8D805F), 2);
    c.drawPath(
        Path()
          ..moveTo(-10, -149)
          ..lineTo(16, -143 + sway)
          ..lineTo(-10, -133)
          ..close(),
        Paint()..color = const Color(0xFFD1A06B));
  }
}
