part of 'adventure_game.dart';

extension AdventureTargeting on AdventureGame {
  // ---- Secondary skills -------------------------------------------------

  bool get _canAttack => started && !finished;
  double get _facing => _cat.facing;
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
  bool canRecallDecoy(int slot) =>
      attacks[slot] == HomeAttack.decoy &&
      _decoy != null &&
      !_decoy!.expired &&
      !_decoy!.recalled;

  double attackActive(int slot) => switch (attacks[slot]) {
        HomeAttack.magnet => magnetTime,
        HomeAttack.timeStop => timeStopTime,
        HomeAttack.reflect => reflectTime,
        HomeAttack.catEye => catEyeTime,
        HomeAttack.decoy => _decoy?.timeLeft ?? 0,
        _ => 0,
      };

  /// Nearest visible hazard within [range], not behind the cat. Hidden springs
  /// stay hidden: auto-aim never gives them away.
  AdventureObstacle? _autoTarget(double range,
      {bool Function(AdventureObstacle)? only}) {
    final origin = _castOrigin;
    AdventureObstacle? best;
    var bestDistance = range;
    for (final o in _spawner.obstacles) {
      if (AdventureGame._hidden(o) || (only != null && !only(o))) continue;
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
    if (attack == HomeAttack.fireball) {
      final patch = _bombs
          .where((b) =>
              b.isMounted &&
              b.landed &&
              !b.empowered &&
              b.target.distanceTo(_castOrigin) <= attack.range &&
              (b.target.x - _castOrigin.x) * _facing >= -10)
          .firstOrNull;
      if (patch != null && patch.target.distanceTo(_castOrigin) > 1) {
        return (patch.target - _castOrigin).normalized();
      }
    }
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
            only: (o) => o.kind == AdventureObstacleKind.rock),
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
      point.x = point.x.clamp(AdventureRoad.startX, road.endX).toDouble();
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
        width: AdventureCat.hitboxWidth,
        height: AdventureCat.hitboxHeight);
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
    if (!_canAttack) return;
    // The second press shares the placement cooldown instead of restarting it.
    if (canRecallDecoy(slot)) {
      final decoy = _decoy!;
      final landing = _decoyLanding(decoy.lureCenter);
      if (landing != null && _blinkWithDecoy(landing, triggerCombo: false)) {
        decoy.recalled = true;
        GameAudio.instance.playGameplay(GameSound.homeShadow, priority: 1);
      }
      return;
    }
    if (attackCooldown[slot] > 0) return;
    final attack = attacks[slot];
    if (_cast(attack, stick)) {
      attackCooldown[slot] = attack.cooldown;
      GameAudio.instance.playGameplay(
          switch (attack) {
            HomeAttack.fireball ||
            HomeAttack.flameBreath ||
            HomeAttack.fireBomb =>
              GameSound.homeFire,
            HomeAttack.iceShard ||
            HomeAttack.frostNova ||
            HomeAttack.iceBridge =>
              GameSound.homeIce,
            HomeAttack.shadowStep ||
            HomeAttack.decoy ||
            HomeAttack.timeStop =>
              GameSound.homeShadow,
            HomeAttack.roar => GameSound.bossRoar,
            HomeAttack.stoneWall => GameSound.adventureLand,
            HomeAttack.reflect => GameSound.homeShield,
            HomeAttack.magnet ||
            HomeAttack.catEye ||
            HomeAttack.bolt =>
              GameSound.homeSupport,
          },
          priority: 1);
    }
  }
}
