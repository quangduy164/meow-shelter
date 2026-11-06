import 'package:flutter/material.dart';

import '../../levels/levels.dart';
import 'game_screen.dart';
import 'level_select_screen.dart';
import 'fishing_screen.dart';
import 'return_home_screen.dart';
import 'camp_screen.dart';
import '../widgets/game_logo.dart';
import '../widgets/home_background_painter.dart';
import '../widgets/mode_icon.dart';

const _ink = Color(0xFF5A3214);
const _cream = Color(0xFFFFF4DA);

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _open(BuildContext context, Widget screen) => Navigator.of(context)
      .push(MaterialPageRoute<void>(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const CustomPaint(painter: HomeBackgroundPainter()),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: SizedBox(
                    width: 780,
                    height: 360,
                    child: Row(
                      children: [
                        Expanded(child: _mainColumn(context)),
                        const SizedBox(width: 36),
                        _modePanel(context),
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
  }

  Widget _mainColumn(BuildContext context) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const GameLogo(),
          const SizedBox(height: 26),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _PlayButton(
                onPressed: () =>
                    _open(context, GameScreen(level: gameLevels.first)),
              ),
              const SizedBox(width: 12),
              _IconSquareButton(
                tooltip: 'Chọn màn',
                icon: Icons.grid_view_rounded,
                onPressed: () => _open(context, const LevelSelectScreen()),
              ),
              const SizedBox(width: 12),
              _IconSquareButton(
                tooltip: 'Trại mèo',
                icon: Icons.cottage_rounded,
                onPressed: () => _open(context, const CampScreen()),
              ),
            ],
          ),
        ],
      );

  Widget _modePanel(BuildContext context) => Container(
        width: 300,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        decoration: BoxDecoration(
          color: const Color(0xD9FFF4DA),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: const Color(0xFFB27A3E), width: 3),
          boxShadow: const [
            BoxShadow(
                color: Color(0x553B2415), blurRadius: 18, offset: Offset(0, 8)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Row(
              children: [
                Icon(Icons.pets_rounded, size: 18, color: Color(0xFFD9822B)),
                SizedBox(width: 6),
                Text('CHẾ ĐỘ CHƠI',
                    style: TextStyle(
                        color: _ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2)),
              ],
            ),
            const SizedBox(height: 8),
            _ModeCard(
              title: 'BẮT MÈO',
              subtitle: 'Đưa các bé vào đúng ổ',
              icon: ModeIconKind.catchCat,
              color: const Color(0xFFD9657B),
              onPressed: () =>
                  _open(context, GameScreen(level: gameLevels.first)),
            ),
            const SizedBox(height: 8),
            _ModeCard(
              title: 'CÂU CÁ',
              subtitle: 'Sưu tập cá làm mồi',
              icon: ModeIconKind.fishing,
              color: const Color(0xFF3E9FB0),
              onPressed: () => _open(context, const FishingScreen()),
            ),
            const SizedBox(height: 8),
            _ModeCard(
              title: 'CỨU HỘ VÔ HẠN',
              subtitle: 'Cứu mèo không giới hạn',
              icon: ModeIconKind.rescue,
              color: const Color(0xFFE0703F),
              onPressed: () =>
                  _open(context, const GameScreen(level: infiniteLevel)),
            ),
            const SizedBox(height: 8),
            _ModeCard(
              title: 'MÈO VỀ NHÀ',
              subtitle: 'Dẫn mèo né chướng ngại',
              icon: ModeIconKind.returnHome,
              color: const Color(0xFF6B9E4E),
              onPressed: () => _open(context, const ReturnHomeScreen()),
            ),
          ],
        ),
      );
}

/// Nút chính lớn, nổi bật với lớp "đế" 3D.
class _PlayButton extends StatelessWidget {
  const _PlayButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => _PressableShell(
        width: 220,
        height: 56,
        radius: 20,
        face: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFD86B), Color(0xFFFFA93A)]),
        base: const Color(0xFFB8641E),
        onPressed: onPressed,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.play_arrow_rounded, size: 30, color: _ink),
            SizedBox(width: 4),
            Text('BẮT ĐẦU',
                style: TextStyle(
                    color: _ink,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2)),
          ],
        ),
      );
}

class _IconSquareButton extends StatelessWidget {
  const _IconSquareButton(
      {required this.tooltip, required this.icon, required this.onPressed});
  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: tooltip,
        child: Semantics(
          label: tooltip,
          child: _PressableShell(
            width: 56,
            height: 56,
            radius: 18,
            face: const LinearGradient(colors: [_cream, _cream]),
            base: const Color(0xFFB27A3E),
            onPressed: onPressed,
            child: Icon(icon, size: 26, color: _ink),
          ),
        ),
      );
}

class _ModeCard extends StatelessWidget {
  const _ModeCard(
      {required this.title,
      required this.subtitle,
      required this.icon,
      required this.color,
      required this.onPressed});
  final String title;
  final String subtitle;
  final ModeIconKind icon;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => _PressableShell(
        width: double.infinity,
        height: 62,
        radius: 16,
        face: const LinearGradient(colors: [Colors.white, Color(0xFFFFF8E8)]),
        base: const Color(0xFFD8B98A),
        onPressed: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              ModeIcon(kind: icon, size: 46),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: _ink,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: .5)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Color(0xFF8A6446),
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: color, size: 26),
            ],
          ),
        ),
      );
}

/// Khung nút kiểu game: mặt nút nằm trên một "đế" tối màu, nhấn thì lún xuống.
class _PressableShell extends StatefulWidget {
  const _PressableShell({
    required this.width,
    required this.height,
    required this.radius,
    required this.face,
    required this.base,
    required this.onPressed,
    required this.child,
  });
  final double width;
  final double height;
  final double radius;
  final Gradient face;
  final Color base;
  final VoidCallback onPressed;
  final Widget child;

  @override
  State<_PressableShell> createState() => _PressableShellState();
}

class _PressableShellState extends State<_PressableShell> {
  static const _depth = 5.0;
  bool _down = false;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(widget.radius);
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
          child: Stack(
            children: [
              Positioned.fill(
                top: _depth,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: widget.base,
                    borderRadius: radius,
                    boxShadow: const [
                      BoxShadow(
                          color: Color(0x40000000),
                          blurRadius: 6,
                          offset: Offset(0, 3))
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
                    gradient: widget.face,
                    borderRadius: radius,
                    border: Border.all(color: widget.base, width: 2),
                  ),
                  child: Center(child: widget.child),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
