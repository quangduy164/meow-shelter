import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:material_ui/material_ui.dart';

import '../../fishing/fishing_river.dart';
import '../../fishing/river_sea_land.dart';
import '../../fishing/fishing_controller.dart';
import 'fishing_river_art.dart';
import 'fishing_oar_art.dart';
import 'fishing_activity_art.dart';
import 'fishing_fight_art.dart';
import 'fishing_river_details.dart';
import 'fishing_rock_art.dart';
import 'fishing_water_art.dart';
import 'fishing_volcano_art.dart';
import '../../fishing/river_props.dart';
import 'river_encounter_art.dart';
import 'fishing_boat_art.dart';
import '../../fishing/fishing_boat.dart';

/// Like Adventure's cached background: only the visible stretch is replayed.
class FishingRiverBackdrop extends StatefulWidget {
  const FishingRiverBackdrop(
      {super.key, required this.round, required this.frames});
  final FishingRiverRound round;
  final Listenable frames;

  @override
  State<FishingRiverBackdrop> createState() => _FishingRiverBackdropState();
}

class _FishingRiverBackdropState extends State<FishingRiverBackdrop> {
  late final _pictures = [
    for (var i = 0; i < FishingRiver.sectionCount; i++) recordFishingRiver(i)
  ];

  @override
  void dispose() {
    for (final picture in _pictures) {
      picture.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CustomPaint(
      painter: _RiverBackdropPainter(widget.round, _pictures, widget.frames));
}

class _RiverBackdropPainter extends CustomPainter {
  _RiverBackdropPainter(this.round, this.pictures, Listenable frames)
      : super(repaint: frames);
  final FishingRiverRound round;
  final List<ui.Picture> pictures;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.scale(round.scale);
    canvas.translate(-round.cameraLeft, -round.cameraTop);
    for (var i = 0; i < pictures.length; i++) {
      final start = i * FishingRiver.sectionLength;
      if (start > round.cameraLeft + round.visibleWidth ||
          start + FishingRiver.sectionLength < round.cameraLeft) {
        continue;
      }
      canvas.drawPicture(pictures[i]);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_RiverBackdropPainter oldDelegate) =>
      oldDelegate.round != round;
}

final _dryLand = Path.combine(
    PathOperation.union, fishingSeaIsland.outline(), mountainSilhouette());

/// Island + mountain bounds: the costly wet-area clip is only needed here.
final _dryBounds = _dryLand.getBounds();

/// Everything except the island and the mountain rising above it.
final _wetArea = Path.combine(
    PathOperation.difference,
    Path()
      ..addRect(
          const Rect.fromLTWH(0, 0, FishingRiver.length, FishingRiver.height)),
    _dryLand);

final _faintFish = Paint()..color = const Color(0x44355E65);
final _leafPaint = Paint()..color = const Color(0xCCB5C68A);
final _faintTail = Path()
  ..moveTo(-6, 0)
  ..lineTo(-12, -4)
  ..lineTo(-12, 4)
  ..close();

class FishingRiverSurface extends CustomPainter {
  FishingRiverSurface(this.round, Listenable frames, {this.fishing})
      : super(repaint: frames);
  final FishingRiverRound round;
  final FishingController? fishing;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.scale(round.scale);
    canvas.translate(-round.cameraLeft, -round.cameraTop);
    // Surface ripples and swimming animals stay off the cached dry island.
    // Clip only while the island or mountain is on screen (+ ripple margin).
    if (Rect.fromLTWH(round.cameraLeft, round.cameraTop, round.visibleWidth,
            round.visibleHeight)
        .inflate(60)
        .overlaps(_dryBounds)) {
      canvas.clipPath(_wetArea);
    }
    final left = math.max(0.0, round.cameraLeft - 30);
    final right = math.min(
        FishingRiver.length, round.cameraLeft + round.visibleWidth + 30);
    final top = round.cameraTop - 30,
        bottom = round.cameraTop + round.visibleHeight + 30;
    paintWaterSparkles(
        canvas, left, right, top, bottom, round.clock, round.zoom);
    paintSeaSwells(canvas, left, right, top, bottom, round.clock);
    paintShoreWash(canvas, left, right, round.clock);
    // Faint little fish and floating leaves make the long channel feel alive.
    for (var i = (left / 240).floor(); i * 240 < right; i++) {
      var point = Offset(
          i * 240.0 + 80 + math.sin(round.clock * .6 + i) * 18,
          FishingRiver.center(i * 240.0 + 80) +
              math.sin(i * 4.0) *
                  (FishingRiver.halfWidth(i * 240.0 + 80) - 50));
      final away = point - round.boat;
      if (away.distance < 150 && away.distance > .01) {
        point = FishingRiver.constrain(
            point + away / away.distance * (150 - away.distance));
      }
      final x = point.dx, y = point.dy;
      canvas.drawOval(
          Rect.fromCenter(center: Offset(x, y), width: 15, height: 5),
          _faintFish);
      canvas
        ..save()
        ..translate(x, y)
        ..drawPath(_faintTail, _faintFish)
        ..restore();
      final leaf = Offset(x + 70, FishingRiver.center(x + 70) + 60);
      if (FishingRiver.coastBlend(x) < .8) {
        canvas.drawOval(
            Rect.fromCenter(center: leaf, width: 7, height: 3), _leafPaint);
      }
    }
    for (final rock in round.props.rocks) {
      if (rock.kind != RiverPropKind.rock ||
          rock.anchor.dx < left - 120 ||
          rock.anchor.dx > right + 120) {
        continue;
      }
      paintRockFoam(canvas, rock.anchor, rock.radius, round.clock,
          rock.anchor.dx.toInt());
    }
    paintFloatingRiverProps(
        canvas,
        round,
        Rect.fromLTWH(round.cameraLeft, round.cameraTop, round.visibleWidth,
            round.visibleHeight));
    paintRiverWildlife(
        canvas,
        round,
        Rect.fromLTWH(round.cameraLeft, round.cameraTop, round.visibleWidth,
            round.visibleHeight));
    paintRiverEncounters(
        canvas,
        round,
        Rect.fromLTWH(round.cameraLeft, round.cameraTop, round.visibleWidth,
            round.visibleHeight));
    final controller = fishing;
    if (controller != null) {
      if (controller.canSail) {
        for (final activity
            in controller.activities.visible(round.clock, left, right)) {
          paintFishingActivity(canvas, activity, round.clock);
        }
      }
      if (controller.phase == FishingPhase.reeling ||
          controller.phase == FishingPhase.bite) {
        paintFishingFight(canvas, controller);
      }
    }
    final destination = round.destination;
    if (destination != null) {
      final radius = 12 + math.sin(round.clock * 5) * 2;
      canvas.drawOval(
          Rect.fromCenter(
              center: destination, width: radius * 2, height: radius),
          Paint()
            ..color = const Color(0xDDFFF0B2)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5);
      canvas.drawCircle(
          destination, 2, Paint()..color = const Color(0xFFFFF5CE));
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(FishingRiverSurface oldDelegate) =>
      oldDelegate.round != round;
}

// Thúng chai (round basket boat), origin = boat point. The back half and
// woven floor go under the cat; the tarred front wall goes over it so the
// cat sits inside the basket.
const _rim = Rect.fromLTWH(-54, -26, 108, 32); // rim top, centre y = -10
const _depth = 15.0;
final _hullBottom = _rim.shift(const Offset(0, _depth)).deflate(3);
final _boatFill = Paint();
final _boatStroke = Paint()
  ..style = PaintingStyle.stroke
  ..strokeCap = StrokeCap.round;

Path _frontWall() => Path()
  ..addArc(_rim, 0, math.pi)
  ..arcTo(_hullBottom, math.pi, -math.pi, false)
  ..close();
final _wall = _frontWall();

void paintBasketBoatBack(Canvas c) {
  // Shadow in the water and a bright waterline ring around the hull.
  c.drawOval(const Rect.fromLTWH(-60, 4, 120, 30),
      _boatFill..color = const Color(0x40345A5C));
  c.drawOval(
      const Rect.fromLTWH(-58, 2, 116, 26),
      _boatStroke
        ..color = const Color(0x88E9FFF7)
        ..strokeWidth = 2);
  // Back of the tarred hull, peeking out at the sides.
  c.drawPath(
      Path()
        ..addOval(_rim)
        ..addOval(_hullBottom),
      _boatFill..color = const Color(0xFF3B2C21));
  c.drawPath(_wall, _boatFill);
  // Rim top and inside of the basket: darker far wall, lighter floor.
  c.drawOval(_rim, _boatFill..color = const Color(0xFFE3C07F));
  final inner = _rim.deflate(5);
  c.drawOval(inner, _boatFill..color = const Color(0xFF9C7144));
  c.drawOval(
      Rect.fromCenter(
          center: inner.center + const Offset(0, 4),
          width: inner.width - 12,
          height: inner.height - 6),
      _boatFill..color = const Color(0xFFBE905A));
  // Woven bamboo: diagonal weave squashed into the basket's perspective.
  c.save();
  c.clipPath(Path()..addOval(inner));
  c.translate(0, inner.center.dy);
  c.scale(1, inner.height / inner.width);
  _boatStroke.strokeWidth = 2.2;
  for (var i = -8; i <= 8; i++) {
    final x = i * 8.0;
    c.drawLine(Offset(x - 60, -60), Offset(x + 60, 60),
        _boatStroke..color = const Color(0x40603F1F));
    c.drawLine(Offset(x + 60, -60), Offset(x - 60, 60),
        _boatStroke..color = const Color(0x2EFFE7B0));
  }
  c.restore();
  // Inner wall shade under the far rim.
  c.drawArc(
      inner.deflate(1),
      math.pi,
      math.pi,
      false,
      _boatStroke
        ..color = const Color(0x55402A15)
        ..strokeWidth = 4);
  // Rim outline, highlight and rope lashings on the far side.
  c.drawOval(
      _rim,
      _boatStroke
        ..color = const Color(0xFF6B4729)
        ..strokeWidth = 2.5);
  c.drawOval(
      _rim.deflate(2.5),
      _boatStroke
        ..color = const Color(0xFFF6DDA6)
        ..strokeWidth = 1.4);
  _paintLashings(c, math.pi, 2 * math.pi);
}

void paintBasketBoatFront(Canvas c) {
  // Tarred front wall with a soft top-to-bottom shade.
  c.drawPath(
      _wall,
      _boatFill
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF55402E), Color(0xFF2E231B)],
        ).createShader(Rect.fromLTRB(-54, -10, 54, _hullBottom.bottom)));
  _boatFill.shader = null;
  // Faint woven ribs showing through the tar.
  c.save();
  c.clipPath(_wall);
  _boatStroke
    ..color = const Color(0x1FFFE2B0)
    ..strokeWidth = 1.2;
  for (var i = 1; i < 12; i++) {
    final t = i * math.pi / 12;
    final top = Offset(math.cos(t) * 54, -10 + math.sin(t) * 16);
    final bottom = Offset(math.cos(t) * 51, -10 + _depth + math.sin(t) * 13);
    c.drawLine(top, bottom, _boatStroke);
  }
  c.restore();
  // Water glinting along the bottom of the hull.
  c.drawArc(
      _hullBottom.deflate(2),
      math.pi * .2,
      math.pi * .45,
      false,
      _boatStroke
        ..color = const Color(0x55FFFFFF)
        ..strokeWidth = 1.6);
  // Thick bamboo lip on the near rim.
  c.drawArc(
      _rim,
      0,
      math.pi,
      false,
      _boatStroke
        ..color = const Color(0xFFD9B26F)
        ..strokeWidth = 5);
  c.drawArc(
      _rim.inflate(2.2),
      0,
      math.pi,
      false,
      _boatStroke
        ..color = const Color(0xFF6B4729)
        ..strokeWidth = 1.6);
  c.drawArc(
      _rim.deflate(1),
      .15,
      math.pi - .3,
      false,
      _boatStroke
        ..color = const Color(0xFFF6DDA6)
        ..strokeWidth = 1.2);
  _paintLashings(c, 0, math.pi);
}

/// Rope bindings across the rim between angles [from] and [to].
void _paintLashings(Canvas c, double from, double to) {
  for (var a = from + .25; a < to; a += math.pi / 5) {
    final p = Offset(_rim.center.dx + math.cos(a) * _rim.width / 2,
        _rim.center.dy + math.sin(a) * _rim.height / 2);
    final along = Offset(-math.sin(a) * _rim.width, math.cos(a) * _rim.height);
    final dir = along / along.distance;
    for (final k in [-1.6, 1.6]) {
      final q = p + dir * k;
      c.drawLine(
          q + const Offset(0, -3),
          q + const Offset(0, 3),
          _boatStroke
            ..color = const Color(0xFF7A5A33)
            ..strokeWidth = 1.6);
    }
  }
}

class FishingRiverBoatPainter extends CustomPainter {
  FishingRiverBoatPainter(this.round,
      {this.front = false, this.fishing = false});
  final FishingRiverRound round;
  final bool front, fishing;

  @override
  void paint(Canvas canvas, Size size) {
    final point = round.toScreen(round.boat);
    canvas.save();
    canvas.translate(
        point.dx, point.dy + math.sin(round.clock * 2.5) * 1.8 * round.scale);
    canvas.scale(round.scale);
    final rowing = round.moving && !fishing;
    final oar = FishingOarPose(round.clock,
        moving: rowing, facingRight: round.heading.dx >= 0);
    if (!front) {
      if (rowing) paintFishingOarWater(canvas, oar, round.clock);
      if (round.wake > .02) {
        // Foam trails spreading behind the boat.
        final back = -round.heading.dx >= 0 ? 1.0 : -1.0;
        for (final side in [-1.0, 1.0]) {
          for (var i = 0; i < 7; i++) {
            final t = ((round.clock * 1.8 + i / 7) % 1);
            final q = Offset(back * (40 + t * 70), 14 + side * (8 + t * 22));
            canvas.drawCircle(
                q,
                2 + t * 3,
                Paint()
                  ..color =
                      Color.fromRGBO(245, 252, 250, (1 - t) * .7 * round.wake));
          }
        }
        for (var i = 0; i < 3; i++) {
          final t = (round.clock * 1.5 + i / 3) % 1;
          canvas.drawOval(
              Rect.fromCenter(
                  center: Offset(-round.heading.dx * t * 22, 10),
                  width: 105 + t * 60,
                  height: 40 + t * 25),
              Paint()
                ..color =
                    Color.fromRGBO(220, 255, 243, (1 - t) * .45 * round.wake)
                ..style = PaintingStyle.stroke
                ..strokeWidth = 2);
        }
      }
      if (round.boatStyle == FishingBoat.paper) {
        paintPaperBoatBack(canvas);
      } else {
        paintBasketBoatBack(canvas);
      }
    } else {
      if (round.boatStyle == FishingBoat.paper) {
        paintPaperBoatFront(canvas);
      } else {
        paintBasketBoatFront(canvas);
      }
      // The cat sprite has no rowing arm; the oar simply moves on its own.
      if (rowing) paintFishingOar(canvas, oar);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(FishingRiverBoatPainter oldDelegate) => true;
}
