part of 'adventure_game.dart';

extension AdventureCombat on AdventureGame {
  Vector2? _decoyLanding(Vector2 center) {
    final halfSprite = _cat.size.x / 2;
    final minX = bossFight
        ? _arenaLeft + 6 + halfSprite
        : AdventureRoad.startX + halfSprite;
    final maxX = bossFight
        ? _dragon!.arenaBarrierX - AdventureCat.hitboxLeft - 80 + halfSprite
        : road.endX + halfSprite;
    final towardCat = _catCenter - center;
    final startAngle = atan2(towardCat.y, towardCat.x);
    // Search near the clone, validating the hitbox after the cat's lane clamp.
    for (var radius = 0.0; radius <= HomeAttack.decoy.radius; radius += 10) {
      for (var i = 0; i < (radius == 0 ? 1 : 16); i++) {
        final angle = startAngle + i * pi / 8;
        final point = center + Vector2(cos(angle), sin(angle)) * radius;
        point.x = point.x.clamp(minX, max(minX, maxX));
        final lane = road.halfWidth(point.x);
        final cy = road.centerY(point.x);
        const hitCenterY =
            AdventureCat.hitboxTop + AdventureCat.hitboxHeight / 2;
        point.y = point.y.clamp(cy - lane - _cat.size.y / 2 + hitCenterY,
            cy + lane - AdventureCat.pawLine + hitCenterY);
        if (point.distanceTo(center) > HomeAttack.decoy.radius ||
            !_blinkValid(point)) {
          continue;
        }
        final box = Rect.fromCenter(
            center: Offset(point.x, point.y),
            width: AdventureCat.hitboxWidth,
            height: AdventureCat.hitboxHeight);
        if (_spawner.obstacles.any(
            (o) => !AdventureGame._hidden(o) && !o.harmless && o.hits(box))) {
          continue;
        }
        return point;
      }
    }
    return null;
  }

  bool _blinkWithDecoy(Vector2 target, {bool triggerCombo = true}) {
    if (!_blinkValid(target)) return false;
    final from = _catCenter;
    _cat.blinkTo(target);
    _world.add(AdventureShadowStep(from: from, to: _catCenter));
    final decoy = _decoy;
    if (triggerCombo &&
        decoy != null &&
        !decoy.expired &&
        (decoy.lureCenter.distanceTo(from) <= HomeAttack.decoy.radius ||
            decoy.lureCenter.distanceTo(_catCenter) <=
                HomeAttack.decoy.radius)) {
      decoy.empowered = true;
      decoy.timeLeft = 0;
      _showCombo('ẢNH NỔ!', decoy.lureCenter, const Color(0xFFB799F2));
    }
    _contacts.clear();
    return true;
  }

  /// Fires [attack]; false if it could not be cast (no cooldown spent).
  bool _cast(HomeAttack attack, Offset? stick) {
    switch (attack) {
      case HomeAttack.fireball:
      case HomeAttack.iceShard:
        final shot = AdventureProjectile(
            position: _castOrigin,
            direction: _aimDirection(attack, stick),
            attack: attack);
        _projectiles.add(shot);
        _world.add(shot);
      case HomeAttack.flameBreath:
        final breath = AdventureFlameBreath(
            position: _castOrigin, direction: _aimDirection(attack, stick));
        _breaths.add(breath);
        _world.add(breath);
      case HomeAttack.fireBomb:
        final bomb = AdventureFireBomb(
            from: _castOrigin, target: _aimPoint(attack, stick));
        _bombs.add(bomb);
        _world.add(bomb);
      case HomeAttack.bolt:
        final bolt = AdventureBolt(
            position: _aimPoint(attack, stick), seed: _boltSeed++);
        _bolts.add(bolt);
        _world.add(bolt);
      case HomeAttack.shadowStep:
        final target = _aimPoint(attack, stick);
        return _blinkWithDecoy(target);
      case HomeAttack.decoy:
        _decoy?.removeFromParent();
        final decoy = AdventureDecoy(
            animations: _cat.animations!,
            center: _aimPoint(attack, stick),
            flip: _cat.facing < 0);
        _decoy = decoy;
        _world.add(decoy);
      case HomeAttack.timeStop:
        timeStopTime = attack.duration;
        _timeAura.start();
      case HomeAttack.frostNova:
        final center = _catCenter;
        _world.add(AdventureFrostWave(position: center));
        for (final o in _spawner.obstacles) {
          if (AdventureGame._hidden(o)) continue;
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
        final bridge = AdventureIceBridge(
            origin: _catCenter, direction: _aimDirection(attack, stick));
        _bridges.add(bridge);
        _world.add(bridge);
      case HomeAttack.roar:
        _roar();
      case HomeAttack.stoneWall:
        final target = _aimPoint(attack, stick);
        var facing = target - _catCenter;
        if (facing.length2 < 1) facing = Vector2(_facing, 0);
        final wall = AdventureStoneWall(center: target, facing: facing);
        _walls.add(wall);
        _world.add(wall);
      case HomeAttack.reflect:
        reflectTime = attack.duration;
      case HomeAttack.magnet:
        magnetTime = attack.duration;
      case HomeAttack.catEye:
        catEyeTime = attack.duration;
        _catEyeExtended = false;
    }
    return true;
  }

  void freezeOnLanding() {
    final center = _catCenter;
    const radius = 80.0;
    _world.add(AdventureFrostWave(position: center, radius: radius));
    for (final o in _spawner.obstacles) {
      if (!AdventureGame._hidden(o) &&
          o.position.distanceTo(center) <= radius) {
        o.frozen = max(o.frozen, 1.2);
        _contacts.remove(o);
      }
    }
    final boss = _boss;
    if (boss != null && boss.core.distanceTo(center) <= radius + 35) {
      boss.interrupt();
      boss.frozen = max(boss.frozen, 1.0);
    }
  }

  void shieldRecoil() => _roar();

  void extendCatEye() {
    _world.add(
        AdventureBurst(position: _catCenter, color: const Color(0xFFFFC782)));
    if (catEyeTime <= 0 || _catEyeExtended) return;
    _catEyeExtended = true;
    catEyeTime += 2;
    _showCombo('PHÚC LÀNH!', _catCenter, const Color(0xFFFFCD76));
  }

  /// Shockwave around the cat: pushes hazards in [roarRadius] away and gives
  /// a short grace window so the cat is not hit while they scatter.
  void _roar() {
    final center = _catCenter;
    _world.add(AdventureRoarWave(position: center));
    for (final o in _spawner.obstacles) {
      if (o.position.distanceTo(center) <= roarRadius) {
        o.scare(center, roarPush);
        if (reflectTime > 0 && o.kind == AdventureObstacleKind.rock) {
          _comboRocks[o] = 2.5;
          o.comboProjectile = true;
          _showCombo('GẦM PHẢN CHẤN!', o.position, const Color(0xFF8EE6CC));
        }
        _contacts.remove(o);
      }
    }
    final boss = _boss;
    if (boss != null && boss.core.distanceTo(center) <= roarRadius + 80) {
      boss.interrupt();
      _damageBoss(reflectTime > 0 ? 2 : 1, boss.core);
      if (reflectTime > 0) {
        _showCombo('GẦM PHẢN CHẤN!', boss.core, const Color(0xFF8EE6CC));
      }
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
    _comboNoticeCooldown = max(0, _comboNoticeCooldown - dt);
    for (final rock in _comboRocks.keys.toList()) {
      final left = _comboRocks[rock]! - dt;
      if (left <= 0 || rock.isRemoved) {
        rock.comboProjectile = false;
        _comboRocks.remove(rock);
      } else {
        _comboRocks[rock] = left;
      }
    }
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
  void _hurt(AdventureObstacle o) {
    o.damage += 1;
    if (o is DragonBrood) {
      if (o.damage >= 2) {
        _destroy(o);
      } else {
        GameAudio.instance.playGameplay(GameSound.homeImpact);
      }
    } else if (o.kind != AdventureObstacleKind.log || o.damage >= 2) {
      _destroy(o);
    } else {
      GameAudio.instance.playGameplay(GameSound.homeImpact);
    }
  }

  void _resolveAttacks() {
    final boss = _boss;
    for (final shot in List<AdventureProjectile>.of(_projectiles)) {
      if (!shot.icy) {
        final patch = _bombs
            .where((b) =>
                b.isMounted &&
                b.landed &&
                !b.empowered &&
                inGroundEllipse(shot.position, b.target, b.radius, margin: 0))
            .firstOrNull;
        if (patch != null && patch.ignite()) {
          _projectiles.remove(shot);
          shot.removeFromParent();
          _showCombo('BÙNG CHÁY!', patch.target, const Color(0xFFFFCA67));
          continue;
        }
      }
      if (boss != null && !shot.hitBoss && boss.hitTest(shot.hitRect)) {
        shot.hitBoss = true;
        if (shot.icy) {
          final shatter = boss.frozen > 0;
          boss
            ..frozen = shatter ? 0 : 1.2
            ..interrupt();
          _damageBoss(shatter ? 3 : 1, shot.position);
          if (shatter) {
            _world.add(AdventureBurst(
                position: shot.position.clone(),
                color: const Color(0xFFBDE8FA)));
            _showCombo('PHÁ BĂNG!', shot.position, const Color(0xFFBDE8FA));
          }
        } else {
          _damageBoss(2, shot.position);
          _projectiles.remove(shot);
          shot.removeFromParent();
          _world.add(AdventureBurst(
              position: shot.position.clone(),
              color: const Color(0xFFFF8A3A),
              fiery: true));
          continue;
        }
      }
      final hits = _spawner.obstacles
          .where((o) =>
              !AdventureGame._hidden(o) &&
              !shot.hit.contains(o) &&
              o.hits(shot.hitRect))
          .toList();
      if (shot.icy) {
        // Pierces: freezes what it touches, shatters what is already ice.
        for (final o in hits) {
          shot.hit.add(o);
          if (o.frozen > 0) {
            _showCombo('PHÁ BĂNG!', o.position, const Color(0xFFBDE8FA));
            _destroy(o, icy: true);
          } else {
            o.frozen = shot.attack.duration;
            _contacts.remove(o);
          }
        }
        if (!shot.spent) continue;
        _projectiles.remove(shot);
        shot.removeFromParent();
        _world.add(AdventureBurst(
            position: shot.position.clone(), color: const Color(0xFFBDE8FA)));
        continue;
      }
      final hit = hits.firstOrNull;
      if (hit == null && !shot.spent) continue;
      _projectiles.remove(shot);
      shot.removeFromParent();
      _world.add(AdventureBurst(
          position: shot.position.clone(),
          color: const Color(0xFFFF8A3A),
          fiery: true));
      if (hit != null) _hurt(hit);
    }

    for (final breath in List<AdventureFlameBreath>.of(_breaths)) {
      if (!breath.isMounted && !breath.blowing) {
        _breaths.remove(breath);
        continue;
      }
      if (breath.blowing) breath.position = _castOrigin;
      if (breath.blowing && _cat.sprinting) {
        for (final bomb in _bombs) {
          if (breath.covers(bomb.target) && bomb.ignite()) {
            _showCombo('BÙNG CHÁY!', bomb.target, const Color(0xFFFFCA67));
          }
        }
      }
      if (!breath.tickNow) continue;
      if (boss != null &&
          (breath.covers(boss.aimPoint) || breath.covers(boss.core))) {
        _damageBoss(1, boss.aimPoint);
      }
      for (final o in List<AdventureObstacle>.of(_spawner.obstacles)) {
        if (!AdventureGame._hidden(o) && breath.covers(o.position)) _hurt(o);
      }
    }

    for (final bomb in List<AdventureFireBomb>.of(_bombs)) {
      if (!bomb.isMounted && bomb.landed) {
        _bombs.remove(bomb);
        continue;
      }
      if (!bomb.explodeNow && !bomb.tickNow) continue;
      if (boss != null &&
          inGroundEllipse(boss.position, bomb.target, bomb.radius,
              margin: 70)) {
        // Only the blast hurts the dragon; the burning patch is for hazards.
        if (bomb.explodeNow) _damageBoss(bomb.empowered ? 6 : 3, boss.core);
      }
      for (final o in List<AdventureObstacle>.of(_spawner.obstacles)) {
        if (AdventureGame._hidden(o) || !bomb.covers(o.position)) continue;
        bomb.explodeNow ? _destroy(o) : _hurt(o);
      }
    }

    for (final bolt in List<AdventureBolt>.of(_bolts)) {
      if (!bolt.isMounted && bolt.struck) {
        _bolts.remove(bolt);
        continue;
      }
      if (!bolt.strikeNow) continue;
      final p = bolt.position;
      var markedHit = false;
      bool marked(Vector2 point) =>
          catEyeTime > 0 &&
          point.distanceTo(_catCenter) <= HomeAttack.catEye.radius + 20;
      if (boss != null &&
          inGroundEllipse(boss.position, p, boltRadius, margin: 70)) {
        markedHit = marked(boss.core);
        _damageBoss(markedHit ? 6 : 4, boss.core);
      }
      for (final o in List<AdventureObstacle>.of(_spawner.obstacles)) {
        final inColumn = o.kind == AdventureObstacleKind.bird &&
            (o.position.x - p.x).abs() < 34 &&
            o.position.y < p.y;
        if (inGroundEllipse(o.position, p, boltRadius) || inColumn) {
          markedHit = markedHit || marked(o.position);
          _destroy(o);
        }
      }
      GameAudio.instance.playGameplay(GameSound.adventureThunder, priority: 1);
      if (markedHit) {
        final slot = attacks.indexOf(HomeAttack.bolt);
        if (slot >= 0) attackCooldown[slot] = max(0, attackCooldown[slot] - 2);
        _showCombo('SÉT TINH ANH!', p, const Color(0xFFFFE497));
      }
    }

    _bridges.removeWhere((b) => b.isRemoved);
    for (final bridge in _bridges) {
      // Fresh ice also freezes whatever stands on it.
      if (bridge.frozeHazards || !bridge.built) continue;
      bridge.frozeHazards = true;
      for (final o in _spawner.obstacles) {
        if (!AdventureGame._hidden(o) &&
            o.kind != AdventureObstacleKind.bird &&
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
          AdventureObstacleKind.rock => rockRadius,
          AdventureObstacleKind.crab => 16.0,
          AdventureObstacleKind.bird => 20.0,
          _ => 0.0,
        };
        if (reach == 0) continue;
        final closest = wall.closest(o.position);
        var normal = o.position - closest;
        final distance = normal.length;
        if (distance >= reach) continue;
        if (o.kind == AdventureObstacleKind.bird) {
          if (!o.harmless) o.scare(wall.position, 0);
          continue;
        }
        normal = distance == 0
            ? (o.position - wall.position).normalized()
            : normal / distance;
        o.position += normal * (reach - distance);
        final into = o.velocity.dot(normal);
        if (into < 0) o.velocity -= normal * (1.8 * into);
        if (o.kind == AdventureObstacleKind.crab) o.velocity.y = -o.velocity.y;
      }
    }

    _resolveComboRocks();

    final decoy = _decoy;
    if (decoy != null && decoy.expired) {
      _decoy = null;
      decoy.removeFromParent();
      final center = decoy.lureCenter;
      _world.add(AdventureShadowStep(from: center, to: center));
      _world.add(
          AdventureBurst(position: center, color: const Color(0xFF7B5FC4)));
      for (final o in List<AdventureObstacle>.of(_spawner.obstacles)) {
        if (o.position.distanceTo(center) <= HomeAttack.decoy.radius) {
          if (o is DragonBrood) {
            _destroy(o);
          } else {
            o.scare(center, roarPush);
          }
        }
      }
      final boss = _boss;
      if (boss != null &&
          boss.core.distanceTo(center) <= HomeAttack.decoy.radius + 80) {
        _damageBoss(decoy.empowered ? 6 : 4, boss.core);
      }
    }
  }

  void _showCombo(String label, Vector2 at, Color color) {
    if (_comboNoticeCooldown > 0) return;
    _comboNoticeCooldown = .8;
    _world.add(AdventureDamageText(
        position: at.clone() + Vector2(0, -38), text: label, color: color));
  }

  void _resolveComboRocks() {
    for (final rock in _comboRocks.keys.toList()) {
      final boss = _boss;
      if (boss != null && boss.hitTest(rock.solidRect)) {
        _damageBoss(4, rock.position);
        _destroy(rock);
        continue;
      }
      final hit = _spawner.obstacles
          .where((o) =>
              o != rock &&
              !AdventureGame._hidden(o) &&
              !_comboRocks.containsKey(o) &&
              o.hits(rock.solidRect))
          .firstOrNull;
      if (hit != null) {
        _destroy(hit);
        _destroy(rock);
      }
    }
  }

  void _destroy(AdventureObstacle o, {bool icy = false}) {
    GameAudio.instance.playGameplay(icy
        ? GameSound.homeIce
        : switch (o.kind) {
            AdventureObstacleKind.log => GameSound.adventureWoodBreak,
            AdventureObstacleKind.rock => GameSound.adventureStoneBreak,
            _ => GameSound.homeImpact,
          });
    if (o is DragonBrood) o.dismiss();
    _spawner.obstacles.remove(o);
    _contacts.remove(o);
    _comboRocks.remove(o);
    o.comboProjectile = false;
    o.removeFromParent();
    _world.add(AdventureBurst(
      position: o.position.clone(),
      color: icy
          ? const Color(0xFFBDE8FA)
          : switch (o.kind) {
              AdventureObstacleKind.log => const Color(0xFF8A5A36),
              AdventureObstacleKind.crab => const Color(0xFFE0583F),
              AdventureObstacleKind.bird => const Color(0xFF4A5A73),
              AdventureObstacleKind.spring => const Color(0xFF8E979C),
              _ => const Color(0xFF8D9690),
            },
    ));
  }
}
