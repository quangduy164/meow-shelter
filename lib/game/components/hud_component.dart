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
  bool isTutorial = false;

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (status != RoundStatus.playing) return;
    // Dùng kích thước canvas hiện tại thay vì kích thước lúc HUD được tạo.
    // Điều này giữ màn thắng/thua ở giữa khi thiết bị xoay hoặc đổi tỉ lệ màn hình.
    final screenSize = gameRef.size;
    final panel = Paint()..color = const Color(0xCC432812);
    const panelWidth = 100.0;
    const panelHeight = 40.0;
    final panelLeft = (screenSize.x - panelWidth) / 2;
    if (!isTutorial) {
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
    }
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
