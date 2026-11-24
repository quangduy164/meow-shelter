import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/painting.dart';

import '../../collection/fish_species.dart';

// Hand-drawn legendary fish, in the same 100x64 box as FishingFishArt
// (origin at the centre, head to the left). [locked] turns them into grey
// stone: undiscovered journal entries and the unlit shrine statues.

class _Ink {
  _Ink(this.locked);
  final bool locked;
  Color call(int v) {
    final c = Color(v);
    if (!locked) return c;
    final l = (.3 * c.r + .59 * c.g + .11 * c.b) * 255;
    final g = (92 + l * .52).round().clamp(0, 255);
    return Color.fromARGB(
        (c.a * 255).round(), g, (g + 5).clamp(0, 255), (g + 3).clamp(0, 255));
  }

  Paint fill(int v) => Paint()..color = call(v);
  Paint line(int v, double w) => Paint()
    ..color = call(v)
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  Paint get outline => line(0xFF263238, 1.6);
}

// Each creature is recorded once per (species, locked) and replayed, so the
// detailed art costs one drawPicture in fights, journals and the shrine.
// The handful of pictures live for the whole app session.
final _pictures = <(FishSpecies, bool), ui.Picture>{};

void paintLegendaryFish(Canvas c, FishSpecies fish, {bool locked = false}) {
  final picture = _pictures.putIfAbsent((fish, locked), () {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final k = _Ink(locked);
    switch (fish) {
      case FishSpecies.catMew:
        _nessie(canvas, k);
      case FishSpecies.seaDragon:
        _dragon(canvas, k);
      case FishSpecies.moonfish:
        _moon(canvas, k);
      default:
        break;
    }
    return recorder.endRecording();
  });
  c.drawPicture(picture);
}

Paint _gradient(_Ink k, Offset a, Offset b, List<int> colors,
        [List<double>? stops]) =>
    Paint()
      ..shader = ui.Gradient.linear(
          a,
          b,
          [for (final v in colors) k(v)],
          stops ??
              [
                for (var i = 0; i < colors.length; i++) i / (colors.length - 1)
              ]);

Paint _glow(_Ink k, Offset at, double r, int color) => Paint()
  ..shader = ui.Gradient.radial(at, r, [k(color), k(color & 0x00FFFFFF)]);

Path _leaf(Offset from, Offset to, double width, [double bend = 0]) {
  final d = to - from;
  final n = Offset(-d.dy, d.dx) / d.distance;
  final mid = from + d * .45 + n * bend;
  return Path()
    ..moveTo(from.dx, from.dy)
    ..quadraticBezierTo(
        (mid + n * width).dx, (mid + n * width).dy, to.dx, to.dy)
    ..quadraticBezierTo(
        (mid - n * width).dx, (mid - n * width).dy, from.dx, from.dy)
    ..close();
}

void _star(Canvas c, Offset s, double r, Paint paint) {
  final t = r * .28;
  c.drawPath(
      Path()
        ..moveTo(s.dx, s.dy - r)
        ..quadraticBezierTo(s.dx + t, s.dy - t, s.dx + r, s.dy)
        ..quadraticBezierTo(s.dx + t, s.dy + t, s.dx, s.dy + r)
        ..quadraticBezierTo(s.dx - t, s.dy + t, s.dx - r, s.dy)
        ..quadraticBezierTo(s.dx - t, s.dy - t, s.dx, s.dy - r)
        ..close(),
      paint);
}

/// Mèo Nessie: one smooth lake-monster silhouette with a kitten's head.
void _nessie(Canvas c, _Ink k) {
  const back = 0xFF2B6B63, mid = 0xFF4E9F8F, light = 0xFF86CDB6;
  const belly = 0xFFF3E7C9, stripe = 0xFF2A625B;
  // Far-side flippers first, then near-side ones; the body hides the roots.
  void flipper(Offset base, double angle, double len, int colour) {
    c.save();
    c.translate(base.dx, base.dy);
    c.rotate(angle);
    final f = Path()
      ..moveTo(-5, -3.5)
      ..cubicTo(3, -5.5, len * .7, -4, len, 1.5)
      ..cubicTo(len * .65, 5.5, 4, 5, -5, 4)
      ..close();
    c.drawPath(f, k.fill(colour));
    for (final x in [.45, .65, .82]) {
      c.drawLine(Offset(len * x, -2.6), Offset(len * x - 2, 3),
          k.line(0x55102A27, .8));
    }
    c.drawPath(f, k.outline);
    c.restore();
  }

  flipper(const Offset(-10, 12), 1.75, 14, 0xFF235A54);
  flipper(const Offset(28, 8), .55, 13, 0xFF235A54);
  flipper(const Offset(-17, 11), 2.05, 16, back);
  flipper(const Offset(21, 11), .85, 15, back);
  // Tail tuft.
  final tuft = Path()
    ..moveTo(43, -5)
    ..quadraticBezierTo(48, -13, 54, -13)
    ..quadraticBezierTo(50, -8, 53, -4)
    ..quadraticBezierTo(49, -1, 44, -3)
    ..close();
  c.drawPath(tuft, k.fill(back));
  c.drawPath(tuft, k.outline);

  final body = Path()
    ..moveTo(48, -7)
    ..cubicTo(40, -3, 30, -3, 22, -6)
    ..cubicTo(14, -11, -1, -11, -7, -4)
    ..cubicTo(-12, 1, -18, -4, -19, -12)
    ..cubicTo(-20, -17, -20, -21, -21, -24)
    ..lineTo(-23, -29)
    ..lineTo(-22, -38)
    ..lineTo(-28, -31.6)
    ..quadraticBezierTo(-31, -32.6, -34, -31.6)
    ..lineTo(-40, -37)
    ..lineTo(-40.6, -28)
    ..cubicTo(-43, -25, -44, -21.5, -42.4, -19.5)
    ..lineTo(-45, -17.6)
    ..lineTo(-40.6, -16.6)
    ..cubicTo(-37, -14, -31, -13, -29, -9)
    ..cubicTo(-27, -2, -24, 7, -17, 12)
    ..cubicTo(-8, 18, 12, 18, 22, 12)
    ..cubicTo(32, 6, 40, 1, 48, -7)
    ..close();
  c.drawPath(body,
      _gradient(k, const Offset(0, -12), const Offset(0, 16), [mid, light]));
  c.save();
  c.clipPath(body);
  // Dark back, pale throat and belly following the same curves.
  final topLine = Path()
    ..moveTo(48, -7)
    ..cubicTo(40, -3, 30, -3, 22, -6)
    ..cubicTo(14, -11, -1, -11, -7, -4)
    ..cubicTo(-12, 1, -18, -4, -19, -12)
    ..cubicTo(-20, -17, -20, -21, -21, -26);
  c.drawPath(topLine, k.line(back, 7));
  c.drawPath(topLine.shift(const Offset(-.5, 3.4)), k.line(0x66A8E3CF, 1.4));
  final under = Path()
    ..moveTo(-36, -15)
    ..cubicTo(-31, -13, -29, -11, -28, -6)
    ..cubicTo(-26, 1, -23, 8, -16, 13)
    ..cubicTo(-8, 18, 12, 18, 22, 12)
    ..cubicTo(32, 6, 40, 1, 48, -7);
  c.drawPath(under, k.line(belly, 9));
  c.drawOval(const Rect.fromLTRB(-18, 7, 28, 24), k.fill(belly));
  c.drawPath(under.shift(const Offset(0, -4.6)), k.line(0x33A08E64, 1));
  // Tabby stripes wrapping the hump, neck and tail.
  for (final (x, y) in const [
    (-3.0, -8.0),
    (4.0, -9.8),
    (11.0, -9.8),
    (18.0, -8.0),
    (29.0, -4.4),
    (36.0, -3.6),
  ]) {
    c.drawPath(
        Path()
          ..moveTo(x - 1, y - 1)
          ..quadraticBezierTo(x + 3, y + 4, x + 1, y + 10),
        k.line(stripe, x > 25 ? 2 : 2.6));
  }
  for (final y in [-7.0, -13.0, -19.0]) {
    c.drawPath(
        Path()
          ..moveTo(-17, y)
          ..quadraticBezierTo(-21, y + 1.5, -24.5, y + .5),
        k.line(stripe, 2.2));
  }
  // Forehead "M" and cheeks.
  for (final (x, len) in const [(-35.5, 3.6), (-31.5, 4.4), (-27.5, 3.4)]) {
    c.drawLine(Offset(x, -31), Offset(x + .4, -31 + len), k.line(stripe, 1.6));
  }
  c.drawOval(const Rect.fromLTRB(-40, -21.5, -29, -14.5), k.fill(belly));
  c.drawOval(const Rect.fromLTRB(-43, -20.5, -38, -17), k.fill(0x55F48FA8));
  c.drawOval(const Rect.fromLTRB(-28.5, -21, -24, -17.5), k.fill(0x55F48FA8));
  c.restore();
  // Pink inner ears.
  for (final ear in [
    [
      const Offset(-23.6, -30),
      const Offset(-22.6, -35.5),
      const Offset(-26.4, -31.4)
    ],
    [
      const Offset(-35.4, -31.2),
      const Offset(-39, -34.8),
      const Offset(-39.3, -29.6)
    ],
  ]) {
    c.drawPath(Path()..addPolygon(ear, true), k.fill(0xFFF0A3B4));
  }
  c.drawPath(body, k.outline);
  // Big shiny eyes.
  for (final x in [-36.4, -29.6]) {
    final eye =
        Rect.fromCenter(center: Offset(x, -24.4), width: 5.6, height: 6);
    c.drawOval(eye, k.fill(0xFFFFFFFF));
    c.drawOval(
        eye.deflate(.7),
        _gradient(
            k, eye.topCenter, eye.bottomCenter, [0xFF8DBF3A, 0xFFE8D45A]));
    c.drawOval(
        Rect.fromCenter(center: Offset(x, -24.2), width: 1.6, height: 4.4),
        k.fill(0xFF14201E));
    c.drawCircle(Offset(x + 1, -25.8), .9, k.fill(0xFFFFFFFF));
    c.drawOval(eye, k.line(0xFF263238, 1));
  }
  // Nose, smile and whiskers.
  c.drawPath(
      Path()
        ..moveTo(-34.6, -19.6)
        ..lineTo(-31.6, -19.6)
        ..lineTo(-33.1, -17.9)
        ..close(),
      k.fill(0xFFE5728A));
  c.drawPath(
      Path()
        ..moveTo(-35.4, -16.6)
        ..quadraticBezierTo(-34.2, -15.4, -33.1, -17.4)
        ..quadraticBezierTo(-32, -15.4, -30.8, -16.6),
      k.line(0xFF5A3A38, .8));
  for (final (a, b) in const [
    (Offset(-38, -18.4), Offset(-49, -20.6)),
    (Offset(-38, -17.2), Offset(-49, -15.6)),
    (Offset(-28.4, -18.6), Offset(-20, -20)),
    (Offset(-28.4, -17.4), Offset(-20.4, -16)),
  ]) {
    c.drawLine(a, b, k.line(0xEEFFFFFF, .7));
  }
}

/// Rồng biển: one tapered serpent body carrying a crest, legs and a pearl.
void _dragon(Canvas c, _Ink k) {
  const n = 40;
  const teal = 0xFF2A9D8F, deep = 0xFF17645D, cream = 0xFFF6DE91;
  const ink = 0xFF7A2E14;
  Offset spine(double t) =>
      Offset(-20 + t * 66, 1 + 6 * math.sin(t * math.pi * 2.2 - .5));
  double radius(double t) => 1.4 + 7.6 * math.pow(1 - t, .75).toDouble();
  Offset normal(double t) {
    final d = spine(math.min(1, t + .01)) - spine(math.max(0, t - .01));
    return Offset(-d.dy, d.dx) / d.distance;
  }

  final top = <Offset>[], bottom = <Offset>[];
  for (var i = 0; i <= n; i++) {
    final t = i / n, p = spine(t), nn = normal(t), r = radius(t);
    top.add(p - nn * r);
    bottom.add(p + nn * r);
  }
  // Flame tail.
  final end = spine(1);
  for (var j = 0; j < 5; j++) {
    final a = -.95 + j * .475;
    final len = j == 2 ? 13.0 : 16.0 - (j - 2).abs();
    final tip = end + Offset(math.cos(a), math.sin(a)) * len;
    final leaf = _leaf(end - const Offset(3, 0), tip, 3.2, (j - 2) * 1.5);
    c.drawPath(leaf, k.fill(j.isEven ? 0xFFF2A33A : 0xFFE76F51));
    c.drawPath(leaf, k.line(ink, .8));
  }
  // One continuous crest membrane along the back.
  final crest = Path()..moveTo(top[7].dx, top[7].dy);
  for (var i = 7; i < n - 4; i += 3) {
    final t = (i + 1.5) / n, nn = normal(t);
    final len = (7 + 3 * math.sin(i * .9).abs()) * (1 - t * .55);
    final tip = top[i + 1] - nn * len + const Offset(3.5, 0);
    crest
      ..quadraticBezierTo(top[i].dx - nn.dx * len * .7,
          top[i].dy - nn.dy * len * .7, tip.dx, tip.dy)
      ..quadraticBezierTo(top[i + 2].dx - nn.dx * 2, top[i + 2].dy - nn.dy * 2,
          top[i + 3].dx, top[i + 3].dy);
  }
  crest.close();
  c.drawPath(
      crest,
      _gradient(k, const Offset(0, -16), const Offset(0, 0),
          [0xFFFFC857, 0xFFE76F51]));
  for (var i = 7; i < n - 4; i += 3) {
    final t = (i + 1.5) / n, nn = normal(t);
    final len = (7 + 3 * math.sin(i * .9).abs()) * (1 - t * .55);
    c.drawLine(top[i + 1], top[i + 1] - nn * len * .85 + const Offset(3, 0),
        k.line(0xAAB5481F, .7));
  }
  c.drawPath(crest, k.line(ink, .9));
  // Legs with clawed feet, rooted under the body.
  Path leg() => Path()
    ..moveTo(-4.5, -3)
    ..cubicTo(-5, 4, -3, 8, -6, 11)
    ..lineTo(-10.5, 12.5)
    ..lineTo(-6.5, 13.6)
    ..lineTo(-9.5, 16)
    ..lineTo(-4.4, 14.6)
    ..lineTo(-5, 17.4)
    ..lineTo(-1, 13.4)
    ..cubicTo(1, 9, 4, 4, 5, -3)
    ..close();
  Offset? pearlAt;
  for (final (t, angle, colour, near) in const [
    (.24, .45, 0xFF1F8077, false),
    (.64, .15, 0xFF1F8077, false),
    (.13, .75, teal, true),
    (.54, .35, teal, true),
  ]) {
    final b = bottom[(t * n).round()];
    c.save();
    c.translate(b.dx, b.dy - 2);
    c.rotate(angle);
    final l = leg();
    c.drawPath(l, k.fill(colour));
    c.drawLine(
        const Offset(-2, 2), const Offset(-3.5, 9), k.line(0x55102A27, 1));
    for (final claw in const [
      Offset(-10.5, 12.5),
      Offset(-9.5, 16),
      Offset(-5, 17.4)
    ]) {
      c.drawCircle(claw, 1, k.fill(0xFFF4E3B5));
    }
    c.drawPath(l, k.outline);
    c.restore();
    if (near && t < .2) {
      pearlAt = b +
          Offset(-math.sin(angle) * 15 - 7 * math.cos(angle),
              math.cos(angle) * 15 - 7 * math.sin(angle));
    }
  }
  // Body: teal back, ribbed cream belly, overlapping scales.
  final body = Path()..addPolygon([...top, ...bottom.reversed], true);
  c.drawPath(body, k.fill(teal));
  c.save();
  c.clipPath(body);
  c.drawPath(Path()..addPolygon(top, false), k.line(deep, 4));
  final belly = [
    for (var i = 0; i <= n; i++)
      spine(i / n) + normal(i / n) * radius(i / n) * .2
  ];
  c.drawPath(
      Path()..addPolygon([...belly, ...bottom.reversed], true), k.fill(cream));
  for (var i = 1; i < n; i += 2) {
    c.drawLine(Offset.lerp(belly[i], bottom[i], .1)!,
        Offset.lerp(belly[i], bottom[i], 1)!, k.line(0xFFCFAE62, .8));
  }
  for (var i = 1; i < n - 1; i++) {
    final t = i / n, p = spine(t), nn = normal(t), r = radius(t);
    for (final f in i.isEven ? const [-.75, -.25] : const [-.5, 0.0]) {
      final o = p + nn * r * f;
      c.drawArc(Rect.fromCircle(center: o, radius: r * .26 + .7), .25,
          math.pi - .5, false, k.line(0xFF1B6F67, .8));
    }
  }
  c.drawPath(
      Path()
        ..addPolygon([
          for (var i = 0; i <= n; i++)
            spine(i / n) - normal(i / n) * radius(i / n) * .55
        ], false),
      k.line(0x667FE3D2, 1.1));
  c.restore();
  c.drawPath(body, k.outline);

  // Head, drawn over the neck with mane and antlers tucked behind.
  const h = Offset(-26, -3);
  Offset o(double x, double y) => h + Offset(x, y);
  for (final (from, to, colour) in [
    (o(3, -7), o(19, -13), 0xFFE76F51),
    (o(6, -3), o(23, -5), 0xFFF2A33A),
    (o(6, 2), o(21, 4), 0xFFE76F51),
    (o(3, 5), o(15, 11), 0xFFF2A33A),
  ]) {
    final strand = _leaf(from, to, 3.4, 1.6);
    c.drawPath(strand, k.fill(colour));
    c.drawPath(strand, k.line(ink, .8));
  }
  for (final (dx, colour) in const [(4.0, 0xFFC9B27C), (0.0, 0xFFF4E3B5)]) {
    final antler = Path()
      ..moveTo(h.dx + 1 + dx, h.dy - 7)
      ..quadraticBezierTo(h.dx + 3 + dx, h.dy - 16, h.dx + 10 + dx, h.dy - 22)
      ..moveTo(h.dx + 3 + dx, h.dy - 13.5)
      ..lineTo(h.dx - 2 + dx, h.dy - 18.5)
      ..moveTo(h.dx + 7 + dx, h.dy - 18.5)
      ..lineTo(h.dx + 7.5 + dx, h.dy - 24.5);
    c.drawPath(antler, k.line(0xFF263238, 3.8));
    c.drawPath(antler, k.line(colour, 2.2));
  }
  // Open mouth, lower jaw, then the long upper head.
  c.drawPath(
      Path()
        ..moveTo(o(-21, 0).dx, o(-21, 0).dy)
        ..lineTo(o(-6, 1.5).dx, o(-6, 1.5).dy)
        ..lineTo(o(-18, 4).dx, o(-18, 4).dy)
        ..close(),
      k.fill(0xFF6B1A26));
  final jaw = Path()
    ..moveTo(o(-6, 1).dx, o(-6, 1).dy)
    ..lineTo(o(-19, 3.4).dx, o(-19, 3.4).dy)
    ..quadraticBezierTo(
        o(-20, 7.4).dx, o(-20, 7.4).dy, o(-15, 7.6).dx, o(-15, 7.6).dy)
    ..cubicTo(o(-8, 8).dx, o(-8, 8).dy, o(0, 7.4).dx, o(0, 7.4).dy, o(7, 5).dx,
        o(7, 5).dy)
    ..close();
  c.drawPath(jaw, k.fill(cream));
  for (final x in [-17.0, -13.0]) {
    c.drawPath(
        Path()
          ..moveTo(o(x, 3.2).dx, o(x, 3.2).dy)
          ..lineTo(o(x + 1, 1.4).dx, o(x + 1, 1.4).dy)
          ..lineTo(o(x + 2, 2.9).dx, o(x + 2, 2.9).dy)
          ..close(),
        k.fill(0xFFFFFFFF));
  }
  c.drawPath(jaw, k.outline);
  final skull = Path()
    ..moveTo(o(9, -6).dx, o(9, -6).dy)
    ..cubicTo(o(3, -11.5).dx, o(3, -11.5).dy, o(-6, -10.5).dx, o(-6, -10.5).dy,
        o(-9, -7.4).dx, o(-9, -7.4).dy)
    ..quadraticBezierTo(
        o(-13, -6.4).dx, o(-13, -6.4).dy, o(-19, -6.2).dx, o(-19, -6.2).dy)
    ..cubicTo(o(-24.5, -6).dx, o(-24.5, -6).dy, o(-25, -.5).dx, o(-25, -.5).dy,
        o(-21, .2).dx, o(-21, .2).dy)
    ..lineTo(o(-7, 1.4).dx, o(-7, 1.4).dy)
    ..cubicTo(o(-1, 3.4).dx, o(-1, 3.4).dy, o(4, 5).dx, o(4, 5).dy, o(9, 4).dx,
        o(9, 4).dy)
    ..close();
  c.drawPath(skull, _gradient(k, o(0, -11), o(0, 4), [deep, teal, 0xFF3DB5A5]));
  c.save();
  c.clipPath(skull);
  c.drawPath(
      Path()
        ..moveTo(o(-22, .4).dx, o(-22, .4).dy)
        ..lineTo(o(-7, 1.8).dx, o(-7, 1.8).dy)
        ..cubicTo(o(-1, 3.8).dx, o(-1, 3.8).dy, o(4, 5.4).dx, o(4, 5.4).dy,
            o(9, 4.4).dx, o(9, 4.4).dy),
      k.line(cream, 3.4));
  c.drawLine(o(-20, -5.2), o(-10, -7), k.line(0x887FE3D2, 1.2));
  for (final (x, y) in const [(1.0, -6.0), (5.0, -4.0), (3.0, -1.0)]) {
    c.drawArc(Rect.fromCircle(center: o(x, y), radius: 1.6), .25, math.pi - .5,
        false, k.line(0xFF1B6F67, .8));
  }
  c.restore();
  for (final x in [-19.0, -15.0, -11.0]) {
    c.drawPath(
        Path()
          ..moveTo(o(x, .4).dx, o(x, .4).dy)
          ..lineTo(o(x + 1, 2.6).dx, o(x + 1, 2.6).dy)
          ..lineTo(o(x + 2, .7).dx, o(x + 2, .7).dy)
          ..close(),
        k.fill(0xFFFFFFFF));
  }
  c.drawPath(skull, k.outline);
  // Fierce eye under a heavy brow, nostril and flowing whiskers.
  final eye = Path()
    ..moveTo(o(-8.6, -5).dx, o(-8.6, -5).dy)
    ..quadraticBezierTo(
        o(-5, -8.6).dx, o(-5, -8.6).dy, o(-1.4, -5.6).dx, o(-1.4, -5.6).dy)
    ..quadraticBezierTo(
        o(-5, -2.6).dx, o(-5, -2.6).dy, o(-8.6, -5).dx, o(-8.6, -5).dy)
    ..close();
  c.drawCircle(o(-5, -5.4), 5, _glow(k, o(-5, -5.4), 5, 0x66FFE27A));
  c.drawPath(eye, k.fill(0xFFFFD54F));
  c.drawOval(Rect.fromCenter(center: o(-4.8, -5.4), width: 1.3, height: 3.6),
      k.fill(0xFF1B1B1B));
  c.drawPath(eye, k.line(0xFF263238, .9));
  c.drawPath(
      Path()
        ..moveTo(o(-10, -8).dx, o(-10, -8).dy)
        ..quadraticBezierTo(
            o(-5, -10.6).dx, o(-5, -10.6).dy, o(1, -8.6).dx, o(1, -8.6).dy),
      k.line(0xFF0F3F3A, 1.8));
  c.drawArc(Rect.fromCircle(center: o(-21, -3.6), radius: 1.2), 0, 4.5, false,
      k.line(0xFF0F3F3A, .9));
  for (final w in [
    Path()
      ..moveTo(o(-22, -3).dx, o(-22, -3).dy)
      ..cubicTo(o(-30, -2).dx, o(-30, -2).dy, o(-30, 9).dx, o(-30, 9).dy,
          o(-22, 11).dx, o(-22, 11).dy)
      ..cubicTo(o(-14, 13).dx, o(-14, 13).dy, o(-8, 11).dx, o(-8, 11).dy,
          o(0, 14).dx, o(0, 14).dy),
    Path()
      ..moveTo(o(-21, .5).dx, o(-21, .5).dy)
      ..cubicTo(o(-26, 6).dx, o(-26, 6).dy, o(-22, 16).dx, o(-22, 16).dy,
          o(-13, 17).dx, o(-13, 17).dy)
      ..cubicTo(o(-5, 18).dx, o(-5, 18).dy, o(0, 21).dx, o(0, 21).dy,
          o(6, 20).dx, o(6, 20).dy),
  ]) {
    c.drawPath(w, k.line(0xFF7A4A12, 2));
    c.drawPath(w, k.line(0xFFF2C14E, 1.1));
  }
  // The dragon's pearl, held in the near front claw.
  final pearl = pearlAt ?? o(-10, 16);
  c.drawCircle(pearl, 7, _glow(k, pearl, 7, 0x88FFF3C4));
  c.drawCircle(
      pearl,
      3.4,
      _gradient(k, pearl - const Offset(2, 2), pearl + const Offset(2, 2),
          [0xFFFFFFFF, 0xFFF6D88A]));
  c.drawCircle(pearl, 3.4, k.line(0xFF9C7A2E, .7));
}

/// Cá nguyệt quang: a deep-bodied opah whose skin is the night sky.
void _moon(Canvas c, _Ink k) {
  const fin = 0xFFA9B9F5, finEdge = 0xFF5B68B8;
  if (!k.locked) {
    c.drawCircle(
        const Offset(2, 0), 34, _glow(k, const Offset(2, 0), 34, 0x4499C8FF));
  }
  // Tall sickle dorsal and the anal fin sit behind the body.
  for (final f in [
    Path()
      ..moveTo(-9, -18)
      ..cubicTo(-5, -30, 1, -36, 9, -39)
      ..quadraticBezierTo(5, -28, 23, -12)
      ..close(),
    Path()
      ..moveTo(4, 18)
      ..cubicTo(9, 25, 14, 28, 21, 29)
      ..quadraticBezierTo(16, 22, 23, 11)
      ..close(),
  ]) {
    c.drawPath(
        f,
        _gradient(k, const Offset(0, -38), const Offset(0, 28),
            [0xFFD9E2FF, fin, 0xFFD9E2FF]));
    c.drawPath(f, k.line(finEdge, 1.2));
  }
  for (var i = 0; i < 5; i++) {
    c.drawLine(Offset(-5 + i * 5.0, -19 + i * 1.2),
        Offset(5 + i * 3.4, -35 + i * 4.6), k.line(0x885B68B8, .7));
    c.drawLine(Offset(6 + i * 3.6, 18 - i * 1.2),
        Offset(12 + i * 2.2, 27 - i * 2.6), k.line(0x885B68B8, .7));
  }
  // Body and forked tail as one silhouette so the sky flows into the tail.
  final body = Path()
    ..moveTo(-26, 2)
    ..cubicTo(-26, -12, -14, -21, 0, -21)
    ..cubicTo(12, -21, 20, -12, 26, -4.5)
    ..lineTo(32, -3.5)
    ..cubicTo(36, -8, 41, -17, 48, -23)
    ..quadraticBezierTo(41, -9, 40, 0)
    ..quadraticBezierTo(41, 9, 48, 23)
    ..cubicTo(41, 17, 36, 8, 32, 3.5)
    ..lineTo(26, 4.5)
    ..cubicTo(20, 13, 12, 21, 0, 21)
    ..cubicTo(-14, 21, -24, 14, -26, 2)
    ..close();
  c.drawPath(
      body,
      Paint()
        ..shader = ui.Gradient.radial(const Offset(-6, -8), 46,
            [k(0xFF6F86E8), k(0xFF33389A), k(0xFF181B55)], const [0, .5, 1]));
  c.save();
  c.clipPath(body);
  // Twilight horizon along the belly and silver tail rays.
  c.drawOval(
      const Rect.fromLTRB(-34, 8, 30, 34),
      _gradient(k, const Offset(0, 8), const Offset(0, 22),
          [0x00C9D4FF, 0xAAC9D4FF]));
  for (final a in [-.7, -.35, .35, .7]) {
    c.drawLine(
        const Offset(34, 0),
        Offset(34 + math.cos(a) * 18, math.sin(a) * 24),
        k.line(0x66C9D4FF, .8));
  }
  c.drawArc(const Rect.fromLTRB(-20, -16, 2, 16), -1.2, 2.4, false,
      k.line(0x557F95F0, 1.2));
  // Glowing crescent moon and a constellation.
  const moonAt = Offset(6, -6);
  c.drawCircle(moonAt, 15, _glow(k, moonAt, 15, 0x77FFF1BF));
  final moon = Path.combine(
      PathOperation.difference,
      Path()..addOval(Rect.fromCircle(center: moonAt, radius: 8.5)),
      Path()
        ..addOval(Rect.fromCircle(
            center: moonAt + const Offset(4, -3), radius: 7.4)));
  c.drawPath(moon, k.fill(0xFFFFF1BF));
  c.drawPath(moon, k.line(0xFFE0C46C, .6));
  const stars = [
    Offset(-12, -13),
    Offset(-4, 9),
    Offset(10, 11),
    Offset(19, 1),
    Offset(36, -12),
    Offset(37, 13),
  ];
  c.drawPath(
      Path()..addPolygon(stars.sublist(0, 4), false), k.line(0x77E6ECFF, .6));
  for (var i = 0; i < stars.length; i++) {
    _star(c, stars[i], i.isEven ? 2.8 : 2.1, k.fill(0xFFFFFFFF));
  }
  for (final d in const [
    Offset(-18, 6),
    Offset(2, -16),
    Offset(16, -12),
    Offset(24, 8),
    Offset(-8, 15),
    Offset(30, -3),
    Offset(-2, 2)
  ]) {
    c.drawCircle(d, .8, k.fill(0xCCFFFFFF));
  }
  c.restore();
  c.drawPath(body, k.line(0xFF1D2160, 1.6));
  // Long silver pectoral fin over the side.
  final pec = Path()
    ..moveTo(-9, 2)
    ..cubicTo(-2, -1, 9, 3, 17, 11)
    ..quadraticBezierTo(4, 10, -9, 6.5)
    ..close();
  c.drawPath(
      pec,
      _gradient(k, const Offset(-9, 2), const Offset(17, 11),
          [0xEEE3E9FF, 0xCC8EA2EE]));
  c.drawPath(pec, k.line(finEdge, .9));
  // Big silver eye and a small mouth.
  c.drawCircle(const Offset(-16, -4), 5, k.fill(0xFFE9C66A));
  c.drawCircle(
      const Offset(-16, -4),
      4,
      _gradient(k, const Offset(-16, -8), const Offset(-16, 0),
          [0xFFF4F7FF, 0xFFB7C3EE]));
  c.drawCircle(const Offset(-16.4, -4), 2.4, k.fill(0xFF11133A));
  c.drawCircle(const Offset(-15.4, -5.2), 1, k.fill(0xFFFFFFFF));
  c.drawCircle(const Offset(-16, -4), 5, k.line(0xFF1D2160, .9));
  c.drawArc(
      Rect.fromCenter(center: const Offset(-23.5, 3.5), width: 5, height: 4),
      -.3,
      1.9,
      false,
      k.line(0xFFE6ECFF, 1));
}
