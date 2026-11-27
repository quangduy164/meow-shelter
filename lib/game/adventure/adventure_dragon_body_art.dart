part of 'adventure_dragon.dart';

extension _DragonBodyArt on AdventureDragon {
  void _paintBody(Canvas canvas) {
    if (_evolution <= 0) {
      _paintOriginalBody(canvas);
      return;
    }
    if (_evolution >= .98) {
      _paintAscendedBody(canvas);
      return;
    }
    if (_evolution <= .02) {
      _paintOriginalBody(canvas);
      return;
    }
    canvas.saveLayer(null,
        Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: _evolution));
    _paintAscendedBody(canvas);
    canvas.restore();
    canvas.saveLayer(
        null,
        Paint()
          ..color = const Color(0xFFFFFFFF).withValues(alpha: 1 - _evolution));
    _paintOriginalBody(canvas);
    canvas.restore();
  }

  void _paintOriginalBody(Canvas canvas) {
    const scale = Color(0xFFE0533D);
    const dark = Color(0xFFB23A2C);
    const belly = Color(0xFFFFD98A);
    const spike = Color(0xFFFFB13A);

    // Enraged glow.
    if (_evolution > 0 && !intro && !defeated) {
      final pulse = .5 + .5 * sin(_t * 5);
      canvas.drawOval(
          Rect.fromCenter(
              center: const Offset(10, -70), width: 230, height: 190),
          Paint()
            ..shader = RadialGradient(colors: [
              Color.fromARGB(
                  ((65 * pulse + 25) * _evolution).round(), 0xFF, 0x4A, 0x2A),
              const Color(0x00FF5A1A),
            ]).createShader(Rect.fromCenter(
                center: const Offset(10, -70), width: 230, height: 190)));
    }

    // Back wing (darker, behind the body).
    _wing(
        canvas, const Offset(46, -92), .09, .86, dark, const Color(0xFFC8642E));
    // Back legs.
    _shape(
        canvas,
        Path()
          ..addOval(Rect.fromCenter(
              center: const Offset(62, -14), width: 36, height: 30)),
        dark);

    // Body and belly.
    // Angular pear-shaped torso: wide shoulders, tucked waist, plated chest.
    final body = Path()
      ..moveTo(-38 - 12 * _evolution, -66)
      ..quadraticBezierTo(-16 - 14 * _evolution, -101 - 18 * _evolution, 27,
          -98 - 14 * _evolution)
      ..quadraticBezierTo(70 + 8 * _evolution, -95, 83 + 5 * _evolution, -61)
      ..lineTo(76, -23)
      ..quadraticBezierTo(57, -5, 24, -4)
      ..quadraticBezierTo(-11 - 8 * _evolution, -6, -38 - 12 * _evolution, -30)
      ..close();
    canvas.drawPath(body, Paint()..color = _c(scale));
    canvas.save();
    canvas.clipPath(body);
    canvas.drawOval(
        Rect.fromCenter(center: const Offset(0, -36), width: 76, height: 74),
        Paint()..color = _c(belly));
    final stripe = Paint()
      ..color = _c(const Color(0xFFE8B464))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    for (var i = 0; i < 4; i++) {
      final y = -58.0 + i * 13;
      canvas.drawArc(
          Rect.fromCenter(center: Offset(0, y), width: 60, height: 16),
          .3,
          2.5,
          false,
          stripe);
    }
    // Scale dots on the back.
    final dot = Paint()..color = _c(dark);
    for (final p in const [
      Offset(46, -78),
      Offset(62, -64),
      Offset(70, -46),
      Offset(34, -86)
    ]) {
      canvas.drawCircle(p, 4, dot);
    }
    canvas.restore();
    canvas.drawPath(body, _outline);
    if (_evolution <= 0) {
      _paintArmorPlates(canvas, _breath);
    } else if (_evolution < 1) {
      canvas.saveLayer(
          null,
          Paint()
            ..color =
                const Color(0xFFFFFFFF).withValues(alpha: 1 - _evolution));
      _paintArmorPlates(canvas, _breath);
      canvas.restore();
    }
    _paintEvolutionArmor(canvas);
    if (_evolution > 0) {
      canvas.save();
      canvas.translate(-20, -76);
      canvas.scale(_evolution);
      _shape(
          canvas,
          Path()
            ..addPolygon(const [
              Offset(-28, -2),
              Offset(-14, -27),
              Offset(12, -32),
              Offset(32, -13),
              Offset(25, 8),
              Offset(2, 20),
              Offset(-23, 12),
            ], true),
          const Color(0xFFB65333));
      _magma(
          canvas,
          Path()
            ..moveTo(-20, -4)
            ..lineTo(-3, -12)
            ..lineTo(16, -8));
      canvas.restore();
    }

    // Back spikes along the top of the body.
    for (var i = 0; i < 6; i++) {
      final a = pi * (1.12 + i * .13);
      final base = Offset(25 + cos(a) * 62, -52 + sin(a) * 47);
      final out = Offset(cos(a), sin(a));
      final side = Offset(-out.dy, out.dx) * 7;
      _shape(
          canvas,
          Path()
            ..moveTo(base.dx - side.dx, base.dy - side.dy)
            ..lineTo(base.dx + out.dx * (15 + 16 * _evolution),
                base.dy + out.dy * (15 + 16 * _evolution))
            ..lineTo(base.dx + side.dx, base.dy + side.dy)
            ..close(),
          spike);
    }

    // Bent forelegs taper from shoulder to ankle, feet stay planted.
    for (final x in const [-8.0, 38.0]) {
      final settle = _breath * 2 +
          (_tailMove?.crouch ?? 0) +
          _fireCharge * 3 +
          _firePower * 5 +
          _castKick * 2;
      final leg = Path()
        ..moveTo(x - 8, -44 - settle)
        ..quadraticBezierTo(x + 15, -40, x + 13, -26)
        ..lineTo(x + 6, -12)
        ..lineTo(x + 11, -5)
        ..lineTo(x + 8, 2)
        ..lineTo(x - 20, 2)
        ..lineTo(x - 23, -4)
        ..lineTo(x - 7, -14)
        ..lineTo(x - 1, -27)
        ..lineTo(x - 13, -35)
        ..close();
      _shape(canvas, leg, x < 0 ? scale : dark);
      final plate = Path()
        ..moveTo(x - 5, -38)
        ..lineTo(x + 8, -34)
        ..lineTo(x + 8, -26)
        ..lineTo(x - 2, -24)
        ..lineTo(x - 8, -31)
        ..close();
      _shape(canvas, plate, const Color(0xFFCE6740));
      canvas.drawLine(
          Offset(x - 3, -18),
          Offset(x + 5, -16),
          Paint()
            ..color = _c(const Color(0xFF7F291F))
            ..strokeWidth = 1.6);
      for (var i = 0; i < 3; i++) {
        final cx = x - 20 + i * 8.0;
        _shape(
            canvas,
            Path()
              ..moveTo(cx, 0)
              ..lineTo(cx - 8, 7)
              ..lineTo(cx + 5, 3)
              ..lineTo(cx + 6, -1)
              ..close(),
            const Color(0xFFFFF0C8));
      }
    }

    // Neck to the head.
    final h = Offset(_head.x, _head.y);
    final neck = Path()
      ..moveTo(-4, -78)
      ..quadraticBezierTo(
          (h.dx - 4) / 2 - 6, (h.dy - 78) / 2 - 4, h.dx + 8, h.dy + 10);
    canvas.drawPath(
        neck,
        Paint()
          ..color = AdventureDragon._ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 37 + 15 * _evolution
          ..strokeCap = StrokeCap.round);
    canvas.drawPath(
        neck,
        Paint()
          ..color = _c(scale)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 32 + 15 * _evolution
          ..strokeCap = StrokeCap.round);
    canvas.drawPath(
        neck.shift(const Offset(-8, 6)),
        Paint()
          ..color = _c(belly)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 12
          ..strokeCap = StrokeCap.round);
    // Segmented neck armor follows the moving neck curve.
    final neckPlate = Paint()
      ..color = _c(const Color(0xFFFFB13A))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    for (var i = 1; i <= 4; i++) {
      final k = i / 5;
      final x = -4 + (h.dx + 8 + 4) * k;
      final y = -78 + (h.dy + 78 - 4) * k - sin(k * pi) * 7;
      canvas.drawArc(
          Rect.fromCenter(center: Offset(x, y), width: 27, height: 18),
          .15,
          2.8,
          false,
          neckPlate);
    }

    _paintHead(canvas, h);

    // Front wing, raised over the shoulder.
    _wing(canvas, const Offset(30, -90), 0, 1, scale, const Color(0xFFF59A55));
  }

  /// Overlapping armor plates give the torso a faceted, scaled silhouette.
  void _paintArmorPlates(Canvas canvas, double breath) {
    const edge = Color(0xFF7F291F);
    final plate = Paint()..color = _c(const Color(0xFFFFB13A));
    final plateEdge = Paint()
      ..color = _c(edge)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeJoin = StrokeJoin.round;
    final chest = Path()
      ..moveTo(-22, -78)
      ..lineTo(8, -87 - breath * 3)
      ..lineTo(34, -77)
      ..lineTo(20, -48)
      ..lineTo(-10, -48)
      ..close();
    canvas.drawPath(chest, plate);
    canvas.drawPath(chest, plateEdge);
    final ribs = Paint()
      ..color = _c(const Color(0xFFE8B464))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    for (var i = 0; i < 3; i++) {
      final y = -68.0 + i * 11;
      canvas.drawArc(
          Rect.fromCenter(center: Offset(8, y), width: 55, height: 22),
          .35,
          2.45,
          false,
          ribs);
    }
    // Individual back scales alternate their tilt as the body breathes.
    for (var row = 0; row < 3; row++) {
      for (var col = 0; col < 5; col++) {
        final x = 27.0 + col * 10 + (row.isEven ? 3 : 0);
        final y = -88.0 + row * 13 + sin(_t * 2 + col) * breath * 1.2;
        final scale = Path()
          ..moveTo(x - 5, y)
          ..lineTo(x, y - 7)
          ..lineTo(x + 6, y)
          ..lineTo(x, y + 5)
          ..close();
        canvas.drawPath(scale, plate);
        canvas.drawPath(scale, plateEdge);
      }
    }
  }

  /// All bones share one beat. Fixed-length links rotate about their parent;
  /// delayed folding narrows the recovery stroke and opens the power stroke.
  void _wing(Canvas canvas, Offset root, double phaseOffset, double size,
      Color bone, Color skin) {
    final beat = _wingPhase + phaseOffset;
    final sweep = sin(beat);
    final balance = _tailMove?.wingSpread ?? _castSpread;
    // Grounded wings rest folded; flight opens them for each power stroke.
    final restingFold = .88 - .35 * _evolution + .04 * cos(beat);
    final flightFold = .08 + .82 * _smoothUnit(.5 + .5 * cos(beat - .45));
    final fold = (restingFold + (flightFold - restingFold) * _flightBlend) *
        (1 - balance * .75);
    Offset link(Offset from, double length, double angle) =>
        from + Offset(cos(angle), sin(angle)) * length;
    final shoulder = -1.38 -
        .55 * _evolution +
        fold * .85 +
        sweep * (.07 + .48 * _flightBlend) -
        balance * .28;
    final elbow = link(Offset.zero, 39, shoulder);
    // Fold rearward along the outer flank, never back through the shoulder.
    final forearm = shoulder + .57 + fold * 1.05 - balance * .18;
    final wrist = link(elbow, 47, forearm);
    final lag = sin(beat - .5) * (.025 + .12 * _flightBlend);
    final spread = 1 - fold * .9 + balance * .18;
    final openFingerBase = forearm + .2 + lag;
    final fingerBase = openFingerBase + (1.15 - openFingerBase) * fold;
    final tips = [
      link(wrist, 34, fingerBase - .65 * spread),
      link(wrist, 60, fingerBase + .44 * spread),
      link(wrist, 79, fingerBase + 1.04 * spread),
    ];
    // The membrane closes on the flank; this anchor never follows the wrist.
    const anchor = Offset(35, 6);
    final billow = sin(beat - .85) * (1 + 3 * _flightBlend) * (1 - fold);
    Offset scallop(Offset a, Offset b) =>
        (a + b) * .5 + (wrist - (a + b) * .5) * .36 + Offset(0, billow);
    final c01 = scallop(tips[0], tips[1]);
    final c12 = scallop(tips[1], tips[2]);
    final c2a = (tips[2] + anchor) * .5 +
        Offset(-12 * (1 - fold * .8), -9 * (1 - fold) + billow);
    final notch = Offset.lerp(c12, wrist, .22 * _evolution)!;
    final membrane = Path()
      ..moveTo(0, 0)
      ..lineTo(elbow.dx, elbow.dy)
      ..lineTo(wrist.dx, wrist.dy)
      ..lineTo(tips[0].dx, tips[0].dy)
      ..quadraticBezierTo(c01.dx, c01.dy, tips[1].dx, tips[1].dy)
      ..quadraticBezierTo(c12.dx, c12.dy, notch.dx, notch.dy)
      ..lineTo(notch.dx + 4 * _evolution, notch.dy + 10 * _evolution)
      ..lineTo(notch.dx + 10 * _evolution, notch.dy + 3 * _evolution)
      ..quadraticBezierTo(c12.dx, c12.dy, tips[2].dx, tips[2].dy)
      ..quadraticBezierTo(c2a.dx, c2a.dy, anchor.dx, anchor.dy)
      ..quadraticBezierTo(18, -4, 0, 0)
      ..close();
    canvas.save();
    canvas.translate(root.dx, root.dy);
    canvas.scale(size * (1 + .18 * _evolution));
    _shape(canvas, membrane,
        Color.lerp(skin, const Color(0xFFAC3D30), _evolution * .65)!);
    canvas.save();
    canvas.clipPath(membrane);
    if (_evolution > 0) {
      for (var panel = 0; panel < 3; panel++) {
        final end = panel < 2
            ? (tips[panel] + tips[panel + 1]) * .5
            : (tips[2] + anchor) * .5;
        final next = panel < 2 ? tips[panel + 1] : anchor;
        final section = Path()
          ..moveTo(wrist.dx, wrist.dy)
          ..lineTo(tips[panel].dx, tips[panel].dy)
          ..quadraticBezierTo(end.dx - 4, end.dy - 5, next.dx, next.dy)
          ..close();
        canvas.drawPath(
            section,
            Paint()
              ..shader = const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xBBE27B83),
                  Color(0x226F243F),
                  Color(0xAA421E35)
                ],
                stops: [0, .45, 1],
              ).createShader(section.getBounds()));
        canvas.drawPath(
            Path()
              ..moveTo(wrist.dx, wrist.dy)
              ..quadraticBezierTo((wrist.dx + next.dx) * .5 + 4,
                  (wrist.dy + next.dy) * .5, next.dx, next.dy),
            Paint()
              ..color = const Color(0xAA652A41)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3);
        for (var v = 1; v < 5; v++) {
          final t = v / 5;
          final start = Offset.lerp(wrist, end, t)!;
          final finish =
              Offset.lerp(wrist, tips[panel], (t + .13).clamp(0.0, 1.0))!;
          final vein = Path()
            ..moveTo(start.dx, start.dy)
            ..quadraticBezierTo((start.dx + finish.dx) * .5 + 3,
                (start.dy + finish.dy) * .5 + 2, finish.dx, finish.dy);
          canvas.drawPath(
              vein,
              Paint()
                ..color = const Color(0x44602C43)
                ..style = PaintingStyle.stroke
                ..strokeWidth = .8);
        }
        final a = Offset.lerp(wrist, tips[panel], .14)!;
        final b = Offset.lerp(wrist, end, .85)!;
        canvas.drawPath(
            Path()
              ..moveTo(a.dx, a.dy)
              ..quadraticBezierTo(b.dx - 5, b.dy - 8, b.dx, b.dy),
            Paint()
              ..color = const Color(0x33FFA8A0)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2);
      }
    }

    canvas.drawPath(
        Path()
          ..moveTo(wrist.dx, wrist.dy)
          ..lineTo(tips[2].dx, tips[2].dy)
          ..lineTo(anchor.dx, anchor.dy)
          ..close(),
        Paint()..color = _c(const Color(0x33852A22)));
    canvas.restore();
    final arm = Path()
      ..moveTo(0, 0)
      ..lineTo(elbow.dx, elbow.dy)
      ..lineTo(wrist.dx, wrist.dy);
    canvas.drawPath(arm, _outline..strokeWidth = 8);
    canvas.drawPath(
        arm,
        Paint()
          ..color = _c(bone)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4.5
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round);
    for (final tip in tips) {
      final mid = (wrist + tip) * .5 + Offset(0, billow * .25);
      final finger = Path()
        ..moveTo(wrist.dx, wrist.dy)
        ..quadraticBezierTo(mid.dx, mid.dy, tip.dx, tip.dy);
      canvas.drawPath(finger, _outline..strokeWidth = 4);
      canvas.drawPath(
          finger,
          Paint()
            ..color = _c(bone)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
      _magma(canvas, finger);
    }
    for (var i = 1; i < 3; i++) {
      final ribEnd = (wrist + tips[i]) * .5;
      canvas.drawLine(
          anchor,
          ribEnd,
          Paint()
            ..color = _c(Color.fromARGB((100 + 70 * fold).round(), 127, 41, 31))
            ..strokeWidth = 1 + fold);
    }
    // The claw follows the wrist orientation rather than sliding over it.
    canvas.save();
    canvas.translate(wrist.dx, wrist.dy);
    canvas.rotate(forearm + pi / 2);
    _shape(
        canvas,
        Path()
          ..moveTo(-3, 0)
          ..quadraticBezierTo(-15, -9, -8, -21)
          ..quadraticBezierTo(-7, -8, 4, -3)
          ..close(),
        const Color(0xFFFFF0C8));
    canvas.restore();
    canvas.restore();
  }
}
