import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:material_ui/material_ui.dart';

import '../../fishing/fishing_river.dart';
import '../../fishing/fishing_controller.dart';
import 'fishing_river_art.dart';
import 'fishing_oar_art.dart';
import 'fishing_activity_art.dart';
import 'fishing_fight_art.dart';
import 'fishing_river_details.dart';

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
  Widget build(BuildContext context) => RepaintBoundary(
      child: CustomPaint(
          painter:
              _RiverBackdropPainter(widget.round, _pictures, widget.frames)));
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
    final left = math.max(0.0, round.cameraLeft - 30);
    final right = math.min(
        FishingRiver.length, round.cameraLeft + round.visibleWidth + 30);
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.5;
    final firstColumn = (left / 57).floor();
    for (var col = firstColumn; col * 57 < right; col++) {
      final x = col * 57.0 + (round.clock * 8) % 30;
      final rows = (FishingRiver.halfWidth(x) * 2 / 26).floor();
      for (var row = 0; row < rows; row++) {
        final y = FishingRiver.center(x) + (row - (rows - 1) / 2) * 26;
        if (y < FishingRiver.top(x) + 10 || y > FishingRiver.bottom(x) - 10) {
          continue;
        }
        if (y < round.cameraTop - 20 ||
            y > round.cameraTop + round.visibleHeight + 20) {
          continue;
        }
        final phase = round.clock * 1.4 + col * 1.7 + row;
        canvas.drawLine(
            Offset(x, y),
            Offset(x + 15 + math.sin(phase) * 6, y - 1),
            paint
              ..color = Color.fromRGBO(
                  218, 255, 237, .12 + math.sin(phase).abs() * .13));
      }
    }
    for (var col = (left / 90).floor(); col * 90 < right; col++) {
      final x = col * 90.0;
      final sea = FishingRiver.coastBlend(x);
      if (sea <= 0) continue;
      final wave = math.sin(round.clock * 1.8 + col) * 3;
      final y = FishingRiver.bottom(x) - 9 - wave;
      canvas.drawPath(
          Path()
            ..moveTo(x, y)
            ..quadraticBezierTo(x + 18, y + 3, x + 38, y - 1),
          Paint()
            ..color = Color.fromRGBO(237, 255, 239, .65 * sea)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.3);
    }
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
          Paint()..color = const Color(0x44355E65));
      canvas.drawPath(
          Path()
            ..moveTo(x - 6, y)
            ..lineTo(x - 12, y - 4)
            ..lineTo(x - 12, y + 4)
            ..close(),
          Paint()..color = const Color(0x44355E65));
      final leaf = Offset(x + 70, FishingRiver.center(x + 70) + 60);
      if (FishingRiver.coastBlend(x) < .8) {
        canvas.drawOval(Rect.fromCenter(center: leaf, width: 7, height: 3),
            Paint()..color = const Color(0xCCB5C68A));
      }
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

class FishingRiverBoatPainter extends CustomPainter {
  FishingRiverBoatPainter(this.round,
      {this.front = false,
      this.fishing = false,
      this.pawColor = const Color(0xFFF4A34E)});
  final FishingRiverRound round;
  final bool front, fishing;
  final Color pawColor;

  @override
  void paint(Canvas canvas, Size size) {
    final point = round.toScreen(round.boat);
    canvas.save();
    canvas.translate(
        point.dx, point.dy + math.sin(round.clock * 2.5) * 1.8 * round.scale);
    canvas.scale(round.scale);
    final p = Paint();
    const rim = Rect.fromLTWH(-52, -21, 104, 48);
    final rowing = round.moving && !fishing;
    final oar = FishingOarPose(round.clock,
        moving: rowing, facingRight: round.heading.dx >= 0);
    if (!front) {
      if (rowing) paintFishingOarWater(canvas, oar, round.clock);
      if (round.wake > .02) {
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
      canvas.drawOval(const Rect.fromLTWH(-55, -9, 112, 51),
          p..color = const Color(0x33466360));
      canvas.drawOval(
          rim.shift(const Offset(0, 10)), p..color = const Color(0xFF8A603B));
      canvas.drawOval(
          rim.shift(const Offset(0, 5)),
          Paint()
            ..color = const Color(0xFFC39960)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 6);
      canvas.drawOval(rim, p..color = const Color(0xFFE0BB7B));
      canvas.drawOval(rim.deflate(7), p..color = const Color(0xFFA77D4C));
      canvas.save();
      canvas.clipPath(Path()..addOval(rim.deflate(7)));
      for (var i = -3; i < 5; i++) {
        canvas.drawLine(
            Offset(-50, i * 6.0),
            Offset(50, i * 6.0),
            Paint()
              ..color = const Color(0xFF947044)
              ..strokeWidth = 1.3);
        canvas.drawLine(
            Offset(i * 12.0, -25),
            Offset(i * 12.0, 25),
            Paint()
              ..color = const Color(0x55E3C085)
              ..strokeWidth = 1.5);
      }
      canvas.restore();
      canvas.drawOval(
          rim,
          Paint()
            ..color = const Color(0xFF795837)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3);
      canvas.drawOval(
          rim.deflate(4),
          Paint()
            ..color = const Color(0xFFF0D49B)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
      if (!rowing) paintFishingOar(canvas, oar);
    } else {
      canvas.drawArc(
          rim,
          0,
          math.pi,
          false,
          Paint()
            ..color = const Color(0xFFCEAA6E)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 7);
      for (var i = 0; i < 17; i++) {
        final a = i * math.pi / 16;
        final outer = rim.center + Offset(math.cos(a) * 51, math.sin(a) * 23);
        canvas.drawLine(
            outer,
            outer + const Offset(0, 5),
            Paint()
              ..color = const Color(0xFF997344)
              ..strokeWidth = 1.3);
      }
      if (rowing) {
        paintFishingOar(canvas, oar);
        final side = round.heading.dx >= 0 ? 1.0 : -1.0;
        final arm = Path()
          ..moveTo(side * 6, 7)
          ..quadraticBezierTo(side * 15, 10, oar.hand.dx, oar.hand.dy);
        canvas.drawPath(
            arm,
            Paint()
              ..color = const Color(0xFF66513A)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 7
              ..strokeCap = StrokeCap.round);
        canvas.drawPath(
            arm,
            Paint()
              ..color = pawColor
              ..style = PaintingStyle.stroke
              ..strokeWidth = 5
              ..strokeCap = StrokeCap.round);
        canvas.drawCircle(oar.hand, 4, Paint()..color = pawColor);
      }
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              const Rect.fromLTWH(-42, 1, 23, 20), const Radius.circular(4)),
          p..color = const Color(0xFFE2BE7B));
      for (var i = 0; i < 3; i++) {
        canvas.drawLine(
            Offset(-40, 6 + i * 5.0),
            Offset(-21, 6 + i * 5.0),
            Paint()
              ..color = const Color(0xFFAC8553)
              ..strokeWidth = 1.5);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(FishingRiverBoatPainter oldDelegate) => true;
}
