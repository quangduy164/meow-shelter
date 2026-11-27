import '../../fishing/fishing_place.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:material_ui/material_ui.dart';

import '../../collection/fish_species.dart';
import '../../fishing/fishing_river.dart';
import 'fishing_art_kit.dart';
import 'fishing_fish_art.dart';

// Floating fish market at the river mouth. The art is recorded once into a
// picture and drawn above the water surface (so ripples and sparkles do not
// cross the stalls), bobbing gently. Origin = FishingVisit.market.anchor, y = 0 is
// the waterline in the middle; three bamboo rafts carry the stalls.

class FishingMarketStalls extends StatefulWidget {
  const FishingMarketStalls(
      {super.key, required this.round, required this.frames});
  final FishingRiverRound round;
  final Listenable frames;
  @override
  State<FishingMarketStalls> createState() => _FishingMarketStallsState();
}

class _FishingMarketStallsState extends State<FishingMarketStalls> {
  late final ui.Picture _picture = () {
    final r = ui.PictureRecorder();
    paintFishMarket(Canvas(r));
    return r.endRecording();
  }();

  @override
  void dispose() {
    _picture.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
      child: CustomPaint(
          painter: _MarketPainter(widget.round, widget.frames, _picture)));
}

class _MarketPainter extends CustomPainter {
  _MarketPainter(this.round, Listenable frames, this.picture)
      : super(repaint: frames);
  final FishingRiverRound round;
  final ui.Picture picture;

  @override
  void paint(Canvas c, Size size) {
    final point = round.toScreen(FishingVisit.market.anchor);
    if (!(Offset.zero & size).inflate(240 * round.scale).contains(point)) {
      return;
    }
    c.save();
    c.clipRect(Offset.zero & size);
    c.translate(point.dx, point.dy + math.sin(round.clock * 1.3) * 1.5);
    c.scale(round.scale);
    c.drawPicture(picture);
    c.restore();
  }

  @override
  bool shouldRepaint(_MarketPainter old) =>
      old.round != round || old.picture != picture;
}

const _ink = 0xFF4A2F1C;

/// Lantern positions (world) for the night glow overlay.
List<Offset> fishMarketLanterns() => [
      for (final p in _lanterns) FishingVisit.market.anchor + p,
    ];

const _lanterns = [
  Offset(-150, -112),
  Offset(-112, -104),
  Offset(-40, -142),
  Offset(0, -134),
  Offset(40, -142),
  Offset(112, -104),
  Offset(150, -112),
];

/// The whole market around the origin (see [FishingMarketStalls]).
void paintFishMarket(Canvas c) {
  c.save();
  // Soft shadows and ripples on the water.
  for (final r in const [
    Rect.fromLTRB(-200, 10, -60, 56),
    Rect.fromLTRB(-92, 22, 92, 76),
    Rect.fromLTRB(60, 6, 200, 52),
  ]) {
    c.drawOval(r, fillPaint(0x33244850));
    c.drawOval(r.inflate(6), strokePaint(0x66E9FFF7, 1.6));
  }
  // Plank gangways between the rafts.
  for (final (a, b) in const [(-82.0, -62.0), (62.0, 82.0)]) {
    final r = Rect.fromLTRB(a - 6, 4, b + 6, 20);
    c.drawRect(r, fillPaint(0xFFB08A5A));
    c.drawRect(r, strokePaint(_ink, 1.4));
  }
  // Left: shellfish stall with a blue awning.
  _raft(c, const Rect.fromLTRB(-196, -10, -68, 36));
  _stall(c, -186, -78, -10, -88, 0xFF3F7FA8, 0xFFEAF4F7);
  _counter(c, -184, -80, -30);
  for (var i = 0; i < 3; i++) {
    _basket(c, Offset(-168 + i * 36.0, -34), i);
  }
  _bucket(c, const Offset(-80, 8));
  // Centre: the big fish stall with a red striped awning and a scale.
  _raft(c, const Rect.fromLTRB(-90, 4, 90, 56));
  _stall(c, -80, 80, 4, -124, 0xFFD9473A, 0xFFFFF4E2, big: true);
  _counter(c, -74, 74, -16);
  // Fish laid out on ice.
  c.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTRB(-68, -34, 68, -18), const Radius.circular(6)),
      fillPaint(0xFFDDF3F6));
  for (final (f, x, flip) in const [
    (FishSpecies.mackerel, -48.0, false),
    (FishSpecies.sardine, -14.0, true),
    (FishSpecies.grouper, 20.0, false),
    (FishSpecies.carp, 50.0, true),
  ]) {
    c.save();
    c.translate(x, -28);
    if (flip) c.scale(-1, 1);
    c.scale(.36);
    c.translate(-50, -32);
    FishingFishArt(f).paint(c, const Size(100, 64));
    c.restore();
  }
  // Hanging scale under the awning.
  c.drawLine(const Offset(-30, -100), const Offset(-30, -76),
      strokePaint(0xFF5E5466, 1.4));
  c.drawCircle(const Offset(-30, -70), 7, fillPaint(0xFFF2EBDD));
  c.drawCircle(const Offset(-30, -70), 7, strokePaint(0xFF5E5466, 1.6));
  c.drawLine(const Offset(-30, -70), const Offset(-27, -74),
      strokePaint(0xFFD9473A, 1.2));
  c.drawLine(const Offset(-30, -63), const Offset(-30, -56),
      strokePaint(0xFF5E5466, 1.2));
  c.drawArc(const Rect.fromLTRB(-40, -60, -20, -50), 0, math.pi, false,
      strokePaint(0xFF5E5466, 1.8));
  // Sign above the stall: a fish and a coin.
  final sign = RRect.fromRectAndRadius(
      const Rect.fromLTRB(-36, -160, 36, -136), const Radius.circular(5));
  c.drawRRect(sign, fillPaint(0xFFF2DDAE));
  c.drawRRect(sign, strokePaint(0xFF7A5533, 2));
  c.save();
  c.translate(-12, -148);
  c.scale(.26);
  c.translate(-50, -32);
  const FishingFishArt(FishSpecies.perch).paint(c, const Size(100, 64));
  c.restore();
  c.drawCircle(const Offset(18, -148), 7, fillPaint(0xFFF2C14E));
  c.drawCircle(const Offset(18, -148), 7, strokePaint(0xFFB7791F, 1.6));
  c.drawCircle(const Offset(18, -148), 3.5, strokePaint(0xFFB7791F, 1));
  c.drawLine(
      const Offset(0, -136), const Offset(0, -124), strokePaint(0xFF7A5533, 2));
  // Right: a sampan with a woven roof, moored to its own raft.
  _raft(c, const Rect.fromLTRB(68, -15, 196, 30));
  _sampan(c);
  // Lantern strings across the stalls.
  _string(c, const Offset(-186, -92), const Offset(-78, -92));
  _string(c, const Offset(-80, -128), const Offset(80, -128));
  _string(c, const Offset(78, -92), const Offset(190, -92));
  for (final p in _lanterns) {
    _lantern(c, p);
  }
  // Pennants on the corner poles.
  for (final (x, color) in const [(-186.0, 0xFFF2C14E), (190.0, 0xFF4F8E93)]) {
    c.drawLine(Offset(x, -92), Offset(x, -128), strokePaint(0xFF6E4A2A, 3));
    c.drawPath(
        Path()
          ..moveTo(x, -128)
          ..lineTo(x + 22, -122)
          ..lineTo(x, -114)
          ..close(),
        fillPaint(color));
  }
  c.restore();
}

/// Bamboo raft seen from the front: a deck of poles with lashings.
void _raft(Canvas c, Rect r) {
  final deck = RRect.fromRectAndRadius(r, const Radius.circular(10));
  c.drawRRect(deck.shift(const Offset(0, 6)), fillPaint(0xFF7A5A33));
  c.drawRRect(deck, fillPaint(0xFFD9B26F));
  c.save();
  c.clipRRect(deck);
  for (var y = r.top + 6; y < r.bottom; y += 9) {
    c.drawLine(
        Offset(r.left, y), Offset(r.right, y), strokePaint(0x55856038, 1.4));
  }
  c.restore();
  for (final x in [r.left + 14, r.right - 14]) {
    c.drawLine(Offset(x, r.top + 2), Offset(x, r.bottom - 2),
        strokePaint(0xFF8A6A3E, 3));
  }
  // Pole ends on the near side.
  for (var y = r.top + 6; y < r.bottom; y += 9) {
    c.drawCircle(Offset(r.left + 3, y), 3.2, fillPaint(0xFFE8CF95));
    c.drawCircle(Offset(r.right - 3, y), 3.2, fillPaint(0xFFE8CF95));
  }
  c.drawRRect(deck, strokePaint(_ink, 2));
}

/// Four-post stall with a scalloped striped awning between [left] and
/// [right], standing on [floor], awning edge at [roof].
void _stall(Canvas c, double left, double right, double floor, double roof,
    int stripe, int cream,
    {bool big = false}) {
  for (final x in [left + 4, right - 4]) {
    c.drawLine(Offset(x, floor), Offset(x, roof), strokePaint(0xFF6E4A2A, 5));
    c.drawLine(Offset(x, floor), Offset(x, roof), strokePaint(0xFFA8703F, 2.6));
  }
  final rise = big ? 26.0 : 20.0;
  final top = roof - rise;
  final cloth = Path()
    ..moveTo(left - 10, roof)
    ..lineTo(left + 8, top)
    ..lineTo(right - 8, top)
    ..lineTo(right + 10, roof)
    ..close();
  c.drawPath(cloth, fillPaint(cream));
  c.save();
  c.clipPath(cloth);
  final w = (right - left + 20) / (big ? 8 : 6);
  for (var i = 0; i < (big ? 8 : 6); i += 2) {
    final x0 = left - 10 + i * w;
    c.drawPath(
        Path()
          ..moveTo(x0, roof)
          ..lineTo(x0 + w * .4, top)
          ..lineTo(x0 + w * 1.4, top)
          ..lineTo(x0 + w, roof)
          ..close(),
        fillPaint(stripe));
  }
  c.restore();
  c.drawPath(cloth, strokePaint(_ink, 2));
  // Scalloped valance.
  final n = big ? 8 : 6;
  final step = (right - left + 20) / n;
  for (var i = 0; i < n; i++) {
    final x = left - 10 + i * step;
    final r = Rect.fromLTWH(x, roof - 6, step, 14);
    c.drawArc(r, 0, math.pi, true, fillPaint(i.isEven ? stripe : cream));
    c.drawArc(r, 0, math.pi, false, strokePaint(_ink, 1.4));
  }
}

void _counter(Canvas c, double left, double right, double top) {
  final r = Rect.fromLTRB(left, top, right, top + 22);
  c.drawRect(r, fillPaint(0xFFB98552));
  for (var x = left + 10; x < right; x += 12) {
    c.drawLine(
        Offset(x, top + 3), Offset(x, top + 20), strokePaint(0x44704B28, 1.2));
  }
  c.drawRect(Rect.fromLTRB(left - 3, top - 4, right + 3, top + 1),
      fillPaint(0xFF8A5A33));
  c.drawRect(r, strokePaint(_ink, 1.6));
}

/// Woven basket of shrimp, clams or crabs.
void _basket(Canvas c, Offset p, int kind) {
  final body = Path()
    ..moveTo(p.dx - 14, p.dy - 6)
    ..lineTo(p.dx + 14, p.dy - 6)
    ..lineTo(p.dx + 10, p.dy + 6)
    ..lineTo(p.dx - 10, p.dy + 6)
    ..close();
  final heap = [0xFFF08A5D, 0xFFE9DCC4, 0xFFD9473A][kind];
  for (var i = 0; i < 5; i++) {
    c.drawCircle(Offset(p.dx - 9 + i * 4.5, p.dy - 7 - (i % 2) * 3), 4.2,
        fillPaint(heap));
    c.drawCircle(Offset(p.dx - 9 + i * 4.5, p.dy - 7 - (i % 2) * 3), 4.2,
        strokePaint(0x55402A15, 1));
  }
  c.drawPath(body, fillPaint(0xFFC9A46A));
  c.drawLine(Offset(p.dx - 12, p.dy), Offset(p.dx + 12, p.dy),
      strokePaint(0xFF8A6A3E, 1.2));
  c.drawPath(body, strokePaint(_ink, 1.4));
}

void _bucket(Canvas c, Offset p) {
  final r = Rect.fromCenter(center: p, width: 18, height: 18);
  c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(3)),
      fillPaint(0xFF5E8FB0));
  c.drawOval(Rect.fromCenter(center: r.topCenter, width: 18, height: 6),
      fillPaint(0xFF9FD3F0));
  c.drawArc(Rect.fromCenter(center: r.topCenter, width: 16, height: 18),
      math.pi, math.pi, false, strokePaint(0xFF5E5466, 1.2));
  c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(3)),
      strokePaint(_ink, 1.4));
}

/// Little wooden sampan with a woven bamboo roof and crates of fruit.
void _sampan(Canvas c) {
  final hull = Path()
    ..moveTo(70, -26)
    ..quadraticBezierTo(80, -6, 104, -4)
    ..lineTo(164, -4)
    ..quadraticBezierTo(186, -6, 196, -28)
    ..lineTo(180, -22)
    ..lineTo(86, -22)
    ..close();
  c.drawPath(hull, fillPaint(0xFF8A5A33));
  c.drawLine(const Offset(84, -16), const Offset(182, -16),
      strokePaint(0xFFD9A441, 2.4));
  c.drawPath(hull, strokePaint(_ink, 2));
  // Woven roof arch.
  final roof = Path()
    ..moveTo(100, -22)
    ..quadraticBezierTo(102, -74, 134, -76)
    ..quadraticBezierTo(166, -74, 168, -22)
    ..close();
  c.drawPath(roof, fillPaint(0xFF6B4A2C));
  final arch = Path()
    ..moveTo(108, -24)
    ..quadraticBezierTo(110, -66, 134, -68)
    ..quadraticBezierTo(158, -66, 160, -24)
    ..close();
  c.drawPath(arch, fillPaint(0xFFD9B26F));
  c.save();
  c.clipPath(arch);
  for (var i = -6; i < 8; i++) {
    c.drawLine(Offset(108 + i * 8.0, -70), Offset(128 + i * 8.0, -20),
        strokePaint(0x44704B28, 1.6));
    c.drawLine(Offset(160 - i * 8.0, -70), Offset(140 - i * 8.0, -20),
        strokePaint(0x33FFE7B0, 1.6));
  }
  c.restore();
  c.drawPath(roof, strokePaint(_ink, 2));
  // Fruit crates on the bow.
  for (final (x, fruit) in const [(84.0, 0xFFF2C14E), (180.0, 0xFF6DB04A)]) {
    final r = Rect.fromCenter(center: Offset(x, -30), width: 18, height: 12);
    c.drawCircle(Offset(x - 4, -37), 4, fillPaint(fruit));
    c.drawCircle(Offset(x + 4, -37), 4, fillPaint(fruit));
    c.drawCircle(Offset(x, -40), 4, fillPaint(fruit));
    c.drawRect(r, fillPaint(0xFFC08A4E));
    c.drawRect(r, strokePaint(_ink, 1.2));
  }
}

void _string(Canvas c, Offset a, Offset b) {
  final mid = Offset.lerp(a, b, .5)! + const Offset(0, 14);
  c.drawPath(
      Path()
        ..moveTo(a.dx, a.dy)
        ..quadraticBezierTo(mid.dx, mid.dy, b.dx, b.dy),
      strokePaint(0xFF4A3727, 1.2));
}

void _lantern(Canvas c, Offset p) {
  final body =
      Rect.fromCenter(center: p + const Offset(0, 8), width: 11, height: 13);
  c.drawLine(p, p + const Offset(0, 2), strokePaint(0xFF3B2C21, 1));
  c.drawOval(body, fillPaint(0xFFE2553F));
  c.drawOval(body.deflate(3), fillPaint(0xFFFFB45C));
  c.drawRect(Rect.fromCenter(center: body.topCenter, width: 7, height: 2.4),
      fillPaint(0xFF3B2C21));
  c.drawRect(Rect.fromCenter(center: body.bottomCenter, width: 7, height: 2.4),
      fillPaint(0xFF3B2C21));
  c.drawLine(body.bottomCenter, body.bottomCenter + const Offset(0, 5),
      strokePaint(0xFFF2C14E, 1.2));
  c.drawOval(body, strokePaint(0xFF6B2A1E, 1.1));
}
