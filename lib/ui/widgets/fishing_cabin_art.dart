import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:material_ui/material_ui.dart';
import '../../collection/fish_collection.dart';
import '../../collection/fish_species.dart';
import '../../fishing/fishing_cabin.dart';
import '../../fishing/fishing_cabin_chest.dart';
import 'fishing_fish_art.dart';
import '../../fishing/fishing_river.dart';
import '../../game/constants.dart';
import '../design.dart';
import 'cat_sprite.dart';
import 'game_glyphs.dart';
import 'round_button.dart';

void _line(Canvas c, Offset a, Offset b, Color color, double w) => c.drawLine(
    a,
    b,
    Paint()
      ..color = color
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round);
void _rect(Canvas c, Rect r, Color color) => c.drawRRect(
    RRect.fromRectAndRadius(r, const Radius.circular(4)),
    Paint()..color = color);
ui.Picture _record(void Function(Canvas) draw) {
  final r = ui.PictureRecorder();
  draw(Canvas(r));
  return r.endRecording();
}

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

Paint _fill(int color) => Paint()..color = Color(color);
Paint _stroke(int color, double width) => Paint()
  ..color = Color(color)
  ..style = PaintingStyle.stroke
  ..strokeWidth = width
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round;

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

class FishingCabinRoom extends StatefulWidget {
  const FishingCabinRoom(
      {super.key,
      required this.round,
      required this.cat,
      required this.onExit});
  final FishingCabin round;
  final String cat;
  final VoidCallback onExit;
  @override
  State<FishingCabinRoom> createState() => _FishingCabinRoomState();
}

class _FishingCabinRoomState extends State<FishingCabinRoom> {
  late final _pictures = [_record(_room), _record(_bedroom)];
  late bool _chestFull = FishingCabinChest.full(FishCollection.instance);
  bool _opening = false, _showChest = false;
  List<FishSpecies>? _reward;

  Future<void> _openChest() async {
    final fish = await FishingCabinChest.open(FishCollection.instance);
    if (!mounted) return;
    setState(() {
      _opening = false;
      _showChest = true;
      _reward = fish;
      _chestFull = FishingCabinChest.full(FishCollection.instance);
    });
  }

  Widget _chestPopup() => Positioned.fill(
      child: ColoredBox(
          color: const Color(0x88000000),
          child: Center(
              child: Container(
                  width: 340,
                  padding: const EdgeInsets.all(DS.spaceMd),
                  decoration: BoxDecoration(
                      color: DS.cream,
                      borderRadius: BorderRadius.circular(DS.radiusSm),
                      border: Border.all(color: DS.wood, width: 3)),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Text('RƯƠNG KHO BÁU',
                        style: TextStyle(
                            color: DS.ink,
                            fontWeight: FontWeight.w900,
                            fontSize: DS.fontTitle)),
                    const SizedBox(height: DS.spaceSm),
                    if (_reward case final fish?) ...[
                      Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (final f in fish)
                              Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 6),
                                  child: Column(children: [
                                    SizedBox(
                                        width: 70,
                                        height: 46,
                                        child: CustomPaint(
                                            painter: FishingFishArt(f))),
                                    Text(f.label,
                                        style: const TextStyle(
                                            color: DS.ink,
                                            fontSize: DS.fontCaption,
                                            fontWeight: FontWeight.w700)),
                                  ])),
                          ]),
                      const SizedBox(height: DS.spaceSm),
                      const Text('Đã cho cá vào giỏ!',
                          style: TextStyle(color: DS.ink)),
                    ] else
                      const Text('Rương trống rồi, mai quay lại nhé!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: DS.ink)),
                    const SizedBox(height: DS.spaceMd),
                    ElevatedButton(
                        onPressed: () => setState(() => _showChest = false),
                        style: DS.primary,
                        child: Text(_reward == null ? 'ĐÓNG' : 'NHẬN')),
                  ])))));
  @override
  void dispose() {
    for (final p in _pictures) {
      p.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ColoredBox(
      color: const Color(0xFF385D64),
      child: LayoutBuilder(builder: (context, box) {
        if (widget.round.atChest && !_opening) {
          widget.round.chestRequested = false;
          _opening = true;
          WidgetsBinding.instance.addPostFrameCallback((_) => _openChest());
        }
        final scale = math.min(box.maxWidth / 800, box.maxHeight / 480);
        final offset = Offset((box.maxWidth - 800 * scale) / 2,
            (box.maxHeight - 480 * scale) / 2);
        final point = offset + widget.round.cat * scale;
        final catSize = 88 * scale;
        return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop) widget.onExit();
            },
            child: Stack(children: [
              Positioned.fill(
                  child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapUp: (e) {
                        final p = (e.localPosition - offset) / scale;
                        final room = widget.round.room;
                        if (room == 0 &&
                            (p - FishingCabin.exit).distance < 40) {
                          widget.onExit();
                        } else if (room == 1 &&
                            FishingCabin.chestTap.contains(p)) {
                          widget.round.goToChest();
                        } else if ((room == 0
                                ? FishingCabin.doorTap
                                : FishingCabin.bedroomDoorTap)
                            .contains(p)) {
                          widget.round.switchRoom();
                        } else {
                          widget.round.walkTo(p);
                        }
                      },
                      child: CustomPaint(
                          painter: _RoomPainter(
                              _pictures[widget.round.room],
                              scale,
                              offset,
                              widget.round.clock,
                              widget.round.room,
                              chestFull: _chestFull)))),
              Positioned(
                  left: point.dx - 17 * scale,
                  top: point.dy - 2 * scale,
                  child: IgnorePointer(
                      child: Container(
                          width: 34 * scale,
                          height: 12 * scale,
                          decoration: const BoxDecoration(
                              color: Color(0x335E4937),
                              shape: BoxShape.circle)))),
              Positioned(
                  left: point.dx - catSize / 2,
                  top: point.dy - catSize * .79,
                  child: IgnorePointer(
                      child: CatSprite(
                          type: widget.cat,
                          size: catSize,
                          action: widget.round.walking ? 'walk' : 'idle',
                          frames:
                              widget.round.walking ? framesWalk : framesIdle,
                          frame: (widget.round.clock *
                                      (widget.round.walking ? 10 : 7))
                                  .floor() %
                              (widget.round.walking ? framesWalk : framesIdle),
                          flip: !widget.round.facingRight))),
              Positioned(
                  left: MediaQuery.paddingOf(context).left + 8,
                  top: MediaQuery.paddingOf(context).top + 8,
                  child: RoundButton(
                      glyph: GameGlyph.back,
                      tooltip: 'Ra ngoài thuyền',
                      onPressed: widget.onExit)),
              Positioned(
                  top: MediaQuery.paddingOf(context).top + 10,
                  left: 75,
                  right: 75,
                  child: IgnorePointer(
                      child: Text(
                          widget.round.room == 0
                              ? 'KHOANG THUYỀN'
                              : 'PHÒNG NGỦ',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: DS.cream,
                              fontWeight: FontWeight.w900,
                              fontSize: DS.fontTitle)))),
              Positioned(
                  bottom: MediaQuery.paddingOf(context).bottom + 10,
                  right: 16,
                  child: ElevatedButton.icon(
                      onPressed: widget.onExit,
                      icon: const GameGlyphView(GameGlyph.back, size: 20),
                      label: const Text('RA NGOÀI'),
                      style: DS.primary)),
              if (_showChest) _chestPopup(),
            ]));
      }));
}

class _RoomPainter extends CustomPainter {
  _RoomPainter(this.picture, this.scale, this.offset, this.clock, this.room,
      {this.chestFull = false});
  final bool chestFull;
  final int room;
  final ui.Picture picture;
  final double scale, clock;
  final Offset offset;
  @override
  void paint(Canvas c, Size size) {
    c.save();
    c.clipRect(Offset.zero & size);
    c.translate(offset.dx, offset.dy);
    c.scale(scale);
    c.drawPicture(picture);
    if (room == 1) {
      for (var i = 0; i < _windows.length; i++) {
        _seaView(c, _windows[i], clock, sun: i == 0);
      }
    }
    if (room == 1 && chestFull) {
      // Fish tails poke out of the coins and a sparkle pulses: tap me.
      for (final (x, color) in const [
        (92.0, 0xFF7CC4D8),
        (124.0, 0xFFF08A4B)
      ]) {
        final sway = math.sin(clock * 4 + x) * 3;
        c.drawPath(
            Path()
              ..moveTo(x, 366)
              ..lineTo(x - 9 + sway, 346)
              ..lineTo(x + 9 + sway, 346)
              ..close(),
            Paint()..color = Color(color));
      }
      final glow = (math.sin(clock * 3) + 1) / 2;
      const star = Offset(146, 336);
      final sparkle = Paint()
        ..color = Color.fromRGBO(255, 241, 170, .5 + glow * .5)
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round;
      final r = 6 + glow * 4;
      c.drawLine(star - Offset(r, 0), star + Offset(r, 0), sparkle);
      c.drawLine(star - Offset(0, r), star + Offset(0, r), sparkle);
    }
    for (final x in room == 0 ? const [220.0, 580.0] : const <double>[]) {
      final flicker = math.sin(clock * 7 + x) * .5 + math.sin(clock * 11) * .3;
      c.drawCircle(Offset(x, 104), 34 + flicker * 3,
          Paint()..color = Color.fromRGBO(255, 211, 107, .16 + flicker * .04));
    }
    c.restore();
  }

  @override
  bool shouldRepaint(_RoomPainter old) =>
      old.clock != clock ||
      old.scale != scale ||
      old.offset != offset ||
      old.picture != picture ||
      old.chestFull != chestFull;
}

/// Top-down opening through a side wall: floor planks run through the gap,
/// with a post at each end so the way through reads at a glance.
void _wallGap(Canvas c, {required bool right}) {
  const top = 212.0, bottom = 302.0;
  final gap = right
      ? const Rect.fromLTRB(738, top, 760, bottom)
      : const Rect.fromLTRB(40, top, 62, bottom);
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
  c.translate(0, 34);
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
