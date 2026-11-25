import '../../collection/fish_species.dart';
import 'dart:ui' as ui;
import 'package:material_ui/material_ui.dart';
import '../../collection/fish_collection.dart';
import '../../camp/camp_state.dart';
import '../../fishing/fishing_bait_house.dart';
import '../../fishing/fishing_river.dart';
import '../design.dart';
import 'fishing_art_kit.dart';
import 'fishing_fish_art.dart';
import 'fishing_tool_art.dart';
import 'game_surfaces.dart';
import 'fishing_dialog_kit.dart';

class FishingBaitHouseView extends StatefulWidget {
  const FishingBaitHouseView(
      {super.key, required this.round, required this.frames});
  final FishingRiverRound round;
  final Listenable frames;
  @override
  State<FishingBaitHouseView> createState() => _BaitHouseViewState();
}

class _BaitHouseViewState extends State<FishingBaitHouseView> {
  late final ui.Picture _picture = () {
    final r = ui.PictureRecorder();
    _paintHouse(Canvas(r));
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
          painter: _HousePainter(widget.round, widget.frames, _picture)));
}

class _HousePainter extends CustomPainter {
  _HousePainter(this.round, Listenable frames, this.picture)
      : super(repaint: frames);
  final FishingRiverRound round;
  final ui.Picture picture;
  @override
  void paint(Canvas c, Size size) {
    final p = round.toScreen(FishingBaitHouse.center);
    if (!(Offset.zero & size).inflate(220 * round.scale).contains(p)) return;
    c.save();
    c.clipRect(Offset.zero & size);
    c.translate(p.dx, p.dy);
    c.scale(round.scale);
    c.drawPicture(picture);
    c.restore();
  }

  @override
  bool shouldRepaint(_HousePainter old) =>
      old.round != round || old.picture != picture;
}

// Static stilt house is recorded once above water; no geometry rebuilds on ticks.
void _paintHouse(Canvas c) {
  c.drawOval(const Rect.fromLTRB(-94, -2, 94, 58), fillPaint(0x44304437));
  for (final x in [-64.0, 64.0]) {
    c.drawLine(Offset(x, -18), Offset(x, 42), strokePaint(0xFF664827, 9));
    c.drawLine(
        Offset(x - 1, -18), Offset(x - 1, 40), strokePaint(0xFF9A7443, 3));
  }
  final deck = RRect.fromRectAndRadius(
      const Rect.fromLTRB(-86, -18, 86, 18), const Radius.circular(5));
  c.drawRRect(deck, fillPaint(0xFFD1AC6F));
  c.drawRRect(deck, strokePaint(0xFF5E472C, 3));
  for (var y = -10.0; y < 18; y += 7) {
    c.drawLine(Offset(-82, y), Offset(82, y), strokePaint(0x66795530, 1.2));
  }
  c.drawRect(const Rect.fromLTRB(-22, 18, 22, 52), fillPaint(0xFFBE965D));
  for (var y = 24.0; y < 52; y += 7) {
    c.drawLine(Offset(-22, y), Offset(22, y), strokePaint(0xFF8D6A3E, 1.5));
  }
  c.drawRect(const Rect.fromLTRB(-68, -102, 68, -18), fillPaint(0xFFC6985F));
  for (var x = -61.0; x < 68; x += 12) {
    c.drawLine(Offset(x, -100), Offset(x, -19), strokePaint(0x55744F2C, 1.2));
  }
  c.drawRect(
      const Rect.fromLTRB(-68, -102, 68, -18), strokePaint(0xFF5E472C, 2.5));
  c.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTRB(-38, -76, 38, -31), const Radius.circular(7)),
      fillPaint(0xFF3D5747));
  c.drawRect(const Rect.fromLTRB(-45, -35, 45, -23), fillPaint(0xFF895E38));
  // Bác cò đứng sau quầy pha mồi.
  c.drawOval(const Rect.fromLTWH(14, -66, 17, 30), fillPaint(0xFFEDEDE0));
  c.drawPath(
      Path()
        ..moveTo(21, -55)
        ..quadraticBezierTo(33, -79, 17, -80),
      strokePaint(0xFFEDEDE0, 7));
  c.drawOval(const Rect.fromLTWH(9, -87, 19, 13), fillPaint(0xFFF5F4E9));
  c.drawPath(
      Path()
        ..moveTo(11, -81)
        ..lineTo(-7, -77)
        ..lineTo(12, -76)
        ..close(),
      fillPaint(0xFFDEA14D));
  c.drawCircle(const Offset(15, -82), 1.5, fillPaint(0xFF304B46));
  // Cối giã mồi, chày gỗ và các lọ mồi.
  c.drawOval(const Rect.fromLTWH(-16, -48, 30, 20), fillPaint(0xFF879597));
  c.drawOval(const Rect.fromLTWH(-16, -48, 30, 7), fillPaint(0xFF4B5E61));
  c.drawLine(
      const Offset(0, -44), const Offset(9, -66), strokePaint(0xFFCCA875, 6));
  for (final x in [-32.0, 21.0]) {
    c.save();
    c.translate(x, -53);
    c.scale(.2);
    paintLegendaryBaitJar(c);
    c.restore();
  }
  final roof = Path()
    ..moveTo(-92, -96)
    ..lineTo(-48, -148)
    ..lineTo(0, -160)
    ..lineTo(48, -148)
    ..lineTo(92, -96)
    ..close();
  c.drawPath(roof, fillPaint(0xFF69864D));
  c.save();
  c.clipPath(roof);
  for (var x = -90.0; x < 95; x += 9) {
    c.drawLine(Offset(x, -150), Offset(x - 9, -96), strokePaint(0xFF9EB66C, 3));
  }
  for (final y in [-112.0, -130.0]) {
    c.drawLine(Offset(-85, y), Offset(85, y), strokePaint(0x5570482B, 2));
  }
  c.restore();
  c.drawPath(roof, strokePaint(0xFF435633, 3));
  // Sign with the same jar as the fishing toggle.
  c.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTRB(-20, -116, 20, -80), const Radius.circular(5)),
      fillPaint(0xFFF4E4BC));
  c.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTRB(-20, -116, 20, -80), const Radius.circular(5)),
      strokePaint(0xFF775533, 2));
  c.save();
  c.translate(-18, -116);
  c.scale(.36);
  paintLegendaryBaitJar(c);
  c.restore();
  // Hanging baskets, landing rope, and a warm lantern.
  for (final x in [-55.0, 55.0]) {
    c.drawLine(Offset(x, -92), Offset(x, -70), strokePaint(0xFF684A2B, 1.5));
    c.drawOval(Rect.fromCenter(center: Offset(x, -63), width: 19, height: 18),
        fillPaint(0xFFD6AF6B));
    for (var y = -67.0; y < -56; y += 4) {
      c.drawLine(
          Offset(x - 8, y), Offset(x + 8, y), strokePaint(0xFF967042, 1));
    }
  }
  c.drawLine(
      const Offset(77, -95), const Offset(77, -71), strokePaint(0xFF684A2B, 2));
  c.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(70, -72, 14, 19), const Radius.circular(4)),
      fillPaint(0xFFFAC66D));
  c.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(70, -72, 14, 19), const Radius.circular(4)),
      strokePaint(0xFF684A2B, 2));
  c.drawOval(const Rect.fromLTWH(51, 1, 24, 9), strokePaint(0xFF967042, 3));
}

class FishingBaitHouseDialog extends StatefulWidget {
  const FishingBaitHouseDialog({super.key});
  @override
  State<FishingBaitHouseDialog> createState() => _BaitHouseDialogState();
}

class _BaitHouseDialogState extends State<FishingBaitHouseDialog> {
  bool _busy = false;
  String? _note;
  Future<void> _exchange({bool withCoins = false}) async {
    setState(() => _busy = true);
    try {
      final ok = withCoins
          ? await CampState.instance.buyLegendaryBait()
          : await FishCollection.instance.exchangeLegendaryBait();
      if (mounted) {
        setState(() => _note = ok
            ? 'Đã nhận 1 mồi huyền thoại!'
            : 'Chưa đổi được mồi, hãy thử lại.');
      }
    } catch (_) {
      if (mounted) setState(() => _note = 'Chưa lưu được, hãy thử lại.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  static const _wood = Color(0xFF8A5A33), _gold = Color(0xFFE2A93B);

  @override
  Widget build(BuildContext context) {
    final collection = FishCollection.instance;
    final common = collection.basket.where((f) => f.rarity == 'Phổ biến');
    final fishHave = collection.commonFishStock;
    final coins = CampState.instance.coins;
    const cost = FishCollection.baitCost, price = CampState.legendaryBaitPrice;
    return GameDialog(
        maxWidth: 620,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
        child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
          FishingDialogHeader(
              icon: Icons.science_rounded,
              title: 'Nhà pha mồi',
              trailing: const FishingCoinPill(),
              onClose: () => Navigator.pop(context)),
          const SizedBox(height: 8),
          IntrinsicHeight(
              child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                _showcase(collection.legendaryBait),
                const SizedBox(width: 10),
                Expanded(
                    child: _offer(
                        title: 'Đổi cá',
                        price: const SizedBox(
                            width: 50,
                            height: 34,
                            child: CustomPaint(
                                painter: FishingFishArt(FishSpecies.perch))),
                        cost: '$cost cá phổ biến',
                        have: 'Đang có $fishHave cá',
                        enough: fishHave >= cost,
                        button: 'ĐỔI 5 CÁ LẤY 1 MỒI',
                        onPressed: () => _exchange())),
                const SizedBox(width: 10),
                Expanded(
                    child: _offer(
                        title: 'Mua bằng xu',
                        price: const Icon(Icons.monetization_on_rounded,
                            color: _gold, size: 40),
                        cost: '$price xu',
                        have: 'Đang có $coins xu',
                        enough: coins >= price,
                        button: 'MUA 1 MỒI · $price XU',
                        onPressed: () => _exchange(withCoins: true))),
              ])),
          const SizedBox(height: 10),
          _basket(common.toList(), collection),
          if (_note != null)
            Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_note!,
                    style: TextStyle(
                        color: _note!.startsWith('Đã') ? DS.success : DS.danger,
                        fontWeight: FontWeight.w800))),
        ])));
  }

  /// Glowing jar of legendary bait with the player's stock and its effect.
  Widget _showcase(int bait) => Container(
      width: 150,
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF2B4256), Color(0xFF1B2B3A)]),
          border: Border.all(color: _gold, width: 2)),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Stack(alignment: Alignment.center, children: [
          Container(
              width: 84,
              height: 84,
              decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    Color(0x99FFE08A),
                    Color(0x00FFE08A),
                  ]))),
          const SizedBox(
              width: 62,
              height: 62,
              child: CustomPaint(
                  painter:
                      FishingToolArt(tool: FishingTool.bait, active: true))),
        ]),
        Text('×$bait',
            style: const TextStyle(
                color: Color(0xFFFFE08A),
                fontSize: 26,
                height: 1.1,
                fontWeight: FontWeight.w900)),
        const Text('Mồi huyền thoại',
            style: TextStyle(
                color: Color(0xFFF4FFFB),
                fontSize: 12,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
                color: const Color(0x33FFE08A),
                borderRadius: BorderRadius.circular(10)),
            child: const Text('Cá huyền thoại ×6',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Color(0xFFFFE08A),
                    fontSize: 11,
                    fontWeight: FontWeight.w800))),
        const SizedBox(height: 4),
        const Text('1 mồi cho 1 lần câu',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF9FC3C8), fontSize: 10.5)),
      ]));

  /// One way to get bait: price, what the player has, and the button.
  Widget _offer(
          {required String title,
          required Widget price,
          required String cost,
          required String have,
          required bool enough,
          required String button,
          required VoidCallback onPressed}) =>
      Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .75),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: enough ? _gold : const Color(0xFFD9CDB8), width: 2)),
          child: Column(children: [
            Text(title,
                style: const TextStyle(
                    color: _wood,
                    fontSize: 12,
                    letterSpacing: .6,
                    fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            FittedBox(
                child:
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              price,
              const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.arrow_forward_rounded,
                      color: _wood, size: 22)),
              const SizedBox(
                  width: 44,
                  height: 44,
                  child: CustomPaint(
                      painter: FishingToolArt(
                          tool: FishingTool.bait, active: true))),
            ])),
            const Spacer(),
            Text(cost,
                style: const TextStyle(
                    color: DS.ink,
                    fontSize: DS.fontButton,
                    fontWeight: FontWeight.w900)),
            Text(have,
                style: TextStyle(
                    color: enough ? DS.success : DS.danger,
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
            const Spacer(),
            SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                    style: DS.primary,
                    onPressed: _busy || !enough ? null : onPressed,
                    child:
                        FittedBox(child: Text(_busy ? 'Đang đổi…' : button)))),
          ]));

  /// Common fish in the basket that can be traded.
  Widget _basket(List<FishSpecies> common, FishCollection collection) =>
      Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
          decoration: BoxDecoration(
              color: const Color(0xFFF3E6CC),
              borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            const Icon(Icons.shopping_basket_rounded, color: _wood, size: 20),
            const SizedBox(width: 8),
            if (common.isEmpty)
              const Expanded(
                  child: Text('Giỏ chưa có cá phổ biến · Câu ở Làng là dễ nhất',
                      style: TextStyle(color: _wood, fontSize: 12)))
            else
              Expanded(
                  child: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Wrap(spacing: 12, runSpacing: 8, children: [
                        for (final fish in common)
                          FishingFishTile(
                              fish: fish,
                              count: collection.stockOf(fish),
                              width: 50,
                              height: 38),
                      ]))),
          ]));
}
