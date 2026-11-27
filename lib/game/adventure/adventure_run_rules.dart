part of 'adventure_game.dart';

extension AdventureRunRules on AdventureGame {
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
    for (final obstacle in List<AdventureObstacle>.of(_spawner.obstacles)) {
      if (obstacle.kind == AdventureObstacleKind.log) continue;
      if (obstacle is DragonBrood &&
          (!obstacle.hatched ||
              obstacle.dead ||
              obstacle.age < DragonBrood.hatchTime + .6)) {
        continue;
      }
      final touching = obstacle.hits(_cat.hitbox);
      if (_comboRocks.containsKey(obstacle)) continue;
      if (touching && obstacle.frozen > 0) continue;
      if (touching &&
          reflectTime > 0 &&
          !_contacts.contains(obstacle) &&
          !(selectedCat == 'scottish' && _cat.shield)) {
        _reflect(obstacle);
        continue;
      }
      if (obstacle.kind == AdventureObstacleKind.spring) {
        if (!touching) {
          _contacts.remove(obstacle);
        } else if (obstacle.springT <= 0 &&
            !_cat.ignoresObstacles &&
            !_contacts.contains(obstacle)) {
          _contacts.add(obstacle);
          obstacle.springT = springShowTime;
          GameAudio.instance
              .playGameplay(GameSound.adventureSpring, priority: 1);
          _cat.launchBack();
        }
        continue;
      }
      if (!touching) {
        _contacts.remove(obstacle);
      } else if (_hitCooldown <= 0 &&
          _cat.invulnerable <= 0 &&
          !_cat.phasing &&
          !_contacts.contains(obstacle)) {
        _hitCooldown = AdventureGame.hitCooldown;
        _contacts.add(obstacle);
        if (_cat.consumeShield()) {
          if (selectedCat != 'scottish') _cat.bumpAwayFrom(obstacle.position);
          continue;
        }
        lives -= 1;
        GameAudio.instance.playGameplay(GameSound.homeHit, priority: 2);
        _cat.bumpAwayFrom(obstacle.position);
        _cat.invulnerable = AdventureGame.hitCooldown;
        if (lives <= 0) {
          _respawn();
          return;
        }
      }
    }
  }

  /// Phản đòn: whatever touches the cat bounces off or breaks, no damage.
  void _reflect(AdventureObstacle o) {
    GameAudio.instance.playGameplay(GameSound.homeShield, priority: 1);
    _contacts.add(o);
    _reflectAura.flash();
    if (o.kind == AdventureObstacleKind.rock) {
      o.scare(_catCenter, 460);
      _world.add(AdventureBurst(
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
    if (!_windSoundPlayed &&
        (sin(elapsed * 1.4) * sin(elapsed * .37 + 1)).abs() > .7) {
      _windSoundPlayed = true;
      GameAudio.instance.playGameplay(GameSound.moonCloud);
    }
    _cat.nudge(sin(elapsed * 1.4) * sin(elapsed * .37 + 1) * wind * dt);
  }

  /// Rolling rocks that reach open water sink instead of rolling across it.
  void _sinkRocks() {
    for (final o in List<AdventureObstacle>.of(_spawner.obstacles)) {
      if (o.kind != AdventureObstacleKind.rock) continue;
      final p = Offset(o.position.x, o.position.y);
      if (!_crossings.any((c) => c.isWater(p)) || _onIce(p)) continue;
      if ((o.position.x - _cat.bodyCenterX).abs() < size.x * .5) {
        GameAudio.instance.playGameplay(GameSound.rescueSplash);
      }
      _spawner.obstacles.remove(o);
      _contacts.remove(o);
      o.removeFromParent();
    }
  }

  /// A cat standing on a drifting stone drifts with it.
  void _rideStones() {
    if (_cat.ignoresObstacles) {
      _standingStone = null;
      return;
    }
    (AdventureCrossing, int)? contact;
    for (final crossing in _crossings) {
      final stone = crossing.stoneUnder(_cat.hitbox);
      if (stone >= 0) contact = (crossing, stone);
      final dy = crossing.carryDy(_cat.hitbox);
      if (dy != 0) {
        _cat.nudge(dy);
        break;
      }
    }
    if (contact != null && contact != _standingStone) {
      GameAudio.instance.playGameplay(GameSound.homeImpact);
    }
    _standingStone = contact;
  }

  void _checkWater() {
    if (_hitCooldown > 0 || _cat.ignoresObstacles) return;
    final crossing = _crossings
        .where((c) => c.inWater(_cat.hitbox, dry: _onIce))
        .firstOrNull;
    if (crossing == null) return;
    GameAudio.instance.playGameplay(GameSound.homeSplash, priority: 2);
    _hitCooldown = AdventureGame.hitCooldown;
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
        GameAudio.instance.playGameplay(GameSound.homeCheckpoint, priority: 2);
        checkpointMessage = 1.8;
        zoneName = 'Đã lưu checkpoint';
        zoneSubtitle = '';
      }
    }
  }

  void _collectPickups() {
    for (final pickup in List<AdventurePickup>.of(_pickups)) {
      if (!pickup.hits(_cat.hitbox)) continue;
      if (pickup.kind == AdventurePickupKind.fish) {
        fish += 1;
        GameAudio.instance.playGameplay(GameSound.catEat);
      } else {
        lives = min(AdventureGame.startingLives, lives + 1);
        GameAudio.instance.playGameplay(GameSound.homeHeal, priority: 1);
      }
      _pickups.remove(pickup);
      pickup.removeFromParent();
    }
  }

  void _respawn() {
    GameAudio.instance.playGameplay(GameSound.homeRespawn, priority: 3);
    falls += 1;
    // Release the arena before respawning; the checkpoint may be outside it.
    if (bossFight) {
      _dragon!.reset();
      _dragon!.removeFromParent();
      _dragon = null;
    }
    cancelAim();
    for (final rock in _comboRocks.keys) {
      rock.comboProjectile = false;
    }
    _comboRocks.clear();
    _spawner.obstacles.removeWhere((o) {
      if (o is DragonBrood) {
        o.dismiss();
        return true;
      }
      return false;
    });
    _decoy?.removeFromParent();
    _decoy = null;
    _comboNoticeCooldown = 0;
    _scratchCooldown = 0;
    lives = AdventureGame.startingLives;
    _contacts.clear();
    _hitCooldown = 1.5;
    _respawnAt(checkpointX);
    zoneName = '';
    zoneSubtitle = '';
    checkpointMessage = 0;
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
          x + AdventureCat.hitboxLeft,
          candidate + AdventureCat.hitboxTop,
          AdventureCat.hitboxWidth,
          AdventureCat.hitboxHeight);
      final blocked = _spawner.obstacles.any((o) =>
          o.kind != AdventureObstacleKind.rock &&
          o.kind != AdventureObstacleKind.bird &&
          o.kind != AdventureObstacleKind.crab &&
          o.hits(box.inflate(10)));
      if (!blocked) {
        y = candidate;
        break;
      }
    }
    for (final o in List<AdventureObstacle>.of(_spawner.obstacles)) {
      final moving = o.kind == AdventureObstacleKind.rock ||
          o.kind == AdventureObstacleKind.bird;
      if (!moving || (o.position.x - cx).abs() > size.x * .6) continue;
      _spawner.obstacles.remove(o);
      o.removeFromParent();
    }
    _contacts.clear();
    _cat.respawn(x, y: y);
  }
}
