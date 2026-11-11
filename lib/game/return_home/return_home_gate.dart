import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/painting.dart';
import 'return_home_game.dart';

/// Gate ground geometry follows the lane; the near half renders over the cat.
class ReturnHomeGate extends Component with HasGameReference<ReturnHomeGame> {
  ReturnHomeGate() : super(priority: 3);

  late final Component foreground = _GateForeground(this);
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

  Offset _foot(bool near) {
    final road = game.road;
    final x = road.gateCenterX;
    final y = near ? road.bottomEdge(x) + 6 : road.topEdge(x) - 6;
    return Offset(road.gateXAt(y), y);
  }

  void _polygon(Canvas canvas, List<Offset> points, Color color) {
    final path = Path()..addPolygon(points, true);
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(
        path,
        Paint()
          ..color = _ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..strokeJoin = StrokeJoin.round);
  }

  void _beam(Canvas canvas, Offset a, Offset b, double width, Color color) {
    canvas.drawLine(
        a,
        b,
        Paint()
          ..color = _ink
          ..strokeWidth = width + 2
          ..strokeCap = StrokeCap.round);
    canvas.drawLine(
        a,
        b,
        Paint()
          ..color = color
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round);
  }

  void _paw(Canvas canvas, Offset c, double r, Color color) {
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(pi / 2);
    final paint = Paint()..color = color;
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(0, r * .3), width: r * 1.1, height: r * .85),
        paint);
    for (final p in const [
      Offset(-.65, -.35),
      Offset(-.23, -.7),
      Offset(.23, -.7),
      Offset(.65, -.35)
    ]) {
      canvas.drawOval(
          Rect.fromCenter(center: p * r, width: r * .4, height: r * .5), paint);
    }
    canvas.restore();
  }

  @override
  void render(Canvas canvas) {
    final far = _foot(false);
    final near = _foot(true);
    // An oblique threshold on the ground, not a front-facing doorway.
    final paving = Path()
      ..addPolygon([
        far + const Offset(-55, 0),
        far + const Offset(74, 0),
        near + const Offset(74, 0),
        near + const Offset(-55, 0),
      ], true);
    canvas.drawPath(paving, Paint()..color = const Color(0x45E7D8B4));
    canvas.save();
    canvas.clipPath(paving);
    final joints = Paint()
      ..color = const Color(0x558F9274)
      ..strokeWidth = 1;
    for (var i = -2; i < 4; i++) {
      final shift = Offset(i * 27.0, 0);
      canvas.drawLine(far + shift, near + shift, joints);
    }
    for (var y = far.dy + 23; y < near.dy; y += 23) {
      final x = game.road.gateXAt(y);
      canvas.drawLine(Offset(x - 60, y), Offset(x + 80, y), joints);
    }
    canvas.restore();
    _beam(canvas, far, near, 3, const Color(0xFFD4C092));
    if (_open > .05) {
      final road = game.road;
      for (var i = 0; i < 5; i++) {
        final x = road.gateCenterX - 86 + i * 25;
        final y = road.centerY(x) + (i.isEven ? -7 : 7);
        final alpha = (_open * (.6 + .25 * sin(_time * 3 - i))).clamp(0.0, 1.0);
        _paw(canvas, Offset(x, y), 6,
            Color.fromARGB((255 * alpha).round(), 255, 245, 172));
      }
    }
    _fence(canvas, far, false);
    _leaf(canvas, far, near, false);
    _post(canvas, far, false);
    _flowers(canvas, far + const Offset(13, -8));
  }

  void renderForeground(Canvas canvas) {
    final far = _foot(false), near = _foot(true);
    _fence(canvas, near, true);
    _leaf(canvas, far, near, true);
    _post(canvas, near, true);
    _flowers(canvas, near + const Offset(-14, 10));
    if (game.finished && _celebration < 3) {
      final center = Offset(
          game.road.gateCenterX, game.road.centerY(game.road.gateCenterX));
      for (var i = 0; i < 22; i++) {
        final age = (_celebration + i * .07) % 1.6;
        final c = center +
            Offset((i % 2 == 0 ? -1 : 1) * (12 + i * 2.0) * age,
                -30 - age * 100 + age * age * 80);
        canvas.save();
        canvas.translate(c.dx, c.dy);
        canvas.rotate(age * 4 + i);
        canvas.drawRect(
            const Rect.fromLTWH(-2, -4, 4, 8),
            Paint()
              ..color = const [
                Color(0xFFFFC24D),
                Color(0xFFF194A6),
                Color(0xFF85C8BD)
              ][i % 3]);
        canvas.restore();
      }
    }
  }

  void _leaf(Canvas canvas, Offset far, Offset near, bool front) {
    final hinge = front ? near : far;
    final span = (near.dy - far.dy) / 2 - 3;
    final angle = _open * pi * .48;
    final dy = (front ? -1 : 1) * cos(angle) * span;
    final dx = sin(angle) * span * .82 - dy * 28 / (near.dy - far.dy);
    final end = hinge + Offset(dx, dy);
    final height = front ? 43.0 : 40.0;
    final bottom = const Offset(0, -7), top = Offset(0, -height);
    // Ground shadows swing with the leaves as they open into the camp (+X).
    canvas.drawPath(
        Path()
          ..addPolygon([
            hinge,
            end,
            end + const Offset(16, 9),
            hinge + const Offset(16, 9)
          ], true),
        Paint()..color = const Color(0x253E402A));
    _polygon(canvas, [hinge + bottom, end + bottom, end + top, hinge + top],
        front ? const Color(0xFF7EAF87) : const Color(0xFF6C9978));
    _polygon(
        canvas,
        [
          hinge + top,
          end + top,
          end + top + const Offset(3, -3),
          hinge + top + const Offset(3, -3)
        ],
        const Color(0xFFADD0A2));
    for (var i = 1; i < 6; i++) {
      final p = Offset.lerp(hinge, end, i / 6)!;
      canvas.drawLine(
          p + bottom,
          p + top,
          Paint()
            ..color = const Color(0xAA48714E)
            ..strokeWidth = 1.5);
    }
    _beam(canvas, hinge + const Offset(0, -13), end + Offset(0, -height + 7), 2,
        const Color(0xFFB5D3A8));
    final handle = Offset.lerp(hinge, end, .88)! + const Offset(0, -20);
    canvas.drawCircle(handle, 2.2, Paint()..color = const Color(0xFFFFD37B));
  }

  void _post(Canvas canvas, Offset foot, bool near) {
    final h = near ? 65.0 : 59.0;
    canvas.drawOval(
        Rect.fromCenter(
            center: foot + const Offset(9, 5), width: 32, height: 11),
        Paint()..color = const Color(0x33402D22));
    _polygon(
        canvas,
        [
          foot + const Offset(-6, 0),
          foot + const Offset(5, 0),
          foot + Offset(5, -h),
          foot + Offset(-6, -h)
        ],
        const Color(0xFFC38F5C));
    _polygon(
        canvas,
        [
          foot + const Offset(5, 0),
          foot + const Offset(11, -5),
          foot + Offset(11, -h - 5),
          foot + Offset(5, -h)
        ],
        const Color(0xFF94623F));
    _polygon(
        canvas,
        [
          foot + Offset(-6, -h),
          foot + Offset(5, -h),
          foot + Offset(11, -h - 5),
          foot + Offset(0, -h - 5)
        ],
        const Color(0xFFF1CB87));
    canvas.drawLine(
        foot + const Offset(-2, -8),
        foot + Offset(-2, -h + 6),
        Paint()
          ..color = const Color(0xFFE9B77B)
          ..strokeWidth = 1.5);
    final lamp = foot + Offset(-2, -h - 14);
    canvas.drawCircle(
        lamp,
        14,
        Paint()
          ..shader = const RadialGradient(
                  colors: [Color(0x88FFD764), Color(0x00FFD764)])
              .createShader(Rect.fromCircle(center: lamp, radius: 14)));
    final light = RRect.fromRectAndRadius(
        Rect.fromCenter(center: lamp, width: 12, height: 16),
        const Radius.circular(3));
    canvas.drawRRect(light, Paint()..color = const Color(0xFFFFDD82));
    canvas.drawRRect(
        light,
        Paint()
          ..color = _ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);
    _beam(canvas, lamp + const Offset(-7, -9), lamp + const Offset(7, -9), 3,
        const Color(0xFF5F8F72));
  }

  void _fence(Canvas canvas, Offset foot, bool near) {
    final dir = near ? const Offset(-18, 43) : const Offset(18, -43);
    final end = foot + dir;
    for (final h in [13.0, 29.0]) {
      _beam(canvas, foot - Offset(0, h), end - Offset(0, h), 4,
          const Color(0xFFE0BA7D));
    }
    for (var i = 1; i <= 3; i++) {
      final p = foot + dir * (i / 3);
      _beam(canvas, p, p - const Offset(0, 38), 5, const Color(0xFFF2D49A));
    }
  }

  void _flowers(Canvas canvas, Offset c) {
    _polygon(
        canvas,
        [
          c + const Offset(-8, -10),
          c + const Offset(10, -10),
          c + const Offset(7, 4),
          c + const Offset(-5, 4)
        ],
        const Color(0xFFBD7658));
    for (var i = 0; i < 3; i++) {
      final p = c + Offset((i - 1) * 6, -17 - (i % 2) * 6);
      canvas.drawLine(
          c,
          p,
          Paint()
            ..color = const Color(0xFF50864B)
            ..strokeWidth = 2);
      for (var j = 0; j < 5; j++) {
        final a = j * pi * 2 / 5;
        canvas.drawCircle(p + Offset(cos(a), sin(a)) * 3, 3,
            Paint()..color = const Color(0xFFF6A1A7));
      }
      canvas.drawCircle(p, 2, Paint()..color = const Color(0xFFFFE68A));
    }
  }
}

class _GateForeground extends Component {
  _GateForeground(this.gate) : super(priority: 7);
  final ReturnHomeGate gate;

  @override
  void render(Canvas canvas) => gate.renderForeground(canvas);
}
