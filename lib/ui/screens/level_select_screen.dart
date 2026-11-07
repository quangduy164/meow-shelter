import 'package:flutter/material.dart';

import '../../camp/camp_state.dart';
import '../../game/cats/cat_breed.dart';
import '../design.dart';
import '../widgets/cat_sprite.dart';
import '../../game/world/shelter_garden_painter.dart';
import '../../levels/level_config.dart';
import '../../levels/levels.dart';
import '../widgets/round_button.dart';
import 'game_screen.dart';

const _ink = Color(0xFF5A3214);

/// Level map: one card per chapter, scrolling sideways. Each chapter shows the
/// breed it teaches and its catch trait, then its levels with best stars.
class LevelSelectScreen extends StatefulWidget {
  const LevelSelectScreen({super.key});

  @override
  State<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends State<LevelSelectScreen> {
  // Wins can happen several rounds away ("next level" replaces the game
  // route), so listen to saved progress instead of waiting for a pop.
  @override
  void initState() {
    super.initState();
    CampState.instance.progress.addListener(_refresh);
  }

  @override
  void dispose() {
    CampState.instance.progress.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _play(LevelConfig level) async {
    await Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => GameScreen(level: level)));
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final stars = CampState.instance.levelStars;
    final total = totalStars(stars);
    var index = 0;
    return Scaffold(
      body: Stack(fit: StackFit.expand, children: [
        const CustomPaint(painter: ShelterGardenPainter()),
        const ColoredBox(color: Color(0x660F371E)),
        SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 16, 6),
              child: Row(children: [
                RoundButton(
                    icon: Icons.arrow_back_rounded,
                    onPressed: () => Navigator.of(context).pop()),
                const SizedBox(width: 12),
                const Text('CHỌN MÀN',
                    style: TextStyle(
                        color: Color(0xFFFFF4DA),
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        shadows: [Shadow(color: _ink, blurRadius: 4)])),
                const Spacer(),
                const Icon(Icons.star_rounded, color: Color(0xFFFFC23D)),
                const SizedBox(width: 4),
                Text('$total/${gameLevels.length * 3}',
                    style: const TextStyle(
                        color: Color(0xFFFFF4DA),
                        fontSize: 18,
                        fontWeight: FontWeight.w900)),
              ]),
            ),
            Expanded(
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
                children: [
                  for (final chapter in levelChapters) ...[
                    _ChapterCard(
                      number: levelChapters.indexOf(chapter) + 1,
                      chapter: chapter,
                      entries: [
                        for (final level in chapter.levels)
                          (
                            level: level,
                            unlocked: levelUnlocked(index++, stars),
                            stars: stars['${level.id}'] ?? 0,
                          ),
                      ],
                      onPlay: _play,
                    ),
                    const SizedBox(width: 14),
                  ],
                ],
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

typedef _Entry = ({LevelConfig level, bool unlocked, int stars});

class _ChapterCard extends StatelessWidget {
  const _ChapterCard({
    required this.number,
    required this.chapter,
    required this.entries,
    required this.onPlay,
  });
  final int number;
  final LevelChapter chapter;
  final List<_Entry> entries;
  final void Function(LevelConfig level) onPlay;

  @override
  Widget build(BuildContext context) {
    final breed = CatBreed.of(chapter.breed);
    final rule = breed.catchRule;
    final mixed = number == levelChapters.length;
    return Container(
      width: 230,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: const Color(0xF2FFF4DA),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFB27A3E), width: 3),
        boxShadow: const [
          BoxShadow(
              color: Color(0x55000000), blurRadius: 8, offset: Offset(0, 4))
        ],
      ),
      child: Column(children: [
        Row(children: [
          CatFace(chapter.breed,
              background: const Color(0xFFFFE3B0), border: DS.wood),
          const SizedBox(width: 8),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('CHƯƠNG $number',
                  maxLines: 1,
                  style: const TextStyle(
                      color: Color(0xFFB0703A),
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1)),
              Text(chapter.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: _ink, fontSize: 18, fontWeight: FontWeight.w900)),
              Text(mixed ? 'Đủ 5 giống mèo' : '${breed.name} · ${rule.trait}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      const TextStyle(color: Color(0xFF8A6446), fontSize: 12)),
            ]),
          ),
        ]),
        const SizedBox(height: 8),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // Rows shrink on short screens instead of overflowing.
              for (final entry in entries)
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: SizedBox(
                        height: 46,
                        child: _LevelRow(
                            entry: entry, onTap: () => onPlay(entry.level))),
                  ),
                ),
            ],
          ),
        ),
      ]),
    );
  }
}

class _LevelRow extends StatelessWidget {
  const _LevelRow({required this.entry, required this.onTap});
  final _Entry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final open = entry.unlocked;
    return Material(
      color: open ? const Color(0xFFFFC24D) : const Color(0xFFD9CDB8),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: open ? onTap : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color:
                      open ? const Color(0xFF9A6028) : const Color(0xFFAA9C86),
                  width: 2)),
          child: Row(children: [
            CircleAvatar(
              radius: 15,
              backgroundColor: open ? _ink : const Color(0xFF8E8270),
              child: Text('${levelNumber(entry.level)}',
                  style: const TextStyle(
                      color: Color(0xFFFFF4DA),
                      fontWeight: FontWeight.w900,
                      fontSize: 13)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entry.level.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: open ? _ink : const Color(0xFF7A6E5C),
                              fontSize: 14,
                              fontWeight: FontWeight.w900)),
                      Text(entry.level.tag,
                          style: TextStyle(
                              color: open
                                  ? const Color(0xFF7A4A22)
                                  : const Color(0xFF8E8270),
                              fontSize: 11)),
                    ]),
              ),
            ),
            if (!open)
              const Icon(Icons.lock_rounded, color: Color(0xFF8E8270), size: 20)
            else
              Row(mainAxisSize: MainAxisSize.min, children: [
                for (var i = 0; i < 3; i++)
                  Icon(Icons.star_rounded,
                      size: 17,
                      color: i < entry.stars
                          ? const Color(0xFFFFF4DA)
                          : const Color(0x55704019)),
              ]),
          ]),
        ),
      ),
    );
  }
}
