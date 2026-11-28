import 'dart:math' as math;
import 'package:flutter/painting.dart';
import '../../collection/fish_species.dart';
import '../../fishing/fishing_legendary_hunts.dart';

final _signFill = Paint();
final _signLine = Paint()
  ..style = PaintingStyle.stroke
  ..strokeWidth = 2;
final _longShadow = Path()
  ..moveTo(-62, 4)
  ..cubicTo(-30, -24, 4, 15, 25, -8)
  ..cubicTo(40, -27, 58, -22, 60, -10)
  ..cubicTo(42, -15, 41, 4, 27, 9)
  ..cubicTo(-3, 26, -28, -13, -62, 4)
  ..close();

/// Dynamic clues only; existing scenery caches remain untouched.
void paintLegendarySign(Canvas c, FishingLegendarySign sign) {
  c.save();
  c.translate(sign.position.dx, sign.position.dy);
  final t = sign.age;
  _signLine.strokeWidth = 2;
  final color = switch (sign.fish) {
    FishSpecies.catMew => const Color(0xFF8CDEC9),
    FishSpecies.moonfish => const Color(0xFFC9D8FF),
    _ => const Color(0xFFFFD598),
  };
  switch (sign.fish) {
    case FishSpecies.catMew:
      c.rotate(sign.heading);
      c.drawPath(_longShadow, _signFill..color = const Color(0x99405D62));
      for (var i = 0; i < 3; i++) {
        final k = (t * .5 + i / 3) % 1;
        c.drawOval(
            Rect.fromCenter(
                center: Offset(-38 + k * 28, 8),
                width: 20 + k * 60,
                height: 7 + k * 19),
            _signLine..color = color.withValues(alpha: (1 - k) * .6));
      }
      if (sign.revealed) {
        c.drawOval(const Rect.fromLTWH(25, -28, 24, 38),
            _signFill..color = const Color(0xAA42636A));
        c.drawCircle(const Offset(30, -20), 2,
            _signFill..color = const Color(0xFFE5FFF3));
      }
    case FishSpecies.moonfish:
      if (!sign.decoy && sign.revealed) {
        c.drawOval(const Rect.fromLTWH(-21, 10, 42, 12),
            _signFill..color = const Color(0xAA354C6C));
        c.drawCircle(const Offset(-12, 14), 2,
            _signFill..color = const Color(0xFFE2EBFF));
      }
      for (var i = 0; i < 9; i++) {
        final y = -44 + i * 11.0;
        final spread = (1 - (y / 65).abs()) * 42;
        c.drawOval(
            Rect.fromCenter(
                center: Offset(math.sin(t * 1.6 + i) * 6, y),
                width: spread,
                height: 3),
            _signFill
              ..color = color.withValues(alpha: sign.revealed ? .65 : .3));
      }
      if (sign.revealed) {
        c.drawCircle(const Offset(0, -8), 13,
            _signFill..color = const Color(0x99E2E9FF));
        c.drawCircle(const Offset(5, -12), 11,
            _signFill..color = const Color(0xCC486879));
      }
    case FishSpecies.seaDragon:
      for (final r in [
        FishingLegendaryHunts.dragonInner,
        FishingLegendaryHunts.dragonOuter
      ]) {
        c.drawCircle(
            Offset.zero,
            r,
            _signLine
              ..strokeWidth = 1
              ..color = color.withValues(alpha: .23));
      }
      if (t < 9) {
        final wave = (t / 3).floor();
        final radius = FishingLegendaryHunts.waveRadius(t);
        final half = math.acos(.25);
        final arc = Rect.fromCircle(center: Offset.zero, radius: radius);
        final start = FishingLegendaryHunts.waveDirection(wave) - half;
        c.drawArc(
            arc,
            start,
            2 * half,
            false,
            _signLine
              ..strokeWidth = 44
              ..color = const Color(0x33FF8D69));
        c.drawArc(
            arc,
            start,
            2 * half,
            false,
            _signLine
              ..strokeWidth = 2
              ..color = const Color(0xDDFBC49B));
      }
      for (var i = 0; i < 3; i++) {
        c.drawCircle(
            Offset((i - 1) * 15, -35),
            3,
            _signFill
              ..color = sign.failed
                  ? const Color(0xFFCE7970)
                  : i < sign.progress
                      ? const Color(0xFF8DE8D3)
                      : const Color(0x777C9596));
      }
      if (sign.ready) {
        for (var i = 0; i < 3; i++) {
          c.drawArc(
              Rect.fromCenter(
                  center: Offset.zero, width: 42 + i * 25, height: 16 + i * 12),
              t * 1.7 + i * 2,
              math.pi * 1.2,
              false,
              _signLine
                ..strokeWidth = 2
                ..color = color.withValues(alpha: .7 - i * .15));
        }
      }
    default:
      break;
  }
  if (sign.ready && sign.fish != FishSpecies.moonfish) {
    c.drawOval(const Rect.fromLTWH(-55, -25, 110, 50),
        _signLine..color = color.withValues(alpha: .8));
  }
  c.restore();
}
