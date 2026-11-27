part of 'adventure_game.dart';

extension AdventureBossFight on AdventureGame {
  // ---- Boss ---------------------------------------------------------------

  void _startBoss(double cameraX) {
    GameAudio.instance.playGameplay(GameSound.bossRoar, priority: 2);
    final x = road.worldWidth - 236;
    final dragon = AdventureDragon(
        road: road,
        feet: Vector2(x, road.centerY(x) + road.halfWidth(x) * .1),
        onSound: (sound) => GameAudio.instance.playGameplay(sound,
            priority: sound == GameSound.bossPhase
                ? 2
                : sound == GameSound.bossWarning ||
                        sound == GameSound.rescueMilestone
                    ? 1
                    : 0))
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
    GameAudio.instance.playGameplay(GameSound.homeImpact);
    if (dragon.evolving) _cat.invulnerable = max(_cat.invulnerable, .3);
    _world.add(AdventureDamageText(
        position: at + Vector2(0, -24),
        text: '-${dealt.round()}',
        color: dealt > amount
            ? const Color(0xFFFFE15A)
            : const Color(0xFFFFF4DA)));
  }

  void _updateBoss(double dt) {
    final dragon = _dragon;
    if (dragon == null) return;
    _spawner.obstacles
        .removeWhere((o) => o is DragonBrood && (o.dead || o.isRemoved));
    for (final child in dragon.brood) {
      if (!child.dead && !_spawner.obstacles.contains(child)) {
        _spawner.obstacles.add(child);
      }
    }
    if (dragon.gone) {
      dragon.removeFromParent();
      _dragon = null;
      return;
    }
    if (dragon.defeated) {
      if (!bossDefeated) {
        bossDefeated = true;
        GameAudio.instance.playGameplay(GameSound.bossWin, priority: 3);
        fish += 10;
        zoneName = 'Đã lưu checkpoint';
        zoneSubtitle = '';
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
    final maxX = dragon.arenaBarrierX - AdventureCat.hitboxLeft - 80;
    if (dragon.evolving) {
      final boundaryX = max(minX,
          dragon.position.x - dragon.bodyRect.width * 2.3 - _cat.size.x / 2);
      _cat.repelFromBoss(boundaryX, dt);
    }
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
            final x = w.position.x + AdventureStoneWall.thickness;
            stop = stop == null ? x : max(stop, x);
          }
        }
        attack.blockedAt = stop;
      } else if (attack is DragonEmber) {
        attack.blocked = walls
            .any((w) => w.closest(attack.point).distanceTo(attack.point) < 18);
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
      _world.add(AdventureBurst(
          position: Vector2(head.dx, head.dy), color: const Color(0xFFFFF4DA)));
      _damageBoss(2.5, Vector2(head.dx, head.dy));
    }
  }

  void _bossHitsCat(AdventureDragon dragon) {
    if (dragon.evolving) return;
    if (_cat.ignoresObstacles || _cat.invulnerable > 0 || _hitCooldown > 0) {
      return;
    }
    _hitCooldown = AdventureGame.hitCooldown;
    if (reflectTime > 0 && !(selectedCat == 'scottish' && _cat.shield)) {
      GameAudio.instance.playGameplay(GameSound.homeShield, priority: 1);
      _reflectAura.flash();
      _damageBoss(2, dragon.core);
      return;
    }
    if (_cat.consumeShield()) return;
    _cat.bumpAwayFrom(dragon.core);
    lives -= 1;
    GameAudio.instance.playGameplay(GameSound.homeHit, priority: 2);
    _cat.invulnerable = AdventureGame.hitCooldown;
    if (lives <= 0) _respawn();
  }
}
