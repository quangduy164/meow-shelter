import 'dart:math';

import 'package:flame/components.dart';

import 'return_home_obstacle.dart';
import 'return_home_road.dart';

/// Owns the hazard list: seeds the opening layout, keeps rocks and birds coming
/// in from off the right edge and drops whatever has fallen behind the camera.
///
/// Every number that controls pressure is a named parameter here, so a new
/// hazard type is a `_add...` method plus one case in [seed].
class ReturnHomeSpawner {
  ReturnHomeSpawner({
    required this.road,
    required this.world,
    Random? random,
    this.initialCount = 20,
    this.initialStartX = 190,
    this.initialGap = 120,
    this.initialGapJitter = 90,
    this.initialRockSpeed = 105,
    this.rockInterval = .6,
    this.rockIntervalJitter = .7,
    this.rockSpeed = 190,
    this.rockSpawnLead = 70,
    this.birdInterval = 2.8,
    this.birdIntervalJitter = 1.8,
    this.birdSpawnLead = 120,
    this.cullBehind = 100,
  }) : random = random ?? Random(42);

  final ReturnHomeRoad road;
  final World world;
  final Random random;

  /// Opening layout: where the first hazard appears, how many, and the gap
  /// between them.
  final double initialStartX;
  final int initialCount;
  final double initialGap;
  final double initialGapJitter;
  final double initialRockSpeed;

  /// Rolling rocks that keep arriving from off the right edge.
  final double rockInterval;
  final double rockIntervalJitter;
  final double rockSpeed;
  final double rockSpawnLead;

  /// Diving birds, on their own slower clock.
  final double birdInterval;
  final double birdIntervalJitter;
  final double birdSpawnLead;

  /// How far past the left edge of view a hazard may fall before it is dropped.
  final double cullBehind;

  final obstacles = <ReturnHomeObstacle>[];
  double _rockTimer = 0;
  double _birdTimer = 2;

  void seed() {
    var x = initialStartX;
    for (var i = 0; i < initialCount; i++) {
      x += initialGap + random.nextDouble() * initialGapJitter;
      if (x > road.endX - 260) break;
      final biome = road.biomeAt(x);
      if (biome.calm) continue;
      final roll = random.nextDouble();
      if (roll < biome.spikes) {
        _addSpikes(x);
      } else if (roll < biome.spikes + biome.logs) {
        _addLog(x);
      } else if (roll < biome.spikes + biome.logs + biome.springs) {
        _addSpring(x);
      } else if (biome.rockRate > 0) {
        _addRock(x, speed: initialRockSpeed * biome.rockSpeed);
      }
    }
  }

  /// Crabs are not rolled with the other hazards: a stretch with crabs gets a
  /// steady row of them, one every [crabGap] px or so, so the player always
  /// has a few to time instead of a lone straggler. [blocked] marks x
  /// positions to keep free (crossings, respawn banks).
  void fillCrabs({required bool Function(double x) blocked}) {
    final w = road.worldWidth;
    for (var i = 0; i < road.biomes.length; i++) {
      final biome = road.biomes[i];
      if (biome.crabs <= 0) continue;
      final end = i + 1 < road.biomes.length ? road.biomes[i + 1].from : 1.0;
      for (var x = biome.from * w + 110; x < end * w - 60;) {
        final crowded = obstacles.any((o) => (o.position.x - x).abs() < 36);
        if (!blocked(x) && !crowded && random.nextDouble() < biome.crabs) {
          _addCrab(x);
        }
        x += crabGap + random.nextDouble() * 25;
      }
    }
  }

  static const double crabGap = 62;

  /// Timed pressure from the right edge, shaped by the stretch the camera is
  /// heading into. [canSpawn] keeps the final stretch of the run clear.
  void tick({
    required double dt,
    required double rightEdge,
    required bool canSpawn,
  }) {
    final biome = road.biomeAt(rightEdge);
    _rockTimer -= dt * biome.rockRate;
    if (_rockTimer <= 0) {
      _rockTimer = rockInterval + random.nextDouble() * rockIntervalJitter;
      if (canSpawn) {
        _addRock(rightEdge + rockSpawnLead, speed: rockSpeed * biome.rockSpeed);
      }
    }
    _birdTimer -= dt * biome.birdRate;
    if (_birdTimer <= 0) {
      _birdTimer = birdInterval + random.nextDouble() * birdIntervalJitter;
      if (canSpawn) _addBird(rightEdge + birdSpawnLead);
    }
  }

  /// Drops flying/rolling hazards that have fallen behind the camera and returns
  /// them, so the caller can forget any pending contact with them.
  List<ReturnHomeObstacle> cull(double leftEdge) {
    final removed = <ReturnHomeObstacle>[];
    for (final obstacle in List<ReturnHomeObstacle>.of(obstacles)) {
      final chasing = obstacle.kind == ReturnHomeObstacleKind.rock ||
          obstacle.kind == ReturnHomeObstacleKind.bird;
      if (!chasing || obstacle.position.x >= leftEdge) continue;
      obstacles.remove(obstacle);
      obstacle.removeFromParent();
      removed.add(obstacle);
    }
    return removed;
  }

  /// Spikes sit at a random depth in the lane; they are small enough that the
  /// cat can always route around them.
  void _addSpikes(double x) {
    _place(ReturnHomeObstacle(
        kind: ReturnHomeObstacleKind.spikes,
        road: road,
        position: Vector2(
            x,
            road.centerY(x) +
                _depth(road.halfWidth(x) - laneHazardClearance))));
  }

  /// Logs hug a road edge, so a blocked lane always leaves the other side free.
  void _addLog(double x) {
    final half = road.halfWidth(x);
    final obstacle = ReturnHomeObstacle(
        kind: ReturnHomeObstacleKind.log,
        road: road,
        position: Vector2(x, road.centerY(x)));
    obstacle.vertical = half * 2 - logLength >= logMinGap && random.nextBool();
    final reach = obstacle.vertical ? logReach : logHalfThickness;
    obstacle.position.y += (random.nextBool() ? 1 : -1) * (half - reach);
    _place(obstacle);
  }

  /// Hidden springs sit anywhere in the lane and fling the cat backwards.
  void _addSpring(double x) {
    _place(ReturnHomeObstacle(
        kind: ReturnHomeObstacleKind.spring,
        road: road,
        position: Vector2(
            x,
            road.centerY(x) +
                _depth(road.halfWidth(x) - laneHazardClearance))));
  }

  /// Crabs walk sideways across the whole lane at a random pace, starting at a
  /// random depth, so the player times a gap instead of just steering around.
  void _addCrab(double x) {
    final crab = ReturnHomeObstacle(
        kind: ReturnHomeObstacleKind.crab,
        road: road,
        position: Vector2(x,
            road.centerY(x) + _depth(road.halfWidth(x) - laneHazardClearance)));
    crab.velocity = Vector2(
        0, (random.nextBool() ? 1 : -1) * (60 + random.nextDouble() * 45));
    _place(crab);
  }

  void _addRock(double x, {required double speed}) {
    final rock = ReturnHomeObstacle(
        kind: ReturnHomeObstacleKind.rock,
        road: road,
        position: Vector2(x,
            road.centerY(x) + _depth(road.halfWidth(x) - rockSpawnClearance)));
    rock.velocity = Vector2(-speed - random.nextDouble() * speed * .4,
        (random.nextBool() ? 1 : -1) * (18 + random.nextDouble() * 28));
    rock.angularVelocity = (random.nextBool() ? 1 : -1) * 3.5;
    _place(rock);
  }

  void _addBird(double x) {
    final bird = ReturnHomeObstacle(
        kind: ReturnHomeObstacleKind.bird,
        road: road,
        position: Vector2(x, road.viewportHeight * birdCruiseHeight));
    bird.velocity = Vector2(-275 - random.nextDouble() * 55, 0);
    _place(bird);
  }

  /// A rock thrown into play by the dragon, rolling left from [at].
  void addRockAt(Vector2 at, {required double speed}) {
    final rock = ReturnHomeObstacle(
        kind: ReturnHomeObstacleKind.rock, road: road, position: at.clone());
    rock.velocity = Vector2(-speed, (random.nextDouble() * 2 - 1) * 60);
    rock.angularVelocity = -3.5;
    _place(rock);
  }

  /// A bird called in by the dragon.
  void addBirdAt(double x) => _addBird(x);

  double _depth(double reach) => (random.nextDouble() * 2 - 1) * reach;

  void _place(ReturnHomeObstacle obstacle) {
    obstacles.add(obstacle);
    world.add(obstacle);
  }
}
