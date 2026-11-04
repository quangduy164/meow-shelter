import 'package:flutter/material.dart';

const _ink = Color(0xFF5A3214);
const _cream = Color(0xFFFFF4DA);
const _orange = Color(0xFFF08A3A);

/// Simple home logo: the app's cat-head badge next to the game name.
class GameLogo extends StatelessWidget {
  const GameLogo({super.key});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox.square(
              dimension: 96, child: CustomPaint(painter: CatBadgePainter())),
          const SizedBox(width: 14),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(children: [
                Text('MEOW',
                    style: _title.copyWith(
                        foreground: Paint()
                          ..style = PaintingStyle.stroke
                          ..strokeWidth = 10
                          ..strokeJoin = StrokeJoin.round
                          ..color = _ink)),
                Text('MEOW', style: _title.copyWith(color: _cream)),
              ]),
              const SizedBox(height: 2),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                decoration: BoxDecoration(
                    color: _ink, borderRadius: BorderRadius.circular(8)),
                child: const Text('SHELTER',
                    style: TextStyle(
                        color: _cream,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 6)),
              ),
            ],
          ),
        ],
      );

  static const _title =
      TextStyle(fontSize: 60, fontWeight: FontWeight.w900, height: 1);
}

/// Same artwork as the Android launcher icon, in a 108x108 viewport.
class CatBadgePainter extends CustomPainter {
  const CatBadgePainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 108, size.height / 108);
    canvas.drawCircle(const Offset(54, 56), 52, Paint()..color = _ink);
    canvas.drawCircle(const Offset(54, 54), 50, Paint()..color = _orange);
    final cream = Paint()..color = _cream;
    canvas.drawOval(
        Rect.fromCenter(center: const Offset(54, 66), width: 36, height: 30),
        cream);
    for (final toe in const [
      Offset(33, 45),
      Offset(46, 33),
      Offset(62, 33),
      Offset(75, 45),
    ]) {
      canvas.drawOval(
          Rect.fromCenter(center: toe, width: 14, height: 18), cream);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CatBadgePainter oldDelegate) => false;
}
