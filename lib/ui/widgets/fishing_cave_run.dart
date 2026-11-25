import 'fishing_dialog_kit.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:material_ui/material_ui.dart';
import '../../collection/fish_collection.dart';
import '../../fishing/fishing_cave.dart';
import '../../game/constants.dart';
import '../design.dart';
import 'cat_sprite.dart';
import 'fishing_art_kit.dart';
import 'fishing_rock_art.dart';
import 'game_glyphs.dart';
import 'round_button.dart';

/// The mountain cave parkour run. Level art is recorded once; the camera
/// follows the cat and the far wall scrolls slower for depth.
class FishingCaveRun extends StatefulWidget {
  const FishingCaveRun(
      {super.key, required this.cave, required this.cat, required this.onExit});
  final FishingCave cave;
  final String cat;
  final VoidCallback onExit;
  @override
  State<FishingCaveRun> createState() => _FishingCaveRunState();
}

class _FishingCaveRunState extends State<FishingCaveRun> {
  late final _back = _record(_paintBackWall, _backWidth);
  late final _level = _record(_paintLevel, FishingCave.length);
  bool _claiming = false;

  static ui.Picture _record(void Function(Canvas) draw, double width) {
    final r = ui.PictureRecorder();
    draw(Canvas(r, Rect.fromLTWH(0, 0, width, FishingCave.height)));
    return r.endRecording();
  }

  @override
  void dispose() {
    _back.dispose();
    _level.dispose();
    super.dispose();
  }

  Future<void> _claim() async {
    await widget.cave.claimReward(FishCollection.instance);
    if (mounted) setState(() => _claiming = false);
  }

  Widget _finishPanel() {
    final cave = widget.cave;
    final fish = cave.reward;
    final best = cave.best;
    return FishingRewardPanel(
        hero: FishingStarsHero(stars: cave.stars),
        title: 'VƯỢT QUA HANG!',
        badge: cave.newBest ? 'Kỷ lục mới!' : null,
        stats: [
          (
            Icons.set_meal_rounded,
            '${cave.collected.length}/${FishingCave.tokens.length}'
          ),
          (Icons.timer_rounded, '${cave.runTime.toStringAsFixed(1)} s'),
          (Icons.personal_injury_rounded, 'Ngã ${cave.falls}'),
        ],
        fish: fish,
        note: [
          if (fish != null)
            cave.stars >= 3
                ? 'Rương tặng ${fish.length} cá, có cá đèn lồng!'
                : 'Rương tặng ${fish.length} cá · 3 sao có cá đèn lồng',
          if (fish == null && !_claiming)
            'Hôm nay đã nhận quà rương rồi, mai quay lại nhé!',
          if (cave.stars < 3) '3 sao: gom 22 cá vàng, ngã tối đa 1 lần',
          if (!cave.newBest && best != null)
            'Kỷ lục: ${best.stars} sao · ${best.time.toStringAsFixed(1)} giây',
        ].join('\n'),
        actions: [
          OutlinedButton(
              onPressed: () => setState(cave.restart),
              child: const Text('CHƠI LẠI')),
          ElevatedButton(
              onPressed: widget.onExit,
              style: DS.primary,
              child: const Text('RA NGOÀI')),
        ]);
  }

  @override
  Widget build(BuildContext context) {
    final cave = widget.cave;
    if (cave.state == CaveRunState.finished &&
        !cave.rewardChecked &&
        !_claiming) {
      _claiming = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _claim());
    }
    return ColoredBox(
        color: const Color(0xFF1C1A22),
        child: LayoutBuilder(builder: (context, box) {
          final scale = box.maxHeight / FishingCave.height;
          final viewWidth = box.maxWidth / scale;
          final camera = (cave.cat.dx - viewWidth * .3)
              .clamp(0.0, math.max(0.0, FishingCave.length - viewWidth))
              .toDouble();
          final catSize = 84 * scale;
          final screenCat =
              Offset((cave.cat.dx - camera) * scale, cave.cat.dy * scale);
          final pose = _pose(cave);
          final pad = MediaQuery.paddingOf(context);
          return PopScope(
              canPop: false,
              onPopInvokedWithResult: (didPop, _) {
                if (!didPop) widget.onExit();
              },
              child: Stack(children: [
                Positioned.fill(
                    child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapDown: (_) => cave.tap(),
                        child: CustomPaint(
                            painter: _CavePainter(
                                cave, _back, _level, scale, camera)))),
                Positioned(
                    left: screenCat.dx - catSize / 2,
                    top: screenCat.dy - catSize * .8 + pose.$3 * catSize,
                    child: IgnorePointer(
                        child: Opacity(
                            opacity: cave.hurt > 0 &&
                                    (cave.clock * 16).floor().isEven
                                ? .35
                                : 1,
                            child: CatSprite(
                                type: widget.cat,
                                size: catSize,
                                action: pose.$1,
                                frames: switch (pose.$1) {
                                  'jump' => framesJump,
                                  'roll' => framesRoll,
                                  'run' => framesRun,
                                  'panic' => framesPanic,
                                  _ => framesIdle,
                                },
                                frame: pose.$2)))),
                Positioned(
                    left: pad.left + 8,
                    top: pad.top + 8,
                    child: RoundButton(
                        glyph: GameGlyph.back,
                        size: 44,
                        tooltip: 'Ra khỏi hang',
                        onPressed: widget.onExit)),
                Positioned(
                    top: pad.top + 12,
                    right: pad.right + 12,
                    child: IgnorePointer(
                        child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                                color: const Color(0xB31E2A30),
                                borderRadius: BorderRadius.circular(16)),
                            child: Text(
                                '${FishingCave.sectionNames[cave.section]} '
                                '${cave.section + 1}/${FishingCave.sectionNames.length}'
                                '  ·  Cá vàng ${cave.collected.length}/${FishingCave.tokens.length}',
                                style: const TextStyle(
                                    color: Color(0xFFFFE08A),
                                    fontWeight: FontWeight.w900))))),
                if (cave.state == CaveRunState.ready)
                  const Positioned.fill(
                      child: IgnorePointer(
                          child: Center(
                              child: Text(
                                  'CHẠM ĐỂ CHẠY\nChạm để nhảy · chạm lần nữa trên không để nhảy đôi\n'
                                  'Né thạch nhũ, dơi, gờ đá sập · gom cá vàng để được 3 sao',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: DS.fontButton,
                                      fontWeight: FontWeight.w900,
                                      shadows: [
                                        Shadow(
                                            color: Colors.black, blurRadius: 6)
                                      ]))))),
                if (cave.state == CaveRunState.finished) _finishPanel(),
              ]));
        }));
  }
}

/// Sheet, frame and vertical correction for the cat. The jump sheet draws
/// the cat higher in its air frames; [jumpSheetLift] cancels that so the feet
/// follow the physics.
(String, int, double) _pose(FishingCave cave) {
  // Pit or crystal spike: the cat panics while it drops.
  if (cave.state == CaveRunState.falling) {
    return ('panic', (cave.clock * 12).floor() % framesPanic, 0);
  }
  // Double jump: a somersault through the curled frames 1-4 of the roll.
  if (cave.spin > 0) {
    final t = 1 - cave.spin / FishingCave.spinTime;
    return ('roll', 1 + (t * 4).floor().clamp(0, 3), 0);
  }
  final airborne = !cave.grounded || cave.state == CaveRunState.falling;
  if (airborne) {
    final frame = cave.vy < -280
        ? 1
        : cave.vy < 280
            ? 2
            : 3;
    return ('jump', frame, jumpSheetLift[frame]);
  }
  if (cave.landing > 0) return ('jump', 4, 0);
  if (cave.state == CaveRunState.running) {
    return ('run', (cave.clock * 14).floor() % framesRun, 0);
  }
  return ('idle', (cave.clock * 7).floor() % framesIdle, 0);
}

class _CavePainter extends CustomPainter {
  _CavePainter(this.cave, this.back, this.level, this.scale, this.camera);
  final FishingCave cave;
  final ui.Picture back, level;
  final double scale, camera;

  @override
  void paint(Canvas c, Size size) {
    c.save();
    c.clipRect(Offset.zero & size);
    c.scale(scale);
    c.save();
    c.translate(-camera * .5, 0);
    c.drawPicture(back);
    c.restore();
    c.translate(-camera, 0);
    c.drawPicture(level);
    final t = cave.clock;
    final viewLeft = camera - 120,
        viewRight = camera + size.width / scale + 120;
    // Crumbling ledges shake once stood on, then are gone.
    for (var i = 0; i < FishingCave.ledges.length; i++) {
      final l = FishingCave.ledges[i];
      if (!l.crumble || cave.ledgeGone(i)) continue;
      if (l.right < viewLeft || l.left > viewRight) continue;
      final stood = cave.crumbleTime[i];
      c.save();
      if (stood != null) {
        final k = stood / FishingCave.crumbleDelay;
        c.translate(math.sin(t * 60) * 2.5 * k, k * k * 6);
      }
      _paintLedge(c, l);
      c.restore();
    }
    // Stalactites hang from the ceiling, drop, then lie shattered.
    for (var i = 0; i < FishingCave.stalactites.length; i++) {
      final x = FishingCave.stalactites[i];
      if (x < viewLeft || x > viewRight) continue;
      final tip = cave.stalactiteY[i];
      if (tip != null && tip >= FishingCave.floor) {
        for (var k = -1; k <= 1; k++) {
          final bx = x + k * FishingCave.shardHalf * .7;
          final tall = k == 0 ? 20.0 : 13.0;
          final shard = Path()
            ..moveTo(bx - 8, FishingCave.floor)
            ..lineTo(bx + k * 3, FishingCave.floor - tall)
            ..lineTo(bx + 8, FishingCave.floor)
            ..close();
          c.drawPath(shard, fillPaint(0xFF9A8CA8));
          c.drawPath(shard, strokePaint(0xFF2A2430, 1.8));
        }
        continue;
      }
      final y = tip ?? FishingCave.stalactiteTop;
      // A hanging one trembles a bit so it reads as loose.
      final shake = tip == null ? math.sin(t * 30 + i) * 1.2 : 0.0;
      final rock = Path()
        ..moveTo(x - 16 + shake, y - 74)
        ..lineTo(x + 16 + shake, y - 74)
        ..lineTo(x + 9 + shake, y - 30)
        ..lineTo(x + shake, y)
        ..lineTo(x - 9 + shake, y - 30)
        ..close();
      c.drawPath(rock, fillPaint(0xFF8E80A0));
      c.drawPath(rock, strokePaint(0xFF1E1A24, 2.4));
      c.drawLine(Offset(x - 5 + shake, y - 66), Offset(x - 2 + shake, y - 18),
          strokePaint(0x88FFFFFF, 2));
    }
    // Bats flap in place.
    for (var i = 0; i < FishingCave.bats.length; i++) {
      final p = cave.batAt(i);
      if (p.dx < viewLeft || p.dx > viewRight) continue;
      final flap = math.sin(t * 18 + i * 2);
      c.save();
      c.translate(p.dx, p.dy);
      for (final side in const [-1.0, 1.0]) {
        c.drawPath(
            Path()
              ..moveTo(side * 6, -2)
              ..quadraticBezierTo(
                  side * 22, -16 * flap - 6, side * 34, -14 * flap)
              ..lineTo(side * 26, 2 - 4 * flap)
              ..lineTo(side * 18, -2 - 6 * flap)
              ..lineTo(side * 10, 6)
              ..close(),
            fillPaint(0xFF3B2B4A));
      }
      c.drawOval(const Rect.fromLTWH(-10, -10, 20, 20), fillPaint(0xFF4A3860));
      c.drawPath(
          Path()
            ..moveTo(-8, -8)
            ..lineTo(-6, -16)
            ..lineTo(-2, -9)
            ..moveTo(8, -8)
            ..lineTo(6, -16)
            ..lineTo(2, -9),
          fillPaint(0xFF4A3860));
      c.drawCircle(const Offset(-4, -2), 2.2, fillPaint(0xFFFF6B5A));
      c.drawCircle(const Offset(4, -2), 2.2, fillPaint(0xFFFF6B5A));
      c.restore();
    }
    // Torches at checkpoints flicker; reached ones burn bright.
    for (var i = 1; i < FishingCave.checkpoints.length; i++) {
      final p = Offset(FishingCave.checkpoints[i] + 10, FishingCave.floor - 62);
      final lit = cave.checkpoint >= i;
      final f = math.sin(t * 12 + i) * .5 + math.sin(t * 7 + i * 2) * .5;
      c.drawCircle(p, 40 + f * 4, fillPaint(lit ? 0x40FFB347 : 0x1AFFB347));
      c.drawPath(
          Path()
            ..moveTo(p.dx - 6, p.dy + 4)
            ..quadraticBezierTo(
                p.dx - 7, p.dy - 8, p.dx + f * 2, p.dy - 16 - f * 3)
            ..quadraticBezierTo(p.dx + 7, p.dy - 8, p.dx + 6, p.dy + 4)
            ..close(),
          fillPaint(lit ? 0xFFF6A93B : 0xFF8A6A4A));
    }
    // Golden fish tokens bob and spin.
    for (var i = 0; i < FishingCave.tokens.length; i++) {
      if (cave.collected.contains(i)) continue;
      final p = FishingCave.tokens[i] + Offset(0, math.sin(t * 3 + i) * 4);
      final squash = math.cos(t * 2.5 + i).abs() * .7 + .3;
      c.drawCircle(p, 16, fillPaint(0x33FFD54F));
      c.save();
      c.translate(p.dx, p.dy);
      c.scale(squash, 1);
      c.drawOval(const Rect.fromLTWH(-11, -6, 20, 12), fillPaint(0xFFFFC83D));
      c.drawPath(
          Path()
            ..moveTo(8, 0)
            ..lineTo(15, -6)
            ..lineTo(15, 6)
            ..close(),
          fillPaint(0xFFFFC83D));
      c.drawOval(
          const Rect.fromLTWH(-11, -6, 20, 12), strokePaint(0xFFB7791F, 1.6));
      c.drawCircle(const Offset(-5, -1), 1.6, fillPaint(0xFF5A3A1A));
      c.restore();
    }
    // Chest sparkle at the finish.
    final glow = (math.sin(t * 3) + 1) / 2;
    c.drawCircle(const Offset(FishingCave.finishX + 60, FishingCave.floor - 30),
        50 + glow * 10, fillPaint(0x33FFE08A));
    c.restore();
  }

  @override
  bool shouldRepaint(_CavePainter old) => true;
}

/// Far wall scrolls at half speed; wide enough for any screen width.
const _backWidth = FishingCave.length * .5 + 1600;

void _paintBackWall(Canvas c) {
  const w = _backWidth, h = FishingCave.height;
  c.drawRect(
      const Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF241F2C),
              Color(0xFF3A3242),
              Color(0xFF2A2430)
            ]).createShader(const Rect.fromLTWH(0, 0, w, h)));
  for (var i = 0; i < 70; i++) {
    final x = artNoise(i, 1) * w;
    final r = 40 + artNoise(i, 2) * 90;
    c.drawOval(
        Rect.fromCenter(
            center: Offset(x, 120 + artNoise(i, 3) * 260),
            width: r * 2,
            height: r),
        fillPaint(0x1A8A7FA0));
  }
  // Distant glowing crystals.
  for (var i = 0; i < 46; i++) {
    final p = Offset(artNoise(i, 4) * w, 80 + artNoise(i, 5) * 260);
    final tone = [0x5582E0D0, 0x55B49AE0, 0x559FD3F0][i % 3];
    c.drawCircle(p, 18, fillPaint((tone & 0x00FFFFFF) | 0x18000000));
    c.drawPath(
        Path()
          ..moveTo(p.dx - 5, p.dy + 8)
          ..lineTo(p.dx, p.dy - 12)
          ..lineTo(p.dx + 5, p.dy + 8)
          ..close(),
        fillPaint(tone));
  }
}

void _paintLevel(Canvas c) {
  // Ceiling with stalactites.
  final ceiling = Path()..moveTo(0, 0);
  for (var x = 0.0; x <= FishingCave.length; x += 30) {
    final k = x.toInt();
    final drop = 30 + artNoise(k, 6) * 26 + (artNoise(k, 7) < .2 ? 50 : 0);
    ceiling.lineTo(x, drop);
    ceiling.lineTo(x + 15, 22 + artNoise(k, 8) * 14);
  }
  ceiling
    ..lineTo(FishingCave.length, 0)
    ..close();
  c.drawPath(ceiling, fillPaint(0xFF2C2530));
  c.drawPath(ceiling, strokePaint(0xFF15111A, 2.5));
  for (final l in FishingCave.ledges) {
    if (!l.crumble) _paintLedge(c, l);
  }
  // Low ceilings: heavy slabs hanging down to the head-bump line.
  for (final ceil in FishingCave.ceilings) {
    final slab = RRect.fromRectAndCorners(
        Rect.fromLTRB(ceil.left, 0, ceil.right, ceil.bottom),
        bottomLeft: const Radius.circular(22),
        bottomRight: const Radius.circular(22));
    c.drawRRect(slab, fillPaint(0xFF3A3140));
    c.save();
    c.clipRRect(slab);
    for (var y = 30.0; y < ceil.bottom; y += 34) {
      c.drawLine(Offset(ceil.left, y), Offset(ceil.right, y - 6),
          strokePaint(0x33000000, 2));
    }
    c.drawRect(
        Rect.fromLTRB(ceil.left, ceil.bottom - 10, ceil.right, ceil.bottom),
        fillPaint(0xFF54485E));
    c.restore();
    c.drawRRect(slab, strokePaint(0xFF15111A, 3));
    // Little drips under the slab warn the cat to keep low.
    for (var x = ceil.left + 24; x < ceil.right - 10; x += 38) {
      c.drawPath(
          Path()
            ..moveTo(x - 7, ceil.bottom - 2)
            ..lineTo(x, ceil.bottom + 12)
            ..lineTo(x + 7, ceil.bottom - 2)
            ..close(),
          fillPaint(0xFF3A3140));
    }
  }
  _paintLevelRest(c);
}

/// Chunky outlined rock ledge with a mossy top; crumbling ones are paler
/// and cracked.
void _paintLedge(Canvas c, CaveLedge l) {
  const h = FishingCave.height;
  {
    final bottom = l.ground ? h : l.top + 46;
    final body = RRect.fromRectAndCorners(
        Rect.fromLTRB(l.left, l.top, l.right, bottom),
        topLeft: const Radius.circular(10),
        topRight: const Radius.circular(10),
        bottomLeft: Radius.circular(l.ground ? 0 : 18),
        bottomRight: Radius.circular(l.ground ? 0 : 18));
    c.drawRRect(body, fillPaint(l.crumble ? 0xFF7A6A62 : 0xFF5E5466));
    c.save();
    c.clipRRect(body);
    for (var y = l.top + 18; y < bottom; y += 22) {
      c.drawLine(Offset(l.left, y), Offset(l.right, y + 4),
          strokePaint(0x332A2430, 2));
    }
    c.drawRect(Rect.fromLTRB(l.left, l.top, l.right, l.top + 8),
        fillPaint(l.crumble ? 0xFFA8957F : 0xFF8C7FA0));
    if (l.crumble) {
      final m = (l.left + l.right) / 2;
      c.drawPath(
          Path()
            ..moveTo(m - 8, l.top)
            ..lineTo(m + 4, l.top + 14)
            ..lineTo(m - 6, l.top + 26)
            ..lineTo(m + 6, bottom),
          strokePaint(0xFF2A2024, 2.4));
      c.drawLine(Offset(l.left + 14, l.top + 4),
          Offset(l.left + 24, l.top + 20), strokePaint(0xFF2A2024, 1.8));
    }
    c.restore();
    c.drawRRect(body, strokePaint(0xFF1E1A24, 3));
    if (l.crumble) return;
    for (var x = l.left + 10; x < l.right - 10; x += 26) {
      c.drawOval(
          Rect.fromCenter(center: Offset(x, l.top + 1), width: 20, height: 7),
          fillPaint(artNoise(x.toInt(), 9) < .5 ? 0xFF6F9A5A : 0xFF5E8A4E));
    }
  }
}

void _paintLevelRest(Canvas c) {
  const h = FishingCave.height;
  // Pits glow faintly from below.
  for (var i = 0; i + 1 < FishingCave.ledges.length; i++) {
    final a = FishingCave.ledges[i];
    if (!a.ground) continue;
    final next = FishingCave.ledges
        .skip(i + 1)
        .firstWhere((l) => l.ground, orElse: () => a);
    if (identical(next, a)) continue;
    c.drawRect(
        Rect.fromLTRB(a.right, h - 40, next.left, h),
        Paint()
          ..shader = const LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Color(0x553A8FA8), Color(0x003A8FA8)])
              .createShader(Rect.fromLTRB(a.right, h - 40, next.left, h)));
  }
  // Crystal spikes.
  for (final (x, half) in FishingCave.spikes) {
    for (var i = 0; i < 4; i++) {
      final bx = x - half + i * half * 2 / 3;
      final tall = 22 + (i.isEven ? 8 : 0);
      final spike = Path()
        ..moveTo(bx - 7, FishingCave.floor)
        ..lineTo(bx, FishingCave.floor - tall)
        ..lineTo(bx + 7, FishingCave.floor)
        ..close();
      c.drawPath(spike, fillPaint(0xFFB49AE0));
      c.drawPath(spike, strokePaint(0xFF4A3A6A, 1.6));
      c.drawLine(
          Offset(bx - 2, FishingCave.floor - 4),
          Offset(bx, FishingCave.floor - tall + 6),
          strokePaint(0xAAFFFFFF, 1.4));
    }
  }
  // Torch posts.
  for (final x in FishingCave.checkpoints.skip(1)) {
    c.drawLine(Offset(x + 10, FishingCave.floor),
        Offset(x + 10, FishingCave.floor - 56), strokePaint(0xFF6B4A2C, 5));
  }
  // Boulders and a big treasure chest at the end.
  for (final (x, r) in const [
    (150.0, 20.0),
    (1300.0, 16.0),
    (2650.0, 22.0),
    (4200.0, 18.0),
    (6640.0, 20.0)
  ]) {
    paintBoulder(c, Offset(x, FishingCave.floor + 2), r, x.toInt(),
        inWater: false);
  }
  const chest = Offset(FishingCave.finishX + 60, FishingCave.floor);
  c.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: chest + const Offset(0, -22), width: 74, height: 44),
          const Radius.circular(6)),
      fillPaint(0xFF8A5A33));
  c.drawPath(
      Path()
        ..moveTo(chest.dx - 37, chest.dy - 40)
        ..quadraticBezierTo(
            chest.dx, chest.dy - 70, chest.dx + 37, chest.dy - 40)
        ..close(),
      fillPaint(0xFFA8703F));
  c.drawLine(chest + const Offset(-37, -30), chest + const Offset(37, -30),
      strokePaint(0xFFD9A441, 4));
  c.drawCircle(chest + const Offset(0, -26), 5, fillPaint(0xFFF2C75C));
  c.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: chest + const Offset(0, -22), width: 74, height: 44),
          const Radius.circular(6)),
      strokePaint(0xFF3E2618, 2.5));
}
