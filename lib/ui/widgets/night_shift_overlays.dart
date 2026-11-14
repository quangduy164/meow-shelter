import 'dart:async';

import 'package:flutter/material.dart';

import '../../audio/game_audio.dart';
import '../../camp/camp_state.dart';
import '../../game/cats/cat_breed.dart';
import '../../game/meow_shelter_game.dart';
import '../../game/night_shift.dart';
import '../design.dart';
import 'cat_sprite.dart';
import 'night_card_icons.dart';
import 'game_glyphs.dart';
import 'adventure_buttons.dart';
import 'round_button.dart';
import 'skill_glyphs.dart';

/// Before the night shift: pick up to two camp cats to bring along. Each one
/// adds an active skill; bonded cats recharge faster.
class NightSetupOverlay extends StatefulWidget {
  const NightSetupOverlay(
      {super.key, required this.game, required this.onHome});
  final MeowShelterGame game;
  final VoidCallback onHome;

  @override
  State<NightSetupOverlay> createState() => _NightSetupOverlayState();
}

class _NightSetupOverlayState extends State<NightSetupOverlay> {
  final camp = CampState.instance;

  /// Bonded cats first, as they recharge faster.
  late final _picked = <String>[
    ...(camp.residents.toList()
          ..sort((a, b) =>
              (camp.bonded(b) ? 1 : 0).compareTo(camp.bonded(a) ? 1 : 0)))
        .take(2)
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => widget.game.pauseEngine());
  }

  void _toggle(String type) {
    GameAudio.instance.play(GameSound.click);
    setState(() {
      if (!_picked.remove(type)) {
        if (_picked.length == 2) _picked.removeAt(0);
        _picked.add(type);
      }
    });
  }

  Future<void> _start() async {
    if (_picked.isEmpty) return;
    GameAudio.instance.play(GameSound.click);
    final game = widget.game
      ..helpers = List.of(_picked)
      ..overlays.remove('nightSetup');
    await game.restartRound();
    game
      ..overlays.add('nightSkills')
      ..resumeEngine();
  }

  @override
  Widget build(BuildContext context) {
    final record = camp.bestNight > 0
        ? 'Kỷ lục: đêm ${camp.bestNight} · ${camp.bestNightCats} mèo'
        : 'Trụ qua càng nhiều đêm càng tốt';
    return Material(
      color: DS.selectionBackdrop,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(DS.spaceMd),
          child: Column(children: [
            Row(children: [
              RoundButton(
                  glyph: GameGlyph.home, size: 40, onPressed: widget.onHome),
              Expanded(
                child: Column(children: [
                  const Text('CA TRỰC ĐÊM',
                      style: TextStyle(
                          color: DS.cream,
                          fontSize: DS.fontTitle,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1)),
                  Text(record,
                      style: const TextStyle(
                          color: DS.gold,
                          fontSize: DS.fontBody,
                          fontWeight: FontWeight.w800)),
                ]),
              ),
              const SizedBox(width: 40),
            ]),
            const SizedBox(height: DS.spaceXs),
            const Text(
                'Mỗi đêm cứu đủ mèo trước khi trời sáng, rồi chọn 1 thẻ. '
                'Chọn tối đa 2 mèo trong trại đi cùng làm trợ thủ.',
                textAlign: TextAlign.center,
                style: TextStyle(color: DS.cream, fontSize: DS.fontCaption)),
            const SizedBox(height: DS.spaceSm),
            Expanded(
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(children: [
                    for (final breed in CatBreed.all) _helperCard(breed),
                  ]),
                ),
              ),
            ),
            const SizedBox(height: DS.spaceSm),
            SizedBox(
              height: DS.controlHeight,
              child: ElevatedButton.icon(
                style: DS.primary,
                onPressed: _picked.isEmpty ? null : _start,
                icon: const Icon(Icons.nights_stay_rounded),
                label: Text(_picked.isEmpty
                    ? 'CHỌN ÍT NHẤT 1 MÈO'
                    : 'VÀO CA TRỰC · ${_picked.map(camp.nameOf).join(' + ')}'),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _helperCard(CatBreed breed) {
    final owned = camp.unlocked(breed.id);
    final picked = _picked.contains(breed.id);
    final bonded = camp.bonded(breed.id);
    final skill = NightHelperSkill.of[breed.id]!;
    final cooldown = skill.cooldownFor(bonded: bonded);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DS.spaceXs),
      child: Opacity(
        opacity: owned ? 1 : .45,
        child: GestureDetector(
          onTap: owned ? () => _toggle(breed.id) : null,
          child: AnimatedContainer(
            duration: DS.fastDuration,
            width: 150,
            height: 218,
            padding: const EdgeInsets.all(DS.spaceSm),
            decoration: BoxDecoration(
              color: picked ? const Color(0xFFFFF0C8) : DS.cream,
              borderRadius: BorderRadius.circular(DS.radiusMd),
              border: Border.all(
                  color: picked ? DS.goldEdge : DS.wood, width: picked ? 4 : 2),
            ),
            child: Column(children: [
              Stack(clipBehavior: Clip.none, children: [
                CatFace(breed.id,
                    size: 58,
                    background: const Color(0xFFFFE3B0),
                    border: bonded ? DS.goldEdge : DS.wood),
                if (bonded)
                  const Positioned(
                      right: -6,
                      top: -6,
                      child:
                          Icon(Icons.star_rounded, color: DS.star, size: 20)),
                if (picked)
                  const Positioned(
                      left: -6,
                      top: -6,
                      child: Icon(Icons.check_circle_rounded,
                          color: DS.success, size: 22)),
              ]),
              const SizedBox(height: DS.spaceXs),
              Text(camp.nameOf(breed.id),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: DS.ink,
                      fontWeight: FontWeight.w900,
                      fontSize: DS.fontBody)),
              const SizedBox(height: DS.spaceXs),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                      color: breed.homeSkill.color, shape: BoxShape.circle),
                  child: SkillGlyphView(breed.homeSkill.glyph, size: 18),
                ),
                const SizedBox(width: DS.spaceXs),
                Flexible(
                  child: Text(breed.homeSkill.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: DS.ink,
                          fontWeight: FontWeight.w800,
                          fontSize: DS.fontCaption)),
                ),
              ]),
              const SizedBox(height: DS.spaceXs),
              Expanded(
                child: Text(owned ? skill.effect : 'Mua ở cửa hàng trại mèo',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: DS.soft, fontSize: DS.fontCaption, height: 1.2)),
              ),
              Text(
                  bonded
                      ? 'Hồi ${cooldown.round()}s · thân thiết'
                      : 'Hồi ${cooldown.round()}s',
                  style: TextStyle(
                      color: bonded ? DS.goldEdge : DS.soft,
                      fontSize: DS.fontCaption,
                      fontWeight: FontWeight.w800)),
            ]),
          ),
        ),
      ),
    );
  }
}

/// End of a night: the bonus earned and three cards to pick one from.
class NightCardsOverlay extends StatelessWidget {
  const NightCardsOverlay({super.key, required this.game});
  final MeowShelterGame game;

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
                  Text('TRỜI SÁNG! QUA ĐÊM ${run.night}',
                      style: const TextStyle(
                          color: DS.cream,
                          fontSize: DS.fontTitle,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                          shadows: [Shadow(color: DS.ink, blurRadius: 4)])),
                  Text(
                      'Đã cứu ${run.totalRescued} mèo · ${run.coins} xu · '
                      'đêm tiếp: ${run.mapFor(run.night + 1).title}',
                      style: const TextStyle(
                          color: DS.gold,
                          fontSize: DS.fontBody,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: DS.spaceMd),
                  Row(children: [
                    for (final card in game.cardOffer) _card(card),
                  ]),
                  if (taken.isNotEmpty) ...[
                    const SizedBox(height: DS.spaceMd),
                    Text('Đang có: ${taken.join(' · ')}',
                        style: const TextStyle(
                            color: DS.cream, fontSize: DS.fontCaption)),
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
          height: 200,
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
            NightCardIcon(card, size: 64),
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

/// Helper skill buttons during the night shift, between the middle bed and
/// the bottom-right bed so they never cover a drop spot.
class NightSkillBar extends StatefulWidget {
  const NightSkillBar({super.key, required this.game});
  final MeowShelterGame game;

  @override
  State<NightSkillBar> createState() => _NightSkillBarState();
}

class _NightSkillBarState extends State<NightSkillBar> {
  Timer? _refresh;

  @override
  void initState() {
    super.initState();
    // Ten refreshes a second is plenty for a cooldown ring.
    _refresh = Timer.periodic(
        const Duration(milliseconds: 100), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _refresh?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    if (game.run == null) return const SizedBox.shrink();
    return SafeArea(
      child: Align(
        alignment: const Alignment(.4, 1),
        child: Padding(
          padding: const EdgeInsets.only(bottom: DS.spaceSm),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            for (final type in game.helpers) ...[
              Column(mainAxisSize: MainAxisSize.min, children: [
                AdventureSkillButton(
                  catType: type,
                  size: 58,
                  ready: (game.helperCooldown[type] ?? 0) <= 0,
                  cooldownLeft: game.helperCooldown[type] ?? 0,
                  cooldownTotal: game.helperCooldownTotal(type),
                  onPressed: () => game.useHelper(type),
                ),
                const SizedBox(height: DS.space2),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: DS.spaceXs, vertical: 1),
                  decoration: BoxDecoration(
                      color: game.effectLeft(type) > 0
                          ? DS.gold
                          : DS.cream.withOpacity(.9),
                      borderRadius: BorderRadius.circular(DS.radiusSm)),
                  child: Text(
                      game.effectLeft(type) > 0
                          ? '${game.effectLeft(type).ceil()}s'
                          : CampState.instance.nameOf(type),
                      style: const TextStyle(
                          color: DS.ink,
                          fontSize: DS.fontCaption,
                          fontWeight: FontWeight.w800)),
                ),
              ]),
              const SizedBox(width: DS.spaceSm),
            ],
          ]),
        ),
      ),
    );
  }
}
