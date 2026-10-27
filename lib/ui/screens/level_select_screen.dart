import 'package:flutter/material.dart';
import '../../levels/levels.dart';
import 'game_screen.dart';
import '../widgets/round_button.dart';
import '../widgets/level_card.dart';
import '../widgets/title_plaque.dart';

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
                const TitlePlaque(),
                const SizedBox(height: 8),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 620),
                      child: LayoutBuilder(builder: (context, constraints) {
                        final rows = (gameLevels.length / 3).ceil();
                        final cardHeight =
                            (constraints.maxHeight - 8 - (rows - 1) * 12) /
                                rows;
                        return GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 4),
                          itemCount: gameLevels.length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            mainAxisExtent: cardHeight.clamp(1.0, 114.0),
                          ),
                          itemBuilder: (context, index) {
                            final level = gameLevels[index];
                            // Mỗi màn mẫu đều có thể chơi, dùng chung cơ chế đã làm.
                            const unlocked = true;
                            return LevelCard(
                              level: level,
                              unlocked: unlocked,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => GameScreen(level: level),
                                ),
                              ),
                            );
                          },
                        );
                      }),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 12,
            left: 12,
            child: SafeArea(
              child: Tooltip(
                message: 'Về Trang chủ',
                child: RoundButton(
                  icon: Icons.arrow_back_rounded,
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
