import 'dart:async';
import 'dart:math';
import 'package:material_ui/material_ui.dart';
import '../../game/adventure/adventure_game.dart';
import '../../game/cats/cat_breed.dart';
import '../design.dart';
import 'adventure_buttons.dart';

class AdventureSkillControls extends StatefulWidget {
  const AdventureSkillControls({super.key, required this.game});
  final AdventureGame game;

  @override
  State<AdventureSkillControls> createState() => _AdventureSkillControlsState();
}

class _AdventureSkillControlsState extends State<AdventureSkillControls> {
  Timer? _timer;
  final _cancelKey = GlobalKey();
  bool _cancelHot = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(DS.fastDuration, (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Widget _attackButton(int slot, double size) {
    final game = widget.game;
    final attack = game.attacks[slot];
    final recall = game.canRecallDecoy(slot);
    final label = recall ? 'Đến phân thân' : attack.label;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      AdventureAimButton(
        key: ValueKey(attack),
        label: label,
        glyph: recall ? CatBreed.black.attacks[0].glyph : attack.glyph,
        color: attack.color,
        size: size,
        aimable: !recall && attack.aimable,
        activeLeft: game.attackActive(slot),
        activeTotal: recall ? attack.duration : 0,
        cooldownLeft: recall ? 0 : game.attackCooldown[slot],
        cooldownTotal: attack.cooldown,
        cancelKey: _cancelKey,
        onCancelHover: (hot) => setState(() => _cancelHot = hot),
        onAim: (stick) {
          final was = game.aimingSlot;
          game.aimAttack(slot, stick);
          if (was != game.aimingSlot) setState(() {});
        },
        onCast: (stick) => setState(() => game.castAttack(slot, stick)),
        onCancel: () => setState(game.cancelAim),
      ),
      const SizedBox(height: DS.space2),
      Text(label,
          style: const TextStyle(
              fontSize: DS.fontCaption,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              shadows: [Shadow(color: Color(0xFF3A2010), blurRadius: 3)])),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    if (!game.started) return const SizedBox.shrink();
    // Keep the thumb resting position inboard of the screen edges.
    const main = 84.0, small = 62.0, arc = 116.0, label = 16.0;
    const box = Size(main / 2 + arc + small / 2 + 20,
        main / 2 + arc + small / 2 + label + 8);
    final mainCenter = Offset(box.width - main / 2, box.height - main / 2 - 4);
    Widget onArc(double degrees, Widget child) {
      final a = degrees * pi / 180;
      final c = mainCenter + Offset(cos(a) * arc, -sin(a) * arc);
      return Positioned(
          left: c.dx - small / 2 - 20,
          top: c.dy - small / 2,
          width: small + 40,
          child: Center(child: child));
    }

    // Original corner placement, raised 20px for easier thumb access.
    const right = 18.0, bottom = 34.0;
    final aiming = game.aimingSlot != null;
    return SafeArea(
      child: Stack(children: [
        Positioned(
          key: const ValueKey('cluster'),
          right: right,
          bottom: bottom,
          child: SizedBox.fromSize(
            size: box,
            child: Stack(clipBehavior: Clip.none, children: [
              Positioned(
                left: mainCenter.dx - main / 2,
                top: mainCenter.dy - main / 2,
                child: AdventureSkillButton(
                  catType: game.selectedCat,
                  size: main,
                  ready: game.skillReady,
                  cooldownLeft: game.skillCooldown,
                  cooldownTotal:
                      CatBreed.of(game.selectedCat).homeSkill.cooldown,
                  onPressed: game.activateSkill,
                ),
              ),
              onArc(187, _attackButton(0, small)),
              onArc(139, _attackButton(1, small)),
              onArc(91, _attackButton(2, small)),
            ]),
          ),
        ),
        // Added after the cluster so showing it never rebuilds the buttons
        // (that used to drop the held finger and need a second press).
        if (aiming)
          Positioned(
            key: const ValueKey('cancel'),
            right: 54,
            top: 66,
            child: SizedBox.square(
              dimension: 76,
              child: Center(
                child: AdventureCancelButton(key: _cancelKey, hot: _cancelHot),
              ),
            ),
          ),
      ]),
    );
  }
}
