import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import 'return_home_road.dart';

/// A shallow stream cutting across the lane. Paws must stay on a stone; water
/// costs one heart and sends the cat back to the near bank.
///
/// The stones drift up and down the lane, each at its own pace, so the dry
/// path only opens when two neighbours line up. The cat has to wait on a stone
/// (which carries it along) and hop across at the right moment.
class ReturnHomeCrossing extends PositionComponent {
  ReturnHomeCrossing({required this.road, required this.centerFraction})
      : super(priority: 1) {
    _stones = List.generate(_lanes.length, (_) => Offset.zero);
    _previous = List.generate(_lanes.length, (_) => Offset.zero);
    _layout();
    _previous.setAll(0, _stones);
  }

  final ReturnHomeRoad road;
  final double centerFraction;
  static const double crossingWidth = 240;

  /// Stone x offset from the crossing center (px), swing speed (rad/s) and
  /// phase. Neighbours are 58 px apart: touching when level, a gap when they
  /// drift too far apart vertically. The outer stones reach past the banks.
  static const _lanes = [
    (x: -87.0, speed: 1.4, phase: 0.0),
    (x: -29.0, speed: 2.0, phase: 2.3),
    (x: 29.0, speed: 1.6, phase: 4.4),
    (x: 87.0, speed: 1.15, phase: 1.1),
  ];

  /// Share of the lane half-width a stone swings to either side.
  static const double swing = .7;

  late final List<Offset> _stones;
  late final List<Offset> _previous;
  double _time = 0;

  double get centerX => road.worldWidth * centerFraction;
  double get left => centerX - crossingWidth / 2;
  double get right => centerX + crossingWidth / 2;
  double get safeBankX => left - 105;

  /// How far a bank bulges into the water at lane depth [v] (-1 top edge,
  /// 1 bottom edge). Only ever inward, so the outer stones always reach dry
  /// ground; the wobble keeps the water from reading as a rectangle.
  double _bankInset(double v, double side) {
    final seed = centerFraction * 53 + side * 1.7;
    final wobble = 13 + 11 * sin(v * 2.3 + seed) + 6 * sin(v * 5.7 + seed * 2);
    if (v < -1) {
      // Above the lane: taper into a narrow, rounded spring head.
      final t = min(1.0, (-1 - v) / .45);
      return max(0.0, wobble) + 78 * t * t;
    }
    if (v > 1) {
      // Below the lane: fan out into the roadside stream.
      final t = min(1.0, (v - 1) / .75);
      return max(0.0, wobble) * (1 - t) - 46 * t * t;
    }
    return max(0.0, wobble);
  }

  double _depthAt(Offset p) =>
      (p.dy - road.centerY(centerX)) / road.halfWidth(centerX);

  double _leftBank(double v) => left + _bankInset(v, -1);
  double _rightBank(double v) => right - _bankInset(v, 1);

  Iterable<Offset> get stones => _stones;

  void _layout() {
    // Each crossing gets its own rhythm.
    final offset = centerFraction * 37;
    for (var i = 0; i < _lanes.length; i++) {
      final lane = _lanes[i];
      final x = centerX + lane.x;
      final y = road.centerY(x) +
          sin(_time * lane.speed + lane.phase + offset) *
              road.halfWidth(x) *
              swing;
      _stones[i] = Offset(x, y);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _previous.setAll(0, _stones);
    _time += dt;
    _layout();
  }

  /// Drawn stone is a 60x40 ellipse; landing uses the same ellipse plus a
  /// small grace margin so what looks dry is dry.
  static const double stoneRx = 30 + 6;
  static const double stoneRy = 20 + 6;

  static bool _inside(Offset s, Offset p) {
    final dx = (p.dx - s.dx) / stoneRx;
    final dy = (p.dy - s.dy) / stoneRy;
    return dx * dx + dy * dy <= 1;
  }

  bool _onStone(Offset p) => _stones.any((s) => _inside(s, p));

  /// Water surface at a point: inside the crossing, on the lane, off stones.
  bool isWater(Offset p) {
    final v = _depthAt(p);
    if (p.dx < _leftBank(v) || p.dx > _rightBank(v)) return false;
    if (p.dy < road.topEdge(p.dx) || p.dy > road.bottomEdge(p.dx)) return false;
    return !_onStone(p);
  }

  static List<Offset> _paws(Rect catBox) {
    final y = catBox.bottom - 4;
    return [catBox.left + 6, catBox.center.dx, catBox.right - 6]
        .map((x) => Offset(x, y))
        .toList(growable: false);
  }

  /// The cat falls only if its whole paw line is over water: one paw on a
  /// stone is enough to stand.
  bool inWater(Rect catBox) => _paws(catBox).every(isWater);

  /// Vertical distance the stone under the cat moved this frame, or 0 when
  /// the cat is not standing on one. With paws on two stones the one holding
  /// more paws wins, the middle paw breaking a tie.
  double carryDy(Rect catBox) {
    final paws = _paws(catBox);
    var best = -1;
    var bestScore = 0;
    for (var i = 0; i < _stones.length; i++) {
      var score = 0;
      for (var p = 0; p < paws.length; p++) {
        if (_inside(_previous[i], paws[p])) score += p == 1 ? 3 : 2;
      }
      if (score > bestScore) {
        bestScore = score;
        best = i;
      }
    }
    return best < 0 ? 0 : _stones[best].dy - _previous[best].dy;
  }

  /// Water outline: wavy banks across the lane, spilling past both lane
  /// edges so it joins the stream running along the bottom of the road.
  Path _waterPath() {
    final cy = road.centerY(centerX);
    final hw = road.halfWidth(centerX);
    const top = -1.45, bottom = 1.75, steps = 28;
    Offset at(double v, double side) =>
        Offset(side < 0 ? _leftBank(v) : _rightBank(v), cy + v * hw);
    final path = Path();
    for (var i = 0; i <= steps; i++) {
      final p = at(top + (bottom - top) * i / steps, -1);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    // Bottom: widen into the roadside stream.
    final bl = at(bottom, -1), br = at(bottom, 1);
    path.quadraticBezierTo(centerX, bl.dy + 26, br.dx, br.dy);
    for (var i = steps; i >= 0; i--) {
      final p = at(top + (bottom - top) * i / steps, 1);
      path.lineTo(p.dx, p.dy);
    }
    // Top: a rounded spring head in the grass.
    final tl = at(top, -1);
    path.quadraticBezierTo(centerX, tl.dy - 22, tl.dx, tl.dy);
    path.close();
    return path;
  }

  @override
  void render(Canvas canvas) {
    final water = _waterPath();
    final bounds = water.getBounds();
    // Sandy, pebbly bank under the water edge.
    canvas.drawPath(
        water,
        Paint()
          ..color = const Color(0xFFCDB98A)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 14
          ..strokeJoin = StrokeJoin.round);
    final pebble = Paint()..color = const Color(0xFFA9A28C);
    for (final metric in water.computeMetrics()) {
      for (var d = 9.0; d < metric.length; d += 23) {
        final t = metric.getTangentForOffset(d);
        if (t == null) continue;
        canvas.drawCircle(t.position, 2.2 + (d % 3), pebble);
      }
    }
    canvas.drawPath(
        water,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF7CC7DB), Color(0xFF4FA6C4)],
          ).createShader(bounds));
    // Shallow rim.
    canvas.drawPath(
        water,
        Paint()
          ..color = const Color(0x99D7F5F2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4);
    // Current: dashes drifting down toward the roadside stream.
    canvas.save();
    canvas.clipPath(water);
    final ripple = Paint()
      ..color = const Color(0x77EFFFFF)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final span = bounds.height;
    for (var i = 0; i < 14; i++) {
      final x = bounds.left + 14 + (i * 37) % (bounds.width - 28);
      final y = bounds.top + ((i * 53 + _time * 26) % span);
      canvas.drawLine(Offset(x - 8, y), Offset(x + 8, y + 2), ripple);
    }
    canvas.restore();

    final wake = Paint()
      ..color = const Color(0xAAEFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < _stones.length; i++) {
      final stone = _stones[i];
      // Ripples on the leading side show which way the stone is drifting.
      final dir = (stone.dy - _previous[i].dy).sign;
      if (dir != 0) {
        canvas.drawArc(
            Rect.fromCenter(
                center: stone + Offset(0, dir * 16), width: 70, height: 26),
            dir > 0 ? .25 : pi + .25,
            pi - .5,
            false,
            wake);
      }
      canvas.drawOval(
          Rect.fromCenter(
              center: stone + const Offset(0, 8), width: 62, height: 20),
          Paint()..color = const Color(0x44406270));
      canvas.drawOval(Rect.fromCenter(center: stone, width: 60, height: 40),
          Paint()..color = const Color(0xFF8D9690));
      canvas.drawOval(
          Rect.fromCenter(
              center: stone + const Offset(-7, -5), width: 25, height: 11),
          Paint()..color = const Color(0xFFC1C7BE));
    }
  }
}
