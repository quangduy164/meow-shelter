part of 'adventure_dragon.dart';

extension _DragonHeadArt on AdventureDragon {
  void _paintHead(Canvas canvas, Offset h) {
    if (_evolution >= .5) {
      _paintAscendedHead(canvas, h);
      return;
    }

    const scale = Color(0xFFE0533D);
    const horn = Color(0xFFFFF0C8);
    canvas.save();
    canvas.translate(h.dx, h.dy);
    canvas.rotate(_headPitch);
    canvas.scale(_headSize);
    // Low nape spines sit behind the ivory horns, leaving their roots visible.
    if (_evolution > 0) {
      for (var i = 0; i < 3; i++) {
        final x = 28.0 + i * 8;
        final y = -3.0 + i * 9;
        _shape(
            canvas,
            Path()
              ..addPolygon([
                Offset(x - 5, y),
                Offset(x + 11 * _evolution, y - 10 * _evolution),
                Offset(x + 5, y + 7),
              ], true),
            const Color(0xFFECA653));
      }
    }
    // Swept, faceted horns stay low behind the skull instead of reading as ears.
    for (final o in const [Offset(27, -9), Offset(9, -24)]) {
      final g = _evolution;
      final length = o.dx > 20 ? 46.0 : 54.0;
      final points = [
        o + Offset(-6 - 2 * g, 5),
        o + Offset(2 + 5 * g, -17 - 4 * g),
        o + Offset(19 + 7 * g, -26 - 3 * g),
        o + Offset(30 + (length - 30) * g, -26 - 4 * g),
        o + Offset(18 + 14 * g, -11 - 2 * g),
        o + Offset(8 + 3 * g, 6),
      ];
      _shape(canvas, Path()..addPolygon(points, true),
          Color.lerp(horn, const Color(0xFFE6BD7C), g)!);
      canvas.drawPath(
          Path()
            ..addPolygon([
              points[0],
              points[1],
              points[2],
              points[3],
              o + const Offset(9, -7),
            ], true),
          Paint()..color = const Color(0xFFFFEAC0).withValues(alpha: .65));
      for (var i = 0; i < 3; i++) {
        final t = .2 + i * .2;
        final top = Offset.lerp(points[1], points[3], t)!;
        final bottom = Offset.lerp(points[5], points[3], t)!;
        canvas.drawLine(
            top,
            bottom,
            Paint()
              ..color = const Color(0xFF98623A).withValues(alpha: .7)
              ..strokeWidth = 1.3);
      }
      if (g > 0) {
        _shape(
            canvas,
            Path()
              ..addPolygon([
                o + const Offset(-9, 5),
                o + const Offset(-3, -10),
                o + const Offset(9, -8),
                o + const Offset(14, 5),
                o + const Offset(3, 10),
              ], true),
            const Color(0xFFB55437));
      }
    }
    // Ear fin.
    _shape(
        canvas,
        Path()
          ..moveTo(18, -2)
          ..lineTo(40, -8)
          ..lineTo(34, 4)
          ..lineTo(42, 12)
          ..lineTo(18, 10)
          ..close(),
        const Color(0xFFFFB13A));
    // Lower jaw, swinging open.
    canvas.save();
    canvas.translate(-6, 14);
    canvas.rotate(-.52 * _jaw);
    final jaw = Path()
      ..addRRect(RRect.fromRectAndRadius(
          const Rect.fromLTWH(-42, -4, 42, 16), const Radius.circular(8)));
    if (_mouth > .05) {
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              const Rect.fromLTWH(-38, -10, 36, 12), const Radius.circular(6)),
          Paint()..color = const Color(0xFF7A1E1E));
    }
    _shape(canvas, jaw, const Color(0xFFFFD98A));
    canvas.restore();
    // Long angular muzzle, cheek ridge and armored crown.
    final head = Path()
      ..moveTo(25, 9)
      ..lineTo(26, -12)
      ..lineTo(10, -30)
      ..lineTo(-10, -31)
      ..lineTo(-24, -19)
      ..lineTo(-29, -7)
      ..lineTo(-49, -7)
      ..lineTo(-56, 0)
      ..lineTo(-53, 14)
      ..lineTo(-40, 20)
      ..lineTo(-14, 18)
      ..lineTo(-2, 24)
      ..lineTo(15, 20)
      ..close();
    _shape(canvas, head, scale);
    if (_evolution > 0) {
      _shape(
          canvas,
          Path()
            ..addPolygon([
              const Offset(-24, -19),
              Offset(-53 - 6 * _evolution, -14),
              Offset(-60 - 4 * _evolution, -1),
              const Offset(-51, 13),
              const Offset(-28, 10),
            ], true),
          scale);
      for (final x in [-43.0, -25.0]) {
        _shape(
            canvas,
            Path()
              ..addPolygon([
                Offset(x - 3, 10),
                Offset(x - 1, 10 + 17 * _evolution),
                Offset(x + 5, 11),
              ], true),
            horn);
      }
    }
    final cheek = Path()
      ..moveTo(22, -10)
      ..lineTo(5, -16)
      ..lineTo(-3, -1)
      ..lineTo(-19, 13)
      ..lineTo(-2, 23)
      ..lineTo(15, 19)
      ..close();
    canvas.drawPath(cheek, Paint()..color = _c(const Color(0xFFB23A2C)));
    if (_evolution > 0) {
      _magma(
          canvas,
          Path()
            ..moveTo(17, -14)
            ..lineTo(6, -8)
            ..lineTo(12, 2)
            ..lineTo(1, 12));
    }
    canvas.drawPath(
        Path()
          ..moveTo(-49, -5)
          ..lineTo(-28, -3)
          ..lineTo(-14, -20)
          ..lineTo(5, -26)
          ..lineTo(18, -16),
        Paint()
          ..color = _c(const Color(0xFFFF9A62))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeJoin = StrokeJoin.round);
    // Scutes down the cheek and snout.
    for (var i = 0; i < 3; i++) {
      final x = 4.0 + i * 6;
      final y = 4.0 + i * 3;
      final scute = Path()
        ..moveTo(x - 4, y)
        ..lineTo(x, y - 4)
        ..lineTo(x + 4, y)
        ..lineTo(x, y + 4)
        ..close();
      canvas.drawPath(scute, Paint()..color = _c(const Color(0xFFD97A42)));
    }
    // Teeth peeking under the snout.
    final tooth = Paint()..color = const Color(0xFFFFFFFF);
    for (final x in const [-40.0, -28.0]) {
      canvas.drawPath(
          Path()
            ..moveTo(x, 19)
            ..lineTo(x + 3, 26)
            ..lineTo(x + 6, 19)
            ..close(),
          tooth);
    }
    // Nostrils, smoking when angry.
    final nostril = Paint()..color = const Color(0xFF7A1E1E);
    canvas.drawOval(
        Rect.fromCenter(center: const Offset(-44, 2), width: 6, height: 4),
        nostril);
    canvas.drawOval(
        Rect.fromCenter(center: const Offset(-36, 0), width: 6, height: 4),
        nostril);
    if ((phase == 2 || _mouth > .3) && !defeated) {
      for (var i = 0; i < 3; i++) {
        final k = (_t * 1.6 + i / 3) % 1;
        canvas.drawCircle(
            Offset(-44 - k * 14, -2 - k * 22),
            3 + k * 5,
            Paint()
              ..color =
                  Color.fromARGB((120 * (1 - k)).round(), 0x80, 0x70, 0x6A));
      }
    }
    // Cheek highlight.
    canvas.drawOval(
        Rect.fromCenter(center: const Offset(-14, 10), width: 14, height: 8),
        Paint()..color = const Color(0x66FF8FA0));
    // Eye.
    if (tired > 0 || defeated) {
      final swirl = Path()..moveTo(-6, -6);
      for (var i = 1; i <= 24; i++) {
        final a = i * .55 + _t * 6;
        final r = i * .38;
        swirl.lineTo(-6 + cos(a) * r, -6 + sin(a) * r);
      }
      canvas.drawOval(
          Rect.fromCenter(center: const Offset(-6, -6), width: 20, height: 20),
          Paint()..color = const Color(0xFFFFFFFF));
      canvas.drawPath(swirl, _outline..strokeWidth = 2);
      // Tongue lolling out.
      canvas.drawOval(
          Rect.fromCenter(center: const Offset(-34, 26), width: 10, height: 14),
          Paint()..color = const Color(0xFFFF7F9A));
    } else {
      canvas.drawOval(
          Rect.fromCenter(
              center: const Offset(-6, -7),
              width: 20 - 3 * _evolution,
              height: 22 - 7 * _evolution),
          Paint()
            ..color = Color.lerp(
                const Color(0xFFFFFFFF), const Color(0xFFFF8D32), _evolution)!);
      canvas.drawOval(
          Rect.fromCenter(
              center: const Offset(-6, -7),
              width: 20 - 3 * _evolution,
              height: 22 - 7 * _evolution),
          _outline..strokeWidth = 2);
      final look = (target.y - position.y) / _scale < _head.y ? -2.0 : 2.0;
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset(-9, -6 + look),
              width: 12 - 7 * _evolution,
              height: 12 - 2 * _evolution),
          Paint()..color = const Color(0xFF2A120C));
      canvas.drawCircle(Offset(-11, -9 + look), 2.2,
          Paint()..color = const Color(0xFFFFFFFF));
      if (_evolution > 0) {
        _shape(
            canvas,
            Path()
              ..addPolygon([
                const Offset(-20, -23),
                const Offset(7, -18),
                Offset(5, -6 - 3 * (1 - _evolution)),
                const Offset(-19, -13),
              ], true),
            const Color(0xFFBD4932));
        canvas.drawLine(const Offset(-18, -13), const Offset(4, -6),
            _outline..strokeWidth = 3);
      }
      // Brow: frowning while attacking or enraged.
      final angry = phase == 2 || _move != _Move.idle;
      canvas.drawLine(Offset(-18, angry ? -22 : -20),
          Offset(4, angry ? -16 : -22), _outline..strokeWidth = 4);
    }
    canvas.restore();
  }

  void _paintDizzy(Canvas canvas) {
    final h = Offset(_head.x, _head.y);
    // Glowing weak spot: scratch here!
    final pulse = .5 + .5 * sin(_t * 9);
    canvas.drawOval(
        Rect.fromCenter(
            center: h + const Offset(-10, 4),
            width: 96 + 10 * pulse,
            height: 72 + 8 * pulse),
        Paint()
          ..color = Color.fromARGB((200 * pulse + 55).round(), 0xFF, 0xE0, 0x5A)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4);
    // Stars circling over the head.
    for (var i = 0; i < 3; i++) {
      final a = _t * 4 + i * pi * 2 / 3;
      final p = h + Offset(cos(a) * 26, -34 + sin(a) * 8);
      final star = Path();
      for (var j = 0; j < 10; j++) {
        final r = j.isEven ? 7.0 : 3.0;
        final b = j * pi / 5 - pi / 2;
        final q = p + Offset(cos(b) * r, sin(b) * r);
        j == 0 ? star.moveTo(q.dx, q.dy) : star.lineTo(q.dx, q.dy);
      }
      star.close();
      canvas.drawPath(star, Paint()..color = const Color(0xFFFFE15A));
      canvas.drawPath(star, _outline..strokeWidth = 1.5);
    }
  }

  void _paintIce(Canvas canvas) {
    if (frozen < .6 && (frozen * 12).floor().isEven) return;
    final block = RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(20, -70), width: 210, height: 160),
        const Radius.circular(24));
    canvas.drawRRect(block, Paint()..color = const Color(0x66C4ECFF));
    canvas.drawRRect(
        block,
        Paint()
          ..color = const Color(0xCC4E9CC4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4);
    final shine = Paint()
      ..color = const Color(0xCCFFFFFF)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(-70, -136), const Offset(-40, -146), shine);
    canvas.drawLine(const Offset(100, -10), const Offset(112, -30), shine);
  }

  void _landingDust(Canvas canvas, double k) {
    for (var i = 0; i < 8; i++) {
      final side = i.isEven ? -1 : 1;
      final x = side * (40 + k * 90 + (i ~/ 2) * 16);
      canvas.drawCircle(
          Offset(x + 10, -6 - (i % 3) * 6),
          10 + k * 16,
          Paint()
            ..color =
                Color.fromARGB((150 * (1 - k)).round(), 0xD8, 0xC8, 0xA4));
    }
  }
}
