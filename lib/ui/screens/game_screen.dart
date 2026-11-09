import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../../game/meow_shelter_game.dart';
import '../../levels/level_config.dart';
import '../../levels/levels.dart';
import '../widgets/cat_guide_overlay.dart';
import '../widgets/round_button.dart';
import '../widgets/game_glyphs.dart';
import '../widgets/round_result_overlay.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.level});

  final LevelConfig level;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  MeowShelterGame? _game;
  late final _newCats = CatGuideOverlay.unseen(widget.level.catTypes);
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final index = gameLevels.indexWhere((level) => level.id == widget.level.id);
    _game ??= MeowShelterGame(
        level: widget.level,
        onNextLevel: index >= 0 && index < gameLevels.length - 1
            ? () => Navigator.of(context).pushReplacement(
                MaterialPageRoute<void>(
                    builder: (_) => GameScreen(level: gameLevels[index + 1])))
            : null);
    return Scaffold(
      body: GameWidget<MeowShelterGame>(game: _game!, initialActiveOverlays: [
        'home',
        if (_newCats.isNotEmpty) 'catGuide',
      ], overlayBuilderMap: {
        'catGuide': (context, game) => _PausedGuide(
              game: game,
              types:
                  _showAll ? widget.level.catTypes.toSet().toList() : _newCats,
              onDone: () {
                game.overlays.remove('catGuide');
                game.resumeEngine();
              },
              // No practice button inside a practice round itself.
              onPractice: widget.level.isTutorial
                  ? null
                  : (type) => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                          builder: (_) =>
                              GameScreen(level: tutorialLevelFor(type)))),
            ),
        'roundResult': (context, game) => RoundResultOverlay(
            game: game, onHome: () => Navigator.of(context).pop()),
        'home': (context, game) => SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    RoundButton(
                      glyph: GameGlyph.home,
                      tooltip: 'Về chọn màn',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 8),
                    RoundButton(
                      icon: Icons.help_outline_rounded,
                      onPressed: () {
                        _showAll = true;
                        game.overlays.add('catGuide');
                      },
                    ),
                  ]),
                ),
              ),
            ),
      }),
    );
  }
}

/// Pauses the round while a catch guide is on screen.
class _PausedGuide extends StatefulWidget {
  const _PausedGuide(
      {required this.game,
      required this.types,
      required this.onDone,
      this.onPractice});
  final MeowShelterGame game;
  final List<String> types;
  final VoidCallback onDone;
  final void Function(String type)? onPractice;

  @override
  State<_PausedGuide> createState() => _PausedGuideState();
}

class _PausedGuideState extends State<_PausedGuide> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => widget.game.pauseEngine());
  }

  @override
  Widget build(BuildContext context) => CatGuideOverlay(
      types: widget.types,
      onDone: widget.onDone,
      onPractice: widget.onPractice);
}
