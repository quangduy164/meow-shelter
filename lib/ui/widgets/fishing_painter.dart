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
      this.pawColor = const Color(0xFFF4A34E),
      this.facingRight = false,
      this.artScale,
      this.drift = 0,
      this.sweetCenter = .45,
      this.combo = 0});
  final FishingPhase phase;
  final FishSpecies fish;
  final Offset spot, boat;
  final Color pawColor;
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
    final line = Paint()
      ..color = const Color(0xCCF4F5DB)
      ..strokeWidth = 1.4
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
    if (phase == FishingPhase.reeling && drift.abs() > .2) {
      _drawPullArrows(canvas, bobber, drift);
    }
    canvas.drawOval(Rect.fromCenter(center: bobber, width: 9, height: 15),
        Paint()..color = Colors.white);
    canvas.drawOval(
        Rect.fromCenter(
            center: bobber - const Offset(0, 3), width: 9, height: 9),
        Paint()..color = const Color(0xFFE25536));
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
    // Rotate the whole rod around the hand, then bend the tip.
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
    final grip =
        base + Offset.fromDirection(handleAngle - math.pi / 2, 14 * scale);
    final reelHand = base + (reel - base) * .55;
    if (phase == FishingPhase.reeling) {
      _drawTensionGauge(
          canvas,
          Offset((body.dx - side * 83 * scale).clamp(44.0, size.width - 44),
              (body.dy - 9 * scale).clamp(82.0, size.height - 64)));
    }
    for (final (root, hand) in [
      (body + Offset(side * 5, -5) * scale, reelHand),
      (body + Offset(side * 12, -7) * scale, grip),
    ]) {
      final arm = Path()
        ..moveTo(root.dx, root.dy)
        ..quadraticBezierTo(
            (root.dx + hand.dx) / 2, root.dy + 3 * scale, hand.dx, hand.dy);
      canvas.drawPath(
          arm,
          Paint()
            ..color = const Color(0xFF66513A)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 7 * scale
            ..strokeCap = StrokeCap.round);
      canvas.drawPath(
          arm,
          Paint()
            ..color = pawColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4.8 * scale
            ..strokeCap = StrokeCap.round);
    }
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
    // The cat's paw overlaps the handle.
    canvas.drawCircle(grip, 3.5 * scale, Paint()..color = pawColor);
    canvas.drawCircle(reelHand, 3 * scale, Paint()..color = pawColor);
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

  /// Chevrons show where the fish is running; swipe the other way.
  void _drawPullArrows(Canvas canvas, Offset bobber, double drift) {
    final dir = drift.sign;
    final strength = ((drift.abs() - .2) / .6).clamp(0.0, 1.0);
    final blink = .55 + math.sin(clock * 9).abs() * .45;
    final paint = Paint()
      ..color = Color.lerp(
              const Color(0xFFFFC247), const Color(0xFFFF554C), strength)!
          .withValues(alpha: blink)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (var i = 0; i < 2; i++) {
      final x = bobber.dx + dir * (16 + i * 9);
      canvas.drawPath(
          Path()
            ..moveTo(x - dir * 4, bobber.dy - 7)
            ..lineTo(x + dir * 3, bobber.dy)
            ..lineTo(x - dir * 4, bobber.dy + 7),
          paint);
    }
  }

  void _drawTensionGauge(Canvas canvas, Offset center) {
    const radius = 24.0;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    // A transparent left-facing half gauge keeps the reel and rod visible.
    const start = math.pi * .5;
    const sweep = math.pi;
    final redPulse =
        tension > .8 ? (.5 + math.sin(clock * 10).abs() * .5) : 0.0;
    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xCCFFF7D6);
    canvas.drawArc(rect, start, sweep, false, glow);
    for (final zone in [
      (0.0, .55, const Color(0xFF36B887)),
      (.58, .79, const Color(0xFFFFC247)),
      (.82, 1.0, const Color(0xFFFF554C)),
    ]) {
      final color = zone.$3 == const Color(0xFFFF554C) && redPulse > 0
          ? Color.lerp(zone.$3, Colors.white, redPulse * .35)!
          : zone.$3;
      canvas.drawArc(rect, start + zone.$1 * sweep, (zone.$2 - zone.$1) * sweep,
          false, stroke..color = color);
    }
    // Golden sweet zone: reeling inside it is faster and builds combo.
    const half = FishingController.sweetWidth / 2;
    final sweetRect = Rect.fromCircle(center: center, radius: radius + 7);
    canvas.drawArc(
        sweetRect,
        start + (sweetCenter - half) * sweep,
        half * 2 * sweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round
          ..color = const Color(0xFF8A5A12));
    canvas.drawArc(
        sweetRect,
        start + (sweetCenter - half) * sweep,
        half * 2 * sweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round
          ..color = const Color(0xFFFFE066));
    if (combo > 0) {
      final comboText = TextCache.layout(
          'x$combo',
          const TextStyle(
              fontFamily: 'Roboto',
              fontSize: DS.fontValue,
              fontWeight: FontWeight.w900,
              color: Color(0xFFFFE066),
              shadows: [Shadow(color: Color(0xFF5A3A10), blurRadius: 3)]));
      comboText.paint(
          canvas, center + Offset(-comboText.width / 2, -radius - 28));
    }
    final tickPaint = Paint()
      ..color = const Color(0xFF294941)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i <= 10; i++) {
      final angle = start + i / 10 * sweep;
      final outer =
          center + Offset(math.cos(angle), math.sin(angle)) * (radius + 4);
      final inner = center +
          Offset(math.cos(angle), math.sin(angle)) *
              (radius - (i % 5 == 0 ? 8 : 5));
      canvas.drawLine(inner, outer, tickPaint);
    }
    final angle = start + tension * sweep;
    final direction = Offset(math.cos(angle), math.sin(angle));
    final needleEnd = center + direction * (radius + 1);
    final needleBase = center - direction * 7;
    canvas.drawLine(
        needleBase,
        needleEnd,
        Paint()
          ..color = const Color(0xFF253D38)
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round);
    final label = TextCache.layout(
        '${(tension * 100).round()}%',
        const TextStyle(
            fontFamily: 'Roboto',
            fontSize: DS.fontMicro,
            fontWeight: FontWeight.w900,
            color: Color(0xFF294941)));
    label.paint(canvas, center - Offset(label.width / 2, label.height / 2));
  }

  @override
  bool shouldRepaint(covariant FishingPainter oldDelegate) => true;
}
