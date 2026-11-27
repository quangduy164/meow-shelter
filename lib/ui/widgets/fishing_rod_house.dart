import 'package:material_ui/material_ui.dart';
import '../../fishing/fishing_controller.dart';
import '../../fishing/fishing_rod.dart';
import '../../camp/camp_state.dart';
import '../design.dart';
import 'fishing_art_kit.dart';
import 'fishing_rod_art.dart';
import 'game_surfaces.dart';
import 'fishing_dialog_kit.dart';
import '../../audio/game_audio.dart';

/// Static village workshop, recorded into the river landscape chunks.
void paintFishingRodHouse(Canvas c) {
  final base = FishingRodHouse.base;
  c.save();
  c.translate(base.dx, base.dy);
  c.drawOval(const Rect.fromLTWH(-102, -6, 204, 25), fillPaint(0x334E5037));
  c.drawRect(const Rect.fromLTRB(-70, -88, 70, -8), fillPaint(0xFFD4AB70));
  for (var x = -64.0; x < 70; x += 12) {
    c.drawLine(Offset(x, -86), Offset(x, -8), strokePaint(0x55704B28, 1.3));
  }
  c.drawRect(
      const Rect.fromLTRB(-70, -88, 70, -8), strokePaint(0xFF61452C, 2.5));
  c.drawRect(const Rect.fromLTRB(-74, -8, 74, 4), fillPaint(0xFFAAA292));
  c.drawRect(const Rect.fromLTRB(-28, -58, 28, -8), fillPaint(0xFF3E5546));
  c.drawRect(const Rect.fromLTRB(-34, -12, 34, -5), fillPaint(0xFF92683D));
  // Upright bamboo rods and a small reel hang by the open doorway.
  for (final x in [-53.0, 48.0, 61.0]) {
    c.drawLine(Offset(x, 0), Offset(x - 9, -77), strokePaint(0xFF657C41, 3.5));
    for (var y = -65.0; y < -5; y += 14) {
      c.drawLine(Offset(x - 10 - y / 10, y), Offset(x - 5 - y / 10, y),
          strokePaint(0xFFE7CD85, 2));
    }
  }
  c.drawCircle(const Offset(-52, -24), 8, fillPaint(0xFF4C6F68));
  c.drawCircle(const Offset(-52, -24), 5, strokePaint(0xFFDDBB76, 2));
  final roof = Path()
    ..moveTo(-93, -84)
    ..lineTo(-48, -135)
    ..lineTo(47, -135)
    ..lineTo(93, -84)
    ..close();
  c.drawPath(roof, fillPaint(0xFF597F50));
  for (var y = -128.0; y < -86; y += 10) {
    final t = (y + 135) / 51;
    c.drawLine(Offset(-48 - t * 45, y), Offset(47 + t * 46, y),
        strokePaint(0xFF83A167, 2));
  }
  c.drawPath(roof, strokePaint(0xFF3C5937, 3));
  final board = RRect.fromRectAndRadius(
      const Rect.fromLTRB(-28, -114, 28, -79), const Radius.circular(5));
  c.drawRRect(board, fillPaint(0xFFF4E4BC));
  c.drawRRect(board, strokePaint(0xFF795532, 2));
  c.save();
  c.translate(-22, -116);
  paintRodPreview(c, const Size(44, 40), FishingRod.bamboo);
  c.restore();
  // Small workbench and spool of line inside the workshop.
  c.drawRect(const Rect.fromLTWH(-20, -25, 40, 7), fillPaint(0xFFAF7A43));
  c.drawCircle(const Offset(8, -31), 7, fillPaint(0xFFE7D4A7));
  c.drawCircle(const Offset(8, -31), 3, fillPaint(0xFF8F744A));
  // A landing step and the lantern beside the door.
  c.drawRect(const Rect.fromLTRB(-28, 5, 28, 18), fillPaint(0xFFC29B61));
  c.drawLine(const Offset(-26, 11), const Offset(26, 11),
      strokePaint(0xFF8B683D, 1.5));
  c.drawLine(
      const Offset(33, -76), const Offset(33, -60), strokePaint(0xFF6D4C2D, 2));
  c.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(27, -61, 12, 16), const Radius.circular(3)),
      fillPaint(0xFFFFD17C));
  c.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(27, -61, 12, 16), const Radius.circular(3)),
      strokePaint(0xFF6D4C2D, 1.5));
  c.restore();
}

void paintRodPreview(Canvas c, Size size, FishingRod rod) {
  c.save();
  c.scale(size.width / 100, size.height / 100);
  final bamboo = rod == FishingRod.bamboo;
  final lantern = rod == FishingRod.lantern;
  const base = Offset(22, 86), control = Offset(43, 12), tip = Offset(77, 17);
  final along = (control - base) / (control - base).distance;
  final neck = bamboo ? base : base + along * 22;
  Offset point(double t) =>
      neck * ((1 - t) * (1 - t)) + control * (2 * (1 - t) * t) + tip * (t * t);
  Offset tangent(double t) => (control - neck) * (1 - t) + (tip - control) * t;
  final shaft = Path()
    ..moveTo(neck.dx, neck.dy)
    ..quadraticBezierTo(control.dx, control.dy, tip.dx, tip.dy);
  c.drawPath(
      shaft,
      strokePaint(
          bamboo
              ? 0xFF28663B
              : lantern
                  ? 0xFF5B2E22
                  : 0xFF4D5A37,
          5));
  c.drawPath(
      shaft,
      strokePaint(
          bamboo
              ? 0xFFA4D776
              : lantern
                  ? 0xFFD08A55
                  : 0xFF8FB8A2,
          2.5));
  if (bamboo) {
    for (final t in [.2, .4, .6, .8]) {
      final p = point(t);
      c.drawLine(p + const Offset(-3, -1), p + const Offset(3, 1),
          strokePaint(0xFF27683A, 2));
    }
  } else {
    final mount = base + along * 13;
    final reel = mount + Offset(-along.dy, along.dx) * 9;
    c.drawLine(mount, reel, strokePaint(0xFF3D6760, 3));
    c.drawCircle(reel, 8, fillPaint(0xFF3D6760));
    c.drawCircle(reel, 5, fillPaint(0xFFDCC38B));
  }
  if (bamboo) {
    for (final (t, side) in const [(.46, 1.0), (.73, -1.0)]) {
      final p = point(t);
      final direction = tangent(t);
      paintBambooLeaves(c, p, direction, scale: .62, side: side);
    }
    c.drawLine(
        const Offset(20, 94), const Offset(22, 86), strokePaint(0xFF387E42, 5));
  } else {
    c.drawLine(base - along * 4, neck, strokePaint(0xFF967148, 7));
  }
  c.drawPath(
      Path()
        ..moveTo(77, 17)
        ..quadraticBezierTo(89, 30, 80, 65),
      strokePaint(0xFF8D9F98, 1.2));
  c.drawOval(const Rect.fromLTWH(76, 63, 8, 15), fillPaint(0xFFF6E8C5));
  c.drawOval(const Rect.fromLTWH(76, 63, 8, 7), fillPaint(0xFFE27859));
  if (lantern) {
    for (final t in [.25, .5]) {
      final p = point(t);
      c.drawCircle(p, 2.6, fillPaint(0xFFD9A441));
    }
    paintRodLantern(c, const Offset(60, 17), scale: 1.25);
  }
  c.restore();
}

class _RodPreview extends CustomPainter {
  const _RodPreview(this.rod);
  final FishingRod rod;
  @override
  void paint(Canvas c, Size size) => paintRodPreview(c, size, rod);
  @override
  bool shouldRepaint(_RodPreview old) => old.rod != rod;
}

class FishingRodHouseDialog extends StatefulWidget {
  const FishingRodHouseDialog({super.key, required this.controller});
  final FishingController controller;
  @override
  State<FishingRodHouseDialog> createState() => _RodHouseDialogState();
}

class _RodHouseDialogState extends State<FishingRodHouseDialog> {
  bool _saving = false;
  String? _error;
  Future<void> _choose(FishingRod rod) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final ok = await widget.controller.selectRod(rod);
      if (!mounted) return;
      if (ok) {
        Navigator.pop(context);
      } else {
        setState(() => _error = 'Chưa lưu được cần câu, hãy thử lại.');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Chưa lưu được cần câu, hãy thử lại.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _buy(FishingRod rod) async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final ok = await CampState.instance.buyItem(rod.itemId, rod.price);
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      GameAudio.instance.play(GameSound.campBuy);
      await _choose(rod);
    } else {
      setState(() => _error = 'Chưa mua được cần, hãy thử lại.');
    }
  }

  @override
  Widget build(BuildContext context) => GameDialog(
      maxWidth: 560,
      child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        FishingDialogHeader(
            icon: Icons.phishing_rounded,
            title: 'Nhà đổi cần câu',
            trailing: const FishingCoinPill(),
            onClose: () => Navigator.pop(context)),
        const SizedBox(height: 12),
        IntrinsicHeight(
            child:
                Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          for (final rod in FishingRod.values) ...[
            if (rod != FishingRod.values.first) const SizedBox(width: 10),
            Expanded(child: _card(rod)),
          ]
        ])),
        if (_error != null)
          Text(_error!, style: const TextStyle(color: DS.danger)),
      ])));

  Widget _card(FishingRod rod) {
    final using = widget.controller.rod == rod;
    final locked = !rod.available;
    final owned = rod.owned;
    final afford = CampState.instance.coins >= rod.price;
    final VoidCallback? onTap = _saving || locked || using
        ? null
        : owned
            ? () => _choose(rod)
            : afford
                ? () => _buy(rod)
                : null;
    final status = using
        ? 'Đang dùng'
        : locked
            ? 'Mở khi tìm thấy đền Hang biển'
            : owned
                ? 'Chọn'
                : 'Mua · ${rod.price} xu';
    return Material(
        color: using
            ? DS.gold
            : locked
                ? const Color(0xFFEFE8DC)
                : DS.surfaceRaised,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
                color: locked ? const Color(0xFFD3C8B6) : DS.wood, width: 2)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
            onTap: onTap,
            child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  SizedBox(
                      height: 64,
                      width: 80,
                      child: Opacity(
                          opacity: locked ? .35 : 1,
                          child: CustomPaint(painter: _RodPreview(rod)))),
                  Text(rod.label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: DS.ink, fontWeight: FontWeight.w900)),
                  Text(rod.effect,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color:
                              rod.price > 0 ? const Color(0xFFB0662F) : DS.soft,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700)),
                  const Spacer(),
                  const SizedBox(height: 4),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    if (locked)
                      const Icon(Icons.lock_rounded,
                          size: 13, color: Color(0xFFA89D8B))
                    else if (!owned)
                      Icon(Icons.monetization_on_rounded,
                          size: 13, color: afford ? fishingGold : DS.danger),
                    if (locked || !owned) const SizedBox(width: 3),
                    Flexible(
                        child: Text(status,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: !owned && !locked && !afford
                                    ? DS.danger
                                    : locked
                                        ? const Color(0xFFA89D8B)
                                        : DS.ink,
                                fontSize: 12,
                                fontWeight: FontWeight.w800))),
                  ]),
                ]))));
  }
}
