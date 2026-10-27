import 'package:flutter/material.dart';

import 'level_config.dart';
import 'level_select_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/Background/home-background.png',
            fit: BoxFit.cover,
          ),
          SafeArea(
            child: Center(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: SizedBox(
                    width: 430,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const _GameLogo(),
                        const SizedBox(height: 24),
                        _HomeButton(
                          label: 'BẮT ĐẦU',
                          icon: Icons.play_arrow_rounded,
                          onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                  builder: (_) =>
                                      GameScreen(level: gameLevels.first))),
                        ),
                        const SizedBox(height: 10),
                        _HomeButton(
                          label: 'CHỌN MÀN',
                          icon: Icons.grid_view_rounded,
                          secondary: true,
                          onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                  builder: (_) => const LevelSelectScreen())),
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          icon:
                              const Icon(Icons.help_outline_rounded, size: 18),
                          label: const Text('Cách chơi'),
                          style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF3B2415),
                              backgroundColor: const Color(0xE6FFF0CA)),
                          onPressed: () => showDialog<void>(
                              context: context,
                              builder: (context) => AlertDialog(
                                    backgroundColor: const Color(0xFFFFF3D8),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(24)),
                                    title: const Text('Cùng cứu mèo nhé!'),
                                    content: const Text(
                                        'Kéo mèo vào ổ đệm đúng loại để nhận điểm.\n\nChạm vào mèo sẽ khiến bé hoảng loạn rồi chạy trốn — hãy bắt kịp!\n\nThả sai hoặc để mèo chạy thoát sẽ mất một lượt. Cứu đủ mèo trước khi hết giờ để thắng.'),
                                    actions: [
                                      TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: const Text('ĐÃ HIỂU'))
                                    ],
                                  )),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GameLogo extends StatelessWidget {
  const _GameLogo();

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 108,
            height: 82,
            child: CustomPaint(painter: _ShelterCatLogoPainter()),
          ),
          const SizedBox(height: 2),
          const FittedBox(
            child: Text(
              'MEOW SHELTER',
              style: TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.w900,
                color: Color(0xFFFFE9B0),
                letterSpacing: 2,
                shadows: [
                  Shadow(
                    color: Color(0xFF573215),
                    offset: Offset(0, 3),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
          ),
        ],
      );
}

class _ShelterCatLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 4);
    final outline = Paint()
      ..color = const Color(0xFF573215)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    final fill = Paint()..color = const Color(0xFFFFC24D);
    final cream = Paint()..color = const Color(0xFFFFE9B0);

    final roof = Path()
      ..moveTo(10, 43)
      ..lineTo(size.width / 2, 7)
      ..lineTo(size.width - 10, 43)
      ..lineTo(size.width - 19, 43)
      ..lineTo(size.width - 19, 73)
      ..lineTo(19, 73)
      ..lineTo(19, 43)
      ..close();
    canvas.drawPath(roof, fill);
    canvas.drawPath(roof, outline);

    final cat = Path()
      ..moveTo(center.dx - 28, 58)
      ..lineTo(center.dx - 28, 37)
      ..lineTo(center.dx - 18, 25)
      ..lineTo(center.dx - 8, 35)
      ..quadraticBezierTo(center.dx, 31, center.dx + 8, 35)
      ..lineTo(center.dx + 18, 25)
      ..lineTo(center.dx + 28, 37)
      ..lineTo(center.dx + 28, 58)
      ..quadraticBezierTo(center.dx, 75, center.dx - 28, 58)
      ..close();
    canvas.drawPath(cat, cream);
    canvas.drawPath(cat, outline);

    final eye = Paint()..color = const Color(0xFF573215);
    canvas.drawCircle(Offset(center.dx - 10, 48), 2.5, eye);
    canvas.drawCircle(Offset(center.dx + 10, 48), 2.5, eye);
    canvas.drawLine(Offset(center.dx, 52), Offset(center.dx, 55), outline);
    canvas.drawArc(
      Rect.fromCenter(center: Offset(center.dx, 55), width: 10, height: 7),
      0.2,
      2.7,
      false,
      outline,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HomeButton extends StatelessWidget {
  const _HomeButton(
      {required this.label,
      required this.icon,
      required this.onPressed,
      this.secondary = false});
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool secondary;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 260,
        height: 50,
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 24),
          label: Text(label),
          style: ElevatedButton.styleFrom(
            backgroundColor:
                secondary ? const Color(0xFFFFF0CA) : const Color(0xFFFFC24D),
            foregroundColor: const Color(0xFF603312),
            elevation: 5,
            textStyle: const TextStyle(
                fontSize: 17, fontWeight: FontWeight.w900, letterSpacing: 1),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: const BorderSide(color: Color(0xFF9A6028), width: 2)),
          ),
        ),
      );
}
