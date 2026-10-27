import 'package:flutter/painting.dart';

import 'package:flame/components.dart';
import 'package:flame/events.dart';

void drawFish(Canvas canvas, Offset center) {
  final body = Paint()..color = const Color(0xFF53C9EF);
  canvas.drawOval(Rect.fromCenter(center: center, width: 30, height: 17), body);
  canvas.drawPath(
      Path()
        ..moveTo(center.dx - 12, center.dy)
        ..lineTo(center.dx - 24, center.dy - 11)
        ..lineTo(center.dx - 24, center.dy + 11)
        ..close(),
      body);
  canvas.drawCircle(center + const Offset(8, -2), 2,
      Paint()..color = const Color(0xFF173D51));
}

class FishItemComponent extends PositionComponent with DragCallbacks {
  FishItemComponent(
      {required this.enabled, required this.visible, required this.placeFish})
      : super(size: Vector2(64, 48), priority: 90);

  final bool Function() enabled;
  final bool Function() visible;
  final void Function(Vector2) placeFish;
  Vector2? _preview;

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    position.setValues((size.x - this.size.x) / 2, size.y - this.size.y - 8);
  }

  @override
  void render(Canvas canvas) {
    if (!visible()) return;
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(0, 0, size.x, size.y), const Radius.circular(14)),
        Paint()
          ..color =
              enabled() ? const Color(0xFFFFD477) : const Color(0xFF8B8170));
    drawFish(canvas, Offset(size.x / 2 + 3, size.y / 2));
    final preview = _preview;
    if (preview != null) drawFish(canvas, Offset(preview.x, preview.y));
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    if (enabled()) _preview = event.localPosition.clone();
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    _preview?.add(event.canvasDelta);
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    final preview = _preview;
    _preview = null;
    if (preview != null &&
        enabled() &&
        !Rect.fromLTWH(0, 0, size.x, size.y)
            .contains(Offset(preview.x, preview.y))) {
      placeFish(position + preview);
    }
  }

  @override
  void onDragCancel(DragCancelEvent event) {
    super.onDragCancel(event);
    _preview = null;
  }
}
