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
  late final ui.Picture _picture = () {
    final recorder = ui.PictureRecorder();
    _stoneShrine(Canvas(recorder));
    return recorder.endRecording();
  }();
  @override
  void dispose() {
    _picture.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
      child: CustomPaint(
          painter: _ShrinePainter(widget.round, widget.frames, _picture)));
}

class _ShrinePainter extends CustomPainter {
  _ShrinePainter(this.round, Listenable frames, this.picture)
      : super(repaint: frames);
  final FishingRiverRound round;
  final ui.Picture picture;
  @override
  void paint(Canvas c, Size size) {
    final p = round.toScreen(FishingShrine.center);
    if (!(Offset.zero & size).inflate(220 * round.scale).contains(p)) return;
    c.save();
    c.clipRect(Offset.zero & size);
    c.translate(p.dx, p.dy);
    c.scale(round.scale);
    c.drawPicture(picture);
    final n = FishCollection.instance.shrineOfferings;
    for (var i = 0; i < FishSpecies.legendary.length; i++) {
      if (!FishCollection.instance
          .hasShrineOffering(FishSpecies.legendary[i])) {
        continue;
      }
      final flame = Offset((i - 1) * 68.0, i == 1 ? -92 : -42);
      final pulse = math.sin(round.clock * 5 + i) * 2;
      c.drawCircle(flame, 24 + pulse, fillPaint(0x3380FFF2));
      c.drawOval(Rect.fromCenter(center: flame, width: 14 + pulse, height: 24),
          fillPaint(0xFF51D8CD));
      c.drawOval(
          Rect.fromCenter(
              center: flame + const Offset(0, 3), width: 7, height: 14),
          fillPaint(0xFFEBFFF1));
    }
    if (n == FishingShrine.requiredFish) {
      c.drawCircle(const Offset(0, -132), 26 + math.sin(round.clock * 2) * 3,
          strokePaint(0x99B8FFF0, 2));
      for (var i = 0; i < 8; i++) {
        final a = round.clock * .3 + i * math.pi / 4;
        c.drawCircle(Offset(math.cos(a) * 32, -132 + math.sin(a) * 32), 2,
            fillPaint(0xFFE4FFF4));
      }
    }
    c.restore();
  }

  @override
  bool shouldRepaint(_ShrinePainter old) =>
      old.round != round || old.picture != picture;
}

// Static stonework is recorded once; only flames and the completed halo animate.
void _stoneShrine(Canvas c) {
  c.drawOval(const Rect.fromLTRB(-132, -8, 132, 80), fillPaint(0x44334852));
  final island = Path()
    ..moveTo(-128, 30)
    ..lineTo(-106, -30)
    ..lineTo(-70, -50)
    ..lineTo(70, -50)
    ..lineTo(113, -26)
    ..lineTo(130, 28)
    ..lineTo(104, 60)
    ..lineTo(38, 70)
    ..lineTo(-80, 62)
    ..close();
  c.drawPath(island, fillPaint(0xFF687C88));
  c.drawPath(island, strokePaint(0xFF364B59, 3));
  c.drawOval(const Rect.fromLTRB(-120, 2, 120, 76), strokePaint(0x77C6F5EF, 2));
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
  // Fish carving suspended in the arch.
  c.save();
  c.translate(-25, -164);
  c.scale(.5);
  const FishingFishArt(FishSpecies.catMew).paint(c, const Size(100, 64));
  c.restore();
  for (var i = 0; i < 3; i++) {
    final p = Offset((i - 1) * 68.0, i == 1 ? -76 : -26);
    c.drawRect(
        Rect.fromCenter(center: p + const Offset(0, 12), width: 12, height: 27),
        fillPaint(0xFF819DA3));
    c.drawOval(
        Rect.fromCenter(center: p + const Offset(0, 25), width: 30, height: 8),
        fillPaint(0xFF4C6670));
    c.drawArc(Rect.fromCenter(center: p, width: 34, height: 20), 0, math.pi,
        true, fillPaint(0xFF425D69));
    c.drawOval(Rect.fromCenter(center: p, width: 34, height: 8),
        fillPaint(0xFF799396));
  }
  // Coral and shell fragments at the foot of the rocks.
  for (final x in [-106.0, 98.0]) {
    c.drawLine(Offset(x, 30), Offset(x, 6), strokePaint(0xFFCC8C90, 5));
    c.drawLine(Offset(x, 20), Offset(x - 9, 11), strokePaint(0xFFCC8C90, 4));
    c.drawLine(Offset(x, 25), Offset(x + 9, 14), strokePaint(0xFFCC8C90, 4));
  }
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
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  width: 64,
                  height: 54,
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
                  ? 'Ba ngọn lửa đã thức tỉnh. Đền Hang biển tỏa sáng!'
                  : 'Dâng mỗi loài 1 con để thắp sáng đền. Cá được lấy từ giỏ.',
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
