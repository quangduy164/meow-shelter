part of 'fishing_cabin_art.dart';

class FishingCabinRoom extends StatefulWidget {
  const FishingCabinRoom(
      {super.key,
      required this.round,
      required this.cat,
      required this.onExit,
      this.hour = 12});
  final FishingCabin round;

  /// Real local hour; the cabin follows the same day/night as outside.
  final double hour;
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
                              chestFull: _chestFull,
                              night: FishingLighting.at(widget.hour).night)))),
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
              Positioned.fill(
                  child: IgnorePointer(
                      child: CustomPaint(
                          painter: _CabinNightPainter(
                              FishingLighting.at(widget.hour),
                              scale,
                              offset,
                              widget.round.clock,
                              widget.round.room)))),
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
      {this.chestFull = false, this.night = 0});
  final double night;
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
        _seaView(c, _windows[i], clock, sun: i == 0, night: night);
      }
    }
    if (room == 0 && night > .05) {
      // Stern windows turn to a starry night sea.
      for (var i = 0; i < 4; i++) {
        final r = Rect.fromLTWH(304 + i * 50.0, 86, 42, 60);
        c.save();
        c.clipRRect(RRect.fromRectAndCorners(r,
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20)));
        // Stop above the desk items that overlap the window bottoms.
        c.clipRect(Rect.fromLTRB(r.left, r.top, r.right, 123));
        c.drawRect(r, Paint()..color = Color.fromRGBO(20, 35, 63, night * .92));
        c.drawRect(Rect.fromLTRB(r.left, 110, r.right, r.bottom),
            Paint()..color = Color.fromRGBO(13, 33, 56, night * .92));
        _nightSky(
            c, Rect.fromLTRB(r.left, r.top, r.right, 128), 128, clock, night,
            moon: i == 2);
        c.restore();
        final bar = Paint()
          ..color = const Color(0xFF4A2E1D)
          ..strokeWidth = 2.5;
        c.drawLine(Offset(r.center.dx, 87), Offset(r.center.dx, 146), bar);
        c.drawLine(Offset(r.left, 112), Offset(r.right, 112), bar);
      }
    }
    if (room == 1) _chandelierFlames(c, clock, night);
    if (room == 1 && chestFull) {
      // Fish tails poke out of the coins and a sparkle pulses: tap me.
      final chest = FishingCabin.chest.topLeft;
      for (final (dx, color) in const [
        (26.0, 0xFF7CC4D8),
        (58.0, 0xFFF08A4B)
      ]) {
        final x = chest.dx + dx;
        final sway = math.sin(clock * 4 + x) * 3;
        c.drawPath(
            Path()
              ..moveTo(x, chest.dy + 28)
              ..lineTo(x - 9 + sway, chest.dy + 8)
              ..lineTo(x + 9 + sway, chest.dy + 8)
              ..close(),
            Paint()..color = Color(color));
      }
      final glow = (math.sin(clock * 3) + 1) / 2;
      final star = chest + const Offset(80, -2);
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
      old.chestFull != chestFull ||
      old.night != night;
}

/// Dims the cabin (cat included) for the hour and adds warm lamp light,
/// or cool moonlight under the bedroom windows.
class _CabinNightPainter extends CustomPainter {
  _CabinNightPainter(
      this.light, this.scale, this.offset, this.clock, this.room);
  final FishingLighting light;
  final double scale, clock;
  final Offset offset;
  final int room;

  @override
  void paint(Canvas c, Size size) {
    final night = light.night;
    if (night < .02 && light.warmth < .02) return;
    final tint = Color.lerp(
        Color.lerp(Colors.white, const Color(0xFFD9D0E2), night * .8)!,
        const Color(0xFFFFC890),
        light.warmth * .35)!;
    c.drawRect(
        Offset.zero & size,
        Paint()
          ..color = tint
          ..blendMode = BlendMode.multiply);
    if (night < .05) return;
    c.save();
    c.translate(offset.dx, offset.dy);
    c.scale(scale);
    void glow(Offset p, double r, Color color, double strength) => c.drawCircle(
        p,
        r,
        Paint()
          ..blendMode = BlendMode.plus
          ..shader = RadialGradient(colors: [
            color.withValues(alpha: strength * night),
            color.withValues(alpha: 0),
          ]).createShader(Rect.fromCircle(center: p, radius: r)));
    final flick = math.sin(clock * 9) * .5 + math.sin(clock * 5.3) * .5;
    if (room == 0) {
      for (final x in [220.0, 580.0]) {
        glow(Offset(x, 110), 170 + flick * 6, const Color(0xFFFFC870), .45);
      }
      glow(const Offset(487, 118), 80, const Color(0xFFFFD27A), .5);
    } else {
      glow(_chandelier + const Offset(0, -10), 260 + flick * 8,
          const Color(0xFFFFC870), .5);
      for (final w in _windows) {
        c.drawOval(
            Rect.fromCenter(
                center: Offset(w.center.dx, 300),
                width: w.width * 1.1,
                height: 150),
            Paint()
              ..blendMode = BlendMode.plus
              ..shader = RadialGradient(colors: [
                Color.fromRGBO(150, 180, 230, .22 * night),
                const Color(0x0096B4E6),
              ]).createShader(Rect.fromCenter(
                  center: Offset(w.center.dx, 300),
                  width: w.width * 1.1,
                  height: 150)));
      }
    }
    c.restore();
  }

  @override
  bool shouldRepaint(_CabinNightPainter old) =>
      old.clock != clock ||
      old.light.hour != light.hour ||
      old.scale != scale ||
      old.room != room;
}
