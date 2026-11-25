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

/// Rồng biển: a slender blue sea serpent curled into a "C", with silky
/// ragged fins along the back, a pale segmented belly and a fan tail.
void _dragon(Canvas c, _Ink k) {
  Offset cubic(Offset a, Offset b, Offset q, Offset d, double t) {
    final u = 1 - t;
    return a * (u * u * u) +
        b * (3 * u * u * t) +
        q * (3 * u * t * t) +
        d * (t * t * t);
  }

  // Spine: from the neck along the top, round the right, back along the
  // bottom to the tail.
  const seg = 26;
  final spine = <Offset>[
    for (var i = 0; i < seg; i++)
      cubic(const Offset(-24, -13), const Offset(-8, -24),
          const Offset(24, -27), const Offset(36, -6), i / seg),
    for (var i = 0; i <= seg; i++)
      cubic(const Offset(36, -6), const Offset(44, 15), const Offset(12, 28),
          const Offset(-12, 20), i / seg),
  ];
  final n = spine.length - 1;
  double radius(int i) {
    final t = i / n;
    return t < .2
        ? 5.6 + (t / .2) * 3.4
        : 9 - 7.2 * math.pow((t - .2) / .8, .8).toDouble();
  }

  Offset dir(int i) {
    final d = spine[math.min(n, i + 1)] - spine[math.max(0, i - 1)];
    return d / d.distance;
  }

  // Normal toward the inside of the curl (the belly side).
  Offset inner(int i) {
    final d = dir(i);
    return Offset(-d.dy, d.dx);
  }

  final back = [for (var i = 0; i <= n; i++) spine[i] - inner(i) * radius(i)];
  final belly = [for (var i = 0; i <= n; i++) spine[i] + inner(i) * radius(i)];
  const finFill = 0xDDA6E6EE, finRay = 0xFF3D90B8, finEdge = 0xFF2A6E92;

  // Ragged silk fin rooted on one edge, its spikes swept toward the tail.
  void fin(List<Offset> edge, int from, int to, double height,
      {required bool outside}) {
    final path = Path()..moveTo(edge[from].dx, edge[from].dy);
    final tips = <(Offset, Offset)>[];
    for (var i = from; i <= to; i += 2) {
      final t = (i - from) / math.max(1, to - from);
      final h =
          height * (.45 + .55 * math.sin(t * math.pi)) * (i.isEven ? 1 : .8);
      final out = inner(i) * (outside ? -1 : 1);
      final tip = edge[i] + out * h + dir(i) * h * .55;
      final notch = edge[math.min(n, i + 1)] + out * h * .45;
      path
        ..quadraticBezierTo((edge[i] + out * h * .7).dx,
            (edge[i] + out * h * .7).dy, tip.dx, tip.dy)
        ..lineTo(notch.dx, notch.dy);
      tips.add((edge[i], tip));
    }
    path
      ..lineTo(edge[to].dx, edge[to].dy)
      ..close();
    c.drawPath(path, k.fill(finFill));
    for (final (from, tip) in tips) {
      c.drawLine(from, Offset.lerp(from, tip, .9)!, k.line(finRay, .7));
    }
    c.drawPath(path, k.line(finEdge, .8));
  }

  // Fins behind the body: big dorsal sail, back fins, belly fins.
  fin(back, 3, 20, 12, outside: true);
  fin(back, 23, 33, 9, outside: true);
  fin(back, 37, 46, 8, outside: true);
  fin(belly, 30, 37, 6, outside: false);
  fin(belly, 42, 48, 6, outside: false);

  // Fan tail: long silky lobes spreading from the tip.
  final end = spine[n], tailDir = dir(n);
  final base = tailDir.direction;
  for (final (a, len, w) in const [
    (-.85, 17.0, 4.2),
    (-.3, 20.0, 4.6),
    (.25, 18.0, 4.4),
    (.8, 15.0, 3.8),
  ]) {
    final tip = end + Offset.fromDirection(base + a, len);
    final lobe = _leaf(end - tailDir * 3, tip, w, a * 2);
    c.drawPath(lobe, k.fill(finFill));
    c.drawLine(end, Offset.lerp(end, tip, .85)!, k.line(finRay, .7));
    c.drawPath(lobe, k.line(finEdge, .8));
  }

  // Body: deep blue back fading to aqua, pale belly plates, dark spots.
  final body = Path()..addPolygon([...back, ...belly.reversed], true);
  c.drawPath(
      body,
      _gradient(k, const Offset(0, -26), const Offset(0, 26),
          [0xFF1F64A6, 0xFF3F97C8, 0xFF62BCD4]));
  c.save();
  c.clipPath(body);
  c.drawPath(Path()..addPolygon(back, false), k.line(0xFF174E86, 4.5));
  final plateLine = [
    for (var i = 0; i <= n; i++) spine[i] + inner(i) * radius(i) * .5
  ];
  c.drawPath(Path()..addPolygon([...plateLine, ...belly.reversed], true),
      k.fill(0xFFDDF5F2));
  for (var i = 3; i < n - 1; i += 2) {
    c.drawLine(plateLine[i], belly[i] + inner(i) * 2, k.line(0xFF8CC4D2, .8));
  }
  c.drawPath(Path()..addPolygon(plateLine, false), k.line(0xFF7DB7CC, .8));
  for (var i = 2; i < n - 3; i++) {
    for (final f in i.isEven ? const [-.6, -.05] : const [-.32, .25]) {
      final p = spine[i] + inner(i) * radius(i) * f;
      c.drawLine(
          p, p + dir(i) * (i % 3 == 0 ? 2.2 : 1.3), k.line(0xFF143F72, 1.1));
    }
  }
  c.drawPath(
      Path()
        ..addPolygon(
            [for (var i = 0; i <= n; i++) spine[i] - inner(i) * radius(i) * .7],
            false),
      k.line(0x55D5F7FF, .9));
  c.restore();
  c.drawPath(body, k.line(0xFF1E4F73, 1.2));

  // Wing-like pectoral fin over the shoulder.
  final shoulder = spine[7] + inner(7) * 4;
  final pecTip = shoulder + inner(7) * 11 + dir(7) * 14;
  final pec = _leaf(shoulder, pecTip, 5, -2);
  c.drawPath(pec, k.fill(finFill));
  for (final f in const [.3, .55, .8]) {
    c.drawLine(
        shoulder, Offset.lerp(shoulder, pecTip, f + .1)!, k.line(finRay, .6));
  }
  c.drawPath(pec, k.line(finEdge, .8));

  // Head, drawn facing +x in a mirrored frame so it looks left.
  const h = Offset(-1, .12);
  c.save();
  c.translate(spine[0].dx, spine[0].dy);
  c.scale(-1.3, 1.3);
  c.rotate(math.atan2(h.dy, -h.dx));
  // Frilled mane and swept-back horns behind the skull.
  for (final (to, w) in const [
    (Offset(-13, -9), 3.2),
    (Offset(-15, -2), 3.4),
    (Offset(-12, 5), 3.0),
    (Offset(-7, 9), 2.6),
  ]) {
    final frill = _leaf(const Offset(1, -1), to, w, 1.2);
    c.drawPath(frill, k.fill(finFill));
    c.drawPath(frill, k.line(finEdge, .8));
  }
  for (final (from, to, w) in const [
    (Offset(4, -4.5), Offset(-9, -11.5), 1.6),
    (Offset(6, -4.8), Offset(-5, -13), 1.2),
  ]) {
    c.drawPath(
        Path()
          ..moveTo(from.dx, from.dy)
          ..quadraticBezierTo(from.dx - 3, to.dy + 2, to.dx, to.dy),
        k.line(0xFF9FD3E6, w));
  }
  final jaw = Path()
    ..moveTo(4, 2.2)
    ..lineTo(18.5, 1.6)
    ..quadraticBezierTo(18, 3.6, 15, 3.8)
    ..lineTo(6, 5)
    ..close();
  c.drawPath(jaw, k.fill(0xFFCDEFF0));
  c.drawPath(jaw, k.line(0xFF1E4F73, .8));
  final skull = Path()
    ..moveTo(-2, -4.6)
    ..cubicTo(5, -7.6, 11, -6.2, 15, -3.6)
    ..lineTo(21.5, -1.4)
    ..quadraticBezierTo(23, .3, 20.8, 1)
    ..lineTo(10, 2.2)
    ..lineTo(4, 4.2)
    ..cubicTo(1, 5.4, -2.5, 4, -3, 1.6)
    ..close();
  c.drawPath(
      skull,
      _gradient(k, const Offset(0, -7), const Offset(0, 4),
          [0xFF2C79B4, 0xFF5BB8D4, 0xFF9FDCE4]));
  c.drawPath(
      Path()
        ..moveTo(2, -4)
        ..quadraticBezierTo(9, -5.6, 15, -2.6),
      k.line(0x66D5F7FF, .8));
  for (final x in [16.5, 12.5]) {
    c.drawPath(
        Path()
          ..moveTo(x, 1.6)
          ..lineTo(x + .7, 3.8)
          ..lineTo(x + 1.4, 1.5)
          ..close(),
        k.fill(0xFFFFFFFF));
  }
  c.drawPath(skull, k.line(0xFF1E4F73, 1));
  // Narrow eye under a heavy brow, nostril.
  final eye = Path()
    ..moveTo(5.5, -2.4)
    ..quadraticBezierTo(8, -4.4, 10.5, -2.8)
    ..quadraticBezierTo(8, -1.4, 5.5, -2.4)
    ..close();
  c.drawPath(eye, k.fill(0xFFF3F8E8));
  c.drawCircle(const Offset(8.4, -2.7), .95, k.fill(0xFF1B2A33));
  c.drawLine(
      const Offset(4.5, -4), const Offset(11, -4.2), k.line(0xFF173F63, 1.1));
  c.drawCircle(const Offset(19.5, -1.4), .55, k.fill(0xFF173F63));
  // Long flowing whiskers: two trailing back, one curling up.
  for (final w in [
    Path()
      ..moveTo(18, 1.4)
      ..cubicTo(10, 9, 0, 6, -10, 14),
    Path()
      ..moveTo(16, 2.4)
      ..cubicTo(9, 12, -2, 12, -6, 20),
    Path()
      ..moveTo(17, -2.6)
      ..cubicTo(13, -10, 6, -11, 2, -17),
  ]) {
    c.drawPath(w, k.line(0xFF7FC4DA, .8));
  }
  c.restore();
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
