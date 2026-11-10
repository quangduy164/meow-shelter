import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/painting.dart';
import 'herd_round.dart';
import 'herd_map.dart';
import 'herd_map_painter.dart';
import 'herd_home_painter.dart';

/// Scenery and hazards only; cat sprites are owned by HerdGame.
void paintHerdField(Canvas canvas, Size size, HerdRound round) {
  paintHerdMap(canvas, size, round);
  for (final patrol in round.patrols) {
    final p = patrol.position(round.map.patrolTime(round.time) * .7).toOffset();
    if (round.map.kind == HerdMapKind.nightMarket ||
        round.map.kind == HerdMapKind.playground) {
      _toyCar(canvas, p,
          facingLeft:
              math.cos(round.map.patrolTime(round.time) * .7 + patrol.phase) <
                  0,
          wheelAngle: round.map.patrolTime(round.time) * 5);
    } else {
      _rollingHazard(canvas, p, round.time, round.map.kind == HerdMapKind.snow);
    }
  }
  paintHerdHome(canvas, round.home.toOffset(), round.map.kind);
  final sign = round.home.toOffset() + const Offset(-41, 33);
  canvas.drawRRect(
      RRect.fromRectAndRadius(
          sign & const Size(82, 19), const Radius.circular(6)),
      Paint()
        ..color = round.homeUnlocked
            ? const Color(0xFFDBEDB4)
            : const Color(0xFFFFEBC5));
  herdText(
      canvas,
      round.homeUnlocked ? 'NHÀ ĐÃ MỞ' : 'CẦN ${HerdRound.requiredCats} BÉ',
      sign + const Offset(7, 3),
      11);
}

void herdText(Canvas canvas, String value, Offset at, double fontSize) {
  final text = TextPainter(
      text: TextSpan(
          text: value,
          style: TextStyle(
              fontSize: fontSize,
              color: const Color(0xFF5A3214),
              fontWeight: FontWeight.w900)),
      textDirection: TextDirection.ltr)
    ..layout();
  text.paint(canvas, at);
}

/// Wooden toy pickup, drawn around its collision centre.
void _toyCar(Canvas canvas, Offset center,
    {required bool facingLeft, required double wheelAngle}) {
  canvas.save();
  canvas.translate(center.dx, center.dy);
  canvas.drawOval(const Rect.fromLTWH(-25, 10, 50, 11),
      Paint()..color = const Color(0x33402A14));
  if (facingLeft) canvas.scale(-1, 1);
  final outline = Paint()
    ..color = const Color(0xFF70422D)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;
  final body = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-23, -6, 46, 20), const Radius.circular(5));
  canvas.drawRRect(
      body,
      Paint()
        ..shader = const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFE9A36C), Color(0xFFBC6246)])
            .createShader(body.outerRect));
  canvas.drawRRect(body, outline);
  // Open cargo bed, with a rolled-up toy blanket.
  canvas.drawRect(const Rect.fromLTWH(-20, -9, 17, 9),
      Paint()..color = const Color(0xFF96623F));
  canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(-18, -12, 12, 8), const Radius.circular(3)),
      Paint()..color = const Color(0xFF9BC2A7));
  canvas.drawLine(
      const Offset(-20, -5),
      const Offset(-4, -5),
      Paint()
        ..color = const Color(0xFFECC292)
        ..strokeWidth = 3);
  final cab = Path()
    ..moveTo(-3, -6)
    ..lineTo(-3, -19)
    ..quadraticBezierTo(-3, -23, 2, -23)
    ..lineTo(12, -23)
    ..lineTo(20, -6)
    ..close();
  canvas.drawPath(cab, Paint()..color = const Color(0xFFF8D898));
  canvas.drawPath(cab, outline);
  final window = Path()
    ..moveTo(1, -18)
    ..lineTo(10, -18)
    ..lineTo(15, -8)
    ..lineTo(1, -8)
    ..close();
  canvas.drawPath(window, Paint()..color = const Color(0xFF79B9C5));
  canvas.drawLine(
      const Offset(3, -16),
      const Offset(8, -10),
      Paint()
        ..color = const Color(0xFFCEEAF0)
        ..strokeWidth = 2);
  canvas.drawLine(
      const Offset(-1, 1),
      const Offset(16, 1),
      Paint()
        ..color = const Color(0xFFF4BA7F)
        ..strokeWidth = 2);
  canvas.drawLine(const Offset(2, 4), const Offset(6, 4), outline);
  canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(19, -2, 5, 6), const Radius.circular(2)),
      Paint()..color = const Color(0xFFFFECA3));
  canvas.drawRect(const Rect.fromLTWH(-24, 2, 3, 5),
      Paint()..color = const Color(0xFFC3443F));
  canvas.drawRect(const Rect.fromLTWH(20, 10, 6, 4),
      Paint()..color = const Color(0xFFB9B8A6));
  for (final x in [-14.0, 14.0]) {
    canvas.save();
    canvas.translate(x, 12);
    canvas.rotate(wheelAngle);
    canvas.drawCircle(Offset.zero, 8, Paint()..color = const Color(0xFF403D3B));
    canvas.drawCircle(Offset.zero, 5, Paint()..color = const Color(0xFFD4BD8A));
    for (var i = 0; i < 4; i++) {
      final angle = i * math.pi / 2;
      canvas.drawLine(
          Offset.zero,
          Offset.fromDirection(angle, 4),
          Paint()
            ..color = const Color(0xFF89704B)
            ..strokeWidth = 1.5);
    }
    canvas.drawCircle(
        Offset.zero, 1.7, Paint()..color = const Color(0xFFF4E0AF));
    canvas.restore();
  }
  canvas.restore();
}

void _rollingHazard(Canvas canvas, Offset p, double time, bool snow) {
  canvas.drawOval(
      Rect.fromCenter(center: p + const Offset(0, 13), width: 38, height: 12),
      Paint()..color = const Color(0x33402A14));
  canvas.save();
  canvas.translate(p.dx, p.dy);
  canvas.rotate(time * 2);
  canvas.drawCircle(
      Offset.zero,
      18,
      Paint()
        ..color = snow ? const Color(0xFFDDEFF2) : const Color(0xFFAF8958));
  if (snow) {
    canvas.drawCircle(
        const Offset(-4, -5), 11, Paint()..color = const Color(0xFFF9FFFF));
    for (var i = 0; i < 5; i++) {
      canvas.drawCircle(Offset.fromDirection(i * 1.2566, 12), 2,
          Paint()..color = const Color(0xFF9DBBC6));
    }
  } else {
    for (var i = 0; i < 8; i++) {
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset.fromDirection(i * .785, 4), width: 25, height: 12),
          Paint()
            ..color = const Color(0xFF795B3B)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5);
      canvas.rotate(.4);
    }
  }
  canvas.restore();
}
