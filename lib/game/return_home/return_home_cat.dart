import 'dart:math';
import '../../audio/game_audio.dart';

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../cats/cat_animations.dart';
import '../cats/cat_state.dart';
import '../constants.dart';
import 'return_home_game.dart';
import 'return_home_road.dart';

/// The player: joystick steering, a knockback that costs progress, the black
/// cat's shadow form, and the clamp that keeps its paws on the curving lane.
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

  static const double shadowDuration = 1.5;
  static const double shadowSpeed = 1.35;
  bool get phasing => _shadowTimer > 0;
  bool get ignoresObstacles => dashing || phasing;

  /// Himalaya dash: a fixed-speed burst that phases through logs, springs and
  /// water and ignores damage; ~200 px, enough to clear a stream crossing.
  static const double dashSpeed = 400;
  static const double dashDuration = .5;

  bool get dashing => _rollTimer > 0;

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
  double _facing = 1;

  /// Last horizontal direction, retained while idle or moving vertically.
  double get facing => _facing;

  double _bumpTimer = 0;
  double _shadowTimer = 0;
  double _shadowClock = 0;
  double _trailClock = 0;
  final _shadowTrail = <Vector2>[];
  double invulnerable = 0;
  double _sprintTimer = 0;
  bool get sprinting => _sprintTimer > 0;
  double _blessingShieldTimer = 0;
  double _rollTimer = 0;
  bool shield = false;

  /// The lane is sampled at the sprite's center, not its top-left corner.
  double get _bodyCenterX => position.x + size.x / 2;

  /// World x of the middle of the body; lane and wind are sampled here.
  double get bodyCenterX => _bodyCenterX;

  /// Pushes the cat vertically (wind) through the normal move, so the lane
  /// clamp and logs still apply.
  void nudge(double dy) {
    if (dy == 0 || phasing) return;
    _moveAxis(Vector2(0, dy));
  }

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
    _shadowClock += dt;
    if (phasing) {
      _shadowTimer = max(0, _shadowTimer - dt);
      _trailClock += dt;
      if (_trailClock >= .045) {
        _trailClock = 0;
        _shadowTrail.add(position.clone());
        if (_shadowTrail.length > 9) _shadowTrail.removeAt(0);
      }
      if (!phasing) _shadowTrail.clear();
    }
    final input = _shaped(game.joystick.relativeDelta);
    final speed =
        maxSpeed * (phasing ? shadowSpeed : (_sprintTimer > 0 ? 1.75 : 1));
    final target = Vector2(input.x * speed, input.y * speed);
    if (!dashing) {
      velocity += (target - velocity) *
          min(1, dt * (_bumpTimer > 0 ? bumpedGrip : grip));
    }
    if (velocity.x.abs() > 2) _facing = velocity.x.sign;
    if (_bumpTimer > 0) _bumpTimer -= dt;
    if (invulnerable > 0) invulnerable = max(0, invulnerable - dt);
    if (_sprintTimer > 0) _sprintTimer = max(0, _sprintTimer - dt);
    final landing = _rollTimer > 0 && _rollTimer <= dt;
    if (_rollTimer > 0) _rollTimer = max(0, _rollTimer - dt);
    if (_blessingShieldTimer > 0) {
      _blessingShieldTimer = max(0, _blessingShieldTimer - dt);
      if (_blessingShieldTimer == 0) shield = false;
    }
    _moveAxis(Vector2(velocity.x * dt, 0));
    _moveAxis(Vector2(0, velocity.y * dt));
    if (landing) game.freezeOnLanding();
    current = _rollTimer > 0
        ? CatState.dashEscape
        : _bumpTimer > 0
            ? CatState.panic
            : velocity.length > idleSpeed
                ? (phasing ? CatState.run : CatState.walk)
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
    // Already overlapping a log (e.g. after a respawn): let the cat walk out
    // instead of freezing it in place.
    final wasBlocked = ignoresObstacles || game.blockedByLog(hitbox);
    final previous = position.clone();
    position += delta;
    position.x = position.x.clamp(ReturnHomeRoad.startX, game.road.endX);
    _clampToLane();
    if (wasBlocked || !game.blockedByLog(hitbox)) return;
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
        activateShadow();
      case 'himalaya':
        _rollTimer = dashDuration;
        invulnerable = dashDuration + .4;
        final input = game.joystick.relativeDelta;
        final dir = input.length > .1 ? input.normalized() : Vector2(facing, 0);
        velocity = dir * dashSpeed;
        if (dir.x.abs() > .01) _facing = dir.x.sign;
      case 'calico':
        // Patches up one heart, never above the starting count.
        if (game.lives < ReturnHomeGame.startingLives) {
          game.lives += 1;
        } else {
          shield = true;
          _blessingShieldTimer = 3;
        }
        game.extendCatEye();
      case 'scottish':
        shield = true;
    }
  }

  /// Dịch chuyển bóng: reappear with the hitbox centered on [center]. If a
  /// log is in the way the cat lands just short of it.
  void blinkTo(Vector2 center) {
    final from = position.clone();
    final to = center -
        Vector2(hitboxLeft + hitboxWidth / 2, hitboxTop + hitboxHeight / 2);
    for (var k = 1.0; k >= 0; k -= .1) {
      position = from + (to - from) * k;
      position.x = position.x.clamp(ReturnHomeRoad.startX, game.road.endX);
      _clampToLane();
      if (!game.blockedByLog(hitbox)) break;
    }
    velocity.scale(.3);
    _bumpTimer = 0;
    _rollTimer = 0;
    invulnerable = max(invulnerable, .35);
  }

  bool consumeShield() {
    if (!shield) return false;
    GameAudio.instance.playGameplay(GameSound.homeShield, priority: 2);
    shield = false;
    _blessingShieldTimer = 0;
    invulnerable = .6;
    if (game.selectedCat == 'scottish') game.shieldRecoil();
    return true;
  }

  void activateShadow() {
    _shadowTimer = shadowDuration;
    _bumpTimer = 0;
    _trailClock = 0;
    _shadowTrail.clear();
  }

  void respawn(double x, {double? y}) {
    _shadowTimer = 0;
    _shadowTrail.clear();
    velocity.setZero();
    _bumpTimer = 0;
    _sprintTimer = 0;
    _blessingShieldTimer = 0;
    _rollTimer = 0;
    shield = false;
    invulnerable = 1.5;
    position = Vector2(x, y ?? game.road.centerY(x + size.x / 2) - size.y / 2);
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

  /// The evolution wave clears space without taking a life or consuming shields.
  void repelFromBoss(double boundaryX, double dt) {
    invulnerable = max(invulnerable, .3);
    if (position.x <= boundaryX) return;
    _rollTimer = 0;
    _bumpTimer = max(_bumpTimer, .15);
    _facing = -1;
    velocity.x = min(0, velocity.x);
    _moveAxis(Vector2(-min(position.x - boundaryX, 600 * dt), 0));
  }

  @override
  void render(Canvas canvas) {
    if (!phasing && invulnerable > 0 && (invulnerable * 12).floor().isEven) {
      return;
    }
    if (sprinting) {
      for (var i = 0; i < 5; i++) {
        final t = (_shadowClock * 2 + i / 5) % 1;
        canvas.drawCircle(
            Offset(size.x / 2 - facing * (8 + t * 24), 58 - t * 18),
            2 + 3 * (1 - t),
            Paint()..color = const Color(0xFFFFA447).withOpacity((1 - t) * .7));
      }
    }
    if (phasing) {
      for (var i = 0; i < _shadowTrail.length; i++) {
        final p = _shadowTrail[i] - position;
        final fade = (i + 1) / _shadowTrail.length;
        canvas.drawOval(
            Rect.fromCenter(
                center: Offset(
                    p.x + size.x / 2, p.y + 51 - sin(_shadowClock * 5 + i) * 3),
                width: 12 + fade * 17,
                height: 8 + fade * 13),
            Paint()..color = const Color(0xFF9E78DF).withOpacity(fade * .3));
      }
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset(size.x / 2, 60), width: 52, height: 16),
          Paint()
            ..shader = const RadialGradient(
                    colors: [Color(0x887A4DC3), Color(0x007A4DC3)])
                .createShader(Rect.fromCenter(
                    center: Offset(size.x / 2, 60), width: 52, height: 16)));
      canvas.saveLayer(
          Offset.zero & Size(size.x, size.y),
          Paint()
            ..color = const Color(0xBFFFFFFF)
            ..colorFilter =
                const ColorFilter.mode(Color(0xFFAA7DE1), BlendMode.srcATop));
    }
    canvas.save();
    if (facing < 0) {
      // Flip around the sprite's own right edge; position stays unchanged.
      canvas.translate(size.x, 0);
      canvas.scale(-1, 1);
    }
    super.render(canvas);
    canvas.restore();
    if (phasing) canvas.restore();
    if (shield) {
      canvas.drawCircle(
          Offset(size.x / 2, size.y * .58),
          31,
          Paint()
            ..color = _blessingShieldTimer > 0
                ? const Color(0xFFDCA0D5)
                : const Color(0xAA75D6FF)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3);
      if (_blessingShieldTimer > 0) {
        canvas.drawArc(
            Rect.fromCircle(
                center: Offset(size.x / 2, size.y * .58), radius: 34),
            -pi / 2,
            2 * pi * _blessingShieldTimer / 3,
            false,
            Paint()
              ..color = const Color(0xFFFFDB8A)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2);
      }
    }
  }
}
