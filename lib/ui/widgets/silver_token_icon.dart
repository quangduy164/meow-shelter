import 'package:flutter/material.dart';
import '../../game/silver_token_art.dart';

class SilverTokenIcon extends StatelessWidget {
  const SilverTokenIcon({super.key, this.size = 24});
  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Nguyệt quang',
        image: true,
        child: SizedBox.square(
            dimension: size,
            child: const CustomPaint(painter: _SilverTokenPainter())),
      );
}

class _SilverTokenPainter extends CustomPainter {
  const _SilverTokenPainter();
  @override
  void paint(Canvas canvas, Size size) =>
      paintSilverToken(canvas, Offset.zero & size);
  @override
  bool shouldRepaint(_SilverTokenPainter oldDelegate) => false;
}
