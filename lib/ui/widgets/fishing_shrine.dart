import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:material_ui/material_ui.dart';
import '../../collection/fish_collection.dart';
import '../../collection/fish_species.dart';
import '../../fishing/fishing_river.dart';
import '../../fishing/fishing_shrine.dart';
import '../design.dart';
import 'fishing_art_kit.dart';
import 'fishing_fish_art.dart';
import 'fishing_legendary_art.dart';
import 'game_surfaces.dart';

class FishingShrineView extends StatefulWidget {
  const FishingShrineView(
      {super.key, required this.round, required this.frames});
  final FishingRiverRound round;
  final Listenable frames;
  @override
  State<FishingShrineView> createState() => _ShrineViewState();
}

class _ShrineViewState extends State<FishingShrineView> {
  static ui.Picture _record(void Function(Canvas) draw) {
    final recorder = ui.PictureRecorder();
    draw(Canvas(recorder));
    return recorder.endRecording();
  }

  late final ui.Picture _picture = _record(_stoneShrine);
  // Coloured statues, recorded once and only drawn once their fish is offered.
  late final List<ui.Picture> _lit = [
    for (var i = 0; i < shrineStatues.length; i++)
      _record((c) => _statue(c, i, locked: false))
  ];
  @override
  void dispose() {
    _picture.dispose();
    for (final p in _lit) {
      p.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
      child: CustomPaint(
          painter: _ShrinePainter(
              widget.round, widget.frames, _picture, _lit)));
}

/// Statue spots in shrine-local space, in [FishSpecies.legendary] order:
/// Nessie on the left facing in, the sea dragon guarding the gate, the
/// moonfish on the right.
const shrineStatues = [
  (at: Offset(-150, -64), scale: 1.15, flip: true),
  (at: Offset(0, -84), scale: 1.25, flip: false),
  (at: Offset(150, -64), scale: 1.15, flip: false),
];

void _statue(Canvas c, int i, {required bool locked}) {
  final s = shrineStatues[i];
  c.save();
  c.translate(s.at.dx, s.at.dy);
  c.scale(s.flip ? -s.scale : s.scale, s.scale);
  paintLegendaryFish(c, FishSpecies.legendary[i], locked: locked);
  c.restore();
}

// Glow shaders live in shrine-local space, so they are built once and only
// their opacity changes per frame.
final List<Paint> _statueGlow = [
  for (final s in shrineStatues)
    Paint()
      ..blendMode = BlendMode.plus
      ..shader = ui.Gradient.radial(s.at, 105 * s.scale, const [
        Color(0x88FFF3B0),
        Color(0x3380FFF2),
        Color(0x0080FFF2)
      ], const [
        0,
        .45,
        1
      ])
];
final Paint _beamPaint = Paint()
  ..blendMode = BlendMode.plus
  ..shader = ui.Gradient.linear(const Offset(0, -440), const Offset(0, -150),
      const [Color(0x00FFF6C8), Color(0x99FFF6C8), Color(0x5580FFF2)],
      const [0, .55, 1]);

class _ShrinePainter extends CustomPainter {
  _ShrinePainter(this.round, Listenable frames, this.picture, this.lit)
      : super(repaint: frames);
  final FishingRiverRound round;
  final ui.Picture picture;
  final List<ui.Picture> lit;
  @override
  void paint(Canvas c, Size size) {
    final p = round.toScreen(FishingShrine.center);
    if (!(Offset.zero & size).inflate(460 * round.scale).contains(p)) return;
    c.save();
    c.clipRect(Offset.zero & size);
    c.translate(p.dx, p.dy);
    c.scale(round.scale);
    final n = FishCollection.instance.shrineOfferings;
    final t = round.clock;
    final complete = n == FishingShrine.requiredFish;
    if (complete) {
      // The awakened shrine sends a pillar of light up to the cave roof.
      final w = 70 + math.sin(t * 1.6) * 8;
      c.drawPath(
          Path()
            ..moveTo(-w * .5, -170)
            ..lineTo(-w, -440)
            ..lineTo(w, -440)
            ..lineTo(w * .5, -170)
            ..close(),
          _beamPaint);
    }
    c.drawPicture(picture);
    for (var i = 0; i < FishSpecies.legendary.length; i++) {
      if (!FishCollection.instance
          .hasShrineOffering(FishSpecies.legendary[i])) {
        continue;
      }
      final s = shrineStatues[i];
      final pulse = .5 + .5 * math.sin(t * 2.4 + i * 2.1);
      final glow = _statueGlow[i]
        ..color = Color.fromRGBO(255, 255, 255, .7 + .3 * pulse);
      c.drawCircle(s.at, 105 * s.scale, glow);
      // Slowly turning sun rays behind the statue.
      final ray = Paint()
        ..blendMode = BlendMode.plus
        ..color = Color.fromRGBO(255, 240, 170, .12 + .1 * pulse)
        ..strokeWidth = 5 * s.scale
        ..strokeCap = StrokeCap.round;
      for (var k = 0; k < 10; k++) {
        final a = t * .35 * (i.isEven ? 1 : -1) + k * math.pi / 5;
        final d = Offset(math.cos(a), math.sin(a));
        c.drawLine(s.at + d * 44 * s.scale,
            s.at + d * (66 + 8 * pulse) * s.scale, ray);
      }
      c.drawPicture(lit[i]);
      // Sparkles drifting up from the statue.
      for (var k = 0; k < 7; k++) {
        final life = (t * .45 + k / 7) % 1;
        final x = s.at.dx + math.sin(k * 2.7 + t) * 46 * s.scale;
        final y = s.at.dy + (30 - life * 90) * s.scale;
        final r = (1 - life) * 3.2 * s.scale;
        c.drawCircle(Offset(x, y), r,
            fillPaint(Color.fromRGBO(255, 250, 220, 1 - life).toARGB32()));
      }
    }
    if (complete) {
      // Threads of light join the three statues to the arch's heart.
      const heart = Offset(0, -158);
      final thread = strokePaint(0xAAFFF3B0, 2.5)..blendMode = BlendMode.plus;
      for (final s in shrineStatues) {
        c.drawLine(s.at, heart, thread);
        final f = (t * .6) % 1;
        c.drawCircle(Offset.lerp(s.at, heart, f)!, 4, fillPaint(0xFFFFFDE8));
      }
      c.drawCircle(heart, 16 + math.sin(t * 3) * 3, fillPaint(0xCCFFF6C8));
      c.drawCircle(heart, 30 + math.sin(t * 2) * 4, strokePaint(0x99B8FFF0, 2));
      for (var k = 0; k < 8; k++) {
        final a = t * .5 + k * math.pi / 4;
        c.drawCircle(heart + Offset(math.cos(a), math.sin(a)) * 40, 2.4,
            fillPaint(0xFFE4FFF4));
      }
    }
    c.restore();
  }

  @override
  bool shouldRepaint(_ShrinePainter old) =>
      old.round != round || old.picture != picture || old.lit != lit;
}

// Static stonework (and the stone statues) is recorded once; only the lit
// statues, their glow and the completed beam animate.
void _stoneShrine(Canvas c) {
  c.drawOval(const Rect.fromLTRB(-212, -14, 212, 86), fillPaint(0x44334852));
  final island = Path()
    ..moveTo(-208, 30)
    ..lineTo(-190, -22)
    ..lineTo(-140, -44)
    ..lineTo(-70, -54)
    ..lineTo(70, -54)
    ..lineTo(146, -42)
    ..lineTo(196, -18)
    ..lineTo(210, 28)
    ..lineTo(170, 62)
    ..lineTo(60, 74)
    ..lineTo(-90, 68)
    ..lineTo(-170, 58)
    ..close();
  c.drawPath(island, fillPaint(0xFF687C88));
  c.drawPath(island, strokePaint(0xFF364B59, 3));
  c.drawOval(const Rect.fromLTRB(-196, 0, 196, 80), strokePaint(0x77C6F5EF, 2));
  for (var i = 0; i < 3; i++) {
    final r =
        Rect.fromLTRB(-66 + i * 8.0, 12 - i * 9.0, 66 - i * 8.0, 32 - i * 9.0);
    c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(3)),
        fillPaint(0xFFA4B7BA));
    c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(3)),
        strokePaint(0xFF4C6670, 2));
  }
  // Twin weathered pillars with a carved arch.
  for (final x in [-44.0, 44.0]) {
    c.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(x - 13, -131, 26, 135), const Radius.circular(5)),
        fillPaint(0xFF8EA8AD));
    c.drawRect(Rect.fromLTWH(x - 8, -125, 6, 121), fillPaint(0xFFBCD0C9));
    for (var y = -110.0; y < -10; y += 25) {
      c.drawLine(
          Offset(x - 12, y), Offset(x + 12, y), strokePaint(0xFF597984, 1.5));
    }
    c.drawRect(Rect.fromLTWH(x - 18, -138, 36, 12), fillPaint(0xFFA8BDB6));
    c.drawOval(
        Rect.fromCenter(center: Offset(x + 9, -7), width: 32, height: 10),
        fillPaint(0xFF5D8B72));
  }
  final arch = Path()
    ..moveTo(-72, -136)
    ..lineTo(-54, -158)
    ..lineTo(-18, -166)
    ..lineTo(0, -180)
    ..lineTo(18, -166)
    ..lineTo(54, -158)
    ..lineTo(72, -136)
    ..close();
  c.drawPath(arch, fillPaint(0xFFAAC2BC));
  c.drawPath(arch, strokePaint(0xFF415F6B, 3));
  // Low plinth for the sea dragon on the top step, framed by the gate.
  _pedestal(c, const Rect.fromLTRB(-40, -46, 40, -8));
  // Side pedestals with carved wave bands.
  for (final x in [-150.0, 150.0]) {
    _pedestal(c, Rect.fromLTRB(x - 44, -26, x + 44, 30));
    for (var k = 0; k < 4; k++) {
      c.drawArc(
          Rect.fromCenter(
              center: Offset(x - 27 + k * 18.0, 8), width: 16, height: 10),
          math.pi,
          math.pi,
          false,
          strokePaint(0xFF4C6670, 1.6));
    }
  }
  for (var i = 0; i < shrineStatues.length; i++) {
    _statue(c, i, locked: true);
  }
  // Coral and shell fragments at the foot of the rocks.
  for (final x in [-196.0, 186.0]) {
    c.drawLine(Offset(x, 34), Offset(x, 10), strokePaint(0xFFCC8C90, 5));
    c.drawLine(Offset(x, 24), Offset(x - 9, 15), strokePaint(0xFFCC8C90, 4));
    c.drawLine(Offset(x, 29), Offset(x + 9, 18), strokePaint(0xFFCC8C90, 4));
  }
}

void _pedestal(Canvas c, Rect r) {
  final cap = Rect.fromLTRB(r.left - 6, r.top, r.right + 6, r.top + 9);
  final foot = Rect.fromLTRB(r.left - 4, r.bottom - 8, r.right + 4, r.bottom);
  c.drawRect(r, fillPaint(0xFF8EA8AD));
  c.drawRect(Rect.fromLTRB(r.left + 5, r.top + 9, r.left + 12, r.bottom - 8),
      fillPaint(0xFFBCD0C9));
  for (final b in [cap, foot]) {
    c.drawRRect(RRect.fromRectAndRadius(b, const Radius.circular(3)),
        fillPaint(0xFFA8BDB6));
    c.drawRRect(RRect.fromRectAndRadius(b, const Radius.circular(3)),
        strokePaint(0xFF415F6B, 2));
  }
  c.drawRect(Rect.fromLTRB(r.left, r.top + 9, r.right, r.bottom - 8),
      strokePaint(0xFF415F6B, 2));
}

class FishingShrineDialog extends StatefulWidget {
  const FishingShrineDialog({super.key});
  @override
  State<FishingShrineDialog> createState() => _ShrineDialogState();
}

class _ShrineDialogState extends State<FishingShrineDialog> {
  bool _busy = false;
  String? _error;
  Future<void> _offer(FishSpecies fish) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final ok = await FishCollection.instance.offerToShrine(fish);
      if (mounted && !ok) {
        setState(() => _error = 'Chưa dâng được cá, hãy thử lại.');
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'Chưa lưu được, hãy thử lại.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final collection = FishCollection.instance;
    final n = collection.shrineOfferings;
    final complete = n == FishingShrine.requiredFish;
    const fish = FishSpecies.legendary;
    return GameDialog(
        maxWidth: 420,
        child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
          GameDialogHeader(
              title: 'Đền hiến tế Hang biển',
              onClose: _busy ? () {} : () => Navigator.pop(context)),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            for (var i = 0; i < FishingShrine.requiredFish; i++)
              Container(
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  width: 104,
                  height: 72,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                      color: collection.hasShrineOffering(fish[i])
                          ? const Color(0xFFB4E8D5)
                          : DS.surfaceMuted,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: collection.hasShrineOffering(fish[i])
                              ? DS.success
                              : DS.borderMedium,
                          width: 2)),
                  child: CustomPaint(
                      painter: FishingFishArt(fish[i],
                          locked: !collection.hasShrineOffering(fish[i])))),
          ]),
          const SizedBox(height: 12),
          Text(
              complete ? 'NGHI LỄ HOÀN THÀNH' : 'Đã dâng $n/3 loài huyền thoại',
              style: DS.title,
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(
              complete
                  ? 'Ba tượng thần đã thức tỉnh. Đền Hang biển tỏa sáng!'
                  : 'Dâng mỗi loài 1 con để thắp sáng tượng của nó. Cá được lấy từ giỏ.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: DS.ink)),
          if (!complete) ...[
            const SizedBox(height: 12),
            for (final f in fish)
              Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(children: [
                    Expanded(
                        child: Text('${f.label} · ${f.habitat}',
                            style: const TextStyle(color: DS.ink))),
                    ElevatedButton(
                        style: DS.primary,
                        onPressed: _busy ||
                                collection.hasShrineOffering(f) ||
                                collection.stockOf(f) == 0
                            ? null
                            : () => _offer(f),
                        child: Text(collection.hasShrineOffering(f)
                            ? 'Đã dâng'
                            : 'Dâng 1 · Còn ${collection.stockOf(f)}')),
                  ])),
          ],
          if (_error != null)
            Text(_error!, style: const TextStyle(color: DS.danger)),
        ])));
  }
}
