import '../design.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../../game/cat_herd/herd_game.dart';
import '../widgets/herd_map_select.dart';
import '../widgets/herd_result_overlay.dart';
import '../widgets/paw_loader.dart';
import '../widgets/round_button.dart';
import '../widgets/game_glyphs.dart';
import '../../camp/camp_state.dart';
import '../../game/cat_herd/herd_map.dart';

class HerdScreen extends StatefulWidget {
  const HerdScreen({super.key});
  @override
  State<HerdScreen> createState() => _HerdScreenState();
}

class _HerdScreenState extends State<HerdScreen> with WidgetsBindingObserver {
  late final HerdGame _game;
  @override
  void initState() {
    super.initState();
    _game = HerdGame(
        needsTutorial: !CampState.instance.herdTutorialDone,
        onTutorialCompleted: CampState.instance.completeHerdTutorial);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _game.pausedByApp = state != AppLifecycleState.resumed;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
          body: GameWidget<HerdGame>(
        game: _game,
        // Shown while sprites load: the map picker's own backdrop, so the
        // screen fades straight into it instead of flashing black.
        loadingBuilder: (_) => const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF293B52), Color(0xFF477471)],
            ),
          ),
          child: Center(child: PawLoader(size: 64, color: DS.cream)),
        ),
        initialActiveOverlays: const ['exit'],
        overlayBuilderMap: {
          'exit': (context, game) => SafeArea(
                child: Padding(
                    padding: const EdgeInsets.all(DS.spaceMd),
                    child: Align(
                        alignment: Alignment.topLeft,
                        child: RoundButton(
                            glyph: GameGlyph.home,
                            tooltip: 'Về Trang chủ',
                            onPressed: () => Navigator.pop(context)))),
              ),
          'maps': (context, game) => HerdMapSelect(
              onPlay: game.chooseMap,
              onHome: () => Navigator.pop(context),
              onTutorial: () => game.chooseMap(HerdMap.tutorial)),
          'result': (context, game) => HerdResultOverlay(
                round: game.round,
                onReplay: game.restart,
                onMap: game.showMaps,
                onHome: () => Navigator.pop(context),
              ),
        },
      ));
}
