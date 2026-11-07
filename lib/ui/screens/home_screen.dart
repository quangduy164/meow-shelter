import 'package:flutter/material.dart';

import '../../camp/camp_state.dart';
import '../../levels/levels.dart';
import 'camp_screen.dart';
import 'fishing_screen.dart';
import 'game_screen.dart';
import 'level_select_screen.dart';
import 'return_home_screen.dart';
import '../widgets/game_logo.dart';
import '../widgets/home_background_painter.dart';
import '../widgets/mode_icon.dart';

const _ink = Color(0xFF5A3214);
const _cream = Color(0xFFFFF4DA);

/// Home: logo and the main "play" action on the left, every other mode as a
/// labelled colour tile on the right, coins always visible.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<void> _open(Widget screen) async {
    await Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => screen));
    // Coins may have changed in the mode we just left.
    if (mounted) setState(() {});
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
            width: 300,
            height: 64,
            color: const Color(0xFFFFB83F),
            shade: const Color(0xFFC0731F),
            // Continue from the first level not yet won.
            onPressed: () => _open(GameScreen(
                level: continueLevel(CampState.instance.levelStars))),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.play_arrow_rounded, size: 34, color: _ink),
                SizedBox(width: 6),
                Text('BẮT ĐẦU',
                    style: TextStyle(
                        color: _ink,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(mainAxisSize: MainAxisSize.min, children: [
            _Pressable(
              width: 172,
              height: 46,
              color: _cream,
              shade: const Color(0xFFB98A55),
              onPressed: () => _open(const LevelSelectScreen()),
              child: const _Label(Icons.grid_view_rounded, 'CHỌN MÀN'),
            ),
            const SizedBox(width: 12),
            _CoinChip(coins: CampState.instance.coins),
          ]),
        ],
      );

  Widget _modeGrid() => SizedBox(
        width: 420,
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _ModeTile(
              title: 'CÂU CÁ',
              subtitle: 'Sưu tập cá hiếm',
              icon: ModeIconKind.fishing,
              color: const Color(0xFF3E9FB0),
              onPressed: () => _open(const FishingScreen()),
            ),
            _ModeTile(
              title: 'MÈO VỀ NHÀ',
              subtitle: 'Né chướng ngại về nhà',
              icon: ModeIconKind.returnHome,
              color: const Color(0xFF5E9A48),
              onPressed: () => _open(const ReturnHomeScreen()),
            ),
            _ModeTile(
              title: 'CỨU HỘ VÔ HẠN',
              subtitle: 'Cứu mèo không giới hạn',
              icon: ModeIconKind.rescue,
              color: const Color(0xFFE0703F),
              onPressed: () => _open(const GameScreen(level: infiniteLevel)),
            ),
            _ModeTile(
              title: 'TRẠI MÈO',
              subtitle: 'Chăm mèo, trang trí sân',
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
          Icon(icon, size: 22, color: _ink),
          const SizedBox(width: 6),
          Text(text,
              style: const TextStyle(
                  color: _ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1)),
        ],
      );
}

class _CoinChip extends StatelessWidget {
  const _CoinChip({required this.coins});
  final int coins;

  @override
  Widget build(BuildContext context) => Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: const Color(0xCC5A3214),
          borderRadius: BorderRadius.circular(23),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.monetization_on_rounded,
              color: Color(0xFFFFC94A), size: 24),
          const SizedBox(width: 6),
          Text('$coins',
              style: const TextStyle(
                  color: _cream, fontSize: 18, fontWeight: FontWeight.w900)),
        ]),
      );
}

/// Solid colour tile: icon on top, white title and a short description.
class _ModeTile extends StatelessWidget {
  const _ModeTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onPressed,
  });
  final String title;
  final String subtitle;
  final ModeIconKind icon;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => _Pressable(
        width: 204,
        height: 146,
        color: color,
        shade: Color.lerp(color, Colors.black, .35)!,
        onPressed: onPressed,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ModeIcon(kind: icon, size: 54, onColor: true),
              const Spacer(),
              Text(title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .5)),
              const SizedBox(height: 2),
              Text(subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Color(0xE6FFFFFF),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600)),
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
