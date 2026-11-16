import 'dart:async';
import 'package:material_ui/material_ui.dart';
import '../../camp/camp_state.dart';
import '../../game/night_shift/night_game.dart';
import '../design.dart';
import 'adventure_buttons.dart';

/// Helper skill buttons during the night shift, between the middle bed and
/// the bottom-right bed so they never cover a drop spot.
class NightSkillBar extends StatefulWidget {
  const NightSkillBar({super.key, required this.game});
  final NightGame game;

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
                          : DS.cream.withValues(alpha: .9),
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
