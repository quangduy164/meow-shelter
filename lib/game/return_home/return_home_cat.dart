import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../cats/cat_animations.dart';
import '../cats/cat_state.dart';
import '../constants.dart';
import 'return_home_game.dart';
import 'return_home_road.dart';

/// The player: joystick steering, a knockback that costs progress, the black
/// cat's vanish, and the clamp that keeps its paws on the curving lane.
class ReturnHomeCat extends SpriteAnimationGroupComponent<CatState>
    with HasGameReference<ReturnHomeGame> {
  ReturnHomeCat()
      : super(
            position: Vector2(0, 0),
            size: Vector2(catWidth, catHeight),
            current: CatState.walk,
            priority: 5);

  /// Top speed the joystick can ask for, and how quickly the cat reaches it.
  /// Grip stays weak while knocked back, otherwise the shove is smoothed out
  /// within a frame and costs the cat nothing.
  static const double maxSpeed = 175;
  static const double grip = 11.0;
  static const double bumpedGrip = 2.2;

  /// How hard a hit shoves the cat, and how long the shove lasts.
  static const double bumpImpulse = 300;
  static const double bumpDuration = .5;

  /// Distance the vanish teleports, and how long the trick takes.
  static const double vanishLeap = 120;
  static const double vanishDuration = .75;

  /// Below this speed the cat is standing rather than walking.
  static const double idleSpeed = 8;

  /// Body/feet area inside the 80px sprite, measured from its alpha bounds:
  /// the opaque cat spans x[15,65] y[28,66], so the transparent padding must not
  /// count as a hit. The box stays symmetric around the sprite center because
  /// the sprite mirrors when the cat walks left.
  static const double hitboxLeft = 20;
  static const double hitboxTop = 40;
  static const double hitboxWidth = 40;
  static const double hitboxHeight = 24;

  /// The sprite's paws touch down this far below its top edge.
  static const double pawLine = 66;

  Vector2 velocity = Vector2.zero();
  double _bumpTimer = 0;
  double _vanishTimer = 0;
  bool _vanished = false;
  double invulnerable = 0;
  double _sprintTimer = 0;
  double _rollTimer = 0;
  bool shield = false;

  /// The lane is sampled at the sprite's center, not its top-left corner.
  double get _bodyCenterX => position.x + size.x / 2;

  /// What a hazard has to overlap to actually hit the cat.
  Rect get hitbox => Rect.fromLTWH(position.x + hitboxLeft,
      position.y + hitboxTop, hitboxWidth, hitboxHeight);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    animations = await loadCatAnimations(game.images, game.selectedCat);
    position = Vector2(
        ReturnHomeRoad.startX, game.road.centerY(_bodyCenterX) - size.y / 2);
  }

  Future<void> changeType(String type) async {
    animations = await loadCatAnimations(game.images, type);
    current = CatState.idle;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (game.finished) return;
    final input = _shaped(game.joystick.relativeDelta);
    final speed = maxSpeed * (_sprintTimer > 0 ? 1.75 : 1);
    final target = Vector2(input.x * speed, input.y * speed);
    velocity +=
        (target - velocity) * min(1, dt * (_bumpTimer > 0 ? bumpedGrip : grip));
    if (_bumpTimer > 0) _bumpTimer -= dt;
    if (invulnerable > 0) invulnerable = max(0, invulnerable - dt);
    if (_sprintTimer > 0) _sprintTimer = max(0, _sprintTimer - dt);
    if (_rollTimer > 0) _rollTimer = max(0, _rollTimer - dt);
    if (_vanishTimer > 0) {
      _vanishTimer -= dt;
      if (!_vanished && _vanishTimer < .35) {
        _vanished = true;
        final previous = position.clone();
        position.x = (position.x + (velocity.x >= 0 ? vanishLeap : -vanishLeap))
            .clamp(ReturnHomeRoad.startX, game.road.endX);
        _clampToLane();
        if (game.blockedByLog(hitbox)) position.setFrom(previous);
      }
      if (_vanishTimer > 0) return;
    }
    _moveAxis(Vector2(velocity.x * dt, 0));
    _moveAxis(Vector2(0, velocity.y * dt));
    current = _rollTimer > 0
        ? CatState.dashEscape
        : _bumpTimer > 0
            ? CatState.panic
            : velocity.length > idleSpeed
                ? CatState.walk
                : CatState.idle;
  }

  /// Small dead zone so a resting thumb does not creep the cat, then a gentle
  /// curve so small pushes give fine control and a full push gives top speed.
  static Vector2 _shaped(Vector2 raw) {
    final length = raw.length;
    if (length < .12) return Vector2.zero();
    final t = ((length - .12) / .88).clamp(0.0, 1.0);
    return raw / length * (t * t * (3 - 2 * t));
  }

  /// Moves one axis at a time so the cat can slide along a log instead of
  /// passing through it or sticking on a diagonal input.
  void _moveAxis(Vector2 delta) {
    final previous = position.clone();
    position += delta;
    position.x = position.x.clamp(ReturnHomeRoad.startX, game.road.endX);
    _clampToLane();
    if (!game.blockedByLog(hitbox)) return;
    position.setFrom(previous);
    if (delta.x != 0) velocity.x = 0;
    if (delta.y != 0) velocity.y = 0;
  }

  /// Paws stay on the road; the body may lean out over an edge.
  void _clampToLane() {
    final road = game.road;
    final lane = road.halfWidth(_bodyCenterX);
    final center = road.centerY(_bodyCenterX);
    position.y =
        position.y.clamp(center - lane - size.y / 2, center + lane - pawLine);
  }

  void activateSkill() {
    switch (game.selectedCat) {
      case 'orange':
        _sprintTimer = 2;
      case 'black':
        activateVanish();
      case 'himalaya':
        _rollTimer = .45;
        invulnerable = 1;
        final input = game.joystick.relativeDelta;
        final dir = input.length > .1
            ? input.normalized()
            : Vector2(velocity.x >= 0 ? 1 : -1, 0);
        velocity = dir * 260;
      case 'scottish':
        shield = true;
    }
  }

  bool consumeShield() {
    if (!shield) return false;
    shield = false;
    invulnerable = .6;
    return true;
  }

  void activateVanish() {
    if (_vanishTimer > 0) return;
    _vanishTimer = vanishDuration;
    _vanished = false;
    current = CatState.vanish;
  }

  void respawn(double x) {
    velocity.setZero();
    _bumpTimer = 0;
    _vanishTimer = 0;
    _sprintTimer = 0;
    _rollTimer = 0;
    shield = false;
    invulnerable = 1.5;
    position = Vector2(x, game.road.centerY(x + size.x / 2) - size.y / 2);
    _clampToLane();
  }

  /// Spring launch: a strong backwards shove with weak grip, so the cat sails
  /// roughly 250-300 px back unless a log stops it.
  void launchBack() {
    _bumpTimer = .9;
    velocity = Vector2(-640, velocity.y * .3);
  }

  void bumpAwayFrom(Vector2 obstacle) {
    _bumpTimer = bumpDuration;
    final away = (position + size / 2) - obstacle;
    if (away.length > 0) velocity += away.normalized() * bumpImpulse;
  }

  @override
  void render(Canvas canvas) {
    if (invulnerable > 0 && (invulnerable * 12).floor().isEven) return;
    canvas.save();
    if (velocity.x < -2) {
      // Flip around the sprite's own right edge; position stays unchanged.
      canvas.translate(size.x, 0);
      canvas.scale(-1, 1);
    }
    super.render(canvas);
    canvas.restore();
    if (shield) {
      canvas.drawCircle(
          Offset(size.x / 2, size.y * .58),
          31,
          Paint()
            ..color = const Color(0xAA75D6FF)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3);
    }
  }
}
