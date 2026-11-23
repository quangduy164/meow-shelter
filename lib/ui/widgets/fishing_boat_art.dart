import 'package:flutter/painting.dart';

import '../../fishing/fishing_boat.dart';

// Origami paper boat, origin = boat point. The sail and the hull opening go
// under the cat; the folded hull face goes over it, so the cat sits inside.
// Notebook paper (faint blue lines, red margin) keeps it readable next to
// orange cats.

const _paper = Color(0xFFFBF6EA);
const _paperShade = Color(0xFFE6DCC6);
const _paperDark = Color(0xFFCDBFA3);
const _crease = Color(0xFF9E8B6E);
const _ink = Color(0x557FA6C9);

final _fill = Paint();
final _line = Paint()
  ..style = PaintingStyle.stroke
  ..strokeJoin = StrokeJoin.round
  ..strokeCap = StrokeCap.round;

/// Front face of the hull: wide top edge, narrower keel.
final _hull = Path()
  ..moveTo(-66, -4)
  ..lineTo(66, -4)
  ..lineTo(44, 22)
  ..lineTo(-44, 22)
  ..close();

/// Sits a little lower than the basket so more of the cat shows.
const _sink = Offset(0, 7);

void paintPaperBoatBack(Canvas c) {
  c.save();
  c.translate(_sink.dx, _sink.dy);
  // Shadow and waterline.
  c.drawOval(const Rect.fromLTWH(-62, 10, 124, 24),
      _fill..color = const Color(0x40345A5C));
  c.drawOval(
      const Rect.fromLTWH(-60, 9, 120, 20),
      _line
        ..color = const Color(0x88E9FFF7)
        ..strokeWidth = 2);
  // Sail: the tall centre fold, rising behind the cat.
  final left = Path()
    ..moveTo(-34, -4)
    ..lineTo(0, -82)
    ..lineTo(0, -4)
    ..close();
  final right = Path()
    ..moveTo(0, -82)
    ..lineTo(34, -4)
    ..lineTo(0, -4)
    ..close();
  c.drawPath(left, _fill..color = _paper);
  c.drawPath(right, _fill..color = _paperShade);
  _ruled(c, left, -78, -4);
  c.drawPath(
      Path()
        ..moveTo(-34, -4)
        ..lineTo(0, -82)
        ..lineTo(34, -4),
      _line
        ..color = _crease
        ..strokeWidth = 1.6);
  c.drawLine(
      const Offset(0, -80), const Offset(0, -6), _line..strokeWidth = 1.2);
  // Inside of the hull, seen over the near edge.
  c.drawPath(
      Path()
        ..moveTo(-66, -4)
        ..lineTo(-50, -14)
        ..lineTo(50, -14)
        ..lineTo(66, -4)
        ..close(),
      _fill..color = _paperDark);
  c.drawPath(
      Path()
        ..moveTo(-66, -4)
        ..lineTo(-50, -14)
        ..lineTo(50, -14)
        ..lineTo(66, -4),
      _line
        ..color = _crease
        ..strokeWidth = 1.4);
  c.restore();
}

void paintPaperBoatFront(Canvas c) {
  c.save();
  c.translate(_sink.dx, _sink.dy);
  c.drawPath(_hull, _fill..color = _paper);
  _ruled(c, _hull, 1, 22);
  // Red margin line, like a page torn from a notebook.
  c.drawLine(
      const Offset(-36, -3),
      const Offset(-27, 21),
      _line
        ..color = const Color(0x66E0705F)
        ..strokeWidth = 1.2);
  // Folded corner flaps at bow and stern.
  for (final s in [-1.0, 1.0]) {
    final flap = Path()
      ..moveTo(s * 66, -4)
      ..lineTo(s * 30, 9)
      ..lineTo(s * 44, 22)
      ..close();
    c.drawPath(flap, _fill..color = s < 0 ? _paperDark : _paperShade);
    c.drawPath(
        flap,
        _line
          ..color = _crease
          ..strokeWidth = 1.1);
  }
  // Centre crease and a soft water shade along the keel.
  c.drawLine(
      const Offset(0, -3),
      const Offset(0, 21),
      _line
        ..color = const Color(0x55A08C6E)
        ..strokeWidth = 1);
  c.drawLine(
      const Offset(-42, 19),
      const Offset(42, 19),
      _line
        ..color = const Color(0x3D4E8FA0)
        ..strokeWidth = 4);
  c.drawPath(
      _hull,
      _line
        ..color = _crease
        ..strokeWidth = 1.6);
  c.drawLine(
      const Offset(-64, -4),
      const Offset(64, -4),
      _line
        ..color = const Color(0xFFFFFFFF)
        ..strokeWidth = 1.2);
  c.restore();
}

/// Faint ruled lines inside [shape] between [top] and [bottom].
void _ruled(Canvas c, Path shape, double top, double bottom) {
  c.save();
  c.clipPath(shape);
  _line
    ..color = _ink
    ..strokeWidth = 1;
  for (var y = top + 6; y < bottom; y += 7) {
    c.drawLine(Offset(-70, y), Offset(70, y), _line);
  }
  c.restore();
}

/// Village boathouse, recorded into the cached landscape.
void paintBoatHouse(Canvas c) {
  final b = FishingBoatHouse.base;
  c.save();
  c.translate(b.dx, b.dy);
  // Ground shadow and a short plank ramp down toward the path.
  c.drawOval(const Rect.fromLTWH(-82, -6, 164, 22),
      _fill..color = const Color(0x334E5037));
  c.drawPath(
      Path()
        ..moveTo(-26, 0)
        ..lineTo(26, 0)
        ..lineTo(32, 12)
        ..lineTo(-32, 12)
        ..close(),
      _fill..color = const Color(0xFFB08A5A));
  // Plank walls with a darker side.
  c.drawRect(const Rect.fromLTWH(-64, -66, 128, 66),
      _fill..color = const Color(0xFFC0915C));
  c.drawRect(const Rect.fromLTWH(34, -66, 30, 66),
      _fill..color = const Color(0xFFA27646));
  _line
    ..color = const Color(0x55704B28)
    ..strokeWidth = 1.4;
  for (var x = -56.0; x < 64; x += 12) {
    c.drawLine(Offset(x, -64), Offset(x, -2), _line);
  }
  // Wide open doorway with both boats waiting inside.
  c.drawRRect(
      RRect.fromRectAndCorners(const Rect.fromLTWH(-40, -50, 64, 50),
          topLeft: const Radius.circular(6),
          topRight: const Radius.circular(6)),
      _fill..color = const Color(0xFF4A3727));
  c.save();
  c.translate(-22, -12);
  c.scale(.22);
  paintPaperBoatBack(c);
  paintPaperBoatFront(c);
  c.restore();
  c.drawOval(const Rect.fromLTWH(-4, -16, 26, 10),
      _fill..color = const Color(0xFF3B2C21));
  c.drawOval(const Rect.fromLTWH(-4, -20, 26, 9),
      _fill..color = const Color(0xFFD9B26F));
  c.drawRRect(
      RRect.fromRectAndCorners(const Rect.fromLTWH(-40, -50, 64, 50),
          topLeft: const Radius.circular(6),
          topRight: const Radius.circular(6)),
      _line
        ..color = const Color(0xFF6E4A2A)
        ..strokeWidth = 3);
  // Teal roof so the boathouse stands out from the brown cottages.
  final roof = Path()
    ..moveTo(-78, -62)
    ..lineTo(-50, -104)
    ..lineTo(46, -104)
    ..lineTo(78, -62)
    ..close();
  c.drawPath(roof, _fill..color = const Color(0xFF4F8E93));
  _line
    ..color = const Color(0x5590D2CF)
    ..strokeWidth = 2;
  for (var y = -96.0; y < -64; y += 8) {
    final t = (y + 104) / 42;
    c.drawLine(Offset(-50 - 28 * t, y), Offset(46 + 32 * t, y), _line);
  }
  c.drawPath(
      roof,
      _line
        ..color = const Color(0xFF2F5E63)
        ..strokeWidth = 3);
  // Sign over the door: a little boat on a wooden board.
  c.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(-30, -80, 44, 22), const Radius.circular(4)),
      _fill..color = const Color(0xFFF2DDAE));
  c.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(-30, -80, 44, 22), const Radius.circular(4)),
      _line
        ..color = const Color(0xFF7A5533)
        ..strokeWidth = 2);
  c.drawPath(
      Path()
        ..moveTo(-20, -70)
        ..lineTo(4, -70)
        ..lineTo(-1, -63)
        ..lineTo(-15, -63)
        ..close(),
      _fill..color = const Color(0xFF6E4A2A));
  c.drawPath(
      Path()
        ..moveTo(-8, -77)
        ..lineTo(-8, -71)
        ..lineTo(-2, -71)
        ..close(),
      _fill);
  c.restore();
}
