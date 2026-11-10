import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart' show CustomPainter;
import '../world/shelter_garden_painter.dart';
import '../world/shelter_map.dart';
import '../world/map_backgrounds.dart';

class ShelterGardenComponent extends PositionComponent {
  ShelterGardenComponent(
      {required this.isPlaying, required this.map, required this.mapTime})
      : super(priority: -100);
  final bool Function() isPlaying;
  final ShelterMap Function() map;

  /// Seconds on the current map; drives the gate and the crates.
  final double Function() mapTime;
  ui.Picture? _background;
  ShelterMapKind? _backgroundKind;
  double _clock = 0;

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size.setFrom(size);
    _background?.dispose();
    _background = null;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isPlaying()) _clock += dt;
  }

  @override
  void render(Canvas canvas) {
    if (size.x <= 0 || size.y <= 0) return;
    final mapConfig = map();
    // The open lawn (no map) shares the garden scene.
    final kind =
        mapConfig.name.isEmpty ? ShelterMapKind.garden : mapConfig.kind;
    if (_background == null || _backgroundKind != kind) {
      _background?.dispose();
      final recorder = ui.PictureRecorder();
      final CustomPainter painter = switch (kind) {
        ShelterMapKind.garden => const ShelterGardenPainter(),
        ShelterMapKind.warehouse => const WarehousePainter(),
        ShelterMapKind.pond => const PondPainter(),
      };
      painter.paint(Canvas(recorder), Size(size.x, size.y));
      _background = recorder.endRecording();
      _backgroundKind = kind;
    }
    canvas.drawPicture(_background!);
    _drawMap(canvas, mapConfig);
    // Butterflies belong outdoors.
    if (kind == ShelterMapKind.warehouse) return;
    canvas.save();
    canvas.scale(size.x / 1000, size.y / 500);
    for (var i = 0; i < 2; i++) {
      final phase = _clock * .65 + i * 2.8;
      final x = (i == 0 ? 67 : 928) + math.sin(phase) * 28;
      final y = 245 + math.cos(phase * 1.7) * 19;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(math.sin(phase) * .3);
      final wingWidth = 2 + math.sin(_clock * 14 + i).abs() * 5;
      final wing = Paint()
        ..color = i == 0 ? const Color(0xFFE6B86D) : const Color(0xFFD79BA8);
      for (final side in [-1.0, 1.0]) {
        canvas.drawOval(
            Rect.fromCenter(
                center: Offset(side * wingWidth / 2, -2),
                width: wingWidth,
                height: 9),
            wing);
        canvas.drawOval(
            Rect.fromCenter(
                center: Offset(side * wingWidth / 2, 3),
                width: wingWidth * .8,
                height: 6),
            wing);
      }
      canvas.drawLine(
          const Offset(0, -5),
          const Offset(0, 6),
          Paint()
            ..color = const Color(0xFF6B7455)
            ..strokeWidth = 1.5
            ..strokeCap = StrokeCap.round);
      canvas.restore();
    }
    canvas.restore();
  }

  void _drawMap(Canvas canvas, ShelterMap mapConfig) {
    if (mapConfig.name.isEmpty) return;
    canvas.save();
    canvas.scale(size.x / 1000, size.y / 500);
    final t = mapTime();
    // Pulses during the last 1.5 s before the gate or crates move.
    final warn =
        mapConfig.untilChange(t) < 1.5 ? .5 + .5 * math.sin(_clock * 14) : 0.0;
    switch (mapConfig.kind) {
      case ShelterMapKind.garden:
        _drawGarden(canvas, mapConfig, t, warn);
      case ShelterMapKind.warehouse:
        _drawWarehouse(canvas, mapConfig, t, warn);
      case ShelterMapKind.pond:
        _drawPond(canvas, mapConfig);
    }
    canvas.restore();
  }

  static Rect _px(Rect r) =>
      Rect.fromLTWH(r.left * 1000, r.top * 500, r.width * 1000, r.height * 500);

  void _shadow(Canvas canvas, Rect r) => canvas.drawOval(
      Rect.fromLTWH(r.left - 4, r.bottom - 8, r.width + 8, 16),
      Paint()..color = const Color(0x33402A14));

  void _drawGarden(Canvas canvas, ShelterMap m, double t, double warn) {
    // Dirt path with stepping stones running through the gate.
    final path = Path()
      ..moveTo(470, 112)
      ..cubicTo(455, 220, 540, 330, 480, 500)
      ..lineTo(540, 500)
      ..cubicTo(600, 330, 515, 220, 530, 112)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0x88D9C18E));
    for (var i = 0; i < 11; i++) {
      final y = 140.0 + i * 33;
      final x = 500 + math.sin(i * .9) * 22;
      final stone =
          Rect.fromCenter(center: Offset(x, y), width: 34, height: 13);
      canvas.drawOval(stone.shift(const Offset(0, 2)),
          Paint()..color = const Color(0x44706448));
      canvas.drawOval(stone, Paint()..color = const Color(0xFFEDE3C4));
    }
    for (final bed in m.obstacles.take(2).map(_px)) {
      _shadow(canvas, bed);
      final frame = RRect.fromRectAndRadius(bed, const Radius.circular(10));
      canvas.drawRRect(frame, Paint()..color = const Color(0xFFB0714A));
      for (var x = bed.left + 6; x < bed.right - 4; x += 16) {
        canvas.drawLine(
            Offset(x, bed.top + 2),
            Offset(x, bed.top + 8),
            Paint()
              ..color = const Color(0xFF8C5537)
              ..strokeWidth = 1.5);
      }
      final soil = bed.deflate(8);
      canvas.drawRRect(RRect.fromRectAndRadius(soil, const Radius.circular(6)),
          Paint()..color = const Color(0xFF6E4A30));
      var i = 0;
      for (var y = soil.top + 9; y < soil.bottom - 4; y += 14) {
        for (var x = soil.left + 9; x < soil.right - 4; x += 14) {
          final sway = math.sin(_clock * 2 + i) * 1.5;
          final head = Offset(x + sway, y);
          canvas.drawCircle(head + const Offset(-4, 4), 3.5,
              Paint()..color = const Color(0xFF5E9A55));
          const petals = [
            Color(0xFFF6A6B8),
            Color(0xFFFFE08A),
            Color(0xFFFFF6E8)
          ];
          for (var k = 0; k < 5; k++) {
            canvas.drawCircle(head + Offset.fromDirection(k * 1.2566, 3.2), 2.6,
                Paint()..color = petals[i % 3]);
          }
          canvas.drawCircle(
              head, 1.8, Paint()..color = const Color(0xFFE59A3B));
          i++;
        }
      }
    }
    final gate = _px(m.gate!);
    final closed = m.gateClosed(t);
    // Horizontal picket fence makes the opening readable from above.
    void fence(double left, double right) {
      final y = gate.center.dy;
      for (final railY in [y - 16, y - 3]) {
        canvas.drawRect(Rect.fromLTWH(left, railY, right - left, 5),
            Paint()..color = const Color(0xFF936035));
      }
      for (var x = left + 3; x < right; x += 15) {
        final picket = Path()
          ..moveTo(x, y + 8)
          ..lineTo(x, y - 25)
          ..lineTo(x + 5, y - 31)
          ..lineTo(x + 10, y - 25)
          ..lineTo(x + 10, y + 8)
          ..close();
        canvas.drawPath(picket, Paint()..color = const Color(0xFFFFE4AD));
        canvas.drawPath(
            picket,
            Paint()
              ..color = const Color(0xFF986535)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5);
      }
    }

    fence(230, gate.left);
    fence(gate.right, 770);
    final open = closed ? 0.0 : 1.0;
    // Two framed leaves swing toward the flower beds when open.
    for (final side in [-1.0, 1.0]) {
      canvas.save();
      canvas.translate(side < 0 ? gate.left : gate.right, gate.center.dy);
      canvas.rotate(side * open * math.pi / 2);
      if (side > 0) canvas.scale(-1, 1);
      final leaf = Rect.fromLTWH(0, -24, gate.width / 2 - 3, 32);
      canvas.drawRect(leaf.shift(const Offset(2, 4)),
          Paint()..color = const Color(0x33402A14));
      canvas.drawRect(leaf, Paint()..color = const Color(0xFFD6A45F));
      final frame = Paint()
        ..color = const Color(0xFF79502F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4;
      canvas.drawRect(leaf, frame);
      for (var x = 14.0; x < leaf.right; x += 16) {
        canvas.drawLine(Offset(x, leaf.top), Offset(x, leaf.bottom),
            frame..strokeWidth = 1.5);
      }
      canvas.drawLine(leaf.bottomLeft, leaf.topRight, frame..strokeWidth = 5);
      canvas.drawCircle(Offset(leaf.right - 8, -8), 3,
          Paint()..color = const Color(0xFF503823));
      canvas.restore();
    }
    for (final x in [gate.left, gate.right]) {
      final post = Rect.fromLTWH(x - 8, gate.center.dy - 38, 16, 51);
      canvas.drawRect(post, Paint()..color = const Color(0xFF97613A));
      canvas.drawRect(Rect.fromLTWH(x - 11, post.top - 4, 22, 7),
          Paint()..color = const Color(0xFFDEB777));
      canvas.drawCircle(
          Offset(x, post.top - 8), 5, Paint()..color = const Color(0xFFDEB777));
    }
    final label = TextPainter(
        text: TextSpan(
            text: closed ? 'CỔNG ĐÓNG' : 'CỔNG MỞ',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: closed
                    ? const Color(0xFF854327)
                    : const Color(0xFF315F37))),
        textDirection: TextDirection.ltr)
      ..layout();
    final sign = Rect.fromCenter(
        center: Offset(gate.center.dx, gate.center.dy + 29),
        width: label.width + 18,
        height: 23);
    canvas.drawRRect(RRect.fromRectAndRadius(sign, const Radius.circular(6)),
        Paint()..color = const Color(0xFFFFEBC5));
    label.paint(canvas, sign.topLeft + const Offset(9, 4));
    if (warn > 0) {
      canvas.drawRRect(
          RRect.fromRectAndRadius(gate.inflate(6), const Radius.circular(8)),
          Paint()
            ..color = Color.fromRGBO(255, 196, 64, .35 + .5 * warn)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3);
    }
  }

  void _drawWarehouse(Canvas canvas, ShelterMap m, double t, double warn) {
    final swapped = m.cratesSwapped(t);
    final now = (swapped ? m.altObstacles : m.obstacles).map(_px);
    final next = (swapped ? m.obstacles : m.altObstacles).map(_px);
    if (warn > 0) {
      for (final ghost in next) {
        canvas.drawRRect(
            RRect.fromRectAndRadius(ghost, const Radius.circular(6)),
            Paint()..color = Color.fromRGBO(232, 120, 60, .12 + .2 * warn));
        canvas.drawRRect(
            RRect.fromRectAndRadius(ghost, const Radius.circular(6)),
            Paint()
              ..color = Color.fromRGBO(232, 120, 60, .5 + .4 * warn)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3);
      }
    }
    for (final crate in now) {
      _shadow(canvas, crate);
      final body = RRect.fromRectAndRadius(crate, const Radius.circular(5));
      canvas.drawRRect(body, Paint()..color = const Color(0xFFC48C50));
      final edge = Paint()
        ..color = const Color(0xFF7A4B24)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4;
      canvas.drawRRect(body, edge);
      canvas.drawRect(crate.deflate(9), edge..strokeWidth = 3);
      canvas.drawLine(crate.deflate(9).topLeft, crate.deflate(9).bottomRight,
          edge..strokeWidth = 5);
      canvas.drawLine(
          Offset(crate.left + 6, crate.top + 4),
          Offset(crate.right - 6, crate.top + 4),
          Paint()
            ..color = const Color(0x66FFE2B0)
            ..strokeWidth = 2);
      for (final corner in [
        crate.topLeft + const Offset(5, 5),
        crate.topRight + const Offset(-5, 5),
        crate.bottomLeft + const Offset(5, -5),
        crate.bottomRight + const Offset(-5, -5)
      ]) {
        canvas.drawCircle(corner, 2, Paint()..color = const Color(0xFF4E3018));
      }
    }
  }

  void _drawPond(Canvas canvas, ShelterMap m) {
    for (final mud in m.mud.map(_px)) {
      canvas.drawRRect(RRect.fromRectAndRadius(mud, const Radius.circular(70)),
          Paint()..color = const Color(0x8A8A6A42));
      final speck = math.Random(7);
      for (var i = 0; i < 40; i++) {
        canvas.drawCircle(
            Offset(mud.left + 20 + speck.nextDouble() * (mud.width - 40),
                mud.top + 12 + speck.nextDouble() * (mud.height - 24)),
            1.5 + speck.nextDouble() * 2,
            Paint()..color = const Color(0x55513A1E));
      }
    }
    for (final water in m.obstacles.map(_px)) {
      final rim =
          RRect.fromRectAndRadius(water.inflate(5), const Radius.circular(45));
      canvas.drawRRect(rim, Paint()..color = const Color(0xFFB9A57C));
      final pond = RRect.fromRectAndRadius(water, const Radius.circular(40));
      canvas.drawRRect(
          pond,
          Paint()
            ..shader = const RadialGradient(
                    colors: [Color(0xFF7FD0D6), Color(0xFF3E8C9E)])
                .createShader(water));
      canvas.save();
      canvas.clipRRect(pond);
      for (var i = 0; i < 3; i++) {
        final phase = (_clock * .35 + i / 3) % 1;
        canvas.drawOval(
            Rect.fromCenter(
                center: water.center + Offset(-30 + i * 30.0, -6 + i * 6.0),
                width: 20 + phase * 70,
                height: 7 + phase * 24),
            Paint()
              ..color = Color.fromRGBO(230, 252, 250, .5 * (1 - phase))
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5);
      }
      for (final (dx, dy, r) in const [
        (-.32, -.2, 13.0),
        (.3, .18, 11.0),
        (.12, -.28, 9.0),
        (-.1, .3, 10.0)
      ]) {
        final c = water.center +
            Offset(dx * water.width, dy * water.height) +
            Offset(math.sin(_clock + r) * 1.5, 0);
        canvas.drawArc(Rect.fromCircle(center: c, radius: r), .5, 5.6, true,
            Paint()..color = const Color(0xFF5FA45A));
        canvas.drawCircle(c + const Offset(-2, -2), r * .35,
            Paint()..color = const Color(0x3389D27E));
      }
      final lotus = water.center + Offset(water.width * .3, water.height * .18);
      for (var k = 0; k < 6; k++) {
        canvas.drawOval(
            Rect.fromCenter(
                center: lotus + Offset.fromDirection(k * 1.047, 4),
                width: 7,
                height: 5),
            Paint()..color = const Color(0xFFF4A3C0));
      }
      canvas.drawCircle(lotus, 2.5, Paint()..color = const Color(0xFFFFE07A));
      canvas.restore();
      for (final base in [
        water.bottomLeft + const Offset(12, -6),
        water.topRight + const Offset(-14, 10),
        water.bottomRight + const Offset(-20, -2),
      ]) {
        for (var k = 0; k < 4; k++) {
          final sway = math.sin(_clock * 1.6 + k + base.dx) * 2;
          final top = base + Offset(k * 5 - 8 + sway, -26 - (k % 2) * 8.0);
          canvas.drawLine(
              base + Offset(k * 5 - 8, 0),
              top,
              Paint()
                ..color = const Color(0xFF5E8B4A)
                ..strokeWidth = 2);
          if (k.isOdd) {
            canvas.drawRRect(
                RRect.fromRectAndRadius(
                    Rect.fromCenter(center: top, width: 5, height: 12),
                    const Radius.circular(3)),
                Paint()..color = const Color(0xFF8A5A33));
          }
        }
      }
    }
  }

  @override
  void onRemove() {
    _background?.dispose();
    _background = null;
    super.onRemove();
  }
}
