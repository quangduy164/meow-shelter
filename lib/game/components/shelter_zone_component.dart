import 'package:flutter/painting.dart';

import 'package:flame/components.dart';

import 'cat_component.dart';

/// Low floor mat, rendered below cats, with its own separate name badge.
class ShelterZoneComponent extends PositionComponent {
  ShelterZoneComponent({
    required this.label,
    required super.position,
    required super.size,
    required this.catType,
  }) : super(priority: -10);

  final String catType;
  final String label;

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final color = switch (catType) {
      'orange' => const Color(0xFFF5AF4D),
      'himalaya' => const Color(0xFFB4A0DC),
      'scottish' => const Color(0xFF79B7C4),
      'calico' => const Color(0xFFEF9BB2),
      _ => const Color(0xFF777483),
    };
    final mat =
        Rect.fromLTWH(size.x * .08, size.y * .26, size.x * .84, size.y * .42);
    canvas.drawOval(mat.shift(const Offset(0, 3)),
        Paint()..color = const Color(0x443D341D));
    canvas.drawOval(mat, Paint()..color = color);
    canvas.drawOval(
        mat,
        Paint()
          ..color = const Color(0xFF70513A)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
    canvas.drawOval(
        mat.deflate(5),
        Paint()
          ..color = const Color(0x88FFF5D8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
    final paw = Paint()..color = const Color(0xBBFFF4DF);
    final center = mat.center;
    final unit = mat.height * .16;
    canvas.drawOval(
        Rect.fromCenter(
            center: center + Offset(0, unit * .6),
            width: unit * 2.5,
            height: unit * 1.8),
        paw);
    for (final toe in [
      const Offset(-1.5, -.5),
      const Offset(-.55, -1.3),
      const Offset(.55, -1.3),
      const Offset(1.5, -.5)
    ]) {
      canvas.drawOval(
          Rect.fromCenter(
              center: center + toe * unit,
              width: unit * .85,
              height: unit * 1.1),
          paw);
    }
    final text = TextPainter(
        text: TextSpan(
            text: label,
            style: const TextStyle(
                color: Color(0xFF5B3516),
                fontSize: 12,
                fontWeight: FontWeight.bold)),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center)
      ..layout(maxWidth: size.x * .85);
    final badge = Rect.fromLTWH((size.x - text.width - 16) / 2, mat.bottom + 7,
        text.width + 16, text.height + 6);
    canvas.drawRRect(RRect.fromRectAndRadius(badge, const Radius.circular(8)),
        Paint()..color = const Color(0xFFFFEBC5));
    text.paint(canvas, Offset(badge.left + 8, badge.top + 3));
  }

  bool accepts(CatComponent cat) {
    if (cat.catType != catType) return false;
    final catCenter = cat.position + cat.size / 2;
    // Mở rộng hitbox lên cao để thả mèo từ phía trên xuống vẫn được nhận ngay.
    final bedCenter = position + Vector2(size.x * 0.5, size.y * 0.38);
    final bedSize = Vector2(size.x * 1.05, size.y * 1.18);
    final bed = Rect.fromCenter(
      center: Offset(bedCenter.x, bedCenter.y),
      width: bedSize.x,
      height: bedSize.y,
    );
    return bed.contains(Offset(catCenter.x, catCenter.y));
  }
}
