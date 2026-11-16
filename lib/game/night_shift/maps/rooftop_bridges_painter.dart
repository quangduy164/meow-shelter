import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/painting.dart';
import '../../../fishing/fishing_lighting.dart';
import '../../components/cat_component.dart';
import '../moonlight_art.dart';
import 'rooftop_bridges.dart';

class RooftopBackground extends PositionComponent {
  RooftopBackground() : super(priority: -100);
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
      paintRooftops(Canvas(recorder), size.toSize());
      _picture = recorder.endRecording();
    }
    canvas.drawPicture(_picture!);
  }
}

void paintRooftops(Canvas canvas, Size size) {
  final w = size.width, h = size.height;
  final lighting = FishingLighting(DateTime(2000, 1, 1, 22));
  canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = ui.Gradient.linear(Offset.zero, Offset(0, h * .35),
            [lighting.skyTop, lighting.skyBottom]));
  final random = math.Random(22);
  for (var i = 0; i < 36; i++) {
    canvas.drawCircle(
        Offset(random.nextDouble() * w, random.nextDouble() * h * .12),
        .6 + random.nextDouble(),
        Paint()..color = const Color(0xBBEAF6DF));
  }
  // Far city silhouettes.
  for (var i = 0; i < 12; i++) {
    final x = i * w / 11 - 20;
    final height = h * (.08 + (i % 4) * .025);
    canvas.drawRect(Rect.fromLTWH(x, h * .17 - height, w / 13, height),
        Paint()..color = const Color(0xFF263B4C));
    if (i.isEven) {
      canvas.drawRect(Rect.fromLTWH(x + 12, h * .12, 6, 7),
          Paint()..color = const Color(0x99D9B76E));
    }
  }
  // Street far below the rooftop gaps.
  canvas.drawRect(Rect.fromLTWH(0, h * .17, w, h * .65),
      Paint()..color = const Color(0xFF162432));
  for (final gap in RooftopBridges.gaps) {
    final r =
        Rect.fromLTRB(gap.left * w, gap.top * h, gap.right * w, gap.bottom * h);
    canvas.drawRect(
        r,
        Paint()
          ..shader = ui.Gradient.linear(r.topCenter, r.bottomCenter,
              const [Color(0xFF07111D), Color(0xFF213845)]));
    for (var y = r.top + 18; y < r.bottom; y += 34) {
      canvas.drawLine(
          Offset(r.center.dx, y),
          Offset(r.center.dx, y + 12),
          Paint()
            ..color = const Color(0x55A8B7B2)
            ..strokeWidth = 2);
    }
  }
  final roofs = [
    Rect.fromLTRB(0, h * .17, w * .34, h * .82),
    Rect.fromLTRB(w * .40, h * .17, w * .60, h * .82),
    Rect.fromLTRB(w * .66, h * .17, w, h * .82),
  ];
  for (var i = 0; i < roofs.length; i++) {
    final r = roofs[i];
    canvas.drawRect(
        r,
        Paint()
          ..colorFilter = lighting.terrainFilter
          ..color = [
            const Color(0xFFA35B4E),
            const Color(0xFF6C8178),
            const Color(0xFF8B6B9B)
          ][i]);
    for (var y = r.top + 16; y < r.bottom; y += 18) {
      canvas.drawLine(
          Offset(r.left, y),
          Offset(r.right, y),
          Paint()
            ..color = const Color(0x33000000)
            ..strokeWidth = 2);
      for (var x = r.left + ((y ~/ 18).isEven ? 0 : 18); x < r.right; x += 36) {
        canvas.drawArc(
            Rect.fromLTWH(x, y - 9, 36, 18),
            0,
            math.pi,
            false,
            Paint()
              ..color = const Color(0x18FFFFFF)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2);
      }
    }
    canvas.drawRect(Rect.fromLTWH(r.left, r.top - 5, r.width, 8),
        Paint()..color = const Color(0xFF4E3933));
  }
  // The shared feeding roof is marked independently of the moving moonbeam.
  const feeding = RooftopBridges.baitArea;
  final feedingRect = Rect.fromLTRB(feeding.left * w + 5, feeding.top * h,
      feeding.right * w - 5, feeding.bottom * h);
  final feedingShape =
      RRect.fromRectAndRadius(feedingRect, const Radius.circular(9));
  canvas.drawRRect(feedingShape, Paint()..color = const Color(0x18FFD47D));
  canvas.drawRRect(
      feedingShape,
      Paint()
        ..color = const Color(0xBBDDCC94)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5);
  final label = TextPainter(
      text: const TextSpan(
          text: 'ĐẶT CÁ Ở MÁI GIỮA',
          style: TextStyle(
              color: Color(0xFFFFE9B6),
              fontSize: 10,
              fontWeight: FontWeight.w800)),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr)
    ..layout(maxWidth: feedingRect.width - 8);
  label.paint(canvas,
      Offset(feedingRect.center.dx - label.width / 2, feedingRect.top + 7));
  label.dispose();
  // Decorative chimneys at the outer edges.
  for (final x in [w * .06, w * .91]) {
    canvas.drawRect(Rect.fromLTWH(x, h * .55, 34, 54),
        Paint()..color = const Color(0xFF6F5249));
    canvas.drawRect(Rect.fromLTWH(x - 4, h * .53, 42, 10),
        Paint()..color = const Color(0xFF3F302C));
    for (var y = h * .57; y < h * .67; y += 10) {
      canvas.drawLine(Offset(x, y), Offset(x + 34, y),
          Paint()..color = const Color(0x33000000));
    }
  }
  canvas.drawRect(Rect.fromLTWH(0, h * .82, w, h * .18),
      Paint()..color = const Color(0xFF223747));
}

class RooftopAtmosphere extends PositionComponent with HasGameReference {
  RooftopAtmosphere(this.roof) : super(priority: 84);
  final RooftopBridges roof;
  @override
  void render(Canvas canvas) {
    final screen = game.size.toSize();
    paintMoon(canvas, screen, roof.moon);
    for (final cat in game.children.whereType<CatComponent>()) {
      if (!cat.catchWindow.canCatch || cat.isCarried || cat.isDelivered) {
        continue;
      }
      final c = cat.center.toOffset();
      if (!roof.isLit(c, screen)) continue;
      canvas.drawCircle(
          c,
          cat.size.x * .5,
          Paint()
            ..color = const Color(0xCC74FF97)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5);
    }
  }
}

class RoofBridgeComponent extends PositionComponent
    with HasGameReference, TapCallbacks {
  RoofBridgeComponent(this.bridge, this.roof, {required this.onTapBridge})
      : super(priority: -15);
  final RoofBridge bridge;
  final RooftopBridges roof;
  final void Function(RoofBridge) onTapBridge;

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    final r = roof.bridgeRect(bridge, size.toSize()).inflate(18);
    position = Vector2(r.left, r.top);
    this.size = Vector2(r.width, r.height);
  }

  @override
  void onTapDown(TapDownEvent event) => onTapBridge(bridge);

  @override
  void render(Canvas canvas) {
    final screen = game.size.toSize();
    final screenRect = roof.bridgeRect(bridge, screen);
    final rect = screenRect.shift(Offset(-position.x, -position.y));
    final active = bridge.active;
    if (active) {
      canvas.drawRRect(
          RRect.fromRectAndRadius(rect.inflate(12), const Radius.circular(10)),
          Paint()..color = const Color(0x33FFD47D));
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)),
          Paint()..color = const Color(0xFFB98552));
      for (var x = rect.left + 7; x < rect.right; x += 13) {
        canvas.drawLine(
            Offset(x, rect.top + 2),
            Offset(x, rect.bottom - 2),
            Paint()
              ..color = const Color(0xFF7E5232)
              ..strokeWidth = 2);
      }
      for (final y in [rect.top + 3, rect.bottom - 3]) {
        canvas.drawLine(
            Offset(rect.left, y),
            Offset(rect.right, y),
            Paint()
              ..color = const Color(0xFFE2BF79)
              ..strokeWidth = 2);
      }
    } else {
      final ready = bridge.ready;
      canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(6)),
          Paint()
            ..color = ready ? const Color(0xAAFFE0A1) : const Color(0x66889CA9)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
      canvas.drawLine(
          rect.centerLeft,
          rect.centerRight,
          Paint()
            ..color = ready ? const Color(0xAAFFE0A1) : const Color(0x66889CA9)
            ..strokeWidth = 2);
    }
    final c = rect.center;
    final fraction = bridge.open > 0
        ? bridge.open / roof.openTime
        : bridge.ember > 0
            ? bridge.ember / math.max(roof.afterglow, .1)
            : bridge.cool > 0
                ? 1 - bridge.cool / roof.cooldown
                : 1.0;
    canvas.drawArc(
        Rect.fromCircle(center: c, radius: 15),
        -math.pi / 2,
        math.pi * 2 * fraction,
        false,
        Paint()
          ..color = active ? const Color(0xFFFFD17A) : const Color(0xFFBFD4DA)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round);
  }
}
