import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flutter/painting.dart';
import '../world/shelter_garden_painter.dart';

class ShelterGardenComponent extends PositionComponent {
  ShelterGardenComponent({required this.isPlaying}) : super(priority: -100);
  final bool Function() isPlaying;
  ui.Picture? _background;
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
    if (_background == null) {
      final recorder = ui.PictureRecorder();
      const ShelterGardenPainter()
          .paint(Canvas(recorder), Size(size.x, size.y));
      _background = recorder.endRecording();
    }
    canvas.drawPicture(_background!);
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

  @override
  void onRemove() {
    _background?.dispose();
    _background = null;
    super.onRemove();
  }
}
