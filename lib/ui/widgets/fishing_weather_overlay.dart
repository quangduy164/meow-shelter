import 'package:material_ui/material_ui.dart';
import '../../fishing/fishing_lighting.dart';
import '../../fishing/fishing_river.dart';
import '../../fishing/river_sea_land.dart';
import 'fishing_art_kit.dart';

/// Weather on top of the world and the night tint: drifting cloud shadows,
/// rain streaks with ripples on the water, and banks of fog.
class FishingWeatherOverlay extends CustomPainter {
  FishingWeatherOverlay(this.round, Listenable frames) : super(repaint: frames);
  final FishingRiverRound round;

  @override
  void paint(Canvas canvas, Size size) {
    final w = round.weather;
    if (w.cloud < .01 && w.rain < .01 && w.fog < .01) return;
    final night = FishingLighting.at(round.hour).night;
    final t = round.clock;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    // Overcast dims the whole scene a little.
    canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..color = Color.fromRGBO(
              40, 52, 66, (w.cloud * .05 + w.rain * .08) * (1 - night * .5)));
    canvas.save();
    canvas.scale(round.scale);
    canvas.translate(-round.cameraLeft, -round.cameraTop);
    final view = Rect.fromLTWH(round.cameraLeft, round.cameraTop,
        round.visibleWidth, round.visibleHeight);
    // Cloud shadows sliding across land and water.
    if (w.cloud > .02) {
      const cell = 700.0;
      final drift = t * 14;
      for (var col = ((view.left - drift) / cell).floor() - 1;
          col * cell + drift < view.right + cell;
          col++) {
        for (var row = (view.top / cell).floor() - 1;
            row * cell < view.bottom + cell;
            row++) {
          final k = col * 131 + row * 977;
          final c = Offset(col * cell + drift + artNoise(k, 1) * cell,
              row * cell + artNoise(k, 2) * cell);
          for (var i = 0; i < 3; i++) {
            canvas.drawOval(
                Rect.fromCenter(
                    center: c + Offset(i * 110.0 - 110, (i % 2) * 40.0),
                    width: 260 + artNoise(k + i, 3) * 160,
                    height: 150 + artNoise(k + i, 4) * 70),
                Paint()..color = Color.fromRGBO(20, 30, 45, .04 * w.cloud));
          }
        }
      }
    }
    // Rain rings on the water.
    if (w.rain > .02) {
      final ring = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4;
      final count = (35 * w.rain).round();
      for (var i = 0; i < count; i++) {
        final cycle = (t * 1.3 + artNoise(i, 5)).floor();
        final life = (t * 1.3 + artNoise(i, 5)) % 1;
        final k = i * 7919 + cycle * 31;
        final p = Offset(view.left + artNoise(k, 6) * view.width,
            view.top + artNoise(k, 7) * view.height);
        if (p.dy < FishingRiver.top(p.dx) + 8 ||
            p.dy > FishingRiver.bottom(p.dx) - 8 ||
            fishingSeaIsland.contains(p)) {
          continue;
        }
        ring.color = Color.fromRGBO(230, 245, 250, (1 - life) * .4 * w.rain);
        canvas.drawOval(
            Rect.fromCenter(
                center: p, width: 6 + life * 26, height: 3 + life * 11),
            ring);
      }
    }
    canvas.restore();
    // Falling rain in screen space, slanted by the wind.
    if (w.rain > .02) {
      final streak = Paint()
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round
        ..color = Color.fromRGBO(220, 235, 248, (.2 + night * .06) * w.rain);
      final count = (80 * w.rain).round();
      final len = size.height * .045;
      for (var i = 0; i < count; i++) {
        final speed = .9 + artNoise(i, 8) * .5;
        final y =
            ((t * speed + artNoise(i, 9)) % 1) * (size.height + len) - len;
        final x = (artNoise(i, 10) * (size.width + 80) - y * .25) %
                (size.width + 80) -
            40;
        canvas.drawLine(Offset(x, y), Offset(x - len * .25, y + len), streak);
      }
    }
    // Fog: an even haze plus slow banks, thicker toward the screen edges.
    if (w.fog > .02) {
      final tone =
          Color.lerp(const Color(0xFFE8EEF0), const Color(0xFF3D4A60), night)!;
      canvas.drawRect(Offset.zero & size,
          Paint()..color = tone.withValues(alpha: .12 * w.fog));
      final edge = Rect.fromCenter(
          center: size.center(Offset.zero),
          width: size.width * 1.3,
          height: size.height * 1.5);
      canvas.drawRect(
          Offset.zero & size,
          Paint()
            ..shader = RadialGradient(colors: [
              tone.withValues(alpha: 0),
              tone.withValues(alpha: .3 * w.fog),
            ], stops: const [
              .35,
              1
            ]).createShader(edge));
      for (var i = 0; i < 6; i++) {
        final x =
            ((t * (8 + i * 2) / size.width + artNoise(i, 11)) % 1.4 - .2) *
                size.width;
        final y = (artNoise(i, 12) * .9 + .05) * size.height;
        final r = Rect.fromCenter(
            center: Offset(x, y),
            width: size.width * (.5 + artNoise(i, 13) * .4),
            height: size.height * .3);
        canvas.drawOval(
            r,
            Paint()
              ..shader = RadialGradient(colors: [
                tone.withValues(alpha: .1 * w.fog),
                tone.withValues(alpha: 0),
              ]).createShader(r));
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(FishingWeatherOverlay old) => old.round != round;
}
