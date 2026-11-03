import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/painting.dart';

import 'cats/cat_animations.dart';
import 'cats/cat_state.dart';
import 'constants.dart';

enum ReturnHomeObstacleKind { spikes, rock, log }

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
  bool started = false;
  bool skillReady = true;
  double skillCooldown = 0;
  String selectedCat = 'orange';
  double _hitCooldown = 0;
  final _contacts = <ReturnHomeObstacle>{};
  double get worldWidth => size.x * 3;

  Future<void> chooseCat(String type) async {
    if (started) return;
    selectedCat = type;
    await _cat.changeType(type);
    started = true;
    overlays.remove('chooseCat');
    if (type == 'black') overlays.add('skill');
  }

  void activateSkill() {
    if (!started || !skillReady || selectedCat != 'black' || finished) return;
    skillReady = false;
    skillCooldown = 4;
    _cat.activateVanish();
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    final world = World();
    add(world);
    camera = CameraComponent(world: world);
    add(camera);
    // Keep the whole landscape viewport visible; only its X center follows
    // the cat along the longer world.
    camera.viewfinder.position = Vector2(size.x / 2, size.y / 2);
    world.add(ReturnHomeBackground());
    _cat = ReturnHomeCat();
    world.add(_cat);
    _addObstacles();
    joystick = ReturnHomeJoystick(position: Vector2(92, size.y - 92));
    camera.viewport.add(joystick);
  }

  void _addObstacles() {
    var x = 190.0;
    for (var i = 0; i < 20; i++) {
      x += 120 + _random.nextDouble() * 90;
      final y = size.y * (.32 + _random.nextDouble() * .36);
      final kind = i % 3 == 2
          ? ReturnHomeObstacleKind.log
          : i.isEven
              ? ReturnHomeObstacleKind.spikes
              : ReturnHomeObstacleKind.rock;
      final obstacle = ReturnHomeObstacle(kind: kind, position: Vector2(x, y));
      obstacle.vertical = _random.nextBool();
      if (kind == ReturnHomeObstacleKind.rock) {
        obstacle.velocity = Vector2(-105 - _random.nextDouble() * 45,
            (_random.nextBool() ? 1 : -1) * (18 + _random.nextDouble() * 28));
        obstacle.angularVelocity = (_random.nextBool() ? 1 : -1) * 3.5;
      }
      _obstacles.add(obstacle);
      camera.world!.add(obstacle);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!started) return;
    // Flame can deliver the first update before the viewport and child assets
    // have finished mounting. Do not resolve collisions or the finish line yet.
    if (size.x < 200 || size.y < 150 || !_cat.isLoaded || !joystick.isMounted) {
      return;
    }
    if (finished) {
      return;
    }
    if (skillCooldown > 0) {
      skillCooldown = max(0, skillCooldown - dt);
      if (skillCooldown == 0) skillReady = true;
    }
    _hitCooldown = max(0, _hitCooldown - dt);
    final cameraX =
        _cat.position.x.clamp(size.x / 2, worldWidth - size.x / 2).toDouble();
    final leftEdge = cameraX - size.x / 2 - 100;
    for (final obstacle in List<ReturnHomeObstacle>.of(_obstacles)) {
      obstacle.updatePhysics(dt, size);
      if (obstacle.kind == ReturnHomeObstacleKind.rock &&
          obstacle.position.x < leftEdge) {
        _contacts.remove(obstacle);
        _obstacles.remove(obstacle);
        obstacle.removeFromParent();
        continue;
      }
      final touching = obstacle.hits(_cat.position, _cat.size);
      if (touching && obstacle.kind == ReturnHomeObstacleKind.log) {
        _cat.position.x -= _cat.velocity.x * dt;
        _cat.velocity.x = 0;
        _contacts.remove(obstacle);
        continue;
      }
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
    camera.viewfinder.position = Vector2(cameraX.toDouble(), size.y / 2);
    progress =
        ((_cat.position.x - 72) / max(1.0, worldWidth - 160)).clamp(0.0, 1.0);
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
    size = Vector2(game.worldWidth, game.size.y);
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
    canvas.drawPath(road, Paint()..color = const Color(0xFFD5B47D));
    final roadLight = Path()
      ..moveTo(0, h * .29)
      ..lineTo(w, h * .36)
      ..lineTo(w, h * .62)
      ..lineTo(0, h * .71)
      ..close();
    canvas.drawPath(roadLight, Paint()..color = const Color(0xFFE8D09E));
    final roadMark = Paint()
      ..color = const Color(0x66FFF0C2)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 18; i++) {
      final x = i * w / 17;
      final y = h * (.50 + sin(i * .75) * .045);
      canvas.drawLine(Offset(x, y), Offset(x + 26, y + 2), roadMark);
    }
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
    _roadsideMarkers(canvas, w, h);
    final houseShadow = Paint()..color = const Color(0x33604432);
    canvas.drawOval(Rect.fromLTWH(w - 178, h * .53, 150, 22), houseShadow);
    final house = Path()
      ..moveTo(w - 168, h * .30)
      ..lineTo(w - 102, h * .14)
      ..lineTo(w - 36, h * .30)
      ..close();
    canvas.drawPath(house, Paint()..color = const Color(0xFFB96D4B));
    canvas.drawPath(
        Path()
          ..moveTo(w - 168, h * .30)
          ..lineTo(w - 102, h * .14)
          ..lineTo(w - 82, h * .22)
          ..lineTo(w - 140, h * .30)
          ..close(),
        Paint()..color = const Color(0xFFD98B59));
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(w - 155, h * .30, 106, 62), const Radius.circular(5)),
        Paint()..color = const Color(0xFFFFE5A6));
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(w - 112, h * .35, 28, 42), const Radius.circular(10)),
        Paint()..color = const Color(0xFF9B6248));
    canvas.drawCircle(
        Offset(w - 90, h * .43), 3, Paint()..color = const Color(0xFFFFD05A));
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(w - 151, h * .34, 22, 18), const Radius.circular(2)),
        Paint()..color = const Color(0xFF76B8B0));
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(w - 77, h * .34, 22, 18), const Radius.circular(2)),
        Paint()..color = const Color(0xFF76B8B0));
    final welcome = Paint()
      ..color = const Color(0xFFF4D78F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawLine(Offset(w - 144, h * .29), Offset(w - 60, h * .29), welcome);
    canvas.drawLine(
        Offset(w - 137, h * .29), Offset(w - 137, h * .36), welcome);
    canvas.drawLine(Offset(w - 67, h * .29), Offset(w - 67, h * .36), welcome);
    _flowers(canvas, w, h);
  }

  void _roadsideMarkers(Canvas canvas, double w, double h) {
    for (var i = 0; i < 7; i++) {
      final x = w * (.08 + i * .14);
      final y = h * (.27 + sin(i * 1.7) * .045);
      final post = Paint()..color = const Color(0xFF8E6849);
      canvas.drawLine(Offset(x, y), Offset(x, y - 24), post..strokeWidth = 4);
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(x - 10, y - 33, 21, 12), const Radius.circular(3)),
          Paint()..color = const Color(0xFFF5D27F));
      canvas.drawLine(
          Offset(x - 5, y - 27),
          Offset(x + 6, y - 27),
          Paint()
            ..color = const Color(0xFFB5744B)
            ..strokeWidth = 2);
    }
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
  double _vanishTimer = 0;
  bool _vanished = false;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    animations = await loadCatAnimations(game.images, game.selectedCat);
    position = Vector2(72, game.size.y / 2 - size.y / 2);
  }

  Future<void> changeType(String type) async {
    animations = await loadCatAnimations(game.images, type);
    current = CatState.idle;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (game.finished) return;
    final input = game.joystick.relativeDelta;
    final target = Vector2(input.x * 125, input.y * 125);
    velocity += (target - velocity) * min(1, dt * 6);
    if (_bumpTimer > 0) _bumpTimer -= dt;
    if (_vanishTimer > 0) {
      _vanishTimer -= dt;
      if (!_vanished && _vanishTimer < .35) {
        _vanished = true;
        position.x = (position.x + (velocity.x >= 0 ? 120 : -120))
            .clamp(72.0, game.worldWidth - 104);
      }
      if (_vanishTimer > 0) return;
    }
    position += velocity * dt;
    position.x = position.x.clamp(72.0, game.worldWidth - 104);
    position.y =
        position.y.clamp(game.size.y * .24, game.size.y * .76 - size.y);
    current = _bumpTimer > 0
        ? CatState.panic
        : velocity.length > 8
            ? CatState.walk
            : CatState.idle;
  }

  void activateVanish() {
    if (game.selectedCat != 'black' || _vanishTimer > 0) return;
    _vanishTimer = .75;
    _vanished = false;
    current = CatState.vanish;
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
  double angularVelocity = 0;
  bool vertical = false;

  void updatePhysics(double dt, Vector2 viewport) {
    if (kind != ReturnHomeObstacleKind.rock) return;
    position += velocity * dt;
    angle += angularVelocity * dt;
    final top = viewport.y * .27;
    final bottom = viewport.y * .73;
    if (position.y < top) {
      position.y = top;
      velocity.y = velocity.y.abs();
    } else if (position.y > bottom) {
      position.y = bottom;
      velocity.y = -velocity.y.abs();
    }
  }

  bool hits(Vector2 catPosition, Vector2 catSize) {
    // Use the visible body/feet area, not the transparent padding in the
    // sprite, so a near miss remains a near miss.
    // Sprite is 80x80 and its opaque body spans x[15,65] y[28,66]; the box is
    // kept symmetric around x=40 because the sprite mirrors when walking left.
    final cat = Rect.fromLTWH(catPosition.x + 20, catPosition.y + 40, 40, 24);
    if (kind == ReturnHomeObstacleKind.spikes) {
      final base = Rect.fromCenter(
          center: Offset(position.x + 1, position.y + 1),
          width: 34,
          height: 20);
      return cat.overlaps(base);
    }
    if (kind == ReturnHomeObstacleKind.log) {
      // Trunk plus its rounded end cap, in whichever orientation it is drawn.
      return cat.overlaps(vertical
          ? Rect.fromCenter(
              center: Offset(position.x - 1, position.y - 3),
              width: 22,
              height: 66)
          : Rect.fromCenter(
              center: Offset(position.x - 3, position.y + 1),
              width: 66,
              height: 22));
    }
    final closestX =
        cat.center.dx.clamp(position.x - 18, position.x + 18).toDouble();
    final closestY =
        cat.center.dy.clamp(position.y - 18, position.y + 18).toDouble();
    return (Offset(closestX, closestY) - Offset(position.x, position.y))
            .distance <
        18;
  }

  @override
  void render(Canvas canvas) {
    // The shapes below are drawn around their own center, but Flame puts the
    // canvas origin at the top-left of the bounding box when anchor is center.
    canvas.save();
    canvas.translate(size.x / 2, size.y / 2);
    if (kind == ReturnHomeObstacleKind.spikes) {
      canvas.drawOval(const Rect.fromLTWH(-17, 8, 34, 8),
          Paint()..color = const Color(0x3D4B392C));
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              const Rect.fromLTWH(-17, 3, 34, 10), const Radius.circular(5)),
          Paint()..color = const Color(0xFFD58A3E));
      final spikes = Path()
        ..moveTo(-14, 5)
        ..lineTo(-8, -14)
        ..lineTo(-2, 5)
        ..lineTo(4, -16)
        ..lineTo(10, 5)
        ..lineTo(15, -12)
        ..lineTo(19, 5)
        ..close();
      canvas.drawPath(spikes, Paint()..color = const Color(0xFF6C6870));
      final edge = Paint()
        ..color = const Color(0xFFE6E0E4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(const Offset(-8, -13), const Offset(-4, 3), edge);
      canvas.drawLine(const Offset(4, -15), const Offset(8, 3), edge);
      canvas.drawLine(const Offset(15, -11), const Offset(17, 3), edge);
      canvas.drawLine(
          const Offset(-14, 8),
          const Offset(14, 8),
          Paint()
            ..color = const Color(0xFFE9A65A)
            ..strokeWidth = 2);
    } else if (kind == ReturnHomeObstacleKind.rock) {
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
    } else {
      canvas.save();
      if (vertical) canvas.rotate(pi / 2);
      canvas.drawOval(const Rect.fromLTWH(-34, 11, 68, 12),
          Paint()..color = const Color(0x3D4B392C));
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              const Rect.fromLTWH(-31, -10, 62, 22), const Radius.circular(8)),
          Paint()..color = const Color(0xFF8B5635));
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              const Rect.fromLTWH(-27, -7, 54, 7), const Radius.circular(4)),
          Paint()..color = const Color(0xFFB87543));
      canvas.drawCircle(
          const Offset(-27, 1), 11, Paint()..color = const Color(0xFFC98A54));
      final rings = Paint()
        ..color = const Color(0xFF8B5635)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawOval(const Rect.fromLTWH(-34, -7, 14, 16), rings);
      canvas.drawOval(const Rect.fromLTWH(-31, -4, 8, 10), rings);
      final bark = Paint()
        ..color = const Color(0xFF653D2A)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(const Offset(-15, -5), const Offset(-8, 7), bark);
      canvas.drawLine(const Offset(2, -6), const Offset(8, 6), bark);
      canvas.drawLine(const Offset(17, -5), const Offset(22, 5), bark);
      canvas.restore();
    }
    canvas.restore();
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
