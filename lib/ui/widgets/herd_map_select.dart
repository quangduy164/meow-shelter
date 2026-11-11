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
                padding: const EdgeInsets.fromLTRB(12, 10, 16, 6),
                child: Row(children: [
                  RoundButton(glyph: GameGlyph.home, onPressed: onHome),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('CHỌN VÙNG KHÁM PHÁ',
                        style: TextStyle(
                            color: DS.cream,
                            fontSize: 22,
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
                  final width = ((box.maxWidth - 60) / 3).clamp(230.0, 300.0);
                  return ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: HerdMap.all.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 14),
                    itemBuilder: (context, i) => SizedBox(
                      width: width,
                      child: _RegionCard(
                          map: HerdMap.all[i],
                          number: i + 1,
                          onPressed: () => onPlay(HerdMap.all[i])),
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
          padding: const EdgeInsets.all(3),
          child: Material(
            color: DS.cream,
            borderRadius: BorderRadius.circular(16),
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
                                    borderRadius: BorderRadius.circular(8)),
                                child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 9, vertical: 5),
                                    child: Text('VÙNG $number',
                                        style: const TextStyle(
                                            color: DS.cream,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 1))),
                              )),
                        ]),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(map.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: DS.ink,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w900)),
                              const SizedBox(height: 4),
                              Text(
                                  switch (map.kind) {
                                    HerdMapKind.tutorial =>
                                      'Tập di chuyển và đón mèo',
                                    HerdMapKind.nightMarket =>
                                      'Quầy cá · Xe đẩy · Phố có đèn',
                                    HerdMapKind.dunes =>
                                      'Ốc đảo · Khe đá · Cồn cát trượt',
                                    HerdMapKind.playground =>
                                      'Khối gỗ · Xe chạy vòng · Bóng nảy',
                                    HerdMapKind.snow =>
                                      'Trại củi · Đảo tuyết · Cầu tuyết lăn',
                                  },
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: DS.soft,
                                      fontSize: 12,
                                      height: 1.3)),
                              const SizedBox(height: 10),
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                    color: DS.gold,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                        color: DS.goldEdge, width: 1.5)),
                                child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.play_arrow_rounded,
                                          color: DS.ink, size: 20),
                                      SizedBox(width: 4),
                                      Text('CHƠI',
                                          style: TextStyle(
                                              color: DS.ink,
                                              fontSize: 12,
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
