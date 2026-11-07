import 'package:flutter/material.dart';
import '../../collection/fish_collection.dart';
import '../../collection/fish_species.dart';
import 'fishing_fish_art.dart';
import '../design.dart';

/// Fish journal: tabbed grid on the left, details of the picked entry on
/// the right. Undiscovered entries show as silhouettes named "???".
class FishCollectionDialog extends StatefulWidget {
  const FishCollectionDialog({super.key, required this.collection});
  final FishCollection collection;

  @override
  State<FishCollectionDialog> createState() => _FishCollectionDialogState();
}

Color _rarityColor(FishSpecies fish) => switch (fish.rarity) {
      'Ít gặp' => const Color(0xFF4F8A4B),
      'Hiếm' => const Color(0xFF3A79A8),
      'Rất hiếm' => const Color(0xFF9150B0),
      'Huyền thoại' => const Color(0xFFD9932B),
      'Đồ thất lạc' => DS.mutedText,
      _ => DS.soft,
    };

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
    final found = FishSpecies.values
        .where((fish) => widget.collection.countOf(fish) > 0)
        .length;
    final total = FishSpecies.values.length;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Container(
        width: (screen.width - 48).clamp(320.0, 780.0),
        height: (screen.height * .88).clamp(260.0, 460.0),
        decoration: DS.card.copyWith(color: DS.cream),
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
        child: Column(children: [
          _Header(found: found, total: total),
          const SizedBox(height: 8),
          Expanded(
            child:
                Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Expanded(
                child: Column(children: [
                  Row(children: [
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
                  const SizedBox(height: 8),
                  Expanded(
                    child: GridView.builder(
                      padding: EdgeInsets.zero,
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 128,
                              mainAxisExtent: 112,
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
                width: 230,
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
  const _Header({required this.found, required this.total});
  final int found, total;

  @override
  Widget build(BuildContext context) => Row(children: [
        const Icon(Icons.menu_book_rounded, color: DS.wood, size: 26),
        const SizedBox(width: 8),
        const Text('BỘ SƯU TẬP', style: DS.title),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('ĐÃ KHÁM PHÁ $found/$total',
                    style: const TextStyle(
                        color: DS.label,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2)),
                const SizedBox(height: 3),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    height: 10,
                    decoration: BoxDecoration(
                        color: DS.mutedFill,
                        border: Border.all(color: DS.mutedBorder),
                        borderRadius: BorderRadius.circular(6)),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: total == 0 ? 0 : found / total,
                      child: const ColoredBox(color: DS.gold),
                    ),
                  ),
                ),
              ]),
        ),
        const SizedBox(width: 12),
        _CloseButton(onTap: () => Navigator.pop(context)),
      ]);
}

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: 'Đóng',
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                color: DS.gold,
                shape: BoxShape.circle,
                border: Border.all(color: DS.goldEdge, width: 2)),
            child: const Icon(Icons.close_rounded, color: DS.ink, size: 22),
          ),
        ),
      );
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
    final accent = locked ? _mysteryEdge : _rarityColor(fish);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          color: locked ? null : Colors.white,
          gradient: locked ? _mysteryGradient : null,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: selected ? DS.goldEdge : (locked ? _mysteryEdge : DS.wood),
              width: selected ? 3 : 2),
          boxShadow: selected
              ? const [BoxShadow(color: Color(0x66FFC24D), blurRadius: 8)]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(11),
          child: Stack(children: [
            Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: 5,
                child: ColoredBox(color: accent)),
            Positioned.fill(
              top: 5,
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                        width: 82,
                        height: 50,
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
                                fontSize: 13,
                                fontWeight: FontWeight.w900)),
                      ),
                    ),
                    Text(locked ? 'Chưa khám phá' : fish.rarity,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: locked ? _mysteryText : accent,
                            fontSize: 10,
                            fontWeight: FontWeight.w700)),
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
                      color: DS.gold,
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
    final accent = locked ? _mysteryEdge : _rarityColor(fish);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: const Color(0xFFFFFBEF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: DS.wood, width: 2)),
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
                      : const [Color(0xFF9ED8D2), Color(0xFF4E9A9A)]),
            ),
            child: Stack(children: [
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
                color: accent, borderRadius: BorderRadius.circular(8)),
            child: Text(fish.rarity,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900)),
          ),
        ]),
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
const _mysteryText = Color(0xFFB9A8D6);

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
