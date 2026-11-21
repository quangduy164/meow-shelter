import 'dart:math' as math;
import 'package:material_ui/material_ui.dart';
import '../../collection/fish_collection.dart';
import '../../collection/fish_species.dart';
import 'fishing_fish_art.dart';
import '../design.dart';
import 'game_surfaces.dart';

/// Fish journal: tabbed grid on the left, details of the picked entry on
/// the right. Undiscovered entries show as silhouettes named "???".
class FishCollectionDialog extends StatefulWidget {
  const FishCollectionDialog({super.key, required this.collection});
  final FishCollection collection;

  @override
  State<FishCollectionDialog> createState() => _FishCollectionDialogState();
}

int _rarityLevel(FishSpecies fish) => switch (fish.rarity) {
      'Hiếm' => 1,
      'Quý' => 2,
      'Cực hiếm' => 3,
      'Huyền thoại' => 4,
      _ => 0,
    };

Color _rarityTone(FishSpecies fish) => switch (_rarityLevel(fish)) {
      1 => const Color(0xFF21754D),
      2 => const Color(0xFF2568A8),
      3 => const Color(0xFF823DB4),
      4 => const Color(0xFFAE5A12),
      _ => const Color(0xFF665F59),
    };

List<Color> _rarityFill(FishSpecies fish) => switch (_rarityLevel(fish)) {
      1 => const [Color(0xFFD5ECCC), Color(0xFF8EC39F)],
      2 => const [Color(0xFFCAE5FF), Color(0xFF85B5DE)],
      3 => const [Color(0xFFDDC1F2), Color(0xFFB07BD1)],
      4 => const [Color(0xFFFFDF85), Color(0xFFDFAC43)],
      _ => const [DS.surfaceRaised, Color(0xFFF3E4C8)],
    };

/// Paint-only animation: the grid and text do not rebuild for each sparkle.
class _RarityAura extends StatefulWidget {
  const _RarityAura(this.fish);
  final FishSpecies fish;
  @override
  State<_RarityAura> createState() => _RarityAuraState();
}

class _RarityAuraState extends State<_RarityAura>
    with SingleTickerProviderStateMixin {
  late final _motion =
      AnimationController(vsync: this, duration: const Duration(seconds: 4));
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMotion();
  }

  @override
  void didUpdateWidget(covariant _RarityAura oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncMotion();
  }

  void _syncMotion() {
    if (MediaQuery.disableAnimationsOf(context) ||
        _rarityLevel(widget.fish) < 3) {
      _motion.stop();
    } else if (!_motion.isAnimating) {
      _motion.repeat();
    }
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
          child: CustomPaint(
        painter: _RarityOrnament(
            _rarityTone(widget.fish), _rarityLevel(widget.fish), _motion),
      ));
}

class _RarityOrnament extends CustomPainter {
  _RarityOrnament(this.color, this.level, this.motion) : super(repaint: motion);
  final Color color;
  final int level;
  final Animation<double> motion;
  @override
  void paint(Canvas canvas, Size size) {
    if (level == 0 || size.isEmpty) return;
    final rect = (Offset.zero & size).deflate(4);
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8)));
    final light =
        Color.lerp(color, const Color(0xFFFFE7AA), level == 4 ? .85 : .35)!;
    final center = Offset(size.width * .5, size.height * .35);
    final halo = Rect.fromCircle(center: center, radius: size.width * .48);
    canvas.drawOval(
        halo,
        Paint()
          ..shader = RadialGradient(colors: [
            light.withValues(alpha: .16 + level * .025),
            light.withValues(alpha: 0),
          ]).createShader(halo));
    final pen = Paint()
      ..color = light.withValues(alpha: .9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = level >= 3 ? 1.5 : 1;
    if (level >= 3) {
      canvas.drawRRect(
          RRect.fromRectAndRadius(rect.deflate(3), const Radius.circular(6)),
          pen..color = light.withValues(alpha: .55));
    }
    // Corner filigree grows more elaborate with rarity.
    for (final dx in [-1.0, 1.0]) {
      for (final dy in [-1.0, 1.0]) {
        final c = Offset(dx < 0 ? rect.left + 4 : rect.right - 4,
            dy < 0 ? rect.top + 4 : rect.bottom - 4);
        final length = 8.0 + level * 3;
        canvas.drawPath(
            Path()
              ..moveTo(c.dx - dx * length, c.dy)
              ..lineTo(c.dx, c.dy)
              ..lineTo(c.dx, c.dy - dy * length),
            pen..color = light);
        if (level >= 2) {
          final gem = c - Offset(dx * 3, dy * 3);
          canvas.drawPath(
              Path()
                ..addPolygon([
                  gem + const Offset(0, -3),
                  gem + const Offset(2.5, 0),
                  gem + const Offset(0, 3),
                  gem + const Offset(-2.5, 0),
                ], true),
              Paint()..color = light);
        }
      }
    }
    if (level >= 3) {
      final sweep = (motion.value * 2.8 - .9) * size.width;
      canvas.drawPath(
          Path()
            ..moveTo(sweep - 22, 0)
            ..lineTo(sweep + 4, 0)
            ..lineTo(sweep - size.height * .4 + 4, size.height)
            ..lineTo(sweep - size.height * .4 - 22, size.height)
            ..close(),
          Paint()
            ..color = Colors.white.withValues(alpha: level == 4 ? .08 : .05));
      for (var i = 0; i < level + 1; i++) {
        final a = i * 2.4;
        final p = Offset(size.width * (.12 + .76 * (.5 + .5 * math.sin(a))),
            size.height * (.16 + .64 * (.5 + .5 * math.cos(a))));
        final pulse =
            .35 + .65 * (.5 + .5 * math.sin(motion.value * math.pi * 2 + i));
        final r = (level == 4 ? 4.0 : 3.0) * pulse;
        canvas.drawPath(
            Path()
              ..moveTo(p.dx, p.dy - r)
              ..quadraticBezierTo(p.dx + 1, p.dy - 1, p.dx + r, p.dy)
              ..quadraticBezierTo(p.dx + 1, p.dy + 1, p.dx, p.dy + r)
              ..quadraticBezierTo(p.dx - 1, p.dy + 1, p.dx - r, p.dy)
              ..quadraticBezierTo(p.dx - 1, p.dy - 1, p.dx, p.dy - r)
              ..close(),
            Paint()..color = light.withValues(alpha: .8 * pulse));
      }
    }
    if (level == 4) {
      final x = size.width * .5;
      canvas.drawPath(
          Path()
            ..addPolygon([
              Offset(x - 10, 8),
              Offset(x - 5, 12),
              Offset(x, 5),
              Offset(x + 5, 12),
              Offset(x + 10, 8),
              Offset(x + 7, 17),
              Offset(x - 7, 17),
            ], true),
          Paint()..color = const Color(0xFFE8AA38));
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _RarityOrnament old) =>
      color != old.color || level != old.level || motion != old.motion;
}

/// Stars shown with the rarity: one for common up to five for legendary.
class _RarityStars extends StatelessWidget {
  const _RarityStars(this.fish, {this.dim = false});
  final FishSpecies fish;
  final bool dim;

  @override
  Widget build(BuildContext context) {
    final level = _rarityLevel(fish);
    final tone = level == 0 ? DS.wood : _rarityTone(fish);
    return Row(mainAxisSize: MainAxisSize.min, children: [
      for (var i = 0; i <= level; i++)
        Icon(Icons.star_rounded,
            size: 11,
            color: dim ? const Color(0xCCFFD877) : tone,
            shadows: const [Shadow(color: Color(0x55FFFFFF), blurRadius: 1)]),
    ]);
  }
}

class _RarityTag extends StatelessWidget {
  const _RarityTag(this.fish);
  final FishSpecies fish;

  @override
  Widget build(BuildContext context) {
    final level = _rarityLevel(fish);
    final color = _rarityTone(fish);
    final foreground = level == 4 ? const Color(0xFF69350C) : Colors.white;
    return Container(
      padding: const EdgeInsets.fromLTRB(DS.spaceSm, 3, DS.spaceSm, 3),
      decoration: BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: fish.isJunk || level == 0
                  ? const [Color(0xFF9C8D7C), Color(0xFF7C6E60)]
                  : level == 4
                      ? const [Color(0xFFFFE5A1), Color(0xFFECAF35)]
                      : [
                          Color.lerp(color, Colors.white, .1)!,
                          Color.lerp(color, Colors.black, .2)!
                        ]),
          borderRadius: BorderRadius.circular(DS.radiusLg)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (!fish.isJunk) ...[
          for (var i = 0; i <= level; i++)
            Icon(Icons.star_rounded, size: 11, color: foreground),
          const SizedBox(width: DS.spaceXs),
        ],
        Text(fish.rarity,
            style: TextStyle(
                color: fish.isJunk || level == 0 ? Colors.white : foreground,
                fontSize: DS.fontCaption,
                height: 1.1,
                fontWeight: FontWeight.w900)),
      ]),
    );
  }
}

/// Nocturnal species receive the regional night-time weight bonus.
(IconData, String) _biteTime(FishSpecies fish) => fish.nightActive
    ? (Icons.bedtime_rounded, 'Ban đêm nhiều hơn')
    : (Icons.schedule_rounded, 'Cả ngày lẫn đêm');

class _FishCollectionDialogState extends State<FishCollectionDialog> {
  bool _junkTab = false;
  late FishSpecies _selected = _entries.firstWhere(
      (fish) => widget.collection.countOf(fish) > 0,
      orElse: () => _entries.first);

  List<FishSpecies> _of(bool junk) {
    final entries =
        FishSpecies.values.where((fish) => fish.isJunk == junk).toList();
    if (!junk) {
      entries.sort((a, b) {
        final region = FishSpecies.habitats
            .indexOf(a.habitat)
            .compareTo(FishSpecies.habitats.indexOf(b.habitat));
        if (region != 0) return region;
        final rarity = _rarityLevel(a).compareTo(_rarityLevel(b));
        return rarity != 0 ? rarity : a.index.compareTo(b.index);
      });
    }
    return entries;
  }

  Widget _grid(List<FishSpecies> fish) => SliverPadding(
        padding: const EdgeInsets.only(bottom: DS.spaceSm),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 132,
              mainAxisExtent: 114,
              crossAxisSpacing: DS.spaceSm,
              mainAxisSpacing: DS.spaceSm),
          delegate: SliverChildBuilderDelegate((context, index) {
            final entry = fish[index];
            return _FishTile(
                fish: entry,
                count: widget.collection.countOf(entry),
                selected: entry == _selected,
                onTap: () => setState(() => _selected = entry));
          }, childCount: fish.length),
        ),
      );

  List<FishSpecies> get _entries => _of(_junkTab);

  int _found(bool junk) =>
      _of(junk).where((fish) => widget.collection.countOf(fish) > 0).length;

  void _switchTab(bool junk) {
    if (junk == _junkTab) return;
    setState(() {
      _junkTab = junk;
      _selected = _entries.firstWhere(
          (fish) => widget.collection.countOf(fish) > 0,
          orElse: () => _entries.first);
    });
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final width = (screen.width - 48).clamp(320.0, 820.0);
    // Detail column takes a share of the card so narrow (4:3) screens still
    // leave room for the grid.
    final detailWidth = (width * .34).clamp(190.0, 260.0);
    return GameDialog(
      maxWidth: 820,
      padding: EdgeInsets.zero,
      insetPadding: const EdgeInsets.symmetric(
          horizontal: DS.spaceXl, vertical: DS.spaceMd),
      child: Container(
        width: width,
        height: (screen.height * .9).clamp(260.0, 480.0),
        padding: const EdgeInsets.fromLTRB(
            DS.spaceLg, DS.spaceSm, DS.spaceSm, DS.spaceMd),
        child: Column(children: [
          SizedBox(
            height: 44,
            child: Row(children: [
              const Icon(Icons.menu_book_rounded,
                  color: DS.goldEdge, size: DS.iconLg),
              const SizedBox(width: DS.spaceSm),
              const Text('BỘ SƯU TẬP', style: DS.title),
              const Spacer(),
              _Tabs(
                  junk: _junkTab,
                  fishFound: '${_found(false)}/${_of(false).length}',
                  junkFound: '${_found(true)}/${_of(true).length}',
                  onChanged: _switchTab),
              IconButton(
                tooltip: 'Đóng bộ sưu tập',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, size: DS.iconMd),
              ),
            ]),
          ),
          const SizedBox(height: DS.spaceSm),
          Expanded(
            child:
                Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Expanded(
                child: CustomScrollView(
                  key: ValueKey(_junkTab),
                  slivers: [
                    if (_junkTab)
                      _grid(_entries)
                    else
                      for (final region in FishSpecies.habitats) ...[
                        SliverToBoxAdapter(
                            child: Padding(
                          padding: const EdgeInsets.only(
                              top: DS.spaceXs, bottom: DS.spaceSm),
                          child: Row(children: [
                            const Icon(Icons.place_rounded,
                                size: 15, color: DS.goldEdge),
                            const SizedBox(width: DS.spaceXs),
                            Text(region,
                                style: const TextStyle(
                                    color: DS.ink,
                                    fontSize: DS.fontBody,
                                    fontWeight: FontWeight.w900)),
                          ]),
                        )),
                        _grid(_entries
                            .where((fish) => fish.habitat == region)
                            .toList()),
                      ],
                  ],
                ),
              ),
              const SizedBox(width: DS.spaceMd),
              SizedBox(
                width: detailWidth,
                child: _DetailPanel(
                    fish: _selected,
                    count: widget.collection.countOf(_selected),
                    heaviest: widget.collection.heaviestGrams(_selected)),
              ),
              const SizedBox(width: DS.spaceSm),
            ]),
          ),
        ]),
      ),
    );
  }
}

/// Two-way segmented switch between fish and lost items.
class _Tabs extends StatelessWidget {
  const _Tabs(
      {required this.junk,
      required this.fishFound,
      required this.junkFound,
      required this.onChanged});
  final bool junk;
  final String fishFound, junkFound;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
            color: DS.surfaceMuted,
            borderRadius: BorderRadius.circular(DS.radiusControl),
            border: Border.all(color: DS.borderMedium)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          _segment('Cá', fishFound, !junk, () => onChanged(false)),
          _segment('Đồ thất lạc', junkFound, junk, () => onChanged(true)),
        ]),
      );

  Widget _segment(String label, String count, bool active, VoidCallback tap) =>
      GestureDetector(
        onTap: tap,
        child: AnimatedContainer(
          duration: DS.fastDuration,
          padding: const EdgeInsets.symmetric(
              horizontal: DS.spaceMd, vertical: DS.spaceXs),
          decoration: BoxDecoration(
              color: active ? DS.gold : Colors.transparent,
              borderRadius: BorderRadius.circular(DS.radiusMd),
              boxShadow: active
                  ? const [BoxShadow(color: DS.goldEdge, offset: Offset(0, 2))]
                  : null),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(label,
                style: TextStyle(
                    color: active ? DS.ink : DS.soft,
                    fontSize: DS.fontBody,
                    fontWeight: FontWeight.w900)),
            const SizedBox(width: DS.spaceXs),
            Text(count,
                style: TextStyle(
                    color: active ? DS.ink : DS.mutedText,
                    fontSize: DS.fontCaption,
                    fontWeight: FontWeight.w700)),
          ]),
        ),
      );
}

class _FishTile extends StatelessWidget {
  const _FishTile(
      {required this.fish,
      required this.count,
      required this.selected,
      required this.onTap});
  final FishSpecies fish;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final locked = count == 0;
    final level = _rarityLevel(fish);
    final tone = _rarityTone(fish);
    final edge = locked
        ? _mysteryEdge
        : level > 0
            ? tone
            : DS.wood;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: DS.fastDuration,
        decoration: BoxDecoration(
          gradient: locked
              ? _mysteryGradient
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _rarityFill(fish)),
          borderRadius: BorderRadius.circular(DS.radiusControl),
          border: Border.all(
              color: selected ? DS.goldEdge : edge, width: selected ? 3 : 2),
          boxShadow: [
            if (selected)
              const BoxShadow(
                  color: Color(0x99FFC24D), blurRadius: 8, spreadRadius: 1)
            else
              const BoxShadow(color: Color(0x22000000), offset: Offset(0, 2)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(DS.radiusMd),
          child: Stack(children: [
            if (level > 0 && !locked)
              Positioned.fill(child: IgnorePointer(child: _RarityAura(fish))),
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 10, 4, 6),
                child: Column(children: [
                  Expanded(
                    child: locked
                        ? _MysteryArt(fish: fish, mark: 22)
                        : CustomPaint(
                            size: Size.infinite, painter: FishingFishArt(fish)),
                  ),
                  const SizedBox(height: 2),
                  Text(locked ? '???' : fish.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: locked ? DS.gold : DS.ink,
                          fontSize: DS.fontBody,
                          fontWeight: FontWeight.w900)),
                  const SizedBox(height: 2),
                  if (!fish.isJunk)
                    _RarityStars(fish, dim: locked)
                  else
                    const SizedBox(height: 11),
                ]),
              ),
            ),
            if (!locked)
              Positioned(
                right: 5,
                top: 5,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                      color: DS.ink,
                      borderRadius: BorderRadius.circular(DS.radiusSm)),
                  child: Text('×$count',
                      style: const TextStyle(
                          color: DS.cream,
                          fontSize: DS.fontMicro,
                          fontWeight: FontWeight.w900)),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}

class _DetailPanel extends StatelessWidget {
  const _DetailPanel({required this.fish, required this.count, this.heaviest});
  final FishSpecies fish;
  final int count;
  final int? heaviest;

  String get _note => switch (fish) {
        FishSpecies.goby => 'Nhỏ nhắn, giật dây từng nhịp ngắn trong rễ đước.',
        FishSpecies.mudskipper => 'Mắt lồi ngộ nghĩnh, quẫy nhanh ở bãi bùn.',
        FishSpecies.grouper => 'Thân đốm, kéo chậm nhưng rất lì trong vịnh đá.',
        FishSpecies.butterflyfish => 'Vây vàng như cánh bướm, bơi lượn sát đá.',
        FishSpecies.cavefish =>
          'Màu nhạt, mắt tiêu giảm. Thỉnh thoảng lặn sâu.',
        FishSpecies.lanternfish => 'Chấm sáng xanh trong hang, bơi theo vòng.',
        FishSpecies.perch => 'Nhanh nhẹn, hay giật dây liên tục.',
        FishSpecies.tilapia => 'Hiền lành, hợp với người mới câu.',
        FishSpecies.carp => 'Khoẻ và lì, kéo chậm nhưng mạnh.',
        FishSpecies.catfish =>
          'Bọt nổi báo sắp lặn. Nới dây, chờ cá nổi mới kéo.',
        FishSpecies.koi => 'Lượn vòng. Vuốt ngược mũi tên để ghìm thuyền.',
        FishSpecies.goldfish => 'Nhỏ xíu mà lượn rất nhanh.',
        FishSpecies.catMew => 'Bé huyền thoại ẩn trong khúc sông tre.',
        FishSpecies.sardine => 'Cá biển nhỏ, đi theo đàn và khá dễ câu.',
        FishSpecies.mackerel => 'Nới dây lúc lao nhanh. Kéo khi cá dừng nghỉ.',
        FishSpecies.clownfish => 'Áo sọc cam trắng, lượn zíc zắc ở biển.',
        FishSpecies.pufferfish =>
          'Phồng lên thì ngừng kéo. Xẹp xuống hãy thu dây.',
        FishSpecies.flipFlop => 'Ai đó làm rơi khi lội suối.',
        FishSpecies.oldBoot => 'Đã cũ nhưng vẫn còn nguyên đế.',
        FishSpecies.tinCan => 'Nhớ nhặt rác giúp hồ sạch nhé.',
      };

  @override
  Widget build(BuildContext context) {
    final locked = count == 0;
    final level = _rarityLevel(fish);
    final tone = _rarityTone(fish);
    final (timeIcon, timeText) = _biteTime(fish);
    return Container(
      decoration: BoxDecoration(
          color: DS.surfaceRaised,
          borderRadius: BorderRadius.circular(DS.radiusLg),
          border: Border.all(
              color: level > 0 && !locked ? tone : DS.wood, width: 2.5),
          boxShadow: DS.cardShadow),
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: locked
                      ? const [Color(0xFF4A3B6B), Color(0xFF241B38)]
                      : level > 0
                          ? _rarityFill(fish)
                          : const [Color(0xFFA9DED6), Color(0xFF5BA6A2)]),
            ),
            child: Stack(children: [
              if (level > 0 && !locked)
                Positioned.fill(child: IgnorePointer(child: _RarityAura(fish))),
              for (final b in const [
                Offset(.15, .7),
                Offset(.82, .25),
                Offset(.7, .8)
              ])
                Align(
                  alignment: Alignment(b.dx * 2 - 1, b.dy * 2 - 1),
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: const Color(0x88FFFFFF), width: 1.2)),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
                child: locked
                    ? _MysteryArt(fish: fish, mark: 40)
                    : CustomPaint(
                        size: Size.infinite, painter: FishingFishArt(fish)),
              ),
              if (!locked)
                Positioned(
                  left: DS.spaceSm,
                  bottom: DS.spaceSm,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: DS.spaceSm, vertical: 2),
                    decoration: BoxDecoration(
                        color: const Color(0xCC2B1A0C),
                        borderRadius: BorderRadius.circular(DS.radiusSm)),
                    child: Text('Đã câu ×$count',
                        style: const TextStyle(
                            color: DS.cream,
                            fontSize: DS.fontCaption,
                            fontWeight: FontWeight.w900)),
                  ),
                ),
            ]),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
              DS.spaceMd, DS.spaceSm, DS.spaceMd, DS.spaceSm),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                child: Text(locked ? '???' : fish.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: DS.ink,
                        fontSize: DS.fontDisplay,
                        fontWeight: FontWeight.w900)),
              ),
              _RarityTag(fish),
            ]),
            const SizedBox(height: DS.spaceSm),
            _InfoRow(
                icon: Icons.place_rounded,
                label: 'Khu vực',
                value: fish.habitat),
            const SizedBox(height: DS.spaceXs),
            _InfoRow(
                icon: timeIcon,
                label: fish.isJunk ? 'Hay gặp' : 'Hay cắn',
                value: timeText),
            if (!fish.isJunk) ...[
              const SizedBox(height: DS.spaceXs),
              _InfoRow(
                  icon: Icons.emoji_events_rounded,
                  label: 'Nặng nhất',
                  value: heaviest == null
                      ? 'Chưa cân'
                      : formatFishWeight(heaviest!)),
              const SizedBox(height: DS.spaceXs),
              _Pips(
                  label: 'Sức kéo',
                  value: locked ? 0 : fish.pullStrength / 1.6),
              const SizedBox(height: DS.spaceXs),
              _Pips(
                  label: 'Tốc độ',
                  value: locked ? 0 : fish.movementSpeed / 1.7),
            ],
            const SizedBox(height: DS.spaceSm),
            Text(locked ? 'Chưa câu được. Ghé khu vực này để tìm nhé!' : _note,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: DS.soft,
                    fontSize: DS.fontCaption,
                    height: 1.3,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w600)),
          ]),
        ),
      ]),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(
      {required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label, value;

  @override
  Widget build(BuildContext context) => Row(children: [
        SizedBox(
          width: 58,
          child: Text(label,
              style: const TextStyle(
                  color: DS.label,
                  fontSize: DS.fontCaption,
                  fontWeight: FontWeight.w900)),
        ),
        Icon(icon, size: 14, color: DS.goldEdge),
        const SizedBox(width: DS.spaceXs),
        Expanded(
          child: Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: DS.ink,
                  fontSize: DS.fontCaption,
                  fontWeight: FontWeight.w700)),
        ),
      ]);
}

/// Five rounded pips instead of a bare bar, easier to compare at a glance.
class _Pips extends StatelessWidget {
  const _Pips({required this.label, required this.value});
  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    final filled = (value.clamp(0.0, 1.0) * 5).round();
    return Row(children: [
      SizedBox(
        width: 58,
        child: Text(label,
            style: const TextStyle(
                color: DS.label,
                fontSize: DS.fontCaption,
                fontWeight: FontWeight.w900)),
      ),
      for (var i = 0; i < 5; i++)
        Container(
          width: 16,
          height: 7,
          margin: const EdgeInsets.only(right: 3),
          decoration: BoxDecoration(
              color: i < filled ? DS.wood : DS.mutedFill,
              borderRadius: BorderRadius.circular(4)),
        ),
    ]);
  }
}

const _mysteryGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF4A3B6B), Color(0xFF2A2040)]);
const _mysteryEdge = Color(0xFF6E5A96);

/// Undiscovered entry: dark silhouette of the real shape with a glowing "?".
class _MysteryArt extends StatelessWidget {
  const _MysteryArt({required this.fish, required this.mark});
  final FishSpecies fish;
  final double mark;

  @override
  Widget build(BuildContext context) => Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: ColorFiltered(
              colorFilter:
                  const ColorFilter.mode(Color(0xFF130C22), BlendMode.srcIn),
              child: CustomPaint(painter: FishingFishArt(fish)),
            ),
          ),
          Text('?',
              style: TextStyle(
                  color: DS.gold,
                  fontSize: mark,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  shadows: const [
                    Shadow(color: Color(0xCCFFC24D), blurRadius: 10),
                    Shadow(color: DS.goldEdge, offset: Offset(0, 2)),
                  ])),
          for (final (x, y, r) in const [
            (-.9, -.8, .22),
            (.85, -.55, .16),
            (.7, .85, .12)
          ])
            Align(
              alignment: Alignment(x, y),
              child: Icon(Icons.auto_awesome_rounded,
                  size: mark * r * 2, color: const Color(0xCCFFE6A0)),
            ),
        ],
      );
}
