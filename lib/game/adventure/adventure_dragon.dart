import '../../ui/design.dart';
import '../../audio/game_audio.dart';
import 'dart:math';
import 'dart:typed_data';

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import 'adventure_road.dart';
import 'adventure_dragon_brood.dart';
import 'adventure_skills.dart';

part 'adventure_dragon_art.dart';
part 'adventure_dragon_ascended_art.dart';
part 'adventure_dragon_body_art.dart';
part 'adventure_dragon_head_art.dart';
part 'adventure_dragon_attacks.dart';

/// The fire dragon guarding the lane home. It stands in front of the house on
/// the final screen; the cat must beat it to walk the last metres.
///
/// The dragon only knows its own AI and looks. It hands out attacks
/// ([attacks]) and the game decides what they hit, what blocks them and what
/// hurts the dragon, the same split as hazards and skills.
///
/// Fight rhythm: every big move is telegraphed (red zone, ground shadow), and
/// after a single move or an enraged two-move chain the dragon is tired: its
/// head drops into the lane, glows, takes extra damage and can be scratched.
class AdventureDragon extends PositionComponent {
  AdventureDragon(
      {required this.road, required Vector2 feet, required this.onSound})
      : super(position: feet, priority: 6);

  final AdventureRoad road;
  final void Function(GameSound sound) onSound;

  static const double maxHp = 50;

  /// Damage multiplier while tired.
  static const double tiredBonus = 1.5;
  static const double introTime = 2.0;
  static const double fleeTime = 2.4;
  static const double evolutionTime = 4.0;
  static const double evolutionPushTime = .35;

  double hp = maxHp;

  /// Where attacks aim: the cat, or the decoy while one stands.
  Vector2 target = Vector2.zero();

  /// Left edge of the arena (world x), set by the game.
  double arenaLeft = 0;

  /// 0 while time is stopped, < 1 inside the cat-eye slow.
  double timeScale = 1;

  /// Seconds left frozen in ice (no new moves; attacks in flight go on).
  double frozen = 0;

  /// Seconds left tired: head down in the lane, extra damage, scratchable.
  double tired = 0;

  final attacks = <DragonAttack>[];
  final brood = <DragonBrood>[];
  double _summonCooldown = 0;
  double get arenaBarrierX => position.x - 72 * _scale;
  DragonDive? get _dive => attacks.whereType<DragonDive>().firstOrNull;
  Vector2 get _diveShift => _dive?.groundOffset ?? Vector2.zero();
  double get _diveLift => _dive?.lift ?? 0;
  bool get flying => _dive?.airborne ?? false;

  double _intro = 0;
  double _death = -1;
  double _t = 0;
  double _cooldown = .8;
  _Move _move = _Move.idle;
  _Move _last = _Move.idle;
  int _lastCount = 0;
  _Move? _followUp;
  bool _evolved = false;
  double _evolutionT = -1;
  double _closeTime = 0;
  double _moveT = 0;
  int _rainLeft = 0;
  double _rainNext = 0;
  double _hurtFlash = 0;
  double _mouth = 0;
  double _jaw = 0;
  double _breath = 0;
  double _wingPhase = 0;
  double _flightBlend = 0;
  double _bodyBob = 0;
  double _bodyTurn = 0;
  double _bodyYaw = 0;
  double _headPitch = 0;
  double _castKick = 0;
  double _castSpread = 0;
  final Vector2 _bodyOffset = Vector2.zero();
  final Vector2 _head = Vector2(-62, -118);
  static final _random = Random();

  bool get intro => _intro < introTime;
  bool get defeated => _death >= 0;
  bool get gone => _death > fleeTime;
  bool get vulnerable => !intro && !defeated && !evolving && !flying;
  int get phase => _evolved ? 2 : 1;
  bool get evolving =>
      _evolutionT >= 0 && _evolutionT < evolutionPushTime + evolutionTime;
  double get _evolutionProgress =>
      ((_evolutionT - evolutionPushTime) / evolutionTime).clamp(0.0, 1.0);
  double get _evolution =>
      _evolved ? _smoothUnit((_evolutionProgress - .18) / .62) : 0;
  double get hpShare => (hp / maxHp).clamp(0.0, 1.0);

  double get _scale =>
      (road.viewportHeight / 400 * .82).clamp(.68, 1.1).toDouble();
  DragonTailSweep? get _tailMove =>
      attacks.whereType<DragonTailSweep>().firstOrNull;

  Vector2 _world(double x, double y) {
    final localX = x + _bodyOffset.x - 15;
    final local = Vector2(cos(_bodyYaw) * localX,
        y + _bodyOffset.y + 8 + sin(_bodyYaw) * localX * .32)
      ..rotate(_bodyTurn);
    return position +
        _diveShift +
        Vector2(0, _diveLift) +
        (local + Vector2(15, -8)) * _scale;
  }

  /// Head hit area and the point skills aim at.
  Rect get headRect {
    final c = _headWorld(-10, 4);
    return Rect.fromCenter(
        center: Offset(c.x, c.y),
        width: 76 * _scale * _headSize,
        height: 56 * _scale * _headSize);
  }

  Rect get bodyRect {
    final c = _world(22, -56 - 28 * _evolution);
    return Rect.fromCenter(
        center: Offset(c.x, c.y),
        width: (130 + 25 * _evolution) * _scale,
        height: (100 + 65 * _evolution) * _scale);
  }

  Vector2 get core => _world(10, -60 - 35 * _evolution);
  Vector2 get aimPoint =>
      tired > 0 ? Vector2(headRect.center.dx, headRect.center.dy) : core;
  Vector2 get mouth => _headWorld(-44 - 12 * _evolution, 14);

  double get _headSize => 1 + .12 * _evolution;
  Vector2 _headWorld(double x, double y) => _world(
      _head.x + (cos(_headPitch) * x - sin(_headPitch) * y) * _headSize,
      _head.y + (sin(_headPitch) * x + cos(_headPitch) * y) * _headSize);

  double get _fireCharge {
    for (final lane in attacks.whereType<DragonFlameLane>()) {
      if (lane.warning) return _smoothUnit(lane.t / lane.warn);
    }
    return 0;
  }

  double get _firePower {
    for (final lane in attacks.whereType<DragonFlameLane>()) {
      if (lane.burning) {
        final elapsed = lane.t - lane.warn;
        return _smoothUnit(elapsed / .1) *
            (1 - _smoothUnit((elapsed - lane.burnDuration + .14) / .14));
      }
    }
    return 0;
  }

  bool hitTest(Rect r) => r.overlaps(bodyRect) || r.overlaps(headRect);

  /// Damage after the tired bonus; returns what was really dealt (0 if
  /// immune). The game shows the number.
  double hurt(double amount) {
    if (!vulnerable || amount <= 0) return 0;
    final damage = tired > 0 ? amount * tiredBonus : amount;
    // A large hit cannot skip the protected phase transition.
    final dealt = !_evolved ? min(damage, max(0.0, hp - maxHp * .5)) : damage;
    hp = max(0, hp - dealt);
    _hurtFlash = .1;
    if (hp <= 0) {
      _death = 0;
      tired = 0;
      frozen = 0;
      _clearAttacks();
      clearBrood();
      _followUp = null;
    } else if (!_evolved && hp <= maxHp * .5) {
      _beginEvolution();
    }
    return dealt;
  }

  /// Stun from a roar or an ice shard: cancels the move being wound up.
  void interrupt() {
    if (!vulnerable) return;
    if (_dive != null && !_dive!.warning) return;
    for (final a in List<DragonAttack>.of(attacks)) {
      if (a.warning) {
        attacks.remove(a);
        a.removeFromParent();
      }
    }
    _followUp = null;
    if (_move != _Move.idle) {
      _move = _Move.idle;
      _cooldown = 1.2;
      _rainLeft = 0;
    }
    _hurtFlash = .22;
  }

  /// Back to full health after the cat falls.
  void reset() {
    hp = maxHp;
    tired = 0;
    frozen = 0;
    _move = _Move.idle;
    _last = _Move.idle;
    _lastCount = 0;
    _followUp = null;
    _evolved = false;
    _evolutionT = -1;
    _closeTime = 0;
    _cooldown = 2;
    _rainLeft = 0;
    _bodyTurn = 0;
    _bodyYaw = 0;
    _headPitch = 0;
    _castKick = 0;
    _castSpread = 0;
    _bodyOffset.setZero();
    _clearAttacks();
    clearBrood();
    _summonCooldown = 0;
  }

  void _beginEvolution() {
    onSound(GameSound.bossPhase);
    _evolved = true;
    _evolutionT = 0;
    _followUp = null;
    _move = _Move.idle;
    _rainLeft = 0;
    _castKick = 0;
    frozen = 0;
    tired = 0;
    _cooldown = .6;
    _clearAttacks();
  }

  void _clearAttacks() {
    for (final a in attacks) {
      a.removeFromParent();
    }
    attacks.clear();
  }

  void clearBrood() {
    for (final child in brood) {
      child.dismiss();
    }
    brood.clear();
  }

  void _summonBrood() {
    brood.removeWhere((b) => b.dead || b.isRemoved);
    if (brood.isNotEmpty) return;
    for (var i = 0; i < 2; i++) {
      final x = arenaLeft + (position.x - arenaLeft) * (.38 + i * .22);
      final half = road.halfWidth(x) - 30;
      final child = DragonBrood(
          road: road,
          position:
              Vector2(x, road.centerY(x) + (i == 0 ? -1 : 1) * half * .55),
          ranged: i == 1,
          left: arenaLeft,
          right: position.x - 80,
          onShoot: (from, to) {
            if (!defeated) _add(DragonEmber(from: from, target: to));
          });
      brood.add(child);
      parent?.add(child);
      parent?.add(AdventureBurst(
          position: child.position.clone(), color: const Color(0xFFF69B61)));
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    final motionDt = intro || defeated || evolving
        ? dt
        : (frozen > 0 ? 0.0 : dt * timeScale);
    _t += motionDt;
    _jaw += (_mouth - _jaw) * (1 - exp(-12 * motionDt));
    // Smooth continuous animation channels keep idle motion alive.
    _breath = sin(_t * 2.6) * .5 + .5;
    final airborne =
        (intro && _intro < 1.05) || (defeated && _death > .6) || flying;
    _flightBlend +=
        ((airborne ? 1.0 : 0.0) - _flightBlend) * (1 - exp(-5 * motionDt));
    _wingPhase = (_wingPhase + motionDt * (2.8 + 7 * _flightBlend)) % (2 * pi);
    _bodyBob = sin(_t * 2.1) * 2.2;
    _hurtFlash = max(0, _hurtFlash - dt);
    if (intro) {
      _intro += dt;
      _mouth = _intro > 1.1 && _intro < 1.8 ? 1 : 0;
      _easeHead(Vector2(-62, -124), dt);
      return;
    }
    if (defeated) {
      _death += dt;
      _mouth = 0;
      return;
    }
    frozen = max(0, frozen - dt);
    final world = evolving ? dt : dt * timeScale;
    for (final a in List<DragonAttack>.of(attacks)) {
      if (a is DragonDive) a.follow(target);
      final wasWarning = a.warning;
      a.tick(
          (a is DragonTailSweep || a is DragonDive) && frozen > 0 ? 0 : world);
      if (a is DragonFlameLane && wasWarning && !a.warning) {
        onSound(GameSound.homeFire);
      }
      if (a is DragonTailSweep && wasWarning && !a.warning) {
        onSound(GameSound.adventureTail);
      }
      if ((a is DragonMeteor && a.impactNow) ||
          (a is DragonDive && a.impactNow)) {
        onSound(GameSound.adventureLand);
      }
      if (a.done) {
        attacks.remove(a);
        a.removeFromParent();
      }
    }
    final ai = evolving ? dt : (frozen > 0 ? 0.0 : world);
    if (!_evolved && hp <= maxHp * .5) _beginEvolution();
    _summonCooldown = max(0, _summonCooldown - ai);
    brood.removeWhere((b) => b.dead || b.isRemoved);
    tired = max(0, tired - ai);
    if (target.x <= position.x - 230 * _scale) {
      _closeTime = 0;
    } else if (_move == _Move.idle && tired <= 0) {
      _closeTime += ai;
    }
    for (final lane in attacks.whereType<DragonFlameLane>()) {
      // Leave a fixed dodge window; the head and telegraph share the locked lane.
      if (ai > 0 && lane.sweepTo == null && lane.t < lane.warn - .28) {
        final half = road.halfWidth(target.x) - DragonFlameLane.halfHeight;
        final center = road.centerY(target.x);
        lane.laneY = target.y.clamp(center - half, center + half);
      }
    }
    _castKick *= exp(-18 * ai);
    final launchMeteor = _think(ai);
    final tail = _tailMove;
    final charge = _fireCharge;
    final fire = _firePower;
    final rain = _move == _Move.rain ? _smoothUnit(_moveT / .45) : 0.0;
    final roar = evolving
        ? sin(pi * _smoothUnit(_evolutionProgress))
        : (_move == _Move.summon
            ? sin(pi * (_moveT / 1.2).clamp(0.0, 1.0))
            : 0.0);
    _bodyYaw = tail?.bodyYaw ?? 0;
    final blend = 1 - exp(-16 * ai);
    final castTurn =
        -.07 * charge + .09 * fire - .1 * rain - .07 * _castKick - .16 * roar;
    _bodyTurn += ((tail?.bodyTurn ?? castTurn) - _bodyTurn) * blend;
    final shift = tail?.bodyShift ??
        Offset(7 * charge + 5 * fire + 4 * _castKick,
            4 * charge + 7 * fire - 3 * rain + 2 * _castKick - 5 * roar);
    _bodyOffset.add((Vector2(shift.dx, shift.dy) - _bodyOffset) * blend);
    _castSpread +=
        ((charge * .25 + fire * .45 + rain * .65 + roar) - _castSpread) * blend;
    final pitch = .68 * rain + .13 * _castKick - .12 * charge + .45 * roar;
    _headPitch += (pitch - _headPitch) * blend;
    if (tail != null) {
      tail.bulk = _evolution;
      tail.root.setFrom(_world(62, -32));
      tail.restClock = _t;
      tail.posedCenterline = tail.localCenterline.map((p) {
        final world = _world(p.dx, p.dy);
        return Offset(world.x, world.y);
      }).toList();
    }
    final desired = evolving
        ? Vector2(-62 + 20 * roar - 12 * _evolution,
            -118 - 52 * _evolution - 22 * roar)
        : tired > 0
            ? Vector2(-104, -36)
            : _move == _Move.breath
                ? Vector2(-74 + 22 * charge + 6 * fire,
                    _breathHeadY() - 12 * charge + sin(_t * 32) * fire * 1.5)
                : _move == _Move.rain
                    ? Vector2(-62 + 17 * rain + 7 * _castKick,
                        -118 - 52 * _evolution - 24 * rain + 4 * _castKick)
                    : tail != null
                        ? Vector2(-24 - 25 * _evolution,
                            -100 - 60 * _evolution + tail.crouch)
                        : Vector2(-62 - 12 * _evolution,
                            -118 - 52 * _evolution + sin(_t * 2.2) * 4);
    _easeHead(desired, ai);
    if (launchMeteor) _launchMeteor();
    for (final attack in attacks.whereType<DragonFlameLane>()) {
      attack
        ..emitter = mouth
        ..right = mouth.x;
    }
  }

  void _easeHead(Vector2 desired, double dt) {
    _head.add((desired - _head) * (1 - exp(-7 * dt)));
  }

  double _breathHeadY() {
    final lane = attacks.whereType<DragonFlameLane>().firstOrNull;
    final y = ((lane?.laneY ?? target.y) - position.y) / _scale - 14;
    return y.clamp(-118.0, -12.0);
  }

  // ---- AI ------------------------------------------------------------------

  bool _think(double dt) {
    if (dt <= 0) return false;
    if (evolving) {
      _evolutionT = min(evolutionPushTime + evolutionTime, _evolutionT + dt);
      _mouth = sin(pi * _smoothUnit(_evolutionProgress));
      return false;
    }
    var launchMeteor = false;
    if (_move == _Move.idle) {
      _mouth = max(0, _mouth - dt * 4);
      if (tired > 0) return false;
      _cooldown -= dt;
      if (_cooldown <= 0) {
        final queued = _followUp;
        if (queued != null) {
          _followUp = null;
          _start(queued);
        } else {
          final first = _pick();
          if (phase == 2) {
            _followUp = switch (first) {
              _Move.rain => _Move.breath,
              _Move.breath => _Move.tail,
              _Move.tail => _Move.breath,
              _Move.idle || _Move.dive || _Move.summon => null,
            };
          }
          _start(first);
        }
      }
      return false;
    }
    _moveT += dt;
    switch (_move) {
      case _Move.breath:
        final lanes = attacks.whereType<DragonFlameLane>();
        _mouth = lanes.any((l) => l.burning)
            ? 1
            : lanes.any((l) => l.warning)
                ? .35
                : 0;
        if (lanes.isEmpty) {
          _finish();
        }
      case _Move.rain:
        _mouth = .25 + .5 * _smoothUnit(_moveT / .45) + .25 * _castKick;
        _rainNext -= dt;
        if (_rainLeft > 0 && _rainNext <= 0) {
          _rainNext = .17;
          _rainLeft -= 1;
          _castKick = 1;
          launchMeteor = true;
        }
        if (_rainLeft == 0 &&
            _rainNext < -.3 &&
            (_followUp != null || !attacks.any((a) => a is DragonMeteor))) {
          _finish();
        }
      case _Move.tail:
        _mouth = .2;
        if (attacks.whereType<DragonTailSweep>().isEmpty) {
          _finish();
        }
      case _Move.dive:
        _mouth = .15;
        if (_dive == null) _finish();
      case _Move.summon:
        _mouth = _moveT < 1.2 ? 1 : 0;
        if (_moveT >= 1.2) {
          _summonBrood();
          _finish();
          _cooldown = 1.0;
        }
      case _Move.idle:
        break;
    }
    return launchMeteor;
  }

  int get _rainCount => phase == 1 ? 3 : 5;

  _Move _pick() {
    final close = target.x > position.x - 230 * _scale;
    if (phase == 2 && brood.isEmpty && _summonCooldown <= 0) {
      return _Move.summon;
    }
    if (_closeTime > 1.2 && _last != _Move.tail) return _Move.tail;
    final options = <(_Move, int)>[
      if (phase == 2 && _last != _Move.dive) (_Move.dive, close ? 3 : 6),
      if (_last != _Move.breath || _lastCount < 2)
        (_Move.breath, _last == _Move.breath ? 1 : (close ? 3 : 5)),
      if (phase == 1 && (_last != _Move.rain || _lastCount < 2))
        (_Move.rain, _last == _Move.rain ? 1 : (close ? 2 : 6)),
      if (close && (_last != _Move.tail || _lastCount < 2))
        (_Move.tail, _last == _Move.tail ? 1 : 6),
    ];
    final total = options.fold<int>(0, (s, o) => s + o.$2);
    var roll = _random.nextInt(total);
    for (final o in options) {
      roll -= o.$2;
      if (roll < 0) return o.$1;
    }
    return _Move.breath;
  }

  void _start(_Move move) {
    if (move != _Move.idle) onSound(GameSound.bossWarning);
    _move = move;
    _lastCount = move == _last ? _lastCount + 1 : 1;
    _last = move;
    _moveT = 0;
    final warn = phase == 2 ? .85 : 1.0;
    switch (move) {
      case _Move.breath:
        final center = road.centerY(target.x);
        final half = road.halfWidth(target.x);
        final side = target.y >= center ? 1.0 : -1.0;
        _add(DragonFlameLane(
            laneY: phase == 2 ? center + side * (half - 28) : target.y,
            sweepTo: phase == 2 ? center + side * 8 : null,
            left: arenaLeft,
            right: mouth.x,
            warn: warn));
      case _Move.rain:
        _rainLeft = _rainCount;
        _rainNext = .45;
      case _Move.tail:
        _closeTime = 0;
        _add(DragonTailSweep(
            road: road,
            left: position.x - 200 * _scale,
            right: position.x - 65 * _scale,
            root: _world(62, -32),
            visualScale: _scale,
            restClock: _t,
            warn: warn + .1));
      case _Move.dive:
        _add(DragonDive(
            home: position.clone(),
            road: road,
            left: arenaLeft,
            barrierX: arenaBarrierX,
            target: target));
      case _Move.summon:
        _summonCooldown = 14;
      case _Move.idle:
        break;
    }
  }

  void _launchMeteor() {
    final spot = target.clone();
    spot.x = spot.x.clamp(arenaLeft + 20, position.x - 90 * _scale);
    final half = road.halfWidth(spot.x) - DragonMeteor.radius;
    final center = road.centerY(spot.x);
    spot.y = spot.y.clamp(center - half, center + half);
    _add(DragonMeteor(
        from: mouth, target: spot, flight: phase == 2 ? 1.0 : 1.1));
  }

  void _add(DragonAttack a) {
    attacks.add(a);
    parent?.add(a);
  }

  void _finish() {
    tired = _followUp != null
        ? 0
        : (phase == 2 ? 2.0 : (_move == _Move.rain ? .8 : 1.5));
    if (tired > 0) onSound(GameSound.rescueMilestone);
    _move = _Move.idle;
    _cooldown = _followUp != null ? .35 : .6;
  }

  static const _ink = Color(0xFF4A1E14);

  @override
  void render(Canvas canvas) => _renderDragon(canvas);
}

double _smoothUnit(double value) {
  final k = value.clamp(0.0, 1.0);
  return k * k * (3 - 2 * k);
}

/// Fixed-length bones: coil at rest, unwind into the sweep, then recoil from
/// hip to tip. Rendering and collision both consume these same points.
List<Offset> _dragonTailPoints(Offset root, double scale, double clock,
    {double? attackTime, double warn = 1}) {
  final points = <Offset>[root];
  const bones = 24;
  for (var i = 0; i < bones; i++) {
    final k = i / (bones - 1);
    final rest = .35 - 2.1 * k + sin(clock * 2.4 - k * 4) * .08 * k;
    var angle = rest;
    final t = attackTime;
    if (t != null) {
      final engage = t < warn
          ? _smoothUnit(t / warn)
          : t < warn + DragonTailSweep.sweep
              ? 1.0
              : 1 -
                  _smoothUnit((t - warn - DragonTailSweep.sweep) /
                      DragonTailSweep.recovery);
      final strike = ((t - warn) / DragonTailSweep.sweep).clamp(0.0, 1.0);
      final flex = sin(strike * pi) * sin(k * pi) * .35;
      angle += (.15 - .55 * k + flex - rest) * engage;
    }
    points.add(
        points.last + Offset(cos(angle), sin(angle)) * (240 * scale / bones));
  }
  return points;
}

bool _tailSegmentHits(Offset a, Offset b, Rect box) {
  var low = 0.0, high = 1.0;
  for (var axis = 0; axis < 2; axis++) {
    final start = axis == 0 ? a.dx : a.dy;
    final delta = axis == 0 ? b.dx - a.dx : b.dy - a.dy;
    final minBound = axis == 0 ? box.left : box.top;
    final maxBound = axis == 0 ? box.right : box.bottom;
    if (delta.abs() < .00001) {
      if (start < minBound || start > maxBound) return false;
    } else {
      final t0 = (minBound - start) / delta;
      final t1 = (maxBound - start) / delta;
      low = max(low, min(t0, t1));
      high = min(high, max(t0, t1));
      if (low > high) return false;
    }
  }
  return true;
}

enum _Move { idle, breath, rain, tail, dive, summon }
