import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/painting.dart';

import '../components/cat_component.dart';

/// One lantern on the night yard. Tap to light it; it burns for a while,
/// then needs a short rest before it can be lit again.
class YardLantern {
  YardLantern(this.spot);

  /// Foot of the post, as fractions of the field.
  final Offset spot;
  double burn = 0, cool = 0, burnTotal = 1;
  bool get lit => burn > 0;
  bool get ready => burn <= 0 && cool <= 0;

  /// Lamp centre in pixels; the light pool is centred here.
  Offset lamp(Size size) =>
      Offset(spot.dx * size.width, spot.dy * size.height - 40);
}

/// State of the moonlit backyard: lanterns, the drifting moonlight patch and
/// the clouds that hide it. Cats in the light are calm and wait longer.
class MoonlitYard {
  /// Post spots in the order extra lanterns are added.
  static const spots = [
    Offset(.50, .40),
    Offset(.27, .36),
    Offset(.73, .36),
    Offset(.31, .66),
    Offset(.69, .66),
  ];
  static const restTime = 5.0;

  final lanterns = <YardLantern>[];
  double burnTime = 10, lightScale = 1;
  bool fullMoon = false, thickClouds = false;
  double _clock = 0, _moonShown = 1;

  void setup(
      {required int count,
      required double burnTime,
      required double lightScale,
      required bool fullMoon,
      required bool thickClouds}) {
    this.burnTime = burnTime;
    this.lightScale = lightScale;
    this.fullMoon = fullMoon;
    this.thickClouds = thickClouds;
    _clock = 0;
    _moonShown = 1;
    lanterns
      ..clear()
      ..addAll([for (final spot in spots.take(count)) YardLantern(spot)]);
  }

  bool light(YardLantern lantern) {
    if (!lantern.ready) return false;
    lantern
      ..burn = burnTime
      ..burnTotal = burnTime;
    return true;
  }

  /// Clouds cover the moon for part of every cycle (longer on cloudy nights).
  bool get cloudy {
    if (fullMoon) return false;
    final period = thickClouds ? 12.0 : 16.0;
    final covered = thickClouds ? 7.0 : 5.0;
    return _clock % period >= period - covered;
  }

  /// 0..1 strength of the moonlight, fading as clouds pass.
  double get moonShown => _moonShown;

  void update(double dt) {
    _clock += dt;
    final target = cloudy ? 0.0 : 1.0;
    _moonShown += (target - _moonShown).clamp(-dt, dt);
    for (final lantern in lanterns) {
      if (lantern.burn > 0) {
        lantern.burn -= dt;
        if (lantern.burn <= 0) lantern.cool = restTime;
      } else if (lantern.cool > 0) {
        lantern.cool -= dt;
      }
    }
  }

  /// The moonlight patch slowly drifts back and forth across the field.
  Offset moonCenter(Size size) => Offset(
      size.width * (.18 + .64 * (.5 + .5 * math.sin(_clock * .16))),
      size.height * (.47 + .08 * math.sin(_clock * .23)));
  double moonRadius(Size size) => size.height * .18;
  double lanternRadius(Size size) => size.height * .22 * lightScale;

  /// Whether [point] is inside lantern or moon light.
  bool isLit(Offset point, Size size) {
    if (_moonShown > .5 &&
        (point - moonCenter(size)).distance <= moonRadius(size) * .85) {
      return true;
    }
    final reach = lanternRadius(size) * .85;
    return lanterns
        .any((l) => l.lit && (point - l.lamp(size)).distance <= reach);
  }

  /// Light pools punched into the darkness layer.
  Iterable<(Offset, double)> lights(Size size) sync* {
    if (_moonShown > 0) yield (moonCenter(size), moonRadius(size) * _moonShown);
    for (final lantern in lanterns) {
      if (lantern.lit) {
        // Dims a little in the last two seconds as a warning.
        final fade = (lantern.burn / 2).clamp(.6, 1.0);
        yield (lantern.lamp(size), lanternRadius(size) * fade);
      }
    }
  }
}

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
    // Sky strip with stars.
    final sky = Rect.fromLTWH(0, 0, w, h * .12);
    canvas.drawRect(
        sky,
        Paint()
          ..shader = ui.Gradient.linear(sky.topCenter, sky.bottomCenter,
              const [Color(0xFF121A3A), Color(0xFF26315E)]));
    for (var i = 0; i < 30; i++) {
      canvas.drawCircle(
          Offset(random.nextDouble() * w, random.nextDouble() * h * .1),
          random.nextDouble() * 1.2 + .4,
          Paint()..color = const Color(0xCCFFF6D8));
    }
    // Lawn.
    final lawn = Rect.fromLTWH(0, h * .1, w, h * .9);
    canvas.drawRect(
        lawn,
        Paint()
          ..shader = ui.Gradient.linear(lawn.topCenter, lawn.bottomCenter,
              const [Color(0xFF3C5E47), Color(0xFF2A4535)]));
    // Mown stripes.
    for (var x = 0.0; x < w; x += 70) {
      canvas.drawRect(Rect.fromLTWH(x, h * .16, 35, h * .66),
          Paint()..color = const Color(0x0DFFFFFF));
    }
    // Fence.
    final plank = Paint()..color = const Color(0xFF6B5240);
    final dark = Paint()..color = const Color(0xFF4A382C);
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
      ..color = const Color(0xFF507A5C)
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
    final bush = Paint()..color = const Color(0xFF223C2D);
    final bushLight = Paint()..color = const Color(0xFF2E4D3A);
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
    canvas.drawRect(porch, Paint()..color = const Color(0xFF6B4F3A));
    final seam = Paint()
      ..color = const Color(0xFF4F3828)
      ..strokeWidth = 1.5;
    for (var y = porch.top; y < h; y += 14) {
      canvas.drawLine(Offset(0, y), Offset(w, y), seam);
    }
    canvas.drawRect(Rect.fromLTWH(0, porch.top - 4, w, 5),
        Paint()..color = const Color(0xFF8A6A50));
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
    _moon(canvas, screen);
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

  void _moon(Canvas canvas, Size screen) {
    // Top left, clear of the status pill and the mission card.
    final c = Offset(screen.width * .22, screen.height * .07);
    final r = screen.height * .045;
    final shown = yard.moonShown;
    canvas.drawCircle(c, r * 2.2,
        Paint()..color = Color.fromRGBO(255, 244, 200, .12 * shown));
    canvas.drawCircle(c, r, Paint()..color = const Color(0xFFFFF4C8));
    canvas.drawCircle(c + Offset(-r * .3, -r * .2), r * .2,
        Paint()..color = const Color(0x22B8A060));
    canvas.drawCircle(c + Offset(r * .35, r * .3), r * .14,
        Paint()..color = const Color(0x22B8A060));
    // Cloud slides over the moon while it is hidden.
    final cover = 1 - shown;
    if (cover <= 0) return;
    final cloud = Paint()..color = Color.fromRGBO(70, 80, 115, .95 * cover);
    final cx = c.dx + (1 - cover) * r * 3;
    for (final (dx, dy, cr) in const [
      (-1.1, .25, .7),
      (-.3, -.1, .9),
      (.6, .2, .75),
      (1.3, .35, .55),
    ]) {
      canvas.drawCircle(Offset(cx + dx * r, c.dy + dy * r), cr * r, cloud);
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
