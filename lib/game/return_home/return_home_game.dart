import 'dart:async';
import '../../camp/camp_state.dart';
import '../cats/cat_breed.dart';
import '../cats/home_attack.dart';
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/painting.dart';

import 'return_home_background.dart';
import 'return_home_cat.dart';
import 'return_home_crossing.dart';
import 'return_home_dragon.dart';
import 'return_home_hud.dart';
import 'return_home_gate.dart';
import 'return_home_joystick.dart';
import 'return_home_obstacle.dart';
import 'return_home_pickup.dart';
import 'return_home_road.dart';
import 'return_home_skills.dart';
import 'return_home_spawner.dart';

/// The Return Home mode: owns the road, the hazard spawner, the cat and the run
/// state. Everything else is a collaborator that reads [road].
class ReturnHomeGame extends FlameGame {
  ReturnHomeGame();

  /// Lives at the start, the invulnerability window after a hit, the share of
  /// the final viewport kept free of new hazards, and the skill cooldown.
  static const int startingLives = 3;
  static const double hitCooldown = .9;
  static const double safeFinishStretch = .45;

  late ReturnHomeJoystick joystick;
  late ReturnHomeCat _cat;
  late ReturnHomeSpawner _spawner;
  final _crossings = <ReturnHomeCrossing>[];

  /// The winding lane. Resized in place, so collaborators can hold on to it.
  final ReturnHomeRoad road = ReturnHomeRoad();

  double progress = 0;
  int lives = startingLives;
  bool finished = false;
  bool started = false;
  bool _choosing = false;
  bool skillReady = true;
  double skillCooldown = 0;
  String selectedCat = 'orange';
  int fish = 0;
  int reward = 0;
  int falls = 0;
  double elapsed = 0;
  double checkpointX = ReturnHomeRoad.startX;
  double checkpointMessage = 0;
  EdgeInsets hudPadding = EdgeInsets.zero;
  String zoneName = '';
  final _pickups = <ReturnHomePickup>[];

  /// The breed's three secondary skills (see HomeAttack) and their state.
  List<HomeAttack> get attacks => CatBreed.of(selectedCat).attacks;
  final attackCooldown = List<double>.filled(3, 0);
  double magnetTime = 0;
  double timeStopTime = 0;
  double reflectTime = 0;
  double catEyeTime = 0;
  final _magnet = ReturnHomeMagnetAura();
  final _reflectAura = ReturnHomeReflectAura();
  final _timeAura = ReturnHomeTimeStopAura();
  late ReturnHomeCatEyeAura _catEyeAura;
  final _projectiles = <ReturnHomeProjectile>[];
  final _bolts = <ReturnHomeBolt>[];
  final _breaths = <ReturnHomeFlameBreath>[];
  final _bombs = <ReturnHomeFireBomb>[];
  final _bridges = <ReturnHomeIceBridge>[];
  final _walls = <ReturnHomeStoneWall>[];
  ReturnHomeDecoy? _decoy;
  final _aim = ReturnHomeAimIndicator();
  Offset? _aimStick;
  late World _world;
  int _boltSeed = 0;

  /// Slot whose button is being held (range preview showing), if any.
  int? aimingSlot;

  /// Boss fight on the final screen (see return_home_dragon.dart).
  ReturnHomeDragon? _dragon;
  bool bossDefeated = false;
  double _scratchCooldown = 0;
  double _bossCamera = 0;
  String zoneSubtitle = 'Đã lưu checkpoint';
  static const int bossBonus = 30;

  bool get bossFight => _dragon != null && !bossDefeated;

  /// Boss health 0..1 for the HUD, null when no fight is on.
  double? get bossHealth => bossFight ? _dragon!.hpShare : null;
  int get bossPhase => _dragon?.phase ?? 1;
  bool get bossTired => (_dragon?.tired ?? 0) > 0;

  /// The dragon when skills can hurt it.
  ReturnHomeDragon? get _boss {
    final d = _dragon;
    return d != null && !bossDefeated && d.vulnerable ? d : null;
  }

  double get _arenaLeft => road.worldWidth - size.x;

  int get stars => 1 + (falls == 0 ? 1 : 0) + (fish >= 10 ? 1 : 0);

  double _hitCooldown = 0;
  final _contacts = <ReturnHomeObstacle>{};

  Future<void> chooseCat(String type) async {
    if (started || _choosing) return;
    _choosing = true;
    selectedCat = type;
    await _cat.changeType(type);
    started = true;
    overlays.remove('chooseCat');
    overlays.add('skill');
  }

  void activateSkill() {
    if (!started || !skillReady || finished) return;
    skillReady = false;
    skillCooldown = CatBreed.of(selectedCat).homeSkill.cooldown -
        (CampState.instance.bonded(selectedCat) ? 1 : 0);
    _cat.activateSkill();
  }

  // ---- Secondary skills -------------------------------------------------

  bool get _canAttack => started && !finished;
  double get _facing => _cat.velocity.x < -2 ? -1 : 1;
  Vector2 get _catCenter {
    final c = _cat.hitbox.center;
    return Vector2(c.dx, c.dy);
  }

  /// Fire comes out of the cat's mouth, a bit ahead of the body.
  Vector2 get _castOrigin {
    final c = _cat.hitbox.center;
    return Vector2(c.dx + _facing * 16, c.dy - 12);
  }

  /// Seconds left on a slot's lasting effect; the button glows meanwhile.
  double attackActive(int slot) => switch (attacks[slot]) {
        HomeAttack.magnet => magnetTime,
        HomeAttack.timeStop => timeStopTime,
        HomeAttack.reflect => reflectTime,
        HomeAttack.catEye => catEyeTime,
        HomeAttack.decoy => _decoy?.timeLeft ?? 0,
        _ => 0,
      };

  static bool _hidden(ReturnHomeObstacle o) =>
      o.kind == ReturnHomeObstacleKind.spring && o.springT <= 0;

  /// Nearest visible hazard within [range], not behind the cat. Hidden springs
  /// stay hidden: auto-aim never gives them away.
  ReturnHomeObstacle? _autoTarget(double range,
      {bool Function(ReturnHomeObstacle)? only}) {
    final origin = _castOrigin;
    ReturnHomeObstacle? best;
    var bestDistance = range;
    for (final o in _spawner.obstacles) {
      if (_hidden(o) || (only != null && !only(o))) continue;
      if ((o.position.x - origin.x) * _facing < -10) continue;
      final d = o.position.distanceTo(origin);
      if (d < bestDistance) {
        bestDistance = d;
        best = o;
      }
    }
    return best;
  }

  /// The button already applies the drag dead zone: any non-zero stick
  /// means the player steered, a zero/null one means auto-aim.
  bool _steered(Offset? stick) => stick != null && stick.distance > 0;

  /// Direction for skill shots, cones, bridges and walls.
  Vector2 _aimDirection(HomeAttack attack, Offset? stick) {
    if (_steered(stick)) return Vector2(stick!.dx, stick.dy).normalized();
    if (attack == HomeAttack.iceBridge) return Vector2(_facing, 0);
    final target = _autoTarget(attack.range);
    final boss = _boss;
    if (boss != null &&
        (target == null ||
            boss.aimPoint.distanceTo(_castOrigin) <
                target.position.distanceTo(_castOrigin))) {
      return (boss.aimPoint - _castOrigin).normalized();
    }
    if (target == null) return Vector2(_facing, 0);
    return (target.position - _castOrigin).normalized();
  }

  /// Ground point for area, wall and blink skills, always within range.
  Vector2 _aimPoint(HomeAttack attack, Offset? stick) {
    final origin = _catCenter;
    Vector2 point;
    if (_steered(stick)) {
      final v = Vector2(stick!.dx, stick.dy);
      if (v.length > 1) v.normalize();
      point = origin + v * attack.range;
    } else {
      final target = switch (attack) {
        HomeAttack.bolt || HomeAttack.fireBomb => _autoTarget(attack.range),
        HomeAttack.stoneWall => _autoTarget(attack.range,
            only: (o) => o.kind == ReturnHomeObstacleKind.rock),
        _ => null,
      };
      point = target?.position.clone() ??
          origin +
              Vector2(
                  _facing *
                      switch (attack) {
                        HomeAttack.shadowStep => attack.range,
                        HomeAttack.stoneWall => 110,
                        _ => 140,
                      },
                  0);
      if (attack == HomeAttack.stoneWall && target != null) {
        // Stand the wall between the cat and the rock.
        point = origin + (point - origin) * .6;
      }
      final boss = _boss;
      if (boss != null && target == null) {
        if (attack == HomeAttack.bolt || attack == HomeAttack.fireBomb) {
          point = boss.position.clone();
        } else if (attack == HomeAttack.stoneWall) {
          // Shield the cat from the dragon's fire.
          point = origin + (boss.core - origin).normalized() * 110;
        }
      }
    }
    final reach = point - origin;
    if (reach.length > attack.range) {
      point = origin + reach.normalized() * attack.range;
    }
    if (attack == HomeAttack.shadowStep || attack == HomeAttack.decoy) {
      // Feet must land on the road.
      point.x = point.x.clamp(ReturnHomeRoad.startX, road.endX).toDouble();
      final half = road.halfWidth(point.x) - 10;
      final center = road.centerY(point.x);
      point.y = point.y.clamp(center - half, center + half).toDouble();
    }
    return point;
  }

  bool _onIce(Offset p) => _bridges.any((b) => b.isMounted && b.covers(p));

  /// Blinking into water or into a log would be wasted; the preview turns red.
  bool _blinkValid(Vector2 center) {
    final box = Rect.fromCenter(
        center: Offset(center.x, center.y),
        width: ReturnHomeCat.hitboxWidth,
        height: ReturnHomeCat.hitboxHeight);
    if (blockedByLog(box)) return false;
    return !_crossings.any((c) => c.inWater(box, dry: _onIce));
  }

  void aimAttack(int slot, Offset stick) {
    if (!_canAttack || attackCooldown[slot] > 0) return;
    aimingSlot = slot;
    _aim.attack = attacks[slot];
    _aimStick = stick;
    _updateAim();
  }

  void cancelAim() {
    aimingSlot = null;
    _aim.attack = null;
    _aimStick = null;
  }

  /// Release of a skill button: [stick] null or short means auto-aim.
  void castAttack(int slot, [Offset? stick]) {
    cancelAim();
    if (!_canAttack || attackCooldown[slot] > 0) return;
    final attack = attacks[slot];
    if (_cast(attack, stick)) attackCooldown[slot] = attack.cooldown;
  }

  /// Fires [attack]; false if it could not be cast (no cooldown spent).
  bool _cast(HomeAttack attack, Offset? stick) {
    switch (attack) {
      case HomeAttack.fireball:
      case HomeAttack.iceShard:
        final shot = ReturnHomeProjectile(
            position: _castOrigin,
            direction: _aimDirection(attack, stick),
            attack: attack);
        _projectiles.add(shot);
        _world.add(shot);
      case HomeAttack.flameBreath:
        final breath = ReturnHomeFlameBreath(
            position: _castOrigin, direction: _aimDirection(attack, stick));
        _breaths.add(breath);
        _world.add(breath);
      case HomeAttack.fireBomb:
        final bomb = ReturnHomeFireBomb(
            from: _castOrigin, target: _aimPoint(attack, stick));
        _bombs.add(bomb);
        _world.add(bomb);
      case HomeAttack.bolt:
        final bolt = ReturnHomeBolt(
            position: _aimPoint(attack, stick), seed: _boltSeed++);
        _bolts.add(bolt);
        _world.add(bolt);
      case HomeAttack.shadowStep:
        final target = _aimPoint(attack, stick);
        if (!_blinkValid(target)) return false;
        _world.add(ReturnHomeShadowStep(from: _catCenter, to: target));
        _cat.blinkTo(target);
        _contacts.clear();
      case HomeAttack.decoy:
        _decoy?.removeFromParent();
        final decoy = ReturnHomeDecoy(
            animations: _cat.animations!,
            center: _aimPoint(attack, stick),
            flip: _cat.velocity.x < -2);
        _decoy = decoy;
        _world.add(decoy);
      case HomeAttack.timeStop:
        timeStopTime = attack.duration;
        _timeAura.start();
      case HomeAttack.frostNova:
        final center = _catCenter;
        _world.add(ReturnHomeFrostWave(position: center));
        for (final o in _spawner.obstacles) {
          if (_hidden(o)) continue;
          if (o.position.distanceTo(center) <= attack.radius + 10) {
            o.frozen = attack.duration;
          }
        }
        final boss = _boss;
        if (boss != null &&
            boss.core.distanceTo(center) <= attack.radius + 80) {
          boss
            ..frozen = 2.5
            ..interrupt();
          _damageBoss(1, boss.core);
        }
      case HomeAttack.iceBridge:
        final bridge = ReturnHomeIceBridge(
            origin: _catCenter, direction: _aimDirection(attack, stick));
        _bridges.add(bridge);
        _world.add(bridge);
      case HomeAttack.roar:
        _roar();
      case HomeAttack.stoneWall:
        final target = _aimPoint(attack, stick);
        var facing = target - _catCenter;
        if (facing.length2 < 1) facing = Vector2(_facing, 0);
        final wall = ReturnHomeStoneWall(center: target, facing: facing);
        _walls.add(wall);
        _world.add(wall);
      case HomeAttack.reflect:
        reflectTime = attack.duration;
      case HomeAttack.magnet:
        magnetTime = attack.duration;
      case HomeAttack.catEye:
        catEyeTime = attack.duration;
    }
    return true;
  }

  /// Shockwave around the cat: pushes hazards in [roarRadius] away and gives
  /// a short grace window so the cat is not hit while they scatter.
  void _roar() {
    final center = _catCenter;
    _world.add(ReturnHomeRoarWave(position: center));
    for (final o in _spawner.obstacles) {
      if (o.position.distanceTo(center) <= roarRadius) {
        o.scare(center, roarPush);
        _contacts.remove(o);
      }
    }
    final boss = _boss;
    if (boss != null && boss.core.distanceTo(center) <= roarRadius + 80) {
      boss.interrupt();
      _damageBoss(1, boss.core);
    }
    _cat.invulnerable = max(_cat.invulnerable, .35);
  }

  /// While the magnet runs, pickups in range slide toward the cat, faster the
  /// closer they get, and are collected by the normal pickup check.
  void _updateMagnet(double dt) {
    final center = _catCenter;
    _magnet
      ..center = center
      ..timeLeft = magnetTime;
    if (magnetTime <= 0) return;
    for (final pickup in _pickups) {
      final toCat = center - pickup.position;
      final d = toCat.length;
      if (d > magnetRadius || d < 1) continue;
      final speed = magnetPull * (1.6 - d / magnetRadius);
      pickup.position += toCat * (min(d, speed * dt) / d);
    }
  }

  void _tickSkillTimers(double dt) {
    for (var i = 0; i < attackCooldown.length; i++) {
      attackCooldown[i] = max(0, attackCooldown[i] - dt);
    }
    magnetTime = max(0, magnetTime - dt);
    timeStopTime = max(0, timeStopTime - dt);
    reflectTime = max(0, reflectTime - dt);
    catEyeTime = max(0, catEyeTime - dt);
    for (final o in _spawner.obstacles) {
      if (o.frozen > 0) o.frozen = max(0, o.frozen - dt);
    }
    final center = _catCenter;
    _reflectAura
      ..center = center
      ..timeLeft = reflectTime;
    _catEyeAura
      ..center = center
      ..timeLeft = catEyeTime;
    _timeAura
      ..center = center
      ..timeLeft = timeStopTime;
    final scale = timeStopTime > 0 ? 0.0 : 1.0;
    for (final c in _crossings) {
      c.timeScale = scale;
    }
    _updateMagnet(dt);
  }

  void _updateAim() {
    final attack = _aim.attack;
    if (attack == null) return;
    final stick = _aimStick;
    _aim
      ..origin = _catCenter
      ..castFrom = _castOrigin
      ..valid = true
      ..view = Rect.fromCenter(
          center: Offset(camera.viewfinder.position.x, size.y / 2),
          width: size.x,
          height: size.y);
    switch (attack.shape) {
      case AimShape.line:
      case AimShape.cone:
        _aim.direction = _aimDirection(attack, stick);
      case AimShape.area:
        _aim.target = _aimPoint(attack, stick);
      case AimShape.wall:
        final target = _aimPoint(attack, stick);
        var facing = target - _catCenter;
        if (facing.length2 < 1) facing = Vector2(_facing, 0);
        _aim
          ..target = target
          ..direction = facing.normalized();
      case AimShape.blink:
        final target = _aimPoint(attack, stick);
        _aim
          ..target = target
          ..valid = _blinkValid(target);
      case AimShape.self:
      case AimShape.global:
        break;
    }
  }

  /// One point of damage; logs need two, everything else breaks at once.
  void _hurt(ReturnHomeObstacle o) {
    o.damage += 1;
    if (o.kind != ReturnHomeObstacleKind.log || o.damage >= 2) _destroy(o);
  }

  void _resolveAttacks() {
    final boss = _boss;
    for (final shot in List<ReturnHomeProjectile>.of(_projectiles)) {
      if (boss != null && !shot.hitBoss && boss.hitTest(shot.hitRect)) {
        shot.hitBoss = true;
        if (shot.icy) {
          boss
            ..frozen = max(boss.frozen, 1.2)
            ..interrupt();
          _damageBoss(1, shot.position);
        } else {
          _damageBoss(2, shot.position);
          _projectiles.remove(shot);
          shot.removeFromParent();
          _world.add(ReturnHomeBurst(
              position: shot.position.clone(),
              color: const Color(0xFFFF8A3A),
              fiery: true));
          continue;
        }
      }
      final hits = _spawner.obstacles
          .where((o) =>
              !_hidden(o) && !shot.hit.contains(o) && o.hits(shot.hitRect))
          .toList();
      if (shot.icy) {
        // Pierces: freezes what it touches, shatters what is already ice.
        for (final o in hits) {
          shot.hit.add(o);
          if (o.frozen > 0) {
            _destroy(o, icy: true);
          } else {
            o.frozen = shot.attack.duration;
            _contacts.remove(o);
          }
        }
        if (!shot.spent) continue;
        _projectiles.remove(shot);
        shot.removeFromParent();
        _world.add(ReturnHomeBurst(
            position: shot.position.clone(), color: const Color(0xFFBDE8FA)));
        continue;
      }
      final hit = hits.firstOrNull;
      if (hit == null && !shot.spent) continue;
      _projectiles.remove(shot);
      shot.removeFromParent();
      _world.add(ReturnHomeBurst(
          position: shot.position.clone(),
          color: const Color(0xFFFF8A3A),
          fiery: true));
      if (hit != null) _hurt(hit);
    }

    for (final breath in List<ReturnHomeFlameBreath>.of(_breaths)) {
      if (!breath.isMounted && !breath.blowing) {
        _breaths.remove(breath);
        continue;
      }
      if (breath.blowing) breath.position = _castOrigin;
      if (!breath.tickNow) continue;
      if (boss != null &&
          (breath.covers(boss.aimPoint) || breath.covers(boss.core))) {
        _damageBoss(1, boss.aimPoint);
      }
      for (final o in List<ReturnHomeObstacle>.of(_spawner.obstacles)) {
        if (!_hidden(o) && breath.covers(o.position)) _hurt(o);
      }
    }

    for (final bomb in List<ReturnHomeFireBomb>.of(_bombs)) {
      if (!bomb.isMounted && bomb.landed) {
        _bombs.remove(bomb);
        continue;
      }
      if (!bomb.explodeNow && !bomb.tickNow) continue;
      if (boss != null &&
          inGroundEllipse(boss.position, bomb.target, bomb.radius,
              margin: 70)) {
        // Only the blast hurts the dragon; the burning patch is for hazards.
        if (bomb.explodeNow) _damageBoss(3, boss.core);
      }
      for (final o in List<ReturnHomeObstacle>.of(_spawner.obstacles)) {
        if (_hidden(o) || !bomb.covers(o.position)) continue;
        bomb.explodeNow ? _destroy(o) : _hurt(o);
      }
    }

    for (final bolt in List<ReturnHomeBolt>.of(_bolts)) {
      if (!bolt.isMounted && bolt.struck) {
        _bolts.remove(bolt);
        continue;
      }
      if (!bolt.strikeNow) continue;
      final p = bolt.position;
      if (boss != null &&
          inGroundEllipse(boss.position, p, boltRadius, margin: 70)) {
        _damageBoss(4, boss.core);
      }
      for (final o in List<ReturnHomeObstacle>.of(_spawner.obstacles)) {
        final inColumn = o.kind == ReturnHomeObstacleKind.bird &&
            (o.position.x - p.x).abs() < 34 &&
            o.position.y < p.y;
        if (inGroundEllipse(o.position, p, boltRadius) || inColumn) {
          _destroy(o);
        }
      }
    }

    _bridges.removeWhere((b) => b.isRemoved);
    for (final bridge in _bridges) {
      // Fresh ice also freezes whatever stands on it.
      if (bridge.frozeHazards || !bridge.built) continue;
      bridge.frozeHazards = true;
      for (final o in _spawner.obstacles) {
        if (!_hidden(o) &&
            o.kind != ReturnHomeObstacleKind.bird &&
            bridge.covers(Offset(o.position.x, o.position.y))) {
          o.frozen = HomeAttack.iceShard.duration;
        }
      }
    }

    _walls.removeWhere((w) => w.isRemoved);
    for (final wall in _walls) {
      if (!wall.standing) continue;
      for (final o in _spawner.obstacles) {
        final reach = switch (o.kind) {
          ReturnHomeObstacleKind.rock => rockRadius,
          ReturnHomeObstacleKind.crab => 16.0,
          ReturnHomeObstacleKind.bird => 20.0,
          _ => 0.0,
        };
        if (reach == 0) continue;
        final closest = wall.closest(o.position);
        var normal = o.position - closest;
        final distance = normal.length;
        if (distance >= reach) continue;
        if (o.kind == ReturnHomeObstacleKind.bird) {
          if (!o.harmless) o.scare(wall.position, 0);
          continue;
        }
        normal = distance == 0
            ? (o.position - wall.position).normalized()
            : normal / distance;
        o.position += normal * (reach - distance);
        final into = o.velocity.dot(normal);
        if (into < 0) o.velocity -= normal * (1.8 * into);
        if (o.kind == ReturnHomeObstacleKind.crab) o.velocity.y = -o.velocity.y;
      }
    }

    final decoy = _decoy;
    if (decoy != null && decoy.expired) {
      _decoy = null;
      decoy.removeFromParent();
      final center = decoy.lureCenter;
      _world.add(ReturnHomeShadowStep(from: center, to: center));
      _world.add(
          ReturnHomeBurst(position: center, color: const Color(0xFF7B5FC4)));
      for (final o in _spawner.obstacles) {
        if (o.position.distanceTo(center) <= HomeAttack.decoy.radius) {
          o.scare(center, roarPush);
        }
      }
      final boss = _boss;
      if (boss != null &&
          boss.core.distanceTo(center) <= HomeAttack.decoy.radius + 80) {
        _damageBoss(4, boss.core);
      }
    }
  }

  void _destroy(ReturnHomeObstacle o, {bool icy = false}) {
    _spawner.obstacles.remove(o);
    _contacts.remove(o);
    o.removeFromParent();
    _world.add(ReturnHomeBurst(
      position: o.position.clone(),
      color: icy
          ? const Color(0xFFBDE8FA)
          : switch (o.kind) {
              ReturnHomeObstacleKind.log => const Color(0xFF8A5A36),
              ReturnHomeObstacleKind.crab => const Color(0xFFE0583F),
              ReturnHomeObstacleKind.bird => const Color(0xFF4A5A73),
              ReturnHomeObstacleKind.spring => const Color(0xFF8E979C),
              _ => const Color(0xFF8D9690),
            },
    ));
  }

  // ---- Boss ---------------------------------------------------------------

  void _startBoss(double cameraX) {
    final x = road.worldWidth - 236;
    final dragon = ReturnHomeDragon(
        road: road, feet: Vector2(x, road.centerY(x) + road.halfWidth(x) * .1))
      ..arenaLeft = _arenaLeft
      ..target = _catCenter;
    _dragon = dragon;
    _world.add(dragon);
    _bossCamera = cameraX;
    zoneName = 'RỒNG LỬA XUẤT HIỆN!';
    zoneSubtitle = 'Đánh bại rồng để về nhà';
    checkpointMessage = 2.4;
  }

  void _damageBoss(double amount, Vector2 at) {
    final dragon = _dragon;
    if (dragon == null) return;
    final dealt = dragon.hurt(amount);
    if (dealt <= 0) return;
    _world.add(ReturnHomeDamageText(
        position: at + Vector2(0, -24),
        text: '-${dealt.round()}',
        color: dealt > amount
            ? const Color(0xFFFFE15A)
            : const Color(0xFFFFF4DA)));
  }

  void _updateBoss(double dt) {
    final dragon = _dragon;
    if (dragon == null) return;
    if (dragon.gone) {
      dragon.removeFromParent();
      _dragon = null;
      return;
    }
    if (dragon.defeated) {
      if (!bossDefeated) {
        bossDefeated = true;
        fish += 10;
        zoneName = 'ĐÃ ĐÁNH BẠI RỒNG!';
        zoneSubtitle = '+10 cá · đường về nhà đã mở';
        checkpointMessage = 2.8;
      }
      return;
    }
    dragon
      ..arenaLeft = _arenaLeft
      ..target = _decoy?.lureCenter ?? _catCenter
      ..timeScale = timeStopTime > 0
          ? 0
          : catEyeTime > 0
              ? .6
              : 1;
    // The dragon blocks the lane: the cat stays in the arena in front of it.
    final minX = _arenaLeft + 6;
    final maxX = dragon.bodyRect.left - ReturnHomeCat.hitboxLeft - 80;
    if (_cat.position.x > maxX) {
      _cat.position.x = maxX;
      _cat.velocity.x = min(0, _cat.velocity.x);
    } else if (_cat.position.x < minX) {
      _cat.position.x = minX;
      _cat.velocity.x = max(0, _cat.velocity.x);
    }

    final walls = _walls.where((w) => w.standing).toList();
    for (final attack in List<DragonAttack>.of(dragon.attacks)) {
      if (attack is DragonFlameLane) {
        double? stop;
        for (final w in walls) {
          final inBand = (w.position.y - attack.laneY).abs() <
              w.length / 2 + DragonFlameLane.halfHeight;
          if (inBand && w.position.x < attack.right) {
            final x = w.position.x + ReturnHomeStoneWall.thickness;
            stop = stop == null ? x : max(stop, x);
          }
        }
        attack.blockedAt = stop;
      } else if (attack is DragonMeteor && attack.impactNow) {
        attack.blocked = walls.any(
            (w) => w.closest(attack.target).distanceTo(attack.target) < 44);
      }
      if (attack.hits(_cat.hitbox)) {
        _bossHitsCat(dragon);
        if (_dragon != dragon || dragon.defeated) return;
      }
    }

    // Tired: the head is down in the lane, claw it!
    _scratchCooldown = max(0, _scratchCooldown - dt);
    if (dragon.tired > 0 &&
        _scratchCooldown <= 0 &&
        _cat.hitbox.overlaps(dragon.headRect)) {
      _scratchCooldown = .45;
      final head = dragon.headRect.center;
      _world.add(ReturnHomeBurst(
          position: Vector2(head.dx, head.dy), color: const Color(0xFFFFF4DA)));
      _damageBoss(2.5, Vector2(head.dx, head.dy));
    }

    if (dragon.summonNow) {
      final mouth = dragon.mouth;
      for (var i = 0; i < 2; i++) {
        final x = mouth.x - 40;
        final half = road.halfWidth(x) - 20;
        _spawner.addRockAt(
            Vector2(x, road.centerY(x) + (i == 0 ? -half * .6 : half * .6)),
            speed: 200 + i * 40);
      }
      if (dragon.phase == 3) _spawner.addBirdAt(_arenaLeft + size.x + 40);
    }
  }

  void _bossHitsCat(ReturnHomeDragon dragon) {
    if (_cat.dashing || _cat.invulnerable > 0 || _hitCooldown > 0) return;
    _hitCooldown = hitCooldown;
    if (reflectTime > 0) {
      _reflectAura.flash();
      _damageBoss(2, dragon.core);
      return;
    }
    _cat.bumpAwayFrom(dragon.core);
    if (_cat.consumeShield()) return;
    lives -= 1;
    _cat.invulnerable = hitCooldown;
    if (lives <= 0) _respawn();
  }

  @override
  void onGameResize(Vector2 size) {
    // Rebuild the road before super propagates the resize, because the
    // background tessellates itself from it.
    final oldWidth = road.worldWidth;
    final oldHeight = road.viewportHeight;
    road.resize(size.x, size.y);
    if (isLoaded) {
      _scaleWorld(road.worldWidth / oldWidth, road.viewportHeight / oldHeight);
    }
    super.onGameResize(size);
  }

  void _scaleWorld(double sx, double sy) {
    final scale = Vector2(sx, sy);
    _cat.position.multiply(scale);
    for (final obstacle in _spawner.obstacles) {
      obstacle.position.multiply(scale);
    }
    for (final pickup in _pickups) {
      pickup.position.multiply(scale);
    }
    checkpointX *= sx;
    joystick.position = Vector2(92, size.y - 92);
  }

  /// Logs are solid walls for normal movement and vanish landing.
  bool blockedByLog(Rect box) => _spawner.obstacles.any((obstacle) =>
      obstacle.kind == ReturnHomeObstacleKind.log && obstacle.hits(box));

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    road.resize(size.x, size.y);
    final world = World();
    _world = world;
    add(world);
    camera = CameraComponent(world: world);
    add(camera);
    // Keep the whole landscape viewport visible; only its X center follows
    // the cat along the longer world.
    camera.viewfinder.position = Vector2(size.x / 2, size.y / 2);
    world.add(ReturnHomeBackground(road: road));
    world.add(ReturnHomeGate());
    // One long crossing near the end of the stream stretch; the dry part
    // before it belongs to the crabs.
    for (final f in [.352]) {
      final crossing = ReturnHomeCrossing(road: road, centerFraction: f);
      _crossings.add(crossing);
      world.add(crossing);
    }
    _cat = ReturnHomeCat();
    world.add(_cat);
    world.add(_aim);
    world.add(_magnet);
    world.add(_reflectAura);
    world.add(_timeAura);
    _spawner = ReturnHomeSpawner(
      road: road,
      world: world,
      // Keep hazard density constant however long the run is.
      initialCount: (road.worldWidth / 175).round(),
    )..seed();
    _clearCrossing();
    // Crabs keep clear of the crossing and of the bank the cat respawns on.
    _spawner.fillCrabs(
        blocked: (x) =>
            _crossings.any((c) => x > c.safeBankX - 30 && x < c.right + 40));
    _addPickups(world);
    _catEyeAura = ReturnHomeCatEyeAura(obstacles: _spawner.obstacles);
    world.add(_catEyeAura);
    joystick = ReturnHomeJoystick(position: Vector2(92, size.y - 92));
    camera.viewport.add(joystick);
  }

  void _clearCrossing() {
    for (final obstacle in List<ReturnHomeObstacle>.of(_spawner.obstacles)) {
      if (!_nearCrossing(obstacle.position.x)) continue;
      _spawner.obstacles.remove(obstacle);
      obstacle.removeFromParent();
    }
  }

  bool _nearCrossing(double x) =>
      _crossings.any((c) => x > c.left - 90 && x < c.right + 90);

  void _addPickups(World world) {
    final random = Random(7);
    var i = 0;
    for (var x = 260.0;
        x < road.endX - 220;
        x += 155 + random.nextDouble() * 70) {
      if (_nearCrossing(x)) continue;
      final reach = road.halfWidth(x) - 18;
      final pickup = ReturnHomePickup(
        kind: i++ % 7 == 6
            ? ReturnHomePickupKind.heart
            : ReturnHomePickupKind.fish,
        position:
            Vector2(x, road.centerY(x) + (random.nextDouble() * 2 - 1) * reach),
      );
      _pickups.add(pickup);
      world.add(pickup);
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
    if (finished) return;
    final fallsBefore = falls;
    elapsed += dt;
    checkpointMessage = max(0, checkpointMessage - dt);
    _updateCheckpoint();
    if (skillCooldown > 0) {
      skillCooldown = max(0, skillCooldown - dt);
      if (skillCooldown == 0) skillReady = true;
    }
    _hitCooldown = max(0, _hitCooldown - dt);
    _tickSkillTimers(dt);
    _updateAim();
    final timeScale = timeStopTime > 0 ? 0.0 : 1.0;
    var cameraX = _cat.position.x
        .clamp(size.x / 2, road.worldWidth - size.x / 2)
        .toDouble();
    if (!bossDefeated &&
        _dragon == null &&
        _cat.position.x >= road.worldWidth - size.x * .78) {
      _startBoss(cameraX);
    }
    if (bossFight) {
      // Pan to the arena (the last screen) and hold it there.
      _bossCamera +=
          (road.worldWidth - size.x / 2 - _bossCamera) * min(1, dt * 3);
      cameraX = _bossCamera;
    }
    final rightEdge = cameraX + size.x / 2;
    _spawner.tick(
      dt: dt * timeScale,
      rightEdge: rightEdge,
      canSpawn: rightEdge < road.worldWidth - size.x * safeFinishStretch,
    );
    _contacts
        .removeAll(_spawner.cull(cameraX - size.x / 2 - _spawner.cullBehind));
    _applyWind(dt);
    _rideStones();
    _resolveHits(dt * timeScale);
    _resolveAttacks();
    resolveObstacleCollisions(_spawner.obstacles);
    _sinkRocks();
    _checkWater();
    _collectPickups();
    _updateBoss(dt);
    if (falls != fallsBefore) {
      cameraX = _cat.position.x
          .clamp(size.x / 2, road.worldWidth - size.x / 2)
          .toDouble();
    }
    camera.viewfinder.position = Vector2(cameraX, size.y / 2);
    const start = ReturnHomeRoad.startX;
    progress = ((_cat.position.x - start) / max(1.0, road.endX - start))
        .clamp(0.0, 1.0);
    if (progress >= 1 && bossDefeated) {
      finished = true;
      reward = fish * 2 + stars * 10 + (bossDefeated ? bossBonus : 0);
      unawaited(CampState.instance.addCoins(reward));
    }
  }

  /// The mode's damage rules: a log is a wall that stops forward motion, every
  /// other hazard costs a life, and one hit cannot burn several lives at once.
  void _resolveHits(double dt) {
    // Birds dive at the decoy while it stands; the cat eye slows hazards
    // around the cat.
    final decoy = _decoy;
    final lure = decoy == null
        ? _cat.hitbox.center
        : Offset(decoy.lureCenter.x, decoy.lureCenter.y);
    final center = _catCenter;
    for (final obstacle in _spawner.obstacles) {
      final slow = catEyeTime > 0 &&
          obstacle.position.distanceTo(center) <= HomeAttack.catEye.radius;
      obstacle.updatePhysics(dt * (slow ? catEyeSlow : 1), lure);
    }
    // Iterate a copy: a respawn removes nearby rocks and birds from the list.
    for (final obstacle in List<ReturnHomeObstacle>.of(_spawner.obstacles)) {
      if (obstacle.kind == ReturnHomeObstacleKind.log) continue;
      final touching = obstacle.hits(_cat.hitbox);
      if (touching && obstacle.frozen > 0) continue;
      if (touching && reflectTime > 0 && !_contacts.contains(obstacle)) {
        _reflect(obstacle);
        continue;
      }
      if (obstacle.kind == ReturnHomeObstacleKind.spring) {
        if (!touching) {
          _contacts.remove(obstacle);
        } else if (obstacle.springT <= 0 &&
            !_cat.dashing &&
            !_contacts.contains(obstacle)) {
          _contacts.add(obstacle);
          obstacle.springT = springShowTime;
          _cat.launchBack();
        }
        continue;
      }
      if (!touching) {
        _contacts.remove(obstacle);
      } else if (_hitCooldown <= 0 &&
          _cat.invulnerable <= 0 &&
          !_contacts.contains(obstacle)) {
        _hitCooldown = hitCooldown;
        _contacts.add(obstacle);
        if (_cat.consumeShield()) {
          _cat.bumpAwayFrom(obstacle.position);
          continue;
        }
        lives -= 1;
        _cat.bumpAwayFrom(obstacle.position);
        _cat.invulnerable = hitCooldown;
        if (lives <= 0) {
          _respawn();
          return;
        }
      }
    }
  }

  /// Phản đòn: whatever touches the cat bounces off or breaks, no damage.
  void _reflect(ReturnHomeObstacle o) {
    _contacts.add(o);
    _reflectAura.flash();
    if (o.kind == ReturnHomeObstacleKind.rock) {
      o.scare(_catCenter, 460);
      _world.add(ReturnHomeBurst(
          position: o.position.clone(), color: const Color(0xFF7FE0CF)));
      return;
    }
    _destroy(o);
  }

  /// Gusts on exposed stretches push the cat up and down the lane; the cat's own
  /// clamp keeps its paws on the road.
  void _applyWind(double dt) {
    final wind = road.windAt(_cat.bodyCenterX);
    if (wind == 0) return;
    _cat.nudge(sin(elapsed * 1.4) * sin(elapsed * .37 + 1) * wind * dt);
  }

  /// Rolling rocks that reach open water sink instead of rolling across it.
  void _sinkRocks() {
    for (final o in List<ReturnHomeObstacle>.of(_spawner.obstacles)) {
      if (o.kind != ReturnHomeObstacleKind.rock) continue;
      final p = Offset(o.position.x, o.position.y);
      if (!_crossings.any((c) => c.isWater(p)) || _onIce(p)) continue;
      _spawner.obstacles.remove(o);
      _contacts.remove(o);
      o.removeFromParent();
    }
  }

  /// A cat standing on a drifting stone drifts with it.
  void _rideStones() {
    if (_cat.dashing) return;
    for (final crossing in _crossings) {
      final dy = crossing.carryDy(_cat.hitbox);
      if (dy != 0) {
        _cat.nudge(dy);
        return;
      }
    }
  }

  void _checkWater() {
    if (_hitCooldown > 0 || _cat.dashing) return;
    final crossing = _crossings
        .where((c) => c.inWater(_cat.hitbox, dry: _onIce))
        .firstOrNull;
    if (crossing == null) return;
    _hitCooldown = hitCooldown;
    if (_cat.invulnerable <= 0 && !_cat.consumeShield()) lives -= 1;
    if (lives <= 0) {
      _respawn();
    } else {
      _respawnAt(crossing.safeBankX);
    }
  }

  void _updateCheckpoint() {
    for (final biome in road.biomes.skip(1)) {
      final x = biome.from * road.worldWidth;
      if (_cat.position.x >= x && checkpointX < x) {
        checkpointX = x;
        checkpointMessage = 1.8;
        zoneName = biome.name.toUpperCase();
        zoneSubtitle = 'Đã lưu checkpoint';
      }
    }
  }

  void _collectPickups() {
    for (final pickup in List<ReturnHomePickup>.of(_pickups)) {
      if (!pickup.hits(_cat.hitbox)) continue;
      if (pickup.kind == ReturnHomePickupKind.fish) {
        fish += 1;
      } else {
        lives = min(startingLives, lives + 1);
      }
      _pickups.remove(pickup);
      pickup.removeFromParent();
    }
  }

  void _respawn() {
    falls += 1;
    // Release the arena before respawning; the checkpoint may be outside it.
    if (bossFight) {
      _dragon!.reset();
      _dragon!.removeFromParent();
      _dragon = null;
    }
    cancelAim();
    _scratchCooldown = 0;
    lives = startingLives;
    _contacts.clear();
    _hitCooldown = 1.5;
    _respawnAt(checkpointX);
    zoneName = 'ĐÃ VỀ CHECKPOINT';
    zoneSubtitle = 'Hồi đầy mạng · tiếp tục hành trình';
    checkpointMessage = 1.8;
  }

  /// Puts the cat back on a spot that is free of logs, springs and spikes, and
  /// clears rocks and birds around it, so the player gets control right away
  /// instead of being stuck or flung again on arrival.
  void _respawnAt(double x) {
    final cx = x + _cat.size.x / 2;
    final half = road.halfWidth(cx);
    var y = road.centerY(cx) - _cat.size.y / 2;
    for (final f in const [0.0, -.5, .5, -.8, .8]) {
      final candidate = road.centerY(cx) + f * half - _cat.size.y / 2;
      final box = Rect.fromLTWH(
          x + ReturnHomeCat.hitboxLeft,
          candidate + ReturnHomeCat.hitboxTop,
          ReturnHomeCat.hitboxWidth,
          ReturnHomeCat.hitboxHeight);
      final blocked = _spawner.obstacles.any((o) =>
          o.kind != ReturnHomeObstacleKind.rock &&
          o.kind != ReturnHomeObstacleKind.bird &&
          o.kind != ReturnHomeObstacleKind.crab &&
          o.hits(box.inflate(10)));
      if (!blocked) {
        y = candidate;
        break;
      }
    }
    for (final o in List<ReturnHomeObstacle>.of(_spawner.obstacles)) {
      final moving = o.kind == ReturnHomeObstacleKind.rock ||
          o.kind == ReturnHomeObstacleKind.bird;
      if (!moving || (o.position.x - cx).abs() > size.x * .6) continue;
      _spawner.obstacles.remove(o);
      o.removeFromParent();
    }
    _contacts.clear();
    _cat.respawn(x, y: y);
  }

  /// World x as a share of the run, the same scale as [progress].
  double _runFraction(double x) {
    const start = ReturnHomeRoad.startX;
    return ((x - start) / max(1.0, road.endX - start)).clamp(0.0, 1.0);
  }

  List<RouteStop> _routeStops() => [
        for (final biome in road.biomes)
          (
            at: _runFraction(biome.from * road.worldWidth),
            color: biome.grass,
            name: biome.name,
          ),
      ];

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (!isLoaded) return;
    paintTimeStopTint(canvas, Size(size.x, size.y), timeStopTime);
    paintReturnHomeHud(
      canvas,
      size: Size(size.x, size.y),
      progress: progress,
      stops: _routeStops(),
      checkpoint: _runFraction(checkpointX),
      lives: lives,
      fish: fish,
      elapsed: elapsed,
      stars: stars,
      reward: reward,
      zone: checkpointMessage > 0 ? zoneName : null,
      finished: finished,
      zoneSubtitle: zoneSubtitle,
      zoneTimeLeft: checkpointMessage,
      padding: hudPadding,
      bossHealth: bossHealth,
      bossPhase: bossPhase,
      bossTired: bossTired,
    );
  }
}
