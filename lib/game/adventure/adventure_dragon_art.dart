part of 'adventure_dragon.dart';

extension _DragonArt on AdventureDragon {
  // ---- Look ------------------------------------------------------------------

  void _renderDragon(Canvas canvas) {
    var lift = _diveLift, drift = 0.0, shrink = 1.0;
    if (intro) {
      final k = (_intro / 1.1).clamp(0.0, 1.0);
      lift = -380 * pow(1 - k, 2).toDouble();
    }
    if (defeated) {
      final k =
          ((_death - .7) / (AdventureDragon.fleeTime - .7)).clamp(0.0, 1.0);
      lift = -420 * k * k;
      drift = 260 * k;
      shrink = 1 - .5 * k;
    }
    final shake =
        (defeated && _death < .7) || (intro && _intro > 1.1 && _intro < 1.8)
            ? sin(_t * 70) * 3
            : 0.0;
    canvas.save();
    // Shadow stays on the ground while the dragon flies.
    final shadowK = 1 - min(1.0, -lift / 380);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(
                _diveShift.x + drift * _scale + 10 * _scale, _diveShift.y + 2),
            width: 200 * _scale * shadowK,
            height: 34 * _scale * shadowK),
        Paint()
          ..color = Color.fromARGB((70 * shadowK).round(), 0x30, 0x10, 0x08));
    canvas.translate(_diveShift.x + drift * _scale + shake,
        _diveShift.y + lift + _bodyBob * shadowK);
    canvas.scale(_scale * shrink);
    if (evolving) _paintEvolutionBurst(canvas);
    if (intro && _intro > 1.0 && _intro < 1.5) {
      _landingDust(canvas, (_intro - 1) / .5);
    }
    final tail = _tailMove;
    canvas.save();
    canvas.translate(15, -8);
    canvas.rotate(_bodyTurn);
    // Ground-plane yaw keeps the dragon upright while its whole body turns.
    canvas.transform(Float64List.fromList([
      cos(_bodyYaw),
      sin(_bodyYaw) * .32,
      0,
      0,
      0,
      1,
      0,
      0,
      0,
      0,
      1,
      0,
      0,
      0,
      0,
      1,
    ]));
    canvas.translate(-15 + _bodyOffset.x, 8 + _bodyOffset.y);
    // The tail and hip share this transform. Drawing the root underneath the
    // torso hides the seam at every angle, including the edge-on spin pose.
    _paintTail(
        canvas,
        tail?.localCenterline ??
            _dragonTailPoints(const Offset(62, -32), 1, _t));
    final profile = _smoothUnit((cos(_bodyYaw).abs() - .08) / .42);
    // Opacity layers are full-screen offscreen passes; only pay for one while
    // the fade is actually visible.
    if (profile > .02) {
      if (profile < .98) {
        canvas.saveLayer(
            null,
            Paint()
              ..color = Color.fromARGB((255 * profile).round(), 255, 255, 255));
      }
      _paintBody(canvas);
      if (tired > 0 && !defeated) _paintDizzy(canvas);
      if (frozen > 0) _paintIce(canvas);
      if (profile < .98) canvas.restore();
    }
    canvas.restore();
    if (profile < .98) _paintTurnedBody(canvas, 1 - profile);
    if (evolving) {
      final flash =
          (1 - ((_evolutionProgress - .69) / .09).abs()).clamp(0.0, 1.0);
      final halo = Rect.fromCenter(
          center: const Offset(5, -95), width: 260, height: 290);
      canvas.drawOval(
          halo,
          Paint()
            ..shader = RadialGradient(colors: [
              const Color(0xFFFFEBD2).withValues(alpha: flash * .45),
              const Color(0x00FFEBD2),
            ]).createShader(halo));
    }
    canvas.restore();
  }

  /// Front/back silhouettes bridge the two profiles, preserving body volume
  /// at quarter turns instead of squeezing a side-view drawing to a line.
  void _paintTurnedBody(Canvas canvas, double opacity) {
    if (_evolution >= .5) {
      _paintAscendedTurnedBody(canvas, opacity);
      return;
    }
    final front = sin(_bodyYaw) > 0;
    canvas.saveLayer(
        null,
        Paint()
          ..color = Color.fromARGB((255 * opacity).round(), 255, 255, 255));
    canvas.translate(15, -8);
    canvas.rotate(_bodyTurn);
    canvas.translate(-15 + cos(_bodyYaw) * _bodyOffset.x,
        8 + _bodyOffset.y + sin(_bodyYaw) * _bodyOffset.x * .32);
    for (final side in [-1.0, 1.0]) {
      canvas.save();
      canvas.translate(15, 0);
      canvas.scale(side * .62, .78);
      _wing(canvas, const Offset(0, -91), side * .07, 1,
          const Color(0xFFCD4C38), const Color(0xFFE88B4B));
      canvas.restore();
    }
    final body = Path()
      ..moveTo(-15 - 12 * _evolution, -79)
      ..quadraticBezierTo(15, -102 - 16 * _evolution, 45 + 12 * _evolution, -79)
      ..lineTo(43, -29)
      ..quadraticBezierTo(15, -5, -13, -29)
      ..close();
    _shape(canvas, body,
        front ? const Color(0xFFE45B40) : const Color(0xFFB94130));
    if (front) {
      final belly = Path()
        ..moveTo(15, -85)
        ..quadraticBezierTo(38, -62, 32, -32)
        ..quadraticBezierTo(15, -18, -2, -32)
        ..quadraticBezierTo(-8, -62, 15, -85)
        ..close();
      _shape(canvas, belly, const Color(0xFFFFD98A));
      for (var i = 0; i < 4; i++) {
        final y = -68.0 + i * 11;
        canvas.drawArc(
            Rect.fromCenter(center: Offset(15, y), width: 30, height: 9),
            .2,
            2.7,
            false,
            Paint()
              ..color = _c(const Color(0xFFCC9958))
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.8);
      }
    } else {
      for (var row = 0; row < 4; row++) {
        final y = -77.0 + row * 12;
        for (final side in [-1.0, 1.0]) {
          _shape(
              canvas,
              Path()
                ..addPolygon([
                  Offset(15 + side * 8, y - 5),
                  Offset(15 + side * 21, y),
                  Offset(15 + side * 8, y + 6),
                ], true),
              const Color(0xFFE28C48));
        }
        _shape(
            canvas,
            Path()
              ..addPolygon([
                Offset(10, y + 2),
                Offset(15, y - 12 - 10 * _evolution),
                Offset(20, y + 2),
              ], true),
            const Color(0xFFFFBA47));
      }
    }
    _paintEvolutionArmor(canvas, turned: true);
    for (final side in [-1.0, 1.0]) {
      final x = 15 + side * 22;
      _shape(
          canvas,
          Path()
            ..addPolygon([
              Offset(x - 8, -29),
              Offset(x + 8, -29),
              Offset(x + 11, -2),
              Offset(x - 11, -2),
            ], true),
          const Color(0xFFD25338));
      for (var i = 0; i < 3; i++) {
        final c = x - 7 + i * 7.0;
        _shape(
            canvas,
            Path()
              ..addPolygon([
                Offset(c - 3, -2),
                Offset(c, 5),
                Offset(c + 3, -2),
              ], true),
            const Color(0xFFFFEED0));
      }
    }
    final hy = _head.y + sin(_bodyYaw) * (_head.x - 15) * .32;
    _shape(
        canvas,
        Path()
          ..addRRect(RRect.fromRectAndRadius(
              Rect.fromCenter(
                  center: Offset(15, hy + 17), width: 23, height: 34),
              const Radius.circular(9))),
        const Color(0xFFD6533C));
    for (final side in [-1.0, 1.0]) {
      final x = 15 + side * 18;
      _shape(
          canvas,
          Path()
            ..addPolygon([
              Offset(x - 5, hy - 12),
              Offset(
                  x + side * (9 + 12 * _evolution), hy - 35 - 18 * _evolution),
              Offset(x + 5, hy - 9),
            ], true),
          const Color(0xFFFFEAC0));
    }
    _shape(
        canvas,
        Path()
          ..addPolygon([
            Offset(-10, hy - 9),
            Offset(0, hy - 20),
            Offset(30, hy - 20),
            Offset(40, hy - 9),
            Offset(35, hy + 15),
            Offset(-5, hy + 15),
          ], true),
        front ? const Color(0xFFE66B46) : const Color(0xFFC34835));
    if (front) {
      for (final side in [-1.0, 1.0]) {
        final eye = Offset(15 + side * 11, hy - 4);
        canvas.drawOval(
            Rect.fromCenter(center: eye, width: 12, height: 15),
            Paint()
              ..color = Color.lerp(const Color(0xFFFFF2D2),
                  const Color(0xFFFF8D32), _evolution)!);
        canvas.drawOval(Rect.fromCenter(center: eye, width: 4, height: 11),
            Paint()..color = const Color(0xFF3A1B13));
      }
      _shape(
          canvas,
          Path()
            ..addRRect(RRect.fromRectAndRadius(
                Rect.fromCenter(
                    center: Offset(15, hy + 11), width: 31, height: 14),
                const Radius.circular(5))),
          const Color(0xFFF28D56));
      for (final side in [-1.0, 1.0]) {
        canvas.drawCircle(Offset(15 + side * 7, hy + 9), 2,
            Paint()..color = AdventureDragon._ink);
      }
    } else {
      _shape(
          canvas,
          Path()
            ..addPolygon([
              Offset(10, hy - 10),
              Offset(15, hy - 28),
              Offset(20, hy - 10),
            ], true),
          const Color(0xFFFFB13A));
    }
    if (frozen > 0) _paintIce(canvas);
    canvas.restore();
  }

  void _paintAscendedTurnedBody(Canvas canvas, double opacity) {
    final front = sin(_bodyYaw) > 0;
    canvas.saveLayer(null,
        Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: opacity));
    canvas.translate(15, -8);
    canvas.rotate(_bodyTurn);
    canvas.translate(-15 + cos(_bodyYaw) * _bodyOffset.x,
        8 + _bodyOffset.y + sin(_bodyYaw) * _bodyOffset.x * .32);
    for (final side in [-1.0, 1.0]) {
      canvas.save();
      canvas.translate(15, 0);
      canvas.scale(side * .7, .9);
      _wing(canvas, const Offset(0, -132), side * .07, 1.4,
          const Color(0xFFD36677), const Color(0xFF96364F));
      canvas.restore();
    }
    _shape(
        canvas,
        Path()
          ..moveTo(-11, -123)
          ..quadraticBezierTo(15, -144, 41, -123)
          ..lineTo(49, -55)
          ..quadraticBezierTo(15, -21, -19, -55)
          ..close(),
        const Color(0xFF37334F));
    final hy = _head.y + sin(_bodyYaw) * (_head.x - 15) * .32;
    _shape(
        canvas,
        Path()
          ..moveTo(4, hy + 8)
          ..lineTo(26, hy + 8)
          ..lineTo(33, -68)
          ..quadraticBezierTo(15, -39, -3, -68)
          ..close(),
        front ? const Color(0xFFFFDB8B) : const Color(0xFFBB4D63));
    for (final side in [-1.0, 1.0]) {
      final x = 15 + side * 26;
      _shape(
          canvas,
          Path()
            ..addPolygon([
              Offset(x - 12, -62),
              Offset(x + 13, -62),
              Offset(x + 15, -35),
              Offset(x + 8, -15),
              Offset(x + 17, 3),
              Offset(x - 16, 3),
              Offset(x - 13, -17),
            ], true),
          const Color(0xFF37334F));
      _shape(
          canvas,
          Path()
            ..addOval(
                Rect.fromCenter(center: Offset(x, -50), width: 23, height: 30)),
          const Color(0xFFBB4D63));
      for (var i = 0; i < 3; i++) {
        final c = x - 9 + i * 8;
        _shape(
            canvas,
            Path()
              ..addPolygon([
                Offset(c - 3, 0),
                Offset(c + 3, 0),
                Offset(c + 2, 8),
                Offset(c - 5, 6)
              ], true),
            const Color(0xFFBFC0D3));
      }
      _shape(
          canvas,
          Path()
            ..addPolygon([
              Offset(15 + side * 29, -116),
              Offset(15 + side * 40, -105),
              Offset(15 + side * 44, -78),
              Offset(15 + side * 30, -75),
            ], true),
          const Color(0xFF37334F));
      _shape(
          canvas,
          Path()
            ..addPolygon([
              Offset(15 + side * 16, hy - 12),
              Offset(15 + side * 32, hy - 49),
              Offset(15 + side * 7, hy - 14),
            ], true),
          const Color(0xFFBB4D63));
    }
    _shape(
        canvas,
        Path()
          ..addPolygon([
            Offset(-10, hy - 15),
            Offset(1, hy - 27),
            Offset(29, hy - 27),
            Offset(40, hy - 15),
            Offset(33, hy + 15),
            Offset(-3, hy + 15),
          ], true),
        const Color(0xFFC7586A));
    if (front) {
      for (final side in [-1.0, 1.0]) {
        _shape(
            canvas,
            Path()
              ..addPolygon([
                Offset(15 + side * 5, hy - 5),
                Offset(15 + side * 20, hy - 11),
                Offset(15 + side * 15, hy + 1),
              ], true),
            const Color(0xFFFFEBC2));
      }
      _shape(
          canvas,
          Path()
            ..addPolygon([
              Offset(0, hy + 6),
              Offset(30, hy + 6),
              Offset(27, hy + 16),
              Offset(3, hy + 16),
            ], true),
          const Color(0xFF38324F));
    }
    if (frozen > 0) _paintIce(canvas);
    canvas.restore();
  }

  Color _c(Color base) {
    var c = base;
    if (_evolution > 0 && base.r > base.g * 1.25) {
      final evolved = base.g * 255 > 120
          ? const Color(0xFFD36B3E)
          : const Color(0xFFA64157);
      c = Color.lerp(c, evolved, .65 * _evolution)!;
    }
    if (frozen > 0) c = Color.lerp(c, const Color(0xFFBFE6FF), .45)!;
    if (_hurtFlash > 0 ||
        (defeated && _death < .7 && (_t * 12).floor().isEven)) {
      c = Color.lerp(c, const Color(0xFFFFFFFF), .5)!;
    }
    return c;
  }

  Paint get _outline => Paint()
    ..color = AdventureDragon._ink
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.6
    ..strokeJoin = StrokeJoin.round
    ..strokeCap = StrokeCap.round;

  void _shape(Canvas canvas, Path path, Color color) {
    final paint = Paint()..color = _c(color);
    final bounds = path.getBounds();
    if (_evolution > 0 && bounds.width > 8 && bounds.height > 8) {
      final base = _c(color);
      paint.shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        stops: const [0, .35, .7, 1],
        colors: [
          Color.lerp(base, const Color(0xFFFFBC9C), .22 * _evolution)!,
          base,
          Color.lerp(base, const Color(0xFF261B37), .18 * _evolution)!,
          Color.lerp(base, const Color(0xFF1D1730), .45 * _evolution)!,
        ],
      ).createShader(bounds);
    }
    canvas.drawPath(path, paint);
    canvas.drawPath(path, _outline);
  }

  /// Small overlapping plates are clipped to their moving anatomical surface.
  void _scaleDetail(Canvas canvas, Path surface, {double spacing = 9}) {
    final bounds = surface.getBounds();
    canvas.save();
    canvas.clipPath(surface);
    final plates = Path();
    final highlights = Path();
    var row = 0;
    for (var y = bounds.top + spacing * .5;
        y < bounds.bottom;
        y += spacing * .72) {
      for (var x = bounds.left + (row.isEven ? 0 : spacing * .5);
          x < bounds.right;
          x += spacing) {
        plates
          ..moveTo(x - spacing * .42, y)
          ..lineTo(x, y - spacing * .25)
          ..lineTo(x + spacing * .42, y)
          ..lineTo(x + spacing * .25, y + spacing * .36)
          ..lineTo(x, y + spacing * .55)
          ..lineTo(x - spacing * .25, y + spacing * .36);
        highlights
          ..moveTo(x - spacing * .3, y)
          ..lineTo(x, y - spacing * .18);
      }
      row++;
    }
    canvas.drawPath(
        plates,
        Paint()
          ..color = const Color(0x55201732)
          ..style = PaintingStyle.stroke
          ..strokeWidth = .8);
    canvas.drawPath(
        highlights,
        Paint()
          ..color = const Color(0x66EEA2A3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = .9);
    canvas.restore();
  }

  void _magma(Canvas canvas, Path path) {
    if (_evolution <= 0) return;
    final pulse = .8 + .2 * sin(_t * 6);
    final color =
        frozen > 0 ? const Color(0xFF70CDFF) : const Color(0xFFFF492A);
    for (final layer in [(8.0, .25), (3.0, .95), (1.0, .9)]) {
      canvas.drawPath(
          path,
          Paint()
            ..color = (layer.$1 == 1 ? const Color(0xFFFFE49A) : color)
                .withValues(alpha: layer.$2 * _evolution * pulse)
            ..style = PaintingStyle.stroke
            ..strokeWidth = layer.$1
            ..strokeJoin = StrokeJoin.round
            ..strokeCap = StrokeCap.round);
    }
  }

  void _paintEvolutionArmor(Canvas canvas, {bool turned = false}) {
    final growth = _evolution;
    if (growth <= 0) return;
    for (var i = 0; i < 3; i++) {
      final y = -80.0 + i * 18;
      final x = turned ? 15.0 : 48.0 + i * 5;
      final width = (turned ? 21 : 16) * growth;
      _shape(
          canvas,
          Path()
            ..addPolygon([
              Offset(x - width, y),
              Offset(x, y - 6 * growth),
              Offset(x + width, y),
              Offset(x + width * .7, y + 9),
              Offset(x, y + 5),
              Offset(x - width * .7, y + 9),
            ], true),
          const Color(0xFFB95635));
      canvas.drawPath(
          Path()
            ..moveTo(x - width, y)
            ..lineTo(x, y - 6 * growth)
            ..lineTo(x + width, y),
          Paint()
            ..color = const Color(0xFFFFBC70).withValues(alpha: growth * .8)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5);
      _magma(
          canvas,
          Path()
            ..moveTo(x - width * .75, y + 2)
            ..lineTo(x, y + 8)
            ..lineTo(x + width * .75, y + 2));
    }
    if (!turned) {
      _magma(
          canvas,
          Path()
            ..moveTo(13, -72)
            ..lineTo(20, -60)
            ..lineTo(13, -48)
            ..lineTo(21, -35));
    }
  }

  void _paintEvolutionBurst(Canvas canvas) {
    final p = _evolutionProgress;
    final charge = _smoothUnit(p / .58);
    final release = _smoothUnit((p - .58) / .18);
    final fade = 1 - _smoothUnit((p - .84) / .16);
    final pulse = .8 + .2 * sin(_evolutionT * 17);
    final aura = Rect.fromCenter(
        center: const Offset(5, -100),
        width: 150 + charge * 90,
        height: 190 + charge * 110);
    canvas.drawOval(
        aura,
        Paint()
          ..shader = RadialGradient(colors: [
            Color.fromRGBO(255, 164, 96, .3 * charge * fade * pulse),
            Color.fromRGBO(182, 72, 145, .2 * charge * fade),
            const Color(0x00B64891),
          ]).createShader(aura));
    // Ground waves push out first, then tighten as energy gathers.
    for (var i = 0; i < 3; i++) {
      final cycle = ((_evolutionT * .65 + i / 3) % 1);
      final radius = 35 + cycle * (90 + release * 100);
      canvas.drawOval(
          Rect.fromCenter(
              center: const Offset(15, 0),
              width: radius * 2,
              height: radius * .55),
          Paint()
            ..color = const Color(0xFFFFAC78)
                .withValues(alpha: (1 - cycle) * fade * .65)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2 + charge);
    }
    // Embers spiral up around the silhouette throughout the longer windup.
    for (var i = 0; i < 26; i++) {
      final life = ((_evolutionT * .48 + i / 26) % 1);
      final a = i * 2.4 + _evolutionT * 2;
      final x = 10 + cos(a) * (70 + charge * 24) * (1 - life * .3);
      final y = -life * (200 + charge * 70);
      canvas.drawLine(
          Offset(x, y + 8),
          Offset(x + sin(a) * 3, y),
          Paint()
            ..color =
                (i.isEven ? const Color(0xFFFFD99B) : const Color(0xFFF994C4))
                    .withValues(alpha: (1 - life) * fade * (.35 + .65 * charge))
            ..strokeWidth = 1.5 + i % 3
            ..strokeCap = StrokeCap.round);
    }
    final burst = (1 - ((p - .7) / .15).abs()).clamp(0.0, 1.0);
    if (burst > 0) {
      for (var i = 0; i < 12; i++) {
        final a = i * pi / 6 + .15;
        final from = Offset(5 + cos(a) * 35, -90 + sin(a) * 45);
        final to = Offset(5 + cos(a) * (95 + release * 70),
            -90 + sin(a) * (115 + release * 60));
        canvas.drawLine(
            from,
            to,
            Paint()
              ..color = const Color(0xFFFFE5AD).withValues(alpha: burst * .65)
              ..strokeWidth = 2 + burst * 2
              ..strokeCap = StrokeCap.round);
      }
    }
  }

  void _paintTail(Canvas canvas, List<Offset> points) {
    Offset tangent(int i) {
      final d = points[min(i + 1, points.length - 1)] - points[max(0, i - 1)];
      return d.distance > .001 ? d / d.distance : const Offset(1, 0);
    }

    Offset normal(int i) {
      final d = tangent(i);
      return Offset(-d.dy, d.dx);
    }

    double width(int i) =>
        (15 + 6 * _evolution) * (1 - i / (points.length - 1)) + 2;
    final shape = Path();
    for (var i = 0; i < points.length; i++) {
      final p = points[i] + normal(i) * width(i);
      if (i == 0) {
        shape.moveTo(p.dx, p.dy);
      } else {
        shape.lineTo(p.dx, p.dy);
      }
    }
    for (var i = points.length - 1; i >= 0; i--) {
      final p = points[i] - normal(i) * width(i);
      shape.lineTo(p.dx, p.dy);
    }
    shape.close();
    _shape(
        canvas,
        shape,
        Color.lerp(
            const Color(0xFFE0533D), const Color(0xFF33304E), _evolution)!);
    final ridge = Path();
    for (var i = 0; i < points.length; i++) {
      final p = points[i] - normal(i) * width(i) * .55;
      if (i == 0) {
        ridge.moveTo(p.dx, p.dy);
      } else {
        ridge.lineTo(p.dx, p.dy);
      }
    }
    canvas.drawPath(
        ridge,
        Paint()
          ..color = _c(const Color(0xFFF68B52))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round);
    if (_evolution > 0) {
      for (var i = 1; i < points.length - 1; i++) {
        final p = points[i];
        final n = normal(i);
        final d = tangent(i);
        final w = width(i);
        canvas.drawPath(
            Path()
              ..moveTo(p.dx - n.dx * w * .7, p.dy - n.dy * w * .7)
              ..quadraticBezierTo(p.dx - d.dx * 4, p.dy - d.dy * 4,
                  p.dx + n.dx * w * .8, p.dy + n.dy * w * .8),
            Paint()
              ..color = const Color(0xFF83687D)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1);
        canvas.drawLine(
            p + n * w * .75 - d * 3,
            p + n * w * .75 + d * 3,
            Paint()
              ..color = const Color(0xFFDDAC79)
              ..strokeWidth = 2);
      }
    }
    for (var i = 3; i < points.length - 2; i += 3) {
      final p = points[i] - normal(i) * width(i);
      final n = normal(i), d = tangent(i);
      _shape(
          canvas,
          Path()
            ..addPolygon([
              p - d * 4,
              p - n * (10 + 2 * _evolution) + d * 3,
              p + d * 7,
            ], true),
          const Color(0xFFFFB13A));
      canvas.drawLine(
          points[i] - n * width(i) * .4,
          points[i] + n * width(i) * .8,
          Paint()
            ..color = _c(const Color(0xFFAC3E2D))
            ..strokeWidth = 1.2);
    }
    final last = points.length - 1;
    final tip = points.last, d = tangent(last), n = normal(last);
    _shape(
        canvas,
        Path()
          ..addPolygon([
            tip + d * (16 + 4 * _evolution),
            tip - d * 5 + n * (10 + 5 * _evolution),
            tip - d * 1,
            tip - d * 5 - n * (10 + 5 * _evolution),
          ], true),
        const Color(0xFFFFB13A));
  }

  /// Upright, two-legged silhouette based on the user's red/violet reference.
}
