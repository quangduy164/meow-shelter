import 'package:flutter/material.dart';
import '../../levels/level_config.dart';

class LevelCard extends StatelessWidget {
  const LevelCard(
      {super.key, required this.level, required this.unlocked, this.onTap});

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
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
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
                        if (unlocked)
                          Text(
                              '${level.catTypes.length} mèo · ${level.isTutorial ? 'Tập chơi' : '${level.timeLimit}s'}',
                              style: const TextStyle(
                                  fontSize: 9, color: Color(0xFF75451F))),
                      ],
                    ),
                  ),
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
