import 'package:material_ui/material_ui.dart';
import '../../audio/game_audio.dart';
import '../../camp/camp_state.dart';
import '../../game/cats/cat_breed.dart';
import '../../game/night_shift/night_game.dart';
import '../../game/night_shift/night_helpers.dart';
import '../design.dart';
import 'night_skill_icon.dart';
import 'cat_sprite.dart';
import 'game_glyphs.dart';
import 'round_button.dart';

/// Before the night shift: pick up to two camp cats to bring along. Each one
/// adds an active skill with the same recharge regardless of affection.
class NightSetupOverlay extends StatefulWidget {
  const NightSetupOverlay(
      {super.key, required this.game, required this.onHome});
  final NightGame game;
  final VoidCallback onHome;

  @override
  State<NightSetupOverlay> createState() => _NightSetupOverlayState();
}

class _NightSetupOverlayState extends State<NightSetupOverlay> {
  final camp = CampState.instance;

  late final _picked = camp.residents.take(2).toList();

  @override
  void initState() {
    super.initState();
    // Let the first round finish mounting before pausing: components still
    // queued while paused would survive the restart below as duplicates
    // (extra cats, a second HUD).
    final game = widget.game.game;
    game.lifecycleEventsProcessed.then((_) {
      if (mounted) game.pauseEngine();
    });
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
      ..game.overlays.remove('nightSetup');
    // Anything still queued must mount first so the restart can remove it.
    game.game.resumeEngine();
    await game.game.lifecycleEventsProcessed;
    await game.game.restartRound();
    if (!game.game.overlays.isActive('nightInfo')) {
      game.game.overlays.add('nightSkills');
    }
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
                'Cứu đủ mèo trước trời sáng, rồi chọn 1 thẻ. Cứu mèo +2 Nguyệt quang, qua đêm thưởng thêm. Chọn tối đa 2 trợ thủ. Qua mỗi 2 đêm ghé tiệm cổ vật.',
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
                    : 'BẮT ĐẦU · ${_picked.map(camp.nameOf).join(' + ')}'),
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
    final cooldown = skill.cooldownFor();
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
                  child: Center(child: NightSkillIcon(breed.id, size: 18)),
                ),
                const SizedBox(width: DS.spaceXs),
                Flexible(
                  child: Text(skill.title,
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
                child: Text(owned ? skill.summary : 'Mua ở cửa hàng trại mèo',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: DS.soft, fontSize: DS.fontCaption, height: 1.2)),
              ),
              Text('Hồi ${cooldown.round()}s',
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
