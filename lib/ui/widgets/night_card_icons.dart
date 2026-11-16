import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../game/night_shift/night_cards.dart';

/// Hand-drawn badge art for each night-shift card, in the same chunky
/// outlined style as the camp icons. Drawn on a 48x48 grid and scaled.
class NightCardIcon extends StatelessWidget {
  const NightCardIcon(this.card, {super.key, this.size = 64});
  final NightCard card;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
      dimension: size, child: CustomPaint(painter: _NightCardPainter(card)));
}

const _ink = Color(0xFF5A3214);
const _cream = Color(0xFFFFF4DA);
const _gold = Color(0xFFFFC24D);
const _goldDark = Color(0xFFD9962B);
const _wood = Color(0xFFB27A3E);
const _woodLight = Color(0xFFE7C3A3);
const _pink = Color(0xFFE85D6F);
const _orange = Color(0xFFF28A3A);
const _blue = Color(0xFF7FB3C7);

class _NightCardPainter extends CustomPainter {
  const _NightCardPainter(this.card);
  final NightCard card;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 48, size.height / 48);
    _badge(canvas);
    switch (card) {
      case NightCard.scentedFish:
        _scentedFish(canvas);
      case NightCard.warmHug:
        _warmHug(canvas);
      case NightCard.patience:
        _patience(canvas);
      case NightCard.lazyLunch:
        _lazyLunch(canvas);
      case NightCard.wideBeds:
        _wideBeds(canvas);
      case NightCard.fishBasket:
        _fishBasket(canvas);

      case NightCard.nailedBeds:
        _nailedBeds(canvas);
      case NightCard.longNight:
        _longNight(canvas);
      case NightCard.eagerHelpers:
        _eagerHelpers(canvas);
      case NightCard.hotCoins:
        _hotCoins(canvas);
      case NightCard.nightWind:
        _nightWind(canvas);
      case NightCard.longWick:
        _longWick(canvas);
      case NightCard.extraLantern:
        _extraLantern(canvas);
      case NightCard.brightLantern:
        _brightLantern(canvas);
      case NightCard.fullMoon:
        _fullMoon(canvas);
      case NightCard.crowd:
        _crowd(canvas);
      case NightCard.hiddenFish:
        _hiddenFish(canvas);
      case NightCard.quietSteps:
        _quietSteps(canvas);
      case NightCard.softWheels:
        _softWheels(canvas);
      case NightCard.backupPower:
        _backupPower(canvas);
      case NightCard.quietCorner:
        _quietCorner(canvas);
      case NightCard.busyMarket:
        _busyMarket(canvas);
      case NightCard.sturdyPlanks:
        _sturdyPlanks(canvas);
      case NightCard.quickCarpenter:
        _quickCarpenter(canvas);
      case NightCard.widePlanks:
        _widePlanks(canvas);
      case NightCard.railLights:
        _railLights(canvas);
      case NightCard.stormyRoof:
        _stormyRoof(canvas);
      case NightCard.quietDoors:
      case NightCard.twinCages:
      case NightCard.deepBait:
      case NightCard.linkedDoors:
        _trapCard(canvas);
      case NightCard.lanternRelay:
      case NightCard.moonEcho:
      case NightCard.restingLight:
      case NightCard.fewerLanterns:
      case NightCard.cartFish:
      case NightCard.gentleCart:
      case NightCard.afterHours:
      case NightCard.closingBell:
      case NightCard.pairedBridges:
      case NightCard.lastStep:
      case NightCard.sharedFish:
      case NightCard.autoBridge:
      case NightCard.relayRescue:
      case NightCard.fishReserve:
      case NightCard.rescueRhythm:
      case NightCard.preparedBait:
      case NightCard.nurturingMeal:
        _newFeature(canvas);
    }
  }

  void _trapCard(Canvas canvas) {
    final box = RRect.fromRectAndRadius(
        const Rect.fromLTWH(7, 14, 34, 25), const Radius.circular(4));
    canvas.drawRRect(box, _fill(_woodLight));
    canvas.drawRRect(box, _line(2.3));
    for (var x = 13.0; x < 40; x += 7) {
      canvas.drawLine(Offset(x, 16), Offset(x, 37), _line(1.3));
    }
    if (card == NightCard.deepBait) {
      _fish(canvas, const Offset(27, 27), 21, _blue);
    } else if (card == NightCard.twinCages) {
      canvas.drawLine(
          const Offset(24, 15), const Offset(24, 38), _line(4, _goldDark));
    } else if (card == NightCard.linkedDoors) {
      _arrow(canvas, const Offset(8, 9), const Offset(39, 9));
    } else {
      _featureSpark(canvas, const Offset(34, 12), 7, _blue);
    }
  }

  void _newFeature(Canvas canvas) {
    switch (card) {
      case NightCard.lanternRelay:
        _extraLantern(canvas);
        _arrow(canvas, const Offset(9, 18), const Offset(37, 18));
      case NightCard.moonEcho:
        _fullMoon(canvas);
        for (var i = 0; i < 3; i++) {
          canvas.drawOval(
              Rect.fromCenter(
                  center: Offset(14 + i * 10, 36), width: 12, height: 5),
              _fill(_blue.withValues(alpha: .3 + i * .2)));
        }
      case NightCard.restingLight:
        _warmHug(canvas);
        _featureSpark(canvas, const Offset(35, 12), 6, _gold);
      case NightCard.fewerLanterns:
        _extraLantern(canvas);
        canvas.drawLine(
            const Offset(9, 38), const Offset(38, 9), _line(4, _pink));
      case NightCard.cartFish:
      case NightCard.gentleCart:
        _softWheels(canvas);
        if (card == NightCard.cartFish) {
          _fish(canvas, const Offset(25, 17), 24, _blue);
        } else {
          canvas.drawArc(const Rect.fromLTWH(8, 8, 31, 24), math.pi, math.pi,
              false, _line(2, _blue));
        }
      case NightCard.afterHours:
        _longNight(canvas);
        _featureSpark(canvas, const Offset(36, 34), 5, _blue);
      case NightCard.closingBell:
        _extraLantern(canvas);
        canvas.drawArc(const Rect.fromLTWH(6, 11, 36, 22), math.pi, math.pi,
            false, _line(2, _blue));
      case NightCard.pairedBridges:
        _widePlanks(canvas);
        _arrow(canvas, const Offset(10, 11), const Offset(38, 11));
      case NightCard.lastStep:
        _sturdyPlanks(canvas);
        canvas.drawCircle(const Offset(35, 12), 7, _fill(_gold));
        canvas.drawLine(const Offset(35, 7), const Offset(35, 14), _line(2));
      case NightCard.autoBridge:
        _quickCarpenter(canvas);
        canvas.drawArc(const Rect.fromLTWH(6, 6, 36, 36), 0, math.pi * 1.5,
            false, _line(2.4, _blue));
      case NightCard.sharedFish:
        canvas.drawOval(const Rect.fromLTWH(7, 25, 35, 14), _fill(_woodLight));
        canvas.drawOval(const Rect.fromLTWH(7, 25, 35, 14), _line(2));
        _fish(canvas, const Offset(23, 20), 26, _blue);
        canvas.drawLine(
            const Offset(23, 14), const Offset(23, 25), _line(1.5, _cream));
      case NightCard.relayRescue:
        _eagerHelpers(canvas);
        _featureSpark(canvas, const Offset(36, 12), 6, _gold);
      case NightCard.fishReserve:
        _fish(canvas, const Offset(25, 25), 29, _blue);
        canvas.drawArc(const Rect.fromLTWH(6, 7, 35, 34), math.pi * .7,
            math.pi * 1.3, false, _line(2.5, _goldDark));
        _arrow(canvas, const Offset(12, 12), const Offset(7, 23));
      case NightCard.rescueRhythm:
        _fish(canvas, const Offset(20, 29), 23, _blue);
        _featureSpark(canvas, const Offset(33, 15), 9, _gold);
        _featureSpark(canvas, const Offset(13, 11), 4, _gold);
      case NightCard.preparedBait:
        _fishBasket(canvas);
        _featureSpark(canvas, const Offset(35, 12), 7, _blue);
      case NightCard.nurturingMeal:
        _fish(canvas, const Offset(24, 27), 27, _blue);
        for (final x in [12.0, 24.0, 36.0]) {
          _featureSpark(canvas, Offset(x, 12), 4, _pink);
        }
      default:
        break;
    }
  }

  void _featureSpark(Canvas canvas, Offset center, double radius, Color color) {
    final path = Path();
    for (var i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      final r = radius * (i.isEven ? 1 : .35);
      final p = center + Offset(math.cos(angle) * r, math.sin(angle) * r);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    _shape(canvas, path, color, 1.2);
  }

  void _arrow(Canvas canvas, Offset from, Offset to) {
    canvas.drawLine(from, to, _line(2.5, _goldDark));
    final direction = (from - to) / (from - to).distance;
    final normal = Offset(-direction.dy, direction.dx);
    canvas.drawLine(to, to + direction * 6 + normal * 4, _line(2.5, _goldDark));
    canvas.drawLine(to, to + direction * 6 - normal * 4, _line(2.5, _goldDark));
  }

  // ---- shared bits -------------------------------------------------------

  Paint _fill(Color c) => Paint()..color = c;
  Paint _line([double w = 2, Color c = _ink]) => Paint()
    ..color = c
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  /// Fills [path] with [color] and draws the ink outline on top.
  void _shape(Canvas canvas, Path path, Color color, [double w = 2]) {
    canvas.drawPath(path, _fill(color));
    canvas.drawPath(path, _line(w));
  }

  Path _oval(Offset c, double w, double h) =>
      Path()..addOval(Rect.fromCenter(center: c, width: w, height: h));

  /// Round backdrop: warm cream for upgrades, deep plum with gold for deals.
  void _badge(Canvas canvas) {
    final deal = card.isDeal;
    canvas.drawCircle(
        const Offset(24, 25.5), 23, _fill(const Color(0x33000000)));
    canvas.drawCircle(const Offset(24, 24), 23,
        _fill(deal ? const Color(0xFF4E3A63) : const Color(0xFFFFE3B0)));
    canvas.drawCircle(
        const Offset(24, 24), 22, _line(2.5, deal ? _gold : _wood));
    canvas.drawArc(
        Rect.fromCircle(center: const Offset(24, 24), radius: 18),
        math.pi * 1.1,
        math.pi * .5,
        false,
        _line(2.5, deal ? const Color(0x33FFFFFF) : const Color(0x88FFFFFF)));
  }

  /// A plump fish facing right, centred on [c].
  void _fish(Canvas canvas, Offset c, double len, Color color,
      {double angle = 0}) {
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(angle);
    final h = len * .52;
    final tail = Path()
      ..moveTo(-len * .32, 0)
      ..lineTo(-len * .58, -h * .55)
      ..quadraticBezierTo(-len * .5, 0, -len * .58, h * .55)
      ..close();
    _shape(canvas, tail, Color.lerp(color, _ink, .15)!, 1.6);
    final body = Path()
      ..moveTo(len * .45, 0)
      ..quadraticBezierTo(len * .2, -h * .62, -len * .1, -h * .5)
      ..quadraticBezierTo(-len * .4, -h * .3, -len * .36, 0)
      ..quadraticBezierTo(-len * .4, h * .3, -len * .1, h * .5)
      ..quadraticBezierTo(len * .2, h * .62, len * .45, 0)
      ..close();
    _shape(canvas, body, color, 1.6);
    canvas.drawPath(
        Path()
          ..moveTo(len * .08, -h * .42)
          ..quadraticBezierTo(len * .02, 0, len * .08, h * .42),
        _line(1.2, Color.lerp(color, _ink, .35)!));
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(-len * .12, -h * .18),
            width: len * .2,
            height: h * .16),
        _fill(const Color(0x66FFFFFF)));
    canvas.drawCircle(Offset(len * .25, -h * .1), len * .055, _fill(_ink));
    canvas.restore();
  }

  void _heart(Canvas canvas, Offset c, double s, Color color) {
    final path = Path()
      ..moveTo(c.dx, c.dy + s * .45)
      ..cubicTo(c.dx - s * .9, c.dy - s * .05, c.dx - s * .5, c.dy - s * .75,
          c.dx, c.dy - s * .32)
      ..cubicTo(c.dx + s * .5, c.dy - s * .75, c.dx + s * .9, c.dy - s * .05,
          c.dx, c.dy + s * .45)
      ..close();
    _shape(canvas, path, color);
    canvas.drawOval(
        Rect.fromCenter(
            center: c + Offset(-s * .3, -s * .3),
            width: s * .22,
            height: s * .14),
        _fill(const Color(0x99FFFFFF)));
  }

  void _paw(Canvas canvas, Offset c, double s, Color color) {
    _shape(canvas, _oval(c + Offset(0, s * .18), s * .62, s * .5), color, 1.6);
    for (final (dx, dy) in const [
      (-.36, -.16),
      (-.13, -.38),
      (.13, -.38),
      (.36, -.16)
    ]) {
      _shape(canvas, _oval(c + Offset(dx * s, dy * s), s * .2, s * .25), color,
          1.4);
    }
  }

  /// A round cushion bed seen from the front.
  void _bed(Canvas canvas, Rect r) {
    _shape(canvas, Path()..addOval(r), const Color(0xFF8C5A34));
    _shape(
        canvas,
        Path()
          ..addOval(r.deflate(r.height * .2).shift(Offset(0, r.height * .06))),
        _woodLight,
        1.6);
    canvas.drawArc(
        r.deflate(r.height * .32).shift(Offset(0, r.height * .04)),
        math.pi * 1.1,
        math.pi * .5,
        false,
        _line(1.4, const Color(0x99FFFFFF)));
  }

  void _star(Canvas canvas, Offset c, double r, Color color) {
    final path = Path();
    for (var i = 0; i < 8; i++) {
      final rad = i.isEven ? r : r * .38;
      final a = -math.pi / 2 + i * math.pi / 4;
      final p = c + Offset(math.cos(a) * rad, math.sin(a) * rad);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(path..close(), _fill(color));
  }

  void _flame(Canvas canvas, Offset base, double s) {
    final outer = Path()
      ..moveTo(base.dx, base.dy)
      ..cubicTo(base.dx - s * .55, base.dy - s * .05, base.dx - s * .45,
          base.dy - s * .55, base.dx - s * .05, base.dy - s)
      ..cubicTo(base.dx + s * .02, base.dy - s * .6, base.dx + s * .3,
          base.dy - s * .62, base.dx + s * .3, base.dy - s * .78)
      ..cubicTo(base.dx + s * .6, base.dy - s * .45, base.dx + s * .5,
          base.dy - s * .05, base.dx, base.dy)
      ..close();
    _shape(canvas, outer, _orange, 1.6);
    final inner = Path()
      ..moveTo(base.dx, base.dy - s * .08)
      ..cubicTo(base.dx - s * .28, base.dy - s * .12, base.dx - s * .2,
          base.dy - s * .42, base.dx + s * .02, base.dy - s * .6)
      ..cubicTo(base.dx + s * .28, base.dy - s * .38, base.dx + s * .26,
          base.dy - s * .12, base.dx, base.dy - s * .08)
      ..close();
    canvas.drawPath(inner, _fill(const Color(0xFFFFD866)));
  }

  void _catHead(Canvas canvas, Offset c, double r, Color fur, {Color? patch}) {
    final head = Path()
      ..moveTo(c.dx - r * .95, c.dy - r * .1)
      ..lineTo(c.dx - r * .85, c.dy - r * 1.15)
      ..lineTo(c.dx - r * .3, c.dy - r * .8)
      ..quadraticBezierTo(c.dx, c.dy - r * .92, c.dx + r * .3, c.dy - r * .8)
      ..lineTo(c.dx + r * .85, c.dy - r * 1.15)
      ..lineTo(c.dx + r * .95, c.dy - r * .1)
      ..quadraticBezierTo(c.dx + r, c.dy + r * .85, c.dx, c.dy + r * .85)
      ..quadraticBezierTo(
          c.dx - r, c.dy + r * .85, c.dx - r * .95, c.dy - r * .1)
      ..close();
    canvas.drawPath(head, _fill(fur));
    if (patch != null) {
      canvas.save();
      canvas.clipPath(head);
      canvas.drawCircle(c + Offset(r * .7, -r * .7), r * .8, _fill(patch));
      canvas.restore();
    }
    canvas.drawPath(head, _line(1.6));
    final eye =
        _fill(fur.computeLuminance() < .2 ? const Color(0xFFFFE066) : _ink);
    canvas.drawOval(
        Rect.fromCenter(
            center: c + Offset(-r * .38, r * .05),
            width: r * .2,
            height: r * .28),
        eye);
    canvas.drawOval(
        Rect.fromCenter(
            center: c + Offset(r * .38, r * .05),
            width: r * .2,
            height: r * .28),
        eye);
    canvas.drawPath(
        Path()
          ..moveTo(c.dx - r * .1, c.dy + r * .3)
          ..lineTo(c.dx + r * .1, c.dy + r * .3)
          ..lineTo(c.dx, c.dy + r * .42)
          ..close(),
        _fill(_pink));
  }

  // ---- cards ------------------------------------------------------------

  void _scentedFish(Canvas canvas) {
    for (final x in const [15.0, 24.0, 33.0]) {
      canvas.drawPath(
          Path()
            ..moveTo(x, 21)
            ..cubicTo(x - 4, 17, x + 4, 14, x, 10)
            ..cubicTo(x - 3, 7.5, x + 1, 6, x + 1, 5.5),
          _line(2.2, const Color(0xCCE85D6F)));
    }
    _fish(canvas, const Offset(25, 31), 30, _orange);
  }

  void _warmHug(Canvas canvas) {
    _heart(canvas, const Offset(24, 25), 26, _pink);
    _paw(canvas, const Offset(10.5, 30), 11, _cream);
    _paw(canvas, const Offset(37.5, 30), 11, _cream);
  }

  void _patience(Canvas canvas) {
    final glass = Path()
      ..moveTo(15, 11)
      ..lineTo(33, 11)
      ..cubicTo(33, 19, 26, 21, 26, 24)
      ..cubicTo(26, 27, 33, 29, 33, 37)
      ..lineTo(15, 37)
      ..cubicTo(15, 29, 22, 27, 22, 24)
      ..cubicTo(22, 21, 15, 19, 15, 11)
      ..close();
    canvas.drawPath(glass, _fill(const Color(0xCCE6F6FA)));
    canvas.save();
    canvas.clipPath(glass);
    canvas.drawRect(
        const Rect.fromLTWH(14, 16, 20, 8), _fill(const Color(0xFFF2C14E)));
    canvas.drawPath(
        Path()
          ..moveTo(15, 37)
          ..quadraticBezierTo(24, 26, 33, 37)
          ..close(),
        _fill(const Color(0xFFF2C14E)));
    canvas.restore();
    canvas.drawLine(const Offset(24, 24), const Offset(24, 33),
        _line(1.2, const Color(0xFFD9962B)));
    canvas.drawPath(glass, _line(1.8));
    for (final y in const [8.0, 37.0]) {
      final bar = Path()
        ..addRRect(RRect.fromRectAndRadius(
            Rect.fromLTWH(11, y, 26, 4), const Radius.circular(2)));
      _shape(canvas, bar, _wood, 1.6);
    }
    final z = TextPainter(
        text: const TextSpan(
            text: 'z',
            style: TextStyle(
                color: _ink, fontSize: 9, fontWeight: FontWeight.w900)),
        textDirection: TextDirection.ltr)
      ..layout();
    z.paint(canvas, const Offset(35, 13));
  }

  void _lazyLunch(Canvas canvas) {
    // Steam.
    for (final x in const [19.0, 29.0]) {
      canvas.drawPath(
          Path()
            ..moveTo(x, 17)
            ..cubicTo(x - 3, 14, x + 3, 11, x, 7),
          _line(2, const Color(0xAAFFFFFF)));
    }
    // Heap of food with a fish on top.
    _shape(
        canvas,
        Path()
          ..moveTo(11, 28)
          ..quadraticBezierTo(24, 15, 37, 28)
          ..close(),
        const Color(0xFFC9935E),
        1.6);
    for (final (x, y) in const [
      (18.0, 25.0),
      (24.0, 22.0),
      (30.0, 25.0),
      (22.0, 26.5),
      (27.0, 26.5)
    ]) {
      canvas.drawCircle(Offset(x, y), 1.3, _fill(const Color(0xFF8C5A34)));
    }
    _fish(canvas, const Offset(25, 21), 14, _blue, angle: -.2);
    // Bowl.
    final bowl = Path()
      ..moveTo(8, 28)
      ..lineTo(40, 28)
      ..quadraticBezierTo(39, 41, 24, 41)
      ..quadraticBezierTo(9, 41, 8, 28)
      ..close();
    _shape(canvas, bowl, const Color(0xFFE0533F));
    canvas.drawLine(const Offset(12, 33), const Offset(36, 33),
        _line(1.6, const Color(0x88FFF4DA)));
    _paw(canvas, const Offset(24, 36.5), 6, _cream);
  }

  void _wideBeds(Canvas canvas) {
    _bed(canvas, const Rect.fromLTWH(12, 19, 24, 15));
    // Fat arrows pushing outward on both sides and below: a bigger bed.
    for (final dir in const [-1.0, 1.0]) {
      final x = 24 + dir * 16.5;
      final arrow = Path()
        ..moveTo(x + dir * 6, 26.5)
        ..lineTo(x - dir * 1, 20)
        ..lineTo(x - dir * 1, 23.5)
        ..lineTo(x - dir * 4.5, 23.5)
        ..lineTo(x - dir * 4.5, 29.5)
        ..lineTo(x - dir * 1, 29.5)
        ..lineTo(x - dir * 1, 33)
        ..close();
      _shape(canvas, arrow, _gold, 1.6);
    }
    final ruler = _line(2, _goldDark);
    canvas.drawLine(const Offset(12, 39), const Offset(36, 39), ruler);
    canvas.drawLine(const Offset(12, 36.5), const Offset(12, 41.5), ruler);
    canvas.drawLine(const Offset(36, 36.5), const Offset(36, 41.5), ruler);
  }

  void _fishBasket(Canvas canvas) {
    _fish(canvas, const Offset(18, 17), 18, _blue, angle: -1.1);
    _fish(canvas, const Offset(30, 17), 18, _orange, angle: -2.0);
    // Handle.
    canvas.drawPath(
        Path()
          ..moveTo(12, 25)
          ..quadraticBezierTo(24, 3, 36, 25),
        _line(3, _ink));
    canvas.drawPath(
        Path()
          ..moveTo(12, 25)
          ..quadraticBezierTo(24, 3, 36, 25),
        _line(1.6, _wood));
    final basket = Path()
      ..moveTo(9, 24)
      ..lineTo(39, 24)
      ..lineTo(35, 41)
      ..lineTo(13, 41)
      ..close();
    _shape(canvas, basket, const Color(0xFFD9A066));
    canvas.save();
    canvas.clipPath(basket);
    final weave = _line(1.2, const Color(0xFF9A6A3A));
    for (var y = 29.0; y < 42; y += 5) {
      canvas.drawLine(Offset(8, y), Offset(40, y), weave);
    }
    for (var x = 12.0; x < 40; x += 6) {
      canvas.drawLine(
          Offset(x, 24), Offset(x + (x < 24 ? 1.5 : -1.5), 41), weave);
    }
    canvas.restore();
    canvas.drawPath(basket, _line());
    final rim = Path()
      ..addRRect(RRect.fromRectAndRadius(
          const Rect.fromLTWH(7.5, 22, 33, 4.5), const Radius.circular(2.2)));
    _shape(canvas, rim, _wood, 1.6);
  }

  void _nailedBeds(Canvas canvas) {
    _bed(canvas, const Rect.fromLTWH(7, 24, 34, 17));
    // A thumbtack pinned through the bed.
    canvas.drawLine(const Offset(24, 22), const Offset(24, 32),
        _line(2.2, const Color(0xFF9A9A9A)));
    final collar = Path()
      ..moveTo(17, 22)
      ..lineTo(31, 22)
      ..lineTo(28, 18)
      ..lineTo(20, 18)
      ..close();
    _shape(canvas, collar, const Color(0xFFC0473A), 1.6);
    final stem = Path()
      ..addRRect(RRect.fromRectAndRadius(
          const Rect.fromLTWH(20.5, 10, 7, 9), const Radius.circular(2)));
    _shape(canvas, stem, const Color(0xFFE0533F), 1.6);
    _shape(canvas, _oval(const Offset(24, 9), 15, 6), const Color(0xFFE0533F),
        1.6);
    canvas.drawLine(const Offset(22.5, 12), const Offset(22.5, 17),
        _line(1.4, const Color(0x99FFFFFF)));
  }

  void _longNight(Canvas canvas) {
    final moon = Path.combine(
        PathOperation.difference,
        _oval(const Offset(21, 22), 26, 26),
        _oval(const Offset(29, 16), 22, 22));
    _shape(canvas, moon, const Color(0xFFFFE08A));
    _star(canvas, const Offset(33, 10), 3.5, _goldDark);
    _star(canvas, const Offset(38, 21), 2.5, _goldDark);
    final pill = RRect.fromRectAndRadius(
        const Rect.fromLTWH(22, 31, 21, 11), const Radius.circular(5.5));
    _shape(canvas, Path()..addRRect(pill), _cream, 1.6);
    final text = TextPainter(
        text: const TextSpan(
            text: '+10s',
            style: TextStyle(
                color: _ink, fontSize: 7.5, fontWeight: FontWeight.w900)),
        textDirection: TextDirection.ltr)
      ..layout();
    text.paint(canvas, Offset(32.5 - text.width / 2, 36.5 - text.height / 2));
  }

  void _eagerHelpers(Canvas canvas) {
    _paw(canvas, const Offset(20, 28), 22, _orange);
    final bolt = Path()
      ..moveTo(33, 5)
      ..lineTo(25, 21)
      ..lineTo(31, 21)
      ..lineTo(27, 34)
      ..lineTo(40, 15)
      ..lineTo(33.5, 15)
      ..lineTo(38, 5)
      ..close();
    _shape(canvas, bolt, const Color(0xFFFFD866), 1.8);
  }

  void _hotCoins(Canvas canvas) {
    _flame(canvas, const Offset(33, 20), 17);
    // Two stacked coins, the front one embossed with a paw.
    for (final c in const [Offset(26, 32), Offset(19, 26)]) {
      _shape(canvas, _oval(c, 24, 24), _goldDark);
      _shape(canvas, _oval(c, 17, 17), _gold, 1.4);
    }
    _paw(canvas, const Offset(19, 26.5), 8, _goldDark);
    canvas.drawArc(
        Rect.fromCircle(center: const Offset(19, 26), radius: 9.5),
        math.pi * 1.1,
        math.pi * .4,
        false,
        _line(1.6, const Color(0xAAFFFFFF)));
  }

  /// Lantern drawn at [c] with height [h]; used by every backyard card.
  void _lanternAt(Canvas canvas, Offset c, double h, {bool glow = true}) {
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.scale(h / 36);
    canvas.translate(-24, -25);
    if (glow) {
      canvas.drawCircle(
          const Offset(24, 25), 17, _fill(const Color(0x55FFE08A)));
    }
    canvas.drawLine(const Offset(24, 4), const Offset(24, 9), _line(1.6));
    _shape(canvas, _oval(const Offset(24, 25), 26, 26),
        glow ? const Color(0xFFE0533F) : const Color(0xFF8A5A4A));
    for (final dx in const [-6.5, 0.0, 6.5]) {
      canvas.drawPath(
          Path()
            ..moveTo(24 + dx * .5, 13)
            ..quadraticBezierTo(24 + dx * 1.7, 25, 24 + dx * .5, 37),
          _line(1.2, const Color(0xFF9E2F25)));
    }
    canvas.drawOval(
        Rect.fromCenter(center: const Offset(18, 20), width: 5, height: 8),
        _fill(const Color(0x66FFF4DA)));
    for (final y in const [9.5, 36.5]) {
      _shape(
          canvas,
          Path()
            ..addRRect(RRect.fromRectAndRadius(
                Rect.fromCenter(center: Offset(24, y), width: 14, height: 4.5),
                const Radius.circular(2))),
          _gold,
          1.6);
    }
    canvas.restore();
  }

  void _pill(Canvas canvas, Rect r, String text) {
    _shape(
        canvas,
        Path()
          ..addRRect(RRect.fromRectAndRadius(r, Radius.circular(r.height / 2))),
        _cream,
        1.6);
    final label = TextPainter(
        text: TextSpan(
            text: text,
            style: const TextStyle(
                color: _ink, fontSize: 8, fontWeight: FontWeight.w900)),
        textDirection: TextDirection.ltr)
      ..layout();
    label.paint(canvas, r.center - Offset(label.width / 2, label.height / 2));
  }

  void _longWick(Canvas canvas) {
    _lanternAt(canvas, const Offset(20, 24), 32);
    // Long wick curling down to a small flame.
    canvas.drawPath(
        Path()
          ..moveTo(20, 41)
          ..cubicTo(26, 44, 34, 38, 36, 30),
        _line(2, _ink));
    _flame(canvas, const Offset(37, 29), 10);
  }

  void _extraLantern(Canvas canvas) {
    _lanternAt(canvas, const Offset(17, 26), 30, glow: false);
    _lanternAt(canvas, const Offset(30, 24), 32);
    _shape(
        canvas, _oval(const Offset(37, 37), 13, 13), const Color(0xFF6DBE63));
    final plus = _line(2.4, Colors.white);
    canvas.drawLine(const Offset(33.5, 37), const Offset(40.5, 37), plus);
    canvas.drawLine(const Offset(37, 33.5), const Offset(37, 40.5), plus);
  }

  void _brightLantern(Canvas canvas) {
    final ray = _line(2.4, _goldDark);
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      final dir = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(const Offset(24, 24) + dir * 15,
          const Offset(24, 24) + dir * 20, ray);
    }
    _lanternAt(canvas, const Offset(24, 24), 26);
  }

  void _fullMoon(Canvas canvas) {
    canvas.drawCircle(const Offset(24, 24), 16, _fill(const Color(0x44FFF4C8)));
    _shape(
        canvas, _oval(const Offset(24, 24), 24, 24), const Color(0xFFFFF0B8));
    for (final (x, y, r) in const [
      (19.0, 20.0, 3.0),
      (28.0, 27.0, 2.2),
      (26.0, 18.0, 1.6)
    ]) {
      canvas.drawCircle(Offset(x, y), r, _fill(const Color(0x33B8A060)));
    }
    _star(canvas, const Offset(9, 12), 2.6, _goldDark);
    _star(canvas, const Offset(40, 36), 2.2, _goldDark);
    // A small cloud drifting away.
    final cloud = _fill(const Color(0xFFB9C3DD));
    for (final (x, y, r) in const [
      (36.0, 13.0, 4.0),
      (41.0, 12.0, 5.0),
      (45.0, 14.0, 3.5)
    ]) {
      canvas.drawCircle(Offset(x, y), r, cloud);
    }
  }

  void _nightWind(Canvas canvas) {
    _lanternAt(canvas, const Offset(29, 25), 30);
    final gust = _line(2.4, const Color(0xFFCFE3FF));
    for (final (y, len) in const [(15.0, 14.0), (24.0, 18.0), (33.0, 12.0)]) {
      canvas.drawPath(
          Path()
            ..moveTo(5, y)
            ..lineTo(5 + len, y)
            ..arcToPoint(Offset(5 + len, y - 5),
                radius: const Radius.circular(2.5)),
          gust);
    }
    _pill(canvas, const Rect.fromLTWH(22, 36, 20, 9), 'x2');
  }

  void _crowd(Canvas canvas) {
    _catHead(canvas, const Offset(13, 23), 8, const Color(0xFF536066));
    _catHead(canvas, const Offset(35, 23), 8, const Color(0xFFDCC7A7));
    _catHead(canvas, const Offset(24, 31), 10.5, const Color(0xFFF4A34E),
        patch: const Color(0xFFFFF4DA));
  }

  void _hiddenFish(Canvas canvas) {
    _fish(canvas, const Offset(29, 17), 20, _blue, angle: -2.3);
    // Open cardboard box with the flaps up.
    _shape(
        canvas,
        Path()
          ..moveTo(9, 23)
          ..lineTo(4, 16)
          ..lineTo(14, 16)
          ..lineTo(17, 23)
          ..close(),
        const Color(0xFFB98A55),
        1.6);
    _shape(
        canvas,
        Path()
          ..moveTo(39, 23)
          ..lineTo(44, 16)
          ..lineTo(34, 16)
          ..lineTo(31, 23)
          ..close(),
        const Color(0xFFB98A55),
        1.6);
    final box = Path()
      ..addRRect(RRect.fromRectAndRadius(
          const Rect.fromLTWH(9, 22, 30, 20), const Radius.circular(2)));
    _shape(canvas, box, const Color(0xFFD9A066));
    canvas.drawLine(const Offset(24, 22), const Offset(24, 28),
        _line(3, const Color(0xFFF2D7A8)));
    final mark = TextPainter(
        text: const TextSpan(
            text: '?',
            style: TextStyle(
                color: _ink, fontSize: 13, fontWeight: FontWeight.w900)),
        textDirection: TextDirection.ltr)
      ..layout();
    mark.paint(canvas, Offset(24 - mark.width / 2, 33 - mark.height / 2 + 1));
  }

  void _quietSteps(Canvas canvas) {
    _shape(
        canvas,
        Path()
          ..addRRect(RRect.fromRectAndRadius(
              const Rect.fromLTWH(9, 26, 31, 13), const Radius.circular(6))),
        const Color(0xFFA69BC4));
    canvas.drawLine(const Offset(12, 34), const Offset(37, 34),
        _line(1.5, const Color(0xFF74648F)));
    _paw(canvas, const Offset(24, 22), 19, _orange);
    _star(canvas, const Offset(38, 13), 3, _goldDark);
  }

  void _softWheels(Canvas canvas) {
    _shape(
        canvas, _oval(const Offset(24, 26), 29, 29), const Color(0xFF7A5E4B));
    _shape(canvas, _oval(const Offset(24, 26), 20, 20), _woodLight, 1.5);
    for (var i = 0; i < 6; i++) {
      final a = i * math.pi / 3;
      canvas.drawLine(const Offset(24, 26),
          Offset(24 + math.cos(a) * 9, 26 + math.sin(a) * 9), _line(1.5));
    }
    _shape(
        canvas,
        Path()
          ..moveTo(6, 13)
          ..quadraticBezierTo(24, 1, 42, 13)
          ..lineTo(39, 20)
          ..quadraticBezierTo(24, 9, 9, 20)
          ..close(),
        const Color(0xFF8EBCA9),
        1.6);
    canvas.drawCircle(const Offset(24, 26), 3, _fill(_ink));
  }

  void _backupPower(Canvas canvas) {
    _shape(
        canvas,
        Path()
          ..addRRect(RRect.fromRectAndRadius(
              const Rect.fromLTWH(12, 11, 25, 29), const Radius.circular(4))),
        _blue);
    _shape(canvas, Path()..addRect(const Rect.fromLTWH(19, 7, 11, 4)),
        _woodLight, 1.5);
    final bolt = Path()
      ..moveTo(26, 14)
      ..lineTo(17, 27)
      ..lineTo(24, 27)
      ..lineTo(21, 37)
      ..lineTo(33, 22)
      ..lineTo(26, 22)
      ..close();
    _shape(canvas, bolt, _gold, 1.3);
  }

  void _quietCorner(Canvas canvas) {
    _catHead(canvas, const Offset(24, 25), 13, _woodLight);
    canvas.drawArc(const Rect.fromLTWH(8, 8, 32, 35), math.pi, math.pi, false,
        _line(5, const Color(0xFF7E9FA9)));
    for (final x in const [9.0, 39.0]) {
      _shape(
          canvas,
          Path()
            ..addRRect(RRect.fromRectAndRadius(
                Rect.fromCenter(center: Offset(x, 26), width: 8, height: 16),
                const Radius.circular(4))),
          const Color(0xFF8FB9B1),
          1.5);
    }
  }

  void _busyMarket(Canvas canvas) {
    final cart = Path()
      ..addRRect(RRect.fromRectAndRadius(
          const Rect.fromLTWH(10, 22, 29, 13), const Radius.circular(2)));
    _shape(canvas, cart, _woodLight);
    canvas.drawLine(const Offset(5, 17), const Offset(11, 24), _line(3, _wood));
    for (final x in const [16.0, 33.0]) {
      _shape(canvas, _oval(Offset(x, 38), 8, 8), const Color(0xFF7C97A1), 1.5);
    }
    _shape(canvas, Path()..addRect(const Rect.fromLTWH(13, 13, 11, 9)), _orange,
        1.5);
    _shape(canvas, Path()..addRect(const Rect.fromLTWH(25, 10, 11, 12)), _blue,
        1.5);
    _star(canvas, const Offset(39, 12), 3, _gold);
  }

  void _plank(Canvas canvas, Rect r, {Color color = _woodLight}) {
    _shape(
        canvas,
        Path()..addRRect(RRect.fromRectAndRadius(r, const Radius.circular(3))),
        color,
        1.6);
    for (var x = r.left + 6; x < r.right; x += 8) {
      canvas.drawLine(
          Offset(x, r.top + 2), Offset(x, r.bottom - 2), _line(1, _wood));
    }
  }

  void _sturdyPlanks(Canvas canvas) {
    _plank(canvas, const Rect.fromLTWH(7, 18, 34, 12));
    for (final x in const [13.0, 35.0]) {
      _shape(canvas, _oval(Offset(x, 24), 5, 5), const Color(0xFF8E8E8E), 1.2);
    }
  }

  void _quickCarpenter(Canvas canvas) {
    _plank(canvas, const Rect.fromLTWH(8, 25, 30, 10));
    canvas.drawLine(
        const Offset(14, 12), const Offset(34, 23), _line(5, _wood));
    _shape(canvas, Path()..addRect(const Rect.fromLTWH(29, 7, 13, 9)),
        const Color(0xFF9DA9AC), 1.5);
    _star(canvas, const Offset(10, 13), 3, _gold);
  }

  void _widePlanks(Canvas canvas) {
    _plank(canvas, const Rect.fromLTWH(10, 15, 28, 21));
    final arrow = _line(2.4, _goldDark);
    for (final y in const [10.0, 40.0]) {
      canvas.drawLine(Offset(24, y), Offset(24, y == 10 ? 15 : 35), arrow);
    }
  }

  void _railLights(Canvas canvas) {
    _plank(canvas, const Rect.fromLTWH(7, 25, 34, 10));
    canvas.drawLine(const Offset(8, 20), const Offset(40, 20), _line(2, _wood));
    for (final x in const [12.0, 24.0, 36.0]) {
      canvas.drawCircle(Offset(x, 17), 5, _fill(const Color(0x55FFE08A)));
      canvas.drawCircle(Offset(x, 17), 2.4, _fill(_gold));
    }
  }

  void _stormyRoof(Canvas canvas) {
    _plank(canvas, const Rect.fromLTWH(14, 27, 27, 10));
    final gust = _line(2.4, const Color(0xFFCFE3FF));
    for (final y in const [12.0, 20.0, 28.0]) {
      canvas.drawPath(
          Path()
            ..moveTo(6, y)
            ..quadraticBezierTo(20, y - 5, 34, y),
          gust);
    }
    _pill(canvas, const Rect.fromLTWH(26, 7, 17, 9), '½');
  }

  @override
  bool shouldRepaint(_NightCardPainter oldDelegate) => oldDelegate.card != card;
}
