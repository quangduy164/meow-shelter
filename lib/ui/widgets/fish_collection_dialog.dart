import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../collection/fish_collection.dart';
import '../../collection/fish_species.dart';
import 'fishing_fish_art.dart';
import '../design.dart';
import 'game_glyphs.dart';
import 'round_button.dart';

/// Fish journal: tabbed grid on the left, details of the picked entry on
/// the right. Undiscovered entries show as silhouettes named "???".
class FishCollectionDialog extends StatefulWidget {
  const FishCollectionDialog({super.key, required this.collection});
  final FishCollection collection;

  @override
  State<FishCollectionDialog> createState() => _FishCollectionDialogState();
}

int _rarityLevel(FishSpecies fish) => switch (fish.rarity) {
      'Elite' => 1,
      'Special' => 2,
      'Epic' => 3,
      'Legend' => 4,
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
      _ => const [Color(0xFFFFFBEF), Color(0xFFF3E4C8)],
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
            light.withOpacity(.16 + level * .025),
            light.withOpacity(0),
          ]).createShader(halo));
    final pen = Paint()
      ..color = light.withOpacity(.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = level >= 3 ? 1.5 : 1;
    if (level >= 3) {
      canvas.drawRRect(
          RRect.fromRectAndRadius(rect.deflate(3), const Radius.circular(6)),
          pen..color = light.withOpacity(.55));
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
          Paint()..color = Colors.white.withOpacity(level == 4 ? .08 : .05));
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
            Paint()..color = light.withOpacity(.8 * pulse));
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

class _RarityTag extends StatelessWidget {
  const _RarityTag(this.fish);
  final FishSpecies fish;

  @override
  Widget build(BuildContext context) {
    final color = _rarityTone(fish);
    final level = _rarityLevel(fish);
    final icon = switch (level) {
      1 => Icons.shield_outlined,
      2 => Icons.diamond_outlined,
      3 => Icons.auto_awesome_rounded,
      4 => Icons.workspace_premium_rounded,
      _ => Icons.label_outline_rounded
    };
    final foreground = level == 0
        ? color
        : (level == 4 ? const Color(0xFF69350C) : Colors.white);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: level == 0
                  ? [const Color(0xFFF2EFEB), const Color(0xFFE7E1DB)]
                  : level == 4
                      ? [const Color(0xFFFFE5A1), const Color(0xFFECAF35)]
                      : [
                          Color.lerp(color, Colors.white, .1)!,
                          Color.lerp(color, Colors.black, .2)!
                        ]),
          boxShadow: level >= 3
              ? [BoxShadow(color: color.withOpacity(.25), blurRadius: 5)]
              : null,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: color)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: foreground),
        const SizedBox(width: 4),
        Text(fish.rarity,
            style: TextStyle(
                color: foreground,
                fontSize: 10,
                height: 1.1,
                fontWeight: FontWeight.w900)),
      ]),
    );
  }
}

class _FishCollectionDialogState extends State<FishCollectionDialog> {
  bool _junkTab = false;
  late FishSpecies _selected = _entries.firstWhere(
      (fish) => widget.collection.countOf(fish) > 0,
      orElse: () => _entries.first);

  List<FishSpecies> get _entries => FishSpecies.values
      .where((fish) => fish.isJunk == _junkTab)
      .toList(growable: false);

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
    final width = (screen.width - 48).clamp(320.0, 780.0);
    // Detail column takes a share of the card so narrow (4:3) screens still
    // leave room for the grid.
    final detailWidth = (width * .36).clamp(170.0, 240.0);
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Container(
        width: width,
        height: (screen.height * .88).clamp(260.0, 460.0),
        decoration: DS.card.copyWith(color: DS.cream),
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
        child: Column(children: [
          const _Header(),
          const SizedBox(height: 8),
          Expanded(
            child:
                Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Expanded(
                child: Column(children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      _TabChip(
                          label: 'Cá',
                          count: widget.collection.count,
                          active: !_junkTab,
                          onTap: () => _switchTab(false)),
                      const SizedBox(width: 8),
                      _TabChip(
                          label: 'Đồ thất lạc',
                          count: widget.collection.junkCount,
                          active: _junkTab,
                          onTap: () => _switchTab(true)),
                    ]),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: GridView.builder(
                      padding: EdgeInsets.zero,
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 170,
                              mainAxisExtent: 132,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8),
                      itemCount: _entries.length,
                      itemBuilder: (context, index) {
                        final fish = _entries[index];
                        return _FishTile(
                            fish: fish,
                            count: widget.collection.countOf(fish),
                            selected: fish == _selected,
                            onTap: () => setState(() => _selected = fish));
                      },
                    ),
                  ),
                ]),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: detailWidth,
                child: _DetailPanel(
                    fish: _selected,
                    count: widget.collection.countOf(_selected)),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) => Row(children: [
        const Icon(Icons.menu_book_rounded, color: DS.wood, size: 26),
        const SizedBox(width: 8),
        const Expanded(child: Text('BỘ SƯU TẬP', style: DS.title)),
        _CloseButton(onTap: () => Navigator.pop(context)),
      ]);
}

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) =>
      RoundButton(glyph: GameGlyph.close, size: 36, onPressed: onTap);
}

class _TabChip extends StatelessWidget {
  const _TabChip(
      {required this.label,
      required this.count,
      required this.active,
      required this.onTap});
  final String label;
  final int count;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
              color: active ? DS.gold : DS.cream,
              borderRadius: BorderRadius.circular(14),
              border:
                  Border.all(color: active ? DS.goldEdge : DS.wood, width: 2)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(label,
                style: const TextStyle(
                    color: DS.ink, fontSize: 13, fontWeight: FontWeight.w900)),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                  color: DS.ink, borderRadius: BorderRadius.circular(8)),
              child: Text('$count',
                  style: const TextStyle(
                      color: DS.cream,
                      fontSize: 11,
                      fontWeight: FontWeight.w900)),
            ),
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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          gradient: locked
              ? _mysteryGradient
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _rarityFill(fish)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: level > 0
                  ? tone
                  : (selected
                      ? DS.goldEdge
                      : (locked ? _mysteryEdge : DS.wood)),
              width: level > 0 ? (selected ? 5 : 4) : (selected ? 3 : 2)),
          boxShadow: level > 0
              ? [
                  BoxShadow(
                      color: tone.withOpacity(selected ? .3 : .15),
                      blurRadius: 4.0 + level * 2,
                      spreadRadius: selected ? 1 : 0)
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(11),
          child: Stack(children: [
            if (level > 0)
              Positioned.fill(child: IgnorePointer(child: _RarityAura(fish))),
            Positioned.fill(
              top: 8,
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                        width: 100,
                        height: 62,
                        child: locked
                            ? _MysteryArt(fish: fish, mark: 26)
                            : CustomPaint(painter: FishingFishArt(fish))),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(locked ? '???' : fish.label,
                            style: TextStyle(
                                color: locked ? DS.gold : DS.ink,
                                fontSize: 14,
                                fontWeight: FontWeight.w900)),
                      ),
                    ),
                    const SizedBox(height: 5),
                    _RarityTag(fish),
                  ]),
            ),
            if (!locked)
              Positioned(
                right: 5,
                top: 9,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                      color: DS.cream,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: DS.goldEdge, width: 1.5)),
                  child: Text('×$count',
                      style: const TextStyle(
                          color: DS.ink,
                          fontSize: 10,
                          fontWeight: FontWeight.w900)),
                ),
              ),
            if (locked)
              const Positioned(
                  right: 6,
                  top: 10,
                  child: Icon(Icons.auto_awesome_rounded,
                      size: 14, color: DS.gold)),
          ]),
        ),
      ),
    );
  }
}

class _DetailPanel extends StatelessWidget {
  const _DetailPanel({required this.fish, required this.count});
  final FishSpecies fish;
  final int count;

  String get _note => switch (fish) {
        FishSpecies.perch => 'Nhanh nhẹn, hay giật dây liên tục.',
        FishSpecies.tilapia => 'Hiền lành, hợp với người mới câu.',
        FishSpecies.carp => 'Khoẻ và lì, kéo chậm nhưng mạnh.',
        FishSpecies.catfish => 'Nặng nhất hồ, giữ dây thật chắc.',
        FishSpecies.koi => 'Vảy óng ánh, ít khi cắn câu.',
        FishSpecies.goldfish => 'Nhỏ xíu mà lượn rất nhanh.',
        FishSpecies.catMew => 'Truyền thuyết của hồ, chưa ai thấy rõ.',
        FishSpecies.flipFlop => 'Ai đó làm rơi khi lội suối.',
        FishSpecies.oldBoot => 'Đã cũ nhưng vẫn còn nguyên đế.',
        FishSpecies.tinCan => 'Nhớ nhặt rác giúp hồ sạch nhé.',
      };

  @override
  Widget build(BuildContext context) {
    final locked = count == 0;
    final level = _rarityLevel(fish);
    final tone = _rarityTone(fish);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _rarityFill(fish)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: level > 0 ? tone : DS.wood, width: level > 0 ? 4 : 2),
          boxShadow: level > 0
              ? [BoxShadow(color: tone.withOpacity(.2), blurRadius: 10)]
              : null),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Expanded(
          flex: 5,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: locked
                      ? const [Color(0xFF4A3B6B), Color(0xFF241B38)]
                      : level > 0
                          ? _rarityFill(fish)
                          : const [Color(0xFF9ED8D2), Color(0xFF4E9A9A)]),
            ),
            child: Stack(children: [
              if (level > 0)
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
              Center(
                child: SizedBox(
                    width: 150,
                    height: 90,
                    child: locked
                        ? _MysteryArt(fish: fish, mark: 46)
                        : CustomPaint(painter: FishingFishArt(fish))),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
            child: FittedBox(
              alignment: Alignment.centerLeft,
              fit: BoxFit.scaleDown,
              child: Text(locked ? '???' : fish.label,
                  style: const TextStyle(
                      color: DS.ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w900)),
            ),
          ),
        ]),
        const SizedBox(height: 6),
        Align(alignment: Alignment.centerLeft, child: _RarityTag(fish)),
        const SizedBox(height: 2),
        Text(locked ? 'Chưa câu được' : 'Đã câu: $count lần',
            style: TextStyle(
                color: locked ? DS.mutedText : DS.goldEdge,
                fontSize: 12,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        _StatBar(
            label: 'Sức kéo',
            value: locked ? 0 : (fish.pullStrength / 1.2).clamp(0.0, 1.0)),
        const SizedBox(height: 4),
        _StatBar(
            label: 'Tốc độ',
            value: locked ? 0 : (fish.movementSpeed / 1.7).clamp(0.0, 1.0)),
        const SizedBox(height: 6),
        Flexible(
          flex: 2,
          child: Text(locked ? 'Hãy tiếp tục câu để khám phá.' : _note,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: DS.soft,
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }
}

class _StatBar extends StatelessWidget {
  const _StatBar({required this.label, required this.value});
  final String label;
  final double value;

  @override
  Widget build(BuildContext context) => Row(children: [
        SizedBox(
          width: 58,
          child: Text(label,
              style: const TextStyle(
                  color: DS.label, fontSize: 11, fontWeight: FontWeight.w900)),
        ),
        Expanded(
          child: Container(
            height: 8,
            decoration: BoxDecoration(
                color: DS.mutedFill, borderRadius: BorderRadius.circular(4)),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: value,
              child: Container(
                  decoration: BoxDecoration(
                      color: DS.wood, borderRadius: BorderRadius.circular(4))),
            ),
          ),
        ),
      ]);
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
