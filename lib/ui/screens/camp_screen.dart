import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../camp/camp_state.dart';
import '../../game/world/shelter_garden_painter.dart';
import '../design.dart';
import '../widgets/round_button.dart';

/// The cat camp: rescued cats wander the yard, the player pets them and buys
/// decorations with coins earned in every other mode.
class CampScreen extends StatefulWidget {
  const CampScreen({super.key});

  @override
  State<CampScreen> createState() => _CampScreenState();
}

class _CampScreenState extends State<CampScreen> {
  final _random = Random();
  final _cats = <_Resident>[];
  late final Timer _tick;
  CampState get camp => CampState.instance;

  @override
  void initState() {
    super.initState();
    for (final type in camp.residents) {
      _cats.add(_Resident(type, _random.nextDouble() * .7 + .1,
          _random.nextDouble() * .35 + .45));
    }
    _tick = Timer.periodic(const Duration(milliseconds: 120), (_) {
      for (final cat in _cats) {
        cat.step(_random);
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tick.cancel();
    super.dispose();
  }

  Future<void> _pet(_Resident cat) async {
    cat.heart = 10;
    await camp.pet(cat.type);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: LayoutBuilder(builder: (context, box) {
          final w = box.maxWidth, h = box.maxHeight;
          return Stack(children: [
            const Positioned.fill(
                child: CustomPaint(painter: ShelterGardenPainter())),
            for (final item in CampDecoration.all)
              if (camp.owned.contains(item.id))
                Positioned(
                    left: w * item.x - 30,
                    top: h * item.y - 30,
                    child: _DecorationArt(item.id)),
            for (final cat in _cats..sort((a, b) => a.y.compareTo(b.y)))
              Positioned(
                left: w * cat.x - 40,
                top: h * cat.y - 60,
                child: GestureDetector(
                  onTap: () => _pet(cat),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    SizedBox(
                        height: 20,
                        child: cat.heart > 0
                            ? const Icon(Icons.favorite,
                                color: Color(0xFFE85D6F), size: 18)
                            : null),
                    _CatSprite(
                        type: cat.type,
                        walking: cat.moving,
                        frame: cat.frame,
                        flip: cat.dx < 0),
                  ]),
                ),
              ),
            SafeArea(
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
              for (final type in CampState.catTypes)
                ListTile(
                  leading: Opacity(
                      opacity: camp.unlocked(type) ? 1 : .3,
                      child: _CatSprite(
                          type: type, walking: false, frame: 0, size: 44)),
                  title: Text(CampState.catNames[type]!,
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

class _Resident {
  _Resident(this.type, this.x, this.y);
  final String type;
  double x, y;
  double dx = 0, dy = 0;
  int frame = 0, rest = 0, heart = 0;
  bool get moving => dx != 0 || dy != 0;

  void step(Random random) {
    frame = (frame + 1) % 6;
    if (heart > 0) heart -= 1;
    if (rest > 0) {
      rest -= 1;
      if (rest == 0) {
        dx = (random.nextDouble() - .5) * .012;
        dy = (random.nextDouble() - .5) * .005;
      }
      return;
    }
    x = (x + dx).clamp(.06, .94);
    y = (y + dy).clamp(.42, .88);
    if (random.nextDouble() < .03) {
      dx = dy = 0;
      rest = 15 + random.nextInt(30);
    }
  }
}

/// One frame of a cat sprite sheet (6 frames of 256px side by side).
class _CatSprite extends StatelessWidget {
  const _CatSprite(
      {required this.type,
      required this.walking,
      required this.frame,
      this.flip = false,
      this.size = 80});
  final String type;
  final bool walking;
  final int frame;
  final bool flip;
  final double size;

  @override
  Widget build(BuildContext context) {
    final folder = type[0].toUpperCase() + type.substring(1);
    final sheet = walking ? 'walk' : 'idle';
    return Transform.flip(
      flipX: flip,
      child: SizedBox(
        width: size,
        height: size,
        child: ClipRect(
          child: OverflowBox(
            maxWidth: size * 6,
            maxHeight: size,
            alignment: Alignment(-1 + 2 * frame / 5, 0),
            child: Image.asset('assets/images/Cat/$folder/cat-$type-$sheet.png',
                width: size * 6, height: size, fit: BoxFit.fill),
          ),
        ),
      ),
    );
  }
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
      width: 60, height: 60, child: CustomPaint(painter: _DecorPainter(id)));
}

class _DecorPainter extends CustomPainter {
  _DecorPainter(this.id);
  final String id;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    canvas.drawOval(
        Rect.fromCenter(center: c + const Offset(0, 22), width: 50, height: 10),
        Paint()..color = const Color(0x334B392C));
    Paint p(int color) => Paint()..color = Color(color);
    switch (id) {
      case 'yarn':
        canvas.drawCircle(c + const Offset(0, 10), 13, p(0xFFE3A2A4));
        canvas.drawArc(
            Rect.fromCircle(center: c + const Offset(0, 10), radius: 9),
            -1,
            2.4,
            false,
            p(0xFFBE7F88)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2);
      case 'flowers':
        canvas.drawRect(
            Rect.fromCenter(
                center: c + const Offset(0, 14), width: 22, height: 16),
            p(0xFFC0714A));
        for (var i = -1; i <= 1; i++) {
          canvas.drawCircle(
              c + Offset(i * 9.0, -2), 6, p(i == 0 ? 0xFFFFE07A : 0xFFFF9CA8));
        }
      case 'bed':
        canvas.drawOval(
            Rect.fromCenter(
                center: c + const Offset(0, 12), width: 52, height: 22),
            p(0xFF9A6A4A));
        canvas.drawOval(
            Rect.fromCenter(
                center: c + const Offset(0, 10), width: 40, height: 14),
            p(0xFFF2C7A0));
      case 'post':
        canvas.drawRect(
            Rect.fromCenter(
                center: c + const Offset(0, 22), width: 34, height: 8),
            p(0xFF8C6245));
        canvas.drawRect(
            Rect.fromCenter(
                center: c + const Offset(0, 0), width: 12, height: 40),
            p(0xFFD8B47A));
        canvas.drawRect(
            Rect.fromCenter(
                center: c + const Offset(0, -22), width: 30, height: 8),
            p(0xFF8C6245));
      case 'lantern':
        canvas.drawLine(c + const Offset(0, -26), c + const Offset(0, -16),
            p(0xFF5A3214)..strokeWidth = 2);
        canvas.drawOval(
            Rect.fromCenter(center: c, width: 30, height: 34), p(0xFFE0533F));
        canvas.drawCircle(c, 8, p(0x99FFE7A0));
      case 'bowl':
        canvas.drawOval(
            Rect.fromCenter(
                center: c + const Offset(0, 6), width: 46, height: 36),
            p(0x996FB6CE));
        canvas.drawOval(
            Rect.fromCenter(
                center: c + const Offset(-4, 8), width: 14, height: 8),
            p(0xFFF08A3A));
      case 'house':
        canvas.drawRect(
            Rect.fromCenter(
                center: c + const Offset(0, 10), width: 44, height: 30),
            p(0xFFE7C3A3));
        canvas.drawPath(
            Path()
              ..moveTo(c.dx - 28, c.dy - 5)
              ..lineTo(c.dx, c.dy - 28)
              ..lineTo(c.dx + 28, c.dy - 5)
              ..close(),
            p(0xFFB4533F));
        canvas.drawOval(
            Rect.fromCenter(
                center: c + const Offset(0, 16), width: 16, height: 18),
            p(0xFF5A3A2A));
    }
  }

  @override
  bool shouldRepaint(_DecorPainter old) => old.id != id;
}
