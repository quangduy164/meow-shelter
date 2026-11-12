import '../design.dart';
import 'package:flutter/material.dart';
import '../../audio/game_audio.dart';
import '../widgets/audio_settings_button.dart';

import '../../camp/camp_state.dart';
import '../../levels/levels.dart';
import 'camp_screen.dart';
import 'fishing_screen.dart';
import 'game_screen.dart';
import 'level_select_screen.dart';
import 'return_home_screen.dart';
import 'herd_screen.dart';
import '../widgets/game_logo.dart';
import '../widgets/home_background_painter.dart';
import '../widgets/mode_icon.dart';
import '../widgets/game_pressable.dart';

const _ink = DS.ink;
const _cream = DS.cream;

final homeRouteObserver = RouteObserver<PageRoute<dynamic>>();

/// Home: logo and the main "play" action on the left, every other mode as a
/// labelled colour tile on the right.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with RouteAware {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute<dynamic>) homeRouteObserver.subscribe(this, route);
  }

  @override
  void didPush() => GameAudio.instance.setHomeActive(true);

  @override
  void didPopNext() => GameAudio.instance.setHomeActive(true);

  @override
  void didPushNext() => GameAudio.instance.setHomeActive(false);

  @override
  void didPop() => GameAudio.instance.setHomeActive(false);

  @override
  void dispose() {
    homeRouteObserver.unsubscribe(this);
    GameAudio.instance.setHomeActive(false);
    super.dispose();
  }

  Future<void> _open(Widget screen) async {
    await Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            const CustomPaint(painter: HomeBackgroundPainter()),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(DS.spaceLg),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: SizedBox(
                      width: 820,
                      height: 340,
                      child: Row(
                        children: [
                          Expanded(child: _hero()),
                          const SizedBox(width: DS.spaceXl),
                          _modeGrid(),
                          const SizedBox(width: DS.spaceXl),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const Positioned(
              left: 12,
              bottom: 10,
              child: SafeArea(child: AudioSettingsButton()),
            ),
          ],
        ),
      );

  Widget _hero() => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const GameLogo(),
          const SizedBox(height: DS.spaceXl),
          GamePressable(
            width: 240,
            height: 52,
            color: const Color(0xFFFFB83F),
            shade: const Color(0xFFC0731F),
            // Continue from the first level not yet won.
            onPressed: () => _open(GameScreen(
                level: continueLevel(CampState.instance.levelStars))),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.play_arrow_rounded, size: 28, color: _ink),
                SizedBox(width: DS.spaceXs),
                Text('BẮT ĐẦU',
                    style: TextStyle(
                        color: _ink,
                        fontSize: DS.fontDisplay,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2)),
              ],
            ),
          ),
          const SizedBox(height: DS.spaceMd),
          GamePressable(
            width: 148,
            height: 42,
            color: _cream,
            shade: const Color(0xFFB98A55),
            onPressed: () => _open(const LevelSelectScreen()),
            child: const _Label(Icons.grid_view_rounded, 'CHỌN MÀN'),
          ),
        ],
      );

  Widget _modeGrid() => SizedBox(
        width: 348,
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _ModeTile(
              title: 'CÂU CÁ',
              icon: ModeIconKind.fishing,
              color: DS.modeFishing,
              onPressed: () => _open(const FishingScreen()),
            ),
            _ModeTile(
              title: 'MÈO VỀ NHÀ',
              icon: ModeIconKind.returnHome,
              color: DS.modeReturnHome,
              onPressed: () => _open(const ReturnHomeScreen()),
            ),
            _ModeTile(
              title: 'CỨU HỘ VÔ HẠN',
              icon: ModeIconKind.rescue,
              color: DS.modeRescue,
              onPressed: () => _open(const GameScreen(level: infiniteLevel)),
            ),
            _ModeTile(
              title: 'DẪN ĐÀN VỀ NHÀ',
              icon: ModeIconKind.herd,
              color: DS.modeHerd,
              onPressed: () => _open(const HerdScreen()),
            ),
            _ModeTile(
              title: 'TRẠI MÈO',
              icon: ModeIconKind.camp,
              color: DS.modeCamp,
              onPressed: () => _open(const CampScreen()),
            ),
          ],
        ),
      );
}

class _Label extends StatelessWidget {
  const _Label(this.icon, this.text);
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: _ink),
          const SizedBox(width: DS.spaceXs),
          Text(text,
              style: const TextStyle(
                  color: _ink,
                  fontSize: DS.fontButton,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1)),
        ],
      );
}

/// Solid colour tile: the icon and title share one centered visual block.
class _ModeTile extends StatelessWidget {
  const _ModeTile({
    required this.title,
    required this.icon,
    required this.color,
    required this.onPressed,
  });
  final String title;
  final ModeIconKind icon;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => GamePressable(
        width: 168,
        height: 88,
        color: color,
        shade: Color.lerp(color, Colors.black, .35)!,
        onPressed: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: DS.spaceSm, vertical: DS.spaceSm),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ModeIcon(kind: icon, size: 30, onColor: true),
              const SizedBox(height: DS.spaceSm),
              Text(title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: DS.fontButton,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .2)),
            ],
          ),
        ),
      );
}
