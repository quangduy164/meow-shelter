import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import '../../game/return_home/return_home_game.dart';
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
            cooldownTotal: ReturnHomeGame.skillCooldownFor(game.selectedCat),
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
        color: const Color(0x88403831),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            decoration: BoxDecoration(
                color: const Color(0xFFFFF3D8),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF9A6028), width: 3),
                boxShadow: const [
                  BoxShadow(
                      color: Color(0x663B2415),
                      blurRadius: 14,
                      offset: Offset(0, 7))
                ]),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('CHỌN MÈO',
                  style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF603312))),
              const SizedBox(height: 16),
              Wrap(
                  spacing: 9,
                  runSpacing: 9,
                  alignment: WrapAlignment.center,
                  children: [
                    _catButton(
                        context, 'orange', 'Mèo cam', const Color(0xFFF4A34E)),
                    _catButton(
                        context, 'black', 'Mèo đen', const Color(0xFF536066)),
                    _catButton(context, 'himalaya', 'Himalaya',
                        const Color(0xFFDCC7A7)),
                    _catButton(context, 'scottish', 'Scottish',
                        const Color(0xFFB77E64)),
                  ])
            ]),
          ),
        ),
      );

  Widget _catButton(
          BuildContext context, String type, String label, Color color) =>
      SizedBox(
        width: 165,
        height: 52,
        child: ElevatedButton.icon(
          onPressed: () => game.chooseCat(type),
          icon: SizedBox(
            width: 34,
            height: 34,
            child: ClipOval(
              child: OverflowBox(
                alignment: Alignment.centerLeft,
                maxWidth: 204,
                maxHeight: 34,
                child: Image.asset(
                  'assets/images/Cat/${type[0].toUpperCase()}${type.substring(1)}/cat-$type-idle.png',
                  height: 34,
                  fit: BoxFit.fitHeight,
                  errorBuilder: (_, __, ___) =>
                      CircleAvatar(radius: 13, backgroundColor: color),
                ),
              ),
            ),
          ),
          label: Text(label),
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF603312),
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                  side: const BorderSide(color: Color(0xFFD4B77A)))),
        ),
      );
}
