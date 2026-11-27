import 'package:flame/game.dart';
import 'package:material_ui/material_ui.dart';

import '../../game/adventure/adventure_game.dart';
import '../design.dart';
import '../widgets/paw_loader.dart';
import '../widgets/adventure_buttons.dart';
import '../widgets/adventure_cat_picker.dart';
import '../widgets/game_surfaces.dart';

import '../widgets/adventure_victory_overlay.dart';
import '../widgets/adventure_skill_controls.dart';
import '../widgets/adventure_combo_help.dart';

class AdventureScreen extends StatefulWidget {
  const AdventureScreen({super.key});

  @override
  State<AdventureScreen> createState() => _AdventureScreenState();
}

class _AdventureScreenState extends State<AdventureScreen> {
  late final AdventureGame _game;
  bool _showingComboHelp = false;

  @override
  void initState() {
    super.initState();
    _game = AdventureGame();
  }

  Future<void> _showComboHelp(BuildContext context,
      {String? selectedCat}) async {
    if (_showingComboHelp) return;
    _showingComboHelp = true;
    final resumeAfter = !_game.paused;
    _game.cancelAim();
    if (_game.isLoaded) _game.joystick.delta.setZero();
    _game.pauseEngine();
    try {
      await showGameDialog<void>(
        context: context,
        builder: (_) => AdventureComboHelpDialog(
            selectedCat:
                selectedCat ?? (_game.started ? _game.selectedCat : null)),
      );
    } finally {
      _showingComboHelp = false;
      if (mounted && resumeAfter) _game.resumeEngine();
    }
  }

  @override
  Widget build(BuildContext context) {
    _game.hudPadding = MediaQuery.paddingOf(context);
    return Scaffold(
      body: GameLoadingCurtain(
          game: _game,
          child: GameWidget<AdventureGame>(
            game: _game,
            overlayBuilderMap: {
              'chooseCat': (context, game) => AdventureCatPicker(
                  initialCat: game.selectedCat,
                  onStart: game.chooseCat,
                  onHome: () => Navigator.of(context).pop(),
                  onHelp: (type) => _showComboHelp(context, selectedCat: type)),
              'skill': (context, game) => AdventureSkillControls(game: game),
              'victory': (context, game) => AdventureVictoryOverlay(
                    game: game,
                    onReplay: () => Navigator.of(context).pushReplacement(
                        MaterialPageRoute<void>(
                            builder: (_) => const AdventureScreen())),
                  ),
              'exit': (context, game) => SafeArea(
                    child: Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.all(DS.spaceMd),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          AdventureComboHelpButton(
                              onPressed: () => _showComboHelp(context)),
                          const SizedBox(width: DS.spaceSm),
                          AdventureHomeButton(
                              onPressed: () => Navigator.of(context).pop()),
                        ]),
                      ),
                    ),
                  ),
            },
            initialActiveOverlays: const ['exit', 'chooseCat'],
          )),
    );
  }
}
