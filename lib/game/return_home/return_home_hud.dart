import 'dart:math';
import 'package:flutter/painting.dart';

typedef RouteStop = ({double at, Color color, String name});
const _ink = Color(0xFF5A3214);
const _cream = Color(0xFFFFF4DA);

void paintReturnHomeHud(
  Canvas canvas, {
  required Size size,
  required double progress,
  required List<RouteStop> stops,
  required double checkpoint,
  required int lives,
  required int fish,
  required double elapsed,
  required String? zone,
  required bool finished,
  String zoneSubtitle = '',
  double? bossHealth,
  int bossPhase = 1,
  bool bossTired = false,
  EdgeInsets padding = EdgeInsets.zero,
  double zoneTimeLeft = 1,
}) {
  if (finished) return;
  if (bossHealth != null && !finished) {
    _paintBossBar(canvas, size, padding, bossHealth, bossPhase, bossTired);
    // Keep the player's three hearts visible without restoring the full HUD.
    final usableWidth = size.width - padding.horizontal;
    final bossLeft = (usableWidth - min(440.0, usableWidth * .6)) / 2;
    final panel = Rect.fromLTWH(
        padding.left + 12, padding.top + (bossLeft < 108 ? 82 : 18), 88, 36);
    canvas.drawRRect(RRect.fromRectAndRadius(panel, const Radius.circular(12)),
        Paint()..color = const Color(0xE6FFF4DA));
    canvas.drawRRect(
        RRect.fromRectAndRadius(panel, const Radius.circular(12)),
        Paint()
          ..color = const Color(0x779A6A3A)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1);
    for (var i = 0; i < 3; i++) {
      _heart(
          canvas, Offset(panel.left + 21 + i * 23, panel.center.dy), i < lives);
    }
    return;
  }
  final availableWidth = size.width - padding.horizontal - 100;
  if (availableWidth <= 0) return;
  const width = 288.0;
  canvas.save();
  canvas.translate(padding.left + 12, padding.top + 12);
  canvas.scale(min(1.0, availableWidth / width));
  const panel = Rect.fromLTWH(0, 0, width, 56);
  final shape = RRect.fromRectAndRadius(panel, const Radius.circular(12));
  canvas.drawRRect(shape.shift(const Offset(0, 2)),
      Paint()..color = const Color(0x22402A14));
  canvas.drawRRect(shape, Paint()..color = const Color(0xE6FFF4DA));
  canvas.drawRRect(
      shape,
      Paint()
        ..color = const Color(0x779A6A3A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1);
  final rowY = panel.top + 16;
  for (var i = 0; i < 3; i++) {
    _heart(canvas, Offset(panel.left + 19 + i * 21, rowY), i < lives);
  }
  paintReturnHomeFishIcon(canvas, Offset(panel.left + 105, rowY));
  _label(
      canvas,
      fish.toString(),
      Rect.fromLTWH(
          panel.left + 119, panel.top + 6, max(0.0, width - 210), 20));
  final clockX = panel.right - 69;
  _clock(canvas, Offset(clockX, rowY));
  final seconds = max(0, elapsed.floor());
  final time =
      '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
  _label(canvas, time, Rect.fromLTWH(clockX + 13, panel.top + 6, 49, 20),
      align: TextAlign.right);
  canvas.drawLine(
      Offset(panel.left + 12, panel.top + 30),
      Offset(panel.right - 12, panel.top + 30),
      Paint()
        ..color = const Color(0x229A6A3A)
        ..strokeWidth = 1);
  final current = stops.lastWhere((s) => s.at <= progress + 1e-6,
      orElse: () => stops.first);
  final labelBox = Rect.fromLTWH(panel.left + 12, panel.top + 33, 88, 20);
  final bar =
      Rect.fromLTWH(panel.left + 107, panel.top + 40, max(0.0, width - 155), 7);
  final percentBox = Rect.fromLTWH(panel.right - 33, panel.top + 33, 26, 20);
  _label(canvas, current.name, labelBox, fontSize: 11.5);
  _paintRouteMap(canvas, bar, progress, stops, checkpoint);
  _label(canvas, '${(progress.clamp(0.0, 1.0) * 100).floor()}%', percentBox,
      fontSize: 10, align: TextAlign.right);
  if (zone != null && bossHealth == null && !finished && zoneTimeLeft > 0) {
    final fade = (zoneTimeLeft / .35).clamp(0.0, 1.0);
    final toast = Rect.fromLTWH(
        panel.left, panel.bottom + 6, width, zoneSubtitle.isEmpty ? 28 : 42);
    canvas.drawRRect(RRect.fromRectAndRadius(toast, const Radius.circular(10)),
        Paint()..color = _cream.withAlpha((225 * fade).round()));
    _label(canvas, zone,
        Rect.fromLTWH(toast.left + 10, toast.top + 3, toast.width - 20, 18),
        fontSize: 11.5, color: _ink.withAlpha((255 * fade).round()));
    if (zoneSubtitle.isNotEmpty) {
      _label(canvas, zoneSubtitle,
          Rect.fromLTWH(toast.left + 10, toast.top + 21, toast.width - 20, 17),
          fontSize: 11, color: _ink.withAlpha((210 * fade).round()));
    }
  }
  canvas.restore();
}

void _label(
  Canvas canvas,
  String text,
  Rect box, {
  double fontSize = 13,
  Color color = _ink,
  TextAlign align = TextAlign.left,
}) {
  if (box.width <= 0) return;
  final painter = TextPainter(
      text: TextSpan(
          text: text,
          style: TextStyle(
            color: color,
            fontSize: fontSize,
            fontFamily: 'Roboto',
            fontWeight: FontWeight.w800,
            fontFeatures: const [FontFeature.tabularFigures()],
          )),
      textDirection: TextDirection.ltr,
      textAlign: align,
      maxLines: 1,
      ellipsis: '…')
    ..layout(minWidth: box.width, maxWidth: box.width);
  painter.paint(canvas, Offset(box.left, box.center.dy - painter.height / 2));
}

void _heart(Canvas canvas, Offset c, bool full) {
  final shape = Path()
    ..moveTo(c.dx, c.dy + 7)
    ..cubicTo(c.dx - 16, c.dy - 2, c.dx - 8, c.dy - 13, c.dx, c.dy - 5)
    ..cubicTo(c.dx + 8, c.dy - 13, c.dx + 16, c.dy - 2, c.dx, c.dy + 7)
    ..close();
  canvas.drawPath(
      shape,
      Paint()
        ..color = full ? const Color(0xFFDF6576) : const Color(0xFFE8DCC8));
  canvas.drawPath(
      shape,
      Paint()
        ..color = full ? const Color(0xFFAD4155) : const Color(0xFFBCA98A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2);
  if (full) {
    canvas.drawLine(
        c + const Offset(-5, -4),
        c + const Offset(-3, -5),
        Paint()
          ..color = const Color(0xFFFFB9C0)
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round);
  }
}

/// Shared by the in-game HUD and the victory card.
void paintReturnHomeFishIcon(Canvas canvas, Offset c) {
  final paint = Paint()..color = const Color(0xFF579FA0);
  canvas.drawPath(
      Path()
        ..moveTo(c.dx - 5, c.dy)
        ..lineTo(c.dx - 12, c.dy - 6)
        ..lineTo(c.dx - 12, c.dy + 6)
        ..close(),
      paint);
  canvas.drawOval(Rect.fromCenter(center: c, width: 19, height: 11), paint);
  canvas.drawCircle(c + const Offset(5, -1), 1.3, Paint()..color = _ink);
  canvas.drawArc(
      Rect.fromCenter(center: c + const Offset(-2, 0), width: 7, height: 8),
      -pi / 2,
      pi,
      false,
      Paint()
        ..color = const Color(0xFF95CDCA)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2);
}

void _clock(Canvas canvas, Offset c) {
  final pen = Paint()
    ..color = const Color(0xFF98774F)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5
    ..strokeCap = StrokeCap.round;
  canvas.drawCircle(c, 7, pen);
  canvas.drawPath(
      Path()
        ..moveTo(c.dx, c.dy - 4)
        ..lineTo(c.dx, c.dy)
        ..lineTo(c.dx + 3, c.dy + 2),
      pen);
}

void _paintBossBar(Canvas canvas, Size size, EdgeInsets padding, double health,
    int phase, bool tired) {
  final usableWidth = size.width - padding.horizontal;
  final width = min(440.0, usableWidth * .6);
  final frame = Rect.fromLTWH(
      padding.left + (usableWidth - width) / 2, padding.top + 18, width, 58);
  _label(canvas, phase == 2 ? 'RỒNG CUỒNG NỘ' : 'RỒNG LỬA',
      Rect.fromLTWH(frame.left + 14, frame.top + 4, width - 152, 24),
      fontSize: 17, color: _ink);
  _label(canvas, tired ? 'MỆT! CÀO ĐI!' : 'GIAI ĐOẠN $phase',
      Rect.fromLTWH(frame.right - 130, frame.top + 6, 116, 20),
      fontSize: 10.5,
      color: tired ? const Color(0xFFB84430) : _ink,
      align: TextAlign.right);
  final bar = Rect.fromLTWH(frame.left + 14, frame.top + 31, width - 28, 18);
  final pill = RRect.fromRectAndRadius(bar, const Radius.circular(6));
  canvas.drawRRect(pill, Paint()..color = const Color(0xFF632E26));
  canvas.save();
  canvas.clipRRect(pill);
  final fill = Rect.fromLTWH(
      bar.left, bar.top, bar.width * health.clamp(0.0, 1.0), bar.height);
  canvas.drawRect(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: phase == 2
              ? const [Color(0xFFFF5550), Color(0xFFB8201A)]
              : const [Color(0xFFFF6B68), Color(0xFFD93838)],
        ).createShader(bar));
  canvas.drawRect(Rect.fromLTWH(fill.left, fill.top + 2, fill.width, 3),
      Paint()..color = const Color(0x44FFFFFF));
  final mark = Paint()
    ..color = const Color(0xAAFFE6AF)
    ..strokeWidth = 1.5;
  for (final f in const [.5]) {
    canvas.drawLine(Offset(bar.left + bar.width * f, bar.top),
        Offset(bar.left + bar.width * f, bar.bottom), mark);
  }
  canvas.restore();
  canvas.drawRRect(
      pill,
      Paint()
        ..color = const Color(0xFFBA8953)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1);
  _label(canvas, '${(health.clamp(0.0, 1.0) * 100).ceil()}%', bar,
      fontSize: 12, color: const Color(0xFFFFF4DA), align: TextAlign.center);
}

void _paintRouteMap(Canvas canvas, Rect bar, double progress,
    List<RouteStop> stops, double checkpoint) {
  final pill = RRect.fromRectAndRadius(bar, const Radius.circular(4));
  canvas.save();
  canvas.clipRRect(pill);
  for (var i = 0; i < stops.length; i++) {
    final end = i + 1 < stops.length ? stops[i + 1].at : 1.0;
    canvas.drawRect(
        Rect.fromLTRB(bar.left + bar.width * stops[i].at, bar.top,
            bar.left + bar.width * end, bar.bottom),
        Paint()..color = stops[i].color);
  }
  final walked = bar.left + bar.width * progress.clamp(0.0, 1.0);
  canvas.drawRect(Rect.fromLTRB(walked, bar.top, bar.right, bar.bottom),
      Paint()..color = const Color(0x99FFF4DA));
  canvas.restore();
  for (final stop in stops.skip(1)) {
    canvas.drawCircle(
        Offset(bar.left + bar.width * stop.at, bar.center.dy),
        2,
        Paint()
          ..color = stop.at <= checkpoint + 1e-6
              ? const Color(0xFFAE803F)
              : const Color(0xFFDDD0B4));
  }
  // Compact cat marker stays inside the strip rather than protruding over it.
  final c = Offset(walked.clamp(bar.left + 3, bar.right - 3), bar.center.dy);
  canvas.drawCircle(c, 4, Paint()..color = const Color(0xFFF4A34E));
  canvas.drawCircle(
      c,
      4,
      Paint()
        ..color = const Color(0xFF8E5B32)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1);
  final gate = Offset(bar.right + 7, bar.center.dy);
  final pen = Paint()
    ..color = const Color(0xFF668A60)
    ..strokeWidth = 1.6;
  canvas.drawLine(gate + const Offset(-3, 4), gate + const Offset(-3, -3), pen);
  canvas.drawLine(gate + const Offset(3, 4), gate + const Offset(3, -3), pen);
  canvas.drawLine(gate + const Offset(-4, -3), gate + const Offset(4, -3), pen);
}
