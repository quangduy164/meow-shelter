import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:material_ui/material_ui.dart';
import '../../fishing/fishing_cabin.dart';
import '../../fishing/fishing_exploration.dart';
import '../../fishing/fishing_river.dart';
import '../../fishing/river_sea_land.dart';
import '../design.dart';

/// Square minimap (a 3600-unit window following the player) or, with [full],
/// the whole world at [size] wide. Fog hides cells not explored yet.
class FishingMinimap extends StatefulWidget {
  const FishingMinimap(
      {super.key,
      required this.round,
      required this.frames,
      this.size = 80,
      this.full = false});
  final FishingRiverRound round;
  final Listenable frames;
  final double size;
  final bool full;
  @override
  State<FishingMinimap> createState() => _FishingMinimapState();
}

class _FishingMinimapState extends State<FishingMinimap> {
  late final ui.Picture _base = _record();

  /// Recorded in world units; the painter scales it to any size.
  static ui.Picture _record() {
    final recorder = ui.PictureRecorder();
    final c = Canvas(recorder);
    const w = FishingRiver.length, h = FishingRiver.height;
    for (final region in FishingRegion.values) {
      if (region == FishingRegion.cave) continue;
      final color = switch (region.land) {
        FishingLand.village => const Color(0xFF8DB565),
        FishingLand.bamboo => const Color(0xFF8DB565),
        FishingLand.mangrove => const Color(0xFF5E8F4E),
        FishingLand.beach => const Color(0xFFE2C98A),
        FishingLand.rocky => const Color(0xFFA3A5A0),
      };
      c.drawRect(Rect.fromLTRB(region.start, 0, region.end, h),
          Paint()..color = color);
    }
    final water = Path()..moveTo(0, FishingRiver.top(0));
    for (var x = 0.0; x <= w; x += 40) {
      water.lineTo(x, FishingRiver.top(x));
    }
    for (var x = w; x >= 0; x -= 40) {
      water.lineTo(x, FishingRiver.bottom(x));
    }
    water.close();
    c.drawPath(
        water,
        Paint()
          ..shader = ui.Gradient.linear(Offset.zero, const Offset(w, 0), const [
            Color(0xFF6CC2D8),
            Color(0xFF4FA6C8),
            Color(0xFF2F86B8),
          ], const [
            0,
            FishingRiver.seaStart / w,
            1
          ]));
    for (final rock in fishingSeaRocks) {
      c.drawCircle(rock.center, rock.radius + 30,
          Paint()..color = const Color(0xFF7D7F7C));
    }
    c.drawPath(
        fishingSeaIsland.outline(), Paint()..color = const Color(0xFFEBD49A));
    c.drawPath(
        fishingSeaIsland
            .outline(scale: .62)
            .shift(fishingSeaIsland.center * (1 - .62)),
        Paint()..color = const Color(0xFF6FA552));
    c.drawCircle(FishingCabin.ship, FishingCabin.radius + 40,
        Paint()..color = const Color(0xFF8A5A33));
    return recorder.endRecording();
  }

  @override
  void dispose() {
    _base.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = widget.full
        ? widget.size * FishingRiver.height / FishingRiver.length
        : widget.size;
    return Container(
      width: widget.size + 6,
      height: height + 6,
      decoration: BoxDecoration(
        color: DS.wood,
        borderRadius: BorderRadius.circular(DS.radiusSm),
      ),
      padding: const EdgeInsets.all(3),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(DS.radiusSm - 2),
        child: RepaintBoundary(
          child: CustomPaint(
              size: Size(widget.size, height),
              painter: _MinimapPainter(
                  widget.round, _base, widget.frames, widget.full)),
        ),
      ),
    );
  }
}

class _MinimapPainter extends CustomPainter {
  _MinimapPainter(this.round, this.base, Listenable frames, this.full)
      : super(repaint: frames);
  final bool full;
  final FishingRiverRound round;
  final ui.Picture base;
  static final _fog = Paint()..color = const Color(0xFF2B3440);
  static final _view = Paint()
    ..color = const Color(0xCCFFFFFF)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.2;
  static final _dot = Paint()..color = const Color(0xFFFF8A3D);
  static final _dotRing = Paint()..color = const Color(0xFFFFFFFF);

  @override
  void paint(Canvas canvas, Size size) {
    final span = full ? FishingRiver.length : FishingRiver.height;
    final s = size.width / span;
    final focus = round.cameraFocus;
    final left = full
        ? 0.0
        : (focus.dx - span / 2)
            .clamp(0.0, FishingRiver.length - span)
            .toDouble();
    canvas.save();
    canvas.scale(s);
    canvas.translate(-left, 0);
    canvas.drawPicture(base);
    const cell = FishingExploration.cell;
    final seen = round.exploration;
    final first = (left / cell).floor();
    final last =
        math.min(FishingExploration.columns - 1, ((left + span) / cell).ceil());
    final fog = Path();
    for (var r = 0; r < FishingExploration.rows; r++) {
      for (var c = first; c <= last; c++) {
        if (seen.isExplored(c, r)) continue;
        final start = c;
        while (c < last && !seen.isExplored(c + 1, r)) {
          c++;
        }
        fog.addRect(Rect.fromLTRB(
            start * cell, r * cell - 4, (c + 1) * cell, (r + 1) * cell + 4));
      }
    }
    canvas.drawPath(fog, _fog);
    canvas.drawRect(
        Rect.fromLTWH(round.cameraLeft, round.cameraTop, round.visibleWidth,
            round.visibleHeight),
        _view..strokeWidth = 1.2 / s);
    canvas.drawCircle(focus, 4.5 / s, _dotRing);
    canvas.drawCircle(focus, 3 / s, _dot);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_MinimapPainter old) =>
      old.round != round || old.base != base || old.full != full;
}
