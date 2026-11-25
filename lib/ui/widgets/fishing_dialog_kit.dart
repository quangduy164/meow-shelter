import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../camp/camp_state.dart';
import '../../collection/fish_species.dart';
import '../design.dart';
import 'fishing_fish_art.dart';

/// Shared look for every fishing-mode panel: one header, one fish tile and
/// one reward card, so shops, chests and the cave run feel like one game.

const fishingWood = Color(0xFF8A5A33);
const fishingGold = Color(0xFFE2A93B);

/// Icon badge, title, optional trailing widget (coins, progress) and close.
class FishingDialogHeader extends StatelessWidget {
  const FishingDialogHeader(
      {super.key,
      required this.icon,
      required this.title,
      required this.onClose,
      this.subtitle,
      this.trailing});
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) => Row(children: [
        Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFFE7A8),
                border: Border.all(color: fishingGold, width: 2)),
            child: Icon(icon, color: fishingWood, size: 22)),
        const SizedBox(width: 10),
        Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
              Text(title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: DS.ink,
                      fontSize: DS.fontTitle,
                      fontWeight: FontWeight.w900)),
              if (subtitle != null)
                Text(subtitle!,
                    style: const TextStyle(
                        color: fishingWood,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
            ])),
        if (trailing != null) ...[trailing!, const SizedBox(width: 4)],
        IconButton(
            tooltip: 'Đóng',
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded, color: DS.ink)),
      ]);
}

/// The player's coins in a small gold pill.
class FishingCoinPill extends StatelessWidget {
  const FishingCoinPill({super.key});
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.fromLTRB(6, 4, 12, 4),
      decoration: BoxDecoration(
          color: const Color(0xFFFFE7A8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: DS.goldEdge, width: 1.5)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.monetization_on_rounded, color: fishingGold, size: 20),
        const SizedBox(width: 4),
        Text('${CampState.instance.coins}',
            style: const TextStyle(
                color: DS.ink, fontWeight: FontWeight.w900, fontSize: 16)),
      ]));
}

/// Frame colours by rarity; [wanted] marks the market's order of the day.
List<Color> fishingRarityFrame(FishSpecies fish, {bool wanted = false}) =>
    wanted
        ? const [Color(0xFFFFB58A), Color(0xFFE8704A)]
        : switch (fish.rarity) {
            'Hiếm' => const [Color(0xFFA8DDF0), Color(0xFF5EB1D6)],
            'Quý' => const [Color(0xFFC8E8A2), Color(0xFF7DBE57)],
            'Cực hiếm' => const [Color(0xFFE3C2F2), Color(0xFFB27BD6)],
            'Huyền thoại' => const [Color(0xFFFFE9A0), Color(0xFFE2A93B)],
            _ => const [Color(0xFFF4E4C4), Color(0xFFD9BE8C)],
          };

/// A fish in an item frame tinted by rarity, with an optional count badge
/// and caption underneath (price, name...).
class FishingFishTile extends StatelessWidget {
  const FishingFishTile(
      {super.key,
      required this.fish,
      this.count,
      this.caption,
      this.wanted = false,
      this.shield = false,
      this.onTap,
      this.tooltip,
      this.width = 70,
      this.height = 56});
  final FishSpecies fish;
  final int? count;
  final Widget? caption;
  final bool wanted, shield;
  final VoidCallback? onTap;
  final String? tooltip;
  final double width, height;

  @override
  Widget build(BuildContext context) {
    Widget tile = SizedBox(
        width: width,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(
              width: width,
              height: height,
              child: Stack(clipBehavior: Clip.none, children: [
                Positioned.fill(
                    child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                            gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors:
                                    fishingRarityFrame(fish, wanted: wanted)),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: const Color(0xFF774016), width: 2),
                            boxShadow: const [
                              BoxShadow(
                                  color: Color(0x33402616),
                                  offset: Offset(0, 2))
                            ]),
                        child: Container(
                            decoration: BoxDecoration(
                                color: const Color(0xFFFFF8E8),
                                borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.all(3),
                            child:
                                CustomPaint(painter: FishingFishArt(fish))))),
                if (count != null)
                  Positioned(
                      right: -6,
                      top: -6,
                      child: FishingBadge('×$count', const Color(0xFF31586C))),
                if (shield)
                  const Positioned(
                      left: -6,
                      top: -6,
                      child: Icon(Icons.shield_rounded,
                          size: 18, color: Color(0xFF6B5BB5))),
              ])),
          if (caption != null) ...[const SizedBox(height: 3), caption!],
        ]));
    if (onTap != null || tooltip != null) {
      tile = GestureDetector(onTap: onTap, child: tile);
    }
    return tooltip == null ? tile : Tooltip(message: tooltip!, child: tile);
  }
}

class FishingBadge extends StatelessWidget {
  const FishingBadge(this.text, this.color, {super.key});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minWidth: 21, minHeight: 21),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        alignment: Alignment.center,
        decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFFEFCA), width: 1.5)),
        child: Text(text,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w900)),
      );
}

/// Full-screen reward card for chests and the cave run: a glowing hero
/// picture, a title, optional stat chips, fish popping in one by one, a note
/// and the actions.
class FishingRewardPanel extends StatelessWidget {
  const FishingRewardPanel(
      {super.key,
      required this.hero,
      required this.title,
      required this.actions,
      this.stats = const [],
      this.badge,
      this.fish,
      this.note});
  final Widget hero;
  final String title;
  final List<(IconData, String)> stats;
  final String? badge, note;
  final List<FishSpecies>? fish;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => Positioned.fill(
      child: ColoredBox(
          color: const Color(0x99000000),
          child: Center(
              child: SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: Container(
                      width: 400,
                      padding: const EdgeInsets.fromLTRB(18, 10, 18, 16),
                      decoration: BoxDecoration(
                          color: DS.cream,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: fishingGold, width: 3),
                          boxShadow: const [
                            BoxShadow(color: Color(0x66FFD36B), blurRadius: 24)
                          ]),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        SizedBox(
                            height: 78,
                            child:
                                Stack(alignment: Alignment.center, children: [
                              const ClipRect(
                                  child: SizedBox(
                                      width: 220,
                                      height: 78,
                                      child: CustomPaint(
                                          painter: _RaysPainter()))),
                              hero,
                            ])),
                        Text(title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: DS.ink,
                                fontSize: DS.fontTitle,
                                fontWeight: FontWeight.w900)),
                        if (badge != null)
                          Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 2),
                              decoration: BoxDecoration(
                                  color: const Color(0xFFC0503A),
                                  borderRadius: BorderRadius.circular(12)),
                              child: Text(badge!,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900))),
                        if (stats.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(children: [
                            for (final (icon, text) in stats)
                              Expanded(
                                  child: Container(
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 3),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 5),
                                      decoration: BoxDecoration(
                                          color: const Color(0xFFF3E6CC),
                                          borderRadius:
                                              BorderRadius.circular(10)),
                                      child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(icon,
                                                size: 16, color: fishingWood),
                                            const SizedBox(width: 4),
                                            Text(text,
                                                style: const TextStyle(
                                                    color: DS.ink,
                                                    fontWeight:
                                                        FontWeight.w900)),
                                          ]))),
                          ]),
                        ],
                        if (fish case final fish? when fish.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 12,
                              runSpacing: 8,
                              children: [
                                for (var i = 0; i < fish.length; i++)
                                  _PopIn(
                                      delay: i,
                                      child: FishingFishTile(
                                          fish: fish[i],
                                          caption: Text(fish[i].label,
                                              style: const TextStyle(
                                                  color: DS.ink,
                                                  fontSize: 11.5,
                                                  fontWeight:
                                                      FontWeight.w800)))),
                              ]),
                        ],
                        if (note != null) ...[
                          const SizedBox(height: 8),
                          Text(note!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  color: fishingWood,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700)),
                        ],
                        const SizedBox(height: 12),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              for (var i = 0; i < actions.length; i++) ...[
                                if (i > 0) const SizedBox(width: 10),
                                actions[i],
                              ]
                            ]),
                      ]))))));
}

/// Scales a reward in with a little bounce, one after another.
class _PopIn extends StatelessWidget {
  const _PopIn({required this.delay, required this.child});
  final int delay;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final start = math.min(.7, delay * .2);
    return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: Duration(milliseconds: 450 + delay * 180),
        curve: Interval(start, 1, curve: Curves.elasticOut),
        builder: (context, t, child) => Opacity(
            opacity: t.clamp(0.0, 1.0),
            child: Transform.scale(scale: .4 + .6 * t, child: child)),
        child: child);
  }
}

/// Soft golden burst behind the hero picture.
class _RaysPainter extends CustomPainter {
  const _RaysPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    canvas.drawCircle(
        c,
        size.height * .55,
        Paint()
          ..shader = const RadialGradient(
                  colors: [Color(0x88FFE08A), Color(0x00FFE08A)])
              .createShader(
                  Rect.fromCircle(center: c, radius: size.height * .55)));
    final ray = Paint()..color = const Color(0x33FFC94D);
    for (var i = 0; i < 12; i++) {
      final a = i * math.pi / 6;
      final p = Path()
        ..moveTo(c.dx, c.dy)
        ..lineTo(c.dx + math.cos(a - .1) * 90, c.dy + math.sin(a - .1) * 90)
        ..lineTo(c.dx + math.cos(a + .1) * 90, c.dy + math.sin(a + .1) * 90)
        ..close();
      canvas.drawPath(p, ray);
    }
  }

  @override
  bool shouldRepaint(_RaysPainter old) => false;
}

/// Open treasure chest, gold spilling out.
class FishingChestHero extends StatelessWidget {
  const FishingChestHero({super.key, this.empty = false});
  final bool empty;
  @override
  Widget build(BuildContext context) => SizedBox(
      width: 86, height: 70, child: CustomPaint(painter: _ChestPainter(empty)));
}

class _ChestPainter extends CustomPainter {
  _ChestPainter(this.empty);
  final bool empty;
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final dark = Paint()..color = const Color(0xFF4A2E1D);
    final wood = Paint()..color = const Color(0xFF8A5A33);
    final gold = Paint()..color = const Color(0xFFE2A93B);
    // Lid tipped open behind.
    final lid = Path()
      ..moveTo(w * .14, h * .42)
      ..lineTo(w * .2, h * .08)
      ..quadraticBezierTo(w * .5, -h * .04, w * .8, h * .08)
      ..lineTo(w * .86, h * .42)
      ..close();
    canvas.drawPath(lid, dark);
    canvas.drawPath(lid.shift(const Offset(0, 3)), wood);
    canvas.drawLine(Offset(w * .5, h * .02), Offset(w * .5, h * .42),
        gold..strokeWidth = 4);
    // Treasure heap.
    if (!empty) {
      for (final (x, y, r) in const [
        (.3, .44, .09),
        (.45, .38, .1),
        (.6, .42, .09),
        (.72, .47, .07),
        (.38, .5, .08),
        (.55, .5, .08),
      ]) {
        canvas.drawCircle(Offset(w * x, h * y), w * r,
            Paint()..color = const Color(0xFFFFD36B));
        canvas.drawCircle(Offset(w * x - 1, h * y - 1), w * r * .4,
            Paint()..color = const Color(0xFFFFF1C4));
      }
      canvas.drawPath(
          Path()
            ..moveTo(w * .46, h * .36)
            ..lineTo(w * .5, h * .24)
            ..lineTo(w * .54, h * .36)
            ..close(),
          Paint()..color = const Color(0xFF7FD3E6));
    }
    // Box front.
    final box = RRect.fromRectAndRadius(
        Rect.fromLTRB(w * .1, h * .46, w * .9, h * .98),
        const Radius.circular(6));
    canvas.drawRRect(box, dark);
    canvas.drawRRect(box.deflate(3), wood);
    for (final x in [.24, .76]) {
      canvas.drawRect(
          Rect.fromLTRB(w * x - 3, h * .46, w * x + 3, h * .98), gold);
    }
    canvas.drawRect(Rect.fromLTRB(w * .1, h * .56, w * .9, h * .62), gold);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset(w * .5, h * .7), width: 14, height: 16),
            const Radius.circular(3)),
        gold);
    canvas.drawCircle(Offset(w * .5, h * .69), 2.4, dark);
  }

  @override
  bool shouldRepaint(_ChestPainter old) => old.empty != empty;
}

/// Three stars, earned ones gold and popping in turn.
class FishingStarsHero extends StatelessWidget {
  const FishingStarsHero({super.key, required this.stars});
  final int stars;
  @override
  Widget build(BuildContext context) => Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < 3; i++)
              Padding(
                  padding: EdgeInsets.only(bottom: i == 1 ? 14 : 0),
                  child: _PopIn(
                      delay: i,
                      child: Icon(
                          i < stars
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          size: i == 1 ? 60 : 48,
                          color: i < stars
                              ? const Color(0xFFFFC94D)
                              : const Color(0xFFCDBB9A),
                          shadows: i < stars
                              ? const [
                                  Shadow(
                                      color: Color(0xFF9C6A1E),
                                      offset: Offset(0, 2))
                                ]
                              : null))),
          ]);
}
