import 'dart:math' as math;
import 'package:flutter/painting.dart';
import '../../fishing/fishing_controller.dart';
import '../../fishing/fishing_fight.dart';
import '../../collection/fish_species.dart';
import 'fishing_fish_art.dart';

/// Reads the same fight timeline as the rules, including warning windows.
void paintFishingFight(Canvas canvas, FishingController controller) {
  final position = controller.spot + const Offset(0, 10);
  final fight = controller.fight;
  final time = controller.elapsed;
  canvas.save();
  canvas.translate(position.dx, position.dy);
  canvas.scale(controller.fishScale);
  final paint = Paint();
  if (controller.fish == FishSpecies.pufferfish) {
    final inflate = fight.blocked
        ? 1.0
        : fight.warning
            ? .45 + math.sin(time * 12) * .1
            : 0.0;
    canvas.save();
    canvas.translate(-25 - inflate * 8, -18 - inflate * 9);
    canvas.scale(1 + inflate * .35, 1 + inflate * .55);
    FishingFishArt(controller.fish).paint(canvas, const Size(50, 34));
    canvas.restore();
    if (fight.blocked) {
      for (var i = 0; i < 6; i++) {
        final dir = Offset.fromDirection(i * math.pi / 3, 1);
        canvas.drawLine(dir * 38, dir * (43 + math.sin(time * 9).abs() * 5),
            _kFishingFightArt0);
      }
    }
  } else if (fight.move != FishFightMove.dive) {
    canvas.save();
    canvas.rotate(controller.river.heading.dx < 0 ? math.pi : 0);
    canvas.drawOval(const Rect.fromLTWH(-22, -7, 44, 14),
        paint..color = const Color(0x993D626B));
    final wag = math.sin(time * 9) * 3;
    canvas.drawPath(
        Path()
          ..moveTo(-17, 0)
          ..lineTo(-32, -8 + wag)
          ..lineTo(-32, 8 + wag)
          ..close(),
        paint);
    if (fight.move == FishFightMove.dash) {
      final streaks = controller.fish == FishSpecies.seaDragon
          ? 3 + ((fight.pullMultiplier - 1) * 10).round()
          : 3;
      for (var i = 0; i < streaks; i++) {
        canvas.drawLine(Offset(-40 - i * 7.0, (i - 1) * 8.0),
            Offset(-61 - i * 8.0, (i - 1) * 8.0), _kFishingFightArt1);
      }
    }
    canvas.restore();
  }
  if ((controller.fish == FishSpecies.catfish ||
          controller.fish == FishSpecies.moonfish) &&
      (fight.warning || fight.move == FishFightMove.dive)) {
    for (var i = 0; i < 7; i++) {
      final t = (time * .8 + i * .17) % 1;
      final point =
          Offset(math.sin(i * 2.4) * 21, math.cos(i * 1.7) * 8 - t * 17);
      canvas.drawCircle(
          point,
          2 + t * 4,
          Paint()
            ..color = Color.fromRGBO(232, 255, 245, math.sin(t * math.pi) * .9)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6);
    }
    if (fight.move == FishFightMove.dive) {
      for (var i = 0; i < 3; i++) {
        final t = (time * 1.6 + i / 3) % 1;
        canvas.drawOval(
            Rect.fromCenter(
                center: Offset.zero, width: 12 + t * 65, height: 5 + t * 24),
            Paint()
              ..color = Color.fromRGBO(224, 255, 240, (1 - t) * .75)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2);
      }
    }
  }
  if (controller.fish == FishSpecies.moonfish && !fight.warning) {
    for (var i = 0; i < 2; i++) {
      final phase = (time * .65 + i * .5) % 1;
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset.zero,
              width: 24 + phase * 54,
              height: 8 + phase * 20),
          _moonRipple..color = Color.fromRGBO(192, 207, 255, (1 - phase) * .6));
    }
  }
  if (fight.move == FishFightMove.orbit) {
    final down = fight.lateral > 0;
    final y = down ? -30.0 : 30.0;
    final sign = down ? -1.0 : 1.0;
    canvas.drawPath(
        Path()
          ..moveTo(-6, y - sign * 4)
          ..lineTo(0, y + sign * 3)
          ..lineTo(6, y - sign * 4),
        _kFishingFightArt2);
  }
  canvas.restore();
}

// Constant paints shared by every frame (hoisted out of the paint loops).
final _kFishingFightArt0 = Paint()
  ..color = const Color(0xDDFFD582)
  ..strokeWidth = 2
  ..strokeCap = StrokeCap.round;
final _kFishingFightArt1 = Paint()
  ..color = const Color(0xCCE1FFF0)
  ..strokeWidth = 2
  ..strokeCap = StrokeCap.round;
final _kFishingFightArt2 = Paint()
  ..color = const Color(0xFFFFE4A1)
  ..style = PaintingStyle.stroke
  ..strokeWidth = 3
  ..strokeCap = StrokeCap.round;

final _moonRipple = Paint()
  ..style = PaintingStyle.stroke
  ..strokeWidth = 1.6;
