import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/painting.dart';
import '../../../fishing/fishing_lighting.dart';
import '../../components/cat_component.dart';
import '../moonlight_art.dart';
import 'night_market.dart';

class NightMarketBackground extends PositionComponent {
  NightMarketBackground() : super(priority: -100);
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
      paintNightMarket(Canvas(recorder), size.toSize());
      _picture = recorder.endRecording();
    }
    canvas.drawPicture(_picture!);
  }
}

/// Scenery is decorative; the open paving is the playable area.
void paintNightMarket(Canvas canvas, Size size) {
  canvas.save();
  canvas.scale(size.width / 1000, size.height / 500);
  final lighting = FishingLighting(DateTime(2000, 1, 1, 22));
  Paint p(int c) => Paint()..color = Color(c);
  canvas.drawRect(
      const Rect.fromLTWH(0, 0, 1000, 500),
      Paint()
        ..shader = LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [lighting.skyTop, lighting.skyBottom])
            .createShader(const Rect.fromLTWH(0, 0, 1000, 150)));
  final random = math.Random(93);
  for (var i = 0; i < 38; i++) {
    canvas.drawCircle(
        Offset(random.nextDouble() * 1000, random.nextDouble() * 62),
        .7 + random.nextDouble(),
        p(0xBBEAF6DF));
  }
  // Shopfronts in a night palette, with warm windows.
  for (var i = 0; i < 7; i++) {
    final x = i * 152.0 - 20;
    final top = 52.0 + (i % 3) * 7;
    canvas.drawRect(
        Rect.fromLTWH(x, top, 148, 88), p(i.isEven ? 0xFF42595C : 0xFF586169));
    canvas.drawRect(Rect.fromLTWH(x - 3, top - 4, 154, 8), p(0xFF25383F));
    for (var j = 0; j < 3; j++) {
      final r = Rect.fromLTWH(x + 12 + j * 44, top + 13, 27, 25);
      canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(2)),
          p((i + j) % 3 == 0 ? 0xFF273F49 : 0xFFBCA16B));
      canvas.drawLine(
          r.topCenter,
          r.bottomCenter,
          Paint()
            ..color = const Color(0xFF46514B)
            ..strokeWidth = 2);
    }
    // Closed shutters behind the awning.
    canvas.drawRect(Rect.fromLTWH(x + 7, top + 47, 132, 40), p(0xFF35474E));
    for (var y = top + 51; y < 138; y += 6) {
      canvas.drawLine(
          Offset(x + 9, y),
          Offset(x + 137, y),
          Paint()
            ..color = const Color(0xFF4C5C61)
            ..strokeWidth = 1);
    }
  }
  // A string of amber bulbs.
  final wire = Path()
    ..moveTo(0, 55)
    ..quadraticBezierTo(500, 94, 1000, 55);
  canvas.drawPath(
      wire,
      Paint()
        ..color = const Color(0xFF27343B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2);
  for (var i = 0; i < 14; i++) {
    final x = 18 + i * 74.0;
    final t = x / 1000;
    final y = 55 + 78 * t * (1 - t);
    canvas.drawCircle(Offset(x, y + 4), 8, p(0x22FFDD92));
    canvas.drawOval(
        Rect.fromCenter(center: Offset(x, y + 4), width: 4, height: 6),
        p(0xFFE7CF94));
  }
  // Market stalls, never hidden physical barriers.
  for (final (x, color) in const [
    (30.0, 0xFF957064),
    (365.0, 0xFF6A8382),
    (700.0, 0xFF7D7193)
  ]) {
    canvas.drawRect(Rect.fromLTWH(x, 114, 270, 12), p(0xFF3A3331));
    for (var j = 0; j < 9; j++) {
      final xx = x + j * 30;
      canvas.drawPath(
          Path()
            ..moveTo(xx + 4, 92)
            ..lineTo(xx + 26, 92)
            ..lineTo(xx + 30, 119)
            ..quadraticBezierTo(xx + 15, 132, xx, 119)
            ..close(),
          p(j.isEven ? color : 0xFFC1B191));
    }
  }
  // Wide slate paving, perspective rows and bright grout.
  canvas.drawRect(
      const Rect.fromLTWH(0, 136, 1000, 364),
      Paint()
        ..shader = const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF5F7472), Color(0xFF3D555E)])
            .createShader(const Rect.fromLTWH(0, 136, 1000, 364)));
  var row = 0;
  for (var y = 143.0; y < 500; y += 35, row++) {
    for (var x = row.isEven ? -45.0 : 0.0; x < 1000; x += 92) {
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(x + 3, y, 86, 29), const Radius.circular(5)),
          p(row.isEven ? 0x1AACC4BE : 0x12334455));
      canvas.drawLine(
          Offset(x + 9, y + 2),
          Offset(x + 78, y + 2),
          Paint()
            ..color = const Color(0x227C9EAA)
            ..strokeWidth = 1);
    }
  }
  // Gutters and traffic lane across the foreground.
  for (final y in const [145.0, 412.0]) {
    canvas.drawLine(
        Offset(0, y),
        Offset(1000, y),
        Paint()
          ..color = const Color(0xFF354D55)
          ..strokeWidth = 4);
  }
  canvas.drawRect(const Rect.fromLTWH(0, 420, 1000, 80), p(0xFF314955));
  for (var x = 10.0; x < 1000; x += 75) {
    canvas.drawLine(
        Offset(x, 453),
        Offset(x + 36, 453),
        Paint()
          ..color = const Color(0x666C8A90)
          ..strokeWidth = 2);
  }
  // Signs, boxes and bins only at the outer edges.
  for (final x in const [0.0, 941.0]) {
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(x, 260, 59, 68), const Radius.circular(5)),
        p(0xFF486161));
    canvas.drawRect(Rect.fromLTWH(x - 2, 256, 63, 8), p(0xFF30454A));
    for (final dx in const [12.0, 27.0, 42.0]) {
      canvas.drawLine(
          Offset(x + dx, 273),
          Offset(x + dx, 314),
          Paint()
            ..color = const Color(0xFF607875)
            ..strokeWidth = 2);
    }
    canvas.drawRect(Rect.fromLTWH(x + 2, 349, 56, 32), p(0xFF8E7960));
    canvas.drawLine(
        Offset(x + 5, 352),
        Offset(x + 55, 378),
        Paint()
          ..color = const Color(0xFF5A534B)
          ..strokeWidth = 3);
    canvas.drawLine(
        Offset(x + 55, 352),
        Offset(x + 5, 378),
        Paint()
          ..color = const Color(0xFF5A534B)
          ..strokeWidth = 3);
  }
  canvas.restore();
}

class MarketLightPools extends PositionComponent with HasGameRef {
  MarketLightPools(this.market) : super(priority: -20);
  final NightMarket market;
  @override
  void render(Canvas canvas) {
    final screen = gameRef.size.toSize();
    for (final lamp in market.lamps) {
      if (!lamp.lit && lamp.ember <= 0) continue;
      final c = lamp.center(screen);
      final r = market.radius(screen) * (lamp.lit ? 1 : .75);
      final strength = lamp.lit ? (lamp.burn / 2).clamp(.6, 1.0) : .45;
      canvas.drawCircle(
          c,
          r,
          Paint()
            ..shader = ui.Gradient.radial(c, r, [
              const Color(0xFFFFD992).withOpacity(.44 * strength),
              const Color(0xFFFFD992).withOpacity(.24 * strength),
              const Color(0x00FFD992),
            ], const [
              0,
              .65,
              1
            ]));
      canvas.drawCircle(
          c,
          r * .85,
          Paint()
            ..color = const Color(0x77FFE1A5)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5);
    }
  }
}

class NightMarketAtmosphere extends PositionComponent with HasGameRef {
  NightMarketAtmosphere(this.market) : super(priority: 84);
  final NightMarket market;
  @override
  void render(Canvas canvas) {
    final screen = gameRef.size.toSize();
    paintMoon(canvas, screen, market.moon);
    _traffic(canvas, screen);
    final danger = market.noise >= 75 || market.alarm > 0;
    final color = danger ? const Color(0xFFE78272) : const Color(0xFF93BFA9);
    final box = RRect.fromRectAndRadius(
        Rect.fromLTWH(screen.width / 2 - 94, 47, 188, 29),
        const Radius.circular(10));
    canvas.drawRRect(box, Paint()..color = const Color(0xEC25384A));
    canvas.drawRRect(
        box,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);
    _text(canvas, 'ĐỘ ỒN ${market.noise.round()}/100',
        Offset(box.left + 9, box.top + 4), color);
    final bar = RRect.fromRectAndRadius(
        Rect.fromLTWH(box.left + 9, box.bottom - 8, 170, 4),
        const Radius.circular(2));
    canvas.drawRRect(bar, Paint()..color = const Color(0xFF526874));
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(bar.left, bar.top, 170 * market.noise / 100, 4),
            const Radius.circular(2)),
        Paint()..color = color);
    if (market.cartWarning || market.alarm > 0) {
      _text(
          canvas,
          market.alarm > 0
              ? 'SUỴT! MÈO NGOÀI SÁNG ĐANG HOẢNG'
              : 'XE ĐẨY SẮP QUA',
          Offset(screen.width / 2, 81),
          const Color(0xFFFFC792),
          centered: true);
    }
    if (market.alarm > 0) {
      canvas.drawRect(
          (Offset.zero & screen).deflate(2),
          Paint()
            ..color = const Color(0xFFEA9A84).withOpacity(market.alarm / 5)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4);
    }
    for (final cat in gameRef.children.whereType<CatComponent>()) {
      if (!cat.catchWindow.canCatch || cat.isCarried || cat.isDelivered) {
        continue;
      }
      final c = cat.center.toOffset();
      if (!market.isLit(c, screen)) continue;
      canvas.drawCircle(
          c,
          cat.size.x * .5,
          Paint()
            ..color = const Color(0xCC74FF97)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5);
    }
  }

  void _traffic(Canvas canvas, Size screen) {
    final progress = market.cartProgress;
    if (progress == null) return;
    final x = -100 + (screen.width + 200) * progress;
    final y = screen.height * .89;
    canvas.save();
    canvas.translate(x, y);
    for (final dx in const [-25.0, 25.0]) {
      canvas.drawCircle(
          Offset(dx, 10), 9, Paint()..color = const Color(0xFF1F303A));
      canvas.drawCircle(
          Offset(dx, 10), 4, Paint()..color = const Color(0xFF819192));
    }
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(-45, -20, 90, 28), const Radius.circular(3)),
        Paint()..color = const Color(0xFFB08A5C));
    canvas.drawRect(const Rect.fromLTWH(-38, -17, 76, 4),
        Paint()..color = const Color(0xFFD7B278));
    for (final dx in const [-25.0, 1.0]) {
      canvas.drawRect(Rect.fromLTWH(dx, -47, 27, 27),
          Paint()..color = const Color(0xFF887C62));
      canvas.drawLine(
          Offset(dx, -46),
          Offset(dx + 26, -21),
          Paint()
            ..color = const Color(0xFFB8A27A)
            ..strokeWidth = 2);
    }
    canvas.drawLine(
        const Offset(-45, -15),
        const Offset(-66, -27),
        Paint()
          ..color = const Color(0xFF535F5D)
          ..strokeWidth = 4);
    canvas.drawCircle(
        const Offset(-72, -38), 9, Paint()..color = const Color(0xFFB6A58B));
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(-82, -28, 20, 36), const Radius.circular(6)),
        Paint()..color = const Color(0xFF607B82));
    canvas.drawOval(const Rect.fromLTWH(-86, -48, 28, 8),
        Paint()..color = const Color(0xFFA99067));
    canvas.restore();
  }

  void _text(Canvas canvas, String text, Offset at, Color color,
      {bool centered = false}) {
    final label = TextPainter(
        text: TextSpan(
            text: text,
            style: TextStyle(
                color: color, fontSize: 10, fontWeight: FontWeight.w800)),
        textDirection: TextDirection.ltr)
      ..layout();
    label.paint(canvas, at - Offset(centered ? label.width / 2 : 0, 0));
    label.dispose();
  }
}

class MarketLampComponent extends PositionComponent
    with HasGameRef, TapCallbacks {
  MarketLampComponent(this.lamp, this.market, {required this.onTapLamp})
      : super(size: Vector2(42, 66), priority: 86);
  final MarketLamp lamp;
  final NightMarket market;
  final void Function(MarketLamp) onTapLamp;
  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    position = Vector2(lamp.spot.dx * size.x - 21, lamp.spot.dy * size.y - 17);
  }

  @override
  void onTapDown(TapDownEvent event) => onTapLamp(lamp);
  @override
  void render(Canvas canvas) {
    const c = Offset(21, 17);
    canvas.drawOval(const Rect.fromLTWH(8, 59, 26, 6),
        Paint()..color = const Color(0x44000000));
    canvas.drawRect(const Rect.fromLTWH(19, 29, 4, 33),
        Paint()..color = const Color(0xFF354B56));
    if (lamp.lit) {
      canvas.drawCircle(c, 25, Paint()..color = const Color(0x33FFE3A5));
    }
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(10, 8, 22, 21), const Radius.circular(3)),
        Paint()
          ..color =
              lamp.lit ? const Color(0xFFFFE0A3) : const Color(0xFF7C8D89));
    canvas.drawPath(
        Path()
          ..moveTo(7, 8)
          ..lineTo(21, 0)
          ..lineTo(35, 8)
          ..close(),
        Paint()..color = const Color(0xFF354B56));
    canvas.drawLine(
        const Offset(21, 9),
        const Offset(21, 28),
        Paint()
          ..color = const Color(0x88516462)
          ..strokeWidth = 2);
    canvas.drawRect(const Rect.fromLTWH(8, 28, 26, 4),
        Paint()..color = const Color(0xFF354B56));
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..color = lamp.lit ? const Color(0xFFFFD186) : const Color(0xFF94B8C0);
    if (lamp.lit || lamp.cool > 0) {
      final fraction =
          lamp.lit ? lamp.burn / market.lampDuration : 1 - lamp.cool / 5;
      canvas.drawArc(Rect.fromCircle(center: c, radius: 19), -math.pi / 2,
          math.pi * 2 * fraction, false, arc);
    } else {
      canvas.drawCircle(c, 19, arc..color = const Color(0x99C5DEE0));
    }
  }
}
