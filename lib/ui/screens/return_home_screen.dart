import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import '../../game/return_home/return_home_game.dart';
import '../../game/cats/cat_breed.dart';
import '../design.dart';
import '../widgets/cat_sprite.dart';
import '../widgets/return_home_buttons.dart';

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
  Widget build(BuildContext context) => Scaffold(
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

class _SkillButton extends StatefulWidget {
  const _SkillButton({required this.game});
  final ReturnHomeGame game;

  @override
  State<_SkillButton> createState() => _SkillButtonState();
}

class _SkillButtonState extends State<_SkillButton> {
  Timer? _timer;
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

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    if (!game.started) return const SizedBox.shrink();
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomRight,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 28, 22),
          child: ReturnHomeSkillButton(
            catType: game.selectedCat,
            ready: game.skillReady,
            cooldownLeft: game.skillCooldown,
            cooldownTotal: CatBreed.of(game.selectedCat).homeSkill.cooldown,
            onPressed: game.activateSkill,
          ),
        ),
      ),
    );
  }
}

class _ChooseCatOverlay extends StatelessWidget {
  const _ChooseCatOverlay({required this.game});
  final ReturnHomeGame game;

  @override
  Widget build(BuildContext context) => Material(
        color: DS.scrim,
        child: Center(
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
