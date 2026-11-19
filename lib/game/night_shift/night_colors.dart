import 'dart:math' as math;
import 'package:flutter/painting.dart';

/// One strong colour per breed for night-map signs, flags and docks. The
/// breeds' coat colours (orange, calico, Scottish) are too close to tell apart
/// at a glance, so signage uses clearly separate hues.
Color nightBreedColor(String? breed) => switch (breed) {
      'orange' => const Color(0xFFF07A2A),
      'black' => const Color(0xFF3C4450),
      'himalaya' => const Color(0xFF59B7D0),
      'scottish' => const Color(0xFF8B66B8),
      'calico' => const Color(0xFFE0566E),
      _ => const Color(0xFF7C8790),
    };

/// A white shape per breed drawn on top of [nightBreedColor], so a sign still
/// reads without relying on colour alone: orange ●, black ▲, himalaya ◆,
/// Scottish ■, calico ★.
void paintBreedMark(Canvas canvas, Offset c, double r, String? breed) {
  final fill = Paint()..color = const Color(0xFFFFF4DA);
  switch (breed) {
    case 'orange':
      canvas.drawCircle(c, r * .8, fill);
    case 'black':
      canvas.drawPath(
          Path()
            ..moveTo(c.dx, c.dy - r)
            ..lineTo(c.dx + r * .95, c.dy + r * .75)
            ..lineTo(c.dx - r * .95, c.dy + r * .75)
            ..close(),
          fill);
    case 'himalaya':
      canvas.drawPath(
          Path()
            ..moveTo(c.dx, c.dy - r)
            ..lineTo(c.dx + r * .8, c.dy)
            ..lineTo(c.dx, c.dy + r)
            ..lineTo(c.dx - r * .8, c.dy)
            ..close(),
          fill);
    case 'scottish':
      canvas.drawRect(
          Rect.fromCenter(center: c, width: r * 1.45, height: r * 1.45), fill);
    case 'calico':
      final star = Path();
      for (var i = 0; i < 10; i++) {
        final rr = i.isEven ? r : r * .45;
        final a = -math.pi / 2 + i * math.pi / 5;
        final p = c + Offset(math.cos(a), math.sin(a)) * rr;
        i == 0 ? star.moveTo(p.dx, p.dy) : star.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(star..close(), fill);
    default:
      canvas.drawCircle(c, r * .35, fill);
  }
}
