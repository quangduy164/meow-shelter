import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../fishing/fishing_lighting.dart';

/// Normalized scenery keeps the lake centered on different screen sizes.
class FishingLandscape extends CustomPainter {
  const FishingLandscape({required this.sceneHeight, required this.lighting});
  final double sceneHeight;
  final FishingLighting lighting;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.saveLayer(
        Offset.zero & size, Paint()..colorFilter = lighting.terrainFilter);
    canvas.drawRect(
        Rect.fromLTWH(0, sceneHeight, size.width, size.height - sceneHeight),
        Paint()..color = const Color(0xFFADC77F));
    final bankRandom = math.Random(84);
    for (var i = 0; i < 220; i++) {
      final x = bankRandom.nextDouble() * size.width;
      final y =
          sceneHeight + bankRandom.nextDouble() * (size.height - sceneHeight);
      canvas.drawLine(
          Offset(x, y),
          Offset(x + 3, y - 2),
          Paint()
            ..color = const Color(0x33718A43)
            ..strokeWidth = 1.2);
    }
    final bankPath = Path()
      ..moveTo(size.width * .67, sceneHeight * .94)
      ..quadraticBezierTo(
          size.width * .66, size.height * .88, size.width * .43, size.height)
      ..lineTo(size.width * .59, size.height)
      ..quadraticBezierTo(size.width * .79, size.height * .87, size.width * .77,
          sceneHeight * .94)
      ..close();
    canvas.drawPath(bankPath, Paint()..color = const Color(0xFFD4C594));
    canvas.save();
    canvas.scale(size.width / 1000, sceneHeight / 600);
    canvas.drawPath(
        Path()
          ..moveTo(0, 310)
          ..lineTo(110, 130)
          ..lineTo(230, 270)
          ..lineTo(390, 85)
          ..lineTo(570, 280)
          ..lineTo(710, 140)
          ..lineTo(880, 275)
          ..lineTo(1000, 155)
          ..lineTo(1000, 420)
          ..lineTo(0, 420)
          ..close(),
        Paint()..color = const Color(0xFF7CAFB2));
    canvas.drawPath(
        Path()
          ..moveTo(340, 146)
          ..lineTo(390, 85)
          ..lineTo(447, 147)
          ..lineTo(411, 132)
          ..lineTo(390, 151)
          ..lineTo(370, 133)
          ..close(),
        Paint()..color = const Color(0xFFEDF6E4));
    for (final peak in [
      const Offset(110, 130),
      const Offset(390, 85),
      const Offset(710, 140),
      const Offset(1000, 155)
    ]) {
      canvas.drawPath(
          Path()
            ..moveTo(peak.dx, peak.dy)
            ..lineTo(peak.dx - 22, peak.dy + 95)
            ..lineTo(peak.dx + 65, 310)
            ..lineTo(peak.dx + 145, 310)
            ..close(),
          Paint()..color = const Color(0x33506479));
      for (var j = 0; j < 7; j++) {
        canvas.drawLine(
            peak + Offset(j * 4.0, 40 + j * 12.0),
            peak + Offset(22 + j * 8.0, 100 + j * 12.0),
            Paint()
              ..color = const Color(0x2274867E)
              ..strokeWidth = 2);
      }
    }
    canvas.drawPath(
        Path()
          ..moveTo(0, 294)
          ..cubicTo(85, 275, 135, 303, 225, 287)
          ..cubicTo(325, 269, 390, 287, 495, 279)
          ..cubicTo(600, 268, 680, 296, 770, 282)
          ..cubicTo(865, 269, 935, 296, 1000, 285)
          ..lineTo(1000, 600)
          ..lineTo(0, 600)
          ..close(),
        Paint()..color = const Color(0xFFADC77F));
    final distantRandom = math.Random(19);
    for (final cluster in [
      (x: 185.0, y: 290.0),
      (x: 310.0, y: 280.0),
      (x: 735.0, y: 287.0),
      (x: 820.0, y: 282.0),
    ]) {
      for (var i = 0; i < 5; i++) {
        final x = cluster.x + i * 9;
        final y = cluster.y + math.sin(i * 1.8) * 3;
        final height = 14 + distantRandom.nextDouble() * 17;
        canvas.drawOval(
            Rect.fromCenter(center: Offset(x, y + 1), width: 18, height: 5),
            Paint()..color = const Color(0x22718A61));
        canvas.drawLine(
            Offset(x, y),
            Offset(x, y - height * .7),
            Paint()
              ..color = const Color(0xFF778367)
              ..strokeWidth = 2);
        canvas.drawPath(
            Path()
              ..moveTo(x, y - height)
              ..lineTo(x - 6, y - height * .42)
              ..lineTo(x - 3, y - height * .44)
              ..lineTo(x - 9, y - 3)
              ..quadraticBezierTo(x, y, x + 9, y - 3)
              ..lineTo(x + 3, y - height * .44)
              ..lineTo(x + 6, y - height * .42)
              ..close(),
            Paint()
              ..color =
                  i.isEven ? const Color(0xFF789B82) : const Color(0xFF8DA58A));
      }
    }
    final random = math.Random(42);
    // Seeded grass and soil strokes stay stable during gameplay.
    for (var i = 0; i < 1800; i++) {
      final x = random.nextDouble() * 1000;
      final y = 340 + random.nextDouble() * 260;
      final length = 2 + random.nextDouble() * 7;
      canvas.drawLine(
          Offset(x, y),
          Offset(x + length, y - 2),
          Paint()
            ..color =
                i.isEven ? const Color(0x33718A43) : const Color(0x55E3DF9A)
            ..strokeWidth = 1 + random.nextDouble() * 2);
    }
    canvas.save();
    canvas.drawOval(const Rect.fromLTWH(188, 281, 624, 255),
        Paint()..color = const Color(0xFF72985D));
    canvas.drawOval(const Rect.fromLTWH(200, 280, 600, 240),
        Paint()..color = const Color(0xFFE1D2A2));
    canvas.drawOval(
        const Rect.fromLTWH(214, 293, 572, 212),
        Paint()
          ..shader = const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF388EAD), Color(0xFF77DAD6)])
              .createShader(const Rect.fromLTWH(214, 293, 572, 212)));
    canvas.save();
    canvas.clipPath(Path()..addOval(const Rect.fromLTWH(214, 293, 572, 212)));
    for (var i = 0; i < 340; i++) {
      final x = 214 + random.nextDouble() * 572;
      final y = 293 + random.nextDouble() * 212;
      canvas.drawLine(
          Offset(x, y),
          Offset(x + 4 + random.nextDouble() * 32, y),
          Paint()
            ..color =
                i % 3 == 0 ? const Color(0x447AE6DA) : const Color(0x3373B5BD)
            ..strokeWidth = 1 + random.nextDouble() * 2);
    }
    canvas.restore();
    for (var i = 0; i < 48; i++) {
      final angle = i * math.pi * 2 / 48;
      final x = 500 + math.cos(angle) * 300;
      final y = 400 + math.sin(angle) * 119;
      final stone = Rect.fromCenter(
          center: Offset(x, y),
          width: 12 + random.nextDouble() * 18,
          height: 7 + random.nextDouble() * 9);
      canvas.drawOval(stone.shift(const Offset(1, 3)),
          Paint()..color = const Color(0x55645237));
      canvas.drawOval(
          stone,
          Paint()
            ..color =
                i.isEven ? const Color(0xFFABA793) : const Color(0xFFC8BC9D));
      canvas.drawArc(
          stone.deflate(2),
          math.pi,
          2,
          false,
          Paint()
            ..color = const Color(0x88F5E8CC)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
    }
    canvas.restore();
    for (final tree in [
      (x: 58.0, base: 407.0, height: 176.0, width: 41.0, lean: -8.0),
      (x: 128.0, base: 421.0, height: 211.0, width: 49.0, lean: 6.0),
      (x: 866.0, base: 405.0, height: 189.0, width: 44.0, lean: -7.0),
      (x: 943.0, base: 424.0, height: 224.0, width: 52.0, lean: 10.0),
    ]) {
      _pine(canvas, Offset(tree.x, tree.base), tree.height, tree.width,
          tree.lean);
    }
    _shoreDetails(canvas);
    // Reeds and flowers along the foreground banks.
    canvas.save();
    for (final base in [
      const Offset(215, 480),
      const Offset(785, 475),
      const Offset(170, 525)
    ]) {
      for (var i = 0; i < 9; i++) {
        final root = base + Offset(i * 4.0, 0);
        final tip = root +
            Offset(
                random.nextDouble() * 12 - 6, -20 - random.nextDouble() * 25);
        canvas.drawLine(
            root,
            tip,
            Paint()
              ..color = const Color(0xFF5A7940)
              ..strokeWidth = 2);
        if (i % 3 == 0) {
          canvas.drawOval(Rect.fromCenter(center: tip, width: 4, height: 12),
              Paint()..color = const Color(0xFF85583C));
        }
      }
    }
    canvas.drawOval(const Rect.fromLTWH(646, 548, 151, 40),
        Paint()..color = const Color(0x3361452E));
    final timber = Paint()..strokeCap = StrokeCap.round;
    for (final x in [681.0, 754.0]) {
      canvas.drawLine(
          Offset(x, 441),
          Offset(x, 479),
          timber
            ..color = const Color(0xFF72533F)
            ..strokeWidth = 9);
      canvas.drawOval(
          Rect.fromCenter(center: Offset(x, 441), width: 12, height: 6),
          Paint()..color = const Color(0xFFE2C28B));
    }
    canvas.drawPath(
        Path()
          ..moveTo(679, 450)
          ..lineTo(756, 450)
          ..lineTo(785, 577)
          ..lineTo(648, 577)
          ..close(),
        Paint()..color = const Color(0xFF70513C));
    for (var i = 0; i < 8; i++) {
      final t = i / 8;
      final next = (i + 1) / 8;
      final left = 681 - 30 * t;
      final right = 754 + 28 * t;
      final top = 448 + 122 * t;
      final bottom = 448 + 122 * next - 1.5;
      canvas.drawPath(
          Path()
            ..moveTo(left, top)
            ..lineTo(right, top)
            ..lineTo(754 + 28 * next, bottom)
            ..lineTo(681 - 30 * next, bottom)
            ..close(),
          Paint()
            ..color =
                i.isEven ? const Color(0xFFC49A6C) : const Color(0xFFD3AB7A));
      canvas.drawLine(
          Offset(left + 1, top + 1),
          Offset(right - 1, top + 1),
          timber
            ..color = const Color(0xFFE7C994)
            ..strokeWidth = 1.3);
      for (var grain = 0; grain < 3; grain++) {
        final y = top + 4 + grain * 3;
        canvas.drawPath(
            Path()
              ..moveTo(left + 7, y)
              ..cubicTo(left + 27, y - 2, right - 30, y + 3, right - 8, y),
            Paint()
              ..color = const Color(0x667E5C40)
              ..style = PaintingStyle.stroke
              ..strokeWidth = .9);
      }
      if (i == 2 || i == 6) {
        canvas.drawOval(
            Rect.fromCenter(
                center: Offset(left + 30, top + 8), width: 11, height: 4),
            Paint()
              ..color = const Color(0x887E5C40)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1);
      }
      for (final x in [left + 5, right - 5]) {
        canvas.drawCircle(
            Offset(x, top + 6), 1.5, Paint()..color = const Color(0xFF63564A));
      }
    }
    for (final x in [652.0, 781.0]) {
      canvas.drawLine(
          Offset(x, 550),
          Offset(x, 585),
          timber
            ..color = const Color(0xFF79583F)
            ..strokeWidth = 10);
      canvas.drawLine(
          Offset(x - 2, 552),
          Offset(x - 2, 581),
          timber
            ..color = const Color(0xFFC49A6C)
            ..strokeWidth = 3);
      canvas.drawOval(
          Rect.fromCenter(center: Offset(x, 549), width: 13, height: 7),
          Paint()..color = const Color(0xFFE2C28B));
    }
    canvas.restore();
    // Fine translucent grain unifies the painted surfaces.
    for (var i = 0; i < 2500; i++) {
      canvas.drawCircle(
          Offset(random.nextDouble() * 1000, random.nextDouble() * 600),
          .5 + random.nextDouble() * .7,
          Paint()..color = const Color(0x0D5F563C));
    }
    canvas.restore();
    canvas.restore();
  }

  void _pine(
      Canvas canvas, Offset base, double height, double width, double lean) {
    canvas.save();
    canvas.translate(base.dx, base.dy);
    canvas.drawOval(
        Rect.fromCenter(
            center: const Offset(5, 2), width: width * 1.8, height: 15),
        Paint()..color = const Color(0x28604431));
    canvas.drawPath(
        Path()
          ..moveTo(-6, 0)
          ..quadraticBezierTo(-2, -height * .55, lean, -height + 22)
          ..quadraticBezierTo(9, -height * .45, 7, 0)
          ..close(),
        Paint()..color = const Color(0xFF806347));
    canvas.drawLine(
        const Offset(-2, -6),
        Offset(lean * .5, -height * .55),
        Paint()
          ..color = const Color(0xFFB48C5F)
          ..strokeWidth = 2);
    for (var layer = 5; layer >= 0; layer--) {
      final t = (layer + 1) / 6;
      final top = -height + layer * (height - 30) / 7;
      final bottom = top + height * .30;
      final center = lean * (1 - t) + math.sin(layer * 2 + base.dx) * 2;
      final spread = width * (.20 + .80 * t);
      final bough = Path()
        ..moveTo(center, top)
        ..cubicTo(center - spread * .2, top + 18, center - spread * .46,
            bottom - 22, center - spread, bottom - 9)
        ..quadraticBezierTo(center - spread * .83, bottom + 2,
            center - spread * .47, bottom - 4)
        ..quadraticBezierTo(
            center - spread * .21, bottom + 3, center, bottom - 4)
        ..quadraticBezierTo(center + spread * .45, bottom + 3,
            center + spread * .70, bottom - 3)
        ..quadraticBezierTo(
            center + spread * .90, bottom + 1, center + spread, bottom - 10)
        ..cubicTo(center + spread * .5, bottom - 20, center + spread * .24,
            top + 15, center, top)
        ..close();
      canvas.drawPath(bough.shift(const Offset(1, 3)),
          Paint()..color = const Color(0x33415E43));
      canvas.drawPath(
          bough,
          Paint()
            ..color = layer.isEven
                ? const Color(0xFF407F65)
                : const Color(0xFF4A896B));
      canvas.drawPath(
          Path()
            ..moveTo(center, top + 6)
            ..quadraticBezierTo(center - spread * .3, bottom - 19,
                center - spread * .82, bottom - 9)
            ..quadraticBezierTo(
                center - spread * .38, bottom - 10, center - 1, bottom - 17)
            ..close(),
          Paint()..color = const Color(0xFF71A378));
      canvas.drawPath(
          Path()
            ..moveTo(center + 4, top + 18)
            ..quadraticBezierTo(center + spread * .4, bottom - 16,
                center + spread * .86, bottom - 8),
          Paint()
            ..color = const Color(0x6651795D)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
    }
    for (final side in [-1.0, 1.0]) {
      canvas.drawPath(
          Path()
            ..moveTo(side * 3, -4)
            ..quadraticBezierTo(side * 12, 1, side * 17, 0),
          Paint()
            ..color = const Color(0xFF806347)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
            ..strokeCap = StrokeCap.round);
    }
    canvas.restore();
  }

  void _shoreDetails(Canvas canvas) {
    for (final patch in [
      const Offset(250, 552),
      const Offset(840, 505),
      const Offset(174, 365)
    ]) {
      canvas.drawOval(Rect.fromCenter(center: patch, width: 53, height: 10),
          Paint()..color = const Color(0x22507543));
      for (var i = 0; i < 7; i++) {
        final root = patch + Offset((i - 3) * 6.0, math.sin(i * 2) * 3);
        final head = root + Offset(math.sin(i) * 4, -12 - (i % 3) * 6.0);
        canvas.drawLine(
            root,
            head,
            Paint()
              ..color = const Color(0xFF547F4C)
              ..strokeWidth = 1.6);
        canvas.drawOval(
            Rect.fromCenter(
                center: root + const Offset(3, -5), width: 9, height: 4),
            Paint()..color = const Color(0xFF6B9754));
        final petal = Paint()
          ..color =
              i.isEven ? const Color(0xFFF2EACE) : const Color(0xFFE7A0A1);
        for (var p = 0; p < 5; p++) {
          canvas.drawCircle(
              head + Offset.fromDirection(p * math.pi * 2 / 5, 3), 2.7, petal);
        }
        canvas.drawCircle(head, 1.9, Paint()..color = const Color(0xFFE5BB5D));
      }
    }
    for (final rock in [const Offset(110, 478), const Offset(882, 448)]) {
      canvas.drawOval(
          Rect.fromCenter(
              center: rock + const Offset(3, 4), width: 43, height: 11),
          Paint()..color = const Color(0x22604431));
      canvas.drawPath(
          Path()
            ..moveTo(rock.dx - 20, rock.dy)
            ..lineTo(rock.dx - 13, rock.dy - 15)
            ..lineTo(rock.dx + 5, rock.dy - 19)
            ..lineTo(rock.dx + 21, rock.dy - 5)
            ..lineTo(rock.dx + 17, rock.dy + 3)
            ..close(),
          Paint()..color = const Color(0xFFA9B2A0));
      canvas.drawPath(
          Path()
            ..moveTo(rock.dx - 13, rock.dy - 15)
            ..lineTo(rock.dx + 5, rock.dy - 19)
            ..lineTo(rock.dx + 8, rock.dy - 6)
            ..lineTo(rock.dx - 16, rock.dy - 4)
            ..close(),
          Paint()..color = const Color(0xFFCED0B5));
      canvas.drawOval(
          Rect.fromCenter(
              center: rock + const Offset(-9, -2), width: 14, height: 5),
          Paint()..color = const Color(0xFF749163));
    }
    canvas.save();
    canvas.translate(104, 543);
    canvas.rotate(-.12);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(-38, -10, 76, 21), const Radius.circular(5)),
        Paint()..color = const Color(0xFF967553));
    canvas.drawOval(const Rect.fromLTWH(29, -10, 17, 21),
        Paint()..color = const Color(0xFFD9BB88));
    canvas.drawOval(
        const Rect.fromLTWH(33, -6, 9, 13),
        Paint()
          ..color = const Color(0xFF967553)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1);
    for (var i = 0; i < 3; i++) {
      canvas.drawLine(
          Offset(-31, -5 + i * 6.0),
          Offset(26, -3 + i * 5.0),
          Paint()
            ..color = const Color(0xFF6E5D45)
            ..strokeWidth = 1.5);
    }
    canvas.drawOval(const Rect.fromLTWH(-17, -12, 29, 8),
        Paint()..color = const Color(0xFF78975B));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant FishingLandscape oldDelegate) =>
      sceneHeight != oldDelegate.sceneHeight ||
      lighting.hour != oldDelegate.lighting.hour;
}
