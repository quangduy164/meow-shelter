import 'dart:math';
import 'package:flame/components.dart';
import 'herd_map.dart';
import 'herd_ball.dart';
import 'herd_navigation.dart';

/// Simulation only: no rendering, input events or persistence.
class HerdCat {
  HerdCat(this.id, this.type, this.position, {this.group = 0});
  final int id;
  final int group;
  final String type;
  final Vector2 position;
  final velocity = Vector2.zero();
  bool following = false, home = false;
  double scared = 0, hop = 0, ballCooldown = 0, tumble = 0;

  /// Desert heat 0..1 and the remaining rest after overheating.
  double heat = 0, overheat = 0;

  /// Seconds left shivering after falling through thin ice.
  double chill = 0;
  bool facingLeft = false;
}

class HerdPatrol {
  HerdPatrol(this.from, this.to, this.phase, {this.trafficLight = false})
      : loops = false;
  HerdPatrol.loop(this.from, this.to, this.phase)
      : loops = true,
        trafficLight = false;
  final Vector2 from, to;
  final double phase;
  final bool loops, trafficLight;
  Vector2 position(double time) {
    if (!loops) return from + (to - from) * (.5 + .5 * sin(time + phase));
    final center = (from + to) / 2;
    final radius = (to - from) / 2;
    return center +
        Vector2(cos(time + phase) * radius.x, sin(time + phase) * radius.y);
  }

  Vector2 tangent(double time) => loops
      ? Vector2(-sin(time + phase) * (to.x - from.x),
          cos(time + phase) * (to.y - from.y))
      : Vector2(cos(time + phase), 0);
}

class HerdRound {
  HerdRound({int? seed}) : random = Random(seed);
  static const target = 12;
  static const requiredCats = 8;
  static const spacing = 25.0;
  final Random random;
  final _navigation = HerdNavigation();
  final cats = <HerdCat>[];
  final chain = <HerdCat>[];
  final trail = <Vector2>[];
  final patrols = <HerdPatrol>[];
  final balls = <HerdBall>[];
  final iceCrack = <double>[];
  final splashes = <HerdSplash>[];
  double _leaderBallCooldown = 0;
  double landingTime = 0;

  /// Market stealth state: global shout cooldown and the vendor shouting.
  double vendorCooldown = 0, shoutTime = 0;
  int? shoutingVendor;
  int _stormAnnounced = -1;
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
  bool get isTutorial => map.kind == HerdMapKind.tutorial;
  int get catCount => target;
  int get minimumToHome => isTutorial ? target : requiredCats;
  bool tutorialMoved = false;
  int get tutorialStep =>
      !tutorialMoved ? 1 : (chain.length < minimumToHome ? 2 : 3);
  String get tutorialInstruction => switch (tutorialStep) {
        1 => 'Kéo joystick để di chuyển mèo có dấu vàng.',
        2 => 'Đến gần mèo để rủ vào đàn. Đi vòng qua đá nhé!',
        _ => 'Dẫn cả đàn vào vòng sáng trước nhà.',
      };
  bool get homeUnlocked =>
      chain.length >= minimumToHome && (!isTutorial || tutorialMoved);
  bool _homeHintShown = false;

  void reset(Vector2 size) {
    field = size.clone();
    home.setFrom(map.route.point(map.route.main.last, size));
    leader.setFrom(map.route.point(map.route.main.first, size));
    _homeHintShown = false;
    tutorialMoved = false;
    velocity.setZero();
    cats.clear();
    chain.clear();
    trail.clear();
    patrols.clear();
    balls.clear();
    iceCrack
      ..clear()
      ..addAll(List.filled(map.thinIce.length, 0.0));
    splashes.clear();
    _leaderBallCooldown = 0;
    landingTime = 0;
    vendorCooldown = 0;
    shoutTime = 0;
    shoutingVendor = null;
    _stormAnnounced = -1;
    lives = 3;
    delivered = 0;
    score = 0;
    time = 0;
    immune = 0;
    started = false;
    leaderFacingLeft = false;
    notice = '';
    noticeTime = 0;
    if (map.kind == HerdMapKind.playground) {
      for (final phase in [0.0, pi]) {
        patrols.add(HerdPatrol.loop(Vector2(size.x * .49, size.y * .18),
            Vector2(size.x * .81, size.y * .50), phase));
      }
      balls.add(HerdBall(Vector2(size.x * .54, size.y * .60),
          Vector2(size.x * .90, size.y * .60), 0));
      balls.add(HerdBall(Vector2(size.x * .24, size.y * .65),
          Vector2(size.x * .51, size.y * .65), pi / 2));
    } else if (map.kind == HerdMapKind.nightMarket) {
      for (final phase in [0.0, pi]) {
        patrols.add(HerdPatrol(Vector2(size.x * .08, size.y * .53),
            Vector2(size.x * .92, size.y * .53), phase,
            trafficLight: true));
      }
    } else if (map.kind == HerdMapKind.dunes) {
      // Heat and sandstorms replace moving hazards here.
    }
    _spawnClusters();
    trail.add(leader.clone());
  }

  /// Layout notifications must not start a new run or erase a result.
  void resize(Vector2 size) {
    if (size.x <= 0 ||
        size.y <= 0 ||
        field.x <= 0 ||
        field.y <= 0 ||
        field == size) return;
    final sx = size.x / field.x, sy = size.y / field.y;
    void scale(Vector2 point) {
      point.x *= sx;
      point.y *= sy;
    }

    scale(leader);
    scale(home);
    scale(velocity);
    for (final cat in cats) {
      scale(cat.position);
      scale(cat.velocity);
    }
    for (final point in trail) {
      scale(point);
    }
    for (final patrol in patrols) {
      scale(patrol.from);
      scale(patrol.to);
    }
    for (final ball in balls) {
      scale(ball.from);
      scale(ball.to);
    }
    for (final splash in splashes) {
      scale(splash.at);
    }
    field.setFrom(size);
  }

  double patrolClock(HerdPatrol patrol) =>
      patrol.trafficLight ? map.patrolTime(time) : time;

  void message(String text, [double seconds = 2.5]) {
    notice = text;
    noticeTime = seconds;
  }

  void update(double dt, Vector2 input) {
    if (!started || ended) return;
    time += dt;
    immune = max(0, immune - dt);
    vendorCooldown = max(0, vendorCooldown - dt);
    shoutTime = max(0, shoutTime - dt);
    noticeTime = max(0, noticeTime - dt);
    _leaderBallCooldown = max(0, _leaderBallCooldown - dt);
    final direction = input.clone();
    if (direction.length > 1) direction.normalize();
    landingTime = max(0, landingTime - dt);
    final wasSliding = map.contains(map.slopes, leader, field);
    final oldLeaderX = leader.x;
    final step = _groundStep(leader, velocity, direction * 115, dt);
    // Sample every <= 4 units, so tail spacing is independent of frame rate.
    final parts = max(1, (step.length / 4).ceil());
    for (var i = 0; i < parts; i++) {
      _move(leader, step / parts.toDouble());
      if (trail.first.distanceTo(leader) >= 2) trail.insert(0, leader.clone());
    }
    if (wasSliding &&
        !map.contains(map.slopes, leader, field) &&
        map.contains(map.landings, leader, field)) {
      landingTime = .65;
    }
    if (isTutorial &&
        leader.distanceTo(map.route.point(map.route.main.first, field)) > 38) {
      tutorialMoved = true;
    }
    final leaderDx = leader.x - oldLeaderX;
    if (leaderDx.abs() > .001) leaderFacingLeft = leaderDx < 0;
    if (trail.length > 600) trail.removeRange(600, trail.length);
    for (final cat in cats) {
      cat.scared = max(0, cat.scared - dt);
      cat.hop = max(0, cat.hop - dt);
      cat.ballCooldown = max(0, cat.ballCooldown - dt);
      cat.tumble = max(0, cat.tumble - dt);
      if (!cat.home &&
          !cat.following &&
          cat.scared == 0 &&
          cat.overheat == 0 &&
          cat.chill == 0 &&
          cat.position.distanceTo(leader) < 29 &&
          _clearLine(cat.position, leader)) {
        cat.following = true;
        cat.hop = .65;
        chain.add(cat);
        if (!isTutorial) {
          message(homeUnlocked
              ? 'Đủ bạn rồi! Về nhà hoặc ghé cụm thưởng'
              : 'Đàn có ${chain.length}/$minimumToHome bạn để mở nhà');
        }
      }
    }
    for (var i = 0; i < chain.length; i++) {
      final cat = chain[i];
      final gap =
          velocity.length < 8 || landingTime > 0 ? spacing * .65 : spacing;
      final target = _followTarget(cat.position, (i + 1) * gap);
      final before = cat.position.x;
      final delta = target - cat.position;
      final desired = delta.length > 1
          ? delta.normalized() * min(145.0, delta.length * 7)
          : Vector2.zero();
      final sliding = map.contains(map.slopes, cat.position, field);
      _move(cat.position, _groundStep(cat.position, cat.velocity, desired, dt));
      if (sliding &&
          !map.contains(map.slopes, cat.position, field) &&
          map.contains(map.landings, cat.position, field)) {
        cat.tumble = .65;
        cat.hop = .4;
      }
      final dx = cat.position.x - before;
      if (dx.abs() > .001) cat.facingLeft = dx < 0;
    }
    if (immune == 0) {
      for (final patrol in patrols) {
        if (patrol.trafficLight && map.green(time)) continue;
        final p = patrol.position(patrolClock(patrol) * .7);
        if (_hitHazard(p)) break;
      }
    }
    if (!ended) _bounceBalls();
    if (!ended) _watchVendors();
    if (!ended && map.kind == HerdMapKind.dunes) _updateDesert(dt);
    if (!ended && map.thinIce.isNotEmpty) _updateIce(dt);
    final nearHome = leader.distanceTo(home) < 38;
    if (!nearHome) _homeHintShown = false;
    if (!ended && nearHome && !homeUnlocked && !_homeHintShown) {
      _homeHintShown = true;
      message('Nhà chưa mở! Đón thêm ${minimumToHome - chain.length} bạn nữa');
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
    assert(delivered + cats.where((c) => !c.home).length == catCount);
    assert(chain.toSet().length == chain.length);
  }

  bool shaded(Vector2 at) => map.contains(map.shade, at, field);

  /// Downwind of a rock, the oasis or the tent, the storm cannot push.
  bool sheltered(Vector2 at) {
    final dir = HerdSandstorm.direction(time);
    for (final wall in map.walls) {
      final r = map.pixels(wall, field);
      if (at.y < r.top - 12 || at.y > r.bottom + 12) continue;
      final gap = dir > 0 ? at.x - r.right : r.left - at.x;
      if (gap >= 0 && gap <= HerdSandstorm.shelterReach) return true;
    }
    return false;
  }

  void _updateDesert(double dt) {
    final storm = HerdSandstorm.number(time);
    if (HerdSandstorm.warning(time) && _stormAnnounced != storm) {
      _stormAnnounced = storm;
      message(HerdSandstorm.direction(time) > 0
          ? 'Bão cát từ bên trái! Nấp sau đá hoặc lều'
          : 'Bão cát từ bên phải! Nấp sau đá hoặc lều');
    }
    for (var i = 0; i < chain.length; i++) {
      final cat = chain[i];
      cat.heat = shaded(cat.position)
          ? max(0, cat.heat - HerdHeat.coolRate * dt)
          : cat.heat + HerdHeat.sunRate * (1 + i * HerdHeat.tailBonus) * dt;
    }
    final fainted = chain.where((cat) => cat.heat >= 1).toList();
    for (final cat in fainted) {
      chain.remove(cat);
      cat.following = false;
      cat.velocity.setZero();
      cat.heat = 1;
      cat.overheat = HerdHeat.faintSeconds;
    }
    if (fainted.isNotEmpty) {
      message('Có bé nóng quá phải ngồi nghỉ! Quay lại đón khi bé hết mệt');
    }
    for (final cat in cats) {
      if (cat.following) continue;
      if (cat.overheat > 0) {
        cat.overheat = max(0, cat.overheat - dt);
        cat.heat = cat.overheat / HerdHeat.faintSeconds;
      } else {
        cat.heat = max(0, cat.heat - HerdHeat.coolRate * dt);
      }
    }
  }

  bool onThinIce(Vector2 at) =>
      map.contains(map.thinIce, at, field) &&
      !map.contains(map.snowPads, at, field);

  /// Followers on one sheet beyond the safe load crack it; when it breaks,
  /// every follower on it falls in, leaves the herd and shivers on shore.
  void _updateIce(double dt) {
    for (final splash in splashes) {
      splash.age += dt;
    }
    splashes.removeWhere((s) => s.age > HerdThinIce.splashSeconds);
    for (final cat in cats) {
      if (!cat.following) cat.chill = max(0, cat.chill - dt);
    }
    for (var z = 0; z < map.thinIce.length; z++) {
      final sheet = map.pixels(map.thinIce[z], field);
      final riders = chain
          .where((cat) =>
              sheet.contains(cat.position.toOffset()) &&
              onThinIce(cat.position))
          .toList();
      final extra = riders.length - HerdThinIce.safeLoad;
      iceCrack[z] = extra > 0
          ? iceCrack[z] + extra * HerdThinIce.crackRate * dt
          : max(0, iceCrack[z] - HerdThinIce.healRate * dt);
      if (iceCrack[z] < 1) continue;
      iceCrack[z] = 0;
      for (final cat in riders) {
        chain.remove(cat);
        cat.following = false;
        cat.velocity.setZero();
        cat.chill = HerdThinIce.chillSeconds;
        cat.hop = .65;
        splashes.add(HerdSplash(cat.position.clone()));
        cat.position.setFrom(_safeSpot(cat.position, avoidThinIce: true));
      }
      message('Băng vỡ! ${riders.length} bé rơi xuống nước, đang run cầm cập');
    }
  }

  /// Vision radius shared by drawing and detection.
  double get vendorRange => min(130.0, field.y * .36);

  /// Vendor i only watches lantern zone i, so darkness always means cover.
  bool vendorSees(HerdVendor vendor, Vector2 at) {
    final zone = map.vendors.indexOf(vendor);
    if (!vendor.watching(time) ||
        map.lanternZoneAt(at, field) != zone ||
        !HerdLanterns.lit(zone, time)) {
      return false;
    }
    final origin = Vector2(vendor.at.dx * field.x, vendor.at.dy * field.y);
    final delta = at - origin;
    if (delta.length > vendorRange) return false;
    var diff = atan2(delta.y, delta.x) - vendor.angle(time);
    diff = atan2(sin(diff), cos(diff));
    return diff.abs() <= HerdVendor.halfAngle;
  }

  // Being spotted scares cats away but never costs a life.
  void _watchVendors() {
    if (vendorCooldown > 0 || map.vendors.isEmpty) return;
    for (var v = 0; v < map.vendors.length; v++) {
      final vendor = map.vendors[v];
      final from = vendorSees(vendor, leader)
          ? 0
          : chain.indexWhere((cat) => vendorSees(vendor, cat.position));
      if (from < 0 || (from == 0 && chain.isEmpty)) continue;
      _scatter(from);
      vendorCooldown = 2.5;
      shoutingVendor = v;
      shoutTime = 1.2;
      message('Bị bác bán hàng xua! Chờ bác quay đi hoặc đèn tắt nhé');
      return;
    }
  }

  bool _hitHazard(Vector2 p) {
    if (immune > 0 || ended) return false;
    if (p.distanceTo(leader) < 25) {
      lives--;
      _scatter(0);
      immune = 2;
      message(lives == 0
          ? 'Mèo đầu đàn mệt rồi!'
          : 'Va chạm! Quay lại tìm các bạn');
      return true;
    }
    final hit = chain.indexWhere((cat) => cat.position.distanceTo(p) < 24);
    if (hit < 0) return false;
    _scatter(hit);
    immune = 2;
    message('Đuôi đàn bị tản ra! Quay lại đón các bạn');
    return true;
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
            _onHazardLane(at) ||
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

  bool _onHazardLane(Vector2 at) {
    if (isTutorial) return false;
    if (map.kind == HerdMapKind.snow) {
      return onThinIce(at) ||
          map.chutes.any((c) =>
              map.pixels(c.area, field).inflate(14).contains(at.toOffset()));
    }
    if (map.kind == HerdMapKind.nightMarket || map.kind == HerdMapKind.dunes) {
      for (final patrol in patrols) {
        final segment = patrol.to - patrol.from;
        final t = segment.length2 == 0
            ? 0.0
            : ((at - patrol.from).dot(segment) / segment.length2)
                .clamp(0.0, 1.0);
        if (at.distanceTo(patrol.from + segment * t) < 31) return true;
      }
      return false;
    }
    if (map.kind != HerdMapKind.playground) {
      return (at.y - field.y * .43).abs() < 26 &&
          at.x > field.x * .22 - 26 &&
          at.x < field.x * .76 + 26;
    }
    for (final car in patrols) {
      for (var i = 0; i < 72; i++) {
        if (car.position(i * pi / 36).distanceTo(at) < 31) return true;
      }
    }
    for (final ball in balls) {
      if ((at.y - ball.from.y).abs() < 29 &&
          at.x > ball.from.x - 29 &&
          at.x < ball.to.x + 29) return true;
    }
    return false;
  }

  void _bounceBalls() {
    for (final ball in balls) {
      final p = ball.position(time);
      if (_leaderBallCooldown == 0 && leader.distanceTo(p) < 28) {
        final push = _ballPush(leader, p);
        _move(leader, push * 22);
        velocity.add(push * 120);
        _leaderBallCooldown = 1;
        trail.insert(0, leader.clone());
      }
      for (final cat in chain) {
        if (cat.ballCooldown > 0 || cat.position.distanceTo(p) >= 27) continue;
        final push = _ballPush(cat.position, p);
        _move(cat.position, push * 24);
        cat.velocity.add(push * 120);
        cat.hop = .65;
        cat.ballCooldown = 1;
      }
    }
  }

  Vector2 _ballPush(Vector2 at, Vector2 ball) {
    final push = at - ball;
    return push.length < .01 ? Vector2(0, 1) : push.normalized();
  }

  // Scared cats land on a nearby walkable spot, never across the whole map.
  Vector2 _safeSpot(Vector2 near, {bool avoidThinIce = false}) {
    for (var radius = 0.0; radius <= 140; radius += 8) {
      for (var i = 0; i < 24; i++) {
        final at = near + Vector2(cos(i * pi / 12), sin(i * pi / 12)) * radius;
        if (at.x < 24 ||
            at.x > field.x - 24 ||
            at.y < 72 ||
            at.y > field.y - 30) continue;
        if (!map.blocked(at, field) && !(avoidThinIce && onThinIce(at))) {
          return at;
        }
      }
    }
    return map.route.point(map.route.main.first, field);
  }

  Vector2 _groundStep(Vector2 at, Vector2 speed, Vector2 desired, double dt) {
    final chute = map.chuteAt(at, field);
    if (chute != null) {
      // No steering inside a chute: everyone rides it to the end.
      speed.setValues(chute.direction.dx * HerdChute.speed,
          chute.direction.dy * HerdChute.speed);
      return speed * dt;
    }
    final onIce = map.contains(map.ice, at, field) &&
        !map.contains(map.snowPads, at, field);
    final factor = 1 - exp(-(onIce ? 1.5 : 18) * dt);
    speed.add((desired - speed) * factor);
    var multiplier = map.contains(map.softSand, at, field) ? .45 : 1.0;
    final step = speed * dt * multiplier;
    if (map.contains(map.landings, at, field)) step.scale(.7);
    if (map.kind == HerdMapKind.dunes &&
        HerdSandstorm.blowing(time) &&
        !sheltered(at)) {
      step.add(
          Vector2(HerdSandstorm.direction(time) * HerdSandstorm.windSpeed, 12) *
              dt);
    }
    if (map.contains(map.slopes, at, field)) {
      step.add(Vector2(40, 75) * dt);
    }
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

  // Reach the assigned trail point through real obstacle corners, even if the
  // leader's older trail has been trimmed or the cat was pushed off the route.
  Vector2 _followTarget(Vector2 at, double distance) =>
      _navigation.nextWaypoint(map, field, at, _trailPoint(distance));

  bool _clearLine(Vector2 from, Vector2 to) =>
      _navigation.clearLine(map, field, from, to);

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
