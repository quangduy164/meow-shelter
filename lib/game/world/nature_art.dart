import 'dart:math' as math;

import 'package:flutter/painting.dart';

/// Shared nature art (clouds and trees) for the home screen and the Return
/// Home landscape. Both are seeded, so the same call always draws the same
/// shape and can be recorded into cached pictures.

/// Colours for [paintPuffyCloud]: lit top, main body and the shaded belly.
class CloudPalette {
  const CloudPalette(this.light, this.body, this.shade);
  final Color light, body, shade;

  static const day =
      CloudPalette(Color(0xFFFFFFFF), Color(0xFFF4F8FF), Color(0xFFC8D9EA));
  static const dusk =
      CloudPalette(Color(0xFFFFF6EE), Color(0xFFF7DCE0), Color(0xFFC6A3C6));
}

/// Cumulus cloud [width] wide, sitting on a flat base centred on [center].
/// Built from overlapping puffs in three tones: a shaded underside, the body
/// shifted up, and soft highlights on the upper-left of the tallest puffs.
void paintPuffyCloud(Canvas canvas, Offset center, double width,
    {int seed = 0,
    CloudPalette palette = CloudPalette.day,
    double opacity = .92}) {
  final random = math.Random(seed);
  final w = width;
  final baseY = center.dy + w * .10;
  final puffs = <(Offset, double)>[];
  const count = 6;
  for (var i = 0; i < count; i++) {
    final t = i / (count - 1);
    final bump = math.sin(t * math.pi);
    final r = w * (.10 + .11 * bump) * (.85 + random.nextDouble() * .3);
    final x = center.dx -
        w * .38 +
        t * w * .76 +
        (random.nextDouble() - .5) * w * .04;
    puffs.add((Offset(x, baseY - r * .55 - bump * w * .06), r));
  }
  // Two crown puffs make the top lumpy instead of a single dome.
  for (final f in const [-.12, .14]) {
    final r = w * (.15 + random.nextDouble() * .04);
    puffs.add((Offset(center.dx + f * w, baseY - w * .19 - r * .3), r));
  }
  final base = RRect.fromRectAndRadius(
      Rect.fromLTRB(
          center.dx - w * .47, baseY - w * .10, center.dx + w * .47, baseY),
      Radius.circular(w * .05));

  final bounds =
      Rect.fromCenter(center: center, width: w * 1.3, height: w * 1.0);
  canvas.saveLayer(bounds, Paint()..color = Color.fromRGBO(0, 0, 0, opacity));
  // 1. Shaded underside: the full silhouette.
  final shade = Paint()..color = palette.shade;
  canvas.drawRRect(base, shade);
  for (final (c, r) in puffs) {
    canvas.drawCircle(c, r, shade);
  }
  // 2. Body: same puffs lifted a little, leaving a shaded belly underneath.
  final lift = Offset(0, -w * .035);
  final bodyShape = Path()..addRRect(base.shift(lift).deflate(w * .012));
  for (final (c, r) in puffs) {
    bodyShape.addOval(Rect.fromCircle(center: c + lift, radius: r * .95));
  }
  canvas.drawPath(bodyShape, Paint()..color = palette.body);
  canvas.save();
  canvas.clipPath(bodyShape);
  // 3. Highlights on the upper-left of the bigger puffs.
  final light = Paint()
    ..color = palette.light
    ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * .012);
  for (final (c, r) in puffs) {
    if (r < w * .14) continue;
    canvas.drawCircle(c + lift + Offset(-r * .22, -r * .28), r * .58, light);
  }
  // 4. A few soft creases where puffs meet, for depth.
  final crease = Paint()
    ..color = palette.shade.withOpacity(.45)
    ..style = PaintingStyle.stroke
    ..strokeWidth = w * .012
    ..strokeCap = StrokeCap.round;
  for (var i = 1; i < count - 1; i += 2) {
    final (c, r) = puffs[i];
    canvas.drawArc(Rect.fromCircle(center: c + lift, radius: r * .8),
        math.pi * .15, math.pi * .5, false, crease);
  }
  canvas.restore();
  canvas.restore();
}

/// Trunk and leaf tones for [paintLeafyTree].
class TreePalette {
  const TreePalette(
      this.trunk, this.bark, this.leafDark, this.leafMid, this.leafLight);
  final Color trunk, bark, leafDark, leafMid, leafLight;

  static const day = TreePalette(Color(0xFF8C6245), Color(0xFF6A4630),
      Color(0xFF3B7A4E), Color(0xFF4E9663), Color(0xFF86C474));
  static const dusk = TreePalette(Color(0xFF7A5236), Color(0xFF573722),
      Color(0xFF3C6E50), Color(0xFF55905F), Color(0xFF9CC883));
}

/// A round-crowned tree [height] tall standing on [base]: tapered trunk with
/// root flare and two branches, and a canopy of clustered leaf blobs in three
/// tones (shadow, mid, sunlit upper-left) with small leaf flecks on top.
void paintLeafyTree(Canvas canvas, Offset base, double height,
    {int seed = 0, TreePalette palette = TreePalette.day}) {
  final random = math.Random(seed);
  final h = height;
  final crown = base - Offset(0, h * .64);
  final radius = h * .34;

  // Ground shadow.
  canvas.drawOval(
      Rect.fromCenter(
          center: base + Offset(h * .04, h * .01),
          width: h * .62,
          height: h * .09),
      Paint()..color = const Color(0x33302010));

  // Trunk: wide at the roots, narrowing into the crown.
  final trunk = Path()
    ..moveTo(base.dx - h * .09, base.dy)
    ..quadraticBezierTo(base.dx - h * .04, base.dy - h * .04,
        base.dx - h * .035, base.dy - h * .16)
    ..lineTo(base.dx - h * .028, crown.dy + radius * .2)
    ..lineTo(base.dx + h * .028, crown.dy + radius * .2)
    ..lineTo(base.dx + h * .035, base.dy - h * .16)
    ..quadraticBezierTo(
        base.dx + h * .04, base.dy - h * .04, base.dx + h * .10, base.dy)
    ..close();
  canvas.drawPath(trunk, Paint()..color = palette.trunk);
  // Shaded right side of the trunk and a couple of bark lines.
  canvas.save();
  canvas.clipPath(trunk);
  canvas.drawRect(
      Rect.fromLTRB(base.dx + h * .008, crown.dy, base.dx + h * .12, base.dy),
      Paint()..color = palette.bark.withOpacity(.55));
  final bark = Paint()
    ..color = palette.bark
    ..style = PaintingStyle.stroke
    ..strokeWidth = h * .008
    ..strokeCap = StrokeCap.round;
  for (final y in [.10, .22, .32]) {
    canvas.drawArc(
        Rect.fromCenter(
            center: Offset(base.dx - h * .01, base.dy - h * y),
            width: h * .04,
            height: h * .03),
        math.pi * .1,
        math.pi * .8,
        false,
        bark);
  }
  canvas.restore();
  // Branches reaching into the crown.
  final branch = Paint()
    ..color = palette.trunk
    ..style = PaintingStyle.stroke
    ..strokeWidth = h * .025
    ..strokeCap = StrokeCap.round;
  canvas.drawLine(base - Offset(h * .01, h * .38),
      crown + Offset(-radius * .55, radius * .25), branch);
  canvas.drawLine(base - Offset(-h * .01, h * .42),
      crown + Offset(radius * .5, radius * .15), branch);

  // Canopy blobs: a ring around the crown plus a centre mass.
  final blobs = <(Offset, double)>[(crown, radius * .62)];
  const ring = 9;
  for (var i = 0; i < ring; i++) {
    final a = i * math.pi * 2 / ring + random.nextDouble() * .3;
    final d = radius * (.52 + random.nextDouble() * .12);
    final r = radius * (.38 + random.nextDouble() * .14);
    blobs.add((crown + Offset(math.cos(a) * d, math.sin(a) * d * .9), r));
  }
  final dark = Paint()..color = palette.leafDark;
  for (final (c, r) in blobs) {
    canvas.drawCircle(c, r, dark);
  }
  // Mid tone shifted toward the light, leaving a dark rim lower-right.
  final shift = Offset(-radius * .07, -radius * .09);
  final midShape = Path();
  for (final (c, r) in blobs) {
    midShape.addOval(Rect.fromCircle(center: c + shift, radius: r * .82));
  }
  canvas.drawPath(midShape, Paint()..color = palette.leafMid);
  // Sunlit clumps, kept inside the mid tone so they read as light falling
  // on the leaves rather than separate balls.
  canvas.save();
  canvas.clipPath(midShape);
  final light = Paint()..color = palette.leafLight.withOpacity(.9);
  for (final (c, r) in blobs) {
    final rel = c - crown;
    if (rel.dx > radius * .35 || rel.dy > radius * .25) continue;
    canvas.drawCircle(c + shift * 2.6, r * .62, light);
  }
  // Darker clumps between them break up the crown into leaf masses.
  final inner = Paint()..color = palette.leafDark.withOpacity(.35);
  for (var i = 1; i < blobs.length; i += 3) {
    final (c, r) = blobs[i];
    canvas.drawCircle(
        Offset.lerp(c, crown, .45)! + Offset(r * .2, r * .25), r * .35, inner);
  }
  canvas.restore(); // Leaf flecks: light ticks up top, dark dots underneath.
  final fleck = Paint()
    ..color = palette.leafLight
    ..style = PaintingStyle.stroke
    ..strokeWidth = h * .01
    ..strokeCap = StrokeCap.round;
  final dot = Paint()..color = palette.leafDark;
  for (var i = 0; i < 14; i++) {
    final a = random.nextDouble() * math.pi * 2;
    final d = random.nextDouble() * radius * .85;
    final p = crown + Offset(math.cos(a) * d, math.sin(a) * d * .85);
    if (p.dy < crown.dy) {
      canvas.drawArc(Rect.fromCircle(center: p, radius: h * .018),
          math.pi * 1.1, math.pi * .6, false, fleck);
    } else {
      canvas.drawCircle(p, h * .009, dot);
    }
  }
}
