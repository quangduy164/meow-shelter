import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/painting.dart';

import 'cats/cat_animations.dart';
import 'cats/cat_state.dart';
import 'constants.dart';

enum ReturnHomeObstacleKind { spikes, rock }

class ReturnHomeGame extends FlameGame {
  ReturnHomeGame({required this.onExit});

  final void Function() onExit;
  late ReturnHomeJoystick joystick;
  late ReturnHomeCat _cat;
  final _obstacles = <ReturnHomeObstacle>[];
  final _random = Random(42);
  double progress = 0;
  int lives = 3;
  bool finished = false;
  double _hitCooldown = 0;
  final _contacts = <ReturnHomeObstacle>{};

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(ReturnHomeBackground());
    _cat = ReturnHomeCat();
    add(_cat);
    _addObstacles();
    joystick = ReturnHomeJoystick(position: Vector2(92, size.y - 92));
    add(joystick);
  }

  void _addObstacles() {
    for (var i = 0; i < 9; i++) {
      final x = (160 + i * max(95, size.x * .11)).toDouble();
      final y = size.y * (.32 + _random.nextDouble() * .36);
      final kind = i.isEven
          ? ReturnHomeObstacleKind.spikes
          : ReturnHomeObstacleKind.rock;
      final obstacle = ReturnHomeObstacle(kind: kind, position: Vector2(x, y));
      _obstacles.add(obstacle);
      add(obstacle);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    // Flame can deliver the first update before the viewport and child assets
    // have finished mounting. Do not resolve collisions or the finish line yet.
    if (size.x < 200 || size.y < 150 || !_cat.isLoaded || !joystick.isMounted) {
      return;
    }
    if (finished) {
      return;
    }
    _hitCooldown = max(0, _hitCooldown - dt);
    for (final obstacle in _obstacles) {
      obstacle.updatePhysics(dt, size);
      final touching = obstacle.hits(_cat.position, _cat.size);
      if (!touching) {
        _contacts.remove(obstacle);
      } else if (_hitCooldown <= 0 && !_contacts.contains(obstacle)) {
        _hitCooldown = .9;
        _contacts.add(obstacle);
        lives -= 1;
        _cat.bumpAwayFrom(obstacle.position);
        if (lives <= 0) {
          finished = true;
        }
      }
    }
    progress =
        ((_cat.position.x - 72) / max(1.0, size.x - 160)).clamp(0.0, 1.0);
    if (progress >= 1 && !finished) {
      finished = true;
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (!isLoaded) return;
    final hud = TextPainter(
      text: TextSpan(
        text: 'VỀ NHÀ   ${(progress * 100).round()}%   ♥ $lives',
        style: const TextStyle(
            color: Color(0xFF3B2415),
            fontSize: 17,
            fontWeight: FontWeight.w900),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    hud.paint(canvas, const Offset(18, 16));
    if (finished) {
      final title = lives > 0 ? 'ĐÃ VỀ ĐẾN NHÀ!' : 'MÈO BỊ MỆT RỒI';
      final painter = TextPainter(
        text: TextSpan(
            text: title,
            style: const TextStyle(
                color: Color(0xFF573215),
                fontSize: 28,
                fontWeight: FontWeight.w900)),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: size.x - 40);
      painter.paint(canvas, Offset((size.x - painter.width) / 2, size.y * .18));
    }
  }
}

class ReturnHomeBackground extends PositionComponent
    with HasGameReference<ReturnHomeGame> {
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = game.size;
  }

  @override
  void render(Canvas canvas) {
    final w = size.x;
    final h = size.y;
    canvas.drawRect(
        Rect.fromLTWH(0, 0, w, h),
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF75C8DF), Color(0xFFD8E9B0), Color(0xFF80B866)],
          ).createShader(Rect.fromLTWH(0, 0, w, h)));
    _clouds(canvas, w, h);
    _treesAndFence(canvas, w, h);
    final road = Path()
      ..moveTo(0, h * .22)
      ..lineTo(w, h * .31)
      ..lineTo(w, h * .69)
      ..lineTo(0, h * .78)
      ..close();
    canvas.drawPath(road, Paint()..color = const Color(0xFFE7D2A8));
    for (var i = 0; i < 12; i++) {
      final x = w * (.08 + i * .082);
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset(x, h * (.48 + sin(i * 2.1) * .09)),
              width: 18 + (i % 3) * 7,
              height: 6),
          Paint()..color = const Color(0x22936E49));
    }
    final edge = Paint()
      ..color = const Color(0x667C9A63)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawLine(Offset(0, h * .31), Offset(w, h * .31), edge);
    canvas.drawLine(Offset(0, h * .69), Offset(w, h * .69), edge);
    final house = Path()
      ..moveTo(w - 130, h * .30)
      ..lineTo(w - 88, h * .20)
      ..lineTo(w - 46, h * .30)
      ..close();
    canvas.drawPath(house, Paint()..color = const Color(0xFFC47B4D));
    canvas.drawRect(Rect.fromLTWH(w - 122, h * .30, 68, 42),
        Paint()..color = const Color(0xFFFFE5A6));
    canvas.drawRect(Rect.fromLTWH(w - 102, h * .34, 26, 42),
        Paint()..color = const Color(0xFF9B6248));
    canvas.drawCircle(
        Offset(w - 82, h * .55), 4, Paint()..color = const Color(0xFFFFD05A));
    _flowers(canvas, w, h);
  }

  void _clouds(Canvas canvas, double w, double h) {
    final paint = Paint()..color = const Color(0xBFFFFFFF);
    for (final center in [Offset(w * .18, h * .10), Offset(w * .60, h * .12)]) {
      canvas.drawOval(
          Rect.fromCenter(center: center, width: 118, height: 30), paint);
      canvas.drawCircle(center + const Offset(-35, 0), 20, paint);
      canvas.drawCircle(center + const Offset(4, -10), 27, paint);
      canvas.drawCircle(center + const Offset(39, 2), 17, paint);
    }
  }

  void _treesAndFence(Canvas canvas, double w, double h) {
    final trunk = Paint()..color = const Color(0xFF8C6245);
    final leaves = Paint()..color = const Color(0xFF4E9663);
    for (final x in [w * .04, w * .96]) {
      canvas.drawRect(Rect.fromLTWH(x - 10, h * .06, 20, h * .30), trunk);
      for (var i = 0; i < 5; i++) {
        canvas.drawCircle(
            Offset(x + (i - 2) * 24, h * .08 + (i % 2) * 22), 36, leaves);
      }
    }
    final fence = Paint()
      ..color = const Color(0xFFE8D9B5)
      ..strokeWidth = 7;
    canvas.drawLine(Offset(0, h * .18), Offset(w, h * .18), fence);
    canvas.drawLine(Offset(0, h * .23), Offset(w, h * .23), fence);
    for (var x = 18.0; x < w; x += 42) {
      canvas.drawLine(Offset(x, h * .13), Offset(x, h * .28), fence);
    }
  }

  void _flowers(Canvas canvas, double w, double h) {
    final stem = Paint()
      ..color = const Color(0xFF4D8B4B)
      ..strokeWidth = 2;
    for (var i = 0; i < 14; i++) {
      final x = w * (.03 + (i * .071) % .94);
      final y = h * (.82 + (i % 3) * .045);
      canvas.drawLine(Offset(x, y + 12), Offset(x, y), stem);
      canvas.drawCircle(
          Offset(x, y), 4, Paint()..color = const Color(0xFFFFC1C7));
      canvas.drawCircle(
          Offset(x + 4, y + 2), 3, Paint()..color = const Color(0xFFFFE49A));
    }
  }
}

class ReturnHomeCat extends SpriteAnimationGroupComponent<CatState>
    with HasGameReference<ReturnHomeGame> {
  ReturnHomeCat()
      : super(
            position: Vector2(0, 0),
            size: Vector2(catWidth, catHeight),
            current: CatState.walk,
            priority: 5);

  Vector2 velocity = Vector2.zero();
  double _bumpTimer = 0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    animations = await loadCatAnimations(game.images, 'orange');
    position = Vector2(72, game.size.y / 2 - size.y / 2);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (game.finished) return;
    final input = game.joystick.relativeDelta;
    final target = Vector2(input.x * 125, input.y * 125);
    velocity += (target - velocity) * min(1, dt * 6);
    if (_bumpTimer > 0) _bumpTimer -= dt;
    position += velocity * dt;
    position.x = position.x.clamp(72.0, game.size.x - 104);
    position.y =
        position.y.clamp(game.size.y * .24, game.size.y * .76 - size.y);
    current = _bumpTimer > 0 ? CatState.panic : CatState.walk;
  }

  @override
  void render(Canvas canvas) {
    canvas.save();
    if (velocity.x < -2) {
      // Flip around the sprite's own right edge; position stays unchanged.
      canvas.translate(size.x, 0);
      canvas.scale(-1, 1);
    }
    super.render(canvas);
    canvas.restore();
  }

  void bumpAwayFrom(Vector2 obstacle) {
    _bumpTimer = .35;
    final away = (position + size / 2) - obstacle;
    if (away.length > 0) velocity += away.normalized() * 150;
  }
}

class ReturnHomeObstacle extends PositionComponent {
  ReturnHomeObstacle({required this.kind, required Vector2 position})
      : super(position: position, size: Vector2.all(54), anchor: Anchor.center);

  final ReturnHomeObstacleKind kind;
  Vector2 velocity = Vector2.zero();
  double _phase = 0;

  void updatePhysics(double dt, Vector2 viewport) {
    if (kind != ReturnHomeObstacleKind.rock) return;
    _phase += dt;
    velocity.y = sin(_phase * 1.6) * 28;
    position += velocity * dt;
    if (position.y < viewport.y * .27 || position.y > viewport.y * .73) {
      velocity.y *= -1;
    }
  }

  bool hits(Vector2 catPosition, Vector2 catSize) {
    // Use the visible body/feet area, not the transparent padding in the
    // sprite, so a near miss remains a near miss.
    // Sprite is 80x80; only this 18x20 box represents the visible body.
    final cat = Rect.fromLTWH(catPosition.x + 31, catPosition.y + 36, 18, 20);
    if (kind == ReturnHomeObstacleKind.spikes) {
      final base = Rect.fromCenter(
          center: Offset(position.x, position.y + 8), width: 28, height: 6);
      return cat.overlaps(base);
    }
    final closestX =
        cat.center.dx.clamp(position.x - 10, position.x + 10).toDouble();
    final closestY =
        cat.center.dy.clamp(position.y - 10, position.y + 10).toDouble();
    return (Offset(closestX, closestY) - Offset(position.x, position.y))
            .distance <
        10;
  }

  @override
  void render(Canvas canvas) {
    if (kind == ReturnHomeObstacleKind.spikes) {
      canvas.drawOval(const Rect.fromLTWH(-31, 12, 62, 12),
          Paint()..color = const Color(0x3D4B392C));
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              const Rect.fromLTWH(-31, 5, 62, 15), const Radius.circular(7)),
          Paint()..color = const Color(0xFFD58A3E));
      final spikes = Path()
        ..moveTo(-27, 9)
        ..lineTo(-17, -22)
        ..lineTo(-7, 9)
        ..lineTo(2, -25)
        ..lineTo(12, 9)
        ..lineTo(21, -19)
        ..lineTo(29, 9)
        ..close();
      canvas.drawPath(spikes, Paint()..color = const Color(0xFF6C6870));
      final edge = Paint()
        ..color = const Color(0xFFE6E0E4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(const Offset(-17, -20), const Offset(-10, 5), edge);
      canvas.drawLine(const Offset(2, -23), const Offset(8, 5), edge);
      canvas.drawLine(const Offset(21, -17), const Offset(26, 5), edge);
      canvas.drawLine(
          const Offset(-25, 12),
          const Offset(25, 12),
          Paint()
            ..color = const Color(0xFFE9A65A)
            ..strokeWidth = 2);
    } else {
      canvas.drawOval(const Rect.fromLTWH(-28, 16, 56, 12),
          Paint()..color = const Color(0x3D4B392C));
      final rock = Path()
        ..moveTo(-23, 6)
        ..lineTo(-20, -11)
        ..lineTo(-7, -23)
        ..lineTo(12, -20)
        ..lineTo(24, -6)
        ..lineTo(20, 11)
        ..lineTo(5, 22)
        ..lineTo(-14, 18)
        ..close();
      canvas.drawPath(rock, Paint()..color = const Color(0xFF777D82));
      final light = Path()
        ..moveTo(-18, -8)
        ..lineTo(-7, -19)
        ..lineTo(9, -16)
        ..lineTo(1, -7)
        ..lineTo(-12, -3)
        ..close();
      canvas.drawPath(light, Paint()..color = const Color(0xFFAEB3B1));
      final vein = Paint()
        ..color = const Color(0xFF596269)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(const Offset(-3, -14), const Offset(-1, 12), vein);
      canvas.drawLine(const Offset(8, -10), const Offset(14, 5), vein);
      canvas.drawLine(const Offset(-15, 4), const Offset(-7, 13), vein);
      final motion = Paint()
        ..color = const Color(0x66929A94)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(const Offset(-33, -4), const Offset(-25, -4), motion);
      canvas.drawLine(const Offset(-35, 5), const Offset(-26, 5), motion);
    }
  }
}

class ReturnHomeJoystick extends PositionComponent with DragCallbacks {
  ReturnHomeJoystick({required Vector2 position})
      : super(
            position: position,
            size: Vector2.all(116),
            anchor: Anchor.center,
            priority: 20);

  final Vector2 delta = Vector2.zero();
  static const _radius = 34.0;

  Vector2 get relativeDelta => delta / _radius;

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    delta.setFrom(event.localPosition - size / 2);
    _clampDelta();
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    delta.add(event.localDelta);
    _clampDelta();
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    delta.setZero();
  }

  @override
  void onDragCancel(DragCancelEvent event) {
    super.onDragCancel(event);
    delta.setZero();
  }

  void _clampDelta() {
    if (delta.length > _radius) delta.scaleTo(_radius);
  }

  @override
  void render(Canvas canvas) {
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), size.x / 2,
        Paint()..color = const Color(0x887A5B42));
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), size.x / 2 - 4,
        Paint()..color = const Color(0x55FFF0CA));
    final knob = Offset(size.x / 2 + delta.x, size.y / 2 + delta.y);
    canvas.drawCircle(knob, 29, Paint()..color = const Color(0xFFD88B45));
    canvas.drawCircle(knob + const Offset(-7, -8), 6,
        Paint()..color = const Color(0x66FFF5D5));
  }
}
