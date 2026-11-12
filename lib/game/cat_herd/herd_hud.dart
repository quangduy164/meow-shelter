import 'dart:math' as math;
import 'package:flutter/painting.dart';
import 'herd_round.dart';

/// Lives and the translucent tutorial caption share one top row.
void paintHerdHud(Canvas canvas, Size size, HerdRound round) {
  final lives = RRect.fromRectAndRadius(
      const Rect.fromLTWH(72, 17, 112, 38), const Radius.circular(14));
  canvas.drawRRect(lives.shift(const Offset(0, 2)),
      Paint()..color = const Color(0x33402616));
  canvas.drawRRect(lives, Paint()..color = const Color(0xF2FFF4DA));
  canvas.drawRRect(
      lives,
      Paint()
        ..color = const Color(0xFFB27A3E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5);
  for (var i = 0; i < 3; i++) {
    final center = Offset(128 + (i - 1) * 30, 36);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(.75);
    final heart = Path()
      ..moveTo(0, 12)
      ..cubicTo(-25, -3, -12, -20, 0, -8)
      ..cubicTo(12, -20, 25, -3, 0, 12)
      ..close();
    canvas.drawPath(
        heart,
        Paint()
          ..color = i < round.lives
              ? const Color(0xFFD96570)
              : const Color(0xFFD4C8B6));
    canvas.restore();
  }
  if (!round.isTutorial || round.ended) return;
  // Leave a clear gap after Home and the life pill, even on narrow tablets.
  final width = math.min(560.0, size.width - 208);
  final caption = TextPainter(
      text: TextSpan(
          text: round.tutorialInstruction,
          style: const TextStyle(
              color: Color(0xFF28564C),
              fontSize: 15,
              fontWeight: FontWeight.bold,
              height: 1.25,
              shadows: [Shadow(color: Color(0xCCFFF4DA), blurRadius: 3)])),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center)
    ..layout(maxWidth: width - 24);
  final centerX = (196 + size.width - 12) / 2;
  final box = Rect.fromCenter(
      center: Offset(centerX, 36), width: width, height: caption.height + 14);
  canvas.drawRRect(RRect.fromRectAndRadius(box, const Radius.circular(10)),
      Paint()..color = const Color(0xCCF1F8E7));
  caption.paint(
      canvas, Offset(centerX - caption.width / 2, 36 - caption.height / 2));
}
