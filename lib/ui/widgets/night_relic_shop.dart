import 'package:flutter/material.dart';

import '../../game/night_shift/night_game.dart';
import '../../game/night_shift/night_run.dart';
import '../../game/night_shift/night_cards.dart';
import '../../game/night_shift/night_relics.dart';
import '../design.dart';
import 'night_relic_icon.dart';
import 'night_relic_stall_painter.dart';
import 'silver_token_icon.dart';

class NightRelicShop extends StatefulWidget {
  const NightRelicShop({super.key, required this.game});
  final NightGame game;

  @override
  State<NightRelicShop> createState() => _NightRelicShopState();
}

class _NightRelicShopState extends State<NightRelicShop> {
  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    final run = game.run!;
    return BlockSemantics(
      child: Stack(fit: StackFit.expand, children: [
        const ModalBarrier(dismissible: false, color: Color(0xD9111D30)),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(DS.spaceMd),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Material(
                  color: Colors.transparent,
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    SizedBox(
                      width: 740,
                      height: 370,
                      child: Stack(children: [
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
                        Positioned(
                          top: 77,
                          left: 48,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                                color: const Color(0xEE243953),
                                borderRadius: BorderRadius.circular(15),
                                border:
                                    Border.all(color: const Color(0xFF9CBBD4))),
                            child:
                                Row(mainAxisSize: MainAxisSize.min, children: [
                              const SilverTokenIcon(size: 25),
                              const SizedBox(width: 5),
                              Text('${run.silver} Ngân quang',
                                  style: const TextStyle(
                                      color: Color(0xFFE1F3FF),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900)),
                            ]),
                          ),
                        ),
                        const Positioned(
                            top: 87,
                            right: 50,
                            child: Text('Chọn món hợp với bộ thẻ của bạn',
                                style: TextStyle(
                                    color: Color(0xFFE4CFA3), fontSize: 10))),
                        Positioned(
                          top: 111,
                          left: 48,
                          right: 48,
                          height: 184,
                          child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                for (final relic in game.shopOffer)
                                  Expanded(child: _item(relic)),
                              ]),
                        ),
                        Positioned(
                          left: 42,
                          top: 319,
                          width: 450,
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    'TÚI CỔ VẬT  ${run.relics.length}/${NightRun.relicSlots}',
                                    style: const TextStyle(
                                        color: Color(0xFFFFD68E),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: .7)),
                                const SizedBox(height: 3),
                                Row(children: [
                                  for (var i = 0; i < NightRun.relicSlots; i++)
                                    Container(
                                      margin: const EdgeInsets.only(right: 5),
                                      width: 29,
                                      height: 29,
                                      decoration: BoxDecoration(
                                          color: const Color(0xFF513B32),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          border: Border.all(
                                              color: const Color(0xFFB48B60))),
                                      child: i < run.relics.length
                                          ? Tooltip(
                                              message: run.relics[i].title,
                                              child: NightRelicIcon(
                                                  run.relics[i],
                                                  size: 26))
                                          : const Icon(Icons.add_rounded,
                                              color: Color(0xFF9E7C5C),
                                              size: 16),
                                    ),
                                  const SizedBox(width: 4),
                                  Text(
                                      run.relics.isEmpty
                                          ? 'Mua tối đa 3 món'
                                          : 'Hiệu lực đến hết lượt chơi',
                                      style: const TextStyle(
                                          color: Color(0xFFE0C69D),
                                          fontSize: 10)),
                                ]),
                              ]),
                        ),
                        Positioned(
                          top: 322,
                          right: 42,
                          width: 172,
                          height: 38,
                          child: ElevatedButton.icon(
                            style: DS.primary,
                            onPressed: game.leaveNightShop,
                            icon: const Icon(Icons.arrow_forward_rounded,
                                size: 18),
                            label: Text('ĐI TIẾP · ĐÊM ${run.night + 1}',
                                style: const TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.w900)),
                          ),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                        'Có thể giữ tiền để mua lần sau · Ngân quang không dùng xu của trại',
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

  Widget _item(NightRelic relic) {
    final run = widget.game.run!;
    final bought = run.relics.contains(relic);
    final full = run.relics.length >= NightRun.relicSlots;
    final afford = run.silver >= relic.price;
    final combos = relic.comboCards.where(run.has).toList();
    final moonBlocked =
        relic == NightRelic.moonPouch && run.has(NightCard.fullMoon);
    return Container(
      height: 184,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.fromLTRB(8, 5, 8, 4),
      decoration: BoxDecoration(
        color: bought ? const Color(0xFFDBE1CC) : const Color(0xFFF5E2B8),
        borderRadius: BorderRadius.circular(9),
        border:
            Border.all(color: combos.isNotEmpty ? DS.gold : DS.wood, width: 2),
      ),
      child: Column(children: [
        Opacity(
            opacity: bought ? .4 : 1, child: NightRelicIcon(relic, size: 52)),
        const SizedBox(height: 4),
        Text(relic.title,
            style: DS.bodyText.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 3),
        Text(relic.description,
            textAlign: TextAlign.center,
            style: DS.captionText.copyWith(height: 1.15)),
        const SizedBox(height: 3),
        Text(
            moonBlocked
                ? 'Trăng tròn: không có mây để kích hoạt món này.'
                : combos.isNotEmpty
                    ? 'Combo: ${combos.map((c) => c.title).join(' + ')}'
                    : 'Hợp với: ${relic.comboCards.map((c) => c.title).join(', ')}',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: moonBlocked
                    ? DS.danger
                    : combos.isNotEmpty
                        ? DS.success
                        : DS.soft,
                fontSize: 10,
                fontWeight: FontWeight.w700)),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          height: 28,
          child: ElevatedButton(
            style: DS.primary,
            onPressed: bought || full || !afford
                ? null
                : () {
                    if (widget.game.buyRelic(relic)) setState(() {});
                  },
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              if (!bought && !full) ...[
                const SilverTokenIcon(size: 21),
                const SizedBox(width: 4),
              ],
              Text(
                  bought
                      ? 'ĐÃ BÁN'
                      : full
                          ? 'TÚI ĐÃ ĐẦY'
                          : '${relic.price}',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w900)),
            ]),
          ),
        ),
      ]),
    );
  }
}
