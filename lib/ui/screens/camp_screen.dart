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
  CampState get camp => CampState.instance;

  @override
  void initState() {
    super.initState();
    for (final type in camp.residents) {
      _cats.add(CampResident(type, _random.nextDouble() * .7 + .1,
          _random.nextDouble() * .25 + .64));
    }
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
                Builder(builder: (context) {
                  final (x, y) = camp.positionOf(item);
                  final dragging = _dragging == item.id;
                  return Positioned(
                    left: w * x - 30 * item.scale,
                    top: h * y - 30 * item.scale,
                    // Drag to rearrange; the spot is saved when released.
                    child: GestureDetector(
                      onPanStart: (_) => setState(() => _dragging = item.id),
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
                              child: FittedBox(child: _DecorationArt(item.id))),
                        ),
                      ),
                    ),
                  );
                }),
            for (final cat in _cats..sort((a, b) => a.y.compareTo(b.y)))
              Positioned(
                left: w * cat.x - 40,
                top: h * cat.y - 60,
                // Tap to pet; drag to pick the cat up and carry it.
                child: GestureDetector(
                  onTap: () => _pet(cat),
                  onPanStart: (_) => setState(cat.pickUp),
                  onPanUpdate: (d) => setState(() {
                    cat.x = (cat.x + d.delta.dx / w).clamp(.03, .97);
                    cat.y = (cat.y + d.delta.dy / h).clamp(.3, .95);
                  }),
                  onPanEnd: (_) => setState(cat.drop),
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
                    ElevatedButton.icon(
                      onPressed: _openShop,
                      icon: const Icon(Icons.storefront_rounded),
                      label: const Text('CỬA HÀNG'),
                      style: DS.primary,
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _openCats,
                      icon: const Icon(Icons.favorite_rounded),
                      label: const Text('CÁC BÉ'),
                      style: DS.secondary,
                    ),
                  ]),
                ),
              ),
            ),
          ]);
        }),
      );

  void _openShop() => showDialog<void>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, refresh) => AlertDialog(
            backgroundColor: DS.cream,
            shape: DS.dialogShape,
            title: Text('CỬA HÀNG · ${camp.coins} xu', style: DS.title),
            content: SizedBox(
              width: 420,
              child: ListView(shrinkWrap: true, children: [
                for (final item in CampDecoration.all)
                  ListTile(
                    leading: SizedBox(
                        width: 48,
                        child: FittedBox(child: _DecorationArt(item.id))),
                    title: Text(item.name,
                        style: const TextStyle(
                            color: DS.ink, fontWeight: FontWeight.w800)),
                    trailing: camp.owned.contains(item.id)
                        ? const Text('Đã có',
                            style: TextStyle(color: Color(0xFF6B9E4E)))
                        : ElevatedButton(
                            style: DS.primary,
                            onPressed: camp.coins < item.price
                                ? null
                                : () async {
                                    await camp.buy(item);
                                    refresh(() {});
                                    setState(() {});
                                  },
                            child: Text('${item.price} xu')),
                  ),
              ]),
            ),
          ),
        ),
      );

  void _openCats() => showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: DS.cream,
          shape: DS.dialogShape,
          title: const Text('CÁC BÉ MÈO', style: DS.title),
          content: SizedBox(
            width: 420,
            child: ListView(shrinkWrap: true, children: [
              for (final type in CatBreed.all.map((b) => b.id))
                ListTile(
                  leading: Opacity(
                      opacity: camp.unlocked(type) ? 1 : .3,
                      child: CatSprite(type: type, size: 44)),
                  title: Text(CatBreed.of(type).name,
                      style: const TextStyle(
                          color: DS.ink, fontWeight: FontWeight.w800)),
                  subtitle: Text(camp.unlocked(type)
                      ? 'Thân thiết ${camp.affection[type] ?? 0}/${CampState.bondedAffection}'
                          '${camp.bonded(type) ? ' · kỹ năng hồi nhanh 1s' : ''}'
                      : 'Cứu bé trong chế độ Bắt mèo để mở'),
                ),
            ]),
          ),
        ),
      );
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
