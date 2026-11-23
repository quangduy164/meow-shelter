import 'package:material_ui/material_ui.dart';

import '../../camp/camp_state.dart';
import '../../collection/fish_collection.dart';
import '../../collection/fish_species.dart';
import '../../fishing/fishing_market.dart';
import '../design.dart';
import 'fishing_fish_art.dart';
import 'game_surfaces.dart';

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
  int get _total => _fish.fold(
      0,
      (sum, f) =>
          sum +
          FishingMarket.priceOf(f, _today) *
              FishCollection.instance.stockOf(f));

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

  @override
  Widget build(BuildContext context) {
    final fish = _fish;
    return GameDialog(
      maxWidth: 460,
      child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        GameDialogHeader(
            title: 'Chợ cá nổi', onClose: () => Navigator.pop(context)),
        Row(children: [
          const Icon(Icons.monetization_on_rounded, color: DS.gold),
          const SizedBox(width: DS.spaceXs),
          Text('${CampState.instance.coins} xu',
              style: const TextStyle(
                  color: DS.ink, fontWeight: FontWeight.w900, fontSize: 16)),
          const Spacer(),
          if (_note case final note?)
            Flexible(
                child: Text(note,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                        color: DS.success, fontWeight: FontWeight.w700))),
        ]),
        const SizedBox(height: DS.spaceSm),
        // Today's order: the wanted fish pays double.
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: DS.spaceSm, vertical: DS.spaceXs),
          decoration: BoxDecoration(
              color: DS.selectedFill,
              borderRadius: BorderRadius.circular(DS.radiusSm),
              border: Border.all(color: DS.borderMedium)),
          child: Row(children: [
            SizedBox(
                width: 44,
                height: 28,
                child: CustomPaint(painter: FishingFishArt(_wanted))),
            const SizedBox(width: DS.spaceSm),
            Expanded(
                child: Text(
                    'Hôm nay chợ cần ${_wanted.label} · giá gấp đôi '
                    '(${FishingMarket.priceOf(_wanted, _today)} xu/con)',
                    style: const TextStyle(
                        color: DS.ink, fontWeight: FontWeight.w700))),
          ]),
        ),
        const SizedBox(height: DS.spaceMd),
        if (fish.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: DS.spaceLg),
            child: Text('Giỏ trống rồi, đi câu thêm cá rồi quay lại nhé!',
                style: TextStyle(color: DS.soft)),
          )
        else
          Wrap(spacing: DS.spaceSm, runSpacing: DS.spaceSm, children: [
            for (final f in fish)
              _FishLot(
                  fish: f,
                  left: FishCollection.instance.stockOf(f),
                  price: FishingMarket.priceOf(f, _today),
                  wanted: f == _wanted,
                  onSell: _busy ? null : () => _sell([(f, 1)])),
          ]),
        const SizedBox(height: DS.spaceMd),
        Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('Chạm vào cá để bán 1 con',
              style: TextStyle(color: DS.soft, fontSize: 12)),
          const SizedBox(height: DS.spaceSm),
          ElevatedButton(
              style: DS.primary,
              onPressed: fish.isEmpty || _busy
                  ? null
                  : () => _sell([
                        for (final f in fish)
                          (f, FishCollection.instance.stockOf(f))
                      ]),
              child: Text('BÁN HẾT · $_total XU')),
        ]),
      ])),
    );
  }
}

/// Basket fish in an item frame with its count and price.
class _FishLot extends StatelessWidget {
  const _FishLot(
      {required this.fish,
      required this.left,
      required this.price,
      required this.wanted,
      required this.onSell});
  final FishSpecies fish;
  final int left, price;
  final bool wanted;
  final VoidCallback? onSell;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: 'Bán 1 ${fish.label}, $price xu, còn $left',
        child: Tooltip(
          message: '${fish.label} · $price xu/con',
          child: GestureDetector(
            onTap: onSell,
            child: SizedBox(
              width: 66,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                SizedBox.square(
                  dimension: 58,
                  child: Stack(clipBehavior: Clip.none, children: [
                    Positioned.fill(
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(5, 5, 5, 7),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: wanted
                                  ? const [Color(0xFFFFB58A), Color(0xFFE8704A)]
                                  : const [
                                      Color(0xFFFFDE85),
                                      Color(0xFFF7B940)
                                    ]),
                          borderRadius: BorderRadius.circular(13),
                          border: Border.all(
                              color: const Color(0xFF774016), width: 2.5),
                          boxShadow: const [
                            BoxShadow(
                                color: Color(0x44402616), offset: Offset(0, 3))
                          ],
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF4DA),
                            borderRadius: BorderRadius.circular(9),
                            border: Border.all(
                                color: const Color(0x55B27A3E), width: 1.5),
                          ),
                          padding: const EdgeInsets.all(2),
                          child: CustomPaint(painter: FishingFishArt(fish)),
                        ),
                      ),
                    ),
                    Positioned(
                      right: -5,
                      top: -5,
                      child: _Badge('$left', const Color(0xFF31586C)),
                    ),
                    if (wanted)
                      const Positioned(
                          left: -5,
                          top: -5,
                          child: _Badge('x2', Color(0xFFC0503A))),
                  ]),
                ),
                const SizedBox(height: 3),
                Text('$price xu',
                    style: TextStyle(
                        color: wanted ? const Color(0xFFC0503A) : DS.ink,
                        fontSize: 12,
                        fontWeight: FontWeight.w900)),
              ]),
            ),
          ),
        ),
      );
}

class _Badge extends StatelessWidget {
  const _Badge(this.text, this.color);
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minWidth: 21, minHeight: 21),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        alignment: Alignment.center,
        decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFFEFCA), width: 1.5)),
        child: Text(text,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w900)),
      );
}
