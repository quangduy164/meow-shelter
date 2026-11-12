import 'package:flutter/material.dart';

import '../../camp/camp_state.dart';
import '../../game/cats/cat_breed.dart';
import '../design.dart';
import '../widgets/cat_sprite.dart';
import '../../game/world/shelter_garden_painter.dart';
import '../../levels/level_config.dart';
import '../../levels/levels.dart';
import '../widgets/round_button.dart';
import '../widgets/game_glyphs.dart';
import 'game_screen.dart';

const _ink = DS.ink;

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
              padding: const EdgeInsets.fromLTRB(
                  DS.spaceMd, DS.spaceSm, DS.spaceLg, DS.spaceXs),
              child: Row(children: [
                RoundButton(
                    glyph: GameGlyph.home,
                    onPressed: () => Navigator.of(context).pop()),
                const SizedBox(width: DS.spaceMd),
                const Text('CHỌN MÀN',
                    style: TextStyle(
                        color: DS.cream,
                        fontSize: DS.fontTitle,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        shadows: [Shadow(color: _ink, blurRadius: 4)])),
                const Spacer(),
                const Icon(Icons.star_rounded, color: DS.star),
                const SizedBox(width: DS.spaceXs),
                Text('$total/${gameLevels.length * 3}',
                    style: const TextStyle(
                        color: DS.cream,
                        fontSize: DS.fontValue,
                        fontWeight: FontWeight.w900)),
              ]),
            ),
            Expanded(
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(
                    DS.spaceLg, DS.spaceXs, DS.spaceLg, DS.spaceMd),
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
                    const SizedBox(width: DS.spaceMd),
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
      padding: const EdgeInsets.fromLTRB(
          DS.spaceMd, DS.spaceSm, DS.spaceMd, DS.spaceSm),
      decoration: BoxDecoration(
        color: DS.surfaceGlass,
        borderRadius: BorderRadius.circular(DS.radiusCard),
        border: Border.all(color: DS.wood, width: 3),
        boxShadow: const [
          BoxShadow(color: DS.shadowColor, blurRadius: 8, offset: Offset(0, 4))
        ],
      ),
      child: Column(children: [
        Row(children: [
          CatFace(chapter.breed,
              background: const Color(0xFFFFE3B0), border: DS.wood),
          const SizedBox(width: DS.spaceSm),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('CHƯƠNG $number',
                  maxLines: 1,
                  style: const TextStyle(
                      color: DS.label,
                      fontSize: DS.fontCaption,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1)),
              Text(chapter.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: _ink,
                      fontSize: DS.fontHeading,
                      fontWeight: FontWeight.w900)),
              Text(mixed ? 'Đủ 5 giống mèo' : '${breed.name} · ${rule.trait}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      const TextStyle(color: DS.soft, fontSize: DS.fontBody)),
            ]),
          ),
        ]),
        const SizedBox(height: DS.spaceSm),
        // Rows share the card height: 46 on phones, up to 62 on tall
        // screens, and they shrink rather than overflow on short ones.
        Expanded(
          child: LayoutBuilder(builder: (context, box) {
            final row = (box.maxHeight / 3.6 - 6).clamp(30.0, 62.0);
            return Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                for (final entry in entries)
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: DS.spaceXs),
                      child: SizedBox(
                          height: row,
                          child: _LevelRow(
                              entry: entry, onTap: () => onPlay(entry.level))),
                    ),
                  ),
              ],
            );
          }),
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
      color: open ? DS.gold : DS.mutedFill,
      borderRadius: BorderRadius.circular(DS.radiusControl),
      child: InkWell(
        borderRadius: BorderRadius.circular(DS.radiusControl),
        onTap: open ? onTap : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: DS.spaceSm),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(DS.radiusControl),
              border: Border.all(
                  color: open ? DS.goldEdge : DS.mutedBorder, width: 2)),
          child: Row(children: [
            CircleAvatar(
              radius: 15,
              backgroundColor: open ? _ink : DS.mutedText,
              child: Text('${levelNumber(entry.level)}',
                  style: const TextStyle(
                      color: DS.cream,
                      fontWeight: FontWeight.w900,
                      fontSize: DS.fontButton)),
            ),
            const SizedBox(width: DS.spaceSm),
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
                              fontSize: DS.fontBody,
                              fontWeight: FontWeight.w900)),
                      Text(entry.level.tag,
                          style: TextStyle(
                              color:
                                  open ? const Color(0xFF7A4A22) : DS.mutedText,
                              fontSize: DS.fontCaption)),
                    ]),
              ),
            ),
            if (!open)
              const Icon(Icons.lock_rounded, color: DS.mutedText, size: 20)
            else
              Row(mainAxisSize: MainAxisSize.min, children: [
                for (var i = 0; i < 3; i++)
                  Icon(Icons.star_rounded,
                      size: 17,
                      color:
                          i < entry.stars ? DS.cream : const Color(0x55704019)),
              ]),
          ]),
        ),
      ),
    );
  }
}
