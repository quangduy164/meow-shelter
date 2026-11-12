import 'package:flame/components.dart' show Vector2;
import 'package:flutter/material.dart';

import '../../game/cat_herd/herd_map.dart';
import '../../game/cat_herd/herd_round.dart';
import '../../game/cat_herd/herd_scene.dart';
import '../design.dart';
import 'game_glyphs.dart';
import 'round_button.dart';

/// Region cards with previews drawn by the same renderer as the playable map.
class HerdMapSelect extends StatelessWidget {
  const HerdMapSelect(
      {super.key, required this.onPlay, required this.onHome, this.onTutorial});
  final ValueChanged<HerdMap> onPlay;
  final VoidCallback onHome;
  final VoidCallback? onTutorial;

  @override
  Widget build(BuildContext context) => Material(
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF293B52), Color(0xFF477471)],
            ),
          ),
          child: SafeArea(
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    DS.spaceMd, DS.spaceSm, DS.spaceLg, DS.spaceXs),
                child: Row(children: [
                  RoundButton(glyph: GameGlyph.home, onPressed: onHome),
                  const SizedBox(width: DS.spaceMd),
                  const Expanded(
                    child: Text('CHỌN VÙNG KHÁM PHÁ',
                        style: TextStyle(
                            color: DS.cream,
                            fontSize: DS.fontTitle,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1)),
                  ),
                  if (onTutorial != null)
                    TextButton.icon(
                        onPressed: onTutorial,
                        icon: const Icon(Icons.school_rounded, size: 18),
                        label: const Text('TẬP CHƠI'),
                        style: TextButton.styleFrom(foregroundColor: DS.cream)),
                ]),
              ),
              Expanded(
                child: LayoutBuilder(builder: (context, box) {
                  // Compact cards: all four regions fit side by side on most
                  // phones, centred vertically instead of filling the height.
                  final width = ((box.maxWidth - 80) / 4).clamp(170.0, 210.0);
                  final height =
                      (box.maxHeight - DS.spaceLg).clamp(0.0, 240.0).toDouble();
                  return Align(
                    alignment: Alignment.center,
                    child: SizedBox(
                      height: height,
                      child: ListView.separated(
                        shrinkWrap: true,
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.fromLTRB(
                            DS.spaceLg, 0, DS.spaceLg, DS.spaceLg),
                        itemCount: HerdMap.all.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(width: DS.spaceMd),
                        itemBuilder: (context, i) => SizedBox(
                          width: width,
                          child: _RegionCard(
                              map: HerdMap.all[i],
                              number: i + 1,
                              onPressed: () => onPlay(HerdMap.all[i])),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ]),
          ),
        ),
      );
}

class _RegionCard extends StatelessWidget {
  const _RegionCard(
      {required this.map, required this.number, required this.onPressed});
  final HerdMap map;
  final int number;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: DS.card,
        child: Padding(
          padding: const EdgeInsets.all(DS.spaceXs),
          child: Material(
            color: DS.cream,
            borderRadius: BorderRadius.circular(DS.radiusLg),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onPressed,
              child: Semantics(
                button: true,
                label: 'Chơi ${map.name}',
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Stack(fit: StackFit.expand, children: [
                          RepaintBoundary(
                              child: CustomPaint(painter: _MapPreview(map))),
                          Positioned(
                              left: 10,
                              top: 10,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                    color: DS.ink,
                                    borderRadius:
                                        BorderRadius.circular(DS.radiusSm)),
                                child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: DS.spaceSm,
                                        vertical: DS.spaceXs),
                                    child: Text('VÙNG $number',
                                        style: const TextStyle(
                                            color: DS.cream,
                                            fontSize: DS.fontCaption,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 1))),
                              )),
                        ]),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                            DS.spaceSm, DS.spaceXs, DS.spaceSm, DS.spaceSm),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(map.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: DS.ink,
                                      fontSize: DS.fontHeading,
                                      fontWeight: FontWeight.w900)),
                              const SizedBox(height: DS.spaceXs),
                              Text(
                                  switch (map.kind) {
                                    HerdMapKind.tutorial =>
                                      'Tập di chuyển và đón mèo',
                                    HerdMapKind.nightMarket =>
                                      'Bác bán hàng · Đèn lồng · Lẻn qua chợ',
                                    HerdMapKind.dunes =>
                                      'Bóng râm · Nắng nóng · Bão cát',
                                    HerdMapKind.playground =>
                                      'Khối gỗ · Xe chạy vòng · Bóng nảy',
                                    HerdMapKind.snow =>
                                      'Băng mỏng · Làn trượt · Đảo tuyết',
                                  },
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: DS.soft,
                                      fontSize: DS.fontBody,
                                      height: 1.3)),
                              const SizedBox(height: DS.spaceXs),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: DS.spaceXs),
                                decoration: BoxDecoration(
                                    color: DS.gold,
                                    borderRadius:
                                        BorderRadius.circular(DS.radiusMd),
                                    border: Border.all(
                                        color: DS.goldEdge, width: 1.5)),
                                child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.play_arrow_rounded,
                                          color: DS.ink, size: 20),
                                      SizedBox(width: DS.spaceXs),
                                      Text('CHƠI',
                                          style: TextStyle(
                                              color: DS.ink,
                                              fontSize: DS.fontBody,
                                              fontWeight: FontWeight.w900)),
                                    ]),
                              ),
                            ]),
                      ),
                    ]),
              ),
            ),
          ),
        ),
      );
}

class _MapPreview extends CustomPainter {
  _MapPreview(HerdMap map) : round = HerdRound(seed: 3) {
    round.map = map;
    round.reset(Vector2(800, 375));
    round.time = 6;
  }
  final HerdRound round;

  @override
  void paint(Canvas canvas, Size size) {
    // Preserve terrain proportions regardless of the card's aspect ratio.
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    final scale = (size.width / 800).clamp(size.height / 375, double.infinity);
    canvas.translate(
        (size.width - 800 * scale) / 2, (size.height - 375 * scale) / 2);
    canvas.scale(scale);
    paintHerdField(canvas, const Size(800, 375), round);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MapPreview oldDelegate) =>
      round.map != oldDelegate.round.map;
}
