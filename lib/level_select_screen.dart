import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'game/meow_shelter_game.dart';
import 'level_config.dart';

class LevelSelectScreen extends StatelessWidget {
  const LevelSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/Background/shelter-yard-background.png',
              fit: BoxFit.cover),
          const ColoredBox(color: Color(0x660F371E)),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 8),
                _TitlePlaque(),
                const SizedBox(height: 8),
                const Text(
                  'Chọn một màn để bắt đầu cứu mèo',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      shadows: [Shadow(blurRadius: 4)]),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 620),
                      child: GridView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 4),
                        itemCount: gameLevels.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.55,
                        ),
                        itemBuilder: (context, index) {
                          final level = gameLevels[index];
                          // Mỗi màn mẫu đều có thể chơi, dùng chung cơ chế đã làm.
                          const unlocked = true;
                          return _LevelCard(
                            level: level,
                            unlocked: unlocked,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => GameScreen(level: level),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: Text(
                      'Mỗi màn có thử thách riêng — chúc bạn cứu đủ các bé mèo!',
                      style: TextStyle(
                          color: Color(0xFFFDE8B3),
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class GameScreen extends StatelessWidget {
  const GameScreen({super.key, required this.level});

  final LevelConfig level;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GameWidget(game: MeowShelterGame(level: level)),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Align(
                alignment: Alignment.topLeft,
                child: _RoundButton(
                  icon: Icons.home_rounded,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TitlePlaque extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 7),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFFFFDF81), Color(0xFFBD6D25)]),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF6E3C16), width: 3),
        boxShadow: const [
          BoxShadow(
              color: Color(0x99000000), blurRadius: 6, offset: Offset(0, 3))
        ],
      ),
      child: const Text('CHỌN MÀN',
          style: TextStyle(
              color: Color(0xFF643613),
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2)),
    );
  }
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({required this.level, required this.unlocked, this.onTap});

  final LevelConfig level;
  final bool unlocked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = unlocked
        ? const [Color(0xFFFFE69B), Color(0xFFF19A35)]
        : const [Color(0xFF9AA09C), Color(0xFF5B655F)];
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: colors),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
                color: unlocked
                    ? const Color(0xFF704019)
                    : const Color(0xFF46504A),
                width: 3),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x66000000), blurRadius: 4, offset: Offset(0, 3))
            ],
          ),
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(unlocked ? Icons.pets_rounded : Icons.lock_rounded,
                        color: unlocked
                            ? const Color(0xFF78441A)
                            : const Color(0xFFE3E7E2),
                        size: 25),
                    const SizedBox(height: 1),
                    Text('MÀN ${level.id}',
                        style: TextStyle(
                            color: unlocked
                                ? const Color(0xFF603312)
                                : Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w900)),
                    Text(unlocked ? level.name : 'Chưa mở khóa',
                        style: TextStyle(
                            color: unlocked
                                ? const Color(0xFF75451F)
                                : const Color(0xFFE8EDEA),
                            fontSize: 10,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              if (unlocked)
                const Positioned(
                  top: 5,
                  right: 7,
                  child: Icon(Icons.star_rounded,
                      color: Color(0xFFFFF1A1),
                      size: 19,
                      shadows: [
                        Shadow(color: Color(0xFF8D560E), blurRadius: 2)
                      ]),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.onPressed});
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Material(
        color: const Color(0xFFFCCB59),
        shape: const CircleBorder(
            side: BorderSide(color: Color(0xFF774016), width: 3)),
        child: IconButton(
            icon: Icon(icon, color: const Color(0xFF643613)),
            onPressed: onPressed),
      );
}
