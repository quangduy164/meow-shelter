import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/painting.dart';

class FishingPondComponent extends PositionComponent with TapCallbacks {
  FishingPondComponent({required this.isPlaying, required this.onCatch})
      : super(size: Vector2(140, 68), priority: 20);

  final bool Function() isPlaying;
  final void Function() onCatch;
  double _remaining = 0;
  double _feedback = 0;

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    position.setValues((size.x - this.size.x) / 2, size.y * .23);
  }

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    if (!isPlaying() || _remaining > 0) return;
    _remaining = 1.2;
    _feedback = 0;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!isPlaying()) return;
    _feedback = (_feedback - dt).clamp(0.0, 1.0);
    if (_remaining <= 0) return;
    _remaining -= dt;
    if (_remaining <= 0) {
      onCatch();
      _feedback = 1;
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    canvas.drawOval(Rect.fromLTWH(0, 0, size.x, size.y),
        Paint()..color = const Color(0xFFB5AD84));
    canvas.drawOval(Rect.fromLTWH(6, 5, size.x - 12, size.y - 10),
        Paint()..color = const Color(0xFF277EAD));
    canvas.drawOval(Rect.fromLTWH(12, 9, size.x - 24, size.y - 24),
        Paint()..color = const Color(0xFF5DCBD4));
    canvas.drawOval(const Rect.fromLTWH(20, 20, 24, 10),
        Paint()..color = const Color(0xFF74A83B));
    final center = Offset(size.x / 2, size.y / 2 - 4);
    if (_remaining > 0) {
      canvas.drawCircle(
          center,
          8 + (1.2 - _remaining) * 8,
          Paint()
            ..color = const Color(0xAAFFFFFF)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
      canvas.drawLine(
          const Offset(120, 0),
          center,
          Paint()
            ..color = const Color(0xFF56432C)
            ..strokeWidth = 2);
      canvas.drawCircle(center, 4, Paint()..color = const Color(0xFFFA7454));
    }
    final label = TextPainter(
      text: TextSpan(
          text: _remaining > 0
              ? 'Đang câu…'
              : _feedback > 0
                  ? '+1 cá!'
                  : 'Câu cá',
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFFFFFF))),
      textDirection: TextDirection.ltr,
    )..layout();
    label.paint(canvas, Offset((size.x - label.width) / 2, size.y - 22));
  }
}
