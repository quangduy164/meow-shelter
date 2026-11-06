import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/painting.dart';
import '../cats/cat_catch_rule.dart';
import 'cat_component.dart';
import 'shelter_zone_component.dart';

/// Guided hints for a practice round: one caption plus an animated arrow or
/// ring that shows exactly what to do next for this breed.
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
    final type = kitten.catType;
    final name = CatCatchRule.names[type]!;
    final center = kitten.position + kitten.size / 2;
    final bottom = Vector2(screen.x / 2, screen.y - 32);
    final fed = kitten.hasEaten;
    final approaching = kitten.fishTarget != null;

    String text;
    Vector2? from, to;
    var ring = false;
    if (fed) {
      text = type == 'orange'
          ? 'Mèo cam no bụng ngủ khò rồi! Giữ và kéo bé vào ổ'
          : type == 'calico'
              ? 'Tam thể chơi mệt rồi! Giữ và kéo bé vào ổ'
              : 'Thanh xanh hiện rồi! Giữ và kéo $name vào ổ';
      final bed = shelter();
      from = center;
      to = bed.position + Vector2(bed.size.x * .5, bed.size.y * .45);
    } else if (approaching) {
      text = '$name đang đến ăn cá…';
    } else {
      switch (type) {
        case 'himalaya':
          text = 'Himalaya nhút nhát: thả cá NGOÀI vòng tròn, xa bé ra';
          _drawShyZone(canvas, center);
          from = bottom;
          to = center + Vector2(-CatCatchRule.shyDistance - 50, 50);
        case 'scottish':
          text = kitten.meals == 0
              ? 'Scottish kén ăn: cho bé ăn 2 con cá'
              : 'Mới ${kitten.meals}/2 thôi! Thả thêm 1 con cá nữa';
          from = bottom;
          to = center;
        case 'calico':
          text = 'Tam thể không thèm cá! Chạm vào bé 3 lần '
              '(${kitten.playTaps}/${CatCatchRule.calicoTaps})';
          to = center;
          ring = true;
        case 'black':
          text = 'Mèo đen cô độc: chỉ ăn cá ở chỗ không có mèo khác';
          from = bottom;
          to = center + Vector2(0, 40);
        default:
          text = 'Mèo cam ham ăn: kéo cá ở dưới đến cạnh bé để cho ăn';
          from = bottom;
          to = center;
      }
    }
    _caption(canvas, screen, text);
    if (to == null) return;
    final pen = Paint()
      ..color = const Color(0xCCFFF0A2)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    if (from != null && !approaching) _arrow(canvas, from, to, pen);
    final bed = shelter();
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(to.x, to.y + (fed ? 12 : 0)),
            width: fed ? bed.size.x * .88 : (ring ? 96 : 76),
            height: fed ? bed.size.y * .55 : (ring ? 96 : 42)),
        pen
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2 + math.sin(_clock * (ring ? 8 : 3)) * .8);
  }

  void _caption(Canvas canvas, Vector2 screen, String text) {
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
  }

  /// Red dashed ring: dropping fish inside it startles the Himalaya.
  void _drawShyZone(Canvas canvas, Vector2 center) {
    final paint = Paint()
      ..color = const Color(0xAAE05A4F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    const dashes = 28;
    for (var i = 0; i < dashes; i++) {
      final a = i * 2 * math.pi / dashes + _clock * .3;
      canvas.drawArc(
          Rect.fromCircle(
              center: Offset(center.x, center.y),
              radius: CatCatchRule.shyDistance),
          a,
          math.pi / dashes,
          false,
          paint);
    }
  }

  void _arrow(Canvas canvas, Vector2 from, Vector2 to, Paint pen) {
    final delta = to - from;
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
}
