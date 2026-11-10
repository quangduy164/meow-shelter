import 'dart:math';
import 'package:flame/components.dart';
import 'herd_map.dart';

/// Simulation only: no rendering, input events or persistence.
class HerdCat {
  HerdCat(this.id, this.type, this.position, {this.group = 0});
  final int id;
  final int group;
  final String type;
  final Vector2 position;
  final velocity = Vector2.zero();
  bool following = false, home = false;
  double scared = 0, hop = 0;
  bool facingLeft = false;
}

class HerdPatrol {
  HerdPatrol(this.from, this.to, this.phase);
  final Vector2 from, to;
  final double phase;
  Vector2 position(double time) =>
      from + (to - from) * (.5 + .5 * sin(time + phase));
}

class HerdRound {
  HerdRound({int? seed}) : random = Random(seed);
  static const target = 12;
  static const requiredCats = 8;
  static const spacing = 25.0;
  final Random random;
  final cats = <HerdCat>[];
  final chain = <HerdCat>[];
  final trail = <Vector2>[];
  final patrols = <HerdPatrol>[];
  HerdMap map = HerdMap.market;
  final leader = Vector2.zero();
  final velocity = Vector2.zero();
  final home = Vector2.zero();
  Vector2 field = Vector2.zero();
  int lives = 3, delivered = 0, score = 0;
  double time = 0, immune = 0;
  bool started = false;
  bool leaderFacingLeft = false;
  String notice = '';
  double noticeTime = 0;
  bool get won => delivered > 0;
  bool get ended => won || lives == 0;
  bool get homeUnlocked => chain.length >= requiredCats;
  bool _homeHintShown = false;

  void reset(Vector2 size) {
    field = size.clone();
    home.setFrom(map.route.point(map.route.main.last, size));
    leader.setFrom(map.route.point(map.route.main.first, size));
    _homeHintShown = false;
    velocity.setZero();
    cats.clear();
    chain.clear();
    trail.clear();
    patrols.clear();
    lives = 3;
    delivered = 0;
    score = 0;
    time = 0;
    immune = 0;
    started = false;
    leaderFacingLeft = false;
    notice = '';
    noticeTime = 0;
    _spawnClusters();
    for (var i = 0; i < 3; i++) {
      final y = size.y * .43;
      patrols.add(HerdPatrol(
          Vector2(size.x * .22, y), Vector2(size.x * .76, y), i * 2.1));
    }
    trail.add(leader.clone());
  }

  void message(String text) {
    notice = text;
    noticeTime = 2.5;
  }

  void update(double dt, Vector2 input) {
    if (!started || ended) return;
    time += dt;
    immune = max(0, immune - dt);
    noticeTime = max(0, noticeTime - dt);
    final direction = input.clone();
    if (direction.length > 1) direction.normalize();
    final oldLeaderX = leader.x;
    final step = _groundStep(leader, velocity, direction * 115, dt);
    // Sample every <= 4 units, so tail spacing is independent of frame rate.
    final parts = max(1, (step.length / 4).ceil());
    for (var i = 0; i < parts; i++) {
      _move(leader, step / parts.toDouble());
      if (trail.first.distanceTo(leader) >= 2) trail.insert(0, leader.clone());
    }
    final leaderDx = leader.x - oldLeaderX;
    if (leaderDx.abs() > .001) leaderFacingLeft = leaderDx < 0;
    if (trail.length > 600) trail.removeRange(600, trail.length);
    for (final cat in cats) {
      cat.scared = max(0, cat.scared - dt);
      cat.hop = max(0, cat.hop - dt);
      if (!cat.home &&
          !cat.following &&
          cat.scared == 0 &&
          cat.position.distanceTo(leader) < 29) {
        cat.following = true;
        cat.hop = .65;
        chain.add(cat);
        message(homeUnlocked
            ? 'Đủ bạn rồi! Về nhà hoặc ghé cụm thưởng'
            : 'Đàn có ${chain.length}/$requiredCats bạn để mở nhà');
      }
    }
    for (var i = 0; i < chain.length; i++) {
      final cat = chain[i];
      final gap = velocity.length < 8 ? spacing * .65 : spacing;
      final target = _followTarget(cat.position, (i + 1) * gap);
      final before = cat.position.x;
      final delta = target - cat.position;
      final desired = delta.length > 1
          ? delta.normalized() * min(145.0, delta.length * 7)
          : Vector2.zero();
      _move(cat.position, _groundStep(cat.position, cat.velocity, desired, dt));
      final dx = cat.position.x - before;
      if (dx.abs() > .001) cat.facingLeft = dx < 0;
    }
    if (immune == 0 &&
        !(map.kind == HerdMapKind.nightMarket && map.green(time))) {
      for (final patrol in patrols) {
        final p = patrol.position(map.patrolTime(time) * .7);
        if (p.distanceTo(leader) < 25) {
          lives--;
          _scatter(0);
          immune = 2;
          message(lives == 0
              ? 'Mèo đầu đàn mệt rồi!'
              : 'Va chạm! Quay lại tìm các bạn');
          break;
        }
        final hit = chain.indexWhere((cat) => cat.position.distanceTo(p) < 24);
        if (hit >= 0) {
          _scatter(hit);
          immune = 2;
          message('Đuôi đàn bị tản ra! Quay lại đón các bạn');
          break;
        }
      }
    }
    final nearHome = leader.distanceTo(home) < 38;
    if (!nearHome) _homeHintShown = false;
    if (!ended && nearHome && !homeUnlocked && !_homeHintShown) {
      _homeHintShown = true;
      message('Nhà chưa mở! Đón thêm ${requiredCats - chain.length} bạn nữa');
    }
    if (!ended && nearHome && homeUnlocked) {
      final count = chain.length;
      for (final cat in chain) {
        cat.home = true;
        cat.following = false;
      }
      delivered += count;
      score += count * 10 + count * (count - 1) * 2;
      chain.clear();
      trail.clear();
      trail.add(leader.clone());
      message('Đã dẫn $count bạn về nhà!');
    }
    assert(delivered + cats.where((c) => !c.home).length == target);
    assert(chain.toSet().length == chain.length);
  }

  /// Three cats per authored stop: small jitter, no walls, overlap or traffic.
  void _spawnClusters() {
    const types = ['orange', 'himalaya', 'scottish', 'calico', 'black'];
    for (var group = 0; group < map.route.groups.length; group++) {
      final center = map.route.point(map.route.groups[group], field);
      List<Vector2>? spots;
      final start = random.nextInt(24);
      for (var attempt = 0; attempt < 48; attempt++) {
        final rotate = (start + attempt % 24) * pi / 12;
        final angles =
            attempt < 24 ? [0.0, pi / 2, pi] : [0.0, 2 * pi / 3, 4 * pi / 3];
        final proposed = angles
            .map((angle) =>
                center +
                Vector2(cos(angle + rotate), sin(angle + rotate)) * 25 +
                Vector2((random.nextDouble() - .5) * 1.2,
                    (random.nextDouble() - .5) * 1.2))
            .toList();
        if (proposed.any((at) =>
            map.blocked(at, field) ||
            at.y < 72 ||
            at.y > field.y - 30 ||
            ((at.y - field.y * .43).abs() < 26 &&
                at.x > field.x * .22 - 26 &&
                at.x < field.x * .76 + 26) ||
            cats.any((cat) => cat.position.distanceTo(at) < 25))) continue;
        spots = proposed;
        break;
      }
      if (spots == null) {
        throw StateError('No safe spawn in ${map.name}, group $group');
      }
      for (final spot in spots) {
        final id = cats.length;
        cats.add(HerdCat(id, types[id % types.length], spot, group: group));
      }
    }
  }

  // Scared cats land on a nearby walkable spot, never across the whole map.
  Vector2 _safeSpot(Vector2 near) {
    for (var radius = 0.0; radius <= 140; radius += 8) {
      for (var i = 0; i < 24; i++) {
        final at = near + Vector2(cos(i * pi / 12), sin(i * pi / 12)) * radius;
        if (at.x < 24 ||
            at.x > field.x - 24 ||
            at.y < 72 ||
            at.y > field.y - 30) continue;
        if (!map.blocked(at, field)) return at;
      }
    }
    return map.route.point(map.route.main.first, field);
  }

  Vector2 _groundStep(Vector2 at, Vector2 speed, Vector2 desired, double dt) {
    final onIce = map.contains(map.ice, at, field);
    final factor = 1 - exp(-(onIce ? 1.5 : 18) * dt);
    speed.add((desired - speed) * factor);
    var multiplier = map.contains(map.softSand, at, field) ? .45 : 1.0;
    final step = speed * dt * multiplier;
    if (map.contains(map.slopes, at, field)) step.add(Vector2(28, 48) * dt);
    return step;
  }

  void _move(Vector2 at, Vector2 step) {
    // Axis sliding lets both the leader and the tail skirt the same wall.
    final pieces = max(1, (step.length / 4).ceil());
    final part = step / pieces.toDouble();
    for (var i = 0; i < pieces; i++) {
      final x = Vector2((at.x + part.x).clamp(24, field.x - 24), at.y);
      if (!map.blocked(x, field)) at.setFrom(x);
      final y = Vector2(at.x, (at.y + part.y).clamp(66, field.y - 30));
      if (!map.blocked(y, field)) at.setFrom(y);
    }
  }

  // Follow the recorded route around corners instead of cutting across stalls.
  Vector2 _followTarget(Vector2 at, double distance) {
    final target = _trailPoint(distance);
    if (_clearLine(at, target)) return target;
    var nearest = -1;
    var best = double.infinity;
    for (var i = 0; i < trail.length; i++) {
      final d = at.distanceToSquared(trail[i]);
      if (d < best && _clearLine(at, trail[i])) {
        nearest = i;
        best = d;
      }
    }
    if (nearest < 0) return at.clone();
    for (var i = max(0, nearest - 6); i < nearest; i++) {
      if (_clearLine(at, trail[i])) return trail[i];
    }
    return trail[nearest];
  }

  bool _clearLine(Vector2 from, Vector2 to) {
    final steps = max(1, (from.distanceTo(to) / 6).ceil());
    for (var i = 1; i <= steps; i++) {
      if (map.blocked(from + (to - from) * (i / steps), field)) return false;
    }
    return true;
  }

  Vector2 _trailPoint(double distance) {
    for (var i = 1; i < trail.length; i++) {
      final length = trail[i - 1].distanceTo(trail[i]);
      if (length >= distance && length > 0) {
        return trail[i - 1] + (trail[i] - trail[i - 1]) * (distance / length);
      }
      distance -= length;
    }
    return trail.last.clone();
  }

  void _scatter(int from) {
    for (final cat in chain.skip(from)) {
      cat.following = false;
      cat.velocity.setZero();
      cat.scared = 2;
      cat.position.add(Vector2(
          (random.nextDouble() - .5) * 65, (random.nextDouble() - .5) * 65));
      cat.position.x = cat.position.x.clamp(30, field.x - 30);
      cat.position.y = cat.position.y.clamp(75, field.y - 35);
      if (map.blocked(cat.position, field)) {
        cat.position.setFrom(_safeSpot(cat.position));
      }
    }
    chain.removeRange(from, chain.length);
  }
}
