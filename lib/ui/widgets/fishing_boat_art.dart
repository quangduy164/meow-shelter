import 'package:flutter/painting.dart';

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
