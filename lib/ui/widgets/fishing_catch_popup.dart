import 'dart:math' as math;
import 'package:material_ui/material_ui.dart';

import '../../collection/fish_species.dart';
import 'fishing_fish_art.dart';
import '../design.dart';

class FishingCatchPopup extends StatelessWidget {
  const FishingCatchPopup(
      {super.key,
      required this.fish,
      required this.onNext,
      this.grams,
      this.newRecord = false,
      this.fishScale = 1});

  final FishSpecies fish;
  final VoidCallback onNext;
  final int? grams;
  final bool newRecord;
  final double fishScale;
  bool get legendary => FishSpecies.legendary.contains(fish);

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 290),
            child: DecoratedBox(
              decoration: DS.card,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    DS.spaceLg, DS.spaceLg, DS.spaceLg, DS.spaceLg),
                child: SingleChildScrollView(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Text('CÂU ĐƯỢC RỒI!',
                      style: TextStyle(
                          color: DS.ink,
                          fontSize: DS.fontTitle,
                          fontWeight: FontWeight.w900)),
                  const SizedBox(height: DS.spaceXs),
                  SizedBox(
                      width: legendary ? 220 : 150,
                      height: legendary ? 136 : 92,
                      child: Center(
                          child: SizedBox(
                              width: legendary
                                  ? 220
                                  : 150 * (fishScale / 1.5).clamp(.55, 1.0),
                              height: legendary
                                  ? 136
                                  : 92 * (fishScale / 1.5).clamp(.55, 1.0),
                              child:
                                  CustomPaint(painter: FishingFishArt(fish))))),
                  Text(fish.label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: DS.goldEdge,
                          fontSize: DS.fontHeading,
                          fontWeight: FontWeight.bold)),
                  if (!fish.isJunk && grams != null) ...[
                    const SizedBox(height: DS.spaceXs),
                    Text(formatFishWeight(grams!),
                        style: const TextStyle(
                            fontSize: DS.fontTitle,
                            fontWeight: FontWeight.w900,
                            color: DS.ink)),
                    if (newRecord)
                      const Padding(
                        padding: EdgeInsets.only(top: DS.spaceXs),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.emoji_events_rounded,
                              color: DS.goldEdge, size: 19),
                          SizedBox(width: DS.spaceXs),
                          Text('KỶ LỤC MỚI!',
                              style: TextStyle(
                                  color: DS.goldEdge,
                                  fontWeight: FontWeight.w900,
                                  fontSize: DS.fontBody)),
                        ]),
                      ),
                  ],
                  const SizedBox(height: DS.spaceXs),
                  Text(fish.isJunk ? 'Đồ vật thất lạc' : fish.rarity,
                      style: const TextStyle(
                          color: DS.soft, fontSize: DS.fontBody)),
                  const SizedBox(height: DS.spaceMd),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: onNext,
                      icon: const SizedBox.square(
                          dimension: 28,
                          child: CustomPaint(painter: _CastAgainIcon())),
                      label: const Text('CÂU TIẾP'),
                      style: DS.primary,
                    ),
                  )
                ])),
              ),
            ),
          ),
        ),
      );
}

/// A bent rod and returning cast arc remain legible at button size.
class _CastAgainIcon extends CustomPainter {
  const _CastAgainIcon();
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 28, size.height / 28);
    final stroke = Paint()
      ..color = DS.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final rod = Path()
      ..moveTo(5, 23)
      ..quadraticBezierTo(9, 5, 19, 5);
    canvas.drawPath(rod, stroke);
    canvas.drawLine(
        const Offset(4, 25),
        const Offset(7, 17),
        Paint()
          ..color = const Color(0xFF95673E)
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round);
    canvas.drawCircle(const Offset(9, 18), 2.6, Paint()..color = DS.ink);
    canvas.drawCircle(
        const Offset(9, 18), 1.2, Paint()..color = const Color(0xFFFFE7AB));
    canvas.drawPath(
        Path()
          ..moveTo(19, 5)
          ..quadraticBezierTo(24, 6, 23, 12),
        stroke
          ..color = const Color(0xFF556F61)
          ..strokeWidth = 1.3);
    canvas.drawOval(const Rect.fromLTWH(20.7, 11, 4.6, 7),
        Paint()..color = const Color(0xFFFFF5DC));
    canvas.drawArc(const Rect.fromLTWH(20.7, 11, 4.6, 7), math.pi, math.pi,
        true, Paint()..color = const Color(0xFFB96745));
    canvas.drawOval(
        const Rect.fromLTWH(20.7, 11, 4.6, 7),
        stroke
          ..color = DS.ink
          ..strokeWidth = .9);
    canvas.drawArc(
        const Rect.fromLTWH(12, 15, 13, 10),
        .1,
        math.pi * .85,
        false,
        stroke
          ..color = const Color(0xFF456B5C)
          ..strokeWidth = 1.8);
    canvas.drawPath(
        Path()
          ..moveTo(13.3, 22)
          ..lineTo(12.5, 25.5)
          ..lineTo(16.2, 25),
        stroke);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_CastAgainIcon oldDelegate) => false;
}
