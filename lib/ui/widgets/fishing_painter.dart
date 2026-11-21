import '../../game/text_cache.dart';
import '../design.dart';
import 'dart:math' as math;
import 'package:material_ui/material_ui.dart';
import '../../fishing/fishing_controller.dart';
import '../../collection/fish_species.dart';

class FishingPainter extends CustomPainter {
  const FishingPainter(
      {required this.phase,
      required this.fish,
      required this.spot,
      required this.clock,
      required this.elapsed,
      required this.progress,
      required this.tension,
      required this.pulling,
      this.boat = const Offset(.5, .75),
      this.facingRight = false,
      this.artScale,
      this.drift = 0,
      this.sweetCenter = .45,
      this.combo = 0});
  final FishingPhase phase;
  final FishSpecies fish;
  final Offset spot, boat;
  final double clock, elapsed, progress, tension;
  final bool pulling, facingRight;
  final double? artScale;
  final double drift, sweetCenter;
  final int combo;

  @override
  void paint(Canvas canvas, Size size) {
    final tip = _drawRod(canvas, size);
    if (phase == FishingPhase.ready || phase == FishingPhase.lost) return;
    var bobber = Offset(spot.dx * size.width, spot.dy * size.height);
    if (phase == FishingPhase.casting) {
      // Bobber hangs at the tip during the wind-up, then flies on the whip.
      final t = ((elapsed - .2) / .45).clamp(0.0, 1.0);
      bobber = Offset.lerp(tip, bobber, t)! -
          Offset(0, math.sin(t * math.pi) * 90 * (artScale ?? 1));
    } else if (phase == FishingPhase.reeling) {
      bobber += Offset(math.sin(clock * 8) * 7, math.cos(clock * 7) * 3);
    } else {
      bobber += Offset(
          0,
          math.sin(clock * (phase == FishingPhase.bite ? 22 : 3)) *
              (phase == FishingPhase.bite ? 7 : 2));
    }
    final danger = phase == FishingPhase.reeling && tension >= .82;
    final pulse = .5 + math.sin(clock * 10).abs() * .5;
    final line = Paint()
      ..color = danger
          ? Color.lerp(
              const Color(0xFFFF7365), const Color(0xFFFFD0A0), pulse * .35)!
          : const Color(0xCCF4F5DB)
      ..strokeWidth = danger ? 1.8 : 1.4
      ..style = PaintingStyle.stroke;
    // Reeling in takes up all slack, regardless of the tension gauge value.
    final scale = artScale ?? 1.0;
    final end = bobber - const Offset(0, 7);
    final span = end - tip;
    final load = phase == FishingPhase.reeling
        ? tension
        : phase == FishingPhase.bite
            ? .45
            : 0.0;
    final slack = (1 - load.clamp(0.0, 1.0));
    final sag = math.min(40 * scale, span.distance * .28) * slack + 2 * scale;
    final breeze = math.sin(clock * 1.5) *
        math.min(3 * scale, span.dx.abs() * .04) *
        slack;
    if (phase == FishingPhase.reeling && pulling) {
      canvas.drawLine(tip, end, line);
    } else {
      canvas.drawPath(
          Path()
            ..moveTo(tip.dx, tip.dy)
            ..cubicTo(
                tip.dx + span.dx * .25 + breeze,
                tip.dy + span.dy * .33 + sag,
                tip.dx + span.dx * .72 + breeze,
                tip.dy + span.dy * .72 + sag * .6,
                end.dx,
                end.dy),
          line);
    }
    final ripple = Paint()
      ..color = const Color(0xAACFF8EF)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < 3; i++) {
      final t = (clock * .7 + i / 3) % 1;
      canvas.drawOval(
          Rect.fromCenter(
              center: bobber + const Offset(0, 5),
              width: 12 + t * 45,
              height: 4 + t * 12),
          ripple..color = Color.fromRGBO(215, 255, 246, (1 - t) * .7));
    }
    canvas.drawLine(
        bobber - const Offset(0, 15),
        bobber + const Offset(0, 4),
        Paint()
          ..color = const Color(0xFF593822)
          ..strokeWidth = 2);
    canvas.drawOval(Rect.fromCenter(center: bobber, width: 9, height: 15),
        Paint()..color = Colors.white);
    canvas.drawOval(
        Rect.fromCenter(
            center: bobber - const Offset(0, 3), width: 9, height: 9),
        Paint()..color = const Color(0xFFE25536));
    if (phase == FishingPhase.reeling) {
      _drawTensionBar(canvas, bobber, size);
    }
    if (phase == FishingPhase.bite || phase == FishingPhase.caught) {
      // Cached: this painter repaints every frame.
      final painter = TextCache.layout(
          phase == FishingPhase.bite ? '!' : '+1',
          const TextStyle(
              fontFamily: 'Roboto',
              fontSize: DS.fontSymbol,
              fontWeight: FontWeight.w900,
              color: Color(0xFFFFF0AF),
              shadows: [Shadow(color: Color(0xFF573215), blurRadius: 3)]));
      painter.paint(canvas, bobber - Offset(painter.width / 2, 58));
    }
  }

  Offset _drawRod(Canvas canvas, Size size) {
    Offset point(double x, double y) => Offset(x * size.width, y * size.height);
    final load = phase == FishingPhase.reeling ? tension : 0.0;
    final motion = _rodMotion();
    final scale = artScale ?? math.min(size.width / 800, size.height / 327);
    final side = facingRight ? 1.0 : -1.0;
    final reeled =
        phase == FishingPhase.reeling ? progress.clamp(0.0, 1.0) : 0.0;
    final body = point(boat.dx, boat.dy) +
        Offset(0, math.sin(clock * 2.5) * 1.8) * scale;
    final base = body + Offset(side * 34, -6) * scale;
    // Rotate the rod around its handle, then bend the tip.
    Offset swing(Offset p) {
      final v = p - base;
      final angle = -side * motion.angle;
      final c = math.cos(angle), s = math.sin(angle);
      return base + Offset(v.dx * c - v.dy * s, v.dx * s + v.dy * c);
    }

    final control =
        swing(base + Offset(side * 38, pulling ? -78 : -72) * scale) +
            Offset(0, motion.bend * 70 * scale);
    final tip = swing(base +
            Offset(
                    side * (103 - reeled * 65) + drift * load * 4,
                    -91 +
                        reeled * 40 +
                        load * 15 +
                        (pulling ? math.sin(clock * 9) * 1.5 : 0)) *
                scale) +
        Offset(0, motion.bend * 200 * scale);
    Offset shaft(double t) =>
        base * ((1 - t) * (1 - t)) +
        control * (2 * (1 - t) * t) +
        tip * (t * t);
    Offset tangent(double t) =>
        (control - base) * (1 - t) + (tip - control) * t;
    Offset guide(double t) {
      final direction = tangent(t);
      return shaft(t) +
          Offset(-direction.dy, direction.dx) /
              direction.distance *
              (side * 5 * scale);
    }

    final handleAngle =
        math.atan2(control.dy - base.dy, control.dx - base.dx) + math.pi / 2;
    final reel = base +
        Offset(
                side * 12 * math.cos(handleAngle) + 17 * math.sin(handleAngle),
                side * 12 * math.sin(handleAngle) -
                    17 * math.cos(handleAngle)) *
            scale;
    const guides = [.30, .52, .73, .90, 1.0];
    final stroke = Paint()..strokeCap = StrokeCap.round;
    for (var i = 0; i < 24; i++) {
      final t = i / 24;
      canvas.drawLine(
          shaft(t),
          shaft((i + 1) / 24),
          stroke
            ..color = const Color(0xFF254D49)
            ..strokeWidth = (4.5 - t * 3) * scale);
      canvas.drawLine(
          shaft(t) + const Offset(-.6, 0),
          shaft((i + 1) / 24) + const Offset(-.6, 0),
          stroke
            ..color = const Color(0xFF8FB8A2)
            ..strokeWidth = (1.2 - t * .7) * scale);
    }
    final threadedLine = Path()..moveTo(reel.dx, reel.dy);
    for (final t in guides) {
      final eye = guide(t);
      threadedLine.lineTo(eye.dx, eye.dy);
    }
    canvas.drawPath(
        threadedLine,
        Paint()
          ..color = const Color(0xCCF4F5DB)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1);
    for (final t in guides) {
      final center = shaft(t);
      final direction = tangent(t);
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(math.atan2(direction.dy, direction.dx));
      canvas.scale(scale);
      canvas.drawLine(
          const Offset(-2, 0),
          const Offset(2, 0),
          stroke
            ..color = const Color(0xFFD7B76C)
            ..strokeWidth = 3);
      canvas.drawOval(
          Rect.fromCenter(center: Offset(0, side * 5), width: 4, height: 5),
          Paint()
            ..color = const Color(0xFFDFE4D4)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1);
      canvas.restore();
    }
    canvas.save();
    canvas.translate(base.dx, base.dy);
    canvas.rotate(handleAngle);
    canvas.scale(scale);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(-4, -34, 8, 40), const Radius.circular(3)),
        Paint()..color = const Color(0xFF725338));
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(-3, -32, 5, 35), const Radius.circular(2)),
        Paint()..color = const Color(0xFFD5AF75));
    for (var i = 0; i < 7; i++) {
      canvas.drawLine(
          Offset(-3, -28 + i * 4.0),
          Offset(3, -27 + i * 4.0),
          stroke
            ..color = const Color(0x887A5D3D)
            ..strokeWidth = .8);
    }
    canvas.drawRect(const Rect.fromLTWH(-4, -38, 8, 5),
        Paint()..color = const Color(0xFFDBD5BA));
    canvas.scale(side, 1);
    canvas.drawLine(
        const Offset(3, -24),
        const Offset(11, -20),
        stroke
          ..color = const Color(0xFF3B5350)
          ..strokeWidth = 3);
    canvas.drawCircle(
        const Offset(12, -17), 8, Paint()..color = const Color(0xFF284C49));
    canvas.drawCircle(
        const Offset(12, -17), 6, Paint()..color = const Color(0xFFE1C486));
    canvas.drawCircle(
        const Offset(12, -17),
        3.5,
        Paint()
          ..color = const Color(0xFF91AAA0)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
    final crank = const Offset(12, -17) +
        Offset.fromDirection(pulling ? clock * 8 : .6, 10);
    canvas.drawLine(
        const Offset(12, -17),
        crank,
        stroke
          ..color = const Color(0xFFE7DEBC)
          ..strokeWidth = 2);
    canvas.drawCircle(crank, 2.5, Paint()..color = const Color(0xFF725338));
    canvas.restore();
    return guide(1);
  }

  /// Rod pose per phase: [angle] in radians (+ = swung back over the
  /// shoulder) and [bend] as a fraction of screen height pushed into the tip.
  ({double angle, double bend}) _rodMotion() {
    double settle(double t, double amp) =>
        amp * math.exp(-5 * t) * math.cos(t * 16);
    switch (phase) {
      case FishingPhase.ready:
        return (angle: math.sin(clock * 1.3) * .015, bend: 0);
      case FishingPhase.casting:
        // Wind back, whip forward past rest, then spring back.
        final t = elapsed;
        if (t < .18) {
          final k = Curves.easeOut.transform(t / .18);
          return (angle: .55 * k, bend: -.02 * k);
        }
        if (t < .32) {
          final k = Curves.easeIn.transform((t - .18) / .14);
          return (angle: .55 - .70 * k, bend: -.02 + .07 * k);
        }
        final k = Curves.easeOut.transform(((t - .32) / .33).clamp(0.0, 1.0));
        return (angle: -.15 * (1 - k), bend: .05 * (1 - k));
      case FishingPhase.waiting:
        return (
          angle: math.sin(clock * 1.6) * .012 + settle(elapsed, .03),
          bend: math.sin(clock * 3) * .002,
        );
      case FishingPhase.bite:
        // Sharp nods as the fish tugs the line.
        final tug = math.pow(math.sin(clock * 11).abs(), 3).toDouble();
        return (angle: -.04 * tug, bend: .035 * tug);
      case FishingPhase.reeling:
        return (
          angle: -.04 * tension + drift * .05 + (pulling ? .06 : 0),
          bend: .02 * tension * (1 + math.sin(clock * 13) * .3),
        );
      case FishingPhase.saving:
      case FishingPhase.caught:
        // Lift the catch up out of the water.
        final k = Curves.easeOutBack.transform((elapsed / .45).clamp(0.0, 1.0));
        return (angle: .28 * k + math.sin(clock * 2) * .01, bend: .012 * k);
      case FishingPhase.lost:
        // Line snaps: the rod recoils upward and wobbles to rest.
        return (
          angle: .12 * math.exp(-3 * elapsed) + settle(elapsed, .1),
          bend: -.01 * math.exp(-4 * elapsed)
        );
    }
  }

  void _drawTensionBar(Canvas canvas, Offset bobber, Size size) {
    const width = 112.0, height = 24.0;
    final danger = tension >= .82;
    final pulse = .5 + math.sin(clock * 10).abs() * .5;
    final x = (bobber.dx - width / 2)
        .clamp(8.0, math.max(8.0, size.width - width - 8))
        .toDouble();
    // Avoid the top-left guide and keep the fish/float clear beneath the bar.
    final above = bobber.dy - height - 24;
    final y = above >= 76
        ? above
        : math.min<double>(bobber.dy + 27, size.height - height - 12);
    final rect = Rect.fromLTWH(x, y, width, height);
    final panel = RRect.fromRectAndRadius(rect, const Radius.circular(8));
    canvas.drawRRect(panel, Paint()..color = const Color(0xDE243F43));
    canvas.drawRRect(
        panel,
        Paint()
          ..color = danger
              ? Color.lerp(
                  const Color(0xFFFF6B5F), const Color(0xFFFFD59A), pulse)!
              : const Color(0x998DC0B4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = danger ? 1.8 : 1);
    final track = Rect.fromLTWH(rect.left + 8, rect.top + 8, width - 16, 7);
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(track, const Radius.circular(3)));
    for (final zone in [
      (0.0, .55, const Color(0xFF4DBA91)),
      (.55, .82, const Color(0xFFE3C26B)),
      (.82, 1.0, const Color(0xFFED7167)),
    ]) {
      canvas.drawRect(
          Rect.fromLTWH(track.left + track.width * zone.$1, track.top,
              track.width * (zone.$2 - zone.$1), track.height),
          Paint()..color = zone.$3);
    }
    canvas.restore();
    const half = FishingController.sweetWidth / 2;
    final sweet = Rect.fromLTRB(
        track.left + track.width * (sweetCenter - half).clamp(0.0, 1.0),
        track.top - 2,
        track.left + track.width * (sweetCenter + half).clamp(0.0, 1.0),
        track.bottom + 2);
    canvas.drawRRect(
        RRect.fromRectAndRadius(sweet, const Radius.circular(2)),
        Paint()
          ..color = const Color(0xFFFFEC94)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
    final needleX = track.left + track.width * tension.clamp(0.0, 1.0);
    canvas.drawLine(
        Offset(needleX, track.top - 4),
        Offset(needleX, track.bottom + 3),
        Paint()
          ..color = const Color(0xFF172F34)
          ..strokeWidth = 3.5
          ..strokeCap = StrokeCap.round);
    canvas.drawLine(
        Offset(needleX, track.top - 4),
        Offset(needleX, track.bottom + 3),
        Paint()
          ..color = const Color(0xFFFFF9E5)
          ..strokeWidth = 1.6
          ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(covariant FishingPainter oldDelegate) => true;
}
