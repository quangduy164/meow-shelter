import 'dart:async';
import '../../audio/game_audio.dart';
import '../../camp/camp_state.dart';
import '../cats/cat_breed.dart';
import '../cats/home_attack.dart';
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/painting.dart';

import 'adventure_background.dart';
import 'adventure_cat.dart';
import 'adventure_crossing.dart';
import 'adventure_dragon.dart';
import 'adventure_dragon_brood.dart';
import 'adventure_hud.dart';
import 'adventure_gate.dart';
import 'adventure_joystick.dart';
import 'adventure_obstacle.dart';
import 'adventure_pickup.dart';
import 'adventure_road.dart';
import 'adventure_skills.dart';
import 'adventure_spawner.dart';

part 'adventure_targeting.dart';
part 'adventure_combat.dart';
part 'adventure_boss_fight.dart';
part 'adventure_run_rules.dart';

/// The Adventure mode: owns the road, the hazard spawner, the cat and the run
/// state. Everything else is a collaborator that reads [road].
class AdventureGame extends FlameGame {
  AdventureGame();

  /// Lives at the start, the invulnerability window after a hit, the share of
  /// the final viewport kept free of new hazards, and the skill cooldown.
  static const int startingLives = 3;
  static const double hitCooldown = .9;
  static const double safeFinishStretch = .45;

  late AdventureJoystick joystick;
  late AdventureCat _cat;
  late AdventureSpawner _spawner;
  final _crossings = <AdventureCrossing>[];

  /// The winding lane. Resized in place, so collaborators can hold on to it.
  final AdventureRoad road = AdventureRoad();

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
  double checkpointX = AdventureRoad.startX;
  double checkpointMessage = 0;
  EdgeInsets hudPadding = EdgeInsets.zero;
  String zoneName = '';
  final _pickups = <AdventurePickup>[];
  (AdventureCrossing, int)? _standingStone;
  bool _windSoundPlayed = false;

  /// The breed's three secondary skills (see HomeAttack) and their state.
  List<HomeAttack> get attacks => CatBreed.of(selectedCat).attacks;
  final attackCooldown = List<double>.filled(3, 0);
  double magnetTime = 0;
  double timeStopTime = 0;
  double reflectTime = 0;
  double catEyeTime = 0;
  bool _catEyeExtended = false;
  final _magnet = AdventureMagnetAura();
  final _reflectAura = AdventureReflectAura();
  final _timeAura = AdventureTimeStopAura();
  late AdventureCatEyeAura _catEyeAura;
  final _projectiles = <AdventureProjectile>[];
  final _bolts = <AdventureBolt>[];
  final _breaths = <AdventureFlameBreath>[];
  final _bombs = <AdventureFireBomb>[];
  final _bridges = <AdventureIceBridge>[];
  final _walls = <AdventureStoneWall>[];
  AdventureDecoy? _decoy;
  final _aim = AdventureAimIndicator();
  Offset? _aimStick;
  late World _world;
  int _boltSeed = 0;
  final _comboRocks = <AdventureObstacle, double>{};
  double _comboNoticeCooldown = 0;

  /// Slot whose button is being held (range preview showing), if any.
  int? aimingSlot;

  /// Boss fight on the final screen (see adventure_dragon.dart).
  AdventureDragon? _dragon;
  bool bossDefeated = false;
  double _scratchCooldown = 0;
  double _bossCamera = 0;
  String zoneSubtitle = '';
  static const int bossBonus = 30;

  bool get bossFight => _dragon != null && !bossDefeated;

  /// Boss health 0..1 for the HUD, null when no fight is on.
  double? get bossHealth => bossFight ? _dragon!.hpShare : null;
  int get bossPhase => _dragon?.phase ?? 1;
  bool get bossTired => (_dragon?.tired ?? 0) > 0;

  /// The dragon when skills can hurt it.
  AdventureDragon? get _boss {
    final d = _dragon;
    return d != null && !bossDefeated && d.vulnerable ? d : null;
  }

  double get _arenaLeft => road.worldWidth - size.x;

  int get stars => 1 + (falls == 0 ? 1 : 0) + (fish >= 10 ? 1 : 0);

  double _hitCooldown = 0;
  final _contacts = <AdventureObstacle>{};

  Future<void> chooseCat(String type) async {
    if (started || _choosing) return;
    _choosing = true;
    try {
      await _cat.changeType(type);
      selectedCat = type;
      started = true;
      overlays.remove('chooseCat');
      overlays.add('skill');
    } finally {
      _choosing = false;
    }
  }

  void activateSkill() {
    if (!started || !skillReady || finished) return;
    skillReady = false;
    skillCooldown = CatBreed.of(selectedCat).homeSkill.cooldown;
    _cat.activateSkill();
    GameAudio.instance.playGameplay(
        switch (selectedCat) {
          'orange' => GameSound.homeFire,
          'himalaya' => GameSound.homeIce,
          'black' => GameSound.homeShadow,
          'scottish' => GameSound.homeShield,
          _ => GameSound.homeHeal,
        },
        priority: 1);
  }

  static bool _hidden(AdventureObstacle o) =>
      o.kind == AdventureObstacleKind.spring && o.springT <= 0;

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
      obstacle.kind == AdventureObstacleKind.log && obstacle.hits(box));

  /// Leaving the screen runs component cleanup now. Flame's image cache is
  /// shared with other screens, so this deliberately does not call [dispose].
  @override
  void onDispose() {
    removeAll(children);
    processLifecycleEvents();
    clearAdventureHudCache();
    super.onDispose();
  }

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
    world.add(AdventureBackground(road: road));
    final gate = AdventureGate();
    world.add(gate);
    world.add(gate.foreground);
    // One long crossing near the end of the stream stretch; the dry part
    // before it belongs to the crabs.
    for (final f in [.352]) {
      final crossing = AdventureCrossing(road: road, centerFraction: f);
      _crossings.add(crossing);
      world.add(crossing);
    }
    _cat = AdventureCat();
    world.add(_cat);
    world.add(_aim);
    world.add(_magnet);
    world.add(_reflectAura);
    world.add(_timeAura);
    _spawner = AdventureSpawner(
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
    _catEyeAura = AdventureCatEyeAura(obstacles: _spawner.obstacles);
    world.add(_catEyeAura);
    joystick = AdventureJoystick(position: Vector2(92, size.y - 92));
    camera.viewport.add(joystick);
  }

  void _clearCrossing() {
    for (final obstacle in List<AdventureObstacle>.of(_spawner.obstacles)) {
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
      final pickup = AdventurePickup(
        kind:
            i++ % 7 == 6 ? AdventurePickupKind.heart : AdventurePickupKind.fish,
        position:
            Vector2(x, road.centerY(x) + (random.nextDouble() * 2 - 1) * reach),
      );
      _pickups.add(pickup);
      world.add(pickup);
    }
  }

  @override
  void update(double dt) {
    // Children update before the game's timers; preserve the clone for the
    // stopped portion of this frame, including a partial final frame.
    final decoy = _decoy;
    if (decoy != null) {
      final stopped = min(dt, max(0.0, timeStopTime));
      decoy.timeScale = dt > 0 ? (dt - stopped) / dt : 1;
    }
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
    const start = AdventureRoad.startX;
    progress = ((_cat.position.x - start) / max(1.0, road.endX - start))
        .clamp(0.0, 1.0);
    if (road.hasPassedGate(_cat.hitbox) && bossDefeated) {
      progress = 1;
      finished = true;
      GameAudio.instance.playGameplay(GameSound.homeWin, priority: 3);
      reward = fish * 2 + stars * 10 + (bossDefeated ? bossBonus : 0);
      unawaited(CampState.instance.addCoins(reward));
      cancelAim();
      joystick.delta.setZero();
      overlays.remove('skill');
      overlays.remove('exit');
      overlays.add('victory');
      pauseEngine();
    }
  }

  /// World x as a share of the run, the same scale as [progress].
  double _runFraction(double x) {
    const start = AdventureRoad.startX;
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
    paintAdventureHud(
      canvas,
      size: Size(size.x, size.y),
      progress: progress,
      stops: _routeStops(),
      checkpoint: _runFraction(checkpointX),
      lives: lives,
      fish: fish,
      elapsed: elapsed,
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
