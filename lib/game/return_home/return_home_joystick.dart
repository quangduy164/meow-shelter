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
    const ink = Color(0xFF5A3214);
    final c = Offset(size.x / 2, size.y / 2);
    final r = size.x / 2 - 3;
    canvas.drawCircle(
        c + const Offset(0, 3), r, Paint()..color = const Color(0x40000000));
    canvas.drawCircle(c, r, Paint()..color = const Color(0xB3FFF4DA));
    canvas.drawCircle(
        c,
        r,
        Paint()
          ..color = const Color(0xFFB27A3E)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4);
    // Direction chevrons around the rim.
    final chevron = Paint()
      ..color = const Color(0xFFB27A3E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (var i = 0; i < 4; i++) {
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(i * 1.5707963);
      canvas.drawPath(
          Path()
            ..moveTo(r - 18, -7)
            ..lineTo(r - 11, 0)
            ..lineTo(r - 18, 7),
          chevron);
      canvas.restore();
    }
    final knob = c + Offset(delta.x, delta.y);
    canvas.drawCircle(knob + const Offset(0, 4), 26,
        Paint()..color = const Color(0xFFB8641E));
    canvas.drawCircle(knob, 26, Paint()..color = const Color(0xFFF5A04A));
    canvas.drawCircle(
        knob,
        26,
        Paint()
          ..color = ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5);
    final paw = Paint()..color = const Color(0xFFFFF4DA);
    canvas.drawOval(
        Rect.fromCenter(
            center: knob + const Offset(0, 5), width: 16, height: 13),
        paw);
    for (final toe in const [
      Offset(-9, -4),
      Offset(-3.5, -10),
      Offset(3.5, -10),
      Offset(9, -4),
    ]) {
      canvas.drawOval(
          Rect.fromCenter(center: knob + toe, width: 6, height: 7.5), paw);
    }
  }
}
