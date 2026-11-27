part of 'adventure_dragon.dart';

extension _DragonAscendedArt on AdventureDragon {
  void _paintAscendedBody(Canvas canvas) {
    const hide = Color(0xFF37334F);
    const red = Color(0xFFBB4D63);
    const gold = Color(0xFFFFDB8B);
    final h = Offset(_head.x, _head.y);
    _wing(canvas, const Offset(35, -133), .09, 1.25, const Color(0xFFAC445B),
        const Color(0xFF742940));
    // Far leg, then pelvis: both feet remain planted throughout each cast.
    _shape(
        canvas,
        Path()
          ..addPolygon(const [
            Offset(22, -62),
            Offset(48, -52),
            Offset(43, -25),
            Offset(22, -14),
            Offset(31, -3),
            Offset(12, 3),
            Offset(-7, 2),
            Offset(-9, -6),
            Offset(8, -21),
          ], true),
        hide);
    final body = Path()
      ..moveTo(-24, -128)
      ..quadraticBezierTo(12, -150, 43, -121)
      ..quadraticBezierTo(79, -94, 76, -52)
      ..lineTo(55, -25)
      ..quadraticBezierTo(16, -13, -16, -44)
      ..quadraticBezierTo(-39, -82, -24, -128)
      ..close();
    _shape(canvas, body, hide);
    _scaleDetail(canvas, body, spacing: 9);
    final neck = Path()
      ..moveTo(3, -89)
      ..cubicTo(-30, -112, h.dx + 36, h.dy + 20, h.dx + 13, h.dy + 9);
    canvas.drawPath(neck, _outline..strokeWidth = 47);
    canvas.drawPath(
        neck,
        Paint()
          ..color = _c(hide)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 41
          ..strokeCap = StrokeCap.round);
    canvas.drawPath(
        neck.shift(const Offset(-8, 0)),
        Paint()
          ..color = _c(red)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 18
          ..strokeCap = StrokeCap.round);
    // Neck ridges follow the same curve used by the throat and the head.
    for (var i = 1; i < 8; i++) {
      final t = i / 8;
      final p = Offset.lerp(h + const Offset(20, 16), const Offset(5, -94), t)!;
      canvas.drawPath(
          Path()
            ..moveTo(p.dx + 3, p.dy - 4)
            ..lineTo(p.dx + 11, p.dy)
            ..lineTo(p.dx + 5, p.dy + 6),
          Paint()
            ..color = const Color(0xFF92536A)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
    }
    // A continuous pale throat joins the belly; rib plates follow the neck.
    final throat = Path()
      ..moveTo(h.dx + 3, h.dy + 19)
      ..cubicTo(h.dx + 7, h.dy + 54, -38, -113, -20, -70)
      ..quadraticBezierTo(-7, -39, 18, -30)
      ..lineTo(33, -51)
      ..quadraticBezierTo(10, -76, 2, -109)
      ..quadraticBezierTo(h.dx + 35, h.dy + 30, h.dx + 23, h.dy + 17)
      ..close();
    _shape(canvas, throat, gold);
    canvas.save();
    canvas.clipPath(throat);
    for (var i = 0; i < 8; i++) {
      final t = i / 7;
      final p = Offset.lerp(h + const Offset(8, 25), const Offset(7, -42), t)!;
      canvas.drawPath(
          Path()
            ..moveTo(p.dx - 23, p.dy)
            ..quadraticBezierTo(p.dx, p.dy + 8, p.dx + 23, p.dy + 2),
          Paint()
            ..color = const Color(0xFFC58C62)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
      canvas.drawLine(
          p + const Offset(-16, -3),
          p + const Offset(4, -1),
          Paint()
            ..color = const Color(0xFFFFF1B2)
            ..strokeWidth = 4);
    }
    canvas.restore();
    // Raised red plates only on shoulders and thighs, leaving the throat clear.
    for (final p in const [Offset(22, -119), Offset(53, -55)]) {
      final plate = Path()
        ..moveTo(p.dx - 14, p.dy - 19)
        ..lineTo(p.dx + 7, p.dy - 23)
        ..lineTo(p.dx + 18, p.dy - 9)
        ..lineTo(p.dx + 15, p.dy + 15)
        ..lineTo(p.dx - 2, p.dy + 23)
        ..lineTo(p.dx - 17, p.dy + 7)
        ..close();
      _shape(canvas, plate, red);
      _scaleDetail(canvas, plate, spacing: 8);
      canvas.drawPath(
          Path()
            ..moveTo(p.dx - 9, p.dy - 12)
            ..lineTo(p.dx + 4, p.dy - 16)
            ..lineTo(p.dx + 11, p.dy - 6),
          Paint()
            ..color = const Color(0xFFF08C86)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3);
      canvas.drawLine(
          p + const Offset(-12, 1),
          p + const Offset(14, 4),
          Paint()
            ..color = const Color(0xFF78364E)
            ..strokeWidth = 2);
    }
    // Front shin and broad taloned foot.
    _shape(
        canvas,
        Path()
          ..addPolygon(const [
            Offset(49, -43),
            Offset(70, -39),
            Offset(71, -17),
            Offset(82, -3),
            Offset(75, 5),
            Offset(35, 6),
            Offset(27, -1),
            Offset(45, -15),
          ], true),
        hide);
    for (final foot in const [Offset(1, -1), Offset(43, 3)]) {
      for (var i = 0; i < 3; i++) {
        final x = foot.dx + i * 11;
        _shape(
            canvas,
            Path()
              ..addPolygon([
                Offset(x, foot.dy - 4),
                Offset(x + 7, foot.dy - 3),
                Offset(x + 4, foot.dy + 7),
                Offset(x - 6, foot.dy + 7),
              ], true),
            const Color(0xFFBFC0D3));
      }
    }
    // The small forearms hang in front of the torso, rather than bearing weight.
    for (final p in const [Offset(-24, -103), Offset(20, -96)]) {
      final reach = sin(_t * 2) * 1.5 + _castKick * 3;
      _shape(
          canvas,
          Path()
            ..addPolygon([
              p,
              p + const Offset(12, 7),
              p + Offset(3, 30 + reach),
              p + Offset(-10, 39 + reach),
              p + Offset(-20, 33 + reach),
              p + const Offset(-10, 18),
            ], true),
          hide);
      for (var i = 0; i < 3; i++) {
        final claw = p + Offset(-18 + i * 7, 31 + reach);
        _shape(
            canvas,
            Path()
              ..addPolygon([
                claw,
                claw + const Offset(5, 0),
                claw + const Offset(3, 10),
                claw + const Offset(-2, 7),
              ], true),
            const Color(0xFFC7C2D7));
      }
    }
    // Low dorsal spines join the neck to the original attached tail.
    for (var i = 0; i < 5; i++) {
      final p = Offset(43 + i * 6, -123 + i * 16);
      _shape(
          canvas,
          Path()
            ..addPolygon([
              p,
              p + const Offset(20, 0),
              p + const Offset(4, 10),
            ], true),
          red);
    }
    _paintHead(canvas, h);
    // The near wing attaches behind the shoulder, away from the head and horns.
    _wing(canvas, const Offset(39, -132), 0, 1.55, const Color(0xFFD36677),
        const Color(0xFF96364F));
  }

  void _paintAscendedHead(Canvas canvas, Offset h) {
    const red = Color(0xFFC7586A);
    const dark = Color(0xFF38324F);
    canvas.save();
    canvas.translate(h.dx, h.dy);
    canvas.rotate(_headPitch);
    canvas.scale(_headSize);
    for (final horn in const [(24.0, -15.0, 30.0), (5.0, -26.0, 42.0)]) {
      _shape(
          canvas,
          Path()
            ..addPolygon([
              Offset(horn.$1 - 7, horn.$2 + 6),
              Offset(horn.$1 + 2, horn.$2 - 16),
              Offset(horn.$1 + horn.$3, horn.$2 - 34),
              Offset(horn.$1 + 21, horn.$2 - 8),
              Offset(horn.$1 + 7, horn.$2 + 9),
            ], true),
          red);
      canvas.drawLine(
          Offset(horn.$1 + 2, horn.$2 - 8),
          Offset(horn.$1 + horn.$3 - 5, horn.$2 - 29),
          Paint()
            ..color = const Color(0xFFFFA193)
            ..strokeWidth = 2.5);
    }
    for (var i = 0; i < 3; i++) {
      final p = Offset(26, -10 + i * 9);
      _shape(
          canvas,
          Path()
            ..addPolygon([
              p,
              p + const Offset(24, -2),
              p + const Offset(9, 9),
            ], true),
          red);
    }
    canvas.save();
    canvas.translate(-9, 12);
    canvas.rotate(-.42 * _jaw);
    _shape(
        canvas,
        Path()
          ..addPolygon(const [
            Offset(-49, -2),
            Offset(-5, -3),
            Offset(12, 7),
            Offset(-1, 17),
            Offset(-43, 12),
            Offset(-52, 6)
          ], true),
        dark);
    canvas.restore();
    final skull = Path()
      ..addPolygon(const [
        Offset(25, 10),
        Offset(27, -13),
        Offset(11, -30),
        Offset(-7, -32),
        Offset(-28, -18),
        Offset(-42, -7),
        Offset(-59, 5),
        Offset(-57, 15),
        Offset(-43, 19),
        Offset(-23, 13),
        Offset(-6, 18),
      ], true);
    _shape(canvas, skull, red);
    _scaleDetail(canvas, skull, spacing: 7);
    _shape(
        canvas,
        Path()
          ..addPolygon(const [
            Offset(3, -2),
            Offset(17, -11),
            Offset(23, 0),
            Offset(13, 12),
            Offset(-2, 16),
          ], true),
        const Color(0xFFAF4D66));
    canvas.drawPath(
        Path()
          ..moveTo(6, -1)
          ..lineTo(16, -7)
          ..lineTo(19, 0),
        Paint()
          ..color = const Color(0xFFFFA19A)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
    canvas.drawPath(
        Path()
          ..moveTo(-54, 5)
          ..lineTo(-40, 1)
          ..lineTo(-27, -6),
        Paint()
          ..color = const Color(0xFFE68A8F)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8);
    _shape(
        canvas,
        Path()
          ..addPolygon(const [
            Offset(-53, 15),
            Offset(-27, 8),
            Offset(-4, 3),
            Offset(14, 9),
            Offset(-6, 20),
            Offset(-43, 23)
          ], true),
        dark);
    canvas.drawPath(
        Path()
          ..moveTo(-45, -3)
          ..lineTo(-25, -14)
          ..lineTo(-6, -23)
          ..lineTo(10, -23),
        Paint()
          ..color = const Color(0xFFF18B8B)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3);
    _shape(
        canvas,
        Path()
          ..addPolygon(const [
            Offset(-18, -8),
            Offset(-3, -17),
            Offset(5, -15),
            Offset(-2, -5),
            Offset(-13, -2)
          ], true),
        const Color(0xFFFFEBC2));
    canvas.drawLine(
        const Offset(-6, -12),
        const Offset(-8, -5),
        Paint()
          ..color = const Color(0xFF211F35)
          ..strokeWidth = 3);
    canvas.drawLine(const Offset(-21, -11), const Offset(4, -20),
        _outline..strokeWidth = 3.5);
    canvas.drawOval(
        Rect.fromCenter(center: const Offset(-46, 5), width: 5, height: 3),
        Paint()..color = dark);
    if (_jaw > .2) {
      for (final x in [-41.0, -24.0]) {
        _shape(
            canvas,
            Path()
              ..addPolygon(
                  [Offset(x, 15), Offset(x + 5, 14), Offset(x + 2, 21)], true),
            const Color(0xFFFFEBC2));
      }
    }
    canvas.restore();
  }
}
