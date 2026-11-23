import 'dart:math' as math;
import 'package:material_ui/material_ui.dart';
import '../../fishing/fishing_boat.dart';
import '../../fishing/fishing_cabin.dart';
import '../../fishing/fishing_island.dart';
import '../../fishing/fishing_lighting.dart';
import '../../fishing/fishing_river.dart';
import '../../fishing/river_sea_land.dart';
import 'fishing_art_kit.dart';
import 'fishing_river_art.dart';

/// Day/night over the whole fishing world: one multiply tint for the hour,
/// then additive glows for lights that matter at night. Drawn above the
/// world and below the HUD; nothing is re-recorded.
final _firefly = Paint()..blendMode = BlendMode.plus;

class FishingNightOverlay extends CustomPainter {
  FishingNightOverlay(this.round, Listenable frames) : super(repaint: frames);
  final FishingRiverRound round;

  static Color tintFor(FishingLighting light) {
    final night =
        Color.lerp(Colors.white, const Color(0xFF55669C), light.night * .92)!;
    return Color.lerp(night, const Color(0xFFFFC28A), light.warmth * .42)!;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final light = FishingLighting.at(round.hour);
    final tint = tintFor(light);
    if (light.night < .01 && light.warmth < .01) return;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..color = tint
          ..blendMode = BlendMode.multiply);
    final glow = light.night;
    if (glow < .05) {
      canvas.restore();
      return;
    }
    canvas.scale(round.scale);
    canvas.translate(-round.cameraLeft, -round.cameraTop);
    final view = Rect.fromLTWH(round.cameraLeft, round.cameraTop,
        round.visibleWidth, round.visibleHeight);
    void lamp(Offset p, double radius, Color color, double strength) {
      if (!view.inflate(radius).contains(p)) return;
      canvas.drawCircle(
          p,
          radius,
          Paint()
            ..blendMode = BlendMode.plus
            ..shader = RadialGradient(colors: [
              color.withValues(alpha: strength * glow),
              color.withValues(alpha: 0),
            ]).createShader(Rect.fromCircle(center: p, radius: radius)));
    }

    final t = round.clock;
    final flick = math.sin(t * 13) * .5 + math.sin(t * 7.3) * .5;
    // Lighthouse lamp and its sweeping beam.
    final top = FishingIslandVisit.lighthouse +
        const Offset(0, -124 * FishingIslandVisit.lighthouseScale);
    lamp(top, 70, const Color(0xFFFFE6A0), .9);
    if (view.inflate(900).contains(top)) {
      final sweep = t * .9;
      for (final a in [sweep, sweep + math.pi]) {
        final reach = 820 * (.55 + .45 * math.cos(a).abs());
        final dir = Offset(math.cos(a), math.sin(a) * .45);
        final side = Offset(-dir.dy, dir.dx);
        final end = top + dir * reach;
        canvas.drawPath(
            Path()
              ..moveTo(top.dx, top.dy)
              ..lineTo((end + side * 90).dx, (end + side * 90).dy)
              ..lineTo((end - side * 90).dx, (end - side * 90).dy)
              ..close(),
            Paint()
              ..blendMode = BlendMode.plus
              ..shader = RadialGradient(colors: [
                Color.fromRGBO(255, 236, 170, .38 * glow),
                const Color(0x00FFECAA),
              ]).createShader(Rect.fromCircle(center: top, radius: reach)));
      }
    }
    // Coast lighthouse lamp.
    lamp(Offset(6190, FishingRiver.bottom(6190) + 77 - 124), 90,
        const Color(0xFFFFE6A0), .8);
    // Campfire on the island beach.
    lamp(fishingSeaIsland.center + const Offset(-210, 226), 150 + flick * 10,
        const Color(0xFFFFA65A), .75);
    // Pirate ship stern windows and lantern.
    lamp(FishingCabin.ship + const Offset(-106, -28), 120,
        const Color(0xFFFFCB70), .6);
    lamp(FishingCabin.ship + const Offset(-126, -132), 70,
        const Color(0xFFFFD98A), .8);
    // Cave crystals.
    for (final x in [8000.0, 8200.0]) {
      lamp(Offset(x, FishingRiver.top(x) + 65), 190, const Color(0xFF8FE7D6),
          .45);
    }
    // Village cottages light their windows.
    for (final (p, s) in fishingCottageWindows()) {
      if (!view.inflate(80).contains(p)) continue;
      canvas.drawRect(
          Rect.fromCenter(center: p, width: 18 * s, height: 20 * s),
          Paint()
            ..blendMode = BlendMode.plus
            ..color = Color.fromRGBO(255, 196, 96, .75 * glow));
      lamp(p, 75 * s, const Color(0xFFFFC870), .45);
      lamp(p + Offset(0, 48 * s), 60 * s, const Color(0xFFFFC870), .2);
    }
    // Basket boat's stern lantern (see paintBasketBoatBack), bobbing along.
    if (round.boatStyle == FishingBoat.basket) {
      final p =
          round.boat + Offset(59, -52 + math.sin(round.clock * 2.5) * 1.8);
      lamp(p, 26, const Color(0xFFFFB45C), .9);
      lamp(p + const Offset(0, 40), 70, const Color(0xFFFFC46B), .35);
    }
    // Harbour: boathouse lantern, beacon tower and pier lamp.
    final house = FishingBoatHouse.base;
    lamp(house + const Offset(18, -60), 45, const Color(0xFFFFD27A), .7);
    lamp(house + const Offset(73, -132), 80, const Color(0xFFFFE6A0), .8);
    const pierX = FishingRiver.startDockX;
    lamp(Offset(pierX + 50, FishingRiver.bottom(pierX) - 7), 55,
        const Color(0xFFFFD27A), .7);
    // A warm lantern around the cat so the player is never lost in the dark.
    lamp(round.cameraFocus + const Offset(0, -20), 130, const Color(0xFFFFD79A),
        .3);
    // Fireflies over the mangrove banks.
    if (view.right > FishingRiver.mangroveStart &&
        view.left < FishingRiver.seaStart) {
      for (var i = 0; i < 70; i++) {
        final x = FishingRiver.mangroveStart + artNoise(i, 1) * 1800;
        if (x < view.left - 20 || x > view.right + 20) continue;
        final north = i.isEven;
        final edge = north ? FishingRiver.top(x) : FishingRiver.bottom(x);
        final p = Offset(
            x + math.sin(t * .6 + i) * 18,
            edge +
                (north ? -1 : 1) * (40 + artNoise(i, 2) * 160) +
                math.cos(t * .8 + i * 1.7) * 12);
        final blink = math.max(0.0, math.sin(t * (1.2 + artNoise(i, 3)) + i));
        if (blink <= 0) continue;
        canvas.drawCircle(
            p,
            6,
            _firefly
              ..color = Color.fromRGBO(220, 255, 140, blink * .35 * glow));
        canvas.drawCircle(p, 1.8,
            _firefly..color = Color.fromRGBO(240, 255, 190, blink * glow));
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(FishingNightOverlay old) => old.round != round;
}
