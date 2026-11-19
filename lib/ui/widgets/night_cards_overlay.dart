import 'package:material_ui/material_ui.dart';
import '../../audio/game_audio.dart';
import '../../game/night_shift/night_game.dart';
import '../../game/night_shift/night_cards.dart';
import '../../game/night_shift/night_relics.dart';
import '../design.dart';
import 'night_card_icons.dart';
import 'silver_token_icon.dart';

/// Compact three-choice draft; long-press reveals the complete combo text.
class NightCardsOverlay extends StatelessWidget {
  const NightCardsOverlay({super.key, required this.game});
  final NightGame game;

  @override
  Widget build(BuildContext context) {
    final run = game.run!;
    final taken = [
      for (final card in run.cards.toSet()) '${card.title} ×${run.count(card)}',
    ];
    return BlockSemantics(
      child: Stack(fit: StackFit.expand, children: [
        const ModalBarrier(dismissible: false, color: DS.scrim),
        SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(DS.spaceMd),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Material(
                  color: Colors.transparent,
                  child: SizedBox(
                    width: 612,
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Row(children: [
                        Expanded(
                            child: Text('CHỌN THẺ · QUA ĐÊM ${run.night}',
                                style: const TextStyle(
                                    color: DS.cream,
                                    fontSize: DS.fontTitle,
                                    fontWeight: FontWeight.w900))),
                        const SilverTokenIcon(size: 23),
                        const SizedBox(width: 4),
                        Text('+${run.lastSilverReward} · Ví ${run.silver}',
                            style: const TextStyle(
                                color: DS.cream,
                                fontSize: DS.fontBody,
                                fontWeight: FontWeight.w800)),
                      ]),
                      const SizedBox(height: 5),
                      Row(children: [
                        Expanded(
                            child: Text(
                                'Đêm tới: ${run.mapFor(run.night + 1).title}',
                                style: const TextStyle(
                                    color: DS.gold, fontSize: DS.fontBody))),
                        if (run.night.isEven)
                          const Text('Chọn xong ghé cửa hàng',
                              style: TextStyle(
                                  color: DS.cream, fontSize: DS.fontCaption)),
                      ]),
                      const SizedBox(height: 12),
                      if (game.cardOffer.isEmpty) ...[
                        const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Text('Đã nâng tối đa mọi thẻ.',
                                style: TextStyle(color: DS.cream))),
                        ElevatedButton.icon(
                            onPressed: game.continueWithoutCard,
                            icon: const Icon(Icons.arrow_forward_rounded),
                            label: const Text('TIẾP TỤC')),
                      ] else
                        Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              for (final card in game.cardOffer) _card(card),
                            ]),
                      const SizedBox(height: 9),
                      Row(children: [
                        const Expanded(
                            child: Text('Chọn 1 thẻ · Giữ thẻ để xem chi tiết',
                                style: TextStyle(
                                    color: DS.cream,
                                    fontSize: DS.fontCaption))),
                        if (taken.isNotEmpty)
                          Tooltip(
                              message: taken.join('\n'),
                              child: Text(
                                  'Bộ thẻ: ${run.cards.length} · Giữ để xem',
                                  style: const TextStyle(
                                      color: DS.cream,
                                      fontSize: DS.fontCaption))),
                      ]),
                    ]),
                  ),
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _card(NightCard card) {
    final run = game.run!;
    final deal = card.isDeal;
    final combos = [
      ...run.relics.where((r) => r.cardCombos.containsKey(card)),
      ...NightRelic.values.where(
          (r) => !run.relics.contains(r) && r.cardCombos.containsKey(card)),
    ];
    final combo = combos.isNotEmpty ? combos.first : null;
    final details = [
      card.title,
      card.perk,
      if (card.cost != null) 'Đổi lại: ${card.cost}',
      if (card.paysOnPick) 'Chọn ngay: +${NightCard.mapCardBonus} Nguyệt quang',
      for (final relic in combos) '${relic.title}: ${relic.cardCombos[card]}',
      if (card.comboHint != null) card.comboHint!,
    ].join('\n');
    final ink = deal ? DS.cream : DS.ink;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Tooltip(
        message: details,
        child: InkWell(
          borderRadius: BorderRadius.circular(DS.radiusMd),
          onTap: () {
            GameAudio.instance.play(GameSound.click);
            game.chooseCard(card);
          },
          child: Container(
            width: 180,
            height: 230,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: deal ? const Color(0xFF3A2A4A) : DS.cream,
              borderRadius: BorderRadius.circular(DS.radiusMd),
              border: Border.all(color: deal ? DS.gold : DS.wood, width: 2),
              boxShadow: DS.cardShadow,
            ),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                      deal
                          ? 'GIAO KÈO'
                          : card.map != null
                              ? 'THẺ BẢN ĐỒ'
                              : 'DÙNG CHUNG',
                      style: TextStyle(
                          color: deal ? DS.gold : DS.soft,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          letterSpacing: .5)),
                  const SizedBox(height: 4),
                  NightCardIcon(card, size: 38),
                  const SizedBox(height: 4),
                  Text(card.title,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: ink,
                          fontSize: DS.fontBody,
                          height: 1.15,
                          fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: SizedBox(
                          width: 156,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(card.perk,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: deal
                                          ? const Color(0xFF9BE3B0)
                                          : DS.success,
                                      fontSize: 11,
                                      height: 1.25,
                                      fontWeight: FontWeight.w800)),
                              if (card.paysOnPick) ...[
                                const SizedBox(height: 5),
                                const Text(
                                    'Chọn ngay: +${NightCard.mapCardBonus} Nguyệt quang',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        color: DS.goldEdge,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800)),
                              ],
                              if (card.cost != null) ...[
                                const SizedBox(height: 5),
                                Text('Đổi lại: ${card.cost}',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        color: Color(0xFFFF9C8A),
                                        fontSize: 10,
                                        height: 1.2,
                                        fontWeight: FontWeight.w700)),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
                    decoration: BoxDecoration(
                        color: deal ? const Color(0x33FFFFFF) : DS.surfaceMuted,
                        borderRadius: BorderRadius.circular(6)),
                    child: Row(children: [
                      Icon(
                          combo != null
                              ? Icons.auto_awesome_rounded
                              : Icons.info_outline_rounded,
                          color: deal ? DS.gold : DS.soft,
                          size: 13),
                      const SizedBox(width: 4),
                      Expanded(
                          child: Text(
                              combo != null
                                  ? '${run.relics.contains(combo) ? 'Đang ghép' : 'Ghép'} ${combo.title}'
                                  : card.comboHint != null
                                      ? 'Có combo · Giữ để xem'
                                      : 'Đã chọn ${run.count(card)}/${card.limit}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: ink,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700))),
                    ]),
                  ),
                ]),
          ),
        ),
      ),
    );
  }
}
