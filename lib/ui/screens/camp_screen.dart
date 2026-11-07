import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../camp/camp_state.dart';
import '../../camp/camp_room_painter.dart';
import '../../camp/camp_resident.dart';
import '../../game/cats/cat_breed.dart';
import '../widgets/cat_sprite.dart';
import '../../camp/camp_decor_painter.dart';
import '../design.dart';
import '../widgets/round_button.dart';

/// The cat camp: rescued cats wander the yard, the player pets them and buys
/// decorations with coins earned in every other mode.
class CampScreen extends StatefulWidget {
  const CampScreen({super.key});

  @override
  State<CampScreen> createState() => _CampScreenState();
}

class _CampScreenState extends State<CampScreen>
    with SingleTickerProviderStateMixin {
  final _random = Random();
  final _cats = <CampResident>[];
  late final Ticker _tick;
  Duration _last = Duration.zero;
  String? _dragging;
  CampResident? _carried;
  _Panel _panel = _Panel.none;
  CampState get camp => CampState.instance;

  /// Adds a resident for every owned breed that is not in the room yet
  /// (on open, and right after a cat is bought).
  void _syncResidents() {
    for (final type in camp.residents) {
      if (_cats.any((cat) => cat.type == type)) continue;
      _cats.add(CampResident(type, _random.nextDouble() * .7 + .1,
          _random.nextDouble() * .25 + .64));
    }
  }

  @override
  void initState() {
    super.initState();
    _syncResidents();
    // Per-frame updates keep the walk smooth instead of stepping 8 times/s.
    _tick = createTicker((elapsed) {
      final dt = ((elapsed - _last).inMicroseconds / 1e6).clamp(0.0, .1);
      _last = elapsed;
      // Floor toys the cats can visit (wall items are out of reach).
      final toys = [
        for (final item in CampDecoration.all)
          if (camp.owned.contains(item.id) && campToyActs.containsKey(item.id))
            (item.id, camp.positionOf(item).$1, camp.positionOf(item).$2),
      ];
      for (final cat in _cats) {
        cat.update(dt, _random, toys);
      }
      setState(() {});
    })
      ..start();
  }

  @override
  void dispose() {
    _tick.dispose();
    super.dispose();
  }

  Future<void> _pet(CampResident cat) async {
    cat.pet();
    await camp.pet(cat.type);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: LayoutBuilder(builder: (context, box) {
          final w = box.maxWidth, h = box.maxHeight;
          // Expand so the yard fills the screen; a loose Stack would shrink to
          // the height of the top bar and leave the rest blank.
          return Stack(fit: StackFit.expand, children: [
            Positioned.fill(
                child: CustomPaint(
                    painter: CampRoomPainter(hour: DateTime.now().hour))),
            for (final item in [
              ...CampDecoration.all.where((d) => d.id == 'rug'),
              ...CampDecoration.all.where((d) => d.id != 'rug'),
            ])
              if (camp.owned.contains(item.id))
                Builder(
                    key: ValueKey(item.id),
                    builder: (context) {
                      final (x, y) = camp.positionOf(item);
                      final dragging = _dragging == item.id;
                      return Positioned(
                        left: w * x - 30 * item.scale,
                        top: h * y - 30 * item.scale,
                        // Drag to rearrange; the spot is saved when released.
                        child: GestureDetector(
                          onPanStart: (_) =>
                              setState(() => _dragging = item.id),
                          onPanUpdate: (d) =>
                              setState(() => camp.placement[item.id] = (
                                    (x + d.delta.dx / w).clamp(.03, .97),
                                    (y + d.delta.dy / h).clamp(.05, .95),
                                  )),
                          onPanEnd: (_) {
                            final (nx, ny) = camp.positionOf(item);
                            camp.place(item.id, nx, ny);
                            setState(() => _dragging = null);
                          },
                          child: AnimatedScale(
                            scale: dragging ? 1.08 : 1,
                            duration: const Duration(milliseconds: 120),
                            child: Opacity(
                              opacity: dragging ? .85 : 1,
                              child: SizedBox.square(
                                  dimension: 60 * item.scale,
                                  child: FittedBox(
                                      child: _DecorationArt(item.id))),
                            ),
                          ),
                        ),
                      );
                    }),
            // Cats are re-sorted by depth every frame; the key keeps each
            // cat's gesture (pet / carry) attached to the same cat.
            for (final cat in _cats..sort((a, b) => a.y.compareTo(b.y)))
              Positioned(
                key: ObjectKey(cat),
                left: w * cat.x - 40,
                top: h * cat.y - 60,
                // Tap to pet; drag to pick the cat up and carry it.
                child: GestureDetector(
                  onTap: () => _pet(cat),
                  // Only one cat can be carried at a time.
                  onPanStart: (_) {
                    if (_carried != null && _carried != cat) return;
                    setState(() {
                      _carried = cat;
                      cat.pickUp();
                    });
                  },
                  onPanUpdate: (d) => _carried != cat
                      ? null
                      : setState(() {
                          cat.x = (cat.x + d.delta.dx / w).clamp(.03, .97);
                          cat.y = (cat.y + d.delta.dy / h).clamp(.3, .95);
                        }),
                  onPanEnd: (_) {
                    if (_carried != cat) return;
                    setState(() {
                      _carried = null;
                      cat.drop();
                    });
                  },
                  onPanCancel: () {
                    if (_carried != cat) return;
                    setState(() {
                      _carried = null;
                      cat.drop();
                    });
                  },
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    SizedBox(
                        height: 20,
                        child: cat.heart > 0
                            ? const Icon(Icons.favorite,
                                color: Color(0xFFE85D6F), size: 18)
                            : null),
                    CatSprite(
                        type: cat.type,
                        action: cat.act.sheet,
                        frames: cat.act.frames,
                        frame: cat.frame,
                        flip: cat.facingLeft),
                  ]),
                ),
              ),
            // Tapping anywhere outside an open panel closes it.
            if (_panel != _Panel.none)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _panel = _Panel.none),
                ),
              ),
            // Panels slide up from the bottom; the room stays visible above.
            for (final (panel, child) in [
              (
                _Panel.shop,
                _ShopBar(
                  onBought: () => setState(_syncResidents),
                  onClose: () => setState(() => _panel = _Panel.none),
                ) as Widget,
              ),
              (
                _Panel.cats,
                _BondBar(onClose: () => setState(() => _panel = _Panel.none)),
              ),
            ])
              AnimatedPositioned(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                left: 0,
                right: 0,
                bottom: _panel == panel ? 0 : -(h * .36 + 20),
                height: h * .36,
                child: child,
              ),
            Align(
              alignment: Alignment.topCenter,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(children: [
                    RoundButton(
                        icon: Icons.arrow_back_rounded,
                        onPressed: () => Navigator.of(context).pop()),
                    const SizedBox(width: 12),
                    _Chip(Icons.monetization_on_rounded, '${camp.coins}',
                        const Color(0xFFE7A72F)),
                    const SizedBox(width: 8),
                    _Chip(Icons.pets_rounded, '${_cats.length} bé',
                        const Color(0xFFD9822B)),
                    const Spacer(),
                    _PanelButton(
                      label: 'CỬA HÀNG',
                      icon: _CampIcon.shop,
                      active: _panel == _Panel.shop,
                      onTap: () => _toggle(_Panel.shop),
                    ),
                    const SizedBox(width: 8),
                    _PanelButton(
                      label: 'THÂN THIẾT',
                      icon: _CampIcon.heart,
                      active: _panel == _Panel.cats,
                      onTap: () => _toggle(_Panel.cats),
                    ),
                  ]),
                ),
              ),
            ),
          ]);
        }),
      );

  void _toggle(_Panel p) =>
      setState(() => _panel = _panel == p ? _Panel.none : p);
}

class _Chip extends StatelessWidget {
  const _Chip(this.icon, this.text, this.color);
  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
            color: const Color(0xEEFFF4DA),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFB27A3E), width: 2)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 6),
          Text(text,
              style:
                  const TextStyle(fontWeight: FontWeight.w900, color: DS.ink)),
        ]),
      );
}

/// Simple painted art for each decoration, sized 60x60.
class _DecorationArt extends StatelessWidget {
  const _DecorationArt(this.id);
  final String id;

  @override
  Widget build(BuildContext context) => SizedBox(
      width: 60, height: 60, child: CustomPaint(painter: CampDecorPainter(id)));
}

/// Compact shop docked at the bottom: one row of category chips and a
/// horizontal strip of item cards. Coins are shown in the camp top bar.
class _ShopBar extends StatefulWidget {
  const _ShopBar({required this.onBought, required this.onClose});
  final VoidCallback onBought;
  final VoidCallback onClose;

  @override
  State<_ShopBar> createState() => _ShopBarState();
}

class _ShopBarState extends State<_ShopBar> {
  /// Selected section; null is the cats tab.
  CampCategory? _tab;
  CampState get camp => CampState.instance;

  @override
  Widget build(BuildContext context) {
    final items = [
      for (final d in CampDecoration.all)
        if (d.cat == _tab) d
    ];
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xF2FFF4DA),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: DS.wood, width: 3)),
        boxShadow: [BoxShadow(color: Color(0x55000000), blurRadius: 10)],
      ),
      child: SafeArea(
        top: false,
        child: Column(children: [
          SizedBox(
            height: 40,
            child: Row(children: [
              Expanded(
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(10, 6, 0, 2),
                  children: [
                    _chip(null),
                    for (final c in CampCategory.values) _chip(c),
                  ],
                ),
              ),
              IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: widget.onClose,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded,
                      color: DS.ink)),
            ]),
          ),
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(10, 4, 10, 8),
              children: _tab == null
                  ? [
                      for (final breed in CatBreed.all)
                        if (breed.id != 'orange') _catCard(breed)
                    ]
                  : [for (final item in items) _card(item)],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _chip(CampCategory? c) {
    final on = c == _tab;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        selected: on,
        onSelected: (_) => setState(() => _tab = c),
        avatar: Icon(c == null ? Icons.pets_rounded : _categoryIcons[c],
            size: 16, color: DS.ink),
        label: Text(c?.label ?? 'Mèo'),
        showCheckmark: false,
        visualDensity: VisualDensity.compact,
        labelStyle: const TextStyle(
            color: DS.ink, fontWeight: FontWeight.w800, fontSize: 12),
        backgroundColor: DS.cream,
        selectedColor: DS.gold,
        side: BorderSide(color: on ? DS.goldEdge : DS.wood, width: 1.5),
        shape: const StadiumBorder(),
      ),
    );
  }

  /// A breed for sale: face, catch trait and price.
  Widget _catCard(CatBreed breed) {
    final owned = camp.unlocked(breed.id);
    final price = CampState.catPrices[breed.id] ?? 0;
    final afford = camp.coins >= price;
    return Container(
      width: 190,
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: owned ? const Color(0xFFEDE6D2) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: owned ? DS.mutedBorder : DS.wood, width: 2),
      ),
      child: Row(children: [
        AspectRatio(
          aspectRatio: 1,
          child: FittedBox(
              child: CatFace(breed.id,
                  background: const Color(0xFFFFE3B0), border: DS.wood)),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(breed.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: DS.ink,
                      fontWeight: FontWeight.w900,
                      fontSize: 12.5)),
              Text(breed.catchRule.trait,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: DS.soft, fontSize: 10.5)),
              const SizedBox(height: 3),
              SizedBox(
                height: 26,
                width: double.infinity,
                child: owned
                    ? const Align(
                        alignment: Alignment.centerLeft,
                        child: Text('✓ Đang ở trại',
                            style: TextStyle(
                                color: Color(0xFF6B9E4E),
                                fontSize: 12,
                                fontWeight: FontWeight.w800)))
                    : ElevatedButton.icon(
                        style: DS.primary.copyWith(
                            padding:
                                const WidgetStatePropertyAll(EdgeInsets.zero),
                            textStyle: const WidgetStatePropertyAll(TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w900))),
                        onPressed: afford
                            ? () async {
                                await camp.buyCat(breed.id);
                                setState(() {});
                                widget.onBought();
                              }
                            : null,
                        icon:
                            const Icon(Icons.monetization_on_rounded, size: 14),
                        label: Text('$price')),
              ),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _card(CampDecoration item) {
    final owned = camp.owned.contains(item.id);
    final afford = camp.coins >= item.price;
    return Container(
      width: 176,
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: owned ? const Color(0xFFEDE6D2) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: owned ? DS.mutedBorder : DS.wood, width: 2),
      ),
      // Art on the left keeps it large even on short screens.
      child: Row(children: [
        AspectRatio(
            aspectRatio: 1, child: FittedBox(child: _DecorationArt(item.id))),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: DS.ink,
                      fontWeight: FontWeight.w800,
                      fontSize: 12)),
              const SizedBox(height: 4),
              SizedBox(
                height: 26,
                width: double.infinity,
                child: owned
                    ? const Align(
                        alignment: Alignment.centerLeft,
                        child: Text('✓ Đã có',
                            style: TextStyle(
                                color: Color(0xFF6B9E4E),
                                fontSize: 12,
                                fontWeight: FontWeight.w800)))
                    : ElevatedButton.icon(
                        style: DS.primary.copyWith(
                            padding:
                                const WidgetStatePropertyAll(EdgeInsets.zero),
                            textStyle: const WidgetStatePropertyAll(TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w900))),
                        onPressed: afford
                            ? () async {
                                await camp.buy(item);
                                setState(() {});
                                widget.onBought();
                              }
                            : null,
                        icon:
                            const Icon(Icons.monetization_on_rounded, size: 14),
                        label: Text('${item.price}')),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

const _categoryIcons = {
  CampCategory.toys: Icons.toys_rounded,
  CampCategory.beds: Icons.bed_rounded,
  CampCategory.furniture: Icons.weekend_rounded,
  CampCategory.wall: Icons.photo_rounded,
  CampCategory.plants: Icons.local_florist_rounded,
};

enum _Panel { none, shop, cats }

enum _CampIcon { shop, heart }

/// Top-bar toggle for a bottom panel, with a hand-drawn icon.
class _PanelButton extends StatelessWidget {
  const _PanelButton(
      {required this.label,
      required this.icon,
      required this.active,
      required this.onTap});
  final String label;
  final _CampIcon icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: active ? DS.gold : DS.cream,
        shape: StadiumBorder(
            side: BorderSide(color: active ? DS.goldEdge : DS.wood, width: 2)),
        elevation: 2,
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(6, 4, 14, 4),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              SizedBox.square(
                  dimension: 30,
                  child: CustomPaint(painter: _CampIconPainter(icon))),
              const SizedBox(width: 6),
              Text(label,
                  style: const TextStyle(
                      color: DS.ink,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .5)),
            ]),
          ),
        ),
      );
}

/// Shop: a little market stall with a striped awning and a fish sign.
/// Heart: a plump heart with a paw print and a shine.
class _CampIconPainter extends CustomPainter {
  const _CampIconPainter(this.icon);
  final _CampIcon icon;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 30, size.height / 30);
    Paint p(int c) => Paint()..color = Color(c);
    if (icon == _CampIcon.shop) {
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              const Rect.fromLTWH(5, 12, 20, 15), const Radius.circular(2)),
          p(0xFFE7C3A3));
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              const Rect.fromLTWH(12, 17, 7, 10), const Radius.circular(2)),
          p(0xFF8C5A34));
      canvas.drawRect(const Rect.fromLTWH(7, 16, 4, 4), p(0xFF7FB3C7));
      for (var i = 0; i < 5; i++) {
        final x = 3.0 + i * 4.8;
        canvas.drawPath(
            Path()
              ..moveTo(x, 6)
              ..lineTo(x + 4.8, 6)
              ..lineTo(x + 4.8, 11)
              ..arcToPoint(Offset(x, 11), radius: const Radius.circular(2.4))
              ..close(),
            p(i.isEven ? 0xFFE0533F : 0xFFFFF4DA));
      }
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              const Rect.fromLTWH(3, 3.5, 24, 3), const Radius.circular(1.5)),
          p(0xFF8C5A34));
      canvas.drawOval(
          Rect.fromCenter(center: const Offset(23, 20), width: 5, height: 3),
          p(0xFFF28A3A));
    } else {
      final heart = Path()
        ..moveTo(15, 26)
        ..cubicTo(2, 18, 3, 6, 10, 6)
        ..cubicTo(13, 6, 15, 9, 15, 10)
        ..cubicTo(15, 9, 17, 6, 20, 6)
        ..cubicTo(27, 6, 28, 18, 15, 26)
        ..close();
      canvas.drawPath(heart.shift(const Offset(0, 1.2)), p(0xFFA8323F));
      canvas.drawPath(heart, p(0xFFE85D6F));
      canvas.drawOval(
          Rect.fromCenter(center: const Offset(9.5, 10), width: 5, height: 3),
          p(0x99FFFFFF));
      final pad = p(0xFFFFF4DA);
      canvas.drawOval(
          Rect.fromCenter(center: const Offset(15, 17), width: 6, height: 4.5),
          pad);
      for (final d in const [
        Offset(11.6, 13.6),
        Offset(14, 12),
        Offset(16, 12),
        Offset(18.4, 13.6)
      ]) {
        canvas.drawCircle(d, 1.2, pad);
      }
    }
  }

  @override
  bool shouldRepaint(_CampIconPainter oldDelegate) => oldDelegate.icon != icon;
}

/// Bond panel: one card per breed with its face, a heart meter toward the
/// bonus, and what the bond unlocks. Locked breeds show how to get them.
class _BondBar extends StatelessWidget {
  const _BondBar({required this.onClose});
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final camp = CampState.instance;
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xF2FFF4DA),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: DS.wood, width: 3)),
        boxShadow: [BoxShadow(color: Color(0x55000000), blurRadius: 10)],
      ),
      child: SafeArea(
        top: false,
        child: Column(children: [
          SizedBox(
            height: 36,
            child: Row(children: [
              const SizedBox(width: 14),
              const Text('ĐỘ THÂN THIẾT',
                  style: TextStyle(
                      color: DS.ink,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1)),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                    'Chạm vào bé để vuốt ve · đủ 10 ♥ thì kỹ năng hồi nhanh 1s',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: DS.soft, fontSize: 11)),
              ),
              IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: onClose,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded,
                      color: DS.ink)),
            ]),
          ),
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
              children: [
                for (final breed in CatBreed.all) _card(camp, breed),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _card(CampState camp, CatBreed breed) {
    final unlocked = camp.unlocked(breed.id);
    final love =
        (camp.affection[breed.id] ?? 0).clamp(0, CampState.bondedAffection);
    final bonded = camp.bonded(breed.id);
    return Container(
      width: 190,
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: unlocked ? Colors.white : const Color(0xFFEDE6D2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: bonded
                ? DS.goldEdge
                : unlocked
                    ? DS.wood
                    : DS.mutedBorder,
            width: bonded ? 3 : 2),
      ),
      child: Row(children: [
        Opacity(
          opacity: unlocked ? 1 : .35,
          child: AspectRatio(
            aspectRatio: 1,
            child: Stack(children: [
              Positioned.fill(
                child: FittedBox(
                    child: CatFace(breed.id,
                        background: const Color(0xFFFFE3B0),
                        border: bonded ? DS.goldEdge : DS.wood)),
              ),
              if (bonded)
                const Positioned(
                    right: 0,
                    top: 0,
                    child: Icon(Icons.star_rounded, color: DS.star, size: 18)),
            ]),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(breed.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: DS.ink,
                      fontWeight: FontWeight.w900,
                      fontSize: 13)),
              const SizedBox(height: 1),
              if (!unlocked)
                const Row(children: [
                  Icon(Icons.lock_rounded, size: 13, color: DS.mutedText),
                  SizedBox(width: 3),
                  Expanded(
                    child: Text('Mua ở cửa hàng',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: DS.mutedText, fontSize: 11)),
                  ),
                ])
              else ...[
                // Ten small hearts fill up as affection grows.
                Wrap(spacing: 1, children: [
                  for (var i = 0; i < CampState.bondedAffection; i++)
                    Icon(Icons.favorite_rounded,
                        size: 10,
                        color: i < love
                            ? const Color(0xFFE85D6F)
                            : const Color(0x33A8323F)),
                ]),
                const SizedBox(height: 1),
                Text(
                    bonded
                        ? 'Thân thiết · ${breed.homeSkill.label} -1s'
                        : '$love/${CampState.bondedAffection} ♥',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: bonded ? DS.goldEdge : DS.soft,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ],
            ],
          ),
        ),
      ]),
    );
  }
}
