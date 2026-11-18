import 'dart:async';
import 'package:material_ui/material_ui.dart';
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
          padding: const EdgeInsets.only(bottom: DS.spaceXs),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            for (final type in game.helpers) ...[
              _compact(game, type),
              const SizedBox(width: DS.spaceSm),
            ],
          ]),
        ),
      ),
    );
  }

  Widget _button(NightGame game, String type, double size) =>
      AdventureSkillButton(
        catType: type,
        size: size,
        ready: (game.helperCooldown[type] ?? 0) <= 0,
        cooldownLeft: game.helperCooldown[type] ?? 0,
        cooldownTotal: game.helperCooldownTotal(type),
        onPressed: () => game.useHelper(type),
      );

  Widget _tag(String text, bool active) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: DS.spaceXs, vertical: 1),
        decoration: BoxDecoration(
            color: active ? DS.gold : DS.cream.withValues(alpha: .9),
            borderRadius: BorderRadius.circular(DS.radiusSm)),
        child: Text(text,
            style: const TextStyle(
                color: DS.ink,
                fontSize: DS.fontCaption,
                fontWeight: FontWeight.w800)),
      );

  /// No name tag; the effect timer sits on the button while it runs.
  Widget _compact(NightGame game, String type) {
    final effect = game.effectLeft(type);
    return Stack(clipBehavior: Clip.none, children: [
      _button(game, type, 44),
      if (effect > 0)
        Positioned(right: -6, top: -6, child: _tag('${effect.ceil()}s', true)),
    ]);
  }
}
