import 'dart:math';
import 'dart:ui' show Offset, Rect;
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
  HerdTrait trait = HerdTrait.normal;

  /// Sleepy cats: wake progress 0..1; awake once it reaches 1.
  double wake = 0;
  bool get awake => trait != HerdTrait.sleepy || wake >= 1;

  /// Curious cats: seconds until the next run-off, the run-off time left
  /// and where it is heading.
  double itch = 0, distracted = 0;
  final wanderTo = Vector2.zero();

  /// Grandma's house: Bé Mập stuck in a cat flap, or a curious cat playing
  /// with a lure instead of chasing a butterfly.
  double stuck = 0;
  bool lured = false;

  /// Lures this cat already played with; they no longer pull it away.
  final playedWith = <int>{};

  /// Station: Bé Nhát Gan running to cover, hiding there, and coax progress.
  bool fleeing = false, hidden = false;
  double coax = 0, calm = 0;

  /// Farm: the plate this cat is holding down, a short pause before it may
  /// sit on a plate again, and Bé Hay Dỗi's sulk.
  int? plate;
  double plateCooldown = 0;

  /// A sitter only gets up once the leader has walked off and come back.
  bool plateReady = false;
  bool sulking = false;
  bool introduced = false;
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

enum HerdSound {
  joined,
  ready,
  locked,
  hit,
  scattered,
  bounced,
  vendor,
  storm,
  overheated,
  iceWarning,
  iceBreak,
  cuckoo,
  stuck,
  horn,
  doors,
}

class HerdRound {
  HerdRound({int? seed, this.onSound}) : random = Random(seed);
  final void Function(HerdSound sound)? onSound;
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
  int _stormAnnounced = -1, _cuckooRung = -1, _hornHeard = -1;
  int? _openStop;

  /// Farm gate state per pen, and how long each plate rests after pickup.
  final gateOpen = <bool>[];
  final plateRest = <double>[];
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
    _cuckooRung = -1;
    _hornHeard = -1;
    _openStop = null;
    gateOpen
      ..clear()
      ..addAll(List.filled(map.pens.length, false));
    plateRest
      ..clear()
      ..addAll(List.filled(map.pens.length, 0.0));
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
        field == size) {
      return;
    }
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
    for (final cat in cats) {
      scale(cat.wanderTo);
    }
    field.setFrom(size);
  }

  double patrolClock(HerdPatrol patrol) =>
      patrol.trafficLight ? map.patrolTime(time) : time;

  void message(String text, [double seconds = 2.5]) {
    // Only the opening map hint is shown on screen; status messages must not
    // cut it short.
    if (notice == map.hint && noticeTime > 0) return;
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
    if (map.track != null) _carryTrain(dt);
    final wasFollowing = chain.toSet();
    if (map.pens.isNotEmpty) _updateGates(dt);
    final direction = input.clone();
    if (direction.length > 1) direction.normalize();
    landingTime = max(0, landingTime - dt);
    final wasSliding = map.contains(map.slopes, leader, field);
    final oldLeaderX = leader.x;
    final heavy = chain.any((c) => c.trait == HerdTrait.chubby)
        ? HerdTraits.chubbyLeaderFactor
        : 1.0;
    final step = _groundStep(leader, velocity, direction * 115 * heavy, dt);
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
    _wakeSleepers(dt);
    if (map.track != null) _station(dt);
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
          cat.distracted == 0 &&
          cat.awake &&
          !cat.hidden &&
          !cat.sulking &&
          (cat.plate == null || cat.plateReady) &&
          cat.position.distanceTo(leader) < 29 &&
          _clearLine(cat.position, leader)) {
        cat.following = true;
        cat.hop = .65;
        cat.lured = false;
        if (cat.plate != null) {
          plateRest[cat.plate!] = HerdPlate.restSeconds;
          cat.plate = null;
          cat.plateCooldown = HerdPlate.rejoinCooldown;
        }
        final wasUnlocked = homeUnlocked;
        chain.add(cat);
        onSound?.call(
            !wasUnlocked && homeUnlocked ? HerdSound.ready : HerdSound.joined);
        if (cat.trait == HerdTrait.curious) {
          cat.itch =
              HerdTraits.itchMin + random.nextDouble() * HerdTraits.itchSpread;
        }
        if (cat.trait != HerdTrait.normal && !cat.introduced) {
          cat.introduced = true;
          message(_introduce(cat.trait), 3.5);
        } else if (!isTutorial) {
          message(homeUnlocked
              ? 'Đủ bạn rồi! Về nhà hoặc ghé cụm thưởng'
              : 'Đàn có ${chain.length}/$minimumToHome bạn để mở nhà');
        }
      }
    }
    final jammed = <HerdCat>[];
    for (var i = 0; i < chain.length; i++) {
      final cat = chain[i];
      final from = cat.position.clone();
      final gap =
          velocity.length < 8 || landingTime > 0 ? spacing * .65 : spacing;
      final target = _followTarget(cat.position, (i + 1) * gap);
      final before = cat.position.x;
      final delta = target - cat.position;
      final desired = delta.length > 1
          ? delta.normalized() *
              min(
                  cat.trait == HerdTrait.chubby
                      ? HerdTraits.chubbySpeed
                      : 145.0,
                  delta.length * 7)
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
      if (cat.trait == HerdTrait.chubby &&
          map.contains(map.catFlaps, cat.position, field)) {
        cat.position.setFrom(from);
        jammed.add(cat);
      }
    }
    for (final cat in jammed) {
      _jamInFlap(cat);
    }
    if (!ended) _wander(dt);
    if (!ended && map.cuckooRoom != null) _cuckoo();
    if (!ended && immune == 0) _bumpRobots();
    if (!ended && map.pens.isNotEmpty) _sitOnPlates();
    if (!ended && map.pens.isNotEmpty) _sulk(dt);
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
      onSound?.call(HerdSound.locked);
      message('Nhà chưa mở! Đón thêm ${minimumToHome - chain.length} bạn nữa');
    }
    if (!ended && nearHome && homeUnlocked) {
      final count = chain.length;
      for (final cat in chain) {
        cat.home = true;
        cat.following = false;
      }
      final golden = chain.where((c) => c.trait == HerdTrait.golden).length;
      delivered += count;
      score += count * 10 +
          count * (count - 1) * 2 +
          golden * HerdTraits.goldenBonus;
      chain.clear();
      trail.clear();
      trail.add(leader.clone());
      message(golden > 0
          ? 'Đã dẫn $count bạn về nhà! Bé Vàng +${HerdTraits.goldenBonus * golden} điểm'
          : 'Đã dẫn $count bạn về nhà!');
    }
    for (final cat in wasFollowing) {
      if (cat.trait == HerdTrait.sulky &&
          !cat.following &&
          !cat.home &&
          !cat.sulking) {
        cat.sulking = true;
        cat.coax = 0;
        message('Bé Hay Dỗi giận rồi! Đuổi theo đứng cạnh để dỗ');
      }
    }
    assert(delivered + cats.where((c) => !c.home).length == catCount);
    assert(chain.toSet().length == chain.length);
  }

  String _introduce(HerdTrait trait) => switch (trait) {
        HerdTrait.chubby => map.thinIce.isNotEmpty
            ? 'Bé Mập vào đàn! Đi chậm, lên băng mỏng nặng bằng hai bé'
            : map.kind == HerdMapKind.dunes
                ? 'Bé Mập vào đàn! Đi chậm và mau nóng hơn'
                : 'Bé Mập vào đàn! Cả đàn đi chậm lại một chút',
        HerdTrait.curious =>
          'Bé Tò Mò vào đàn! Thấy dấu ! là bé sắp chạy theo bướm',
        HerdTrait.sleepy => 'Bé Ngủ Say dậy rồi! Đi thôi',
        HerdTrait.golden =>
          'Bé Vàng vào đàn! Đưa bé về nhà để được thêm ${HerdTraits.goldenBonus} điểm',
        HerdTrait.shy => 'Bé Nhát Gan vào đàn! Coi chừng tiếng còi tàu',
        HerdTrait.sulky =>
          'Bé Hay Dỗi vào đàn! Đừng bỏ rơi bé, bé giận lâu lắm',
        HerdTrait.normal => '',
      };

  Rect? get trackRect =>
      map.track == null ? null : map.pixels(map.track!, field);

  /// The whole train in pixels, or null on maps without one.
  Rect? trainAt(double t) => map.track == null
      ? null
      : map.pixels(HerdTrain.rect(t, map.track!), field);

  bool _inCar(Rect? car, Vector2 p) =>
      car != null &&
      Rect.fromLTRB(car.left + 8, car.top, car.right - 8, car.bottom)
          .contains(p.toOffset());

  bool inTrain(Vector2 p) => _inCar(trainAt(time), p);
  bool onTrack(Vector2 p) => trackRect?.contains(p.toOffset()) ?? false;

  /// Walls, plus the rails: inside the train only while its doors are open,
  /// and no way out of it while it is moving.
  bool _solid(Vector2 p, bool riding) {
    if (map.blocked(p, field)) return true;
    for (var i = 0; i < map.pens.length; i++) {
      if (!gateOpen[i] &&
          map
              .pixels(map.pens[i].gate, field)
              .inflate(15)
              .contains(p.toOffset())) {
        return true;
      }
    }
    if (map.track == null) return false;
    final open = HerdTrain.open(time);
    if (riding && !open) return !inTrain(p);
    return onTrack(p) && !(inTrain(p) && (open || riding));
  }

  bool _offLimits(Vector2 p) => map.blocked(p, field) || onTrack(p);

  /// Which side of the rails a point is on; the hall splits the upper side.
  int _zone(Vector2 p) {
    if (inTrain(p)) return 0;
    final track = trackRect!;
    if (p.y > track.center.dy) return 3;
    return p.x < field.x / 2 ? 1 : 2;
  }

  void _carryTrain(double dt) {
    final before = trainAt(time - dt), after = trainAt(time);
    if (before == null || after == null) return;
    final dx = after.center.dx - before.center.dx;
    if (dx == 0 || dx.abs() > 40) return;
    if (_inCar(before, leader)) leader.x += dx;
    for (final cat in cats) {
      if (!cat.home && _inCar(before, cat.position)) cat.position.x += dx;
    }
  }

  void _station(double dt) {
    final stop = HerdTrain.stop(time);
    if (stop != null && _openStop == null) onSound?.call(HerdSound.doors);
    if (_openStop != null && stop == null) _depart(_openStop!);
    _openStop = stop;
    final horn = HerdTrain.horn(time);
    if (horn != null && horn != _hornHeard) {
      _hornHeard = horn;
      _blowHorn(horn.isEven ? HerdTrain.westX : HerdTrain.eastX);
    }
    for (final cat in cats) {
      cat.calm = max(0, cat.calm - dt);
      if (!cat.hidden) continue;
      final near = cat.position.distanceTo(leader) < 32 &&
          _clearLine(cat.position, leader);
      cat.coax = near
          ? min(1, cat.coax + dt / HerdShy.coaxSeconds)
          : max(0, cat.coax - dt);
      if (cat.coax >= 1) {
        cat.hidden = false;
        cat.coax = 0;
        cat.calm = HerdShy.calmSeconds;
        cat.hop = .65;
        message('Bé Nhát Gan hết sợ rồi, đi tiếp thôi!');
      }
    }
  }

  /// Doors close: riders stay aboard only with the leader; everyone else is
  /// put off on the nearer platform, and followers on another side than the
  /// leader are left behind. The east stop is the end of the line.
  void _depart(int stop) {
    final leaderAboard = stop == 0 && inTrain(leader);
    void putOff(Vector2 p) {
      final track = trackRect!;
      final up = (p.y - track.top) < (track.bottom - p.y);
      final off = Vector2(p.x, up ? track.top - 16 : track.bottom + 16);
      p.setFrom(_offLimits(off) ? _safeSpot(off) : off);
    }

    if (!leaderAboard && inTrain(leader)) {
      putOff(leader);
      trail
        ..clear()
        ..add(leader.clone());
    }
    for (final cat in cats) {
      if (cat.home || !inTrain(cat.position)) continue;
      if (!leaderAboard) putOff(cat.position);
    }
    final side = _zone(leader);
    final left = chain.where((c) => _zone(c.position) != side).toList();
    for (final cat in left) {
      chain.remove(cat);
      cat.following = false;
      cat.velocity.setZero();
    }
    if (left.isNotEmpty) {
      onSound?.call(HerdSound.scattered);
      message('Tàu chạy rồi! ${left.length} bé bị bỏ lại sân ga');
    } else if (stop == 1) {
      message('Ga cuối! Mời cả đàn xuống tàu');
    }
  }

  /// The horn sends every Bé Nhát Gan in earshot running to the nearest
  /// bench on its own side of the rails.
  void _blowHorn(double stopX) {
    onSound?.call(HerdSound.horn);
    final source = Vector2(stopX * field.x, trackRect!.center.dy);
    var ran = 0;
    for (final cat in cats) {
      if (cat.trait != HerdTrait.shy ||
          cat.home ||
          cat.hidden ||
          cat.fleeing ||
          cat.calm > 0 ||
          cat.position.distanceTo(source) > HerdShy.hearing * field.x) {
        continue;
      }
      final zone = _zone(cat.position);
      Vector2? best;
      for (final spot in map.hideSpots) {
        final p = _px(spot);
        if (zone != 0 && _zone(p) != zone) continue;
        if (best == null ||
            p.distanceTo(cat.position) < best.distanceTo(cat.position)) {
          best = p;
        }
      }
      if (cat.following) chain.remove(cat);
      cat.following = false;
      cat.velocity.setZero();
      cat.fleeing = true;
      cat.lured = false;
      cat.coax = 0;
      cat.hop = .5;
      cat.distracted = 3;
      cat.wanderTo.setFrom(best ?? cat.position);
      ran++;
    }
    if (ran > 0) message('Tuuu! Bé Nhát Gan sợ quá chạy đi trốn');
  }

  /// Bé Mập cannot squeeze through: it pops back out and leaves the herd.
  void _jamInFlap(HerdCat cat) {
    chain.remove(cat);
    cat.following = false;
    cat.velocity.setZero();
    cat.tumble = .65;
    cat.stuck = 1.6;
    cat.distracted = 1.2;
    Rect? flap;
    for (final f in map.catFlaps) {
      final box = map.pixels(f, field).inflate(14);
      if (box.contains(cat.position.toOffset())) flap = box;
    }
    final side = flap == null || cat.position.x < flap.center.dx ? -1.0 : 1.0;
    final back = cat.position + Vector2(side * 30, 0);
    cat.wanderTo.setFrom(map.blocked(back, field) ? cat.position : back);
    onSound?.call(HerdSound.stuck);
    message('Bé Mập kẹt ở cửa mèo! Đi cửa lớn với bé nhé');
  }

  Vector2 _px(Offset fraction) =>
      Vector2(fraction.dx * field.x, fraction.dy * field.y);

  List<Vector2> get robotPositions => [
        for (final loop in map.robots)
          () {
            final p = HerdRobot.at(map.pixels(loop, field), time);
            return Vector2(p.dx, p.dy);
          }()
      ];

  /// The robot vacuum scatters the herd but never costs a life.
  List<Vector2> get goosePositions => [
        for (final flock in map.geese)
          for (var k = 0; k < HerdGoose.flock; k++) _px(flock.at(time, k))
      ];

  Vector2 platePoint(int i) => _px(map.pens[i].plate);

  /// Whether cat [c] (or the leader when null) can push plate [i] down.
  bool _presses(int i, HerdCat? c) =>
      !map.pens[i].heavy || (c != null && c.trait == HerdTrait.chubby);

  /// Gates open while their plate is down or someone stands in the gap.
  /// Closing shuts in whoever is on the other side from the leader.
  void _updateGates(double dt) {
    for (var i = 0; i < map.pens.length; i++) {
      plateRest[i] = max(0, plateRest[i] - dt);
      final plate = platePoint(i);
      bool on(Vector2 p) => p.distanceTo(plate) < HerdPlate.radius;
      final pressed = (on(leader) && _presses(i, null)) ||
          cats.any((c) => !c.home && on(c.position) && _presses(i, c));
      final gap = map.pixels(map.pens[i].gate, field).inflate(14);
      final area = map.pixels(map.pens[i].area, field);
      // Never shut on the herd: the gate waits for every follower inside.
      final busy = gap.contains(leader.toOffset()) ||
          cats.any((c) => !c.home && gap.contains(c.position.toOffset())) ||
          chain.any((c) => area.contains(c.position.toOffset()));
      final open = pressed || busy;
      if (open != gateOpen[i]) onSound?.call(HerdSound.doors);
      gateOpen[i] = open;
      if (open) continue;
      final leaderIn = area.contains(leader.toOffset());
      final shut = chain
          .where((c) => area.contains(c.position.toOffset()) != leaderIn)
          .toList();
      for (final cat in shut) {
        chain.remove(cat);
        cat.following = false;
        cat.velocity.setZero();
      }
      if (shut.isNotEmpty) {
        message('Cổng đóng mất rồi! ${shut.length} bé bị nhốt lại');
      }
    }
    for (final cat in cats) {
      cat.plateCooldown = max(0, cat.plateCooldown - dt);
      if (cat.plate != null && cat.position.distanceTo(leader) > 70) {
        cat.plateReady = true;
      }
    }
  }

  /// The first follower to step on a free plate sits down and holds it.
  void _sitOnPlates() {
    for (var i = 0; i < map.pens.length; i++) {
      if (plateRest[i] > 0 || cats.any((c) => c.plate == i)) continue;
      final plate = platePoint(i);
      final sitter = chain
          .where((c) =>
              c.trait != HerdTrait.sulky &&
              c.plateCooldown == 0 &&
              _presses(i, c) &&
              c.position.distanceTo(plate) < HerdPlate.radius - 2)
          .firstOrNull;
      if (sitter == null) continue;
      chain.remove(sitter);
      sitter.following = false;
      sitter.velocity.setZero();
      sitter.position.setFrom(plate);
      sitter.plate = i;
      sitter.plateReady = false;
      sitter.hop = .5;
      message(map.pens[i].heavy
          ? 'Bé Mập ngồi đè bàn đạp, cổng chuồng gà mở rồi!'
          : 'Một bé ngồi giữ bàn đạp, cổng mở rồi! Nhớ quay lại đón bé');
    }
  }

  /// Bé Hay Dỗi backs away from the leader until coaxed.
  void _sulk(double dt) {
    for (final cat in cats) {
      if (!cat.sulking || cat.home) continue;
      final away = cat.position - leader;
      final near =
          away.length < HerdSulk.coaxRange && _clearLine(cat.position, leader);
      if (away.length < HerdSulk.avoidRange && away.length > .01) {
        final before = cat.position.x;
        _move(cat.position, away.normalized() * HerdSulk.walkSpeed * dt);
        cat.facingLeft = cat.position.x < before;
      }
      cat.coax = near
          ? min(1, cat.coax + dt / HerdSulk.coaxSeconds)
          : max(0, cat.coax - dt * .5);
      if (cat.coax >= 1) {
        cat.sulking = false;
        cat.coax = 0;
        cat.hop = .65;
        message('Bé Hay Dỗi hết giận rồi!');
      }
    }
  }

  void _bumpRobots() {
    final geese = goosePositions;
    for (final p in [...robotPositions, ...geese]) {
      final hitLeader = p.distanceTo(leader) < 25;
      final hit = hitLeader
          ? 0
          : chain.indexWhere((cat) => cat.position.distanceTo(p) < 24);
      if (hit < 0 || (hitLeader && chain.isEmpty)) continue;
      for (final cat in chain.skip(hit)) {
        cat.tumble = .65;
      }
      _scatter(hit);
      immune = 1.5;
      onSound?.call(HerdSound.scattered);
      message(geese.contains(p)
          ? 'Quác quác! Ngỗng đuổi cả đàn chạy tán loạn'
          : 'Robot hút bụi húc trúng! Đàn chạy tán loạn');
      return;
    }
  }

  /// Every ring wakes the sleepy cats in the living room at once.
  void _cuckoo() {
    if (!HerdCuckoo.ringing(time)) return;
    final ring = HerdCuckoo.number(time);
    if (ring == _cuckooRung) return;
    _cuckooRung = ring;
    final room = map.pixels(map.cuckooRoom!, field);
    var woke = 0;
    for (final cat in cats) {
      if (cat.awake || cat.home || !room.contains(cat.position.toOffset())) {
        continue;
      }
      cat.wake = 1;
      cat.hop = .65;
      woke++;
    }
    onSound?.call(HerdSound.cuckoo);
    if (woke > 0) message('Cúc cu! Bé Ngủ Say giật mình tỉnh dậy');
  }

  /// The leader must stay beside a sleepy cat until it wakes up.
  void _wakeSleepers(double dt) {
    for (final cat in cats) {
      if (cat.awake || cat.home || cat.following) continue;
      final near = cat.position.distanceTo(leader) < 29 &&
          _clearLine(cat.position, leader);
      if (near && cat.wake == 0 && !isTutorial) {
        message('Bé Ngủ Say đang ngáy... đứng cạnh để gọi bé dậy');
      }
      cat.wake = near
          ? min(1, cat.wake + dt / HerdTraits.wakeSeconds)
          : max(0, cat.wake - HerdTraits.dozeRate * dt);
    }
  }

  /// Curious followers run off after a butterfly now and then.
  void _wander(double dt) {
    for (final cat in cats) {
      if (cat.distracted > 0 && !cat.following) {
        cat.distracted = max(0, cat.distracted - dt);
        final delta = cat.wanderTo - cat.position;
        final speed = cat.fleeing ? HerdShy.runSpeed : HerdTraits.wanderSpeed;
        if (delta.length > 2) {
          final before = cat.position.x;
          _move(
              cat.position, delta.normalized() * min(delta.length, speed * dt));
          cat.facingLeft = cat.position.x < before;
        }
        if (cat.fleeing && (delta.length <= 2 || cat.distracted == 0)) {
          cat.fleeing = false;
          cat.hidden = true;
          cat.distracted = 0;
        }
      }
    }
    for (final cat in cats) {
      cat.stuck = max(0, cat.stuck - dt);
    }
    for (final cat in chain.toList()) {
      if (cat.trait != HerdTrait.curious) continue;
      Vector2? lure;
      for (var k = 0; k < map.lures.length; k++) {
        final p = _px(map.lures[k]);
        if (!cat.playedWith.contains(k) &&
            p.distanceTo(cat.position) < HerdLure.radius) {
          lure = p;
          cat.playedWith.add(k);
          break;
        }
      }
      if (lure != null) {
        // Straight to the yarn or the fish dish, no warning.
        final toward = cat.position - lure;
        final spot = lure +
            (toward.length < .01 ? Vector2(0, 1) : toward.normalized()) * 14;
        _leaveFor(cat, map.blocked(spot, field) ? cat.position.clone() : spot,
            lured: true);
        message('Bé Tò Mò bị cuộn len, đĩa cá dụ mất rồi!');
        continue;
      }
      if (onThinIce(cat.position) ||
          map.chuteAt(cat.position, field) != null ||
          leader.distanceTo(home) < 110) {
        continue;
      }
      cat.itch = max(0, cat.itch - dt);
      if (cat.itch > 0) continue;
      final spot = _wanderSpot(cat.position);
      if (spot == null) {
        cat.itch = 1;
        continue;
      }
      _leaveFor(cat, spot);
      message('Bé Tò Mò chạy theo bướm rồi! Quay lại đón bé nhé');
    }
  }

  void _leaveFor(HerdCat cat, Vector2 spot, {bool lured = false}) {
    chain.remove(cat);
    cat.following = false;
    cat.velocity.setZero();
    cat.hop = .5;
    cat.lured = lured;
    cat.distracted = lured ? 2.4 : HerdTraits.wanderSeconds;
    cat.wanderTo.setFrom(spot);
    onSound?.call(HerdSound.scattered);
  }

  Vector2? _wanderSpot(Vector2 from) {
    final start = random.nextInt(12);
    for (var i = 0; i < 12; i++) {
      final angle = (start + i) * pi / 6;
      final at =
          from + Vector2(cos(angle), sin(angle)) * HerdTraits.wanderDistance;
      if (at.x < 30 ||
          at.x > field.x - 30 ||
          at.y < 75 ||
          at.y > field.y - 35 ||
          _offLimits(at) ||
          onThinIce(at) ||
          map.chuteAt(at, field) != null ||
          !_clearLine(from, at)) {
        continue;
      }
      return at;
    }
    return null;
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
      onSound?.call(HerdSound.storm);
      message(HerdSandstorm.direction(time) > 0
          ? 'Bão cát từ bên trái! Nấp sau đá hoặc lều'
          : 'Bão cát từ bên phải! Nấp sau đá hoặc lều');
    }
    for (var i = 0; i < chain.length; i++) {
      final cat = chain[i];
      cat.heat = shaded(cat.position)
          ? max(0, cat.heat - HerdHeat.coolRate * dt)
          : cat.heat +
              HerdHeat.sunRate *
                  (1 + i * HerdHeat.tailBonus) *
                  (cat.trait == HerdTrait.chubby ? HerdTraits.chubbyHeat : 1) *
                  dt;
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
      onSound?.call(HerdSound.overheated);
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
      final load = riders.fold<int>(
          0,
          (sum, cat) =>
              sum +
              (cat.trait == HerdTrait.chubby ? HerdTraits.chubbyIceWeight : 1));
      final extra = load - HerdThinIce.safeLoad;
      final previousCrack = iceCrack[z];
      iceCrack[z] = extra > 0
          ? iceCrack[z] + extra * HerdThinIce.crackRate * dt
          : max(0, iceCrack[z] - HerdThinIce.healRate * dt);
      if (previousCrack < HerdThinIce.warnAt &&
          iceCrack[z] >= HerdThinIce.warnAt) {
        onSound?.call(HerdSound.iceWarning);
      }
      if (iceCrack[z] < 1) continue;
      iceCrack[z] = 0;
      onSound?.call(HerdSound.iceBreak);
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
      onSound?.call(HerdSound.vendor);
      message('Bị bác bán hàng xua! Chờ bác quay đi hoặc đèn tắt nhé');
      return;
    }
  }

  bool _hitHazard(Vector2 p) {
    if (immune > 0 || ended) return false;
    if (p.distanceTo(leader) < 25) {
      lives--;
      onSound?.call(HerdSound.hit);
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
    onSound?.call(HerdSound.scattered);
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
            cats.any((cat) => cat.position.distanceTo(at) < 25))) {
          continue;
        }
        spots = proposed;
        break;
      }
      if (spots == null) {
        throw StateError('No safe spawn in ${map.name}, group $group');
      }
      for (final spot in spots) {
        final id = cats.length;
        final cat = HerdCat(id, types[id % types.length], spot, group: group);
        final index = spots.indexOf(spot);
        if (group < map.specials.length && index < map.specials[group].length) {
          cat.trait = map.specials[group][index];
        }
        cats.add(cat);
      }
    }
  }

  bool _onHazardLane(Vector2 at) {
    if (isTutorial) return false;
    if (map.track != null) {
      return map.pixels(map.track!, field).inflate(20).contains(at.toOffset());
    }
    if (map.pens.isNotEmpty) {
      for (var i = 0; i < map.pens.length; i++) {
        if (platePoint(i).distanceTo(at) < 40 ||
            map
                .pixels(map.pens[i].gate, field)
                .inflate(20)
                .contains(at.toOffset())) {
          return true;
        }
      }
      for (final flock in map.geese) {
        final a = _px(flock.from), b = _px(flock.to);
        final d = b - a;
        final t = ((at - a).dot(d) / d.length2).clamp(0.0, 1.0);
        if (at.distanceTo(a + d * t) < 36) return true;
      }
      return false;
    }
    if (map.robots.isNotEmpty) {
      return map.robots.any((loop) =>
          HerdRobot.distanceToLoop(map.pixels(loop, field), at.toOffset()) <
          34);
    }
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
          at.x < ball.to.x + 29) {
        return true;
      }
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
        onSound?.call(HerdSound.bounced);
        trail.insert(0, leader.clone());
      }
      for (final cat in chain) {
        if (cat.ballCooldown > 0 || cat.position.distanceTo(p) >= 27) continue;
        final push = _ballPush(cat.position, p);
        _move(cat.position, push * 24);
        cat.velocity.add(push * 120);
        cat.hop = .65;
        cat.ballCooldown = 1;
        onSound?.call(HerdSound.bounced);
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
            at.y > field.y - 30) {
          continue;
        }
        if (!_offLimits(at) && !(avoidThinIce && onThinIce(at))) {
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
    final riding = map.track != null && inTrain(at);
    for (var i = 0; i < pieces; i++) {
      final x = Vector2((at.x + part.x).clamp(24, field.x - 24), at.y);
      if (!_solid(x, riding)) at.setFrom(x);
      final y = Vector2(at.x, (at.y + part.y).clamp(66, field.y - 30));
      if (!_solid(y, riding)) at.setFrom(y);
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
      if (_offLimits(cat.position)) {
        cat.position.setFrom(_safeSpot(cat.position));
      }
    }
    chain.removeRange(from, chain.length);
  }
}
