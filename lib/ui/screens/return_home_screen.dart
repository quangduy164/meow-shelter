import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

import '../../game/return_home/return_home_game.dart';
import '../../game/cats/cat_breed.dart';
import '../design.dart';
import '../widgets/cat_sprite.dart';
import '../widgets/return_home_buttons.dart';
import '../widgets/game_glyphs.dart';
import '../widgets/round_button.dart';

class ReturnHomeScreen extends StatefulWidget {
  const ReturnHomeScreen({super.key});

  @override
  State<ReturnHomeScreen> createState() => _ReturnHomeScreenState();
}

class _ReturnHomeScreenState extends State<ReturnHomeScreen> {
  late final ReturnHomeGame _game;

  @override
  void initState() {
    super.initState();
    _game = ReturnHomeGame();
  }

  @override
  Widget build(BuildContext context) {
    _game.hudPadding = MediaQuery.paddingOf(context);
    return Scaffold(
      body: GameWidget<ReturnHomeGame>(
        game: _game,
        overlayBuilderMap: {
          'chooseCat': (context, game) => _ChooseCatOverlay(game: game),
          'skill': (context, game) => _SkillButton(game: game),
          'exit': (context, game) => SafeArea(
                child: Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: ReturnHomeHomeButton(
                        onPressed: () => Navigator.of(context).pop()),
                  ),
                ),
              ),
        },
        initialActiveOverlays: const ['exit', 'chooseCat'],
      ),
    );
  }
}

class _SkillButton extends StatefulWidget {
  const _SkillButton({required this.game});
  final ReturnHomeGame game;

  @override
  State<_SkillButton> createState() => _SkillButtonState();
}

class _SkillButtonState extends State<_SkillButton> {
  Timer? _timer;
  final _cancelKey = GlobalKey();
  bool _cancelHot = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
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
    return Column(mainAxisSize: MainAxisSize.min, children: [
      ReturnHomeAimButton(
        key: ValueKey(attack),
        label: attack.label,
        glyph: attack.glyph,
        color: attack.color,
        size: size,
        aimable: attack.aimable,
        activeLeft: game.attackActive(slot),
        cooldownLeft: game.attackCooldown[slot],
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
      const SizedBox(height: 2),
      Text(attack.label,
          style: const TextStyle(
              fontSize: 11,
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
                child: ReturnHomeSkillButton(
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
                child: ReturnHomeCancelButton(key: _cancelKey, hot: _cancelHot),
              ),
            ),
          ),
      ]),
    );
  }
}

class _ChooseCatOverlay extends StatelessWidget {
  const _ChooseCatOverlay({required this.game});
  final ReturnHomeGame game;

  @override
  Widget build(BuildContext context) => Material(
        color: DS.scrim,
        child: Stack(children: [
          // The picker covers the in-game exit button, so it has its own.
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Align(
                alignment: Alignment.topLeft,
                child: RoundButton(
                    glyph: GameGlyph.home,
                    tooltip: 'Về Trang chủ',
                    onPressed: () => Navigator.of(context).pop()),
              ),
            ),
          ),
          Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 420),
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              decoration: DS.card,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('CHỌN MÈO', style: DS.title),
                const SizedBox(height: 16),
                Wrap(
                    spacing: 9,
                    runSpacing: 9,
                    alignment: WrapAlignment.center,
                    children: [
                      for (final breed in CatBreed.all)
                        _catButton(context, breed),
                    ])
              ]),
            ),
          ),
        ]),
      );

  Widget _catButton(BuildContext context, CatBreed breed) => SizedBox(
        width: 165,
        height: 52,
        child: ElevatedButton.icon(
          onPressed: () => game.chooseCat(breed.id),
          icon: CatFace(breed.id, size: 34),
          label: Text(breed.name),
          style: DS.primary,
        ),
      );
}
