part of 'fishing_cabin_art.dart';

/// Top-down opening through a side wall: floor planks run through the gap,
/// with a post at each end so the way through reads at a glance.
void _wallGap(Canvas c, {required bool right}) {
  final top = FishingCabin.door.dy - FishingCabin.doorHalfHeight,
      bottom = FishingCabin.door.dy + FishingCabin.doorHalfHeight;
  final gap = right
      ? Rect.fromLTRB(738, top, 760, bottom)
      : Rect.fromLTRB(40, top, 62, bottom);
  _rect(c, gap, const Color(0xFFA9774A));
  // Same rows as the room floor (196 + 24k) so the planks run straight through.
  for (var y = 220.0; y < bottom; y += 24) {
    _line(c, Offset(gap.left, y), Offset(gap.right, y), const Color(0xFF8A5C36),
        2);
  }
  for (final y in [top - 6, bottom - 6]) {
    final post = Rect.fromLTWH(right ? 736 : 40, y, 24, 12);
    _rect(c, post, const Color(0xFF4A2E1D));
    _line(c, post.centerLeft, post.centerRight, const Color(0xFFD9A441), 2);
  }
}

/// Shared walls, plank floor and ceiling beam for both cabin rooms.
void _cabinShell(Canvas c) {
  _rect(c, const Rect.fromLTWH(40, 60, 720, 395), const Color(0xFF3E2618));
  _rect(c, const Rect.fromLTWH(54, 72, 692, 365), const Color(0xFFA9774A));
  for (var row = 0; row < 10; row++) {
    final y = 196 + row * 24.0;
    _line(c, Offset(57, y), Offset(743, y), const Color(0xFF8A5C36), 2);
    for (var col = 0; col < 7; col++) {
      final x = 90 + col * 105.0 + (row % 2) * 50;
      _line(c, Offset(x, y), Offset(x, y + 23), const Color(0x66704626), 1);
      c.drawCircle(Offset(x + 6, y + 6), 1.4, _fill(0xFF5E3A22));
    }
  }
  _rect(c, const Rect.fromLTWH(58, 74, 684, 118), const Color(0xFF6E4429));
  for (var x = 58.0; x < 740; x += 38) {
    _line(c, Offset(x, 76), Offset(x, 190), const Color(0xFF5A361F), 2);
  }
  for (final x in [58.0, 280.0, 520.0, 735.0]) {
    _rect(c, Rect.fromLTWH(x - 6, 66, 14, 128), const Color(0xFF4A2E1D));
  }
  _line(c, const Offset(56, 70), const Offset(744, 70), const Color(0xFF4A2E1D),
      10);
  _line(c, const Offset(58, 192), const Offset(742, 192),
      const Color(0xFFD9A441), 3);
}

void _lantern(Canvas c, double x) {
  _line(c, Offset(x, 72), Offset(x, 92), const Color(0xFF2B2D2F), 2);
  c.drawCircle(Offset(x, 104), 26, _fill(0x33FFD36B));
  _rect(c, Rect.fromLTWH(x - 9, 92, 18, 24), const Color(0xFFFFD36B));
  _line(c, Offset(x - 11, 92), Offset(x + 11, 92), const Color(0xFF2B2D2F), 3);
  _line(
      c, Offset(x - 11, 116), Offset(x + 11, 116), const Color(0xFF2B2D2F), 3);
}

const _windows = [
  Rect.fromLTRB(82, 88, 262, 176),
  Rect.fromLTRB(302, 88, 500, 176),
];

/// Animated sea seen through a bedroom window: sky, sun or island, drifting
/// clouds, a gently rocking horizon, rolling waves, a passing gull and the
/// glazing bars on top.
void _seaView(Canvas c, Rect glass, double t, {required bool sun}) {
  c.save();
  c.clipRect(glass);
  final horizon = glass.top + glass.height * .55 + math.sin(t * 1.1) * 3;
  c.drawRect(
      glass,
      Paint()
        ..shader = ui.Gradient.linear(glass.topCenter, Offset(0, horizon),
            const [Color(0xFF7CC8EC), Color(0xFFE6F6FB)]));
  if (sun) {
    final p = Offset(glass.right - 42, glass.top + 22);
    c.drawCircle(p, 18, Paint()..color = const Color(0x55FFF1A8));
    c.drawCircle(p, 11, Paint()..color = const Color(0xFFFFE08A));
  } else {
    final island = Offset(glass.left + 60, horizon);
    c.drawOval(Rect.fromCenter(center: island, width: 54, height: 14),
        Paint()..color = const Color(0xFF6FA552));
    final top = island + const Offset(8, -24);
    _line(c, island + const Offset(3, -4), top, const Color(0xFF7A5634), 3);
    for (final d in const [
      Offset(-11, 4),
      Offset(11, 5),
      Offset(0, -8),
      Offset(-7, -5),
      Offset(8, -4)
    ]) {
      _line(c, top, top + d, const Color(0xFF4F8F43), 3);
    }
  }
  final cloud = Paint()..color = const Color(0xEEFFFFFF);
  final span = glass.width + 60;
  for (final (seed, y) in const [(0.0, 18.0), (90.0, 34.0), (150.0, 12.0)]) {
    final x = glass.left - 30 + (t * 6 + seed + (sun ? 0 : 40)) % span;
    c.drawOval(
        Rect.fromCenter(center: Offset(x, glass.top + y), width: 30, height: 9),
        cloud);
    c.drawOval(
        Rect.fromCenter(
            center: Offset(x + 6, glass.top + y - 4), width: 15, height: 9),
        cloud);
  }
  final sea = Rect.fromLTRB(glass.left, horizon, glass.right, glass.bottom);
  c.drawRect(
      sea,
      Paint()
        ..shader = ui.Gradient.linear(sea.topCenter, sea.bottomCenter,
            const [Color(0xFF3FA3C8), Color(0xFF1C6A97)]));
  c.drawLine(
      Offset(glass.left, horizon),
      Offset(glass.right, horizon),
      Paint()
        ..color = const Color(0x99FFFFFF)
        ..strokeWidth = 1);
  final wave = Paint()
    ..color = const Color(0x88D8F3FF)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.8
    ..strokeCap = StrokeCap.round;
  for (var i = 0; i < 4; i++) {
    final y = horizon + 7 + i * 9.0;
    final p = Path()..moveTo(glass.left, y);
    for (var x = glass.left; x <= glass.right; x += 4) {
      p.lineTo(x, y + math.sin(x * .18 + t * (2 + i * .6) + i) * 1.6);
    }
    c.drawPath(p, wave);
  }
  if (!sun) {
    final gx = glass.right + 10 - (t * 14 % (glass.width + 20));
    final gy = glass.top + 20 + math.sin(t * 2) * 3;
    final flap = math.sin(t * 8) * 3;
    c.drawPath(
        Path()
          ..moveTo(gx - 7, gy - flap)
          ..quadraticBezierTo(gx - 3, gy - 3, gx, gy)
          ..quadraticBezierTo(gx + 3, gy - 3, gx + 7, gy - flap),
        Paint()
          ..color = const Color(0xFF3B4A55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8);
  }
  final glint = Paint()
    ..color = const Color(0x55FFFFFF)
    ..strokeWidth = 5
    ..strokeCap = StrokeCap.round;
  c.drawLine(glass.bottomLeft + const Offset(14, -14),
      glass.topLeft + const Offset(46, 12), glint);
  c.drawLine(glass.bottomLeft + const Offset(30, -10),
      glass.topLeft + const Offset(58, 18), glint..strokeWidth = 2);
  c.restore();
  // Glazing bars: three panes across, one rail.
  final bar = Paint()..color = const Color(0xFF8A5A33);
  for (var i = 1; i < 3; i++) {
    final x = glass.left + glass.width * i / 3;
    c.drawRect(Rect.fromLTRB(x - 2.5, glass.top, x + 2.5, glass.bottom), bar);
  }
  final railY = glass.top + glass.height * .42;
  c.drawRect(
      Rect.fromLTRB(glass.left, railY - 2.5, glass.right, railY + 2.5), bar);
}

/// Bedroom: door on the left wall, big captain's bed against the right.
void _bedroom(Canvas c) {
  _cabinShell(c);
  _wallGap(c, right: false);
  // Two wide windows filling the wall panels; the animated sea view and the
  // glazing bars are drawn on top by _RoomPainter.
  for (final w in _windows) {
    _rect(c, w.inflate(9), const Color(0xFF4A2E1D));
    _rect(c, w.inflate(5), const Color(0xFFD9A441));
    _rect(c, w.inflate(2), const Color(0xFF8A5A33));
    _rect(
        c,
        Rect.fromLTRB(w.left - 14, w.bottom + 6, w.right + 14, w.bottom + 14),
        const Color(0xFF6E4429));
  }
  // Captain's bed: posts, headboard on the back wall, quilt and pillows.
  const bed = Rect.fromLTRB(540, 168, 734, 382);
  _rect(c, bed.translate(6, 8), const Color(0x334A2E1D));
  _rect(c, const Rect.fromLTWH(536, 92, 202, 90), const Color(0xFF5E3A22));
  for (var x = 552.0; x < 730; x += 30) {
    c.drawRRect(
        RRect.fromRectAndCorners(Rect.fromLTWH(x, 108, 20, 58),
            topLeft: const Radius.circular(10),
            topRight: const Radius.circular(10)),
        _fill(0xFF8A5A33));
  }
  _line(c, const Offset(532, 92), const Offset(742, 92),
      const Color(0xFFD9A441), 4);
  _rect(c, bed, const Color(0xFF7A4A27));
  _rect(c, bed.deflate(8), const Color(0xFFF3E9D2));
  for (final x in [568.0, 650.0]) {
    c.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(x, 182, 66, 34), const Radius.circular(14)),
        _fill(0xFFFFFBF0));
    _line(c, Offset(x + 10, 199), Offset(x + 56, 199), const Color(0xFFE6DCC6),
        1.5);
  }
  const quilt = Rect.fromLTRB(548, 232, 726, 374);
  _rect(c, quilt, const Color(0xFF8E2F2A));
  c.save();
  c.clipRect(quilt);
  for (var x = quilt.left; x < quilt.right; x += 30) {
    for (var y = quilt.top; y < quilt.bottom; y += 30) {
      if (((x - quilt.left) ~/ 30 + (y - quilt.top) ~/ 30).isEven) {
        _rect(c, Rect.fromLTWH(x + 3, y + 3, 24, 24), const Color(0xFFA63C33));
      }
    }
  }
  c.restore();
  _rect(c, const Rect.fromLTRB(548, 232, 726, 246), const Color(0xFFF1E2BE));
  _line(c, const Offset(548, 372), const Offset(726, 372),
      const Color(0xFFD9A441), 3);
  for (final p in [
    bed.topLeft,
    bed.topRight,
    bed.bottomLeft,
    bed.bottomRight
  ]) {
    _rect(c, Rect.fromCenter(center: p, width: 16, height: 16),
        const Color(0xFF4A2E1D));
    c.drawCircle(p, 4, _fill(0xFFD9A441));
  }
  // Open treasure chest in the free corner below the door.
  c.save();
  // Drawn at (66, 304) originally; shift onto FishingCabin.chest.
  c.translate(FishingCabin.chest.left - 66, FishingCabin.chest.top - 304);
  _rect(c, const Rect.fromLTWH(66, 334, 82, 50), const Color(0xFF7A4A27));
  c.drawPath(
      Path()
        ..moveTo(66, 334)
        ..lineTo(74, 304)
        ..lineTo(140, 304)
        ..lineTo(148, 334)
        ..close(),
      _fill(0xFF9A6233));
  for (var i = 0; i < 7; i++) {
    c.drawCircle(Offset(76 + i * 11.0, 334 - (i % 3) * 4.0), 7,
        _fill(i.isEven ? 0xFFF2C75C : 0xFFE0A93A));
  }
  c.drawCircle(const Offset(104, 322), 5, _fill(0xFFE04F5F));
  _line(c, const Offset(66, 350), const Offset(148, 350),
      const Color(0xFFD9A441), 3);
  c.drawCircle(const Offset(107, 360), 4, _fill(0xFFD9A441));
  c.restore();

  // Round rug.
  c.drawOval(const Rect.fromLTWH(230, 270, 210, 100), _fill(0xFF3F6E78));
  c.drawOval(const Rect.fromLTWH(244, 280, 182, 80), _stroke(0xFFD9A441, 3));
}

/// Captain's cabin. Furniture stays outside [FishingCabin.floor] except the
/// flat rug; the exit hatch sits at [FishingCabin.exit].
void _room(Canvas c) {
  _cabinShell(c);

  // Stern windows looking out to sea.
  _rect(c, const Rect.fromLTWH(296, 80, 208, 72), const Color(0xFF4A2E1D));
  for (var i = 0; i < 4; i++) {
    final r = Rect.fromLTWH(304 + i * 50.0, 86, 42, 60);
    c.drawRRect(
        RRect.fromRectAndCorners(r,
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20)),
        Paint()
          ..shader = ui.Gradient.linear(r.topCenter, r.bottomCenter,
              const [Color(0xFFBFE6F2), Color(0xFF2F86B8)]));
    _line(c, Offset(r.left + 4, 128), Offset(r.right - 4, 125),
        const Color(0x88FFFFFF), 1.5);
    _line(c, Offset(r.center.dx, 87), Offset(r.center.dx, 146),
        const Color(0xFF4A2E1D), 2.5);
    _line(c, Offset(r.left, 112), Offset(r.right, 112), const Color(0xFF4A2E1D),
        2.5);
  }

  // Captain's desk with map, compass, candle and quill.
  _rect(c, const Rect.fromLTWH(286, 148, 228, 44), const Color(0xFF5E3A22));
  _rect(c, const Rect.fromLTWH(280, 142, 240, 14), const Color(0xFF8A5A33));
  _line(c, const Offset(282, 156), const Offset(518, 156),
      const Color(0xFFD9A441), 2);
  for (final x in [300.0, 500.0]) {
    _rect(c, Rect.fromLTWH(x - 6, 160, 12, 30), const Color(0xFF4A2E1D));
  }
  final map = Path()
    ..moveTo(330, 128)
    ..lineTo(420, 124)
    ..lineTo(424, 150)
    ..lineTo(334, 152)
    ..close();
  c.drawPath(map, _fill(0xFFE8D2A0));
  c.drawPath(
      Path()
        ..moveTo(342, 146)
        ..quadraticBezierTo(366, 128, 388, 140)
        ..quadraticBezierTo(400, 146, 408, 134),
      _stroke(0xFFB0472F, 1.6)..color = const Color(0xFFB0472F));
  _line(c, const Offset(404, 130), const Offset(412, 138),
      const Color(0xFFB0472F), 2.4);
  _line(c, const Offset(412, 130), const Offset(404, 138),
      const Color(0xFFB0472F), 2.4);
  c.drawCircle(const Offset(452, 140), 11, _fill(0xFFD9A441));
  c.drawCircle(const Offset(452, 140), 8, _fill(0xFFF5ECD6));
  c.drawPath(
      Path()
        ..moveTo(452, 133)
        ..lineTo(455, 141)
        ..lineTo(452, 147)
        ..lineTo(449, 141)
        ..close(),
      _fill(0xFFB0472F));
  _rect(c, const Rect.fromLTWH(482, 124, 10, 20), const Color(0xFFF3E9D2));
  c.drawCircle(const Offset(487, 118), 10, _fill(0x55FFD36B));
  c.drawOval(const Rect.fromLTWH(483, 112, 8, 12), _fill(0xFFFFC24A));
  _line(c, const Offset(304, 144), const Offset(322, 114),
      const Color(0xFFF5ECD6), 3);

  // Jolly Roger and crossed cutlasses on the back wall.
  _rect(c, const Rect.fromLTWH(92, 90, 120, 76), const Color(0xFF1F1A17));
  c.drawCircle(const Offset(152, 124), 18, _fill(0xFFF1E2BE));
  c.drawCircle(const Offset(145, 121), 4, _fill(0xFF1F1A17));
  c.drawCircle(const Offset(159, 121), 4, _fill(0xFF1F1A17));
  _rect(c, const Rect.fromLTWH(144, 140, 16, 9), const Color(0xFFF1E2BE));
  for (final d in [-1.0, 1.0]) {
    _line(c, Offset(152 - 36 * d, 148), Offset(152 + 36 * d, 160),
        const Color(0xFFF1E2BE), 4);
  }
  for (final d in [-1.0, 1.0]) {
    c.drawPath(
        Path()
          ..moveTo(620 - 46 * d, 168)
          ..quadraticBezierTo(620 - 10 * d, 130, 620 + 40 * d, 92),
        _stroke(0xFFD8DDE0, 5));
    _line(c, Offset(620 - 46 * d, 168), Offset(620 - 54 * d, 178),
        const Color(0xFF5E3A22), 6);
    _line(c, Offset(620 - 56 * d, 160), Offset(620 - 36 * d, 174),
        const Color(0xFFD9A441), 3);
  }
  // Ship's wheel hung on the wall.
  c.drawCircle(const Offset(698, 128), 30, _stroke(0xFF8A5A33, 6));
  for (var i = 0; i < 8; i++) {
    final a = i * math.pi / 4;
    _line(
        c,
        const Offset(698, 128),
        Offset(698 + math.cos(a) * 40, 128 + math.sin(a) * 40),
        const Color(0xFF8A5A33),
        4);
  }
  c.drawCircle(const Offset(698, 128), 7, _fill(0xFFD9A441));

  // Right: door to the bedroom.
  _wallGap(c, right: true);

  _lantern(c, 220);
  _lantern(c, 580);

  // Exit hatch and ladder.
  _rect(c, const Rect.fromLTWH(352, 400, 96, 37), const Color(0xFF3E2618));
  for (var i = 0; i < 5; i++) {
    _line(c, Offset(360, 406 + i * 6.0), Offset(440, 406 + i * 6.0),
        const Color(0xFFA78B60), 2);
  }
  c.drawPath(
      Path()
        ..moveTo(391, 419)
        ..lineTo(400, 426)
        ..lineTo(409, 419),
      _stroke(0xFFEED79F, 3));
}
