import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart' show CustomPainter;
import '../world/shelter_garden_painter.dart';
import '../world/shelter_map.dart';
import '../world/kitchen_painter.dart';
import '../world/hedge_garden_painter.dart';
import '../world/playroom_painter.dart';
import '../world/attic_painter.dart';
import '../world/yard_painter.dart';
import '../world/storm_station_painter.dart';

class ShelterGardenComponent extends PositionComponent {
  ShelterGardenComponent({required this.isPlaying, required this.map})
      : super(priority: -100);
  final bool Function() isPlaying;
  final ShelterMap Function() map;

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
        ShelterMapKind.kitchen => const KitchenPainter(),
        ShelterMapKind.hedge => const HedgeGardenPainter(),
        ShelterMapKind.playroom => const PlayroomPainter(),
        ShelterMapKind.attic => const AtticPainter(),
        ShelterMapKind.yard => const YardPainter(),
        ShelterMapKind.storm => const StormStationPainter(),
      };
      painter.paint(Canvas(recorder), Size(size.x, size.y));
      _background = recorder.endRecording();
      _backgroundKind = kind;
    }
    // Map obstacles are static and live in the cached background.
    canvas.drawPicture(_background!);
    // Butterflies belong outdoors.
    if (kind == ShelterMapKind.kitchen ||
        kind == ShelterMapKind.playroom ||
        kind == ShelterMapKind.attic ||
        kind == ShelterMapKind.storm) {
      return;
    }
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
}
