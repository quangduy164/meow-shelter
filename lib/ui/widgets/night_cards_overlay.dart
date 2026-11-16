import 'package:material_ui/material_ui.dart';
import '../../audio/game_audio.dart';
import '../../game/night_shift/night_game.dart';
import '../../game/night_shift/night_cards.dart';
import '../../game/night_shift/night_relics.dart';
import '../design.dart';
import 'night_card_icons.dart';
import 'silver_token_icon.dart';

/// End of a night: the bonus earned and three cards to pick one from.
class NightCardsOverlay extends StatelessWidget {
  const NightCardsOverlay({super.key, required this.game});
  final NightGame game;

  @override
  Widget build(BuildContext context) {
    final run = game.run!;
    final taken = [
      for (final card in run.cards.toSet())
        run.count(card) > 1 ? '${card.title} x${run.count(card)}' : card.title
    ];
    return Stack(fit: StackFit.expand, children: [
      const ModalBarrier(dismissible: false, color: DS.scrim),
      SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(DS.spaceMd),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Material(
                color: Colors.transparent,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('HOÀN THÀNH ĐÊM ${run.night}',
                      style: const TextStyle(
                          color: DS.cream,
                          fontSize: DS.fontTitle,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                          shadows: [Shadow(color: DS.ink, blurRadius: 4)])),
                  Text(
                      'Đã cứu ${run.totalRescued} mèo · '
                      'đêm tiếp: ${run.mapFor(run.night + 1).title}',
                      style: const TextStyle(
                          color: DS.gold,
                          fontSize: DS.fontBody,
                          fontWeight: FontWeight.w800)),
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    const SilverTokenIcon(size: 22),
                    const SizedBox(width: 4),
                    Text(
                        'Qua đêm +${run.lastSilverReward} Nguyệt quang · Ví: ${run.silver}'
                        '${run.night.isEven ? ' · Chọn thẻ xong ghé cửa hàng' : ''}',
                        style: const TextStyle(
                            color: DS.cream, fontSize: DS.fontBody)),
                  ]),
                  const SizedBox(height: DS.spaceMd),
                  if (game.cardOffer.isEmpty) ...[
                    const Text(
                        'Đã nâng tối đa mọi thẻ. Tiếp tục với bộ thẻ hiện tại.',
                        style: TextStyle(color: DS.cream)),
                    const SizedBox(height: DS.spaceSm),
                    ElevatedButton.icon(
                        onPressed: game.continueWithoutCard,
                        icon: const Icon(Icons.arrow_forward_rounded),
                        label: const Text('TIẾP TỤC')),
                  ],
                  Row(children: [
                    for (final card in game.cardOffer) _card(card),
                  ]),
                  if (taken.isNotEmpty) ...[
                    const SizedBox(height: DS.spaceMd),
                    SizedBox(
                      width: 536,
                      child: Text('Đang có: ${taken.join(' · ')}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: DS.cream, fontSize: DS.fontCaption)),
                    ),
                  ],
                ]),
              ),
            ),
          ),
        ),
      ),
    ]);
  }

  Widget _card(NightCard card) {
    final deal = card.isDeal;
    final combos = [
      ...game.run!.relics.where((r) => r.cardCombos.containsKey(card)),
      ...NightRelic.values.where((r) =>
          !game.run!.relics.contains(r) && r.cardCombos.containsKey(card)),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DS.spaceXs),
      child: InkWell(
        borderRadius: BorderRadius.circular(DS.radiusMd),
        onTap: () {
          GameAudio.instance.play(GameSound.click);
          game.chooseCard(card);
        },
        child: Container(
          width: 168,
          height: 292,
          padding: const EdgeInsets.all(DS.spaceSm),
          decoration: BoxDecoration(
            color: deal ? const Color(0xFF3A2A4A) : DS.cream,
            borderRadius: BorderRadius.circular(DS.radiusMd),
            border: Border.all(
                color: deal ? DS.gold : DS.wood, width: deal ? 3 : 2),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x55000000), blurRadius: 6, offset: Offset(0, 3))
            ],
          ),
          child: Column(children: [
            Text(
                deal
                    ? 'GIAO KÈO'
                    : card.map != null
                        ? 'THẺ BẢN ĐỒ'
                        : 'NÂNG CẤP',
                style: TextStyle(
                    color: deal ? DS.gold : DS.soft,
                    fontSize: DS.fontCaption,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1)),
            const SizedBox(height: DS.spaceXs),
            NightCardIcon(card, size: 54),
            const SizedBox(height: DS.spaceXs),
            Text(card.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: deal ? DS.cream : DS.ink,
                    fontSize: DS.fontBody,
                    fontWeight: FontWeight.w900)),
            const SizedBox(height: DS.spaceXs),
            Text(card.perk,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: deal ? const Color(0xFF9BE3B0) : DS.success,
                    fontSize: DS.fontCaption,
                    fontWeight: FontWeight.w800)),
            if (combos.isNotEmpty) ...[
              const SizedBox(height: DS.spaceXs),
              Text(
                  'Ghép ${combos.first.title}: ${combos.first.cardCombos[card]}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: deal ? DS.cream : DS.soft,
                      fontSize: 10,
                      fontWeight: FontWeight.w700)),
            ],
            if (combos.isEmpty && card.comboHint != null) ...[
              const SizedBox(height: DS.spaceXs),
              Text(card.comboHint!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: deal ? DS.cream : DS.soft, fontSize: 10)),
            ],
            if (card.cost != null) ...[
              const SizedBox(height: DS.space2),
              Text('Đổi lại: ${card.cost}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Color(0xFFFF9C8A),
                      fontSize: DS.fontCaption,
                      fontWeight: FontWeight.w800)),
            ],
          ]),
        ),
      ),
    );
  }
}
