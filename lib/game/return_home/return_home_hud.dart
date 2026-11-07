import 'package:flutter/painting.dart';

/// Screen-space text drawn by the game: progress, pickups, checkpoint notices
/// and the result card.
/// One stretch on the route map: where it starts along the run (0–1), its
/// colour and its name.
typedef RouteStop = ({double at, Color color, String name});

void paintReturnHomeHud(
  Canvas canvas, {
  required Size size,
  required double progress,
  required List<RouteStop> stops,
  required double checkpoint,
  required int lives,
  required int fish,
  required double elapsed,
  required int stars,
  required int reward,
  required String? zone,
  required bool finished,
}) {
  final bar = Rect.fromLTWH(18, 18, (size.width * .38).clamp(200.0, 340.0), 14);
  _paintRouteMap(canvas, bar, progress, stops, checkpoint);
  final current = stops.lastWhere((s) => s.at <= progress + 1e-6,
      orElse: () => stops.first);
  final hearts = List.filled(lives, '♥').join(' ');
  final hud = TextPainter(
    text: TextSpan(
      children: [
        TextSpan(
            text: current.name,
            style: const TextStyle(fontWeight: FontWeight.w900)),
        TextSpan(
            text: '   $hearts',
            style: const TextStyle(color: Color(0xFFD9475A))),
        TextSpan(text: '   🐟 $fish   ${elapsed.toStringAsFixed(1)}s'),
      ],
      style: const TextStyle(
          color: Color(0xFF5A3214), fontSize: 14, fontWeight: FontWeight.w800),
    ),
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: size.width - 110);
  final chip = RRect.fromRectAndRadius(
      Rect.fromLTWH(
          bar.left - 6, bar.bottom + 12, hud.width + 18, hud.height + 8),
      const Radius.circular(12));
  canvas.drawRRect(chip, Paint()..color = const Color(0xCCFFF4DA));
  hud.paint(canvas, Offset(bar.left + 3, bar.bottom + 16));
  if (zone != null && !finished) {
    _center(canvas, size, zone, size.height * .17, 26);
    _center(canvas, size, 'Đã lưu checkpoint', size.height * .17 + 34, 14);
  }
  if (!finished) return;
  final card = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * .32),
      width: 330,
      height: 128);
  canvas.drawRRect(RRect.fromRectAndRadius(card, const Radius.circular(18)),
      Paint()..color = const Color(0xF2FFF4DA));
  canvas.drawRRect(
      RRect.fromRectAndRadius(card, const Radius.circular(18)),
      Paint()
        ..color = const Color(0xFFB27A3E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3);
  _center(canvas, size, 'ĐÃ VỀ ĐẾN NHÀ!', card.top + 18, 28);
  _center(
      canvas,
      size,
      List.generate(3, (i) => i < stars ? '★' : '☆').join(' '),
      card.top + 58,
      30);
  _center(
      canvas,
      size,
      '${elapsed.toStringAsFixed(1)} giây · $fish cá · +$reward xu',
      card.top + 96,
      16);
}

void _center(Canvas canvas, Size size, String text, double y, double fontSize) {
  final painter = TextPainter(
    text: TextSpan(
        text: text,
        style: TextStyle(
            color: const Color(0xFF5A3214),
            fontSize: fontSize,
            fontWeight: FontWeight.w900)),
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: size.width - 40);
  painter.paint(canvas, Offset((size.width - painter.width) / 2, y));
}

/// Route map: the run as a pill split into each stretch's colour, flags at
/// stretch borders (gold once reached as a checkpoint), a house at the end
/// and the cat's head moving along with [progress].
void _paintRouteMap(Canvas canvas, Rect bar, double progress,
    List<RouteStop> stops, double checkpoint) {
  final pill = RRect.fromRectAndRadius(bar, Radius.circular(bar.height / 2));
  canvas.drawRRect(
      pill.shift(const Offset(0, 2)), Paint()..color = const Color(0x55402616));
  canvas.save();
  canvas.clipRRect(pill);
  for (var i = 0; i < stops.length; i++) {
    final x0 = bar.left + bar.width * stops[i].at;
    final x1 = i + 1 < stops.length
        ? bar.left + bar.width * stops[i + 1].at
        : bar.right;
    canvas.drawRect(Rect.fromLTRB(x0, bar.top, x1, bar.bottom),
        Paint()..color = stops[i].color);
  }
  // Road still ahead is dimmed; the walked part stays bright.
  final walked = bar.left + bar.width * progress;
  canvas.drawRect(Rect.fromLTRB(walked, bar.top, bar.right, bar.bottom),
      Paint()..color = const Color(0x77FFF4DA));
  // Dotted path along the middle.
  final dots = Paint()..color = const Color(0x99FFFFFF);
  for (var x = bar.left + 6; x < bar.right - 4; x += 8) {
    canvas.drawCircle(Offset(x, bar.center.dy), 1.1, dots);
  }
  canvas.restore();
  canvas.drawRRect(
      pill,
      Paint()
        ..color = const Color(0xFF9A6028)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2);

  // Flags at each stretch border.
  for (final stop in stops.skip(1)) {
    final x = bar.left + bar.width * stop.at;
    final reached = stop.at <= checkpoint + 1e-6;
    final pole = Offset(x, bar.top - 1);
    canvas.drawLine(
        pole,
        pole - const Offset(0, 9),
        Paint()
          ..color = const Color(0xFF5A3214)
          ..strokeWidth = 1.4);
    canvas.drawPath(
        Path()
          ..moveTo(pole.dx, pole.dy - 9)
          ..lineTo(pole.dx + 6, pole.dy - 7)
          ..lineTo(pole.dx, pole.dy - 5)
          ..close(),
        Paint()
          ..color =
              reached ? const Color(0xFFFFC24D) : const Color(0xFFD9CDB8));
  }

  // House at the finish.
  final home = Offset(bar.right + 13, bar.center.dy);
  final roof = Paint()..color = const Color(0xFFC0564A);
  canvas.drawRect(
      Rect.fromCenter(center: home + const Offset(0, 3), width: 13, height: 9),
      Paint()..color = const Color(0xFFFFE5A6));
  canvas.drawPath(
      Path()
        ..moveTo(home.dx - 9, home.dy)
        ..lineTo(home.dx, home.dy - 8)
        ..lineTo(home.dx + 9, home.dy)
        ..close(),
      roof);
  canvas.drawRect(Rect.fromLTWH(home.dx - 2, home.dy + 2, 4, 5),
      Paint()..color = const Color(0xFF7A4A33));

  // Cat head marker.
  final c = Offset(walked.clamp(bar.left + 4, bar.right - 4), bar.center.dy);
  final fur = Paint()..color = const Color(0xFFF4A34E);
  final edge = Paint()
    ..color = const Color(0xFF5A3214)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.6;
  final ears = Path()
    ..moveTo(c.dx - 9, c.dy - 3)
    ..lineTo(c.dx - 7, c.dy - 13)
    ..lineTo(c.dx - 1, c.dy - 7)
    ..moveTo(c.dx + 9, c.dy - 3)
    ..lineTo(c.dx + 7, c.dy - 13)
    ..lineTo(c.dx + 1, c.dy - 7);
  canvas.drawPath(ears, fur);
  canvas.drawPath(ears, edge);
  canvas.drawCircle(c, 9, fur);
  canvas.drawCircle(c, 9, edge);
  final eye = Paint()..color = const Color(0xFF5A3214);
  canvas.drawCircle(c + const Offset(-3.2, -1), 1.3, eye);
  canvas.drawCircle(c + const Offset(3.2, -1), 1.3, eye);
  canvas.drawCircle(
      c + const Offset(0, 2.2), 1.1, Paint()..color = const Color(0xFFD9657B));
}
