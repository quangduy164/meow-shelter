import 'package:flutter/material.dart';

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

const _ink = Color(0xFF5A3214);
const _cream = Color(0xFFFFF4DA);

/// Home: logo and the main "play" action on the left, every other mode as a
/// labelled colour tile on the right.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: SizedBox(
                      width: 820,
                      height: 340,
                      child: Row(
                        children: [
                          Expanded(child: _hero()),
                          const SizedBox(width: 24),
                          _modeGrid(),
                          const SizedBox(width: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _hero() => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const GameLogo(),
          const SizedBox(height: 22),
          _Pressable(
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
                SizedBox(width: 6),
                Text('BẮT ĐẦU',
                    style: TextStyle(
                        color: _ink,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _Pressable(
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
              color: const Color(0xFF3E9FB0),
              onPressed: () => _open(const FishingScreen()),
            ),
            _ModeTile(
              title: 'MÈO VỀ NHÀ',
              icon: ModeIconKind.returnHome,
              color: const Color(0xFF5E9A48),
              onPressed: () => _open(const ReturnHomeScreen()),
            ),
            _ModeTile(
              title: 'CỨU HỘ VÔ HẠN',
              icon: ModeIconKind.rescue,
              color: const Color(0xFFE0703F),
              onPressed: () => _open(const GameScreen(level: infiniteLevel)),
            ),
            _ModeTile(
              title: 'DẪN ĐÀN VỀ NHÀ',
              icon: ModeIconKind.herd,
              color: const Color(0xFF8277B2),
              onPressed: () => _open(const HerdScreen()),
            ),
            _ModeTile(
              title: 'TRẠI MÈO',
              icon: ModeIconKind.camp,
              color: const Color(0xFFC85A7C),
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
          const SizedBox(width: 6),
          Text(text,
              style: const TextStyle(
                  color: _ink,
                  fontSize: 14,
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
  Widget build(BuildContext context) => _Pressable(
        width: 168,
        height: 88,
        color: color,
        shade: Color.lerp(color, Colors.black, .35)!,
        onPressed: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ModeIcon(kind: icon, size: 30, onColor: true),
              const SizedBox(height: 8),
              Text(title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .2)),
            ],
          ),
        ),
      );
}

/// Game-style button: a face sitting on a darker base that sinks when pressed.
class _Pressable extends StatefulWidget {
  const _Pressable({
    required this.width,
    required this.height,
    required this.color,
    required this.shade,
    required this.onPressed,
    required this.child,
  });
  final double width;
  final double height;
  final Color color;
  final Color shade;
  final VoidCallback onPressed;
  final Widget child;

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  static const _depth = 6.0;
  bool _down = false;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(20);
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _set(true),
        onTapCancel: () => _set(false),
        onTapUp: (_) => _set(false),
        onTap: widget.onPressed,
        child: SizedBox(
          width: widget.width,
          height: widget.height + _depth,
          child: Stack(children: [
            Positioned.fill(
              top: _depth,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: widget.shade,
                  borderRadius: radius,
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x40000000),
                        blurRadius: 8,
                        offset: Offset(0, 4))
                  ],
                ),
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 70),
              left: 0,
              right: 0,
              top: _down ? _depth : 0,
              height: widget.height,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: radius,
                  border: Border.all(color: widget.shade, width: 2.5),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color.lerp(widget.color, Colors.white, .18)!,
                      widget.color,
                    ],
                  ),
                ),
                child: Center(child: widget.child),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
