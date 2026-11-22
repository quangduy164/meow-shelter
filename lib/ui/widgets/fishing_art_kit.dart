import 'dart:math' as math;
import 'package:flutter/painting.dart';

/// Small helpers shared by the cached fishing scenery painters.

/// Deterministic 0..1 noise: the same (i, salt) always gives the same value,
/// so recorded chunks look identical every run.
double artNoise(int i, int salt) {
  final v = math.sin(i * 12.9898 + salt * 78.233) * 43758.5453;
  return v - v.floorToDouble();
}

Paint fillPaint(int color) => Paint()..color = Color(color);

Paint strokePaint(int color, double width) => Paint()
  ..color = Color(color)
  ..style = PaintingStyle.stroke
  ..strokeWidth = width
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round;

/// Closed strip between two curves across [from, to], sampled every 8 units.
Path bankBand(double from, double to, double Function(double) upper,
    double Function(double) lower) {
  final p = Path()..moveTo(from, upper(from));
  for (var x = from + 8; x < to; x += 8) {
    p.lineTo(x, upper(x));
  }
  p.lineTo(to, upper(to));
  p.lineTo(to, lower(to));
  for (var x = to - 8; x > from; x -= 8) {
    p.lineTo(x, lower(x));
  }
  return p
    ..lineTo(from, lower(from))
    ..close();
}
