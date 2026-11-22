part of 'fishing_cabin_art.dart';

class FishingCabinShip extends StatefulWidget {
  const FishingCabinShip(
      {super.key, required this.round, required this.frames});
  final FishingRiverRound round;
  final Listenable frames;
  @override
  State<FishingCabinShip> createState() => _FishingCabinShipState();
}

class _FishingCabinShipState extends State<FishingCabinShip> {
  late final picture = _record(_ship);
  @override
  void dispose() {
    picture.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
      child: RepaintBoundary(
          child: CustomPaint(
              painter: _ShipPainter(widget.round, widget.frames, picture))));
}

class _ShipPainter extends CustomPainter {
  _ShipPainter(this.round, Listenable frames, this.picture)
      : super(repaint: frames);
  final FishingRiverRound round;
  final ui.Picture picture;
  @override
  void paint(Canvas c, Size size) {
    final point = round.toScreen(FishingCabin.ship);
    if (!(Offset.zero & size).inflate(320 * round.scale).contains(point)) {
      return;
    }
    c.save();
    c.clipRect(Offset.zero & size);
    c.translate(point.dx, point.dy);
    c.scale(round.scale);
    c.drawPicture(picture);
    final wave = round.clock * 5;
    final flag = Path()..moveTo(2, -296);
    for (var i = 1; i <= 6; i++) {
      flag.lineTo(2 + i * 9.0, -296 + math.sin(wave - i * .9) * i * .7);
    }
    for (var i = 6; i >= 0; i--) {
      flag.lineTo(2 + i * 9.0, -270 + math.sin(wave - i * .9) * i * .7);
    }
    flag.close();
    c.drawPath(flag, Paint()..color = const Color(0xFF1F1A17));
    c.drawCircle(Offset(26, -283 + math.sin(wave - 2.7) * 2), 5,
        Paint()..color = const Color(0xFFF1E2BE));
    final t = (round.clock * .35) % 1;
    c.drawOval(
        Rect.fromCenter(
            center: const Offset(0, 110),
            width: 37 + t * 12,
            height: 16 + t * 6),
        Paint()
          ..color = Color.fromRGBO(255, 239, 181, .7 - t * .3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
    c.drawPath(
        Path()
          ..moveTo(-6, 106)
          ..lineTo(0, 100)
          ..lineTo(6, 106),
        Paint()
          ..color = const Color(0xFFFFEDB1)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round);
    c.restore();
  }

  @override
  bool shouldRepaint(_ShipPainter old) =>
      old.round != round || old.picture != picture;
}

/// Pirate ship, bow to the right. Origin = FishingCabin.ship; the hull stays
/// inside the solid radius, masts and sails rise above it.
void _ship(Canvas c) {
  c.drawOval(const Rect.fromLTWH(-160, 70, 345, 80), _fill(0x33405C5A));
  final hull = Path()
    ..moveTo(-140, -10)
    ..lineTo(-138, 70)
    ..quadraticBezierTo(-126, 118, -60, 118)
    ..lineTo(70, 118)
    ..quadraticBezierTo(140, 100, 174, 8)
    ..quadraticBezierTo(140, 50, 60, 52)
    ..lineTo(-80, 52)
    ..quadraticBezierTo(-140, 46, -140, -10)
    ..close();
  c.drawPath(hull, _fill(0xFF4A2E1D));
  c.save();
  c.clipPath(hull);
  c.drawRect(const Rect.fromLTRB(-150, 50, 180, 66), _fill(0xFF6E4429));
  for (final y in [72.0, 86.0, 100.0, 113.0]) {
    _line(c, Offset(-150, y), Offset(180, y - (y - 60) * .25),
        const Color(0xFF3A2416), 1.6);
  }
  c.restore();
  c.drawPath(
      Path()
        ..moveTo(-139, 62)
        ..lineTo(60, 62)
        ..quadraticBezierTo(132, 60, 166, 24),
      _stroke(0xFFD9A441, 3));
  for (final x in [-104.0, -62.0, 36.0, 78.0]) {
    _rect(c, Rect.fromLTWH(x - 11, 72, 22, 17), const Color(0xFFC08A3A));
    _rect(c, Rect.fromLTWH(x - 8, 75, 16, 11), const Color(0xFF1E1410));
    c.drawCircle(Offset(x, 81), 4.5, _fill(0xFF3C3F42));
    c.drawCircle(Offset(x, 81), 2, _fill(0xFF101214));
  }
  // Anchor hanging at the bow.
  _line(c, const Offset(128, 54), const Offset(128, 92),
      const Color(0xFF6A6F70), 3);
  c.drawArc(const Rect.fromLTWH(116, 80, 24, 20), .2, 2.7, false,
      _stroke(0xFF6A6F70, 3.5));
  _line(c, const Offset(121, 64), const Offset(135, 64),
      const Color(0xFF6A6F70), 3);

  final deck = Path()
    ..moveTo(-140, -10)
    ..quadraticBezierTo(-140, -62, -40, -62)
    ..lineTo(90, -55)
    ..quadraticBezierTo(150, -40, 174, 8)
    ..quadraticBezierTo(140, 48, 60, 50)
    ..lineTo(-80, 50)
    ..quadraticBezierTo(-140, 45, -140, -10)
    ..close();
  c.drawPath(deck, _fill(0xFFB98552));
  c.save();
  c.clipPath(deck);
  for (var y = -60.0; y < 55; y += 10) {
    _line(c, Offset(-150, y), Offset(180, y), const Color(0xFF9C6C40), 1.3);
  }
  for (var x = -120.0; x < 170; x += 46) {
    for (var y = -55.0; y < 55; y += 20) {
      _line(
          c,
          Offset(x + (y % 40 == 0 ? 0 : 23), y),
          Offset(x + (y % 40 == 0 ? 0 : 23), y + 10),
          const Color(0xFF9C6C40),
          1);
    }
  }
  c.restore();
  c.drawPath(deck, _stroke(0xFF5E3A22, 7));
  c.drawPath(deck, _stroke(0xFFD9A441, 1.6));
  for (var x = -110.0; x < 150; x += 22) {
    c.drawCircle(
        Offset(x, x > 60 ? 50 - (x - 60) * .36 : 51), 2.6, _fill(0xFF5E3A22));
  }

  // Cargo hatch, barrels and a treasure chest.
  _rect(c, const Rect.fromLTWH(40, -18, 40, 30), const Color(0xFF6E4429));
  for (var i = 0; i < 4; i++) {
    _line(c, Offset(45, -12 + i * 7.0), Offset(75, -12 + i * 7.0),
        const Color(0xFF3F2716), 2);
  }
  for (final b in [const Offset(112, -10), const Offset(128, 12)]) {
    c.drawCircle(b, 13, _fill(0xFF8A5A33));
    c.drawCircle(b, 13, _stroke(0xFF4B4F52, 2));
    c.drawCircle(b, 7, _stroke(0xFF4B4F52, 1.6));
  }
  _rect(c, const Rect.fromLTWH(-48, 4, 34, 22), const Color(0xFF7A4A27));
  _rect(c, const Rect.fromLTWH(-48, 0, 34, 9), const Color(0xFF9A6233));
  _line(c, const Offset(-48, 9), const Offset(-14, 9), const Color(0xFFD9A441),
      2.5);
  c.drawCircle(const Offset(-31, 14), 3, _fill(0xFFF2C75C));

  // Raised stern castle with glowing windows and a lantern.
  _rect(c, const Rect.fromLTWH(-138, -98, 84, 50), const Color(0xFFA47448));
  for (var y = -92.0; y < -50; y += 9) {
    _line(c, Offset(-136, y), Offset(-56, y), const Color(0xFF8A5E37), 1.2);
  }
  _rect(c, const Rect.fromLTWH(-138, -50, 84, 58), const Color(0xFF6B4329));
  _line(c, const Offset(-138, -50), const Offset(-54, -50),
      const Color(0xFFD9A441), 2.5);
  for (final x in [-128.0, -106.0, -84.0]) {
    c.drawRRect(
        RRect.fromRectAndCorners(Rect.fromLTWH(x, -38, 16, 20),
            topLeft: const Radius.circular(8),
            topRight: const Radius.circular(8)),
        _fill(0xFFFFCF6E));
    _line(c, Offset(x + 8, -36), Offset(x + 8, -18), const Color(0xFF6B4329),
        1.6);
  }
  _rect(c, const Rect.fromLTWH(-96, -12, 22, 20), const Color(0xFF3A2416));
  for (var x = -136.0; x <= -56; x += 10) {
    _line(c, Offset(x, -98), Offset(x, -110), const Color(0xFF5E3A22), 2.4);
  }
  _line(c, const Offset(-138, -110), const Offset(-54, -110),
      const Color(0xFF5E3A22), 3);
  c.drawCircle(const Offset(-126, -132), 18, _fill(0x55FFD36B));
  _line(c, const Offset(-126, -110), const Offset(-126, -124),
      const Color(0xFF3A2416), 2);
  _rect(c, const Rect.fromLTWH(-132, -140, 12, 15), const Color(0xFFFFD36B));
  _line(c, const Offset(-134, -141), const Offset(-118, -141),
      const Color(0xFF3A2416), 2.5);

  // Gangplank down to the mooring (the enter arrow sits at its foot).
  for (var i = 0; i < 6; i++) {
    _rect(c, Rect.fromLTWH(-16, 46 + i * 11.0, 32, 8),
        Color.lerp(const Color(0xFFC89B62), const Color(0xFFA77B4A), i / 6)!);
  }

  // Masts lean slightly aft; yards are angled so the sails belly toward the
  // bow (right), matching the hull.
  const main = 0.0, fore = 92.0;
  final rope = _stroke(0xFF3E2C1E, 1.4);
  for (final line in const [
    (Offset(main, -292), Offset(-132, -100)),
    (Offset(main, -292), Offset(fore, -236)),
    (Offset(fore, -236), Offset(222, -36)),
    (Offset(main, -200), Offset(-104, -60)),
    (Offset(fore, -160), Offset(160, 0)),
  ]) {
    c.drawLine(line.$1, line.$2, rope);
  }
  _line(c, const Offset(150, 4), const Offset(228, -38),
      const Color(0xFF5B3A22), 6);
  c.drawPath(
      Path()
        ..moveTo(fore + 6, -226)
        ..quadraticBezierTo(190, -150, 220, -38)
        ..quadraticBezierTo(176, -30, 128, -18)
        ..quadraticBezierTo(140, -110, fore + 6, -226)
        ..close(),
      _fill(0xFFE9D7AE));
  _line(c, const Offset(fore, 10), const Offset(fore, -240),
      const Color(0xFF5B3A22), 7);
  _line(c, const Offset(main, 8), const Offset(main, -296),
      const Color(0xFF5B3A22), 8);

  /// A billowing square sail seen at an angle: luff on the mast, belly
  /// pushed toward the bow.
  void sail(double mast, double top, double bottom, double reach) {
    final mid = (top + bottom) / 2;
    final p = Path()
      ..moveTo(mast - 10, top + 6)
      ..lineTo(mast + reach * .7, top - 6)
      ..quadraticBezierTo(mast + reach * 1.25, mid, mast + reach * .72, bottom)
      ..quadraticBezierTo(mast + reach * .3, bottom + 8, mast - 8, bottom - 4)
      ..quadraticBezierTo(mast + reach * .3, mid, mast - 10, top + 6)
      ..close();
    c.drawPath(p, _fill(0xFFF1E2BE));
    c.save();
    c.clipPath(p);
    c.drawPath(
        Path()
          ..moveTo(mast - 10, top)
          ..quadraticBezierTo(mast + reach * .4, mid, mast - 10, bottom)
          ..close(),
        _fill(0x33806040));
    for (var f = .3; f < 1; f += .22) {
      c.drawPath(
          Path()
            ..moveTo(mast + reach * .7 * f, top - 4 * f)
            ..quadraticBezierTo(mast + reach * (.3 + .9 * f), mid,
                mast + reach * .72 * f, bottom),
          _stroke(0xFFD9C49A, 1.4));
    }
    c.restore();
    c.drawPath(p, _stroke(0xFFB89E70, 1.6));
    _line(c, Offset(mast - 14, top + 7), Offset(mast + reach * .74, top - 7),
        const Color(0xFF5B3A22), 5);
  }

  sail(fore, -228, -170, 62);
  sail(fore, -160, -66, 74);
  sail(main, -270, -208, 70);
  sail(main, -196, -60, 98);
  // Patch on the main sail.
  _rect(c, const Rect.fromLTWH(18, -92, 18, 15), const Color(0xFFD8C08E));
  final stitch = _stroke(0xFF8E7550, 1);
  for (var i = 0; i < 3; i++) {
    c.drawLine(Offset(21 + i * 5.0, -94), Offset(21 + i * 5.0, -90), stitch);
  }
  // Crossed bones and a fish skeleton facing the bow.
  c.save();
  c.translate(52, -138);
  c.scale(.82, 1);
  final bone = _stroke(0xFF33261C, 5);
  c.drawLine(const Offset(-26, -26), const Offset(26, 26), bone);
  c.drawLine(const Offset(26, -26), const Offset(-26, 26), bone);
  for (final e in const [
    Offset(-26, -26),
    Offset(26, 26),
    Offset(26, -26),
    Offset(-26, 26)
  ]) {
    c.drawCircle(e, 5, _fill(0xFF33261C));
  }
  c.drawCircle(Offset.zero, 21, _fill(0xFFF1E2BE));
  c.drawPath(
      Path()
        ..moveTo(18, 0)
        ..quadraticBezierTo(12, -12, 4, -12)
        ..lineTo(4, 12)
        ..quadraticBezierTo(12, 12, 18, 0)
        ..close(),
      _fill(0xFF33261C));
  c.drawCircle(const Offset(10, -3), 2.4, _fill(0xFFF1E2BE));
  final spine = _stroke(0xFF33261C, 2.4);
  c.drawLine(const Offset(4, 0), const Offset(-15, 0), spine);
  for (var x = -1.0; x >= -13; x -= 4) {
    c.drawLine(Offset(x, -8), Offset(x, 8), spine);
  }
  c.drawPath(
      Path()
        ..moveTo(-15, 0)
        ..lineTo(-23, -8)
        ..lineTo(-23, 8)
        ..close(),
      _fill(0xFF33261C));
  c.restore();
  // Crow's nest.
  _rect(
      c, const Rect.fromLTWH(main - 18, -284, 36, 16), const Color(0xFF6E4429));
  _line(c, const Offset(main - 18, -284), const Offset(main + 18, -284),
      const Color(0xFFD9A441), 2);
}
