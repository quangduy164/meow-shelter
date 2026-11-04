import 'package:flutter/painting.dart';

/// Screen-space text drawn by the game: progress, pickups, checkpoint notices
/// and the result card.
void paintReturnHomeHud(
  Canvas canvas, {
  required Size size,
  required double progress,
  required int lives,
  required int fish,
  required double elapsed,
  required int stars,
  required bool checkpoint,
  required bool finished,
}) {
  final hearts = List.filled(lives, '♥').join(' ');
  final hud = TextPainter(
    text: TextSpan(
      text:
          'VỀ NHÀ ${(progress * 100).round()}%   $hearts   🐟 $fish   ${elapsed.toStringAsFixed(1)}s',
      style: const TextStyle(
          color: Color(0xFF3B2415), fontSize: 17, fontWeight: FontWeight.w900),
    ),
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: size.width - 90);
  hud.paint(canvas, const Offset(18, 16));
  if (checkpoint && !finished) {
    _center(canvas, size, 'ĐÃ LƯU CHECKPOINT', size.height * .20, 22);
  }
  if (!finished) return;
  final card = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * .32),
      width: 330,
      height: 128);
  canvas.drawRRect(RRect.fromRectAndRadius(card, const Radius.circular(18)),
      Paint()..color = const Color(0xF2FFF3D8));
  canvas.drawRRect(
      RRect.fromRectAndRadius(card, const Radius.circular(18)),
      Paint()
        ..color = const Color(0xFF9A6028)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3);
  _center(canvas, size, 'ĐÃ VỀ ĐẾN NHÀ!', card.top + 18, 28);
  _center(
      canvas,
      size,
      List.generate(3, (i) => i < stars ? '★' : '☆').join(' '),
      card.top + 58,
      30);
  _center(canvas, size, '${elapsed.toStringAsFixed(1)} giây · $fish cá',
      card.top + 96, 16);
}

void _center(Canvas canvas, Size size, String text, double y, double fontSize) {
  final painter = TextPainter(
    text: TextSpan(
        text: text,
        style: TextStyle(
            color: const Color(0xFF573215),
            fontSize: fontSize,
            fontWeight: FontWeight.w900)),
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: size.width - 40);
  painter.paint(canvas, Offset((size.width - painter.width) / 2, y));
}
