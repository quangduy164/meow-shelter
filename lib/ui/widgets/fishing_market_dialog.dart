import 'package:material_ui/material_ui.dart';

import '../../collection/fish_collection.dart';
import '../../collection/fish_species.dart';
import '../../fishing/fishing_market.dart';
import '../design.dart';
import 'fishing_fish_art.dart';
import 'game_surfaces.dart';
import 'fishing_dialog_kit.dart';

/// The floating market's counter: tap a basket fish to sell one, or sell
/// everything at once. Today's wanted species sells for double.
class FishingMarketDialog extends StatefulWidget {
  const FishingMarketDialog({super.key});

  @override
  State<FishingMarketDialog> createState() => _FishingMarketDialogState();
}

class _FishingMarketDialogState extends State<FishingMarketDialog> {
  final _today = DateTime.now();
  bool _busy = false;
  String? _note;

  late final _wanted = FishingMarket.wantedOn(_today);
  List<FishSpecies> get _fish => FishCollection.instance.basket;

  Future<void> _sell(List<(FishSpecies, int)> lots) async {
    if (_busy) return;
    setState(() => _busy = true);
    var coins = 0, count = 0;
    for (final (fish, n) in lots) {
      final got = await FishingMarket.sell(fish, n, now: _today);
      if (got > 0) {
        coins += got;
        count += n;
      }
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _note = coins > 0
          ? 'Đã bán $count con · +$coins xu'
          : 'Chưa bán được, thử lại nhé';
    });
  }

  /// Legendary fish are kept back from "Bán hết": the shrine needs them.
  List<FishSpecies> get _sellAll => [
        for (final f in _fish)
          if (!f.isLegendary) f
      ];
  int get _sellAllCoins => _sellAll.fold(
      0,
      (sum, f) =>
          sum +
          FishingMarket.priceOf(f, _today) *
              FishCollection.instance.stockOf(f));

  static const _wood = Color(0xFF8A5A33);

  @override
  Widget build(BuildContext context) {
    final fish = [..._fish]..sort((a, b) => FishingMarket.priceOf(b, _today)
        .compareTo(FishingMarket.priceOf(a, _today)));
    final keep = fish.where((f) => f.isLegendary).length;
    return GameDialog(
      maxWidth: 660,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        FishingDialogHeader(
            icon: Icons.storefront_rounded,
            title: 'Chợ cá nổi',
            trailing: const FishingCoinPill(),
            onClose: () => Navigator.pop(context)),
        const SizedBox(height: 6),
        SizedBox(
            // Shrinks on short phones so "Bán hết" stays on screen.
            height:
                (MediaQuery.sizeOf(context).height - 196).clamp(110.0, 196.0),
            child:
                Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              _order(),
              const SizedBox(width: 10),
              Expanded(
                  child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .7),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2D3B5))),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              const Icon(Icons.shopping_basket_rounded,
                                  color: _wood, size: 18),
                              const SizedBox(width: 6),
                              const Text('Giỏ cá',
                                  style: TextStyle(
                                      color: _wood,
                                      fontWeight: FontWeight.w900)),
                              const Spacer(),
                              if (fish.isNotEmpty)
                                const Text('Chạm cá để bán 1 con',
                                    style: TextStyle(
                                        color: DS.soft, fontSize: 11.5)),
                            ]),
                            const SizedBox(height: 2),
                            if (fish.isEmpty)
                              const Expanded(
                                  child: Center(
                                      child: Text(
                                          'Giỏ trống rồi, đi câu thêm cá rồi quay lại nhé!',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(color: DS.soft))))
                            else
                              Expanded(
                                  child: SingleChildScrollView(
                                      padding:
                                          const EdgeInsets.fromLTRB(6, 8, 6, 4),
                                      child: Wrap(
                                          spacing: 10,
                                          runSpacing: 10,
                                          children: [
                                            for (final f in fish) _lot(f),
                                          ]))),
                          ]))),
            ])),
        const SizedBox(height: 10),
        Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
            decoration: BoxDecoration(
                color: const Color(0xFFF3E6CC),
                borderRadius: BorderRadius.circular(14)),
            child: Row(children: [
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(
                        _note ??
                            (fish.isEmpty
                                ? 'Chưa có cá để bán'
                                : 'Bán hết được $_sellAllCoins xu'),
                        style: TextStyle(
                            color: _note == null
                                ? DS.ink
                                : _note!.startsWith('Đã')
                                    ? DS.success
                                    : DS.danger,
                            fontWeight: FontWeight.w900)),
                    if (keep > 0)
                      const Row(children: [
                        Icon(Icons.shield_rounded,
                            size: 13, color: Color(0xFF6B5BB5)),
                        SizedBox(width: 3),
                        Flexible(
                            child: Text(
                                'Cá huyền thoại được giữ lại để hiến tế',
                                style: TextStyle(
                                    color: Color(0xFF6B5BB5),
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700))),
                      ]),
                  ])),
              ElevatedButton.icon(
                  style: DS.primary,
                  onPressed: _sellAll.isEmpty || _busy
                      ? null
                      : () => _sell([
                            for (final f in _sellAll)
                              (f, FishCollection.instance.stockOf(f))
                          ]),
                  icon: const Icon(Icons.sell_rounded, size: 18),
                  label: Text('BÁN HẾT · $_sellAllCoins XU')),
            ])),
      ])),
    );
  }

  /// One basket fish: tap sells one. Price in red for today's order.
  Widget _lot(FishSpecies f) {
    final price = FishingMarket.priceOf(f, _today);
    final left = FishCollection.instance.stockOf(f);
    final wanted = f == _wanted;
    return Semantics(
        button: true,
        label: 'Bán 1 ${f.label}, $price xu, còn $left',
        child: FishingFishTile(
            fish: f,
            count: left,
            wanted: wanted,
            shield: f.isLegendary,
            tooltip: '${f.label} · $price xu/con',
            onTap: _busy ? null : () => _sell([(f, 1)]),
            caption:
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.monetization_on_rounded,
                  size: 13, color: fishingGold),
              const SizedBox(width: 2),
              Text('$price',
                  style: TextStyle(
                      color: wanted ? const Color(0xFFC0503A) : DS.ink,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900)),
            ])));
  }

  /// Today's order board: the wanted fish, its doubled price and stock.
  Widget _order() {
    final have = FishCollection.instance.stockOf(_wanted);
    return Container(
        width: 150,
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: const Color(0xFF5E3A22),
            border: Border.all(color: const Color(0xFF3E2618), width: 2)),
        child: FittedBox(
            child: SizedBox(
                width: 126,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Text('ĐƠN HÀNG HÔM NAY',
                      style: TextStyle(
                          color: Color(0xFFFFE08A),
                          fontSize: 11,
                          letterSpacing: .6,
                          fontWeight: FontWeight.w900)),
                  const SizedBox(height: 6),
                  (Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                          color: const Color(0xFFFFF4DA),
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.all(8),
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Stack(clipBehavior: Clip.none, children: [
                              SizedBox(
                                  width: 86,
                                  height: 56,
                                  child: CustomPaint(
                                      painter: FishingFishArt(_wanted))),
                              const Positioned(
                                  right: -10,
                                  top: -6,
                                  child: FishingBadge('x2', Color(0xFFC0503A))),
                            ]),
                            const SizedBox(height: 4),
                            Text(_wanted.label,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    color: DS.ink,
                                    fontWeight: FontWeight.w900)),
                            Text(
                                '${FishingMarket.priceOf(_wanted, _today)} xu/con',
                                style: const TextStyle(
                                    color: Color(0xFFC0503A),
                                    fontWeight: FontWeight.w900)),
                          ]))),
                  const SizedBox(height: 6),
                  Text(have > 0 ? 'Bạn có $have con' : 'Chưa có trong giỏ',
                      style: TextStyle(
                          color: have > 0
                              ? const Color(0xFFB4E8A5)
                              : const Color(0xFFE7CFAE),
                          fontSize: 12,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text('Đổi đơn sau\n${fishingUntilReset()}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Color(0xFFE7CFAE),
                          fontSize: 11,
                          height: 1.2,
                          fontWeight: FontWeight.w700)),
                ]))));
  }
}
