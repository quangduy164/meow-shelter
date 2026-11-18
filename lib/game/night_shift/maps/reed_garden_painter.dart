import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/painting.dart';
import '../static_layer.dart';
import '../../components/fish_item_component.dart';
import '../moonlight.dart';
import '../moonlight_art.dart';
import 'reed_garden.dart';

Rect _px(Rect r, Vector2 s) =>
    Rect.fromLTWH(r.left * s.x, r.top * s.y, r.width * s.x, r.height * s.y);

class ReedGardenBackground extends PositionComponent {
  ReedGardenBackground() : super(priority: -100);
  final _layer = StaticLayer();
  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size.setFrom(size);
    _layer.clear();
  }

  @override
  void onRemove() {
    _layer.clear();
    super.onRemove();
  }

  @override
  void render(Canvas canvas) {
    if (size.x <= 0 || size.y <= 0) return;
    _layer.draw(canvas, size.toSize(), (c) => _paint(c, size.toSize()));
  }

  void _paint(Canvas c, Size s) {
    c.drawRect(
        Offset.zero & s,
        Paint()
          ..shader = ui.Gradient.linear(
              Offset.zero,
              Offset(0, s.height),
              const [Color(0xFF1C344B), Color(0xFF365B50), Color(0xFF233F38)],
              const [0, .38, 1]));
    final pond = Path()
      ..moveTo(0, s.height * .78)
      ..cubicTo(s.width * .25, s.height * .68, s.width * .38, s.height * .92,
          s.width * .62, s.height * .82)
      ..cubicTo(s.width * .78, s.height * .76, s.width * .9, s.height * .9,
          s.width, s.height * .82)
      ..lineTo(s.width, s.height)
      ..lineTo(0, s.height)
      ..close();
    c.drawPath(pond, Paint()..color = const Color(0xFF1B4652));
    final path = Path()
      ..moveTo(s.width * .08, s.height * .26)
      ..cubicTo(s.width * .32, s.height * .54, s.width * .66, s.height * .48,
          s.width * .92, s.height * .62);
    c.drawPath(
        path,
        Paint()
          ..color = const Color(0x55BFAF7B)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 34
          ..strokeCap = StrokeCap.round);
    final grass = Paint()
      ..color = const Color(0x557EA171)
      ..strokeWidth = 1.4;
    for (var i = 0; i < 90; i++) {
      final x = (i * 37 % 100) / 100 * s.width;
      final y = s.height * (.24 + (i * 19 % 70) / 100);
      c.drawLine(Offset(x, y), Offset(x + 3, y - 9), grass);
    }
  }
}

class ReedMoon extends PositionComponent with HasGameReference {
  ReedMoon(this.moon) : super(priority: 84);
  final Moonlight moon;
  @override
  void render(Canvas canvas) => paintMoon(canvas, game.size.toSize(), moon);
}

class ReedTrailsComponent extends PositionComponent with HasGameReference {
  ReedTrailsComponent(this.garden) : super(priority: 89);
  final ReedGarden garden;
  @override
  void render(Canvas canvas) {
    for (final trail in garden.trails) {
      final from = _px(trail.from.area, game.size).center;
      final to = _px(trail.to.area, game.size).center;
      final alpha = (trail.left / trail.total).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = Color.fromRGBO(255, 225, 135, .95 * alpha)
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round;
      final dir = to - from;
      final unit = dir / dir.distance;
      final normal = Offset(-unit.dy, unit.dx);
      canvas.drawLine(
          from,
          to,
          Paint()
            ..color = Color.fromRGBO(255, 225, 135, .22 * alpha)
            ..strokeWidth = 14
            ..strokeCap = StrokeCap.round);
      for (var i = 1; i < 5; i++) {
        final p = Offset.lerp(from, to, i / 5)! + normal * (i.isEven ? 6 : -6);
        canvas.drawOval(
            Rect.fromCenter(center: p, width: 13, height: 8), paint);
      }
      final tip = Offset.lerp(from, to, .82)!;
      canvas.drawLine(tip, tip - unit * 12 + normal * 6, paint);
      canvas.drawLine(tip, tip - unit * 12 - normal * 6, paint);
    }
  }
}

class ReedPatchComponent extends PositionComponent
    with HasGameReference, TapCallbacks {
  ReedPatchComponent(this.patch, {required this.onTapPatch})
      : super(priority: 88);
  final ReedPatch patch;
  final void Function(ReedPatch) onTapPatch;
  double _clock = 0;

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    final r = _px(patch.area, size);
    position = Vector2(r.left, r.top);
    this.size = Vector2(r.width, r.height);
  }

  @override
  void update(double dt) => _clock += dt;
  @override
  void onTapDown(TapDownEvent event) => onTapPatch(patch);

  @override
  void render(Canvas canvas) {
    final w = size.x, h = size.y;
    canvas.drawOval(Rect.fromLTWH(w * .05, h * .78, w * .9, h * .2),
        Paint()..color = const Color(0x77324B30));
    final shake = patch.shake > 0 ? math.sin(_clock * 36) * 7 * patch.shake : 0;
    for (var i = 0; i < 17; i++) {
      final x = w * (.08 + .84 * i / 16);
      final top = h * (.08 + (i * 7 % 5) * .035);
      final sway =
          math.sin(_clock * 1.7 + i) * 2 + shake * (i.isEven ? 1 : -.7);
      final stem = Paint()
        ..color = i.isEven ? const Color(0xFF8FA65B) : const Color(0xFF6F8D50)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(x, h * .94), Offset(x + sway, top), stem);
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset(x + sway, top + 7), width: 7, height: 18),
          Paint()..color = const Color(0xFFD8C27D));
    }
    if (patch.baited) {
      canvas.save();
      canvas.translate(w / 2, h * .72);
      canvas.scale(.62);
      drawFish(canvas, Offset.zero);
      canvas.restore();
    }
    if (patch.cool > 0) {
      canvas.drawArc(
          Rect.fromCircle(center: Offset(w / 2, h * .48), radius: 17),
          -math.pi / 2,
          math.pi * 2 * patch.cool / 1.5,
          false,
          Paint()
            ..color = const Color(0xCCFFF4DA)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3);
    }
  }
}

class ReedExitComponent extends PositionComponent with HasGameReference {
  ReedExitComponent(this.garden) : super(priority: 87);
  final ReedGarden garden;

  @override
  void render(Canvas canvas) {
    for (final exit in garden.exits) {
      final r = _px(exit.area, game.size);
      final left = exit.center.dx < .5;
      canvas.drawOval(
          Rect.fromCenter(
              center: r.center, width: r.width * 1.4, height: r.width * 1.4),
          Paint()..color = const Color(0x33FFE08A));
      final basket = RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: r.center, width: r.width * .9, height: r.width * .62),
          const Radius.circular(10));
      canvas.drawRRect(basket.shift(const Offset(0, 4)),
          Paint()..color = const Color(0x55000000));
      canvas.drawRRect(basket, Paint()..color = const Color(0xFFC28A51));
      canvas.drawRRect(
          basket,
          Paint()
            ..color = const Color(0xFF6A3E1E)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3);
      for (var x = basket.left + 8; x < basket.right; x += 9) {
        canvas.drawLine(Offset(x, basket.top + 3), Offset(x, basket.bottom - 3),
            Paint()..color = const Color(0x886A3E1E));
      }
      canvas.drawArc(
          Rect.fromCenter(
              center: basket.outerRect.topCenter,
              width: basket.width * .72,
              height: basket.height * .9),
          math.pi,
          math.pi,
          false,
          Paint()
            ..color = const Color(0xFF6A3E1E)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4);
      final arrow = Paint()
        ..color = const Color(0xFFFFE08A)
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round;
      final y = r.center.dy - r.width * .72;
      final from = Offset(left ? r.right + 8 : r.left - 8, y);
      final to = Offset(left ? r.left + 10 : r.right - 10, y);
      canvas.drawLine(from, to, arrow);
      canvas.drawLine(to, to + Offset(left ? 8 : -8, -6), arrow);
      canvas.drawLine(to, to + Offset(left ? 8 : -8, 6), arrow);
    }
  }
}
