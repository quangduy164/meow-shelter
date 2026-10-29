import 'package:flutter/material.dart';
import '../../collection/fish_species.dart';
import 'fishing_junk_art.dart';

class FishingFishArt extends CustomPainter {
  const FishingFishArt(this.fish, {this.locked = false});
  final FishSpecies fish;
  final bool locked;

  @override
  void paint(Canvas canvas, Size size) {
    if (fish.isJunk) {
      FishingJunkArt(fish, locked: locked).paint(canvas, size);
      return;
    }
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    final scale = (size.width / 100).clamp(0.0, size.height / 64);
    canvas.scale(scale);
    final color = locked
        ? const Color(0xFFABB9B1)
        : switch (fish) {
            FishSpecies.perch => const Color(0xFF9DBB58),
            FishSpecies.tilapia => const Color(0xFF7ABAC8),
            FishSpecies.carp => const Color(0xFFE8B667),
            FishSpecies.catfish => const Color(0xFF9B93BA),
            FishSpecies.koi => const Color(0xFFF3E7CE),
            FishSpecies.goldfish => const Color(0xFFEEA642),
            FishSpecies.catMew => const Color(0xFFB7A6A0),
            _ => const Color(0xFFABB9B1),
          };
    final fin = Color.lerp(color, const Color(0xFF45655C), .25)!;
    final height = switch (fish) {
      FishSpecies.catfish => 13.0,
      FishSpecies.carp || FishSpecies.goldfish || FishSpecies.catMew => 22.0,
      _ => 18.0,
    };
    final outline = Paint()
      ..color = const Color(0xFF426058)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawOval(const Rect.fromLTWH(-34, 24, 72, 5),
        Paint()..color = const Color(0x18426058));
    final tail = Path()
      ..moveTo(23, 0)
      ..lineTo(44, -18)
      ..quadraticBezierTo(37, 0, 44, 18)
      ..close();
    canvas.drawPath(tail, Paint()..color = fin);
    canvas.drawPath(tail, outline);
    final dorsal = Path()
      ..moveTo(-14, -height + 3)
      ..lineTo(-4, -height - 10)
      ..lineTo(15, -height - 2)
      ..lineTo(22, -height + 8)
      ..close();
    canvas.drawPath(dorsal, Paint()..color = fin);
    if (fish == FishSpecies.catMew) {
      final ear = Paint()..color = const Color(0xFF9C8780);
      canvas.drawPath(
          Path()
            ..moveTo(-28, -height + 5)
            ..lineTo(-23, -height - 19)
            ..lineTo(-9, -height + 1)
            ..close(),
          ear);
      canvas.drawPath(
          Path()
            ..moveTo(-2, -height + 1)
            ..lineTo(10, -height - 17)
            ..lineTo(18, -height + 8)
            ..close(),
          ear);
      canvas.drawLine(Offset(-22, -height - 12), Offset(-14, -height - 3),
          outline..strokeWidth = 1.5);
      canvas.drawLine(Offset(4, -height - 10), Offset(11, -height - 3),
          outline..strokeWidth = 1.5);
    }
    final body = _bodyPath(fish, height);
    canvas.drawPath(body, Paint()..color = color);
    canvas.drawPath(body, outline);
    canvas.save();
    canvas.clipPath(body);
    if (fish == FishSpecies.koi && !locked) {
      for (final spot in [const Offset(-14, -9), const Offset(10, 5)]) {
        canvas.drawOval(Rect.fromCenter(center: spot, width: 18, height: 23),
            Paint()..color = const Color(0xFFD76B4C));
      }
    } else if (fish == FishSpecies.perch || fish == FishSpecies.tilapia) {
      for (var i = 0; i < 4; i++) {
        canvas.drawLine(
            Offset(-9 + i * 9.0, -height),
            Offset(-4 + i * 9.0, height * .65),
            Paint()
              ..color = const Color(0x55426058)
              ..strokeWidth = 3);
      }
    }
    canvas.restore();
    canvas.drawArc(const Rect.fromLTWH(-28, -11, 16, 22), -.9, 1.8, false,
        outline..strokeWidth = 1);
    canvas.drawPath(
        Path()
          ..moveTo(-4, 3)
          ..lineTo(10, 17)
          ..lineTo(12, 4)
          ..close(),
        Paint()..color = fin);
    final ink = Paint()..color = const Color(0xFF294941);
    for (final eye in [const Offset(-24, -8), const Offset(-10, -10)]) {
      canvas.drawOval(Rect.fromCenter(center: eye, width: 15, height: 18),
          Paint()..color = const Color(0xFFFFF9E8));
      canvas.drawOval(
          Rect.fromCenter(center: eye, width: 15, height: 18), outline);
      final pupil = eye + Offset(-2, fish == FishSpecies.perch ? 2 : 0);
      canvas.drawCircle(pupil, 3.2, ink);
      canvas.drawCircle(
          pupil + const Offset(-1, -1), 1, Paint()..color = Colors.white);
      if (fish == FishSpecies.tilapia || fish == FishSpecies.catfish) {
        canvas.drawArc(Rect.fromCenter(center: eye, width: 15, height: 18),
            3.14, 3.14, true, Paint()..color = color);
        canvas.drawLine(
            eye + const Offset(-7, 0), eye + const Offset(7, 0), outline);
      }
    }
    if (fish == FishSpecies.perch) {
      canvas.drawOval(const Rect.fromLTWH(-28, 6, 12, 9), ink);
      canvas.drawLine(const Offset(-31, -22), const Offset(-20, -19),
          outline..strokeWidth = 2);
      canvas.drawLine(const Offset(-14, -21), const Offset(-3, -25), outline);
    } else if (fish == FishSpecies.koi) {
      canvas.drawOval(const Rect.fromLTWH(-33, 4, 9, 5),
          Paint()..color = const Color(0xFFD46B78));
      canvas.drawOval(const Rect.fromLTWH(-6, 4, 10, 5),
          Paint()..color = const Color(0x77E4919A));
    } else {
      canvas.drawPath(
          Path()
            ..moveTo(-29, 5)
            ..quadraticBezierTo(-20, 17, -9, 5),
          outline..strokeWidth = 2);
      if (fish == FishSpecies.carp) {
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                const Rect.fromLTWH(-23, 7, 9, 7), const Radius.circular(1)),
            Paint()..color = const Color(0xFFFFFAE9));
        canvas.drawLine(const Offset(-19, 8), const Offset(-19, 13),
            outline..strokeWidth = 1);
      }
    }
    if (fish == FishSpecies.catMew) {
      final whisker = outline..strokeWidth = 1;
      for (final y in [-2.0, 5.0]) {
        canvas.drawLine(Offset(-32, y), Offset(-48, y - 3), whisker);
        canvas.drawLine(Offset(14, y), Offset(30, y - 3), whisker);
      }
      canvas.drawCircle(
          const Offset(-9, 4), 2.5, Paint()..color = const Color(0xFFD87883));
    }
    if (fish == FishSpecies.goldfish) {
      final crown = Path()
        ..moveTo(-22, -21)
        ..lineTo(-25, -30)
        ..lineTo(-17, -26)
        ..lineTo(-12, -32)
        ..lineTo(-7, -25)
        ..lineTo(0, -29)
        ..lineTo(-3, -20)
        ..close();
      canvas.drawPath(crown, Paint()..color = const Color(0xFFF6D76A));
      canvas.drawPath(crown, outline);
      canvas.drawCircle(
          const Offset(-12, -24), 2, Paint()..color = const Color(0xFFDE7972));
    }
    if (fish == FishSpecies.catfish) {
      for (final sign in [-1.0, 1.0]) {
        canvas.drawPath(
            Path()
              ..moveTo(-25, 6)
              ..cubicTo(-36, 1, -46, sign * 17, -40, sign * 19)
              ..quadraticBezierTo(-36, sign * 20, -37, sign * 15),
            outline..strokeWidth = 1.5);
      }
    }
    canvas.restore();
  }

  Path _bodyPath(FishSpecies fish, double height) => switch (fish) {
        FishSpecies.perch => Path()
          ..moveTo(31, 0)
          ..cubicTo(18, -height * .95, -18, -height * .78, -34, 0)
          ..cubicTo(-18, height * .78, 18, height * .95, 31, 0)
          ..close(),
        FishSpecies.tilapia => Path()
          ..moveTo(30, 0)
          ..cubicTo(18, -height * 1.05, -20, -height * 1.05, -35, 0)
          ..cubicTo(-20, height * 1.05, 18, height * 1.05, 30, 0)
          ..close(),
        FishSpecies.carp => Path()
          ..moveTo(27, 0)
          ..cubicTo(19, -height * 1.2, -15, -height * 1.35, -32, -height * .25)
          ..cubicTo(-36, height * .6, -12, height * 1.35, 24, height * .8)
          ..cubicTo(31, height * .45, 34, height * .18, 27, 0)
          ..close(),
        FishSpecies.catfish => Path()
          ..moveTo(34, 0)
          ..cubicTo(18, -height * .72, -18, -height * .65, -37, 0)
          ..cubicTo(-18, height * .65, 18, height * .72, 34, 0)
          ..close(),
        FishSpecies.koi => Path()
          ..moveTo(35, 0)
          ..cubicTo(16, -height * .82, -18, -height * .72, -35, 0)
          ..cubicTo(-18, height * .72, 16, height * .82, 35, 0)
          ..close(),
        FishSpecies.goldfish => Path()
          ..moveTo(27, 0)
          ..cubicTo(20, -height * 1.35, -17, -height * 1.45, -33, 0)
          ..cubicTo(-17, height * 1.45, 20, height * 1.35, 27, 0)
          ..close(),
        FishSpecies.catMew => Path()
          ..moveTo(28, 0)
          ..cubicTo(22, -height * 1.1, -18, -height * 1.15, -31, 0)
          ..cubicTo(-18, height * 1.15, 22, height * 1.1, 28, 0)
          ..close(),
        _ => Path()
          ..addOval(Rect.fromCenter(
              center: const Offset(-3, 0), width: 65, height: height * 2)),
      };

  @override
  bool shouldRepaint(covariant FishingFishArt oldDelegate) =>
      fish != oldDelegate.fish || locked != oldDelegate.locked;
}
