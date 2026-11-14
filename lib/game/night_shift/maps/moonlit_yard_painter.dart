import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/painting.dart';
import '../../components/cat_component.dart';
import '../../../fishing/fishing_lighting.dart';
import 'moonlit_yard.dart';
import '../moonlight_art.dart';

/// Night backyard scene: wooden fence, dark lawn, stepping stones, bushes
/// and a porch along the bottom. Recorded once per size.
class MoonlitYardBackground extends PositionComponent {
  MoonlitYardBackground() : super(priority: -100);
  ui.Picture? _picture;

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size.setFrom(size);
    _picture?.dispose();
    _picture = null;
  }

  @override
  void onRemove() {
    _picture?.dispose();
    super.onRemove();
  }

  @override
  void render(Canvas canvas) {
    if (size.x <= 0 || size.y <= 0) return;
    if (_picture == null) {
      final recorder = ui.PictureRecorder();
      _paint(Canvas(recorder), size.x, size.y);
      _picture = recorder.endRecording();
    }
    canvas.drawPicture(_picture!);
  }

  static void _paint(Canvas canvas, double w, double h) {
    final random = math.Random(7);
    final lighting = FishingLighting(DateTime(2000, 1, 1, 22));
    // Use the same sky and terrain lighting as a night at the fishing lake.
    // Sky strip with stars.
    final sky = Rect.fromLTWH(0, 0, w, h * .12);
    canvas.drawRect(
        sky,
        Paint()
          ..shader = ui.Gradient.linear(sky.topCenter, sky.bottomCenter,
              [lighting.skyTop, lighting.skyBottom]));
    for (var i = 0; i < 30; i++) {
      canvas.drawCircle(
          Offset(random.nextDouble() * w, random.nextDouble() * h * .1),
          random.nextDouble() * 1.2 + .4,
          Paint()..color = const Color(0xCCFFF6D8));
    }
    canvas.saveLayer(Offset.zero & Size(w, h),
        Paint()..colorFilter = lighting.terrainFilter);
    // Lawn.
    final lawn = Rect.fromLTWH(0, h * .1, w, h * .9);
    canvas.drawRect(
        lawn,
        Paint()
          ..shader = ui.Gradient.linear(lawn.topCenter, lawn.bottomCenter,
              const [Color(0xFF99BC80), Color(0xFF7CA665)]));
    // Mown stripes.
    for (var x = 0.0; x < w; x += 70) {
      canvas.drawRect(Rect.fromLTWH(x, h * .16, 35, h * .66),
          Paint()..color = const Color(0x0DFFFFFF));
    }
    // Fence.
    final plank = Paint()..color = const Color(0xFFC0A078);
    final dark = Paint()..color = const Color(0xFF9B7C59);
    canvas.drawRect(Rect.fromLTWH(0, h * .075, w, h * .012), dark);
    canvas.drawRect(Rect.fromLTWH(0, h * .13, w, h * .012), dark);
    for (var x = 4.0; x < w; x += 26) {
      canvas.drawPath(
          Path()
            ..moveTo(x, h * .17)
            ..lineTo(x, h * .06)
            ..lineTo(x + 10, h * .045)
            ..lineTo(x + 20, h * .06)
            ..lineTo(x + 20, h * .17)
            ..close(),
          plank);
      canvas.drawLine(
          Offset(x + 10, h * .055),
          Offset(x + 10, h * .17),
          Paint()
            ..color = const Color(0x33000000)
            ..strokeWidth = 1);
    }
    canvas.drawRect(Rect.fromLTWH(0, h * .165, w, h * .012),
        Paint()..color = const Color(0x55000000));
    // Stepping stones winding across the yard.
    final stone = Paint()..color = const Color(0xFF6E736A);
    final stoneShade = Paint()..color = const Color(0xFF4D514B);
    for (var i = 0; i < 9; i++) {
      final t = i / 8;
      final c = Offset(
          w * (.08 + .84 * t), h * (.5 + .16 * math.sin(t * math.pi * 2.2)));
      final r = Rect.fromCenter(center: c, width: 34, height: 18);
      canvas.drawOval(r.shift(const Offset(0, 3)), stoneShade);
      canvas.drawOval(r, stone);
    }
    // Grass tufts and tiny flowers.
    final tuft = Paint()
      ..color = const Color(0xFFA7C88D)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 60; i++) {
      final p =
          Offset(random.nextDouble() * w, h * (.2 + random.nextDouble() * .6));
      for (final dx in const [-3.0, 0.0, 3.0]) {
        canvas.drawLine(p, p + Offset(dx, -6 - dx.abs()), tuft);
      }
      if (i % 5 == 0) {
        canvas.drawCircle(p + const Offset(0, -9), 2.2,
            Paint()..color = const Color(0xFFE8D7F0));
      }
    }
    // Bushes on the sides.
    final bush = Paint()..color = const Color(0xFF50764A);
    final bushLight = Paint()..color = const Color(0xFF699858);
    for (final (x, y, r) in [
      (0.0, .78, 46.0),
      (.04, .9, 40.0),
      (1.0, .78, 46.0),
      (.96, .9, 40.0),
    ]) {
      canvas.drawCircle(Offset(w * x, h * y), r, bush);
      canvas.drawCircle(Offset(w * x - 8, h * y - 10), r * .6, bushLight);
    }
    // Porch boards along the bottom.
    final porch = Rect.fromLTWH(0, h * .86, w, h * .14);
    canvas.drawRect(porch, Paint()..color = const Color(0xFFBE986E));
    final seam = Paint()
      ..color = const Color(0xFF926F4C)
      ..strokeWidth = 1.5;
    for (var y = porch.top; y < h; y += 14) {
      canvas.drawLine(Offset(0, y), Offset(w, y), seam);
    }
    canvas.drawRect(Rect.fromLTWH(0, porch.top - 4, w, 5),
        Paint()..color = const Color(0xFFD1B18A));
    canvas.restore();
  }
}

/// Warm light is painted on the lawn, below beds and cats, so a lit lamp
/// remains visibly different even when the night scenery is already bright.
class LanternLightComponent extends PositionComponent with HasGameRef {
  LanternLightComponent(this.yard) : super(priority: -20);
  final MoonlitYard yard;

  @override
  void render(Canvas canvas) {
    final screen = gameRef.size.toSize();
    for (final lantern in yard.lanterns) {
      if (!lantern.lit && lantern.ember <= 0) continue;
      final radius = yard.lanternRadius(screen) * (lantern.lit ? 1 : .75);
      final center = lantern.lamp(screen);
      final strength = lantern.lit
          ? (lantern.burn / 2).clamp(.6, 1.0)
          : .5 * (lantern.ember / 2).clamp(.2, 1.0);
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = ui.Gradient.radial(center, radius, [
            const Color(0xFFFFD57A).withOpacity(.48 * strength),
            const Color(0xFFFFD57A).withOpacity(.30 * strength),
            const Color(0xFFFFD57A).withOpacity(0),
          ], const [
            0,
            .65,
            1
          ]),
      );
      canvas.drawCircle(
        center,
        radius * .85,
        Paint()
          ..color = const Color(0xFFFFDF99).withOpacity(.4 * strength)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }
}

/// Drawn over the darkness: the moon in the sky with passing clouds, and a
/// green ring on every ready cat standing in the light (calm, slow timer).
class MoonlitYardOverlay extends PositionComponent with HasGameRef {
  MoonlitYardOverlay({required this.yard, required this.cats})
      : super(priority: 84);
  final MoonlitYard yard;
  final Iterable<CatComponent> Function() cats;

  @override
  void render(Canvas canvas) {
    final screen = gameRef.size.toSize();
    paintMoon(canvas, screen, yard.moon);
    for (final cat in cats()) {
      if (!cat.catchWindow.canCatch || cat.isCarried || cat.isDelivered) {
        continue;
      }
      final center = (cat.position + cat.size / 2).toOffset();
      if (!yard.isLit(center, screen)) continue;
      canvas.drawCircle(
          center,
          cat.size.x * .5,
          Paint()
            ..color = const Color(0xCC74FF97)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5);
    }
  }
}

/// A lantern post. Tapping the lamp lights it.
class LanternComponent extends PositionComponent with HasGameRef, TapCallbacks {
  LanternComponent({required this.lantern, required this.onTapLantern})
      : super(size: Vector2(44, 64), priority: 86);
  final YardLantern lantern;
  final void Function(YardLantern lantern) onTapLantern;
  double _clock = 0;

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    position = Vector2(lantern.spot.dx * size.x - this.size.x / 2,
        lantern.spot.dy * size.y - this.size.y);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _clock += dt;
  }

  @override
  void onTapDown(TapDownEvent event) => onTapLantern(lantern);

  @override
  void render(Canvas canvas) {
    final lit = lantern.lit;
    const lamp = Offset(22, 24);
    if (lit) {
      final flicker = 1 + math.sin(_clock * 13) * .06;
      canvas.drawCircle(
          lamp, 24 * flicker, Paint()..color = const Color(0x55FFC86A));
    }
    // Post and foot.
    canvas.drawOval(
        Rect.fromCenter(center: const Offset(22, 62), width: 22, height: 6),
        Paint()..color = const Color(0x66000000));
    canvas.drawRect(const Rect.fromLTWH(20, 34, 4, 28),
        Paint()..color = const Color(0xFF3B2A20));
    canvas.drawLine(
        const Offset(22, 10),
        const Offset(22, 13),
        Paint()
          ..color = const Color(0xFF2B1D14)
          ..strokeWidth = 2);
    // Lamp body.
    final body = RRect.fromRectAndRadius(
        Rect.fromCenter(center: lamp, width: 18, height: 22),
        const Radius.circular(5));
    canvas.drawRRect(
        body,
        Paint()
          ..color = lit ? const Color(0xFFFFD27A) : const Color(0xFF7A6650));
    canvas.drawRRect(
        body,
        Paint()
          ..color = const Color(0xFF2B1D14)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
    canvas.drawLine(
        const Offset(22, 13),
        const Offset(22, 35),
        Paint()
          ..color = const Color(0x552B1D14)
          ..strokeWidth = 1.2);
    for (final y in const [12.0, 35.0]) {
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromCenter(center: Offset(22, y), width: 22, height: 4),
              const Radius.circular(2)),
          Paint()..color = const Color(0xFF2B1D14));
    }
    if (lit) {
      canvas.drawOval(
          Rect.fromCenter(
              center: lamp + const Offset(0, 2), width: 6, height: 9),
          Paint()..color = const Color(0xFFFFF6D0));
    }
    // Ring: time left while lit, rest time while cooling, a pulse when ready.
    final ring = Rect.fromCircle(center: lamp, radius: 17);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    if (lit) {
      canvas.drawArc(
          ring,
          -math.pi / 2,
          math.pi * 2 * (lantern.burn / lantern.burnTotal),
          false,
          stroke..color = const Color(0xFFFFC24D));
    } else if (lantern.cool > 0) {
      canvas.drawArc(
          ring,
          -math.pi / 2,
          math.pi * 2 * (1 - lantern.cool / MoonlitYard.restTime),
          false,
          stroke..color = const Color(0x88C8C8D8));
    } else {
      final pulse = .5 + .5 * math.sin(_clock * 4);
      canvas.drawCircle(lamp, 16 + pulse * 2,
          stroke..color = Color.fromRGBO(255, 244, 200, .35 + .35 * pulse));
    }
  }
}
