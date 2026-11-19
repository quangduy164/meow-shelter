import 'package:material_ui/material_ui.dart';

import '../../game/night_shift/night_game.dart';
import '../../game/night_shift/night_run.dart';
import '../../game/night_shift/night_relics.dart';
import '../design.dart';
import 'night_relic_icon.dart';
import 'night_relic_stall_painter.dart';
import 'silver_token_icon.dart';

/// Moon-market relic stall between nights. Laid out on the stall painter's
/// 740×370 canvas and scaled down to fit: wallet and reroll on top, three
/// counter cards in the middle, the relic bag as square frames on the shelf.
class NightRelicShop extends StatefulWidget {
  const NightRelicShop({super.key, required this.game});
  final NightGame game;

  @override
  State<NightRelicShop> createState() => _NightRelicShopState();
}

const _boardW = 740.0, _boardH = 370.0;
const _cardTop = 104.0, _cardH = 148.0, _cardW = 172.0, _cardGap = 18.0;
const _bagTop = 252.0, _slot = 46.0, _slotGap = 8.0, _bagLeft = 118.0;

class _NightRelicShopState extends State<NightRelicShop> {
  NightRelic? _selectedRelic;

  NightGame get game => widget.game;
  NightRun get run => game.run!;

  void _refresh(bool changed) {
    if (changed) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final offer = game.shopOffer;
    final cardsLeft = (_boardW -
            offer.length * _cardW -
            (offer.length - 1).clamp(0, 9) * _cardGap) /
        2;
    final selected = _selectedRelic;
    return BlockSemantics(
      child: Stack(fit: StackFit.expand, children: [
        const ModalBarrier(dismissible: false, color: Color(0xD9111D30)),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(DS.spaceSm),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Material(
                  color: Colors.transparent,
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    SizedBox(
                      width: _boardW,
                      height: _boardH,
                      child: Stack(clipBehavior: Clip.none, children: [
                        const Positioned.fill(
                            child: CustomPaint(painter: RelicStallPainter())),
                        const Positioned(
                          left: 170,
                          right: 170,
                          top: 22,
                          child: Text('CỔ VẬT DƯỚI TRĂNG',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: DS.cream,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2)),
                        ),
                        Positioned(left: 48, top: 66, child: _wallet()),
                        Positioned(right: 48, top: 62, child: _reroll()),
                        for (var i = 0; i < offer.length; i++)
                          Positioned(
                            left: cardsLeft + i * (_cardW + _cardGap),
                            top: _cardTop,
                            width: _cardW,
                            height: _cardH,
                            child: _card(offer[i]),
                          ),
                        Positioned(
                            left: 44, top: _bagTop + 6, child: _bagLabel()),
                        for (var i = 0; i < run.relicSlots; i++)
                          Positioned(
                            left: _slotX(i),
                            top: _bagTop,
                            width: _slot,
                            height: _slot,
                            child: _bagSlot(i),
                          ),
                        if (run.relicSlots < NightRun.maxRelicSlots)
                          Positioned(
                            left: _slotX(run.relicSlots),
                            top: _bagTop,
                            width: _slot,
                            height: _slot,
                            child: _slotOffer(),
                          ),
                        Positioned(
                          right: 44,
                          top: _bagTop + 5,
                          width: 176,
                          height: 36,
                          child: ElevatedButton.icon(
                            style: DS.primary,
                            onPressed: game.leaveNightShop,
                            icon: const Icon(Icons.arrow_forward_rounded,
                                size: 18),
                            label: Text('ĐI TIẾP · ĐÊM ${run.night + 1}',
                                style: const TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w900)),
                          ),
                        ),
                        if (selected != null &&
                            run.relics.contains(selected)) ...[
                          Positioned.fill(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () =>
                                  setState(() => _selectedRelic = null),
                              child: const ColoredBox(color: Color(0x44000000)),
                            ),
                          ),
                          _popover(selected),
                        ],
                      ]),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                        'Mua lại cổ vật đã có để lên bậc · Chạm ô trong túi để xem hoặc bán',
                        style:
                            TextStyle(color: Color(0xFFB7C8DF), fontSize: 10)),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  double _slotX(int i) => _bagLeft + i * (_slot + _slotGap);

  Widget _wallet() => Container(
        padding: const EdgeInsets.fromLTRB(4, 3, 10, 3),
        decoration: BoxDecoration(
            color: const Color(0xEE243953),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: const Color(0xFF9CBBD4))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const SilverTokenIcon(size: 22),
          const SizedBox(width: 5),
          Text('${run.silver}',
              style: const TextStyle(
                  color: Color(0xFFE1F3FF),
                  fontSize: 14,
                  fontWeight: FontWeight.w900)),
        ]),
      );

  /// Round reroll button; the price sits on a small tag under it.
  Widget _reroll() {
    final price = run.rerollPrice;
    final ok = run.silver >= price;
    return Tooltip(
      message: 'Đổi hàng trên quầy · $price Nguyệt quang',
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Material(
          color: ok ? DS.gold : const Color(0xFF6A6476),
          shape: const CircleBorder(
              side: BorderSide(color: Color(0xFF4C332C), width: 2)),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: ok ? () => _refresh(game.rerollShop()) : null,
            child: const SizedBox.square(
                dimension: 34,
                child: Icon(Icons.refresh_rounded, color: DS.ink, size: 22)),
          ),
        ),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          decoration: BoxDecoration(
              color: const Color(0xEE243953),
              borderRadius: BorderRadius.circular(6)),
          child: Text('$price',
              style: const TextStyle(
                  color: Color(0xFFE1F3FF),
                  fontSize: 10,
                  fontWeight: FontWeight.w900)),
        ),
      ]),
    );
  }

  Widget _bagLabel() => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('TÚI',
                style: TextStyle(
                    color: Color(0xFFFFD68E),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .8)),
            Text('${run.relics.length}/${run.relicSlots}',
                style: const TextStyle(
                    color: Color(0xFFE0C69D),
                    fontSize: 13,
                    fontWeight: FontWeight.w900)),
          ]);

  BoxDecoration _frame({bool lit = false}) => BoxDecoration(
        color: const Color(0xFF3A2A26),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: lit ? const Color(0xFFFFD68E) : const Color(0xFF8E6A4C),
            width: 2),
      );

  /// Square bag frame: the relic icon with its tier as dots.
  Widget _bagSlot(int index) {
    if (index >= run.relics.length) {
      return DecoratedBox(
        decoration: _frame(),
        child: const Icon(Icons.add_circle_outline_rounded,
            color: Color(0x668E6A4C), size: 18),
      );
    }
    final relic = run.relics[index];
    final tier = run.relicLevel(relic);
    return Tooltip(
      message: '${relic.title} · Bậc $tier/3',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => setState(() => _selectedRelic = relic),
          child: Ink(
            decoration: _frame(lit: _selectedRelic == relic),
            child: Stack(alignment: Alignment.center, children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: NightRelicIcon(relic, size: 30),
              ),
              Positioned(bottom: 3, child: _tierDots(tier)),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _tierDots(int tier) => Row(mainAxisSize: MainAxisSize.min, children: [
        for (var i = 1; i <= 3; i++)
          Container(
            width: 5,
            height: 5,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i <= tier ? DS.gold : const Color(0xFF6B5444)),
          ),
      ]);

  /// Extra bag slot for sale until the bag reaches its maximum size.
  Widget _slotOffer() {
    final ok = run.silver >= NightRun.slotPrice;
    return Tooltip(
      message: 'Mở thêm 1 ô túi · ${NightRun.slotPrice} Nguyệt quang',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: ok ? () => _refresh(game.buyRelicSlot()) : null,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: ok ? const Color(0xFFFFD68E) : const Color(0xFF6B5444),
                  width: 2),
            ),
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.add_rounded,
                  size: 18,
                  color:
                      ok ? const Color(0xFFFFD68E) : const Color(0xFF8E7A6A)),
              Text('${NightRun.slotPrice}',
                  style: TextStyle(
                      color: ok
                          ? const Color(0xFFFFD68E)
                          : const Color(0xFF8E7A6A),
                      fontSize: 10,
                      fontWeight: FontWeight.w900)),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _popover(NightRelic relic) {
    final index = run.relics.indexOf(relic);
    final anchor = _slotX(index) + _slot / 2;
    const width = 290.0;
    final left = (anchor - width / 2).clamp(24.0, _boardW - width - 24);
    return Positioned(
      left: left,
      bottom: _boardH - _bagTop + 10,
      width: width,
      child: Stack(clipBehavior: Clip.none, children: [
        Positioned(
          left: anchor - left - 6,
          bottom: -6,
          child: Transform.rotate(
              angle: .785398,
              child: Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                      color: DS.cream,
                      border: Border(
                          right: BorderSide(color: DS.wood, width: 2),
                          bottom: BorderSide(color: DS.wood, width: 2))))),
        ),
        Material(
          color: DS.cream,
          elevation: 12,
          shadowColor: Colors.black54,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: DS.wood, width: 2)),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    NightRelicIcon(relic, size: 28),
                    const SizedBox(width: 7),
                    Expanded(child: Text(relic.title, style: DS.headingText)),
                    _tierDots(run.relicLevel(relic)),
                  ]),
                  const SizedBox(height: 6),
                  // Short: the description plus only combos already in play.
                  Text(relic.description,
                      style:
                          DS.captionText.copyWith(color: DS.ink, height: 1.35)),
                  for (final card in relic.comboCards.where(run.has))
                    Text('${card.title}: ${relic.cardCombos[card]}',
                        style: const TextStyle(
                            color: DS.goldEdge,
                            fontSize: 10,
                            fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text('Mỗi bậc thêm: ${relic.levelPerk}',
                      style: const TextStyle(
                          color: DS.success,
                          fontSize: 10,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 32,
                    child: ElevatedButton(
                      style: DS.primary,
                      onPressed: () {
                        if (game.sellRelic(relic)) {
                          setState(() => _selectedRelic = null);
                        }
                      },
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('BÁN +${run.sellPrice(relic)}',
                                style: const TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w900)),
                            const SizedBox(width: 3),
                            const SilverTokenIcon(size: 18),
                          ]),
                    ),
                  ),
                ]),
          ),
        ),
      ]),
    );
  }

  /// Counter card: icon, name, a short line, one tier/combo hint, price.
  Widget _card(NightRelic relic) {
    final owned = run.relics.contains(relic);
    final bought = game.shopBought.contains(relic);
    final full = !owned && run.relics.length >= run.relicSlots;
    final price = run.shopPrice(relic);
    final afford = run.silver >= price;
    final tier = run.relicLevel(relic);
    final combos = relic.comboCards.where(run.has).toList();
    final hint = owned
        ? 'Lên bậc ${tier + 1}: ${relic.levelPerk}'
        : combos.isNotEmpty
            ? 'Ghép ${combos.first.title}'
            : null;
    return Tooltip(
      message: relic.details,
      child: Container(
        padding: const EdgeInsets.fromLTRB(9, 8, 9, 8),
        decoration: BoxDecoration(
          color: bought ? const Color(0xFFDBE1CC) : const Color(0xFFF5E2B8),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: owned || combos.isNotEmpty ? DS.gold : DS.wood, width: 2),
        ),
        child: Column(children: [
          Row(children: [
            Opacity(
                opacity: bought ? .45 : 1,
                child: NightRelicIcon(relic, size: 34)),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(relic.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: DS.bodyText.copyWith(
                            fontWeight: FontWeight.w900, height: 1.1)),
                    if (owned) _tierDots(tier),
                  ]),
            ),
          ]),
          const SizedBox(height: 5),
          Text(relic.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: DS.captionText.copyWith(height: 1.2, fontSize: 10)),
          const Spacer(),
          if (hint != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(hint,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: DS.success,
                      fontSize: 10,
                      fontWeight: FontWeight.w800)),
            ),
          SizedBox(
            width: double.infinity,
            height: 28,
            child: ElevatedButton(
              style: DS.primary,
              onPressed: bought || full || !afford
                  ? null
                  : () => _refresh(game.buyRelic(relic)),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  if (!bought && !full) ...[
                    const SilverTokenIcon(size: 20),
                    const SizedBox(width: 4),
                  ],
                  Text(
                      bought
                          ? 'ĐÃ MUA'
                          : full
                              ? 'TÚI ĐẦY'
                              : owned
                                  ? 'BẬC ${tier + 1} · $price'
                                  : '$price',
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w900)),
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
