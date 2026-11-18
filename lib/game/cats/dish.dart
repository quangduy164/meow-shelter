import 'dart:math' as math;
import 'package:flutter/painting.dart';

import '../components/fish_item_component.dart' show drawFish;

/// What the tray hands out. Outside the kitchen and playroom chapters every
/// bait is plain fish. [yarn] is a toy: Calico plays with it, nobody eats it.
enum Dish {
  fish('Cá'),
  shrimp('Tôm'),
  salmon('Cá hồi'),
  yarn('Cuộn len');

  const Dish(this.label);
  final String label;

  /// The three kitchen dishes a Scottish can order.
  static const foods = [fish, shrimp, salmon];
}

/// Draws [dish] centred on [center], about the size of the plain fish.
void drawDish(Canvas canvas, Offset center, Dish dish) {
  switch (dish) {
    case Dish.fish:
      drawFish(canvas, center);
    case Dish.shrimp:
      _shrimp(canvas, center);
    case Dish.salmon:
      _salmon(canvas, center);
    case Dish.yarn:
      drawYarn(canvas, center);
  }
}

/// Pink ball of yarn with a loose strand; [spin] turns the wraps as it rolls.
void drawYarn(Canvas canvas, Offset c, [double spin = 0]) {
  canvas.drawOval(
      Rect.fromCenter(center: c + const Offset(0, 10), width: 26, height: 7),
      Paint()..color = const Color(0x33402A14));
  canvas.drawCircle(c, 12, Paint()..color = const Color(0xFFE77FA0));
  final wrap = Paint()
    ..color = const Color(0xFFF9B9CC)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.8;
  for (var i = 0; i < 3; i++) {
    canvas.drawArc(Rect.fromCircle(center: c, radius: 9.5 - i * 2.8),
        spin + i * 1.3, 3.4, false, wrap);
  }
  canvas.drawPath(
      Path()
        ..moveTo(c.dx + 10, c.dy + 6)
        ..cubicTo(
            c.dx + 22, c.dy + 16, c.dx + 12, c.dy + 22, c.dx + 28, c.dy + 20),
      Paint()
        ..color = const Color(0xFFE77FA0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2);
}

void _shrimp(Canvas canvas, Offset c) {
  // A curled orange shrimp with banded segments and a fan tail.
  final body = Paint()
    ..color = const Color(0xFFF0884A)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 9
    ..strokeCap = StrokeCap.round;
  final arc = Rect.fromCircle(center: c + const Offset(0, 2), radius: 10);
  canvas.drawArc(arc, math.pi * .95, math.pi * 1.25, false, body);
  final band = Paint()
    ..color = const Color(0xFFFFC08A)
    ..strokeWidth = 1.6
    ..strokeCap = StrokeCap.round;
  for (var i = 0; i < 4; i++) {
    final a = math.pi * (1.1 + i * .27);
    final dir = Offset(math.cos(a), math.sin(a));
    canvas.drawLine(c + const Offset(0, 2) + dir * 6,
        c + const Offset(0, 2) + dir * 14, band);
  }
  final tail = c + const Offset(-9, 7);
  canvas.drawPath(
      Path()
        ..moveTo(tail.dx, tail.dy)
        ..lineTo(tail.dx - 8, tail.dy + 6)
        ..lineTo(tail.dx - 2, tail.dy + 9)
        ..close(),
      Paint()..color = const Color(0xFFE0663A));
  final head = c + const Offset(9, 5);
  canvas.drawCircle(head, 2, Paint()..color = const Color(0xFF3A2A20));
  canvas.drawLine(
      head,
      head + const Offset(10, 6),
      Paint()
        ..color = const Color(0xFFE0663A)
        ..strokeWidth = 1.2);
}

void _salmon(Canvas canvas, Offset c) {
  // A salmon steak: pink slice with pale fat lines and silver skin.
  final slice = Path()
    ..moveTo(c.dx - 15, c.dy + 7)
    ..quadraticBezierTo(c.dx - 16, c.dy - 9, c.dx, c.dy - 10)
    ..quadraticBezierTo(c.dx + 16, c.dy - 9, c.dx + 15, c.dy + 7)
    ..quadraticBezierTo(c.dx, c.dy + 11, c.dx - 15, c.dy + 7)
    ..close();
  canvas.drawPath(slice, Paint()..color = const Color(0xFFF27A6B));
  canvas.drawPath(
      slice,
      Paint()
        ..color = const Color(0xFFBFC7CF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2);
  final fat = Paint()
    ..color = const Color(0xFFFFD3C6)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.6;
  for (var i = -1; i <= 1; i++) {
    canvas.drawArc(
        Rect.fromCenter(center: c + Offset(i * 6.0, 2), width: 10, height: 14),
        -math.pi * .9,
        math.pi * .8,
        false,
        fat);
  }
  canvas.drawCircle(
      c + const Offset(0, -2), 2.4, Paint()..color = const Color(0xFFF7E9D8));
}
