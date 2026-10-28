import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/painting.dart';

enum RoundStatus { playing, won, lost }

class HudComponent extends PositionComponent with HasGameRef<FlameGame> {
  HudComponent() : super(priority: 100);

  int delivered = 0;
  int totalCats = 8;
  int secondsLeft = 90;
  String levelTitle = 'MÀN 1 · LÀM QUEN';
  RoundStatus status = RoundStatus.playing;

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    // Dùng kích thước canvas hiện tại thay vì kích thước lúc HUD được tạo.
    // Điều này giữ màn thắng/thua ở giữa khi thiết bị xoay hoặc đổi tỉ lệ màn hình.
    final screenSize = gameRef.size;
    final panel = Paint()..color = const Color(0xCC432812);
    const panelWidth = 100.0;
    const panelHeight = 40.0;
    final panelLeft = (screenSize.x - panelWidth) / 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(panelLeft, 14, panelWidth, panelHeight),
        const Radius.circular(14),
      ),
      panel,
    );
    _drawCentered(
      canvas,
      '${secondsLeft}s',
      screenSize,
      22,
      18,
      const Color(0xFFFFFFFF),
    );

    if (status == RoundStatus.playing) return;
    final isWin = status == RoundStatus.won;
    final overlay = Paint()..color = const Color(0xAA000000);
    canvas.drawRect(Rect.fromLTWH(0, 0, screenSize.x, screenSize.y), overlay);
    final title = isWin ? 'BẠN ĐÃ THẮNG!' : 'HẾT GIỜ!';
    final subtitle = isWin
        ? 'Đã đưa đủ mèo về đúng chuồng'
        : 'Thử lại để cứu các bé mèo nhé';
    _drawCentered(
      canvas,
      title,
      screenSize,
      screenSize.y * 0.34,
      42,
      isWin ? const Color(0xFFFFE373) : const Color(0xFFFFA0A0),
    );
    _drawCentered(
      canvas,
      subtitle,
      screenSize,
      screenSize.y * 0.46,
      21,
      const Color(0xFFFFFFFF),
    );
    final button = Rect.fromCenter(
      center: Offset(screenSize.x / 2, screenSize.y * 0.64),
      width: 220,
      height: 58,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(button, const Radius.circular(18)),
      Paint()..color = const Color(0xFFFFB52A),
    );
    _drawCentered(
      canvas,
      'CHƠI LẠI',
      screenSize,
      screenSize.y * 0.64 - 15,
      24,
      const Color(0xFF57300F),
    );
  }

  void _drawCentered(
    Canvas canvas,
    String text,
    Vector2 screenSize,
    double y,
    double fontSize,
    Color color,
  ) {
    final painter = TextPainter(
      text: TextSpan(
          text: text,
          style: TextStyle(
              color: color, fontSize: fontSize, fontWeight: FontWeight.bold)),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, Offset((screenSize.x - painter.width) / 2, y));
  }
}
