import 'package:flutter/rendering.dart';

/// Hand-drawn vector hat: folded red cloth, a broad shaggy cuff and a pompom.
class SantaHatPainter extends CustomPainter {
  const SantaHatPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 160, size.height / 122);
    const red = Color(0xFFDD1212);
    const darkRed = Color(0xFF910909);
    const ink = Color(0xFF161313);
    const white = Color(0xFFFFFFFF);
    const shade = Color(0xFF9AA7AF);

    void shape(Path path, Color color, {bool outline = false}) {
      canvas.drawPath(path, Paint()..color = color);
      if (outline) {
        canvas.drawPath(
            path,
            Paint()
              ..color = ink
              ..style = PaintingStyle.stroke
              ..strokeWidth = .85
              ..strokeJoin = StrokeJoin.round
              ..strokeCap = StrokeCap.round);
      }
    }

    final cloth = Path()
      ..moveTo(21, 100)
      ..cubicTo(27, 86, 17, 73, 22, 57)
      ..cubicTo(22, 42, 31, 31, 44, 27)
      ..cubicTo(51, 17, 63, 12, 79, 12)
      ..cubicTo(86, 6, 96, 1, 102, 3)
      ..cubicTo(125, 8, 142, 23, 148, 42)
      ..lineTo(146, 76)
      ..lineTo(48, 88)
      ..lineTo(34, 106)
      ..close();
    shape(cloth, red, outline: true);
    canvas.save();
    canvas.clipPath(cloth);
    // Layered folds descend toward the hanging tip on the left.
    shape(
        Path()
          ..moveTo(79, 12)
          ..cubicTo(49, 27, 49, 47, 37, 64)
          ..cubicTo(26, 79, 38, 91, 27, 103)
          ..lineTo(17, 103)
          ..cubicTo(24, 84, 14, 64, 23, 48)
          ..cubicTo(30, 33, 37, 29, 44, 27)
          ..cubicTo(56, 18, 66, 15, 79, 12)
          ..close(),
        darkRed);
    shape(
        Path()
          ..moveTo(27, 62)
          ..cubicTo(26, 46, 37, 31, 45, 30)
          ..cubicTo(39, 40, 32, 50, 27, 62)
          ..close(),
        red);
    shape(
        Path()
          ..moveTo(43, 81)
          ..cubicTo(54, 60, 76, 39, 94, 25)
          ..cubicTo(80, 47, 64, 61, 53, 79)
          ..lineTo(47, 97)
          ..lineTo(34, 105)
          ..close(),
        darkRed);
    shape(
        Path()
          ..moveTo(58, 36)
          ..cubicTo(63, 24, 73, 19, 80, 18)
          ..cubicTo(76, 26, 65, 32, 58, 36)
          ..close(),
        darkRed);
    shape(
        Path()
          ..moveTo(84, 14)
          ..quadraticBezierTo(95, 6, 104, 6)
          ..quadraticBezierTo(96, 14, 84, 14)
          ..close(),
        const Color(0xFFF02A24));
    final crease = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = .8
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
        Path()
          ..moveTo(43, 33)
          ..cubicTo(36, 50, 29, 72, 30, 91),
        crease);
    canvas.drawPath(
        Path()
          ..moveTo(92, 27)
          ..cubicTo(81, 42, 59, 58, 49, 74),
        crease);
    canvas.restore();

    // Cuff silhouette: uneven tufts instead of a smooth strip or circles.
    final cuff = Path()
      ..moveTo(39, 94)
      ..cubicTo(32, 84, 38, 64, 46, 55)
      ..cubicTo(59, 44, 79, 37, 96, 30)
      ..lineTo(98, 26)
      ..lineTo(101, 30)
      ..lineTo(105, 25)
      ..lineTo(107, 29)
      ..lineTo(111, 26)
      ..lineTo(113, 31)
      ..lineTo(117, 27)
      ..lineTo(120, 32)
      ..lineTo(123, 30)
      ..lineTo(128, 34)
      ..lineTo(132, 32)
      ..lineTo(136, 37)
      ..lineTo(140, 36)
      ..lineTo(142, 41)
      ..lineTo(147, 40)
      ..lineTo(146, 45)
      ..lineTo(152, 48)
      ..lineTo(149, 50)
      ..lineTo(154, 54)
      ..lineTo(151, 56)
      ..lineTo(157, 62)
      ..lineTo(154, 63)
      ..lineTo(158, 69)
      ..lineTo(154, 70)
      ..lineTo(158, 76)
      ..lineTo(154, 77)
      ..lineTo(157, 85)
      ..lineTo(152, 82)
      ..lineTo(152, 91)
      ..lineTo(147, 87)
      ..lineTo(144, 92)
      ..lineTo(140, 87)
      ..lineTo(136, 91)
      ..lineTo(132, 87)
      ..lineTo(127, 90)
      ..lineTo(125, 85)
      ..lineTo(120, 89)
      ..lineTo(117, 85)
      ..lineTo(112, 88)
      ..lineTo(109, 84)
      ..lineTo(104, 88)
      ..lineTo(101, 84)
      ..lineTo(96, 88)
      ..lineTo(93, 85)
      ..lineTo(88, 90)
      ..lineTo(85, 87)
      ..lineTo(79, 92)
      ..lineTo(77, 89)
      ..lineTo(71, 94)
      ..lineTo(68, 92)
      ..lineTo(62, 98)
      ..lineTo(59, 95)
      ..lineTo(53, 102)
      ..lineTo(50, 98)
      ..lineTo(45, 105)
      ..lineTo(43, 99)
      ..lineTo(38, 101)
      ..close();
    shape(cuff, shade, outline: true);
    canvas.save();
    canvas.clipPath(cuff);
    shape(
        Path()
          ..moveTo(35, 51)
          ..lineTo(112, 20)
          ..lineTo(151, 34)
          ..cubicTo(160, 51, 151, 68, 135, 71)
          ..cubicTo(98, 64, 76, 79, 47, 96)
          ..cubicTo(34, 101, 30, 86, 35, 51)
          ..close(),
        white);
    shape(
        Path()
          ..moveTo(46, 57)
          ..cubicTo(42, 66, 37, 80, 41, 90)
          ..cubicTo(33, 84, 37, 67, 46, 57)
          ..close(),
        shade);
    shape(
        Path()
          ..moveTo(64, 87)
          ..cubicTo(91, 65, 112, 70, 134, 67)
          ..cubicTo(147, 65, 150, 59, 150, 53)
          ..cubicTo(149, 70, 135, 74, 115, 73)
          ..cubicTo(94, 72, 80, 79, 64, 87)
          ..close(),
        shade);
    canvas.restore();

    final pom = Path()
      ..moveTo(14, 96)
      ..lineTo(18, 93)
      ..lineTo(20, 96)
      ..lineTo(25, 94)
      ..lineTo(26, 98)
      ..lineTo(31, 97)
      ..lineTo(31, 101)
      ..lineTo(35, 103)
      ..lineTo(32, 106)
      ..lineTo(35, 109)
      ..lineTo(32, 112)
      ..lineTo(33, 116)
      ..lineTo(29, 116)
      ..lineTo(28, 120)
      ..lineTo(23, 119)
      ..lineTo(20, 122)
      ..lineTo(17, 119)
      ..lineTo(12, 121)
      ..lineTo(11, 117)
      ..lineTo(6, 117)
      ..lineTo(7, 113)
      ..lineTo(3, 110)
      ..lineTo(6, 107)
      ..lineTo(4, 104)
      ..lineTo(8, 102)
      ..lineTo(8, 98)
      ..lineTo(13, 98)
      ..close();
    shape(pom, shade, outline: true);
    canvas.save();
    canvas.clipPath(pom);
    shape(
        Path()
          ..moveTo(1, 94)
          ..lineTo(29, 92)
          ..cubicTo(40, 103, 22, 116, 13, 115)
          ..cubicTo(4, 114, 2, 103, 1, 94)
          ..close(),
        white);
    shape(
        Path()
          ..moveTo(8, 104)
          ..cubicTo(10, 115, 23, 113, 28, 108)
          ..cubicTo(23, 117, 11, 119, 8, 104)
          ..close(),
        shade);
    canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant SantaHatPainter oldDelegate) => false;
}
