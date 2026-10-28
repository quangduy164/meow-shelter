import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/painting.dart';
import 'cat_component.dart';
import 'shelter_zone_component.dart';

class CatchTutorialComponent extends PositionComponent {
  CatchTutorialComponent(
      {required this.cat,
      required this.shelter,
      required this.screenSize,
      required this.isPlaying})
      : super(priority: 85);
  final CatComponent? Function() cat;
  final ShelterZoneComponent Function() shelter;
  final Vector2 Function() screenSize;
  final bool Function() isPlaying;
  double _clock = 0;

  @override
  void update(double dt) {
    super.update(dt);
    if (isPlaying()) _clock += dt;
  }

  @override
  void render(Canvas canvas) {
    final kitten = cat();
    if (!isPlaying() || kitten == null || kitten.isDelivered) return;
    final screen = screenSize();
    final fed = kitten.hasEaten;
    final approaching = kitten.fishTarget != null;
    final text = fed
        ? '2. Giữ và kéo mèo vào ổ màu cam'
        : approaching
            ? 'Mèo đang đến ăn cá…'
            : '1. Kéo cá ở dưới đến cạnh mèo để cho ăn';
    final caption = TextPainter(
        text: TextSpan(
            text: text,
            style: const TextStyle(
                color: Color(0xFF28564C),
                fontSize: 15,
                fontWeight: FontWeight.bold)),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr)
      ..layout(maxWidth: screen.x * .68);
    final box = Rect.fromLTWH((screen.x - caption.width) / 2 - 12, 66,
        caption.width + 24, caption.height + 16);
    canvas.drawRRect(RRect.fromRectAndRadius(box, const Radius.circular(8)),
        Paint()..color = const Color(0xF0F1F8E7));
    caption.paint(canvas, Offset(box.left + 12, box.top + 8));
    final bed = shelter();
    final from = fed
        ? kitten.position + kitten.size / 2
        : Vector2(screen.x / 2, screen.y - 32);
    final to = fed
        ? bed.position + Vector2(bed.size.x * .5, bed.size.y * .45)
        : kitten.position + kitten.size / 2;
    final delta = to - from;
    final pen = Paint()
      ..color = const Color(0xCCFFF0A2)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    if (!approaching) {
      for (var i = 0; i < 10; i++) {
        final t = (i / 10 + _clock * .15) % 1;
        final p = from + delta * t;
        canvas.drawCircle(Offset(p.x, p.y), 2.5, pen);
      }
      final angle = math.atan2(delta.y, delta.x);
      for (final side in [-.5, .5]) {
        canvas.drawLine(
            Offset(to.x, to.y),
            Offset(to.x - math.cos(angle + side) * 14,
                to.y - math.sin(angle + side) * 14),
            pen);
      }
    }
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(to.x, to.y + 12),
            width: fed ? bed.size.x * .88 : 76,
            height: fed ? bed.size.y * .55 : 42),
        pen
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2 + math.sin(_clock * 3) * .6);
  }
}
