import 'dart:math' as math;
import 'package:material_ui/material_ui.dart';
import '../../collection/fish_species.dart';
import '../../fishing/fishing_showcase.dart';
import '../../game/constants.dart';
import 'fishing_fish_art.dart';

/// Shared local/remote fish art, attached to the same fish-hold sheet paws.
class FishingShowcaseView extends StatelessWidget {
  const FishingShowcaseView(
      {super.key,
      required this.showcase,
      required this.point,
      required this.catSize,
      required this.land,
      required this.facingRight,
      required this.frame,
      required this.scale,
      this.bob = 0});
  final FishingShowcase showcase;
  final Offset point;
  final double catSize, scale, bob;
  final bool land, facingRight;
  final int frame;
  @override
  Widget build(BuildContext context) {
    final paws = fishHoldPaws[frame.clamp(0, fishHoldPaws.length - 1)];
    final top = point.dy - catSize * (land ? .78 : .69) + bob;
    final width = showcase.width * scale, height = width * .64;
    final center = Offset(
        point.dx +
            ((facingRight ? paws.$1 : 256 - paws.$1) / 256 - .5) * catSize,
        top + paws.$2 / 256 * catSize - math.max(0, height * .38 - 8 * scale));
    final legendary = FishSpecies.legendary.contains(showcase.fish);
    return IgnorePointer(
        child: Stack(clipBehavior: Clip.none, children: [
      Positioned(
          left: center.dx - width / 2,
          top: center.dy - height / 2,
          width: width,
          height: height,
          child: RepaintBoundary(
              child: DecoratedBox(
                  decoration: BoxDecoration(
                      gradient: legendary
                          ? const RadialGradient(
                              colors: [Color(0x66FFE28A), Color(0x00FFE28A)])
                          : null),
                  child: CustomPaint(painter: FishingFishArt(showcase.fish))))),
      Positioned(
          left: point.dx - 110,
          top: math.min(top - 20, center.dy - height / 2 - 22),
          width: 220,
          child: Text(
              showcase.measured
                  ? '${showcase.fish.label} · ${formatFishWeight(showcase.grams)}'
                  : showcase.fish.label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: legendary ? const Color(0xFFFFDF8B) : Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  shadows: const [
                    Shadow(
                        color: Color(0xFF172E3B),
                        blurRadius: 3,
                        offset: Offset(0, 1))
                  ]))),
    ]));
  }
}
