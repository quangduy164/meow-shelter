import '../design.dart';
import 'package:flame/game.dart';
import 'package:material_ui/material_ui.dart';
import '../../game/meow_shelter_game.dart';
import '../../camp/camp_state.dart';
import '../../levels/level_config.dart';
import '../../levels/levels.dart';
import '../widgets/cat_guide_overlay.dart';
import '../widgets/round_button.dart';
import '../widgets/game_glyphs.dart';
import '../widgets/round_result_overlay.dart';
import '../widgets/night_setup_overlay.dart';
import '../widgets/night_cards_overlay.dart';
import '../widgets/night_skill_bar.dart';
import '../widgets/night_info_overlay.dart';
import '../widgets/night_relic_shop.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.level});

  final LevelConfig level;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  MeowShelterGame? _game;
  late final _tutorial =
      requiredCatchTutorial(widget.level, CampState.instance.levelStars);
  late final _level = _tutorial ?? widget.level;

  @override
  Widget build(BuildContext context) {
    final index = gameLevels.indexWhere((level) => level.id == widget.level.id);
    final nextLevel = _tutorial != null
        ? widget.level
        : index >= 0 && index < gameLevels.length - 1
            ? gameLevels[index + 1]
            : null;
    _game ??= MeowShelterGame(
        level: _level,
        onNextLevel: nextLevel != null
            ? () => Navigator.of(context).pushReplacement(
                MaterialPageRoute<void>(
                    builder: (_) => GameScreen(level: nextLevel)))
            : null);
    return Scaffold(
      body: GameWidget<MeowShelterGame>(game: _game!, initialActiveOverlays: [
        'home',
        // The night shift starts by choosing helper cats.
        if (_level.isInfinite) 'nightSetup',
      ], overlayBuilderMap: {
        'nightSetup': (context, game) => NightSetupOverlay(
            game: game.night!, onHome: () => Navigator.of(context).pop()),
        'nightCards': (context, game) => NightCardsOverlay(game: game.night!),
        'nightShop': (context, game) => NightRelicShop(game: game.night!),
        'nightInfo': (context, game) => NightInfoOverlay(
              run: game.night!.run!,
              secondsLeft: game.night!.nightSecondsLeft,
              rules: game.night!.nightRules,
              lanternBurn: game.night!.lanternBurn,
              onClose: game.night!.closeNightInfo,
            ),
        'nightSkills': (context, game) => NightSkillBar(game: game.night!),
        'catGuide': (context, game) => _PausedGuide(
              game: game,
              types: _level.catTypes.toSet().toList(),
              onDone: () {
                game.overlays.remove('catGuide');
                game.resumeEngine();
              },
              // No practice button inside a practice round itself.
              onPractice: _level.isTutorial
                  ? null
                  : (type) => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                          builder: (_) =>
                              GameScreen(level: tutorialLevelFor(type)))),
            ),
        'roundResult': (context, game) => RoundResultOverlay(
            game: game,
            nextLabel: _tutorial != null ? 'TIẾP TỤC' : 'MÀN TIẾP',
            onHome: () => Navigator.of(context).pop()),
        'home': (context, game) => SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(DS.spaceMd),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    RoundButton(
                      glyph: GameGlyph.home,
                      tooltip: 'Về chọn màn',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    if (_level.isInfinite) ...[
                      const SizedBox(width: DS.spaceSm),
                      RoundButton(
                        icon: Icons.info_outline_rounded,
                        tooltip: 'Nhiệm vụ và hướng dẫn đêm này',
                        onPressed: game.night!.openNightInfo,
                      ),
                    ],
                    const SizedBox(width: DS.spaceSm),
                    if (!_level.isInfinite)
                      RoundButton(
                        icon: Icons.help_outline_rounded,
                        onPressed: () {
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
