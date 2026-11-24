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
void _seaView(Canvas c, Rect glass, double t,
    {required bool sun, double night = 0}) {
  c.save();
  c.clipRect(glass);
  final horizon = glass.top + glass.height * .55 + math.sin(t * 1.1) * 3;
  c.drawRect(
      glass,
      Paint()
        ..shader = ui.Gradient.linear(glass.topCenter, Offset(0, horizon), [
          Color.lerp(const Color(0xFF7CC8EC), const Color(0xFF14233F), night)!,
          Color.lerp(const Color(0xFFE6F6FB), const Color(0xFF3A5682), night)!,
        ]));
  if (night > .05) _nightSky(c, glass, horizon, t, night, moon: sun);
  if (sun && night < .5) {
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
  final cloud = Paint()
    ..color = Color.fromRGBO(255, 255, 255, .93 * (1 - night * .8));
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
        ..shader = ui.Gradient.linear(sea.topCenter, sea.bottomCenter, [
          Color.lerp(const Color(0xFF3FA3C8), const Color(0xFF1D4468), night)!,
          Color.lerp(const Color(0xFF1C6A97), const Color(0xFF0D2138), night)!,
        ]));
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
  _doubleBed(c);
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
  _chandelierFrame(c);
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

/// Stars, an optional moon and a moonlit streak on the sea for night windows.
void _nightSky(Canvas c, Rect glass, double horizon, double t, double night,
    {required bool moon}) {
  for (var i = 0; i < 18; i++) {
    final p = Offset(glass.left + artNoise(i, 70) * glass.width,
        glass.top + artNoise(i, 71) * (horizon - glass.top - 4));
    final twinkle = .55 + .45 * math.sin(t * 2 + i * 1.7);
    c.drawCircle(p, .9 + artNoise(i, 72) * 1.1,
        Paint()..color = Color.fromRGBO(255, 250, 225, night * twinkle));
  }
  if (!moon) return;
  final m = Offset(glass.right - 40, glass.top + 22);
  c.drawCircle(
      m, 18, Paint()..color = Color.fromRGBO(235, 240, 210, .18 * night));
  c.drawCircle(m, 10, Paint()..color = Color.fromRGBO(245, 243, 220, night));
  c.drawCircle(m + const Offset(4, -2), 9,
      Paint()..color = Color.fromRGBO(20, 35, 63, night * .85));
  for (var i = 0; i < 5; i++) {
    final y = horizon + 6 + i * 8.0;
    final w = 18 - i * 2.0 + math.sin(t * 2 + i) * 3;
    c.drawLine(
        Offset(m.dx - w / 2, y),
        Offset(m.dx + w / 2, y),
        Paint()
          ..color = Color.fromRGBO(240, 238, 200, .5 * night)
          ..strokeWidth = 2);
  }
}

/// Bedroom chandelier between the windows; flames are drawn live.
const _chandelier = Offset(282, 112);
const _chandelierCandles = [-34.0, -17.0, 0.0, 17.0, 34.0];

void _chandelierFrame(Canvas c) {
  const p = _chandelier;
  c.save();
  c.translate(p.dx, p.dy);
  c.scale(1.35);
  c.translate(-p.dx, -p.dy);
  // Chain from the ceiling beam.
  for (var y = 66.0; y < p.dy - 14; y += 7) {
    c.drawOval(Rect.fromCenter(center: Offset(p.dx, y), width: 4, height: 7),
        _stroke(0xFF8A6A2E, 1.6));
  }
  // Brass ring seen slightly from above, centre boss and drop.
  c.drawOval(Rect.fromCenter(center: p, width: 84, height: 18),
      _stroke(0xFF7A5A22, 5));
  c.drawOval(Rect.fromCenter(center: p, width: 84, height: 18),
      _stroke(0xFFD9A441, 2.5));
  for (final dx in [-30.0, 30.0]) {
    c.drawLine(Offset(p.dx, p.dy - 16), Offset(p.dx + dx, p.dy - 2),
        _stroke(0xFFB8862E, 2));
  }
  c.drawCircle(Offset(p.dx, p.dy - 16), 5, _fill(0xFFD9A441));
  c.drawCircle(Offset(p.dx, p.dy + 6), 6, _fill(0xFFB8862E));
  c.drawPath(
      Path()
        ..moveTo(p.dx - 4, p.dy + 10)
        ..lineTo(p.dx, p.dy + 22)
        ..lineTo(p.dx + 4, p.dy + 10)
        ..close(),
      _fill(0xFFE8C56A));
  for (final dx in _chandelierCandles) {
    final y = p.dy - 4 + (dx.abs() < 1 ? -3 : 0);
    c.drawOval(
        Rect.fromCenter(center: Offset(p.dx + dx, y + 2), width: 11, height: 4),
        _fill(0xFFD9A441));
    _rect(c, Rect.fromLTWH(p.dx + dx - 3, y - 12, 6, 13),
        const Color(0xFFF3E9D2));
  }
  c.restore();
}

void _chandelierFlames(Canvas c, double clock, double night) {
  const p = _chandelier;
  c.save();
  c.translate(p.dx, p.dy);
  c.scale(1.35);
  c.translate(-p.dx, -p.dy);
  c.drawCircle(Offset(p.dx, p.dy - 20), 46 + night * 20,
      Paint()..color = Color.fromRGBO(255, 211, 107, .12 + night * .1));
  for (var i = 0; i < _chandelierCandles.length; i++) {
    final dx = _chandelierCandles[i];
    final y = p.dy - 4 + (dx.abs() < 1 ? -3 : 0) - 13;
    final f =
        math.sin(clock * 11 + i * 1.9) * .5 + math.sin(clock * 6.7 + i) * .5;
    final h = 9 + f * 1.8;
    final base = Offset(p.dx + dx, y);
    c.drawPath(
        Path()
          ..moveTo(base.dx - 3.2, base.dy)
          ..quadraticBezierTo(
              base.dx - 3.5, base.dy - h * .55, base.dx + f, base.dy - h)
          ..quadraticBezierTo(
              base.dx + 3.5, base.dy - h * .55, base.dx + 3.2, base.dy)
          ..close(),
        _fill(0xFFF6A93B));
    c.drawOval(
        Rect.fromCenter(
            center: base + const Offset(0, -3), width: 3, height: 5),
        _fill(0xFFFFF1B8));
  }
  c.restore();
}

/// Captain's double bed: arched headboard against the back wall, one pillow
/// and one quilt half per sleeper, turned posts and a low footboard.
void _doubleBed(Canvas c) {
  const bed = FishingCabin.bed;
  const wood = Color(0xFF6B4026), dark = Color(0xFF4A2E1D);
  const gold = Color(0xFFD9A441);
  final mid = bed.center.dx;
  // Soft floor shadow.
  c.drawRRect(
      RRect.fromRectAndRadius(
          bed.translate(5, 9).inflate(2), const Radius.circular(14)),
      _fill(0x40311C10));
  // Arched headboard with one carved panel per side and a ship-wheel crest.
  final head = Path()
    ..moveTo(bed.left - 4, bed.top + 8)
    ..lineTo(bed.left - 4, 128)
    ..quadraticBezierTo(bed.left + 4, 112, mid - 34, 112)
    ..quadraticBezierTo(mid, 96, mid + 34, 112)
    ..quadraticBezierTo(bed.right - 4, 112, bed.right + 4, 128)
    ..lineTo(bed.right + 4, bed.top + 8)
    ..close();
  c.drawPath(head, Paint()..color = wood);
  c.drawPath(head, _stroke(0xFF3E2618, 3));
  for (final side in [-1.0, 1.0]) {
    final cx = mid + side * 42;
    final panel = RRect.fromRectAndCorners(
        Rect.fromCenter(center: Offset(cx, 162), width: 64, height: 58),
        topLeft: const Radius.circular(26),
        topRight: const Radius.circular(26),
        bottomLeft: const Radius.circular(4),
        bottomRight: const Radius.circular(4));
    c.drawRRect(panel, _fill(0xFF8A5A33));
    c.drawRRect(panel.deflate(5), _fill(0xFF7A4A27));
    c.drawRRect(panel, _stroke(0xFFD9A441, 1.6));
  }
  _line(c, Offset(bed.left + 2, 126), Offset(mid - 36, 117), gold, 2);
  _line(c, Offset(mid + 36, 117), Offset(bed.right - 2, 126), gold, 2);
  const crest = Offset(638, 116);
  c.drawCircle(crest, 13, _fill(0xFF3E2618));
  c.drawCircle(crest, 10, _stroke(0xFFD9A441, 2.4));
  for (var i = 0; i < 8; i++) {
    final d = Offset(math.cos(i * math.pi / 4), math.sin(i * math.pi / 4));
    _line(c, crest + d * 3, crest + d * 14, gold, 2);
  }
  c.drawCircle(crest, 3.4, _fill(0xFFD9A441));
  // Frame and mattress.
  final frame = RRect.fromRectAndRadius(bed, const Radius.circular(10));
  c.drawRRect(frame, Paint()..color = wood);
  c.drawRRect(frame, _stroke(0xFF3E2618, 3));
  final mattress = RRect.fromRectAndRadius(
      Rect.fromLTRB(bed.left + 9, bed.top + 6, bed.right - 9, bed.bottom - 22),
      const Radius.circular(10));
  c.drawRRect(mattress, _fill(0xFFF6EEDB));
  // Two plump pillows, one for each sleeper.
  for (final cx in [bed.left + 44.0, bed.right - 44.0]) {
    final pillow = RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(cx, bed.top + 28), width: 70, height: 36),
        const Radius.circular(16));
    c.drawRRect(pillow.shift(const Offset(0, 3)), _fill(0x33704626));
    c.drawRRect(pillow, _fill(0xFFFFFCF3));
    c.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset(cx, bed.top + 34), width: 56, height: 12),
            const Radius.circular(6)),
        _fill(0xFFF0E6D0));
    c.drawRRect(pillow, _stroke(0xFFD8C9A8, 1.4));
  }
  // Quilt: two patchwork halves meeting in a stitched seam, folded sheet on
  // top and a gold hem, draping slightly over both sides of the frame.
  final quilt = RRect.fromRectAndCorners(
      Rect.fromLTRB(bed.left + 4, bed.top + 58, bed.right - 4, bed.bottom - 18),
      bottomLeft: const Radius.circular(12),
      bottomRight: const Radius.circular(12),
      topLeft: const Radius.circular(4),
      topRight: const Radius.circular(4));
  c.drawRRect(quilt.shift(const Offset(0, 4)), _fill(0xFF5E1E1B));
  c.drawRRect(quilt, _fill(0xFF8E2F2A));
  c.save();
  c.clipRRect(quilt);
  const cell = 21.5;
  for (var row = 0; row < 7; row++) {
    for (var col = 0; col < 8; col++) {
      final x = quilt.left + col * cell, y = quilt.top + 18 + row * cell;
      if ((row + col).isEven) {
        c.drawPath(
            Path()
              ..moveTo(x + cell / 2, y + 3)
              ..lineTo(x + cell - 3, y + cell / 2)
              ..lineTo(x + cell / 2, y + cell - 3)
              ..lineTo(x + 3, y + cell / 2)
              ..close(),
            _fill(0xFFA63C33));
      } else {
        c.drawCircle(
            Offset(x + cell / 2, y + cell / 2), 1.8, _fill(0xFFE3B65A));
      }
    }
  }
  // Side shading so the quilt reads as draping over the mattress edge.
  c.drawRect(Rect.fromLTRB(quilt.left, quilt.top, quilt.left + 8, quilt.bottom),
      _fill(0x33000000));
  c.drawRect(
      Rect.fromLTRB(quilt.right - 8, quilt.top, quilt.right, quilt.bottom),
      _fill(0x33000000));
  c.restore();
  for (var y = quilt.top + 22; y < quilt.bottom - 6; y += 9) {
    _line(c, Offset(mid, y), Offset(mid, y + 5), const Color(0xFFE3B65A), 1.4);
  }
  final sheet = RRect.fromRectAndRadius(
      Rect.fromLTRB(quilt.left, quilt.top - 2, quilt.right, quilt.top + 16),
      const Radius.circular(5));
  c.drawRRect(sheet, _fill(0xFFF1E2BE));
  _line(c, Offset(quilt.left + 4, quilt.top + 11),
      Offset(quilt.right - 4, quilt.top + 11), const Color(0xFFD9C397), 1.4);
  c.drawRRect(quilt, _stroke(0xFF5E1E1B, 1.6));
  _line(c, Offset(quilt.left + 6, quilt.bottom - 5),
      Offset(quilt.right - 6, quilt.bottom - 5), gold, 2.4);
  // Low footboard with a gold rail.
  final foot = RRect.fromRectAndRadius(
      Rect.fromLTRB(
          bed.left - 4, bed.bottom - 16, bed.right + 4, bed.bottom + 4),
      const Radius.circular(6));
  c.drawRRect(foot, Paint()..color = dark);
  c.drawRRect(foot.deflate(4), Paint()..color = wood);
  _line(c, Offset(bed.left + 6, bed.bottom - 6),
      Offset(bed.right - 6, bed.bottom - 6), gold, 2);
  // Turned corner posts with brass knobs, kept inside the frame.
  for (final p in [
    Offset(bed.left, bed.top + 6),
    Offset(bed.right, bed.top + 6),
    Offset(bed.left, bed.bottom - 4),
    Offset(bed.right, bed.bottom - 4),
  ]) {
    c.drawCircle(p, 9, _fill(0xFF3E2618));
    c.drawCircle(p, 7, Paint()..color = wood);
    c.drawCircle(p, 4.2, _fill(0xFFD9A441));
    c.drawCircle(p - const Offset(1.4, 1.4), 1.4, _fill(0xFFFFE7A6));
  }
}
