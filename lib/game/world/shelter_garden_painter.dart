import 'dart:math' as math;
import 'package:flutter/rendering.dart';

class ShelterGardenPainter extends CustomPainter {
  const ShelterGardenPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 1000, size.height / 500);
    canvas.drawRect(const Rect.fromLTWH(0, 0, 1000, 500),
        Paint()..color = const Color(0xFFACCE91));
    canvas.drawRect(
        const Rect.fromLTWH(0, 0, 1000, 100),
        Paint()
          ..shader = const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFA8DFE4), Color(0xFFEAF2D4)])
              .createShader(const Rect.fromLTWH(0, 0, 1000, 110)));
    for (final cloud in [const Offset(200, 20), const Offset(652, 24)]) {
      canvas.drawPath(
          Path()
            ..moveTo(cloud.dx, cloud.dy + 12)
            ..cubicTo(cloud.dx - 14, cloud.dy, cloud.dx + 12, cloud.dy - 10,
                cloud.dx + 25, cloud.dy)
            ..cubicTo(cloud.dx + 30, cloud.dy - 21, cloud.dx + 62,
                cloud.dy - 18, cloud.dx + 66, cloud.dy)
            ..cubicTo(cloud.dx + 96, cloud.dy - 7, cloud.dx + 111,
                cloud.dy + 15, cloud.dx + 80, cloud.dy + 16)
            ..close(),
          Paint()..color = const Color(0xBBFFFCEE));
    }
    final hedge = Path()..moveTo(0, 57);
    for (var x = 0.0; x < 1000; x += 60) {
      hedge.quadraticBezierTo(x + 25, 27 + math.sin(x) * 10, x + 60, 62);
    }
    hedge
      ..lineTo(1000, 118)
      ..lineTo(0, 118)
      ..close();
    canvas.drawPath(hedge, Paint()..color = const Color(0xFF76AC80));
    canvas.drawPath(hedge.shift(const Offset(0, 19)),
        Paint()..color = const Color(0xFF8DBC81));
    _fence(canvas);
    final path = Path()
      ..moveTo(469, 112)
      ..cubicTo(465, 145, 450, 169, 445, 188)
      ..quadraticBezierTo(490, 172, 534, 188)
      ..cubicTo(521, 156, 525, 134, 530, 112)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xFFE4D4AB));
    for (var i = 0; i < 4; i++) {
      final stone = Rect.fromCenter(
          center: Offset(496 - math.sin(i) * 4, 124 + i * 13.0),
          width: 34 + i * 2,
          height: 8);
      canvas.drawOval(stone.shift(const Offset(0, 2)),
          Paint()..color = const Color(0x447C8865));
      canvas.drawOval(stone, Paint()..color = const Color(0xFFF0E7CA));
    }
    _tree(canvas, const Offset(10, 125), false);
    _tree(canvas, const Offset(990, 128), true);
    _bench(canvas);
    _wateringCan(canvas);
    final random = math.Random(91);
    for (var i = 0; i < 160; i++) {
      final x = random.nextDouble() * 1000;
      final y = 129 + random.nextDouble() * 365;
      // Keep the playable lawn quiet and the five shelter positions clear.
      if (x > 160 && x < 840 && y < 430) continue;
      if ((x < 205 || x > 795) &&
          ((y > 133 && y < 205) || (y > 317 && y < 409))) continue;
      canvas.drawPath(
          Path()
            ..moveTo(x - 3, y)
            ..lineTo(x - 4, y - 4)
            ..moveTo(x, y)
            ..lineTo(x + 1, y - 6)
            ..moveTo(x + 3, y)
            ..lineTo(x + 6, y - 3),
          Paint()
            ..color = const Color(0x44678F58)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2
            ..strokeCap = StrokeCap.round);
    }
    for (final patch in [
      const Offset(55, 272),
      const Offset(942, 272),
      const Offset(185, 472),
      const Offset(825, 472)
    ]) {
      _flowers(canvas, patch);
    }
    _yarn(canvas, const Offset(118, 456));
    for (final rock in [
      const Offset(18, 302),
      const Offset(975, 310),
      const Offset(886, 465)
    ]) {
      canvas.drawOval(
          Rect.fromCenter(
              center: rock + const Offset(0, 3), width: 26, height: 8),
          Paint()..color = const Color(0x2260784B));
      canvas.drawPath(
          Path()
            ..moveTo(rock.dx - 13, rock.dy)
            ..lineTo(rock.dx - 8, rock.dy - 9)
            ..lineTo(rock.dx + 6, rock.dy - 11)
            ..lineTo(rock.dx + 13, rock.dy - 1)
            ..quadraticBezierTo(rock.dx, rock.dy + 5, rock.dx - 13, rock.dy)
            ..close(),
          Paint()..color = const Color(0xFFB4BCA6));
      canvas.drawLine(
          rock + const Offset(-6, -7),
          rock + const Offset(5, -8),
          Paint()
            ..color = const Color(0xFFE1E5CD)
            ..strokeWidth = 2
            ..strokeCap = StrokeCap.round);
    }
    canvas.restore();
  }

  void _fence(Canvas canvas) {
    final rail = Paint()..color = const Color(0xFFD4C7A3);
    canvas.drawRect(const Rect.fromLTWH(0, 79, 1000, 8), rail);
    canvas.drawRect(const Rect.fromLTWH(0, 103, 1000, 7), rail);
    for (var i = 0; i < 36; i++) {
      final x = i * 29.0 - 7;
      if (x > 449 && x < 543) continue;
      final top = 63 + (i % 3) * 2.0;
      canvas.drawPath(
          Path()
            ..moveTo(x, 116)
            ..lineTo(x, top + 7)
            ..lineTo(x + 9, top)
            ..lineTo(x + 18, top + 7)
            ..lineTo(x + 18, 116)
            ..close(),
          Paint()..color = const Color(0xFFF6EFD7));
      canvas.drawLine(
          Offset(x + 15, top + 10),
          Offset(x + 15, 113),
          Paint()
            ..color = const Color(0xFFD9CDAA)
            ..strokeWidth = 2);
      canvas.drawCircle(
          Offset(x + 8, 84), 1.3, Paint()..color = const Color(0xFFB6AA89));
    }
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(448, 73, 100, 47), const Radius.circular(4)),
        Paint()..color = const Color(0xFFB18C60));
    for (var i = 0; i < 6; i++) {
      canvas.drawRect(
          Rect.fromLTWH(453 + i * 16.0, 76, 12, 39),
          Paint()
            ..color =
                i.isEven ? const Color(0xFFD7B681) : const Color(0xFFCBA672));
    }
    canvas.drawLine(
        const Offset(455, 110),
        const Offset(538, 81),
        Paint()
          ..color = const Color(0xFFAF8758)
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round);
    canvas.drawCircle(
        const Offset(536, 97), 2.5, Paint()..color = const Color(0xFF776548));
  }

  void _tree(Canvas canvas, Offset root, bool mirror) {
    canvas.save();
    canvas.translate(root.dx, root.dy);
    if (mirror) canvas.scale(-1, 1);
    canvas.drawOval(const Rect.fromLTWH(-34, -4, 94, 14),
        Paint()..color = const Color(0x22607B4D));
    canvas.drawPath(
        Path()
          ..moveTo(-13, 1)
          ..quadraticBezierTo(-4, -48, -17, -99)
          ..lineTo(8, -109)
          ..quadraticBezierTo(4, -65, 17, -44)
          ..lineTo(42, -65)
          ..lineTo(48, -57)
          ..lineTo(20, -31)
          ..lineTo(23, 0)
          ..close(),
        Paint()..color = const Color(0xFF967551));
    canvas.drawPath(
        Path()
          ..moveTo(-3, -5)
          ..quadraticBezierTo(5, -53, -6, -83),
        Paint()
          ..color = const Color(0xFFC59C68)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round);
    final canopy = Path()
      ..moveTo(-93, -82)
      ..cubicTo(-112, -121, -75, -152, -46, -138)
      ..cubicTo(-23, -172, 21, -158, 27, -137)
      ..cubicTo(65, -158, 103, -126, 86, -105)
      ..cubicTo(115, -81, 80, -47, 52, -58)
      ..cubicTo(36, -35, 3, -45, -5, -59)
      ..cubicTo(-38, -39, -74, -56, -69, -72)
      ..quadraticBezierTo(-93, -67, -93, -82)
      ..close();
    canvas.drawPath(canopy, Paint()..color = const Color(0xFF4D8F68));
    canvas.save();
    canvas.clipPath(canopy);
    canvas.drawPath(canopy.shift(const Offset(-7, -19)),
        Paint()..color = const Color(0xFF78AD73));
    canvas.drawPath(
        Path()
          ..moveTo(-74, -112)
          ..cubicTo(-62, -141, -29, -127, -17, -135)
          ..cubicTo(14, -148, 38, -123, 60, -126)
          ..quadraticBezierTo(84, -100, 64, -94)
          ..cubicTo(34, -107, 20, -91, -5, -108)
          ..quadraticBezierTo(-47, -97, -74, -112)
          ..close(),
        Paint()..color = const Color(0xFF9AC382));
    canvas.restore();
    canvas.restore();
  }

  void _bench(Canvas canvas) {
    canvas.save();
    canvas.translate(216, 100);
    final leg = Paint()
      ..color = const Color(0xFF856D4D)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(-32, 3), const Offset(-36, 22), leg);
    canvas.drawLine(const Offset(33, 3), const Offset(37, 22), leg);
    for (var i = 0; i < 2; i++) {
      canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(-44, -22 + i * 12.0, 88, 9),
              const Radius.circular(2)),
          Paint()..color = const Color(0xFFCEAE77));
    }
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(-48, 3, 96, 11), const Radius.circular(3)),
        Paint()..color = const Color(0xFFB99865));
    canvas.drawLine(
        const Offset(-42, 5),
        const Offset(43, 5),
        Paint()
          ..color = const Color(0xFFE5CAA0)
          ..strokeWidth = 1.5);
    canvas.restore();
  }

  void _wateringCan(Canvas canvas) {
    canvas.save();
    canvas.translate(850, 115);
    canvas.drawOval(const Rect.fromLTWH(-19, 8, 52, 7),
        Paint()..color = const Color(0x225C7951));
    canvas.drawOval(
        const Rect.fromLTWH(10, -21, 21, 25),
        Paint()
          ..color = const Color(0xFF598F96)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5);
    canvas.drawPath(
        Path()
          ..moveTo(-16, -1)
          ..lineTo(-35, -14)
          ..lineTo(-38, -9)
          ..lineTo(-18, 8)
          ..close(),
        Paint()..color = const Color(0xFF72AEB1));
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(-20, -15, 38, 27), const Radius.circular(5)),
        Paint()..color = const Color(0xFF8AC3C0));
    canvas.drawOval(const Rect.fromLTWH(-17, -18, 31, 7),
        Paint()..color = const Color(0xFF5B9295));
    canvas.drawLine(
        const Offset(-14, -7),
        const Offset(-14, 4),
        Paint()
          ..color = const Color(0xFFBCE0D1)
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round);
    canvas.restore();
  }

  void _flowers(Canvas canvas, Offset origin) {
    canvas.drawOval(Rect.fromCenter(center: origin, width: 59, height: 14),
        Paint()..color = const Color(0xFF86AF72));
    for (var i = 0; i < 6; i++) {
      final root = origin + Offset((i - 2.5) * 8, math.sin(i) * 3);
      final head = root + Offset(math.sin(i * 2) * 3, -12 - (i % 3) * 6.0);
      canvas.drawLine(
          root,
          head,
          Paint()
            ..color = const Color(0xFF5D905E)
            ..strokeWidth = 1.6);
      canvas.drawOval(
          Rect.fromCenter(
              center: root + const Offset(-3, -5), width: 9, height: 5),
          Paint()..color = const Color(0xFF70A76A));
      for (var p = 0; p < 5; p++) {
        canvas.drawCircle(
            head + Offset.fromDirection(p * math.pi * 2 / 5, 3),
            2.5,
            Paint()
              ..color =
                  i.isEven ? const Color(0xFFFFEDD7) : const Color(0xFFEAA3AC));
      }
      canvas.drawCircle(head, 1.6, Paint()..color = const Color(0xFFE8BA5A));
    }
  }

  void _yarn(Canvas canvas, Offset origin) {
    canvas.drawOval(
        Rect.fromCenter(
            center: origin + const Offset(0, 9), width: 28, height: 6),
        Paint()..color = const Color(0x225C7951));
    canvas.drawCircle(origin, 12, Paint()..color = const Color(0xFFE3A2A4));
    final thread = Paint()
      ..color = const Color(0xFFBE7F88)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 4; i++) {
      canvas.drawArc(
          Rect.fromCircle(center: origin + Offset(i * 3.0 - 4, 0), radius: 10),
          -1.1,
          2.5,
          false,
          thread);
    }
    canvas.drawPath(
        Path()
          ..moveTo(origin.dx + 9, origin.dy + 8)
          ..cubicTo(origin.dx + 44, origin.dy + 7, origin.dx + 17,
              origin.dy + 23, origin.dx + 47, origin.dy + 17),
        thread);
  }

  @override
  bool shouldRepaint(covariant ShelterGardenPainter oldDelegate) => false;
}
