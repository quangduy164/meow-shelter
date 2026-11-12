import 'dart:math' as math;
import 'package:flutter/painting.dart';
import 'herd_market.dart';
import 'herd_round.dart';

/// Vision cones and vendors, drawn under the cats so cats stay readable.
void paintMarketVendors(Canvas canvas, HerdRound round) {
  final range = round.vendorRange;
  for (var i = 0; i < round.map.vendors.length; i++) {
    final vendor = round.map.vendors[i];
    final origin =
        Offset(vendor.at.dx * round.field.x, vendor.at.dy * round.field.y);
    final angle = vendor.angle(round.time);
    final watching = vendor.watching(round.time);
    final warning = vendor.warning(round.time);
    final z = round.map.lanternZones[i];
    final zone = Rect.fromLTWH(z.left * round.field.x, z.top * round.field.y,
        z.width * round.field.x, z.height * round.field.y);
    if (watching || warning) {
      canvas.save();
      canvas
          .clipRRect(RRect.fromRectAndRadius(zone, const Radius.circular(18)));
      final cone = Path()
        ..moveTo(origin.dx, origin.dy)
        ..arcTo(Rect.fromCircle(center: origin, radius: range),
            angle - HerdVendor.halfAngle, HerdVendor.halfAngle * 2, false)
        ..close();
      final pulse = .5 + .5 * math.sin(round.time * 12);
      // Dark zones hide cats, so the cone fades there via the overlay later.
      canvas.drawPath(
          cone,
          Paint()
            ..color = watching
                ? const Color(0x40FFE08A)
                : Color.fromRGBO(255, 160, 80, .12 + .1 * pulse));
      canvas.drawPath(
          cone,
          Paint()
            ..color = watching
                ? const Color(0x99F0B44C)
                : Color.fromRGBO(240, 120, 60, .4 + .4 * pulse)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
      canvas.restore();
    }
    _vendor(canvas, origin, angle, watching, i);
    if (round.shoutingVendor == i && round.shoutTime > 0) {
      _bubble(
          canvas, origin + const Offset(0, -38), '!', const Color(0xFFD9534F));
    } else if (!watching && !warning) {
      _bubble(
          canvas, origin + const Offset(0, -38), 'z', const Color(0xFF6E6A8F));
    }
  }
}

void _vendor(Canvas c, Offset at, double angle, bool watching, int index) {
  const shirts = [Color(0xFF6F9FB8), Color(0xFFC77A62), Color(0xFF86A86B)];
  c.drawOval(
      Rect.fromCenter(center: at + const Offset(0, 12), width: 28, height: 8),
      Paint()..color = const Color(0x55201B2E));
  c.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: at + const Offset(0, 3), width: 22, height: 20),
          const Radius.circular(8)),
      Paint()..color = shirts[index % shirts.length]);
  final head = at + const Offset(0, -12);
  c.drawCircle(head, 8, Paint()..color = const Color(0xFFF1C9A0));
  // Conical hat, tilted toward where the vendor is looking.
  c.save();
  c.translate(head.dx, head.dy - 4);
  c.rotate(math.cos(angle) * .25);
  c.drawPath(
      Path()
        ..moveTo(-14, 2)
        ..lineTo(0, -10)
        ..lineTo(14, 2)
        ..close(),
      Paint()..color = const Color(0xFFE9CF8E));
  c.drawLine(
      const Offset(-14, 2),
      const Offset(14, 2),
      Paint()
        ..color = const Color(0xFFB99A5C)
        ..strokeWidth = 1.5);
  c.restore();
  final eyes = Paint()..color = const Color(0xFF3A2A22);
  if (watching) {
    final look = Offset(math.cos(angle) * 2.5, math.sin(angle) * 2);
    for (final dx in [-3.0, 3.0]) {
      c.drawCircle(head + Offset(dx, 0) + look, 1.4, eyes);
    }
  } else {
    for (final dx in [-3.0, 3.0]) {
      c.drawLine(head + Offset(dx - 1.5, 1), head + Offset(dx + 1.5, 1),
          eyes..strokeWidth = 1.2);
    }
  }
}

void _bubble(Canvas c, Offset at, String text, Color color) {
  c.drawCircle(at, 9, Paint()..color = const Color(0xF2FFF4DA));
  final t = TextPainter(
      text: TextSpan(
          text: text,
          style: TextStyle(
              color: color, fontSize: 13, fontWeight: FontWeight.w900)),
      textDirection: TextDirection.ltr)
    ..layout();
  t.paint(c, at - Offset(t.width / 2, t.height / 2));
}

/// Unlit lantern zones, drawn over cats so darkness reads as cover.
void paintMarketDarkness(Canvas canvas, HerdRound round) {
  for (var i = 0; i < round.map.lanternZones.length; i++) {
    final z = round.map.lanternZones[i];
    final box = Rect.fromLTWH(z.left * round.field.x, z.top * round.field.y,
        z.width * round.field.x, z.height * round.field.y);
    final lit = HerdLanterns.lit(i, round.time);
    final flicker = HerdLanterns.flickering(i, round.time);
    if (!lit) {
      canvas.drawRRect(
          RRect.fromRectAndRadius(box, const Radius.circular(18)),
          Paint()
            ..color = const Color(0x8C0B0C1E)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
    }
    // A row of lanterns along the zone's top edge shows its state.
    final count = (box.width / 46).floor().clamp(2, 8);
    for (var k = 0; k < count; k++) {
      final x = box.left + (k + .5) * box.width / count;
      final on = lit && (!flicker || math.sin(round.time * 30 + k) > -.2);
      final p = Offset(x, box.top + 6);
      canvas.drawLine(
          p + const Offset(0, -6),
          p,
          Paint()
            ..color = const Color(0xFF2B2840)
            ..strokeWidth = 1);
      if (on) {
        canvas.drawCircle(p + const Offset(0, 6), 14,
            Paint()..color = const Color(0x26FFC46E));
      }
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromCenter(
                  center: p + const Offset(0, 6), width: 11, height: 13),
              const Radius.circular(4)),
          Paint()
            ..color = on ? const Color(0xFFF0A65F) : const Color(0xFF4E4660));
    }
  }
}
