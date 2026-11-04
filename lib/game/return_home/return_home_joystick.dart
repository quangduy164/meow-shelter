import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/painting.dart';

/// Thumb stick pinned to the viewport: it only reports a normalized delta, so
/// whatever reads it decides what a full push means.
class ReturnHomeJoystick extends PositionComponent with DragCallbacks {
  ReturnHomeJoystick({required Vector2 position})
      : super(
            position: position,
            size: Vector2.all(116),
            anchor: Anchor.center,
            priority: 20);

  final Vector2 delta = Vector2.zero();
  static const double _radius = 34.0;

  Vector2 get relativeDelta => delta / _radius;

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    delta.setFrom(event.localPosition - size / 2);
    _clampDelta();
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    delta.add(event.localDelta);
    _clampDelta();
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    delta.setZero();
  }

  @override
  void onDragCancel(DragCancelEvent event) {
    super.onDragCancel(event);
    delta.setZero();
  }

  void _clampDelta() {
    if (delta.length > _radius) delta.scaleTo(_radius);
  }

  @override
  void render(Canvas canvas) {
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), size.x / 2,
        Paint()..color = const Color(0x887A5B42));
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), size.x / 2 - 4,
        Paint()..color = const Color(0x55FFF0CA));
    final knob = Offset(size.x / 2 + delta.x, size.y / 2 + delta.y);
    canvas.drawCircle(knob, 29, Paint()..color = const Color(0xFFD88B45));
    canvas.drawCircle(knob + const Offset(-7, -8), 6,
        Paint()..color = const Color(0x66FFF5D5));
  }
}
