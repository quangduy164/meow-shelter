import 'dart:async';
import '../../camp/camp_state.dart';
import '../cats/cat_breed.dart';
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/painting.dart';

import 'return_home_background.dart';
import 'return_home_cat.dart';
import 'return_home_crossing.dart';
import 'return_home_hud.dart';
import 'return_home_joystick.dart';
import 'return_home_obstacle.dart';
import 'return_home_pickup.dart';
import 'return_home_road.dart';
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
  String zoneName = '';
  final _pickups = <ReturnHomePickup>[];

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
    add(world);
    camera = CameraComponent(world: world);
    add(camera);
    // Keep the whole landscape viewport visible; only its X center follows
    // the cat along the longer world.
    camera.viewfinder.position = Vector2(size.x / 2, size.y / 2);
    world.add(ReturnHomeBackground(road: road));
    for (final f in [.285, .335]) {
      final crossing = ReturnHomeCrossing(road: road, centerFraction: f);
      _crossings.add(crossing);
      world.add(crossing);
    }
    _cat = ReturnHomeCat();
    world.add(_cat);
    _spawner = ReturnHomeSpawner(
      road: road,
      world: world,
      // Keep hazard density constant however long the run is.
      initialCount: (road.worldWidth / 175).round(),
    )..seed();
    _clearCrossing();
    _addPickups(world);
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
    elapsed += dt;
    checkpointMessage = max(0, checkpointMessage - dt);
    _updateCheckpoint();
    if (skillCooldown > 0) {
      skillCooldown = max(0, skillCooldown - dt);
      if (skillCooldown == 0) skillReady = true;
    }
    _hitCooldown = max(0, _hitCooldown - dt);
    final cameraX = _cat.position.x
        .clamp(size.x / 2, road.worldWidth - size.x / 2)
        .toDouble();
    final rightEdge = cameraX + size.x / 2;
    _spawner.tick(
      dt: dt,
      rightEdge: rightEdge,
      canSpawn: rightEdge < road.worldWidth - size.x * safeFinishStretch,
    );
    _contacts
        .removeAll(_spawner.cull(cameraX - size.x / 2 - _spawner.cullBehind));
    _applyWind(dt);
    _resolveHits(dt);
    resolveObstacleCollisions(_spawner.obstacles);
    _sinkRocks();
    _checkWater();
    _collectPickups();
    camera.viewfinder.position = Vector2(cameraX, size.y / 2);
    const start = ReturnHomeRoad.startX;
    progress = ((_cat.position.x - start) / max(1.0, road.endX - start))
        .clamp(0.0, 1.0);
    if (progress >= 1) {
      finished = true;
      reward = fish * 2 + stars * 10;
      unawaited(CampState.instance.addCoins(reward));
    }
  }

  /// The mode's damage rules: a log is a wall that stops forward motion, every
  /// other hazard costs a life, and one hit cannot burn several lives at once.
  void _resolveHits(double dt) {
    for (final obstacle in _spawner.obstacles) {
      obstacle.updatePhysics(dt, _cat.position.x);
    }
    // Iterate a copy: a respawn removes nearby rocks and birds from the list.
    for (final obstacle in List<ReturnHomeObstacle>.of(_spawner.obstacles)) {
      if (obstacle.kind == ReturnHomeObstacleKind.log) continue;
      final touching = obstacle.hits(_cat.hitbox);
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
      if (!_crossings.any((c) => c.isWater(p))) continue;
      _spawner.obstacles.remove(o);
      _contacts.remove(o);
      o.removeFromParent();
    }
  }

  void _checkWater() {
    if (_hitCooldown > 0 || _cat.dashing) return;
    final crossing =
        _crossings.where((c) => c.inWater(_cat.hitbox)).firstOrNull;
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
    lives = startingLives;
    _contacts.clear();
    _hitCooldown = 1.5;
    _respawnAt(checkpointX);
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
    );
  }
}
