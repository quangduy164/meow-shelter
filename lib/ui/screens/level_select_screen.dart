import 'package:material_ui/material_ui.dart';

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
  static const _cardWidth = 210.0;
  static const _cardGap = DS.spaceMd;
  final _scroll = ScrollController();

  // Wins can happen several rounds away ("next level" replaces the game
  // route), so listen to saved progress instead of waiting for a pop.
  @override
  void initState() {
    super.initState();
    CampState.instance.progress.addListener(_refresh);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToNext());
  }

  @override
  void dispose() {
    CampState.instance.progress.removeListener(_refresh);
    _scroll.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  /// The level "play" continues from, or null once every level is won.
  LevelConfig? _nextLevel(Map<String, int> stars) {
    final next = continueLevel(stars);
    return (stars['${next.id}'] ?? 0) == 0 ? next : null;
  }

  /// Opens the screen on the chapter the player is working through.
  void _scrollToNext() {
    if (!mounted || !_scroll.hasClients) return;
    final next = _nextLevel(CampState.instance.levelStars);
    if (next == null) return;
    final chapter =
        levelChapters.indexWhere((c) => c.levels.any((l) => l.id == next.id));
    final target = (chapter * (_cardWidth + _cardGap) - _cardGap)
        .clamp(0.0, _scroll.position.maxScrollExtent);
    _scroll.animateTo(target,
        duration: DS.overlayDuration, curve: Curves.easeOutCubic);
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
    final next = _nextLevel(stars);
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
                controller: _scroll,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(
                    DS.spaceLg, DS.spaceXs, DS.spaceLg, DS.spaceMd),
                children: [
                  for (final chapter in levelChapters) ...[
                    _ChapterCard(
                      width: _cardWidth,
                      number: levelChapters.indexOf(chapter) + 1,
                      chapter: chapter,
                      entries: [
                        for (final level in chapter.levels)
                          (
                            level: level,
                            unlocked: levelUnlocked(index++, stars),
                            stars: stars['${level.id}'] ?? 0,
                            next: level.id == next?.id,
                          ),
                      ],
                      onPlay: _play,
                    ),
                    const SizedBox(width: _cardGap),
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

typedef _Entry = ({LevelConfig level, bool unlocked, int stars, bool next});

const _mixedBreeds = ['orange', 'himalaya', 'scottish', 'calico', 'black'];

class _ChapterCard extends StatelessWidget {
  const _ChapterCard({
    required this.width,
    required this.number,
    required this.chapter,
    required this.entries,
    required this.onPlay,
  });
  final double width;
  final int number;
  final LevelChapter chapter;
  final List<_Entry> entries;
  final void Function(LevelConfig level) onPlay;

  @override
  Widget build(BuildContext context) {
    final breed = CatBreed.of(chapter.breed);
    final rule = breed.catchRule;
    final mixed = number == levelChapters.length;
    final open = entries.first.unlocked;
    // Cards hug their content and sit centred in the scrolling strip.
    return Center(
        child: Container(
      width: width,
      padding: const EdgeInsets.fromLTRB(
          DS.spaceLg, DS.spaceMd, DS.spaceLg, DS.spaceMd),
      decoration: BoxDecoration(
        color: open ? DS.surfaceRaised : DS.surfaceMuted,
        borderRadius: BorderRadius.circular(DS.radiusCard),
        border: Border.all(color: open ? DS.wood : DS.mutedBorder, width: 3),
        boxShadow: const [
          BoxShadow(color: DS.shadowColor, blurRadius: 8, offset: Offset(0, 4))
        ],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          Stack(clipBehavior: Clip.none, children: [
            Opacity(
              opacity: open ? 1 : .55,
              child: mixed
                  ? const _FaceCluster()
                  : CatFace(chapter.breed,
                      background: const Color(0xFFFFE3B0), border: DS.wood),
            ),
            if (!open)
              const Positioned(
                right: -4,
                bottom: -4,
                child: CircleAvatar(
                  radius: 11,
                  backgroundColor: DS.mutedText,
                  child: Icon(Icons.lock_rounded, color: DS.cream, size: 14),
                ),
              ),
          ]),
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
              Text(
                  !open
                      ? 'Chưa mở khóa'
                      : mixed
                          ? 'Đủ 5 giống mèo'
                          : '${breed.name} · ${rule.trait}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      const TextStyle(color: DS.soft, fontSize: DS.fontBody)),
            ]),
          ),
        ]),
        const SizedBox(height: DS.spaceSm),
        for (final entry in entries)
          Padding(
            padding: const EdgeInsets.only(top: DS.spaceSm),
            child: SizedBox(
                height: 44,
                child:
                    _LevelRow(entry: entry, onTap: () => onPlay(entry.level))),
          ),
      ]),
    ));
  }
}

/// Five small faces for the final chapter, which mixes every breed.
class _FaceCluster extends StatelessWidget {
  const _FaceCluster();

  @override
  Widget build(BuildContext context) {
    const size = 24.0;
    const spots = [
      Offset(0, 0),
      Offset(19, 0),
      Offset(38, 0),
      Offset(9.5, 21),
      Offset(28.5, 21),
    ];
    return SizedBox(
      width: 62,
      height: 46,
      child: Stack(children: [
        for (var i = 0; i < _mixedBreeds.length; i++)
          Positioned(
            left: spots[i].dx,
            top: spots[i].dy,
            child: CatFace(_mixedBreeds[i],
                size: size,
                background: const Color(0xFFFFE3B0),
                border: DS.wood),
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
    final row = Material(
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
                  color: entry.next
                      ? DS.success
                      : open
                          ? DS.goldEdge
                          : DS.mutedBorder,
                  width: entry.next ? 3 : 2)),
          child: Row(children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: open ? _ink : DS.mutedText,
              child: Text('${levelNumber(entry.level)}',
                  style: const TextStyle(
                      color: DS.cream,
                      fontWeight: FontWeight.w900,
                      fontSize: DS.fontButton)),
            ),
            const SizedBox(width: DS.spaceSm),
            Expanded(
              child: Text(entry.level.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: open ? _ink : DS.mutedText,
                      fontSize: DS.fontBody,
                      height: 1.15,
                      fontWeight: FontWeight.w900)),
            ),
            const SizedBox(width: DS.spaceXs),
            if (!open)
              const Icon(Icons.lock_rounded, color: DS.mutedText, size: 20)
            else if (entry.next)
              const _PlayBadge()
            else
              _Stars(entry.stars),
          ]),
        ),
      ),
    );
    return entry.next ? _Pulse(child: row) : row;
  }
}

/// Earned stars are bright with a brown rim; missing ones are hollow.
class _Stars extends StatelessWidget {
  const _Stars(this.count);
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      for (var i = 0; i < 3; i++)
        i < count
            ? const Icon(Icons.star_rounded,
                size: 17,
                color: Colors.white,
                shadows: [
                    Shadow(color: DS.goldEdge, offset: Offset(0, 1.2)),
                    Shadow(color: DS.goldEdge, blurRadius: 1.5),
                  ])
            : const Icon(Icons.star_outline_rounded,
                size: 17, color: Color(0x99704019)),
    ]);
  }
}

class _PlayBadge extends StatelessWidget {
  const _PlayBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 3, 8, 3),
      decoration: BoxDecoration(
          color: DS.success, borderRadius: BorderRadius.circular(DS.radiusSm)),
      child: const Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.play_arrow_rounded, color: DS.cream, size: 16),
        Text('CHƠI',
            style: TextStyle(
                color: DS.cream,
                fontSize: DS.fontCaption,
                fontWeight: FontWeight.w900)),
      ]),
    );
  }
}

/// Soft breathing glow that marks the level to play next.
class _Pulse extends StatefulWidget {
  const _Pulse({required this.child});
  final Widget child;

  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late final _glow = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glow,
      child: widget.child,
      builder: (context, child) => DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(DS.radiusControl),
          boxShadow: [
            BoxShadow(
                color: DS.success.withValues(alpha: .25 + .35 * _glow.value),
                blurRadius: 4 + 6 * _glow.value,
                spreadRadius: 1 + _glow.value),
          ],
        ),
        child: child,
      ),
    );
  }
}
