import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import 'return_home_obstacle.dart';
import 'return_home_skills.dart';

/// Boss summons share hazard targeting, freezing and damage handling.
class DragonBrood extends ReturnHomeObstacle {
  DragonBrood(
      {required super.road,
      required super.position,
      required this.ranged,
      required this.left,
      required this.right,
      required this.onShoot})
      : super(kind: ReturnHomeObstacleKind.crab) {
    priority = 6;
  }

  final bool ranged;
  final double left, right;
  final void Function(Vector2 from, Vector2 target) onShoot;
  static const hatchTime = 4.0;
  double age = 0;
  double _clock = 0;
  double _shot = 1.8;
  double _stagger = 0;
  final Vector2 _target = Vector2.zero();
  bool dead = false;
  bool get hatched => age >= hatchTime;
  bool get charging => hatched && ranged && _shot <= .65;

  @override
  Rect get solidRect => Rect.fromCenter(
      center: Offset(position.x, position.y), width: 36, height: 30);

  @override
  bool hits(Rect catBox) => !dead && !harmless && solidRect.overlaps(catBox);

  void dismiss() {
    dead = true;
    harmless = true;
    removeFromParent();
  }

  @override
  void scare(Vector2 from, double push) {
    if (!hatched || dead) return;
    final away = position - from;
    if (away.length2 > .01) position += away.normalized() * min(35, push * .08);
    _stagger = .7;
    _shot = max(_shot, 1.2);
  }

  @override
  void updatePhysics(double dt, Offset cat) {
    if (dead || frozen > 0 || dt <= 0) return;
    _clock += dt;
    _target.setValues(cat.dx, cat.dy);
    final wasHatched = hatched;
    age += dt;
    if (!wasHatched && hatched) {
      damage = 0;
      parent?.add(ReturnHomeBurst(
          position: position.clone(),
          color: const Color(0xFFFFBC76),
          fiery: true));
    }
    if (!hatched) return;
    _stagger = max(0, _stagger - dt);
    if (_stagger > 0 || age < hatchTime + .6) return;
    final toward = _target - position;
    final distance = toward.length;
    if (ranged) {
      _shot -= dt;
      if (_shot <= 0) {
        onShoot(position + Vector2(-12, -13), _target.clone());
        _shot = 2.5;
      }
      if (!charging && distance > 190 && distance > 1) {
        position += toward / distance * 38 * dt;
      }
    } else if (distance > 6) {
      position += toward / distance * 78 * dt;
    }
    position.x = position.x.clamp(left + 24, right - 24);
    final half = max(10.0, road.halfWidth(position.x) - 22);
    position.y = position.y.clamp(
        road.centerY(position.x) - half, road.centerY(position.x) + half);
  }

  @override
  void render(Canvas canvas) {
    if (dead) return;
    canvas.save();
    canvas.translate(size.x / 2, size.y / 2);
    final edge = Paint()
      ..color = const Color(0xFF47213E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeJoin = StrokeJoin.round;
    void shape(Path path, Color color) {
      canvas.drawPath(
          path,
          Paint()
            ..color = frozen > 0
                ? Color.lerp(color, const Color(0xFFBCEBFF), .6)!
                : color);
      canvas.drawPath(path, edge);
    }

    canvas.drawOval(const Rect.fromLTWH(-22, -4, 44, 13),
        Paint()..color = const Color(0x44352228));
    if (!hatched) {
      final shake = age > 3 ? sin(_clock * 35) * 1.3 : 0.0;
      canvas.translate(shake, 0);
      final egg = Path()
        ..moveTo(0, -38)
        ..cubicTo(-15, -35, -24, -7, -15, 1)
        ..quadraticBezierTo(0, 12, 15, 1)
        ..cubicTo(24, -7, 15, -35, 0, -38)
        ..close();
      shape(egg, ranged ? const Color(0xFF984C83) : const Color(0xFFB95643));
      canvas.save();
      canvas.clipPath(egg);
      canvas.drawPath(
          Path()
            ..moveTo(-7, -33)
            ..lineTo(-2, -19)
            ..lineTo(-9, -11)
            ..lineTo(1, -2)
            ..lineTo(-3, 8),
          Paint()
            ..color = const Color(0xFFFFBF68)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5);
      if (age > 2) {
        canvas.drawPath(
            Path()
              ..moveTo(5, -32)
              ..lineTo(1, -23)
              ..lineTo(10, -15)
              ..lineTo(4, -6),
            edge..strokeWidth = 1.5);
      }
      canvas.restore();
      canvas.drawArc(
          const Rect.fromLTWH(-24, -12, 48, 22),
          -pi / 2,
          2 * pi * (1 - age / hatchTime).clamp(0.0, 1.0),
          false,
          Paint()
            ..color = const Color(0xFFFFD681)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
    } else {
      final flip = _target.x > position.x;
      if (flip) canvas.scale(-1, 1);
      final flap = sin(_clock * 9) * 6;
      shape(
          Path()
            ..addPolygon([
              const Offset(4, -15),
              Offset(21, -34 + flap),
              Offset(30, -17 + flap),
              const Offset(17, -9)
            ], true),
          const Color(0xFF973E68));
      shape(
          Path()
            ..moveTo(11, -3)
            ..quadraticBezierTo(30, 5, 34, -10)
            ..quadraticBezierTo(35, 12, 12, 8)
            ..close(),
          const Color(0xFF8A3858));
      shape(Path()..addOval(const Rect.fromLTWH(-9, -22, 30, 31)),
          const Color(0xFFB95163));
      shape(Path()..addOval(const Rect.fromLTWH(-8, -14, 16, 22)),
          const Color(0xFFFFD78F));
      shape(
          Path()
            ..addPolygon(const [
              Offset(-7, -15),
              Offset(-21, -14),
              Offset(-27, -22),
              Offset(-19, -31),
              Offset(-5, -30),
              Offset(1, -20)
            ], true),
          const Color(0xFFC45B6E));
      shape(
          Path()
            ..addPolygon(
                const [Offset(-16, -30), Offset(-7, -41), Offset(-8, -28)],
                true),
          const Color(0xFFFFD4A0));
      canvas.drawCircle(
          const Offset(-17, -24), 3, Paint()..color = const Color(0xFFFFE49C));
      canvas.drawCircle(const Offset(-18, -24), 1.4,
          Paint()..color = const Color(0xFF30213B));
      for (final x in [-4.0, 12.0]) {
        shape(
            Path()
              ..addPolygon([
                Offset(x, -2),
                Offset(x + 6, -2),
                Offset(x + 8, 10),
                Offset(x - 6, 10)
              ], true),
            const Color(0xFF63334F));
      }
      if (charging) {
        canvas.drawCircle(
            const Offset(-26, -19),
            3 + sin(_clock * 16).abs() * 3,
            Paint()..color = const Color(0xFFFFAC43));
      }
    }
    // Two visible health pips; both eggs and hatchlings take two basic hits.
    for (var i = 0; i < 2; i++) {
      canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(-14 + i * 16, -49, 12, 4),
              const Radius.circular(2)),
          Paint()
            ..color = i < 2 - damage
                ? const Color(0xFFEF927C)
                : const Color(0xFF604655));
    }
    canvas.restore();
  }
}
