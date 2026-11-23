import 'dart:math' as math;
import 'package:flutter/painting.dart';
import '../../fishing/fishing_river.dart';
import '../../fishing/river_props.dart';
import 'river_toy_art.dart';
import 'fishing_coast_art.dart';
import 'fishing_rock_art.dart';

/// Solid rocks and submerged coral are recorded with the landscape.
void paintRiverDetails(Canvas c, double left, double right) {
  for (var i = 0; i < ((FishingRiver.length - 420) / 265).ceil(); i++) {
    final x = 420.0 + i * 265;
    if (x < left - 180 || x > right + 180) continue;
    final north = i.isEven;
    final bank = north ? FishingRiver.top(x) : FishingRiver.bottom(x);
    final p = Offset(x, bank + (north ? 95 : -100));
    final rng = math.Random(927 + i);
    if (x >= FishingRiver.seaStart &&
        (x < FishingRiver.rockyBayStart - 300 ||
            x > FishingRiver.openSeaStart + 300)) {
      for (var j = 0; j < 8; j++) {
        final q = p +
            Offset(rng.nextDouble() * 210 - 105, rng.nextDouble() * 100 - 50);
        _coral(c, q, j);
      }
    }
  }
  // Each inlet has a landmark at its far end, inviting vertical exploration.
  for (final cove in FishingRiver.coves) {
    if (cove.x < left - 150 || cove.x > right + 150) continue;
    final edge =
        cove.north ? FishingRiver.top(cove.x) : FishingRiver.bottom(cove.x);
    final p = Offset(cove.x, edge + (cove.north ? 75 : -75));
    if (cove.x >= 3500) {
      // Sand sits on dry land; the turquoise lagoon remains fully navigable.
      final sand = Offset(cove.x, edge - 45);
      c.drawOval(Rect.fromCenter(center: sand, width: 190, height: 65),
          Paint()..color = const Color(0xFFF3E2B7));
      for (var i = 0; i < 7; i++) {
        c.drawArc(
            Rect.fromCenter(
                center: sand + Offset(i * 18 - 50, 6), width: 9, height: 7),
            math.pi,
            math.pi,
            true,
            Paint()..color = const Color(0xFFD5AF98));
      }
      for (var i = 0; i < 7; i++) {
        _coral(c, p + Offset(i * 25 - 80, math.sin(i * 2) * 22), i);
      }
    }
  }
  for (final rock in createRiverProps().where((p) => p.solid)) {
    if (rock.anchor.dx < left - rock.radius - 80 ||
        rock.anchor.dx > right + rock.radius + 80) {
      continue;
    }
    if (rock.kind == RiverPropKind.island) {
      paintFishingIsland(c, rock.anchor, rock.radius);
    } else if (rock.kind == RiverPropKind.market ||
        rock.kind == RiverPropKind.shrine ||
        rock.kind == RiverPropKind.baitHouse) {
      // Structures have cached painters above the water surface.
    } else if (rock.kind != RiverPropKind.mangroveRoot &&
        rock.kind != RiverPropKind.cabinShip) {
      paintRiverRock(c, rock.anchor, rock.radius);
    }
  }
}

void paintFloatingRiverProps(Canvas c, FishingRiverRound round, Rect visible) {
  for (final prop in round.props.items) {
    if (prop.solid || !visible.inflate(80).contains(prop.position)) continue;
    final p = prop.position +
        Offset(0, math.sin(round.clock * 1.8 + prop.anchor.dx) * 1.8);
    if (prop.ripple > 0) {
      final t = 1 - prop.ripple / .8;
      c.drawOval(
          Rect.fromCenter(
              center: prop.position, width: 65 + t * 55, height: 25 + t * 20),
          Paint()
            ..color = Color.fromRGBO(223, 249, 228, (1 - t) * .5)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5);
    }
    c.save();
    c.translate(p.dx, p.dy);
    c.rotate(prop.angle + math.sin(round.clock * .7 + prop.anchor.dx) * .035);
    c.translate(-p.dx, -p.dy);
    switch (prop.kind) {
      case RiverPropKind.lily:
        _lily(c, p, flower: prop.flower);
      case RiverPropKind.raft:
        _raft(c, p);
      case RiverPropKind.log:
        _log(c, p);
      case RiverPropKind.paperBoat:
        paintPaperBoat(c, p);
      case RiverPropKind.cabinShip:
      case RiverPropKind.market:
      case RiverPropKind.shrine:
      case RiverPropKind.baitHouse:
      case RiverPropKind.mangroveRoot:
      case RiverPropKind.island:
      case RiverPropKind.rock:
        break;
    }
    c.restore();
  }
  final frogView = visible.inflate(100);
  for (final frog in round.props.frogs) {
    if (frogView.contains(frog.position)) {
      final lily = round.props.items[frog.lilyIndex];
      paintRiverFrog(c, frog, round.clock,
          bob: math.sin(round.clock * 1.8 + lily.anchor.dx) * 1.8);
    }
  }
}

void _lily(Canvas c, Offset p, {bool flower = false}) {
  p = Offset(p.dx,
      p.dy.clamp(FishingRiver.top(p.dx) + 55, FishingRiver.bottom(p.dx) - 55));
  c.drawOval(
      Rect.fromCenter(center: p + const Offset(2, 4), width: 34, height: 16),
      Paint()..color = const Color(0x22446861));
  c.drawArc(Rect.fromCenter(center: p, width: 31, height: 18), .35,
      math.pi * 1.82, true, Paint()..color = const Color(0xFF70A880));
  c.drawArc(
      Rect.fromCenter(center: p - const Offset(3, 2), width: 19, height: 9),
      math.pi,
      math.pi,
      false,
      Paint()
        ..color = const Color(0xFF9FC18C)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5);
  if (!flower) return;
  for (var i = 0; i < 5; i++) {
    c.drawOval(
        Rect.fromCenter(
            center: p + Offset((i - 2) * 3.0, -5 - (2 - (i - 2).abs()) * 2),
            width: 7,
            height: 13),
        Paint()
          ..color =
              i.isEven ? const Color(0xFFF2B8C4) : const Color(0xFFFFDCE1));
  }
  c.drawCircle(
      p - const Offset(0, 5), 3, Paint()..color = const Color(0xFFFFDE91));
}

void _raft(Canvas c, Offset p) {
  p = Offset(p.dx,
      p.dy.clamp(FishingRiver.top(p.dx) + 55, FishingRiver.bottom(p.dx) - 55));
  c.save();
  c.translate(p.dx, p.dy);
  c.rotate(-.12);
  c.drawOval(const Rect.fromLTWH(-42, -17, 88, 42),
      Paint()..color = const Color(0x22416553));
  for (var i = 0; i < 7; i++) {
    final x = i * 10 - 32.0;
    c.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(x, -25, 8, 55), const Radius.circular(3)),
        Paint()
          ..color =
              i.isEven ? const Color(0xFFC9B27A) : const Color(0xFFA78F60));
  }
  for (final y in [-17.0, 20.0]) {
    c.drawLine(
        Offset(-35, y),
        Offset(34, y),
        Paint()
          ..color = const Color(0xFF77684C)
          ..strokeWidth = 3);
  }
  for (var i = 0; i < 6; i++) {
    final q = Offset((i % 3) * 19 - 20.0, (i ~/ 3) * 20 - 9.0);
    c.drawCircle(q, 10, Paint()..color = const Color(0xFF598653));
    c.drawOval(
        Rect.fromCenter(center: q - const Offset(2, 2), width: 17, height: 9),
        Paint()..color = const Color(0xFF94B46D));
  }
  c.restore();
}

void paintRiverRock(Canvas c, Offset p, double r) {
  p = Offset(p.dx,
      p.dy.clamp(FishingRiver.top(p.dx) + 55, FishingRiver.bottom(p.dx) - 55));
  paintBoulder(c, p, r, (p.dx * 3 + p.dy * 7).toInt());
}

void _log(Canvas c, Offset p) {
  p = Offset(p.dx,
      p.dy.clamp(FishingRiver.top(p.dx) + 55, FishingRiver.bottom(p.dx) - 55));
  c.save();
  c.translate(p.dx, p.dy);
  c.rotate(-.25);
  final bark = Paint()
    ..color = const Color(0xFF886D4C)
    ..strokeWidth = 15
    ..strokeCap = StrokeCap.round;
  c.drawLine(const Offset(-38, 0), const Offset(40, 0), bark);
  c.drawLine(const Offset(0, 0), const Offset(17, -20), bark..strokeWidth = 7);
  c.drawLine(
      const Offset(-32, -3),
      const Offset(32, -3),
      Paint()
        ..color = const Color(0xFFB69B6D)
        ..strokeWidth = 2);
  c.drawOval(const Rect.fromLTWH(33, -7, 12, 14),
      Paint()..color = const Color(0xFFD3BC88));
  c.drawOval(
      const Rect.fromLTWH(36, -4, 6, 8),
      Paint()
        ..color = const Color(0xFF9F865C)
        ..style = PaintingStyle.stroke);
  c.restore();
}

void _coral(Canvas c, Offset p, int seed) {
  p = Offset(p.dx,
      p.dy.clamp(FishingRiver.top(p.dx) + 55, FishingRiver.bottom(p.dx) - 55));
  c.drawOval(Rect.fromCenter(center: p, width: 55, height: 24),
      Paint()..color = const Color(0x224D8F90));
  final paint = Paint()
    ..color = [
      const Color(0x668FC7B1),
      const Color(0x66E8AF9E),
      const Color(0x66BCA9CB)
    ][seed % 3]
    ..strokeWidth = 5
    ..strokeCap = StrokeCap.round;
  for (var i = 0; i < 4; i++) {
    final q = p + Offset((i - 2) * 10.0, -12 - (i % 2) * 8);
    c.drawLine(p, q, paint);
    c.drawLine(q, q + const Offset(-7, -9), paint);
    c.drawLine(q, q + const Offset(6, -8), paint);
  }
}

/// Only a few visible animals animate; no world-sized per-frame scene rebuild.
void paintRiverWildlife(Canvas c, FishingRiverRound round, Rect visible) {
  final duckView = visible.inflate(35);
  for (final duck in round.props.ducks) {
    if (!duckView.contains(duck.position)) continue;
    final bob = math.sin(round.clock * 2.5 + duck.phase) * 1.2;
    _duck(c, duck.position + Offset(0, bob), duck.size, duck.facing);
  }
  for (var group = 4; group < round.props.wildlifeOffsets.length; group++) {
    final x = 480 + group * 420.0;
    if (x < visible.left - 160 || x > visible.right + 160) continue;
    final sea = x >= FishingRiver.seaStart;
    final base =
        RiverProps.wildlifeHome(group) + round.props.wildlifeOffsets[group];
    if (!visible.inflate(140).contains(base)) continue;
    final time = round.clock;
    {
      for (var i = 0; i < 7; i++) {
        final p = RiverProp.waterPoint(base +
            Offset(math.sin(time * .35 + group) * 80 + (i % 3) * 23,
                (i ~/ 3) * 18 + math.sin(time * 2 + i) * 4));
        c.drawOval(Rect.fromCenter(center: p, width: 14, height: 5),
            Paint()..color = const Color(0x44516E79));
        c.drawPath(
            Path()
              ..moveTo(p.dx - 6, p.dy)
              ..lineTo(p.dx - 12, p.dy - 4)
              ..lineTo(p.dx - 12, p.dy + 4)
              ..close(),
            Paint()..color = const Color(0x44516E79));
      }
    }
    if (sea &&
        (x < FishingRiver.rockyBayStart || x >= FishingRiver.openSeaStart)) {
      for (var i = 0; i < 2; i++) {
        final p = base +
            Offset(math.sin(time * .15 + group) * 120 + i * 65, -110 + i * 26);
        final flap = math.sin(time * 3 + i) * 8;
        c.drawPath(
            Path()
              ..moveTo(p.dx - 12, p.dy + flap)
              ..quadraticBezierTo(p.dx - 6, p.dy - 5, p.dx, p.dy)
              ..quadraticBezierTo(p.dx + 6, p.dy - 5, p.dx + 12, p.dy + flap),
            Paint()
              ..color = const Color(0xDDEDF4E8)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3
              ..strokeCap = StrokeCap.round);
      }
    }
  }
}

void _duck(Canvas c, Offset p, double scale, double facing) {
  c.save();
  c.translate(p.dx, p.dy);
  c.scale(scale * (facing == 0 ? 1 : facing), scale);
  c.drawOval(
      const Rect.fromLTWH(-19, 3, 38, 12),
      Paint()
        ..color = const Color(0x44D9F0DD)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5);
  c.drawOval(const Rect.fromLTWH(-15, -6, 28, 17),
      Paint()..color = const Color(0xFFFFE4A3));
  c.drawOval(const Rect.fromLTWH(-10, -3, 15, 9),
      Paint()..color = const Color(0xFFE7C17A));
  c.drawCircle(
      const Offset(10, -9), 8, Paint()..color = const Color(0xFFFFEDBC));
  c.drawPath(
      Path()
        ..moveTo(16, -10)
        ..lineTo(24, -7)
        ..lineTo(16, -4)
        ..close(),
      Paint()..color = const Color(0xFFE99F50));
  c.drawCircle(
      const Offset(12, -11), 1.6, Paint()..color = const Color(0xFF4B5144));
  c.restore();
}
