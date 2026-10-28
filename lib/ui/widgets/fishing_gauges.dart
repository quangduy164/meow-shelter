import 'dart:math' as math;

import 'package:flutter/material.dart';

class FishingGauge extends StatelessWidget {
  const FishingGauge({super.key, required this.value, this.tension = false});
  final double value;
  final bool tension;

  @override
  Widget build(BuildContext context) {
    final color = tension
        ? (value > .8 ? const Color(0xFFD94D42) : const Color(0xFF966022))
        : const Color(0xFF166B75);
    final percent = ((tension ? value : 1 - value) * 100).round();
    return Semantics(
      label: tension ? 'Lực căng dây' : 'Khoảng cách còn lại',
      value: '$percent phần trăm',
      child: SizedBox(
          width: 100,
          height: 112,
          child: Column(children: [
            SizedBox(
                width: 84,
                height: 84,
                child: CustomPaint(
                  painter: _GaugePainter(value: value, tension: tension),
                  child: Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(tension ? Icons.bolt_rounded : Icons.set_meal_rounded,
                        size: 18, color: color),
                    Text('$percent%',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: color)),
                  ])),
                )),
            const SizedBox(height: 4),
            Text(tension ? 'CĂNG DÂY' : 'CÁCH BỜ',
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF253F36))),
          ])),
    );
  }
}

class _GaugePainter extends CustomPainter {
  const _GaugePainter({required this.value, required this.tension});
  final double value;
  final bool tension;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 6;
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawCircle(center + const Offset(0, 2), radius + 5,
        Paint()..color = const Color(0x22522F18));
    canvas.drawCircle(
        center, radius + 4, Paint()..color = const Color(0xF7FFF8E6));
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    if (tension) {
      const start = math.pi * .75;
      const sweep = math.pi * 1.5;
      for (final zone in [
        (0.0, .55, const Color(0xFF448D72)),
        (.58, .79, const Color(0xFFE3AF42)),
        (.82, 1.0, const Color(0xFFD94D42)),
      ]) {
        canvas.drawArc(rect, start + zone.$1 * sweep,
            (zone.$2 - zone.$1) * sweep, false, stroke..color = zone.$3);
      }
      final angle = start + value * sweep;
      final direction = Offset(math.cos(angle), math.sin(angle));
      final sideways = Offset(-direction.dy, direction.dx);
      canvas.drawPath(
          Path()
            ..moveTo((center + direction * (radius + 5)).dx,
                (center + direction * (radius + 5)).dy)
            ..lineTo((center + direction * (radius - 10) + sideways * 4).dx,
                (center + direction * (radius - 10) + sideways * 4).dy)
            ..lineTo((center + direction * (radius - 10) - sideways * 4).dx,
                (center + direction * (radius - 10) - sideways * 4).dy)
            ..close(),
          Paint()..color = const Color(0xFF4B352A));
    } else {
      canvas.drawCircle(
          center, radius, stroke..color = const Color(0xFFD4E4DC));
      canvas.drawArc(rect, -math.pi / 2, value * math.pi * 2, false,
          stroke..color = const Color(0xFF21858B));
      final angle = -math.pi / 2 + value * math.pi * 2;
      canvas.drawCircle(
          center + Offset(math.cos(angle), math.sin(angle)) * radius,
          4,
          Paint()..color = const Color(0xFFFFC55C));
    }
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) =>
      value != oldDelegate.value || tension != oldDelegate.tension;
}
