import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

enum RoundStatus { playing, won, lost }

class HudComponent extends PositionComponent {
  HudComponent() : super(priority: 100);

  int score = 0;
  int lives = 3;
  int delivered = 0;
  int totalCats = 8;
  int secondsLeft = 90;
  RoundStatus status = RoundStatus.playing;

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final panel = Paint()..color = const Color(0xCC432812);
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(16, 16, 330, 64), const Radius.circular(16)),
      panel,
    );
    _drawText(
      canvas,
      'Điểm: $score     Lượt: $lives     Mèo: $delivered/$totalCats     ${secondsLeft}s',
      const Offset(30, 36),
      22,
      const Color(0xFFFFFFFF),
    );

    if (status == RoundStatus.playing) return;
    final isWin = status == RoundStatus.won;
    final overlay = Paint()..color = const Color(0xAA000000);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), overlay);
    final title = isWin ? 'BẠN ĐÃ THẮNG!' : 'HẾT LƯỢT!';
    final subtitle = isWin
        ? 'Đã đưa đủ mèo về đúng chuồng'
        : 'Thử lại để cứu các bé mèo nhé';
    _drawCentered(canvas, title, size.y * 0.40, 44, isWin ? const Color(0xFFFFE373) : const Color(0xFFFFA0A0));
    _drawCentered(canvas, subtitle, size.y * 0.49, 24, const Color(0xFFFFFFFF));
    final button = Rect.fromCenter(
      center: Offset(size.x / 2, size.y * 0.61),
      width: 220,
      height: 58,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(button, const Radius.circular(18)),
      Paint()..color = const Color(0xFFFFB52A),
    );
    _drawCentered(canvas, 'CHƠI LẠI', size.y * 0.61 - 14, 26, const Color(0xFF57300F));
  }

  void _drawText(Canvas canvas, String text, Offset offset, double fontSize, Color color) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize, fontWeight: FontWeight.bold)),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, offset);
  }

  void _drawCentered(Canvas canvas, String text, double y, double fontSize, Color color) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: fontSize, fontWeight: FontWeight.bold)),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, Offset((size.x - painter.width) / 2, y));
  }
}
