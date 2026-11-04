import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import 'return_home_road.dart';
import 'return_home_scenery.dart';

/// The whole landscape behind the run. It never moves, so it is tessellated
/// once into a [ui.Picture] and replayed each frame instead of re-drawing a few
/// hundred vector shapes every tick.
class ReturnHomeBackground extends PositionComponent {
  ReturnHomeBackground({required this.road});

  final ReturnHomeRoad road;

  /// Columns the world is sliced into for palette blending and road geometry.
  static const int columns = 96;

  /// How far before a biome border its palette starts cross-fading in.
  static const double paletteBlend = .07;

  /// Fraction of the viewport height occupied by sky.
  static const double horizon = .22;

  ui.Picture? _scene;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    rebuild();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    rebuild();
  }

  void rebuild() {
    size = Vector2(road.worldWidth, road.viewportHeight);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    _ground(canvas);
    paintClouds(canvas, road);
    _road(canvas);
    paintStream(canvas, road);
    _props(canvas);
    paintFlowers(canvas, road);
    paintHouse(canvas, road);
    _scene?.dispose();
    _scene = recorder.endRecording();
  }

  @override
  void render(Canvas canvas) {
    final scene = _scene;
    if (scene != null) canvas.drawPicture(scene);
  }

  Color _biomeColor(double f, Color Function(ReturnHomeBiome biome) pick) {
    final biomes = road.biomes;
    final biome = road.biomeAtFraction(f);
    final index = biomes.indexOf(biome);
    if (index + 1 >= biomes.length) return pick(biome);
    final next = biomes[index + 1];
    final t = (f - (next.from - paletteBlend)) / paletteBlend;
    if (t <= 0) return pick(biome);
    return Color.lerp(pick(biome), pick(next), min(t, 1.0))!;
  }

  void _ground(Canvas canvas) {
    final w = road.worldWidth;
    final h = road.viewportHeight;
    final dx = w / columns;
    final skyHeight = h * horizon;
    for (var i = 0; i < columns; i++) {
      final x = i * dx;
      final f = i / columns;
      canvas.drawRect(Rect.fromLTWH(x, 0, dx + 1, skyHeight),
          Paint()..color = _biomeColor(f, (biome) => biome.sky));
      canvas.drawRect(Rect.fromLTWH(x, skyHeight, dx + 1, h - skyHeight),
          Paint()..color = _biomeColor(f, (biome) => biome.grass));
    }
  }

  void _road(Canvas canvas) {
    final w = road.worldWidth;
    final dx = w / columns;
    for (var i = 0; i < columns; i++) {
      final x0 = i * dx;
      final x1 = x0 + dx;
      final f = min(1.0, x1 / w);
      _ribbon(canvas, x0, x1, 1.0, 6,
          Paint()..color = _biomeColor(f, (biome) => biome.edge));
      _ribbon(canvas, x0, x1, 1.0, 0,
          Paint()..color = _biomeColor(f, (biome) => biome.road));
      _ribbon(canvas, x0, x1, .58, 0,
          Paint()..color = _biomeColor(f, (biome) => biome.roadLight));
    }
    _centerDashes(canvas);
  }

  /// One slice of the winding lane between two sample columns. `pad` grows it,
  /// which lets the same shape double as the shoulder behind the road fill.
  void _ribbon(Canvas canvas, double x0, double x1, double scale, double pad,
      Paint paint) {
    final c0 = road.centerY(x0);
    final c1 = road.centerY(x1);
    final h0 = road.halfWidth(x0) * scale + pad;
    final h1 = road.halfWidth(x1) * scale + pad;
    canvas.drawPath(
        Path()
          ..moveTo(x0, c0 - h0)
          ..lineTo(x1, c1 - h1)
          ..lineTo(x1, c1 + h1)
          ..lineTo(x0, c0 + h0)
          ..close(),
        paint);
  }

  /// Only biomes with a [ReturnHomeBiome.dash] get centre lines, which is what
  /// separates the paved outer suburb from the dirt tracks before it.
  void _centerDashes(Canvas canvas) {
    for (var x = 60.0; x < road.worldWidth - sceneryEndMargin; x += 96) {
      final dash = road.biomeAt(x).dash;
      if (dash == null) continue;
      final slope = (road.centerY(x + 26) - road.centerY(x - 26)) / 52;
      canvas.save();
      canvas.translate(x, road.centerY(x));
      canvas.rotate(atan(slope));
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              const Rect.fromLTWH(-18, -3, 36, 6), const Radius.circular(3)),
          Paint()..color = dash);
      canvas.restore();
    }
  }

  void _props(Canvas canvas) {
    final w = road.worldWidth;
    for (var x = sceneryStep * .6; x < w - sceneryEndMargin; x += sceneryStep) {
      paintSceneryProp(
          canvas, road, road.biomeAt(x).scenery, x, (x / sceneryStep).round());
    }
  }
}
