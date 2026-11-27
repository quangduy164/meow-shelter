import '../../fishing/fishing_place.dart';
import '../../fishing/fishing_quests.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:material_ui/material_ui.dart';
import '../../fishing/fishing_exploration.dart';
import '../../fishing/fishing_island.dart';
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

  /// Fires only when something the minimap shows has changed, instead of
  /// every game frame (the fog path is rebuilt on each repaint).
  final _repaint = ValueNotifier(0);
  Object? _shown;

  Object get _state {
    final r = widget.round;
    return (
      r.cameraLeft,
      r.cameraTop,
      r.visibleWidth,
      r.visibleHeight,
      r.cameraFocus,
      r.exploration.version,
      FishingQuests.instance.navigationTarget,
    );
  }

  void _onFrame() {
    final state = _state;
    if (state == _shown) return;
    _shown = state;
    _repaint.value++;
  }

  @override
  void initState() {
    super.initState();
    widget.frames.addListener(_onFrame);
  }

  @override
  void didUpdateWidget(FishingMinimap old) {
    super.didUpdateWidget(old);
    if (old.frames != widget.frames) {
      old.frames.removeListener(_onFrame);
      widget.frames.addListener(_onFrame);
    }
    _shown = null;
    _repaint.value++;
  }

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
    c.drawPath(fishingSeaIsland.outline(grow: -90),
        Paint()..color = const Color(0xFF6FA552));
    c.drawOval(
        Rect.fromCenter(
            center: FishingIslandVisit.mountain,
            width: FishingIslandVisit.mountainRadii.width * 1.5,
            height: FishingIslandVisit.mountainRadii.height * 1.5),
        Paint()..color = const Color(0xFF8C7A5E));
    c.drawCircle(
        FishingVisit.cabinShip.anchor,
        FishingVisit.cabinShip.radius + 40,
        Paint()..color = const Color(0xFF8A5A33));
    return recorder.endRecording();
  }

  @override
  void dispose() {
    widget.frames.removeListener(_onFrame);
    _repaint.dispose();
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
              painter:
                  _MinimapPainter(widget.round, _base, _repaint, widget.full)),
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
  static final _quest = Paint()..color = const Color(0xFFFFD36B);
  static final _questEdge = Paint()
    ..color = const Color(0xFF6E4429)
    ..style = PaintingStyle.stroke;

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
    // Quest destination: a gold star, drawn over the fog so it can lead
    // the player into unexplored water.
    if (FishingQuests.instance.navigationTarget case final t?) {
      final r = (full ? 11 : 6) / s;
      final star = Path();
      for (var i = 0; i < 10; i++) {
        final a = -math.pi / 2 + i * math.pi / 5;
        final p =
            t + Offset(math.cos(a), math.sin(a)) * (i.isEven ? r : r * .45);
        i == 0 ? star.moveTo(p.dx, p.dy) : star.lineTo(p.dx, p.dy);
      }
      star.close();
      canvas.drawPath(star, _quest);
      canvas.drawPath(star, _questEdge..strokeWidth = 1.2 / s);
    }
    canvas.drawCircle(focus, 4.5 / s, _dotRing);
    canvas.drawCircle(focus, 3 / s, _dot);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_MinimapPainter old) =>
      old.round != round || old.base != base || old.full != full;
}
