import 'package:flutter/painting.dart';
import 'package:flame/components.dart';
import 'herd_round.dart';

/// Optional footprints and cluster labels; the whole field stays walkable.
void paintHerdRoute(Canvas canvas, Size size, HerdRound round) {
  // Small footprints point along the main route, rather than a UI arrow overlay.
  final route = round.map.route.main;
  for (var i = 1; i < route.length; i++) {
    final a = round.map.route.point(route[i - 1], round.field).toOffset();
    final b = round.map.route.point(route[i], round.field).toOffset();
    final delta = b - a, length = delta.distance;
    for (var d = 45.0; d < length - 25; d += 65) {
      final p = a + delta * (d / length);
      canvas.save();
      canvas.translate(p.dx, p.dy);
      canvas.rotate(delta.direction);
      canvas.drawOval(const Rect.fromLTWH(-3, -8, 7, 4),
          Paint()..color = const Color(0x667A633E));
      canvas.drawOval(const Rect.fromLTWH(3, 3, 7, 4),
          Paint()..color = const Color(0x667A633E));
      canvas.restore();
    }
  }
  for (var i = 0; i < round.map.route.groups.length; i++) {
    final p = round.map.route
        .point(round.map.route.groups[i], round.field)
        .toOffset();
    final left = round.cats
        .where((cat) => cat.group == i && !cat.following && !cat.home)
        .length;
    canvas.drawCircle(
        p,
        29,
        Paint()
          ..color =
              left == 0 ? const Color(0x225DAB69) : const Color(0x33FFE29A));
    final text = TextPainter(
        text: TextSpan(
            text: i == 3 ? 'THƯỞNG · $left' : 'CỤM ${i + 1} · $left',
            style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: Color(0xFF5A3214))),
        textDirection: TextDirection.ltr)
      ..layout();
    final at = p + Offset(-text.width / 2, -43);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            (at & text.size).inflate(4), const Radius.circular(5)),
        Paint()..color = const Color(0xEEFFF0CF));
    text.paint(canvas, at);
  }
}
