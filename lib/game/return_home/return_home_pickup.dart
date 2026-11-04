import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

enum ReturnHomePickupKind { fish, heart }

/// Small optional rewards on the road. They give the player a reason to choose
/// a risky line instead of only walking straight home.
class ReturnHomePickup extends PositionComponent {
  ReturnHomePickup({required this.kind, required Vector2 position})
      : super(position: position, size: Vector2.all(30), anchor: Anchor.center);

  final ReturnHomePickupKind kind;
  double _time = 0;

  bool hits(Rect cat) => cat.overlaps(Rect.fromCenter(
      center: Offset(position.x, position.y), width: 24, height: 22));

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
  }

  @override
  void render(Canvas canvas) {
    canvas.save();
    canvas.translate(size.x / 2, size.y / 2 + sin(_time * 4) * 2);
    canvas.drawOval(const Rect.fromLTWH(-11, 10, 22, 5),
        Paint()..color = const Color(0x334B392C));
    if (kind == ReturnHomePickupKind.fish) {
      canvas.drawOval(const Rect.fromLTWH(-11, -6, 20, 12),
          Paint()..color = const Color(0xFF4F9EA0));
      canvas.drawPath(
          Path()
            ..moveTo(-9, 0)
            ..lineTo(-17, -7)
            ..lineTo(-16, 7)
            ..close(),
          Paint()..color = const Color(0xFF3D8189));
      canvas.drawCircle(
          const Offset(4, -2), 1.6, Paint()..color = const Color(0xFF203A3D));
    } else {
      final heart = Path()
        ..moveTo(0, 10)
        ..cubicTo(-16, 0, -12, -12, 0, -5)
        ..cubicTo(12, -12, 16, 0, 0, 10)
        ..close();
      canvas.drawPath(heart, Paint()..color = const Color(0xFFE85D6F));
      canvas.drawCircle(
          const Offset(-4, -4), 2.5, Paint()..color = const Color(0x99FFFFFF));
    }
    canvas.restore();
  }
}
