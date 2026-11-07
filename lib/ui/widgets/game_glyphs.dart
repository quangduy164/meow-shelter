import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../design.dart';

/// Hand-drawn navigation glyphs shared by every mode.
enum GameGlyph { back, close, home }

/// Draws a [GameGlyph]: medium rounded strokes in ink with a soft shadow.
class GameGlyphView extends StatelessWidget {
  const GameGlyphView(this.glyph, {super.key, this.size = 26, this.color});
  final GameGlyph glyph;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) => SizedBox.square(
        dimension: size,
        child: CustomPaint(painter: _GlyphPainter(glyph, color ?? DS.ink)),
      );
}

class _GlyphPainter extends CustomPainter {
  const _GlyphPainter(this.glyph, this.color);
  final GameGlyph glyph;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    // The arrow's head makes it left-heavy; nudge it to look centred.
    if (glyph == GameGlyph.back) canvas.translate(s * .03, 0);
    final path = switch (glyph) {
      GameGlyph.back => _back(s),
      GameGlyph.close => _close(s),
      GameGlyph.home => _home(s),
    };
    final width = s * (glyph == GameGlyph.home ? .095 : .12);
    Paint stroke(Color c, double w) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Soft drop shadow, then the line itself.
    canvas.drawPath(
        path.shift(Offset(0, s * .035)), stroke(color.withOpacity(.16), width));
    canvas.drawPath(path, stroke(color, width));
    if (glyph == GameGlyph.back) {
      // Small open arrow head on the left end of the curve.
      final head = Path()
        ..moveTo(s * .44, s * .22)
        ..lineTo(s * .24, s * .42)
        ..lineTo(s * .44, s * .62);
      canvas.drawPath(head.shift(Offset(0, s * .035)),
          stroke(color.withOpacity(.16), width));
      canvas.drawPath(head, stroke(color, width));
    }
    if (glyph == GameGlyph.home) {
      // Door.
      final door = RRect.fromRectAndCorners(
          Rect.fromLTWH(s * .43, s * .62, s * .14, s * .22),
          topLeft: Radius.circular(s * .07),
          topRight: Radius.circular(s * .07));
      canvas.drawRRect(door, Paint()..color = color);
    }
  }

  /// U-turn arrow: shaft curves from the right back toward the head.
  static Path _back(double s) => Path()
    ..moveTo(s * .26, s * .42)
    ..lineTo(s * .58, s * .42)
    ..arcTo(Rect.fromCircle(center: Offset(s * .58, s * .60), radius: s * .18),
        -math.pi / 2, math.pi, false)
    ..lineTo(s * .36, s * .78);

  static Path _close(double s) => Path()
    ..moveTo(s * .24, s * .24)
    ..lineTo(s * .76, s * .76)
    ..moveTo(s * .76, s * .24)
    ..lineTo(s * .24, s * .76);

  static Path _home(double s) => Path()
    ..moveTo(s * .12, s * .50)
    ..lineTo(s * .50, s * .16)
    ..lineTo(s * .88, s * .50)
    ..moveTo(s * .24, s * .44)
    ..lineTo(s * .24, s * .84)
    ..lineTo(s * .76, s * .84)
    ..lineTo(s * .76, s * .44)
    ..moveTo(s * .68, s * .30)
    ..lineTo(s * .68, s * .20);

  @override
  bool shouldRepaint(covariant _GlyphPainter old) =>
      glyph != old.glyph || color != old.color;
}
