import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/painting.dart';
import '../moonlight.dart';
import '../moonlight_art.dart';
import 'night_station.dart';
import 'night_station_scene.dart';

const _ink = Color(0xFF3B2414);
Paint _stroke(Color color, double width) => Paint()
  ..color = color
  ..style = PaintingStyle.stroke
  ..strokeWidth = width
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round;

/// Sign colours are picked to be told apart at a glance, not breed fur.
Color _signColor(String? breed, bool shared) => shared
    ? const Color(0xFFFFE08A)
    : switch (breed) {
        'orange' => const Color(0xFFF07A2A),
        'black' => const Color(0xFF3C4450),
        'himalaya' => const Color(0xFF59B7D0),
        'scottish' => const Color(0xFF8B66B8),
        'calico' => const Color(0xFFE0566E),
        _ => const Color(0xFF7C8790),
      };

void _paw(Canvas c, Offset center, double s, Color color) {
  final paint = Paint()..color = color;
  c.drawOval(
      Rect.fromCenter(
          center: center + Offset(0, s * .22), width: s * .62, height: s * .48),
      paint);
  for (final (dx, dy) in const [
    (-.34, -.16),
    (-.12, -.36),
    (.12, -.36),
    (.34, -.16)
  ]) {
    c.drawOval(
        Rect.fromCenter(
            center: center + Offset(dx * s, dy * s),
            width: s * .2,
            height: s * .26),
        paint);
  }
}

/// Car sign: a coloured plate with a paw, used on posts and on the train.
void paintStationSign(Canvas c, Offset center, String? breed, bool shared,
    {double size = 26}) {
  final plate = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: size * 1.3, height: size),
      Radius.circular(size * .25));
  c.drawRRect(plate.shift(const Offset(0, 2)),
      Paint()..color = const Color(0x66000000));
  c.drawRRect(plate, Paint()..color = _signColor(breed, shared));
  c.drawRRect(plate, _stroke(_ink, 2));
  if (breed == null && !shared) {
    final text = TextPainter(
        text: const TextSpan(
            text: '?',
            style: TextStyle(
                color: Color(0xFFFFF4DA),
                fontSize: 16,
                fontWeight: FontWeight.w900)),
        textDirection: TextDirection.ltr)
      ..layout();
    text.paint(c, center - Offset(text.width / 2, text.height / 2));
    text.dispose();
  } else {
    _paw(c, center, size * .62,
        shared ? const Color(0xFF6A3E1E) : const Color(0xFFFFF4DA));
  }
}

class NightStationBackground extends PositionComponent with HasGameReference {
  NightStationBackground(this.scene) : super(priority: -100);
  final NightStationScene scene;
  ui.Picture? _picture;
  Size _size = Size.zero;

  @override
  void onRemove() {
    _picture?.dispose();
    super.onRemove();
  }

  @override
  void render(Canvas canvas) {
    final s = game.size.toSize();
    if (s.isEmpty) return;
    if (_picture == null || _size != s) {
      _picture?.dispose();
      final rec = ui.PictureRecorder();
      _paint(Canvas(rec), s);
      _picture = rec.endRecording();
      _size = s;
    }
    canvas.drawPicture(_picture!);
  }

  void _paint(Canvas c, Size s) {
    c.drawRect(
        Offset.zero & s,
        Paint()
          ..shader = ui.Gradient.linear(Offset.zero, Offset(0, s.height * .2),
              const [Color(0xFF15233D), Color(0xFF2A3554)]));
    // Station wall with warm windows and a roof edge.
    c.drawRect(Rect.fromLTWH(0, s.height * .1, s.width, s.height * .12),
        Paint()..color = const Color(0xFF5B4A4A));
    for (var x = s.width * .06; x < s.width; x += s.width * .16) {
      final w = RRect.fromRectAndRadius(
          Rect.fromLTWH(x, s.height * .125, s.width * .07, s.height * .07),
          const Radius.circular(4));
      c.drawRRect(w, Paint()..color = const Color(0xFFFFD98A));
      c.drawRRect(w, _stroke(_ink, 2));
      c.drawLine(w.outerRect.topCenter, w.outerRect.bottomCenter,
          _stroke(const Color(0xFF8A6235), 1.5));
    }
    c.drawRect(Rect.fromLTWH(0, s.height * .095, s.width, 6),
        Paint()..color = const Color(0xFF2D2230));
    // Platform tiles.
    final platform = Rect.fromLTWH(0, s.height * .22, s.width, s.height * .48);
    c.drawRect(
        platform,
        Paint()
          ..shader = ui.Gradient.linear(
              platform.topCenter,
              platform.bottomCenter,
              const [Color(0xFF6E6A66), Color(0xFF575452)]));
    final tile = _stroke(const Color(0x33FFFFFF), 1);
    for (var x = 0.0; x < s.width; x += 42) {
      c.drawLine(
          Offset(x, platform.top), Offset(x - 18, platform.bottom), tile);
    }
    for (var y = platform.top + 30; y < platform.bottom; y += 30) {
      c.drawLine(Offset(0, y), Offset(s.width, y), tile);
    }
    // Benches.
    for (var i = 0; i < 6; i++) {
      final x = s.width * (.1 + i * .16);
      final bench = RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset(x, s.height * .4),
              width: s.width * .11,
              height: 10),
          const Radius.circular(4));
      c.drawRRect(bench, Paint()..color = const Color(0xFFA06A3A));
      c.drawRRect(bench, _stroke(_ink, 2));
      for (final dx in [-s.width * .04, s.width * .04]) {
        c.drawLine(Offset(x + dx, s.height * .4 + 5),
            Offset(x + dx, s.height * .43), _stroke(_ink, 3));
      }
    }
    // Yellow safety edge and tracks.
    c.drawRect(Rect.fromLTWH(0, s.height * .69, s.width, s.height * .025),
        Paint()..color = const Color(0xFFE8C04A));
    for (var x = 0.0; x < s.width; x += 22) {
      c.drawRect(Rect.fromLTWH(x, s.height * .69, 11, s.height * .025),
          Paint()..color = const Color(0xFF3B3430));
    }
    c.drawRect(Rect.fromLTWH(0, s.height * .715, s.width, s.height * .285),
        Paint()..color = const Color(0xFF252326));
    for (var x = 0.0; x < s.width; x += 26) {
      c.drawRect(Rect.fromLTWH(x, s.height * .79, 14, s.height * .16),
          Paint()..color = const Color(0xFF4A3628));
    }
    for (final y in [s.height * .81, s.height * .93]) {
      c.drawLine(Offset(0, y), Offset(s.width, y),
          _stroke(const Color(0xFF9EA4A8), 3));
    }
  }
}

class NightStationTrain extends PositionComponent with HasGameReference {
  NightStationTrain(this.scene) : super(priority: 75);
  final NightStationScene scene;
  @override
  void render(Canvas canvas) {
    final line = scene.line;
    if (line.phase == TrainPhase.waiting) return;
    final s = game.size;
    final shift = line.offset * s.x;
    final top = s.y * .735, height = s.y * .2;
    final carWidth = s.x * (line.cars == 3 ? .23 : .18);
    for (var car = 0; car < line.cars; car++) {
      final cx = s.x * line.markX(car) + shift;
      final body = RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset(cx, top + height / 2),
              width: carWidth,
              height: height),
          const Radius.circular(10));
      canvas.drawRRect(body, Paint()..color = const Color(0xFF2F6B73));
      canvas.drawRect(Rect.fromLTWH(body.left, body.bottom - 10, body.width, 6),
          Paint()..color = const Color(0xFFE8C04A));
      canvas.drawRRect(body, _stroke(_ink, 2.5));
      final open = line.phase == TrainPhase.stopped;
      final door = Rect.fromCenter(
          center: Offset(cx, top + height * .55),
          width: open ? carWidth * .3 : carWidth * .22,
          height: height * .62);
      canvas.drawRect(
          door,
          Paint()
            ..color = open ? const Color(0xFFFFE6A6) : const Color(0xFF1C3F46));
      canvas.drawRect(door, _stroke(_ink, 2));
      for (final dx in [-carWidth * .32, carWidth * .32]) {
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromCenter(
                    center: Offset(cx + dx, top + height * .38),
                    width: carWidth * .2,
                    height: height * .32),
                const Radius.circular(3)),
            Paint()..color = const Color(0xFFFFD98A));
      }
      paintStationSign(
          canvas, Offset(cx, top + 2), line.signs[car], car == line.sharedCar,
          size: 22);
    }
    final noseX = s.x * line.markX(0) + shift - carWidth / 2;
    canvas.drawPath(
        Path()
          ..moveTo(noseX, top + 8)
          ..lineTo(noseX - 26, top + height * .55)
          ..lineTo(noseX, top + height - 4)
          ..close(),
        Paint()..color = const Color(0xFF24565D));
    canvas.drawCircle(Offset(noseX - 12, top + height * .55), 6,
        Paint()..color = const Color(0xFFFFF0B0));
  }
}

class StationSelectionComponent extends PositionComponent
    with HasGameReference {
  StationSelectionComponent(this.scene) : super(priority: 70);
  final NightStationScene scene;
  double _clock = 0;
  @override
  void update(double dt) => _clock += dt;
  @override
  void render(Canvas canvas) {
    // A tag in the sign colour teaches which car each breed needs.
    for (final cat in [...scene.benches, ...scene.marks]) {
      if (cat == null || cat.isDelivered) continue;
      final c = Offset(cat.center.x, cat.position.y + cat.size.y * .93);
      canvas.drawOval(
          Rect.fromCenter(center: c, width: cat.size.x * .62, height: 10),
          Paint()..color = _signColor(cat.catType, false));
      canvas.drawOval(
          Rect.fromCenter(center: c, width: cat.size.x * .62, height: 10),
          _stroke(_ink, 1.5));
    }
    final cat = scene.selected;
    if (cat == null) return;
    final r = 1 + math.sin(_clock * 8) * .06;
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(cat.center.x, cat.position.y + cat.size.y * .92),
            width: cat.size.x * .95 * r,
            height: 18 * r),
        _stroke(const Color(0xFFFFE08A), 3));
  }
}

class StationMoon extends PositionComponent with HasGameReference {
  StationMoon(this.moon) : super(priority: 84);
  final Moonlight moon;
  @override
  void render(Canvas canvas) => paintMoon(canvas, game.size.toSize(), moon);
}

/// Boarding mark with its car sign post. Taps assign the selected cat.
class StationMarkComponent extends PositionComponent
    with HasGameReference, TapCallbacks {
  StationMarkComponent(this.scene, this.car, {required this.onTapMark})
      : super(priority: 85);
  final NightStationScene scene;
  final int car;
  final void Function(int) onTapMark;
  double _clock = 0;

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = Vector2(size.x * .17, size.y * .3);
    position =
        Vector2(size.x * scene.line.markX(car) - this.size.x / 2, size.y * .43);
  }

  @override
  void update(double dt) => _clock += dt;
  @override
  void onTapDown(TapDownEvent event) => onTapMark(car);

  @override
  void render(Canvas canvas) {
    final line = scene.line;
    final mark =
        Rect.fromLTWH(size.x * .12, size.y * .6, size.x * .76, size.y * .3);
    final waiting = scene.selected != null && scene.marks[car] == null;
    final pulse = waiting ? .55 + math.sin(_clock * 6) * .25 : .35;
    canvas.drawRRect(RRect.fromRectAndRadius(mark, const Radius.circular(8)),
        Paint()..color = Color.fromRGBO(255, 224, 138, pulse * .45));
    canvas.drawRRect(RRect.fromRectAndRadius(mark, const Radius.circular(8)),
        _stroke(const Color(0xFFFFE08A), 2.5));
    final label = TextPainter(
        text: TextSpan(
            text: 'TOA ${car + 1}',
            style: const TextStyle(
                color: Color(0xFFFFF4DA),
                fontSize: 10,
                fontWeight: FontWeight.w900)),
        textDirection: TextDirection.ltr)
      ..layout();
    label.paint(
        canvas,
        Offset(
            mark.center.dx - label.width / 2, mark.bottom - label.height - 2));
    label.dispose();
    // Sign post: the coming train's car, unless signs are hidden.
    final post = Offset(size.x - 10, 10);
    canvas.drawLine(post + const Offset(0, 12), Offset(post.dx, mark.top),
        _stroke(_ink, 3));
    final sign = !line.signsShown
        ? null
        : line.phase == TrainPhase.waiting
            ? line.next[car]
            : line.signs[car];
    paintStationSign(canvas, post, sign, car == line.sharedCar, size: 22);
  }
}
