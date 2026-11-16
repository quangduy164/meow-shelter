import 'dart:ui' as ui;
import 'package:flutter/painting.dart';
import 'moonlight.dart';

/// The sky disc is separate, but the entire ground beam is painted once
/// inside the darkness layer, so its tint cannot lag behind its cutout.
void paintMoon(Canvas canvas, Size size, Moonlight moon) =>
    _paintMoon(canvas, size, moon);

void paintMoonlitField(Canvas canvas, Size screen, Moonlight moon) {
  _paintBeam(canvas, screen, moon, erase: true);
  _paintBeam(canvas, screen, moon, erase: false);
}

void _paintBeam(Canvas canvas, Size screen, Moonlight moon,
    {required bool erase}) {
  if (moon.shown <= .01) return;
  final source = moon.source(screen);
  final target = moon.foot(screen);
  // Overlapping bands soften both sides without a full-screen blur layer.
  for (final width in const [1.0, .96, .91, .85]) {
    final strength = moon.shown * (erase ? .38 : .065);
    Color color(double opacity) => erase
        ? Color.fromRGBO(0, 0, 0, opacity)
        : const Color(0xFFCEE8E4).withValues(alpha: opacity);
    canvas.drawPath(
      moon.beam(screen, widthScale: width),
      Paint()
        ..blendMode = erase ? BlendMode.dstOut : BlendMode.srcOver
        ..shader = ui.Gradient.linear(source, target, [
          color(0),
          color(strength * .25),
          color(strength),
          color(strength * .8),
          color(0),
        ], const [
          0,
          .18,
          .62,
          .88,
          1
        ]),
    );
  }
}

void _paintMoon(Canvas canvas, Size screen, Moonlight moon) {
  // Top left, clear of the status pill and the mission card.
  final c = moon.source(screen);
  final r = screen.height * .045;
  final shown = moon.shown;
  canvas.drawCircle(
      c, r * 2.2, Paint()..color = Color.fromRGBO(255, 244, 200, .12 * shown));
  canvas.drawCircle(c, r, Paint()..color = const Color(0xFFFFF4C8));
  canvas.drawCircle(c + Offset(-r * .3, -r * .2), r * .2,
      Paint()..color = const Color(0x22B8A060));
  canvas.drawCircle(c + Offset(r * .35, r * .3), r * .14,
      Paint()..color = const Color(0x22B8A060));
  // Cloud slides over the moon while it is hidden.
  final cover = 1 - shown;
  if (cover <= 0) return;
  final cloud = Paint()..color = Color.fromRGBO(70, 80, 115, .95 * cover);
  final cx = c.dx + (1 - cover) * r * 3;
  for (final (dx, dy, cr) in const [
    (-1.1, .25, .7),
    (-.3, -.1, .9),
    (.6, .2, .75),
    (1.3, .35, .55),
  ]) {
    canvas.drawCircle(Offset(cx + dx * r, c.dy + dy * r), cr * r, cloud);
  }
}
