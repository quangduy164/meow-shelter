import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:material_ui/material_ui.dart';
import '../../fishing/fishing_cabin.dart';
import '../../fishing/fishing_river.dart';
import '../../fishing/river_sea_land.dart';
import '../design.dart';

/// Square minimap: a 3600-unit window that follows the player; fog hides
/// cells the player has not reached this session.
class FishingMinimap extends StatefulWidget {
  const FishingMinimap(
      {super.key, required this.round, required this.frames, this.size = 104});
  final FishingRiverRound round;
  final Listenable frames;
  final double size;
  @override
  State<FishingMinimap> createState() => _FishingMinimapState();
}

class _FishingMinimapState extends State<FishingMinimap> {
  late final ui.Picture _base = _record(widget.size / FishingRiver.height);

  static ui.Picture _record(double s) {
    final recorder = ui.PictureRecorder();
    final c = Canvas(recorder)..scale(s);
    const w = FishingRiver.length, h = FishingRiver.height;
    const regions = [
      (0.0, FishingRiver.mangroveStart, Color(0xFF8DB565)),
      (FishingRiver.mangroveStart, FishingRiver.seaStart, Color(0xFF5E8F4E)),
      (FishingRiver.seaStart, FishingRiver.rockyBayStart, Color(0xFFE2C98A)),
      (FishingRiver.rockyBayStart, FishingRiver.openSeaStart, Color(0xFFA3A5A0)),
      (FishingRiver.openSeaStart, w, Color(0xFFE2C98A)),
    ];
    for (final (from, to, color) in regions) {
      c.drawRect(Rect.fromLTRB(from, 0, to, h), Paint()..color = color);
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
          ..shader = ui.Gradient.linear(
              Offset.zero, const Offset(w, 0), const [
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
    c.drawCircle(fishingSeaIsland.center, fishingSeaIsland.radius,
        Paint()..color = const Color(0xFFEBD49A));
    c.drawCircle(fishingSeaIsland.center, fishingSeaIsland.radius * .62,
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
  Widget build(BuildContext context) => Container(
        width: widget.size + 6,
        height: widget.size + 6,
        decoration: BoxDecoration(
          color: DS.wood,
          borderRadius: BorderRadius.circular(DS.radiusSm),
        ),
        padding: const EdgeInsets.all(3),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(DS.radiusSm - 2),
          child: RepaintBoundary(
            child: CustomPaint(
                size: Size.square(widget.size),
                painter: _MinimapPainter(widget.round, _base, widget.frames)),
          ),
        ),
      );
}

class _MinimapPainter extends CustomPainter {
  _MinimapPainter(this.round, this.base, Listenable frames)
      : super(repaint: frames);
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
    const span = FishingRiver.height;
    final s = size.width / span;
    final focus = round.cameraFocus;
    final left = (focus.dx - span / 2)
        .clamp(0.0, FishingRiver.length - span)
        .toDouble();
    canvas.save();
    canvas.translate(-left * s, 0);
    canvas.drawPicture(base);
    canvas.scale(s);
    const cell = FishingRiverRound.mapCell;
    final first = (left / cell).floor();
    final last = math.min(FishingRiverRound.mapColumns - 1,
        ((left + span) / cell).ceil());
    final fog = Path();
    for (var r = 0; r < FishingRiverRound.mapRows; r++) {
      for (var c = first; c <= last; c++) {
        if (round.isExplored(c, r)) continue;
        final start = c;
        while (c < last && !round.isExplored(c + 1, r)) {
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
      old.round != round || old.base != base;
}
