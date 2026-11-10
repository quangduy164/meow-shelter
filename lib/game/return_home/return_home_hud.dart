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
  String zoneSubtitle = 'Đã lưu checkpoint',
  double? bossHealth,
  int bossPhase = 1,
  bool bossTired = false,
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
    _center(canvas, size, zoneSubtitle, size.height * .17 + 34, 14);
  }
  if (bossHealth != null && !finished) {
    _paintBossBar(canvas, size, bossHealth, bossPhase, bossTired);
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
  _center(canvas, size, 'BÉ ĐÃ VỀ AN TOÀN!', card.top + 18, 24);
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

/// Dragon health bar, bottom center between the joystick and the skills: a red bar split in
/// three phases, a dragon-head badge, and a "MỆT!" tag while it is tired.
void _paintBossBar(
    Canvas canvas, Size size, double health, int phase, bool tired) {
  final width = (size.width * .34).clamp(200.0, 360.0);
  final bar = Rect.fromCenter(
      center: Offset(size.width * .46, size.height - 26),
      width: width,
      height: 16);
  final pill = RRect.fromRectAndRadius(bar, const Radius.circular(8));
  canvas.drawRRect(pill.inflate(3), Paint()..color = const Color(0xCC3A1A10));
  canvas.save();
  canvas.clipRRect(pill);
  canvas.drawRect(bar, Paint()..color = const Color(0xFF5A2A20));
  final fill = Rect.fromLTWH(bar.left, bar.top, bar.width * health, bar.height);
  canvas.drawRect(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: phase == 3
              ? const [Color(0xFFFF6A4A), Color(0xFFB8201A)]
              : const [Color(0xFFFF8A5A), Color(0xFFD9382A)],
        ).createShader(bar));
  canvas.drawRect(Rect.fromLTWH(bar.left, bar.top + 2, fill.width, 4),
      Paint()..color = const Color(0x55FFFFFF));
  canvas.restore();
  // Phase marks at 2/3 and 1/3.
  final mark = Paint()
    ..color = const Color(0xFFFFF4DA)
    ..strokeWidth = 2;
  for (final f in const [1 / 3, 2 / 3]) {
    final x = bar.left + bar.width * f;
    canvas.drawLine(Offset(x, bar.top), Offset(x, bar.bottom), mark);
  }
  canvas.drawRRect(
      pill,
      Paint()
        ..color = const Color(0xFFFFC24D)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2);
  // Dragon head badge.
  final c = Offset(bar.left - 14, bar.center.dy);
  canvas.drawCircle(c, 15, Paint()..color = const Color(0xFFE0533D));
  canvas.drawCircle(
      c,
      15,
      Paint()
        ..color = const Color(0xFF4A1E14)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4);
  final horn = Paint()..color = const Color(0xFFFFF0C8);
  canvas.drawPath(
      Path()
        ..moveTo(c.dx - 9, c.dy - 9)
        ..lineTo(c.dx - 13, c.dy - 20)
        ..lineTo(c.dx - 3, c.dy - 12)
        ..close(),
      horn);
  canvas.drawPath(
      Path()
        ..moveTo(c.dx + 9, c.dy - 9)
        ..lineTo(c.dx + 13, c.dy - 20)
        ..lineTo(c.dx + 3, c.dy - 12)
        ..close(),
      horn);
  canvas.drawCircle(
      c + const Offset(-5, -2), 3.4, Paint()..color = _HudColors.white);
  canvas.drawCircle(
      c + const Offset(5, -2), 3.4, Paint()..color = _HudColors.white);
  canvas.drawCircle(
      c + const Offset(-5, -1), 1.7, Paint()..color = _HudColors.ink);
  canvas.drawCircle(
      c + const Offset(5, -1), 1.7, Paint()..color = _HudColors.ink);
  canvas.drawLine(
      c + const Offset(-6, 7),
      c + const Offset(6, 7),
      Paint()
        ..color = _HudColors.ink
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round);
  final label = TextPainter(
    text: TextSpan(
      children: [
        const TextSpan(text: 'RỒNG LỬA'),
        if (tired)
          const TextSpan(
              text: '  MỆT! CÀO ĐI!',
              style: TextStyle(color: Color(0xFFFFE15A))),
      ],
      style: const TextStyle(
          color: Color(0xFFFFF4DA),
          fontSize: 12,
          fontWeight: FontWeight.w900,
          shadows: [Shadow(color: Color(0xFF3A1A10), blurRadius: 3)]),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  label.paint(canvas, Offset(bar.left + 6, bar.top - label.height - 3));
}

class _HudColors {
  static const white = Color(0xFFFFFFFF);
  static const ink = Color(0xFF2A120C);
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

  // Shelter gate at the finish.
  final gate = Offset(bar.right + 13, bar.center.dy);
  final frame = Paint()
    ..color = const Color(0xFF9B6745)
    ..strokeWidth = 3
    ..strokeCap = StrokeCap.round;
  canvas.drawLine(
      gate + const Offset(-7, 6), gate + const Offset(-7, -7), frame);
  canvas.drawLine(gate + const Offset(7, 6), gate + const Offset(7, -7), frame);
  canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: gate + const Offset(0, -7), width: 20, height: 6),
          const Radius.circular(2)),
      Paint()..color = const Color(0xFF5F8F72));
  canvas.drawCircle(
      gate + const Offset(0, -11), 3, Paint()..color = const Color(0xFFFFD478));

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
