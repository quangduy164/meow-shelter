import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../collection/fish_species.dart';
import 'fishing_junk_art.dart';

class _Look {
  const _Look(
      {required this.top,
      required this.belly,
      required this.fin,
      required this.height,
      this.nose = -38,
      this.tailBase = 26,
      this.tailSize = 18});
  final Color top, belly, fin;
  final double height, nose, tailBase, tailSize;
}

/// Side-view fish drawn in a 100x64 box, head facing left.
class FishingFishArt extends CustomPainter {
  const FishingFishArt(this.fish, {this.locked = false});
  final FishSpecies fish;
  final bool locked;

  static const _ink = Color(0xFF34504A);

  _Look get _look => switch (fish) {
        FishSpecies.perch => const _Look(
            top: Color(0xFF5E8A3A),
            belly: Color(0xFFE7E9A8),
            fin: Color(0xFFE07A3E),
            height: 17),
        FishSpecies.tilapia => const _Look(
            top: Color(0xFF4F7F95),
            belly: Color(0xFFD3E8EA),
            fin: Color(0xFF6E92A3),
            height: 20),
        FishSpecies.carp => const _Look(
            top: Color(0xFFC07A2C),
            belly: Color(0xFFF6D88A),
            fin: Color(0xFFD9913F),
            height: 23),
        FishSpecies.catfish => const _Look(
            top: Color(0xFF5E5872),
            belly: Color(0xFFCBC5D8),
            fin: Color(0xFF6F6886),
            height: 12,
            nose: -42,
            tailBase: 30,
            tailSize: 13),
        FishSpecies.koi => const _Look(
            top: Color(0xFFFFF6E8),
            belly: Color(0xFFFFFFFF),
            fin: Color(0xFFF3E2CF),
            height: 16,
            nose: -40,
            tailSize: 22),
        FishSpecies.goldfish => const _Look(
            top: Color(0xFFF08A1E),
            belly: Color(0xFFFFD27A),
            fin: Color(0xFFF6A94A),
            height: 22,
            nose: -30,
            tailBase: 18,
            tailSize: 24),
        FishSpecies.catMew => const _Look(
            top: Color(0xFF8F8A92),
            belly: Color(0xFFEDE7EA),
            fin: Color(0xFF7D7681),
            height: 21,
            nose: -32,
            tailBase: 22),
        _ => const _Look(
            top: Color(0xFF9AA59F),
            belly: Color(0xFFE0E4E0),
            fin: Color(0xFF8E9993),
            height: 18),
      };

  @override
  void paint(Canvas canvas, Size size) {
    if (fish.isJunk) {
      FishingJunkArt(fish, locked: locked).paint(canvas, size);
      return;
    }
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(math.min(size.width / 100, size.height / 64));
    final base = _look;
    final look = locked
        ? _Look(
            top: const Color(0xFFA7B3AD),
            belly: const Color(0xFFD5DCD8),
            fin: const Color(0xFF9AA6A0),
            height: base.height,
            nose: base.nose,
            tailBase: base.tailBase,
            tailSize: base.tailSize)
        : base;
    final h = look.height, n = look.nose, tb = look.tailBase;
    final outline = Paint()
      ..color = _ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    final finPaint = Paint()..color = look.fin;

    canvas.drawOval(Rect.fromLTWH(n + 4, h + 9, tb - n + 10, 5),
        Paint()..color = const Color(0x18426058));

    // Tail and fins sit behind the body.
    final tail = _tail(tb, look.tailSize);
    canvas.drawPath(tail, finPaint);
    _tailRays(canvas, tb, look.tailSize);
    if (fish == FishSpecies.tilapia && !locked) {
      canvas.drawPath(
          Path()
            ..moveTo(tb + 18, -look.tailSize)
            ..quadraticBezierTo(tb + 12, 0, tb + 18, look.tailSize),
          Paint()
            ..color = const Color(0xFFD9574A)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3);
    }
    canvas.drawPath(tail, outline);
    final dorsal = _dorsal(n, h, tb);
    canvas.drawPath(dorsal, finPaint);
    canvas.drawPath(dorsal, outline);
    final pelvic = Path()
      ..moveTo(-8, h * .7)
      ..quadraticBezierTo(0, h + 9, 9, h * .65)
      ..close();
    canvas.drawPath(pelvic, finPaint);
    canvas.drawPath(pelvic, outline);
    if (fish == FishSpecies.catMew) _ears(canvas, n, h, look, outline);

    final body = Path()
      ..moveTo(n, 0)
      ..cubicTo(n + 4, -h * 1.05, tb - 14, -h * 1.05, tb, -h * .32)
      ..lineTo(tb, h * .32)
      ..cubicTo(tb - 14, h * 1.05, n + 4, h * 1.05, n, 0)
      ..close();
    canvas.drawPath(
        body,
        Paint()
          ..shader = LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [look.top, look.top, look.belly],
                  stops: const [0, .42, .9])
              .createShader(Rect.fromLTWH(-50, -h, 100, h * 2)));
    canvas.save();
    canvas.clipPath(body);
    if (!locked) _pattern(canvas, n, h, tb);
    canvas.drawOval(Rect.fromLTWH(n + 10, -h * .78, tb - n - 24, h * .32),
        Paint()..color = const Color(0x33FFFFFF));
    canvas.drawArc(Rect.fromLTWH(n + 10, -h * .7, 14, h * 1.4), -1.1, 2.2,
        false, outline..strokeWidth = 1.4);
    canvas.restore();
    canvas.drawPath(body, outline..strokeWidth = 2);

    final pectoral = Path()
      ..moveTo(n + 22, h * .15)
      ..quadraticBezierTo(n + 36, h * .2, n + 38, h * .62)
      ..quadraticBezierTo(n + 28, h * .55, n + 22, h * .15)
      ..close();
    canvas.drawPath(pectoral, finPaint);
    canvas.drawPath(pectoral, outline..strokeWidth = 1.5);
    _face(canvas, n, h, outline);
    if (fish == FishSpecies.goldfish) _crown(canvas, n, h, outline);
    canvas.restore();
  }

  Path _tail(double tb, double s) {
    final fan = fish == FishSpecies.goldfish || fish == FishSpecies.koi;
    final reach = fan ? 28.0 : 20.0;
    return Path()
      ..moveTo(tb - 3, 0)
      ..quadraticBezierTo(tb + 6, -s * .45, tb + reach, -s)
      ..quadraticBezierTo(tb + reach * (fan ? .55 : .65), 0, tb + reach, s)
      ..quadraticBezierTo(tb + 6, s * .45, tb - 3, 0)
      ..close();
  }

  void _tailRays(Canvas canvas, double tb, double s) {
    final ray = Paint()
      ..color = const Color(0x3334504A)
      ..strokeWidth = 1.2;
    for (final y in [-.7, -.35, 0.0, .35, .7]) {
      canvas.drawLine(Offset(tb + 2, y * 3), Offset(tb + 17, y * s), ray);
    }
  }

  Path _dorsal(double n, double h, double tb) {
    switch (fish) {
      case FishSpecies.perch:
        final path = Path()..moveTo(n + 18, -h * .85);
        for (var i = 0; i < 5; i++) {
          final x = n + 22 + i * 8.0;
          path
            ..lineTo(x, -h - 12 + i)
            ..lineTo(x + 4, -h * .95);
        }
        return path
          ..lineTo(tb - 6, -h * .5)
          ..close();
      case FishSpecies.catfish:
        return Path()
          ..moveTo(-12, -h * .9)
          ..quadraticBezierTo(-4, -h - 9, 4, -h * .85)
          ..close();
      case FishSpecies.goldfish:
        return Path()
          ..moveTo(n + 14, -h * .9)
          ..cubicTo(n + 20, -h - 16, tb - 4, -h - 14, tb + 4, -h * .4)
          ..close();
      default:
        return Path()
          ..moveTo(n + 16, -h * .9)
          ..quadraticBezierTo(-2, -h - 13, tb - 4, -h * .5)
          ..close();
    }
  }

  void _pattern(Canvas canvas, double n, double h, double tb) {
    switch (fish) {
      case FishSpecies.perch:
        for (var i = 0; i < 5; i++) {
          canvas.drawRect(Rect.fromLTWH(n + 24 + i * 10.0, -h, 4, h * 1.5),
              Paint()..color = const Color(0x553A5A20));
        }
      case FishSpecies.tilapia:
        for (var i = 0; i < 6; i++) {
          canvas.drawLine(
              Offset(n + 22 + i * 8.0, -h),
              Offset(n + 20 + i * 8.0, h),
              Paint()
                ..color = const Color(0x332C4F60)
                ..strokeWidth = 3);
        }
      case FishSpecies.carp:
      case FishSpecies.goldfish:
        final scale = Paint()
          ..color = fish == FishSpecies.carp
              ? const Color(0x669A5A1A)
              : const Color(0x55FFF0C0)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.3;
        for (var row = -1; row <= 1; row++) {
          for (var col = 0; col < 6; col++) {
            final x = n + 26 + col * 8.0 + (row.isEven ? 0 : 4);
            canvas.drawArc(
                Rect.fromCenter(
                    center: Offset(x, row * h * .45), width: 9, height: 9),
                -math.pi / 2,
                math.pi,
                false,
                scale);
          }
        }
      case FishSpecies.catfish:
        for (final spot in [
          Offset(n + 30, -h * .4),
          Offset(n + 44, -h * .2),
          Offset(n + 56, -h * .45),
          Offset(n + 64, -h * .1),
        ]) {
          canvas.drawCircle(spot, 2, Paint()..color = const Color(0x553B3550));
        }
      case FishSpecies.koi:
        final red = Paint()..color = const Color(0xFFE0543A);
        canvas.drawOval(Rect.fromLTWH(n + 2, -h, 22, h * 1.1), red);
        canvas.drawOval(Rect.fromLTWH(n + 34, -h * 1.1, 26, h * 1.2), red);
        canvas.drawOval(Rect.fromLTWH(tb - 16, -h * .2, 12, h * .7), red);
        canvas.drawCircle(Offset(n + 30, h * .2), 3,
            Paint()..color = const Color(0xFF2E2A2A));
      case FishSpecies.catMew:
        final stripe = Paint()
          ..color = const Color(0x885E5862)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round;
        for (var i = 0; i < 4; i++) {
          final x = n + 24 + i * 9.0;
          canvas.drawPath(
              Path()
                ..moveTo(x, -h)
                ..quadraticBezierTo(x + 4, -h * .5, x, -h * .1),
              stripe);
        }
      default:
        break;
    }
  }

  void _ears(Canvas canvas, double n, double h, _Look look, Paint outline) {
    for (final x in [n + 6.0, n + 20.0]) {
      final ear = Path()
        ..moveTo(x - 2, -h * .6)
        ..lineTo(x + 3, -h - 11)
        ..lineTo(x + 11, -h * .75)
        ..close();
      canvas.drawPath(ear, Paint()..color = look.top);
      canvas.drawPath(ear, outline);
      canvas.drawPath(
          Path()
            ..moveTo(x + 1, -h * .7)
            ..lineTo(x + 3.5, -h - 5)
            ..lineTo(x + 8, -h * .78)
            ..close(),
          Paint()..color = const Color(0xFFF2B6BE));
    }
  }

  void _face(Canvas canvas, double n, double h, Paint outline) {
    final catfish = fish == FishSpecies.catfish;
    final eye = Offset(n + (catfish ? 13 : 11), -h * (catfish ? .2 : .28));
    final r = switch (fish) {
      FishSpecies.goldfish => 7.5,
      FishSpecies.catfish => 4.5,
      _ => 6.0,
    };
    canvas.drawCircle(eye, r, Paint()..color = const Color(0xFFFFFBEF));
    canvas.drawCircle(eye, r, outline..strokeWidth = 1.5);
    final pupil = eye + Offset(-r * .2, r * .1);
    canvas.drawCircle(pupil, r * .55, Paint()..color = const Color(0xFF22332F));
    canvas.drawCircle(pupil + Offset(-r * .2, -r * .25), r * .2,
        Paint()..color = Colors.white);
    if (!catfish && !locked) {
      canvas.drawOval(
          Rect.fromCenter(center: Offset(n + 15, h * .32), width: 8, height: 4),
          Paint()..color = const Color(0x66F08A96));
    }
    final mouth = Offset(n + 3, h * .14);
    if (fish == FishSpecies.catMew) {
      canvas.drawPath(
          Path()
            ..moveTo(n + 1, h * .02)
            ..lineTo(n + 5, h * .02)
            ..lineTo(n + 3, h * .12)
            ..close(),
          Paint()..color = const Color(0xFFE48795));
      canvas.drawPath(
          Path()
            ..moveTo(n + 3, h * .12)
            ..quadraticBezierTo(n + 1, h * .3, n - 1, h * .22)
            ..moveTo(n + 3, h * .12)
            ..quadraticBezierTo(n + 5, h * .3, n + 7, h * .22),
          outline..strokeWidth = 1.2);
    } else {
      canvas.drawArc(Rect.fromCenter(center: mouth, width: 7, height: 5), .2,
          2.4, false, outline..strokeWidth = 1.5);
    }
    if (catfish || fish == FishSpecies.catMew || fish == FishSpecies.carp) {
      final whisker = Paint()
        ..color = _ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round;
      final length = catfish
          ? 20.0
          : fish == FishSpecies.carp
              ? 7.0
              : 14.0;
      for (final dy in catfish ? [-3.0, 2.0, 6.0] : [0.0, 4.0]) {
        canvas.drawPath(
            Path()
              ..moveTo(mouth.dx, mouth.dy + dy * .3)
              ..quadraticBezierTo(mouth.dx - length * .5, mouth.dy + dy,
                  mouth.dx - length, mouth.dy + dy * 2.2),
            whisker);
      }
    }
  }

  void _crown(Canvas canvas, double n, double h, Paint outline) {
    final x = n + 14;
    final crown = Path()
      ..moveTo(x - 9, -h + 1)
      ..lineTo(x - 11, -h - 9)
      ..lineTo(x - 4, -h - 4)
      ..lineTo(x, -h - 12)
      ..lineTo(x + 4, -h - 4)
      ..lineTo(x + 11, -h - 9)
      ..lineTo(x + 9, -h + 1)
      ..close();
    canvas.drawPath(crown, Paint()..color = const Color(0xFFF6D76A));
    canvas.drawPath(crown, outline..strokeWidth = 1.5);
    canvas.drawCircle(
        Offset(x, -h - 4), 1.8, Paint()..color = const Color(0xFFDE5F6F));
  }

  @override
  bool shouldRepaint(covariant FishingFishArt oldDelegate) =>
      fish != oldDelegate.fish || locked != oldDelegate.locked;
}
