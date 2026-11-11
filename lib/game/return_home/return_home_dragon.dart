import 'dart:math';
import 'dart:typed_data';

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import 'return_home_road.dart';
import 'return_home_skills.dart';

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
class ReturnHomeDragon extends PositionComponent {
  ReturnHomeDragon({required this.road, required Vector2 feet})
      : super(position: feet, priority: 6);

  final ReturnHomeRoad road;

  static const double maxHp = 50;

  /// Damage multiplier while tired.
  static const double tiredBonus = 1.5;
  static const double introTime = 2.0;
  static const double fleeTime = 2.4;
  static const double evolutionTime = 1.8;
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
  bool get vulnerable => !intro && !defeated && !evolving;
  int get phase => _evolved ? 2 : 1;
  bool get evolving =>
      _evolutionT >= 0 && _evolutionT < evolutionPushTime + evolutionTime;
  double get _evolutionProgress =>
      ((_evolutionT - evolutionPushTime) / evolutionTime).clamp(0.0, 1.0);
  double get _evolution => _evolved ? _smoothUnit(_evolutionProgress) : 0;
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
    return position + (local + Vector2(15, -8)) * _scale;
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
            (1 - _smoothUnit((elapsed - DragonFlameLane.burn + .14) / .14));
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
      _followUp = null;
    } else if (!_evolved && hp <= maxHp * .5) {
      _beginEvolution();
    }
    return dealt;
  }

  /// Stun from a roar or an ice shard: cancels the move being wound up.
  void interrupt() {
    if (!vulnerable) return;
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
  }

  void _beginEvolution() {
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
    final airborne = (intro && _intro < 1.05) || (defeated && _death > .6);
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
      a.tick(a is DragonTailSweep && frozen > 0 ? 0 : world);
      if (a.done) {
        attacks.remove(a);
        a.removeFromParent();
      }
    }
    final ai = evolving ? dt : (frozen > 0 ? 0.0 : world);
    if (!_evolved && hp <= maxHp * .5) _beginEvolution();
    tired = max(0, tired - ai);
    _closeTime = target.x > position.x - 230 * _scale ? _closeTime + ai : 0;
    for (final lane in attacks.whereType<DragonFlameLane>()) {
      // Leave a fixed dodge window; the head and telegraph share the locked lane.
      if (ai > 0 && lane.t < lane.warn - .28) {
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
    final roar = evolving ? sin(pi * _smoothUnit(_evolutionProgress)) : 0.0;
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
              _Move.tail => _Move.rain,
              _Move.idle => null,
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
      case _Move.idle:
        break;
    }
    return launchMeteor;
  }

  int get _rainCount => phase == 1 ? 3 : 5;

  _Move _pick() {
    final close = target.x > position.x - 230 * _scale;
    if (_closeTime > 1.2 && _last != _Move.tail) return _Move.tail;
    final options = <(_Move, int)>[
      if (_last != _Move.breath || _lastCount < 2)
        (_Move.breath, _last == _Move.breath ? 1 : (close ? 3 : 5)),
      if (_last != _Move.rain || _lastCount < 2)
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
    _move = move;
    _lastCount = move == _last ? _lastCount + 1 : 1;
    _last = move;
    _moveT = 0;
    final warn = phase == 2 ? .85 : 1.0;
    switch (move) {
      case _Move.breath:
        _add(DragonFlameLane(
            laneY: target.y, left: arenaLeft, right: mouth.x, warn: warn));
      case _Move.rain:
        _rainLeft = _rainCount;
        _rainNext = .45;
      case _Move.tail:
        _add(DragonTailSweep(
            road: road,
            left: position.x - 200 * _scale,
            right: position.x - 65 * _scale,
            root: _world(62, -32),
            visualScale: _scale,
            restClock: _t,
            warn: warn + .1));
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
    _move = _Move.idle;
    _cooldown = _followUp != null ? .35 : .6;
  }

  // ---- Look ------------------------------------------------------------------

  @override
  void render(Canvas canvas) {
    var lift = 0.0, drift = 0.0, shrink = 1.0;
    if (intro) {
      final k = (_intro / 1.1).clamp(0.0, 1.0);
      lift = -380 * pow(1 - k, 2).toDouble();
    }
    if (defeated) {
      final k = ((_death - .7) / (fleeTime - .7)).clamp(0.0, 1.0);
      lift = -420 * k * k;
      drift = 260 * k;
      shrink = 1 - .5 * k;
    }
    final shake =
        (defeated && _death < .7) || (intro && _intro > 1.1 && _intro < 1.8)
            ? sin(_t * 70) * 3
            : 0.0;
    canvas.save();
    // Shadow stays on the ground while the dragon flies.
    final shadowK = 1 - min(1.0, -lift / 380);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(drift * _scale + 10 * _scale, 2),
            width: 200 * _scale * shadowK,
            height: 34 * _scale * shadowK),
        Paint()
          ..color = Color.fromARGB((70 * shadowK).round(), 0x30, 0x10, 0x08));
    canvas.translate(drift * _scale + shake, lift + _bodyBob * shadowK);
    canvas.scale(_scale * shrink);
    if (evolving) _paintEvolutionBurst(canvas);
    if (intro && _intro > 1.0 && _intro < 1.5) {
      _landingDust(canvas, (_intro - 1) / .5);
    }
    final tail = _tailMove;
    canvas.save();
    canvas.translate(15, -8);
    canvas.rotate(_bodyTurn);
    // Ground-plane yaw keeps the dragon upright while its whole body turns.
    canvas.transform(Float64List.fromList([
      cos(_bodyYaw),
      sin(_bodyYaw) * .32,
      0,
      0,
      0,
      1,
      0,
      0,
      0,
      0,
      1,
      0,
      0,
      0,
      0,
      1,
    ]));
    canvas.translate(-15 + _bodyOffset.x, 8 + _bodyOffset.y);
    // The tail and hip share this transform. Drawing the root underneath the
    // torso hides the seam at every angle, including the edge-on spin pose.
    _paintTail(
        canvas,
        tail?.localCenterline ??
            _dragonTailPoints(const Offset(62, -32), 1, _t));
    final profile = _smoothUnit((cos(_bodyYaw).abs() - .08) / .42);
    if (profile > 0) {
      if (profile < 1) {
        canvas.saveLayer(
            null,
            Paint()
              ..color = Color.fromARGB((255 * profile).round(), 255, 255, 255));
      }
      _paintBody(canvas);
      if (tired > 0 && !defeated) _paintDizzy(canvas);
      if (frozen > 0) _paintIce(canvas);
      if (profile < 1) canvas.restore();
    }
    canvas.restore();
    if (profile < 1) _paintTurnedBody(canvas, 1 - profile);
    canvas.restore();
  }

  /// Front/back silhouettes bridge the two profiles, preserving body volume
  /// at quarter turns instead of squeezing a side-view drawing to a line.
  void _paintTurnedBody(Canvas canvas, double opacity) {
    if (_evolution >= .5) {
      _paintAscendedTurnedBody(canvas, opacity);
      return;
    }
    final front = sin(_bodyYaw) > 0;
    canvas.saveLayer(
        null,
        Paint()
          ..color = Color.fromARGB((255 * opacity).round(), 255, 255, 255));
    canvas.translate(15, -8);
    canvas.rotate(_bodyTurn);
    canvas.translate(-15 + cos(_bodyYaw) * _bodyOffset.x,
        8 + _bodyOffset.y + sin(_bodyYaw) * _bodyOffset.x * .32);
    for (final side in [-1.0, 1.0]) {
      canvas.save();
      canvas.translate(15, 0);
      canvas.scale(side * .62, .78);
      _wing(canvas, const Offset(0, -91), side * .07, 1,
          const Color(0xFFCD4C38), const Color(0xFFE88B4B));
      canvas.restore();
    }
    final body = Path()
      ..moveTo(-15 - 12 * _evolution, -79)
      ..quadraticBezierTo(15, -102 - 16 * _evolution, 45 + 12 * _evolution, -79)
      ..lineTo(43, -29)
      ..quadraticBezierTo(15, -5, -13, -29)
      ..close();
    _shape(canvas, body,
        front ? const Color(0xFFE45B40) : const Color(0xFFB94130));
    if (front) {
      final belly = Path()
        ..moveTo(15, -85)
        ..quadraticBezierTo(38, -62, 32, -32)
        ..quadraticBezierTo(15, -18, -2, -32)
        ..quadraticBezierTo(-8, -62, 15, -85)
        ..close();
      _shape(canvas, belly, const Color(0xFFFFD98A));
      for (var i = 0; i < 4; i++) {
        final y = -68.0 + i * 11;
        canvas.drawArc(
            Rect.fromCenter(center: Offset(15, y), width: 30, height: 9),
            .2,
            2.7,
            false,
            Paint()
              ..color = _c(const Color(0xFFCC9958))
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.8);
      }
    } else {
      for (var row = 0; row < 4; row++) {
        final y = -77.0 + row * 12;
        for (final side in [-1.0, 1.0]) {
          _shape(
              canvas,
              Path()
                ..addPolygon([
                  Offset(15 + side * 8, y - 5),
                  Offset(15 + side * 21, y),
                  Offset(15 + side * 8, y + 6),
                ], true),
              const Color(0xFFE28C48));
        }
        _shape(
            canvas,
            Path()
              ..addPolygon([
                Offset(10, y + 2),
                Offset(15, y - 12 - 10 * _evolution),
                Offset(20, y + 2),
              ], true),
            const Color(0xFFFFBA47));
      }
    }
    _paintEvolutionArmor(canvas, turned: true);
    for (final side in [-1.0, 1.0]) {
      final x = 15 + side * 22;
      _shape(
          canvas,
          Path()
            ..addPolygon([
              Offset(x - 8, -29),
              Offset(x + 8, -29),
              Offset(x + 11, -2),
              Offset(x - 11, -2),
            ], true),
          const Color(0xFFD25338));
      for (var i = 0; i < 3; i++) {
        final c = x - 7 + i * 7.0;
        _shape(
            canvas,
            Path()
              ..addPolygon([
                Offset(c - 3, -2),
                Offset(c, 5),
                Offset(c + 3, -2),
              ], true),
            const Color(0xFFFFEED0));
      }
    }
    final hy = _head.y + sin(_bodyYaw) * (_head.x - 15) * .32;
    _shape(
        canvas,
        Path()
          ..addRRect(RRect.fromRectAndRadius(
              Rect.fromCenter(
                  center: Offset(15, hy + 17), width: 23, height: 34),
              const Radius.circular(9))),
        const Color(0xFFD6533C));
    for (final side in [-1.0, 1.0]) {
      final x = 15 + side * 18;
      _shape(
          canvas,
          Path()
            ..addPolygon([
              Offset(x - 5, hy - 12),
              Offset(
                  x + side * (9 + 12 * _evolution), hy - 35 - 18 * _evolution),
              Offset(x + 5, hy - 9),
            ], true),
          const Color(0xFFFFEAC0));
    }
    _shape(
        canvas,
        Path()
          ..addPolygon([
            Offset(-10, hy - 9),
            Offset(0, hy - 20),
            Offset(30, hy - 20),
            Offset(40, hy - 9),
            Offset(35, hy + 15),
            Offset(-5, hy + 15),
          ], true),
        front ? const Color(0xFFE66B46) : const Color(0xFFC34835));
    if (front) {
      for (final side in [-1.0, 1.0]) {
        final eye = Offset(15 + side * 11, hy - 4);
        canvas.drawOval(
            Rect.fromCenter(center: eye, width: 12, height: 15),
            Paint()
              ..color = Color.lerp(const Color(0xFFFFF2D2),
                  const Color(0xFFFF8D32), _evolution)!);
        canvas.drawOval(Rect.fromCenter(center: eye, width: 4, height: 11),
            Paint()..color = const Color(0xFF3A1B13));
      }
      _shape(
          canvas,
          Path()
            ..addRRect(RRect.fromRectAndRadius(
                Rect.fromCenter(
                    center: Offset(15, hy + 11), width: 31, height: 14),
                const Radius.circular(5))),
          const Color(0xFFF28D56));
      for (final side in [-1.0, 1.0]) {
        canvas.drawCircle(
            Offset(15 + side * 7, hy + 9), 2, Paint()..color = _ink);
      }
    } else {
      _shape(
          canvas,
          Path()
            ..addPolygon([
              Offset(10, hy - 10),
              Offset(15, hy - 28),
              Offset(20, hy - 10),
            ], true),
          const Color(0xFFFFB13A));
    }
    if (frozen > 0) _paintIce(canvas);
    canvas.restore();
  }

  void _paintAscendedTurnedBody(Canvas canvas, double opacity) {
    final front = sin(_bodyYaw) > 0;
    canvas.saveLayer(
        null, Paint()..color = const Color(0xFFFFFFFF).withOpacity(opacity));
    canvas.translate(15, -8);
    canvas.rotate(_bodyTurn);
    canvas.translate(-15 + cos(_bodyYaw) * _bodyOffset.x,
        8 + _bodyOffset.y + sin(_bodyYaw) * _bodyOffset.x * .32);
    for (final side in [-1.0, 1.0]) {
      canvas.save();
      canvas.translate(15, 0);
      canvas.scale(side * .7, .9);
      _wing(canvas, const Offset(0, -132), side * .07, 1.4,
          const Color(0xFFD36677), const Color(0xFF96364F));
      canvas.restore();
    }
    _shape(
        canvas,
        Path()
          ..moveTo(-11, -123)
          ..quadraticBezierTo(15, -144, 41, -123)
          ..lineTo(49, -55)
          ..quadraticBezierTo(15, -21, -19, -55)
          ..close(),
        const Color(0xFF37334F));
    final hy = _head.y + sin(_bodyYaw) * (_head.x - 15) * .32;
    _shape(
        canvas,
        Path()
          ..moveTo(4, hy + 8)
          ..lineTo(26, hy + 8)
          ..lineTo(33, -68)
          ..quadraticBezierTo(15, -39, -3, -68)
          ..close(),
        front ? const Color(0xFFFFDB8B) : const Color(0xFFBB4D63));
    for (final side in [-1.0, 1.0]) {
      final x = 15 + side * 26;
      _shape(
          canvas,
          Path()
            ..addPolygon([
              Offset(x - 12, -62),
              Offset(x + 13, -62),
              Offset(x + 15, -35),
              Offset(x + 8, -15),
              Offset(x + 17, 3),
              Offset(x - 16, 3),
              Offset(x - 13, -17),
            ], true),
          const Color(0xFF37334F));
      _shape(
          canvas,
          Path()
            ..addOval(
                Rect.fromCenter(center: Offset(x, -50), width: 23, height: 30)),
          const Color(0xFFBB4D63));
      for (var i = 0; i < 3; i++) {
        final c = x - 9 + i * 8;
        _shape(
            canvas,
            Path()
              ..addPolygon([
                Offset(c - 3, 0),
                Offset(c + 3, 0),
                Offset(c + 2, 8),
                Offset(c - 5, 6)
              ], true),
            const Color(0xFFBFC0D3));
      }
      _shape(
          canvas,
          Path()
            ..addPolygon([
              Offset(15 + side * 29, -116),
              Offset(15 + side * 40, -105),
              Offset(15 + side * 44, -78),
              Offset(15 + side * 30, -75),
            ], true),
          const Color(0xFF37334F));
      _shape(
          canvas,
          Path()
            ..addPolygon([
              Offset(15 + side * 16, hy - 12),
              Offset(15 + side * 32, hy - 49),
              Offset(15 + side * 7, hy - 14),
            ], true),
          const Color(0xFFBB4D63));
    }
    _shape(
        canvas,
        Path()
          ..addPolygon([
            Offset(-10, hy - 15),
            Offset(1, hy - 27),
            Offset(29, hy - 27),
            Offset(40, hy - 15),
            Offset(33, hy + 15),
            Offset(-3, hy + 15),
          ], true),
        const Color(0xFFC7586A));
    if (front) {
      for (final side in [-1.0, 1.0]) {
        _shape(
            canvas,
            Path()
              ..addPolygon([
                Offset(15 + side * 5, hy - 5),
                Offset(15 + side * 20, hy - 11),
                Offset(15 + side * 15, hy + 1),
              ], true),
            const Color(0xFFFFEBC2));
      }
      _shape(
          canvas,
          Path()
            ..addPolygon([
              Offset(0, hy + 6),
              Offset(30, hy + 6),
              Offset(27, hy + 16),
              Offset(3, hy + 16),
            ], true),
          const Color(0xFF38324F));
    }
    if (frozen > 0) _paintIce(canvas);
    canvas.restore();
  }

  Color _c(Color base) {
    var c = base;
    if (_evolution > 0 && base.red > base.green * 1.25) {
      final evolved =
          base.green > 120 ? const Color(0xFFD36B3E) : const Color(0xFFA64157);
      c = Color.lerp(c, evolved, .65 * _evolution)!;
    }
    if (frozen > 0) c = Color.lerp(c, const Color(0xFFBFE6FF), .45)!;
    if (_hurtFlash > 0 ||
        (defeated && _death < .7 && (_t * 12).floor().isEven)) {
      c = Color.lerp(c, const Color(0xFFFFFFFF), .5)!;
    }
    return c;
  }

  static const _ink = Color(0xFF4A1E14);
  Paint get _outline => Paint()
    ..color = _ink
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.6
    ..strokeJoin = StrokeJoin.round
    ..strokeCap = StrokeCap.round;

  void _shape(Canvas canvas, Path path, Color color) {
    final paint = Paint()..color = _c(color);
    final bounds = path.getBounds();
    if (_evolution > 0 && bounds.width > 8 && bounds.height > 8) {
      final base = _c(color);
      paint.shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        stops: const [0, .35, .7, 1],
        colors: [
          Color.lerp(base, const Color(0xFFFFBC9C), .22 * _evolution)!,
          base,
          Color.lerp(base, const Color(0xFF261B37), .18 * _evolution)!,
          Color.lerp(base, const Color(0xFF1D1730), .45 * _evolution)!,
        ],
      ).createShader(bounds);
    }
    canvas.drawPath(path, paint);
    canvas.drawPath(path, _outline);
  }

  /// Small overlapping plates are clipped to their moving anatomical surface.
  void _scaleDetail(Canvas canvas, Path surface, {double spacing = 9}) {
    final bounds = surface.getBounds();
    canvas.save();
    canvas.clipPath(surface);
    var row = 0;
    for (var y = bounds.top + spacing * .5;
        y < bounds.bottom;
        y += spacing * .72) {
      for (var x = bounds.left + (row.isEven ? 0 : spacing * .5);
          x < bounds.right;
          x += spacing) {
        final plate = Path()
          ..moveTo(x - spacing * .42, y)
          ..lineTo(x, y - spacing * .25)
          ..lineTo(x + spacing * .42, y)
          ..lineTo(x + spacing * .25, y + spacing * .36)
          ..lineTo(x, y + spacing * .55)
          ..lineTo(x - spacing * .25, y + spacing * .36);
        canvas.drawPath(
            plate,
            Paint()
              ..color = const Color(0x55201732)
              ..style = PaintingStyle.stroke
              ..strokeWidth = .8);
        canvas.drawLine(
            Offset(x - spacing * .3, y),
            Offset(x, y - spacing * .18),
            Paint()
              ..color = const Color(0x66EEA2A3)
              ..strokeWidth = .9);
      }
      row++;
    }
    canvas.restore();
  }

  void _magma(Canvas canvas, Path path) {
    if (_evolution <= 0) return;
    final pulse = .8 + .2 * sin(_t * 6);
    final color =
        frozen > 0 ? const Color(0xFF70CDFF) : const Color(0xFFFF492A);
    for (final layer in [(8.0, .25), (3.0, .95), (1.0, .9)]) {
      canvas.drawPath(
          path,
          Paint()
            ..color = (layer.$1 == 1 ? const Color(0xFFFFE49A) : color)
                .withOpacity(layer.$2 * _evolution * pulse)
            ..style = PaintingStyle.stroke
            ..strokeWidth = layer.$1
            ..strokeJoin = StrokeJoin.round
            ..strokeCap = StrokeCap.round);
    }
  }

  void _paintEvolutionArmor(Canvas canvas, {bool turned = false}) {
    final growth = _evolution;
    if (growth <= 0) return;
    for (var i = 0; i < 3; i++) {
      final y = -80.0 + i * 18;
      final x = turned ? 15.0 : 48.0 + i * 5;
      final width = (turned ? 21 : 16) * growth;
      _shape(
          canvas,
          Path()
            ..addPolygon([
              Offset(x - width, y),
              Offset(x, y - 6 * growth),
              Offset(x + width, y),
              Offset(x + width * .7, y + 9),
              Offset(x, y + 5),
              Offset(x - width * .7, y + 9),
            ], true),
          const Color(0xFFB95635));
      canvas.drawPath(
          Path()
            ..moveTo(x - width, y)
            ..lineTo(x, y - 6 * growth)
            ..lineTo(x + width, y),
          Paint()
            ..color = const Color(0xFFFFBC70).withOpacity(growth * .8)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5);
      _magma(
          canvas,
          Path()
            ..moveTo(x - width * .75, y + 2)
            ..lineTo(x, y + 8)
            ..lineTo(x + width * .75, y + 2));
    }
    if (!turned) {
      _magma(
          canvas,
          Path()
            ..moveTo(13, -72)
            ..lineTo(20, -60)
            ..lineTo(13, -48)
            ..lineTo(21, -35));
    }
  }

  void _paintEvolutionBurst(Canvas canvas) {
    final progress = _evolutionT / (evolutionPushTime + evolutionTime);
    final fade = sin(pi * progress);
    final radius = 40 + progress * 160;
    canvas.drawOval(
        Rect.fromCenter(
            center: const Offset(15, 0),
            width: radius * 2,
            height: radius * .6),
        Paint()
          ..color = const Color(0xFFFF6C35).withOpacity(fade * .8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5 * (1 - progress) + 1);
    for (var i = 0; i < 12; i++) {
      final a = i * pi / 6;
      final p = Offset(15 + cos(a) * radius * .65,
          -45 + sin(a) * radius * .3 - progress * 55);
      canvas.drawCircle(p, (2 + i % 3) * fade,
          Paint()..color = const Color(0xFFFFD371).withOpacity(fade));
    }
  }

  void _paintTail(Canvas canvas, List<Offset> points) {
    Offset tangent(int i) {
      final d = points[min(i + 1, points.length - 1)] - points[max(0, i - 1)];
      return d.distance > .001 ? d / d.distance : const Offset(1, 0);
    }

    Offset normal(int i) {
      final d = tangent(i);
      return Offset(-d.dy, d.dx);
    }

    double width(int i) =>
        (15 + 6 * _evolution) * (1 - i / (points.length - 1)) + 2;
    final shape = Path();
    for (var i = 0; i < points.length; i++) {
      final p = points[i] + normal(i) * width(i);
      if (i == 0) {
        shape.moveTo(p.dx, p.dy);
      } else {
        shape.lineTo(p.dx, p.dy);
      }
    }
    for (var i = points.length - 1; i >= 0; i--) {
      final p = points[i] - normal(i) * width(i);
      shape.lineTo(p.dx, p.dy);
    }
    shape.close();
    _shape(
        canvas,
        shape,
        Color.lerp(
            const Color(0xFFE0533D), const Color(0xFF33304E), _evolution)!);
    final ridge = Path();
    for (var i = 0; i < points.length; i++) {
      final p = points[i] - normal(i) * width(i) * .55;
      if (i == 0) {
        ridge.moveTo(p.dx, p.dy);
      } else {
        ridge.lineTo(p.dx, p.dy);
      }
    }
    canvas.drawPath(
        ridge,
        Paint()
          ..color = _c(const Color(0xFFF68B52))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round);
    if (_evolution > 0) {
      for (var i = 1; i < points.length - 1; i++) {
        final p = points[i];
        final n = normal(i);
        final d = tangent(i);
        final w = width(i);
        canvas.drawPath(
            Path()
              ..moveTo(p.dx - n.dx * w * .7, p.dy - n.dy * w * .7)
              ..quadraticBezierTo(p.dx - d.dx * 4, p.dy - d.dy * 4,
                  p.dx + n.dx * w * .8, p.dy + n.dy * w * .8),
            Paint()
              ..color = const Color(0xFF83687D)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1);
        canvas.drawLine(
            p + n * w * .75 - d * 3,
            p + n * w * .75 + d * 3,
            Paint()
              ..color = const Color(0xFFDDAC79)
              ..strokeWidth = 2);
      }
    }
    for (var i = 3; i < points.length - 2; i += 3) {
      final p = points[i] - normal(i) * width(i);
      final n = normal(i), d = tangent(i);
      _shape(
          canvas,
          Path()
            ..addPolygon([
              p - d * 4,
              p - n * (10 + 2 * _evolution) + d * 3,
              p + d * 7,
            ], true),
          const Color(0xFFFFB13A));
      canvas.drawLine(
          points[i] - n * width(i) * .4,
          points[i] + n * width(i) * .8,
          Paint()
            ..color = _c(const Color(0xFFAC3E2D))
            ..strokeWidth = 1.2);
    }
    final last = points.length - 1;
    final tip = points.last, d = tangent(last), n = normal(last);
    _shape(
        canvas,
        Path()
          ..addPolygon([
            tip + d * (16 + 4 * _evolution),
            tip - d * 5 + n * (10 + 5 * _evolution),
            tip - d * 1,
            tip - d * 5 - n * (10 + 5 * _evolution),
          ], true),
        const Color(0xFFFFB13A));
  }

  /// Upright, two-legged silhouette based on the user's red/violet reference.
  void _paintAscendedBody(Canvas canvas) {
    const hide = Color(0xFF37334F);
    const red = Color(0xFFBB4D63);
    const gold = Color(0xFFFFDB8B);
    final h = Offset(_head.x, _head.y);
    _wing(canvas, const Offset(35, -133), .09, 1.25, const Color(0xFFAC445B),
        const Color(0xFF742940));
    // Far leg, then pelvis: both feet remain planted throughout each cast.
    _shape(
        canvas,
        Path()
          ..addPolygon(const [
            Offset(22, -62),
            Offset(48, -52),
            Offset(43, -25),
            Offset(22, -14),
            Offset(31, -3),
            Offset(12, 3),
            Offset(-7, 2),
            Offset(-9, -6),
            Offset(8, -21),
          ], true),
        hide);
    final body = Path()
      ..moveTo(-24, -128)
      ..quadraticBezierTo(12, -150, 43, -121)
      ..quadraticBezierTo(79, -94, 76, -52)
      ..lineTo(55, -25)
      ..quadraticBezierTo(16, -13, -16, -44)
      ..quadraticBezierTo(-39, -82, -24, -128)
      ..close();
    _shape(canvas, body, hide);
    _scaleDetail(canvas, body, spacing: 9);
    final neck = Path()
      ..moveTo(3, -89)
      ..cubicTo(-30, -112, h.dx + 36, h.dy + 20, h.dx + 13, h.dy + 9);
    canvas.drawPath(neck, _outline..strokeWidth = 47);
    canvas.drawPath(
        neck,
        Paint()
          ..color = _c(hide)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 41
          ..strokeCap = StrokeCap.round);
    canvas.drawPath(
        neck.shift(const Offset(-8, 0)),
        Paint()
          ..color = _c(red)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 18
          ..strokeCap = StrokeCap.round);
    // Neck ridges follow the same curve used by the throat and the head.
    for (var i = 1; i < 8; i++) {
      final t = i / 8;
      final p = Offset.lerp(h + const Offset(20, 16), const Offset(5, -94), t)!;
      canvas.drawPath(
          Path()
            ..moveTo(p.dx + 3, p.dy - 4)
            ..lineTo(p.dx + 11, p.dy)
            ..lineTo(p.dx + 5, p.dy + 6),
          Paint()
            ..color = const Color(0xFF92536A)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
    }
    // A continuous pale throat joins the belly; rib plates follow the neck.
    final throat = Path()
      ..moveTo(h.dx + 3, h.dy + 19)
      ..cubicTo(h.dx + 7, h.dy + 54, -38, -113, -20, -70)
      ..quadraticBezierTo(-7, -39, 18, -30)
      ..lineTo(33, -51)
      ..quadraticBezierTo(10, -76, 2, -109)
      ..quadraticBezierTo(h.dx + 35, h.dy + 30, h.dx + 23, h.dy + 17)
      ..close();
    _shape(canvas, throat, gold);
    canvas.save();
    canvas.clipPath(throat);
    for (var i = 0; i < 8; i++) {
      final t = i / 7;
      final p = Offset.lerp(h + const Offset(8, 25), const Offset(7, -42), t)!;
      canvas.drawPath(
          Path()
            ..moveTo(p.dx - 23, p.dy)
            ..quadraticBezierTo(p.dx, p.dy + 8, p.dx + 23, p.dy + 2),
          Paint()
            ..color = const Color(0xFFC58C62)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
      canvas.drawLine(
          p + const Offset(-16, -3),
          p + const Offset(4, -1),
          Paint()
            ..color = const Color(0xFFFFF1B2)
            ..strokeWidth = 4);
    }
    canvas.restore();
    // Raised red plates only on shoulders and thighs, leaving the throat clear.
    for (final p in const [Offset(22, -119), Offset(53, -55)]) {
      final plate = Path()
        ..moveTo(p.dx - 14, p.dy - 19)
        ..lineTo(p.dx + 7, p.dy - 23)
        ..lineTo(p.dx + 18, p.dy - 9)
        ..lineTo(p.dx + 15, p.dy + 15)
        ..lineTo(p.dx - 2, p.dy + 23)
        ..lineTo(p.dx - 17, p.dy + 7)
        ..close();
      _shape(canvas, plate, red);
      _scaleDetail(canvas, plate, spacing: 8);
      canvas.drawPath(
          Path()
            ..moveTo(p.dx - 9, p.dy - 12)
            ..lineTo(p.dx + 4, p.dy - 16)
            ..lineTo(p.dx + 11, p.dy - 6),
          Paint()
            ..color = const Color(0xFFF08C86)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3);
      canvas.drawLine(
          p + const Offset(-12, 1),
          p + const Offset(14, 4),
          Paint()
            ..color = const Color(0xFF78364E)
            ..strokeWidth = 2);
    }
    // Front shin and broad taloned foot.
    _shape(
        canvas,
        Path()
          ..addPolygon(const [
            Offset(49, -43),
            Offset(70, -39),
            Offset(71, -17),
            Offset(82, -3),
            Offset(75, 5),
            Offset(35, 6),
            Offset(27, -1),
            Offset(45, -15),
          ], true),
        hide);
    for (final foot in const [Offset(1, -1), Offset(43, 3)]) {
      for (var i = 0; i < 3; i++) {
        final x = foot.dx + i * 11;
        _shape(
            canvas,
            Path()
              ..addPolygon([
                Offset(x, foot.dy - 4),
                Offset(x + 7, foot.dy - 3),
                Offset(x + 4, foot.dy + 7),
                Offset(x - 6, foot.dy + 7),
              ], true),
            const Color(0xFFBFC0D3));
      }
    }
    // The small forearms hang in front of the torso, rather than bearing weight.
    for (final p in const [Offset(-24, -103), Offset(20, -96)]) {
      final reach = sin(_t * 2) * 1.5 + _castKick * 3;
      _shape(
          canvas,
          Path()
            ..addPolygon([
              p,
              p + const Offset(12, 7),
              p + Offset(3, 30 + reach),
              p + Offset(-10, 39 + reach),
              p + Offset(-20, 33 + reach),
              p + const Offset(-10, 18),
            ], true),
          hide);
      for (var i = 0; i < 3; i++) {
        final claw = p + Offset(-18 + i * 7, 31 + reach);
        _shape(
            canvas,
            Path()
              ..addPolygon([
                claw,
                claw + const Offset(5, 0),
                claw + const Offset(3, 10),
                claw + const Offset(-2, 7),
              ], true),
            const Color(0xFFC7C2D7));
      }
    }
    // Low dorsal spines join the neck to the original attached tail.
    for (var i = 0; i < 5; i++) {
      final p = Offset(43 + i * 6, -123 + i * 16);
      _shape(
          canvas,
          Path()
            ..addPolygon([
              p,
              p + const Offset(20, 0),
              p + const Offset(4, 10),
            ], true),
          red);
    }
    _paintHead(canvas, h);
    // The near wing attaches behind the shoulder, away from the head and horns.
    _wing(canvas, const Offset(39, -132), 0, 1.55, const Color(0xFFD36677),
        const Color(0xFF96364F));
  }

  void _paintAscendedHead(Canvas canvas, Offset h) {
    const red = Color(0xFFC7586A);
    const dark = Color(0xFF38324F);
    canvas.save();
    canvas.translate(h.dx, h.dy);
    canvas.rotate(_headPitch);
    canvas.scale(_headSize);
    for (final horn in const [(24.0, -15.0, 30.0), (5.0, -26.0, 42.0)]) {
      _shape(
          canvas,
          Path()
            ..addPolygon([
              Offset(horn.$1 - 7, horn.$2 + 6),
              Offset(horn.$1 + 2, horn.$2 - 16),
              Offset(horn.$1 + horn.$3, horn.$2 - 34),
              Offset(horn.$1 + 21, horn.$2 - 8),
              Offset(horn.$1 + 7, horn.$2 + 9),
            ], true),
          red);
      canvas.drawLine(
          Offset(horn.$1 + 2, horn.$2 - 8),
          Offset(horn.$1 + horn.$3 - 5, horn.$2 - 29),
          Paint()
            ..color = const Color(0xFFFFA193)
            ..strokeWidth = 2.5);
    }
    for (var i = 0; i < 3; i++) {
      final p = Offset(26, -10 + i * 9);
      _shape(
          canvas,
          Path()
            ..addPolygon([
              p,
              p + const Offset(24, -2),
              p + const Offset(9, 9),
            ], true),
          red);
    }
    canvas.save();
    canvas.translate(-9, 12);
    canvas.rotate(-.42 * _jaw);
    _shape(
        canvas,
        Path()
          ..addPolygon(const [
            Offset(-49, -2),
            Offset(-5, -3),
            Offset(12, 7),
            Offset(-1, 17),
            Offset(-43, 12),
            Offset(-52, 6)
          ], true),
        dark);
    canvas.restore();
    final skull = Path()
      ..addPolygon(const [
        Offset(25, 10),
        Offset(27, -13),
        Offset(11, -30),
        Offset(-7, -32),
        Offset(-28, -18),
        Offset(-42, -7),
        Offset(-59, 5),
        Offset(-57, 15),
        Offset(-43, 19),
        Offset(-23, 13),
        Offset(-6, 18),
      ], true);
    _shape(canvas, skull, red);
    _scaleDetail(canvas, skull, spacing: 7);
    _shape(
        canvas,
        Path()
          ..addPolygon(const [
            Offset(3, -2),
            Offset(17, -11),
            Offset(23, 0),
            Offset(13, 12),
            Offset(-2, 16),
          ], true),
        const Color(0xFFAF4D66));
    canvas.drawPath(
        Path()
          ..moveTo(6, -1)
          ..lineTo(16, -7)
          ..lineTo(19, 0),
        Paint()
          ..color = const Color(0xFFFFA19A)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
    canvas.drawPath(
        Path()
          ..moveTo(-54, 5)
          ..lineTo(-40, 1)
          ..lineTo(-27, -6),
        Paint()
          ..color = const Color(0xFFE68A8F)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8);
    _shape(
        canvas,
        Path()
          ..addPolygon(const [
            Offset(-53, 15),
            Offset(-27, 8),
            Offset(-4, 3),
            Offset(14, 9),
            Offset(-6, 20),
            Offset(-43, 23)
          ], true),
        dark);
    canvas.drawPath(
        Path()
          ..moveTo(-45, -3)
          ..lineTo(-25, -14)
          ..lineTo(-6, -23)
          ..lineTo(10, -23),
        Paint()
          ..color = const Color(0xFFF18B8B)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3);
    _shape(
        canvas,
        Path()
          ..addPolygon(const [
            Offset(-18, -8),
            Offset(-3, -17),
            Offset(5, -15),
            Offset(-2, -5),
            Offset(-13, -2)
          ], true),
        const Color(0xFFFFEBC2));
    canvas.drawLine(
        const Offset(-6, -12),
        const Offset(-8, -5),
        Paint()
          ..color = const Color(0xFF211F35)
          ..strokeWidth = 3);
    canvas.drawLine(const Offset(-21, -11), const Offset(4, -20),
        _outline..strokeWidth = 3.5);
    canvas.drawOval(
        Rect.fromCenter(center: const Offset(-46, 5), width: 5, height: 3),
        Paint()..color = dark);
    if (_jaw > .2) {
      for (final x in [-41.0, -24.0]) {
        _shape(
            canvas,
            Path()
              ..addPolygon(
                  [Offset(x, 15), Offset(x + 5, 14), Offset(x + 2, 21)], true),
            const Color(0xFFFFEBC2));
      }
    }
    canvas.restore();
  }

  void _paintBody(Canvas canvas) {
    if (_evolution > 0) {
      canvas.saveLayer(null,
          Paint()..color = const Color(0xFFFFFFFF).withOpacity(_evolution));
      _paintAscendedBody(canvas);
      canvas.restore();
    }
    if (_evolution >= 1) return;
    canvas.saveLayer(null,
        Paint()..color = const Color(0xFFFFFFFF).withOpacity(1 - _evolution));
    _paintOriginalBody(canvas);
    canvas.restore();
  }

  void _paintOriginalBody(Canvas canvas) {
    const scale = Color(0xFFE0533D);
    const dark = Color(0xFFB23A2C);
    const belly = Color(0xFFFFD98A);
    const spike = Color(0xFFFFB13A);

    // Enraged glow.
    if (_evolution > 0 && !intro && !defeated) {
      final pulse = .5 + .5 * sin(_t * 5);
      canvas.drawOval(
          Rect.fromCenter(
              center: const Offset(10, -70), width: 230, height: 190),
          Paint()
            ..shader = RadialGradient(colors: [
              Color.fromARGB(
                  ((65 * pulse + 25) * _evolution).round(), 0xFF, 0x4A, 0x2A),
              const Color(0x00FF5A1A),
            ]).createShader(Rect.fromCenter(
                center: const Offset(10, -70), width: 230, height: 190)));
    }

    // Back wing (darker, behind the body).
    _wing(
        canvas, const Offset(46, -92), .09, .86, dark, const Color(0xFFC8642E));
    // Back legs.
    _shape(
        canvas,
        Path()
          ..addOval(Rect.fromCenter(
              center: const Offset(62, -14), width: 36, height: 30)),
        dark);

    // Body and belly.
    // Angular pear-shaped torso: wide shoulders, tucked waist, plated chest.
    final body = Path()
      ..moveTo(-38 - 12 * _evolution, -66)
      ..quadraticBezierTo(-16 - 14 * _evolution, -101 - 18 * _evolution, 27,
          -98 - 14 * _evolution)
      ..quadraticBezierTo(70 + 8 * _evolution, -95, 83 + 5 * _evolution, -61)
      ..lineTo(76, -23)
      ..quadraticBezierTo(57, -5, 24, -4)
      ..quadraticBezierTo(-11 - 8 * _evolution, -6, -38 - 12 * _evolution, -30)
      ..close();
    canvas.drawPath(body, Paint()..color = _c(scale));
    canvas.save();
    canvas.clipPath(body);
    canvas.drawOval(
        Rect.fromCenter(center: const Offset(0, -36), width: 76, height: 74),
        Paint()..color = _c(belly));
    final stripe = Paint()
      ..color = _c(const Color(0xFFE8B464))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    for (var i = 0; i < 4; i++) {
      final y = -58.0 + i * 13;
      canvas.drawArc(
          Rect.fromCenter(center: Offset(0, y), width: 60, height: 16),
          .3,
          2.5,
          false,
          stripe);
    }
    // Scale dots on the back.
    final dot = Paint()..color = _c(dark);
    for (final p in const [
      Offset(46, -78),
      Offset(62, -64),
      Offset(70, -46),
      Offset(34, -86)
    ]) {
      canvas.drawCircle(p, 4, dot);
    }
    canvas.restore();
    canvas.drawPath(body, _outline);
    if (_evolution < 1) {
      canvas.saveLayer(null,
          Paint()..color = const Color(0xFFFFFFFF).withOpacity(1 - _evolution));
      _paintArmorPlates(canvas, _breath);
      canvas.restore();
    }
    _paintEvolutionArmor(canvas);
    if (_evolution > 0) {
      canvas.save();
      canvas.translate(-20, -76);
      canvas.scale(_evolution);
      _shape(
          canvas,
          Path()
            ..addPolygon(const [
              Offset(-28, -2),
              Offset(-14, -27),
              Offset(12, -32),
              Offset(32, -13),
              Offset(25, 8),
              Offset(2, 20),
              Offset(-23, 12),
            ], true),
          const Color(0xFFB65333));
      _magma(
          canvas,
          Path()
            ..moveTo(-20, -4)
            ..lineTo(-3, -12)
            ..lineTo(16, -8));
      canvas.restore();
    }

    // Back spikes along the top of the body.
    for (var i = 0; i < 6; i++) {
      final a = pi * (1.12 + i * .13);
      final base = Offset(25 + cos(a) * 62, -52 + sin(a) * 47);
      final out = Offset(cos(a), sin(a));
      final side = Offset(-out.dy, out.dx) * 7;
      _shape(
          canvas,
          Path()
            ..moveTo(base.dx - side.dx, base.dy - side.dy)
            ..lineTo(base.dx + out.dx * (15 + 16 * _evolution),
                base.dy + out.dy * (15 + 16 * _evolution))
            ..lineTo(base.dx + side.dx, base.dy + side.dy)
            ..close(),
          spike);
    }

    // Bent forelegs taper from shoulder to ankle, feet stay planted.
    for (final x in const [-8.0, 38.0]) {
      final settle = _breath * 2 +
          (_tailMove?.crouch ?? 0) +
          _fireCharge * 3 +
          _firePower * 5 +
          _castKick * 2;
      final leg = Path()
        ..moveTo(x - 8, -44 - settle)
        ..quadraticBezierTo(x + 15, -40, x + 13, -26)
        ..lineTo(x + 6, -12)
        ..lineTo(x + 11, -5)
        ..lineTo(x + 8, 2)
        ..lineTo(x - 20, 2)
        ..lineTo(x - 23, -4)
        ..lineTo(x - 7, -14)
        ..lineTo(x - 1, -27)
        ..lineTo(x - 13, -35)
        ..close();
      _shape(canvas, leg, x < 0 ? scale : dark);
      final plate = Path()
        ..moveTo(x - 5, -38)
        ..lineTo(x + 8, -34)
        ..lineTo(x + 8, -26)
        ..lineTo(x - 2, -24)
        ..lineTo(x - 8, -31)
        ..close();
      _shape(canvas, plate, const Color(0xFFCE6740));
      canvas.drawLine(
          Offset(x - 3, -18),
          Offset(x + 5, -16),
          Paint()
            ..color = _c(const Color(0xFF7F291F))
            ..strokeWidth = 1.6);
      for (var i = 0; i < 3; i++) {
        final cx = x - 20 + i * 8.0;
        _shape(
            canvas,
            Path()
              ..moveTo(cx, 0)
              ..lineTo(cx - 8, 7)
              ..lineTo(cx + 5, 3)
              ..lineTo(cx + 6, -1)
              ..close(),
            const Color(0xFFFFF0C8));
      }
    }

    // Neck to the head.
    final h = Offset(_head.x, _head.y);
    final neck = Path()
      ..moveTo(-4, -78)
      ..quadraticBezierTo(
          (h.dx - 4) / 2 - 6, (h.dy - 78) / 2 - 4, h.dx + 8, h.dy + 10);
    canvas.drawPath(
        neck,
        Paint()
          ..color = _ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 37 + 15 * _evolution
          ..strokeCap = StrokeCap.round);
    canvas.drawPath(
        neck,
        Paint()
          ..color = _c(scale)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 32 + 15 * _evolution
          ..strokeCap = StrokeCap.round);
    canvas.drawPath(
        neck.shift(const Offset(-8, 6)),
        Paint()
          ..color = _c(belly)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 12
          ..strokeCap = StrokeCap.round);
    // Segmented neck armor follows the moving neck curve.
    final neckPlate = Paint()
      ..color = _c(const Color(0xFFFFB13A))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    for (var i = 1; i <= 4; i++) {
      final k = i / 5;
      final x = -4 + (h.dx + 8 + 4) * k;
      final y = -78 + (h.dy + 78 - 4) * k - sin(k * pi) * 7;
      canvas.drawArc(
          Rect.fromCenter(center: Offset(x, y), width: 27, height: 18),
          .15,
          2.8,
          false,
          neckPlate);
    }

    _paintHead(canvas, h);

    // Front wing, raised over the shoulder.
    _wing(canvas, const Offset(30, -90), 0, 1, scale, const Color(0xFFF59A55));
  }

  /// Overlapping armor plates give the torso a faceted, scaled silhouette.
  void _paintArmorPlates(Canvas canvas, double breath) {
    const edge = Color(0xFF7F291F);
    final plate = Paint()..color = _c(const Color(0xFFFFB13A));
    final plateEdge = Paint()
      ..color = _c(edge)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeJoin = StrokeJoin.round;
    final chest = Path()
      ..moveTo(-22, -78)
      ..lineTo(8, -87 - breath * 3)
      ..lineTo(34, -77)
      ..lineTo(20, -48)
      ..lineTo(-10, -48)
      ..close();
    canvas.drawPath(chest, plate);
    canvas.drawPath(chest, plateEdge);
    final ribs = Paint()
      ..color = _c(const Color(0xFFE8B464))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    for (var i = 0; i < 3; i++) {
      final y = -68.0 + i * 11;
      canvas.drawArc(
          Rect.fromCenter(center: Offset(8, y), width: 55, height: 22),
          .35,
          2.45,
          false,
          ribs);
    }
    // Individual back scales alternate their tilt as the body breathes.
    for (var row = 0; row < 3; row++) {
      for (var col = 0; col < 5; col++) {
        final x = 27.0 + col * 10 + (row.isEven ? 3 : 0);
        final y = -88.0 + row * 13 + sin(_t * 2 + col) * breath * 1.2;
        final scale = Path()
          ..moveTo(x - 5, y)
          ..lineTo(x, y - 7)
          ..lineTo(x + 6, y)
          ..lineTo(x, y + 5)
          ..close();
        canvas.drawPath(scale, plate);
        canvas.drawPath(scale, plateEdge);
      }
    }
  }

  /// All bones share one beat. Fixed-length links rotate about their parent;
  /// delayed folding narrows the recovery stroke and opens the power stroke.
  void _wing(Canvas canvas, Offset root, double phaseOffset, double size,
      Color bone, Color skin) {
    final beat = _wingPhase + phaseOffset;
    final sweep = sin(beat);
    final balance = _tailMove?.wingSpread ?? _castSpread;
    // Grounded wings rest folded; flight opens them for each power stroke.
    final restingFold = .88 - .35 * _evolution + .04 * cos(beat);
    final flightFold = .08 + .82 * _smoothUnit(.5 + .5 * cos(beat - .45));
    final fold = (restingFold + (flightFold - restingFold) * _flightBlend) *
        (1 - balance * .75);
    Offset link(Offset from, double length, double angle) =>
        from + Offset(cos(angle), sin(angle)) * length;
    final shoulder = -1.38 -
        .55 * _evolution +
        fold * .85 +
        sweep * (.07 + .48 * _flightBlend) -
        balance * .28;
    final elbow = link(Offset.zero, 39, shoulder);
    // Fold rearward along the outer flank, never back through the shoulder.
    final forearm = shoulder + .57 + fold * 1.05 - balance * .18;
    final wrist = link(elbow, 47, forearm);
    final lag = sin(beat - .5) * (.025 + .12 * _flightBlend);
    final spread = 1 - fold * .9 + balance * .18;
    final openFingerBase = forearm + .2 + lag;
    final fingerBase = openFingerBase + (1.15 - openFingerBase) * fold;
    final tips = [
      link(wrist, 34, fingerBase - .65 * spread),
      link(wrist, 60, fingerBase + .44 * spread),
      link(wrist, 79, fingerBase + 1.04 * spread),
    ];
    // The membrane closes on the flank; this anchor never follows the wrist.
    const anchor = Offset(35, 6);
    final billow = sin(beat - .85) * (1 + 3 * _flightBlend) * (1 - fold);
    Offset scallop(Offset a, Offset b) =>
        (a + b) * .5 + (wrist - (a + b) * .5) * .36 + Offset(0, billow);
    final c01 = scallop(tips[0], tips[1]);
    final c12 = scallop(tips[1], tips[2]);
    final c2a = (tips[2] + anchor) * .5 +
        Offset(-12 * (1 - fold * .8), -9 * (1 - fold) + billow);
    final notch = Offset.lerp(c12, wrist, .22 * _evolution)!;
    final membrane = Path()
      ..moveTo(0, 0)
      ..lineTo(elbow.dx, elbow.dy)
      ..lineTo(wrist.dx, wrist.dy)
      ..lineTo(tips[0].dx, tips[0].dy)
      ..quadraticBezierTo(c01.dx, c01.dy, tips[1].dx, tips[1].dy)
      ..quadraticBezierTo(c12.dx, c12.dy, notch.dx, notch.dy)
      ..lineTo(notch.dx + 4 * _evolution, notch.dy + 10 * _evolution)
      ..lineTo(notch.dx + 10 * _evolution, notch.dy + 3 * _evolution)
      ..quadraticBezierTo(c12.dx, c12.dy, tips[2].dx, tips[2].dy)
      ..quadraticBezierTo(c2a.dx, c2a.dy, anchor.dx, anchor.dy)
      ..quadraticBezierTo(18, -4, 0, 0)
      ..close();
    canvas.save();
    canvas.translate(root.dx, root.dy);
    canvas.scale(size * (1 + .18 * _evolution));
    _shape(canvas, membrane,
        Color.lerp(skin, const Color(0xFFAC3D30), _evolution * .65)!);
    canvas.save();
    canvas.clipPath(membrane);
    if (_evolution > 0) {
      for (var panel = 0; panel < 3; panel++) {
        final end = panel < 2
            ? (tips[panel] + tips[panel + 1]) * .5
            : (tips[2] + anchor) * .5;
        final next = panel < 2 ? tips[panel + 1] : anchor;
        final section = Path()
          ..moveTo(wrist.dx, wrist.dy)
          ..lineTo(tips[panel].dx, tips[panel].dy)
          ..quadraticBezierTo(end.dx - 4, end.dy - 5, next.dx, next.dy)
          ..close();
        canvas.drawPath(
            section,
            Paint()
              ..shader = const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xBBE27B83),
                  Color(0x226F243F),
                  Color(0xAA421E35)
                ],
                stops: [0, .45, 1],
              ).createShader(section.getBounds()));
        canvas.drawPath(
            Path()
              ..moveTo(wrist.dx, wrist.dy)
              ..quadraticBezierTo((wrist.dx + next.dx) * .5 + 4,
                  (wrist.dy + next.dy) * .5, next.dx, next.dy),
            Paint()
              ..color = const Color(0xAA652A41)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3);
        for (var v = 1; v < 5; v++) {
          final t = v / 5;
          final start = Offset.lerp(wrist, end, t)!;
          final finish =
              Offset.lerp(wrist, tips[panel], (t + .13).clamp(0.0, 1.0))!;
          final vein = Path()
            ..moveTo(start.dx, start.dy)
            ..quadraticBezierTo((start.dx + finish.dx) * .5 + 3,
                (start.dy + finish.dy) * .5 + 2, finish.dx, finish.dy);
          canvas.drawPath(
              vein,
              Paint()
                ..color = const Color(0x44602C43)
                ..style = PaintingStyle.stroke
                ..strokeWidth = .8);
        }
        final a = Offset.lerp(wrist, tips[panel], .14)!;
        final b = Offset.lerp(wrist, end, .85)!;
        canvas.drawPath(
            Path()
              ..moveTo(a.dx, a.dy)
              ..quadraticBezierTo(b.dx - 5, b.dy - 8, b.dx, b.dy),
            Paint()
              ..color = const Color(0x33FFA8A0)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2);
      }
    }

    canvas.drawPath(
        Path()
          ..moveTo(wrist.dx, wrist.dy)
          ..lineTo(tips[2].dx, tips[2].dy)
          ..lineTo(anchor.dx, anchor.dy)
          ..close(),
        Paint()..color = _c(const Color(0x33852A22)));
    canvas.restore();
    final arm = Path()
      ..moveTo(0, 0)
      ..lineTo(elbow.dx, elbow.dy)
      ..lineTo(wrist.dx, wrist.dy);
    canvas.drawPath(arm, _outline..strokeWidth = 8);
    canvas.drawPath(
        arm,
        Paint()
          ..color = _c(bone)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4.5
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round);
    for (final tip in tips) {
      final mid = (wrist + tip) * .5 + Offset(0, billow * .25);
      final finger = Path()
        ..moveTo(wrist.dx, wrist.dy)
        ..quadraticBezierTo(mid.dx, mid.dy, tip.dx, tip.dy);
      canvas.drawPath(finger, _outline..strokeWidth = 4);
      canvas.drawPath(
          finger,
          Paint()
            ..color = _c(bone)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
      _magma(canvas, finger);
    }
    for (var i = 1; i < 3; i++) {
      final ribEnd = (wrist + tips[i]) * .5;
      canvas.drawLine(
          anchor,
          ribEnd,
          Paint()
            ..color = _c(Color.fromARGB((100 + 70 * fold).round(), 127, 41, 31))
            ..strokeWidth = 1 + fold);
    }
    // The claw follows the wrist orientation rather than sliding over it.
    canvas.save();
    canvas.translate(wrist.dx, wrist.dy);
    canvas.rotate(forearm + pi / 2);
    _shape(
        canvas,
        Path()
          ..moveTo(-3, 0)
          ..quadraticBezierTo(-15, -9, -8, -21)
          ..quadraticBezierTo(-7, -8, 4, -3)
          ..close(),
        const Color(0xFFFFF0C8));
    canvas.restore();
    canvas.restore();
  }

  void _paintHead(Canvas canvas, Offset h) {
    if (_evolution >= .5) {
      _paintAscendedHead(canvas, h);
      return;
    }

    const scale = Color(0xFFE0533D);
    const horn = Color(0xFFFFF0C8);
    canvas.save();
    canvas.translate(h.dx, h.dy);
    canvas.rotate(_headPitch);
    canvas.scale(_headSize);
    // Low nape spines sit behind the ivory horns, leaving their roots visible.
    if (_evolution > 0) {
      for (var i = 0; i < 3; i++) {
        final x = 28.0 + i * 8;
        final y = -3.0 + i * 9;
        _shape(
            canvas,
            Path()
              ..addPolygon([
                Offset(x - 5, y),
                Offset(x + 11 * _evolution, y - 10 * _evolution),
                Offset(x + 5, y + 7),
              ], true),
            const Color(0xFFECA653));
      }
    }
    // Swept, faceted horns stay low behind the skull instead of reading as ears.
    for (final o in const [Offset(27, -9), Offset(9, -24)]) {
      final g = _evolution;
      final length = o.dx > 20 ? 46.0 : 54.0;
      final points = [
        o + Offset(-6 - 2 * g, 5),
        o + Offset(2 + 5 * g, -17 - 4 * g),
        o + Offset(19 + 7 * g, -26 - 3 * g),
        o + Offset(30 + (length - 30) * g, -26 - 4 * g),
        o + Offset(18 + 14 * g, -11 - 2 * g),
        o + Offset(8 + 3 * g, 6),
      ];
      _shape(canvas, Path()..addPolygon(points, true),
          Color.lerp(horn, const Color(0xFFE6BD7C), g)!);
      canvas.drawPath(
          Path()
            ..addPolygon([
              points[0],
              points[1],
              points[2],
              points[3],
              o + const Offset(9, -7),
            ], true),
          Paint()..color = const Color(0xFFFFEAC0).withOpacity(.65));
      for (var i = 0; i < 3; i++) {
        final t = .2 + i * .2;
        final top = Offset.lerp(points[1], points[3], t)!;
        final bottom = Offset.lerp(points[5], points[3], t)!;
        canvas.drawLine(
            top,
            bottom,
            Paint()
              ..color = const Color(0xFF98623A).withOpacity(.7)
              ..strokeWidth = 1.3);
      }
      if (g > 0) {
        _shape(
            canvas,
            Path()
              ..addPolygon([
                o + const Offset(-9, 5),
                o + const Offset(-3, -10),
                o + const Offset(9, -8),
                o + const Offset(14, 5),
                o + const Offset(3, 10),
              ], true),
            const Color(0xFFB55437));
      }
    }
    // Ear fin.
    _shape(
        canvas,
        Path()
          ..moveTo(18, -2)
          ..lineTo(40, -8)
          ..lineTo(34, 4)
          ..lineTo(42, 12)
          ..lineTo(18, 10)
          ..close(),
        const Color(0xFFFFB13A));
    // Lower jaw, swinging open.
    canvas.save();
    canvas.translate(-6, 14);
    canvas.rotate(-.52 * _jaw);
    final jaw = Path()
      ..addRRect(RRect.fromRectAndRadius(
          const Rect.fromLTWH(-42, -4, 42, 16), const Radius.circular(8)));
    if (_mouth > .05) {
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              const Rect.fromLTWH(-38, -10, 36, 12), const Radius.circular(6)),
          Paint()..color = const Color(0xFF7A1E1E));
    }
    _shape(canvas, jaw, const Color(0xFFFFD98A));
    canvas.restore();
    // Long angular muzzle, cheek ridge and armored crown.
    final head = Path()
      ..moveTo(25, 9)
      ..lineTo(26, -12)
      ..lineTo(10, -30)
      ..lineTo(-10, -31)
      ..lineTo(-24, -19)
      ..lineTo(-29, -7)
      ..lineTo(-49, -7)
      ..lineTo(-56, 0)
      ..lineTo(-53, 14)
      ..lineTo(-40, 20)
      ..lineTo(-14, 18)
      ..lineTo(-2, 24)
      ..lineTo(15, 20)
      ..close();
    _shape(canvas, head, scale);
    if (_evolution > 0) {
      _shape(
          canvas,
          Path()
            ..addPolygon([
              const Offset(-24, -19),
              Offset(-53 - 6 * _evolution, -14),
              Offset(-60 - 4 * _evolution, -1),
              const Offset(-51, 13),
              const Offset(-28, 10),
            ], true),
          scale);
      for (final x in [-43.0, -25.0]) {
        _shape(
            canvas,
            Path()
              ..addPolygon([
                Offset(x - 3, 10),
                Offset(x - 1, 10 + 17 * _evolution),
                Offset(x + 5, 11),
              ], true),
            horn);
      }
    }
    final cheek = Path()
      ..moveTo(22, -10)
      ..lineTo(5, -16)
      ..lineTo(-3, -1)
      ..lineTo(-19, 13)
      ..lineTo(-2, 23)
      ..lineTo(15, 19)
      ..close();
    canvas.drawPath(cheek, Paint()..color = _c(const Color(0xFFB23A2C)));
    if (_evolution > 0) {
      _magma(
          canvas,
          Path()
            ..moveTo(17, -14)
            ..lineTo(6, -8)
            ..lineTo(12, 2)
            ..lineTo(1, 12));
    }
    canvas.drawPath(
        Path()
          ..moveTo(-49, -5)
          ..lineTo(-28, -3)
          ..lineTo(-14, -20)
          ..lineTo(5, -26)
          ..lineTo(18, -16),
        Paint()
          ..color = _c(const Color(0xFFFF9A62))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeJoin = StrokeJoin.round);
    // Scutes down the cheek and snout.
    for (var i = 0; i < 3; i++) {
      final x = 4.0 + i * 6;
      final y = 4.0 + i * 3;
      final scute = Path()
        ..moveTo(x - 4, y)
        ..lineTo(x, y - 4)
        ..lineTo(x + 4, y)
        ..lineTo(x, y + 4)
        ..close();
      canvas.drawPath(scute, Paint()..color = _c(const Color(0xFFD97A42)));
    }
    // Teeth peeking under the snout.
    final tooth = Paint()..color = const Color(0xFFFFFFFF);
    for (final x in const [-40.0, -28.0]) {
      canvas.drawPath(
          Path()
            ..moveTo(x, 19)
            ..lineTo(x + 3, 26)
            ..lineTo(x + 6, 19)
            ..close(),
          tooth);
    }
    // Nostrils, smoking when angry.
    final nostril = Paint()..color = const Color(0xFF7A1E1E);
    canvas.drawOval(
        Rect.fromCenter(center: const Offset(-44, 2), width: 6, height: 4),
        nostril);
    canvas.drawOval(
        Rect.fromCenter(center: const Offset(-36, 0), width: 6, height: 4),
        nostril);
    if ((phase == 2 || _mouth > .3) && !defeated) {
      for (var i = 0; i < 3; i++) {
        final k = (_t * 1.6 + i / 3) % 1;
        canvas.drawCircle(
            Offset(-44 - k * 14, -2 - k * 22),
            3 + k * 5,
            Paint()
              ..color =
                  Color.fromARGB((120 * (1 - k)).round(), 0x80, 0x70, 0x6A));
      }
    }
    // Cheek highlight.
    canvas.drawOval(
        Rect.fromCenter(center: const Offset(-14, 10), width: 14, height: 8),
        Paint()..color = const Color(0x66FF8FA0));
    // Eye.
    if (tired > 0 || defeated) {
      final swirl = Path()..moveTo(-6, -6);
      for (var i = 1; i <= 24; i++) {
        final a = i * .55 + _t * 6;
        final r = i * .38;
        swirl.lineTo(-6 + cos(a) * r, -6 + sin(a) * r);
      }
      canvas.drawOval(
          Rect.fromCenter(center: const Offset(-6, -6), width: 20, height: 20),
          Paint()..color = const Color(0xFFFFFFFF));
      canvas.drawPath(swirl, _outline..strokeWidth = 2);
      // Tongue lolling out.
      canvas.drawOval(
          Rect.fromCenter(center: const Offset(-34, 26), width: 10, height: 14),
          Paint()..color = const Color(0xFFFF7F9A));
    } else {
      canvas.drawOval(
          Rect.fromCenter(
              center: const Offset(-6, -7),
              width: 20 - 3 * _evolution,
              height: 22 - 7 * _evolution),
          Paint()
            ..color = Color.lerp(
                const Color(0xFFFFFFFF), const Color(0xFFFF8D32), _evolution)!);
      canvas.drawOval(
          Rect.fromCenter(
              center: const Offset(-6, -7),
              width: 20 - 3 * _evolution,
              height: 22 - 7 * _evolution),
          _outline..strokeWidth = 2);
      final look = (target.y - position.y) / _scale < _head.y ? -2.0 : 2.0;
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset(-9, -6 + look),
              width: 12 - 7 * _evolution,
              height: 12 - 2 * _evolution),
          Paint()..color = const Color(0xFF2A120C));
      canvas.drawCircle(Offset(-11, -9 + look), 2.2,
          Paint()..color = const Color(0xFFFFFFFF));
      if (_evolution > 0) {
        _shape(
            canvas,
            Path()
              ..addPolygon([
                const Offset(-20, -23),
                const Offset(7, -18),
                Offset(5, -6 - 3 * (1 - _evolution)),
                const Offset(-19, -13),
              ], true),
            const Color(0xFFBD4932));
        canvas.drawLine(const Offset(-18, -13), const Offset(4, -6),
            _outline..strokeWidth = 3);
      }
      // Brow: frowning while attacking or enraged.
      final angry = phase == 2 || _move != _Move.idle;
      canvas.drawLine(Offset(-18, angry ? -22 : -20),
          Offset(4, angry ? -16 : -22), _outline..strokeWidth = 4);
    }
    canvas.restore();
  }

  void _paintDizzy(Canvas canvas) {
    final h = Offset(_head.x, _head.y);
    // Glowing weak spot: scratch here!
    final pulse = .5 + .5 * sin(_t * 9);
    canvas.drawOval(
        Rect.fromCenter(
            center: h + const Offset(-10, 4),
            width: 96 + 10 * pulse,
            height: 72 + 8 * pulse),
        Paint()
          ..color = Color.fromARGB((200 * pulse + 55).round(), 0xFF, 0xE0, 0x5A)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4);
    // Stars circling over the head.
    for (var i = 0; i < 3; i++) {
      final a = _t * 4 + i * pi * 2 / 3;
      final p = h + Offset(cos(a) * 26, -34 + sin(a) * 8);
      final star = Path();
      for (var j = 0; j < 10; j++) {
        final r = j.isEven ? 7.0 : 3.0;
        final b = j * pi / 5 - pi / 2;
        final q = p + Offset(cos(b) * r, sin(b) * r);
        j == 0 ? star.moveTo(q.dx, q.dy) : star.lineTo(q.dx, q.dy);
      }
      star.close();
      canvas.drawPath(star, Paint()..color = const Color(0xFFFFE15A));
      canvas.drawPath(star, _outline..strokeWidth = 1.5);
    }
  }

  void _paintIce(Canvas canvas) {
    if (frozen < .6 && (frozen * 12).floor().isEven) return;
    final block = RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(20, -70), width: 210, height: 160),
        const Radius.circular(24));
    canvas.drawRRect(block, Paint()..color = const Color(0x66C4ECFF));
    canvas.drawRRect(
        block,
        Paint()
          ..color = const Color(0xCC4E9CC4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4);
    final shine = Paint()
      ..color = const Color(0xCCFFFFFF)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(-70, -136), const Offset(-40, -146), shine);
    canvas.drawLine(const Offset(100, -10), const Offset(112, -30), shine);
  }

  void _landingDust(Canvas canvas, double k) {
    for (var i = 0; i < 8; i++) {
      final side = i.isEven ? -1 : 1;
      final x = side * (40 + k * 90 + (i ~/ 2) * 16);
      canvas.drawCircle(
          Offset(x + 10, -6 - (i % 3) * 6),
          10 + k * 16,
          Paint()
            ..color =
                Color.fromARGB((150 * (1 - k)).round(), 0xD8, 0xC8, 0xA4));
    }
  }
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

enum _Move { idle, breath, rain, tail }

// ===========================================================================
// Dragon attacks. Each runs on the dragon's clock (tick), so time stop
// freezes them in place.
// ===========================================================================

abstract class DragonAttack extends PositionComponent {
  DragonAttack({super.position, super.priority = 7});

  double t = 0;
  void tick(double dt) => t += dt;

  /// Still showing its warning (an interrupt cancels it).
  bool get warning;
  bool get done;

  /// Whether it hurts a cat with hitbox [box] this frame.
  bool hits(Rect box);
}

/// A band of fire across the lane, from the dragon's mouth to the arena edge.
/// Warns for [warn] seconds, then burns. A stone wall standing in the band
/// stops the flames at [blockedAt].
class DragonFlameLane extends DragonAttack {
  DragonFlameLane(
      {required this.laneY,
      required this.left,
      required this.right,
      required this.warn});

  double laneY;
  final double left, warn;
  double right;
  Vector2? emitter;
  static const double halfHeight = 24;
  static const double burn = .7;

  /// World x where a wall stops the fire (flames only right of it).
  double? blockedAt;

  @override
  bool get warning => t < warn;
  bool get burning => t >= warn && t < warn + burn;
  @override
  bool get done => t >= warn + burn + .15;

  double get _from => max(left, blockedAt ?? left);
  double get _front =>
      right - (right - _from) * ((t - warn) / .12).clamp(0.0, 1.0);

  @override
  bool hits(Rect box) =>
      burning &&
      box.overlaps(
          Rect.fromLTRB(_front, laneY - halfHeight, right, laneY + halfHeight));

  @override
  void render(Canvas canvas) {
    final band =
        Rect.fromLTRB(left, laneY - halfHeight, right, laneY + halfHeight);
    if (warning) {
      final k = t / warn;
      final pulse = .5 + .5 * sin(t * 26);
      canvas.drawRect(
          band,
          Paint()
            ..color = Color.fromARGB(
                (50 + 60 * k + 30 * pulse).round(), 0xFF, 0x3A, 0x2A));
      final edge = Paint()
        ..color = Color.fromARGB((160 + 90 * pulse).round(), 0xFF, 0x5A, 0x3A)
        ..strokeWidth = 2.5;
      canvas.drawLine(band.topLeft, band.topRight, edge);
      canvas.drawLine(band.bottomLeft, band.bottomRight, edge);
      // Fill sweeping from the mouth shows when it fires.
      canvas.drawRect(
          Rect.fromLTRB(
              right - (right - left) * k, band.top, right, band.bottom),
          Paint()..color = const Color(0x33FF2A1A));
      final chevron = Paint()
        ..color = const Color(0xCCFFF4DA)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      for (var x = right - 30 - (t * 160) % 60; x > left + 10; x -= 60) {
        canvas.drawPath(
            Path()
              ..moveTo(x + 8, laneY - 10)
              ..lineTo(x, laneY)
              ..lineTo(x + 8, laneY + 10),
            chevron);
      }
      return;
    }
    final e = t - warn;
    final fade = (e < burn ? 1.0 : 1 - (e - burn) / .15).clamp(0.0, 1.0);
    if (done || fade <= 0) return;
    final start = _front;
    final mouth = emitter ?? Vector2(right, laneY);
    final source = Offset(mouth.x, mouth.y);
    Color tint(int value) => Color(value).withAlpha((255 * fade).round());
    final length = max(1.0, source.dx - start);
    Offset center(double k) => Offset(source.dx - length * k,
        source.dy + (laneY - source.dy) * min(1.0, k * 6));
    Path jet(double thickness) {
      final path = Path()..moveTo(source.dx, source.dy);
      for (var i = 0; i <= 40; i++) {
        final k = i / 40;
        final c = center(k);
        final wave = sin(k * 32 - t * 35) * 2.8 + sin(k * 57 - t * 23) * 1.2;
        final width = (3 + 17 * min(1.0, k * 7) + wave) * thickness * fade;
        path.lineTo(c.dx, c.dy - width);
      }
      for (var i = 40; i >= 0; i--) {
        final k = i / 40;
        final c = center(k);
        final wave = sin(k * 37 - t * 31 + 1.4) * 3;
        final width = (3 + 17 * min(1.0, k * 7) + wave) * thickness * fade;
        path.lineTo(c.dx, c.dy + width);
      }
      return path..close();
    }

    // One continuous stream from the jaw, with layers moving toward the target.
    canvas.drawPath(
        jet(1.25),
        Paint()
          ..color = const Color(0x66FF5A20).withAlpha((90 * fade).round()));
    canvas.drawPath(
        jet(1),
        Paint()
          ..shader = LinearGradient(
            colors: [tint(0xFFFFE67A), tint(0xFFFFA12A), tint(0xFFE9451B)],
            begin: Alignment.centerRight,
            end: Alignment.centerLeft,
          ).createShader(Rect.fromLTRB(
              start, laneY - halfHeight, right + 1, laneY + halfHeight)));
    canvas.drawPath(jet(.56),
        Paint()..color = Color.fromARGB((240 * fade).round(), 255, 201, 69));
    canvas.drawPath(jet(.23),
        Paint()..color = Color.fromARGB((250 * fade).round(), 255, 247, 203));
    for (var i = 0; i < 12; i++) {
      final k = (t * 1.9 + i / 12) % 1;
      final c = center(k);
      final side = sin(i * 2.4 + t * 8) * (5 + k * 11);
      canvas.drawOval(
          Rect.fromCenter(
              center: c + Offset(0, side),
              width: 15 + 12 * k,
              height: 3 + 4 * k),
          Paint()
            ..color = Color.fromARGB(
                (120 * fade * (1 - k * .6)).round(), 255, 239, 135));
    }
    if (blockedAt != null && blockedAt! > left && start <= _from + 1) {
      for (var i = 0; i < 7; i++) {
        final k = (t * 3 + i / 7) % 1;
        canvas.drawCircle(
            Offset(_from + sin(i * 2.3) * k * 20, laneY - k * 40),
            2.5 * (1 - k) + 1,
            Paint()
              ..color =
                  Color.fromARGB((220 * (1 - k) * fade).round(), 255, 221, 96));
      }
    }
  }
}

void _tongue(Canvas canvas, Offset base, double h, double w, double alpha) {
  if (h <= 1) return;
  Path p(double ww, double hh) => Path()
    ..moveTo(base.dx - ww, base.dy)
    ..quadraticBezierTo(base.dx - ww, base.dy - hh * .6, base.dx, base.dy - hh)
    ..quadraticBezierTo(base.dx + ww, base.dy - hh * .6, base.dx + ww, base.dy)
    ..close();
  canvas.drawPath(p(w, h * 2),
      Paint()..color = Color.fromARGB((220 * alpha).round(), 0xF0, 0x58, 0x2A));
  canvas.drawPath(p(w * .65, h * 1.4),
      Paint()..color = Color.fromARGB((235 * alpha).round(), 0xFF, 0xB1, 0x3A));
  canvas.drawPath(p(w * .3, h * .8),
      Paint()..color = Color.fromARGB((255 * alpha).round(), 0xFF, 0xF2, 0xB0));
}

/// A fireball lobbed onto [target]: its ground shadow grows for [flight]
/// seconds, then it bursts. A stone wall next to the spot catches it.
class DragonMeteor extends DragonAttack {
  DragonMeteor(
      {required Vector2 from, required this.target, required this.flight})
      : _from = from.clone(),
        super(position: target.clone(), priority: 8);

  final Vector2 _from;
  final Vector2 target;
  final double flight;
  static const double radius = 36;
  bool blocked = false;
  bool impactNow = false;

  @override
  void tick(double dt) {
    final before = t;
    super.tick(dt);
    impactNow = before < flight && t >= flight;
  }

  @override
  bool get warning => t < flight;
  @override
  bool get done => t >= flight + .4;

  @override
  bool hits(Rect box) =>
      impactNow &&
      !blocked &&
      inGroundEllipse(Vector2(box.center.dx, box.center.dy), target, radius,
          margin: 10);

  @override
  void render(Canvas canvas) {
    final zone = groundEllipse(Vector2.zero(), radius);
    if (t < flight) {
      final k = t / flight;
      canvas.drawOval(
          zone,
          Paint()
            ..color = Color.fromARGB((40 + 90 * k).round(), 0xE0, 0x30, 0x20));
      canvas.drawOval(
          zone,
          Paint()
            ..color = const Color(0xDDFF5A3A)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5);
      canvas.drawOval(groundEllipse(Vector2.zero(), radius * k),
          Paint()..color = const Color(0x55801010));
      Offset point(double progress) {
        final ground = (_from + (target - _from) * progress) - target;
        return Offset(ground.x, ground.y - sin(pi * progress) * 90);
      }

      final p = point(k);
      final samples =
          List.generate(10, (i) => point(max(0.0, k - (9 - i) * .016)));
      final ribbon = Path();
      for (var i = 0; i < samples.length; i++) {
        final tangent = samples[min(i + 1, 9)] - samples[max(0, i - 1)];
        final len = tangent.distance;
        final normal = len > .001
            ? Offset(-tangent.dy, tangent.dx) / len
            : const Offset(0, 1);
        final edge = samples[i] + normal * (i / 9 * 12);
        if (i == 0) {
          ribbon.moveTo(edge.dx, edge.dy);
        } else {
          ribbon.lineTo(edge.dx, edge.dy);
        }
      }
      for (var i = 9; i >= 0; i--) {
        final tangent = samples[min(i + 1, 9)] - samples[max(0, i - 1)];
        final len = tangent.distance;
        final normal = len > .001
            ? Offset(-tangent.dy, tangent.dx) / len
            : const Offset(0, 1);
        final edge = samples[i] - normal * (i / 9 * 12);
        ribbon.lineTo(edge.dx, edge.dy);
      }
      ribbon.close();
      canvas.drawPath(ribbon, Paint()..color = const Color(0xDDFF8B25));
      // Hot core and soft halo travel along the same arc as the tail.
      canvas.drawCircle(
          p,
          25,
          Paint()
            ..shader = const RadialGradient(
                    colors: [Color(0x99FFB13A), Color(0x00FF6A20)])
                .createShader(Rect.fromCircle(center: p, radius: 25)));
      canvas.drawCircle(
          p,
          14,
          Paint()
            ..shader = const RadialGradient(
              center: Alignment(-.3, -.3),
              colors: [
                Color(0xFFFFF6CC),
                Color(0xFFFFD45C),
                Color(0xFFFF872A),
                Color(0xFFD93920)
              ],
              stops: [0, .3, .65, 1],
            ).createShader(Rect.fromCircle(center: p, radius: 14)));
      for (var i = 1; i < 6; i++) {
        final progress = max(0.0, k - i * .028);
        if (progress == 0) continue;
        final q = point(progress) +
            Offset(sin(i * 4.2 + t * 12) * 5, cos(i * 2.7 + t * 8) * 5);
        canvas.drawCircle(q, 1.2 + (6 - i) * .3,
            Paint()..color = Color.fromARGB(200 - i * 25, 255, 220, 106));
      }
      return;
    }
    if (done) return;
    final e = ((t - flight) / .4).clamp(0.0, 1.0);
    final fade = 1 - e;
    canvas.drawOval(
        zone.inflate(14 * e),
        Paint()
          ..color = Color.fromARGB((210 * fade).round(), 0xFF, 0x9A, 0x3A));
    canvas.drawOval(
        zone.inflate(26 * e),
        Paint()
          ..color = Color.fromARGB((255 * fade).round(), 0xFF, 0xF4, 0xDA)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4);
    for (var i = 0; i < 5; i++) {
      final a = i * 1.26;
      _tongue(canvas, Offset(cos(a) * radius * .5, sin(a) * radius * .3 + 6),
          14 * fade, 7, fade);
    }
  }
}

/// The tail swings across the lane in front of the dragon. Warns with a red
/// zone, then turns counterclockwise, sweeping down its left side.
class DragonTailSweep extends DragonAttack {
  DragonTailSweep({
    required this.road,
    required this.left,
    required this.right,
    required this.root,
    required this.warn,
    this.visualScale = 1,
    this.restClock = 0,
  });

  final ReturnHomeRoad road;
  final double left, right, warn, visualScale;
  final Vector2 root;
  double restClock;
  double bulk = 0;
  static const double sweep = .7;
  static const double recovery = .55;

  @override
  bool get warning => t < warn;
  bool get sweeping => t >= warn && t < warn + sweep;
  @override
  bool get done => t >= warn + sweep + recovery;

  double get _strike => _smoothUnit((t - warn) / sweep);
  double get _recover => _smoothUnit((t - warn - sweep) / recovery);
  double get bodyTurn => warning
      ? -.22 * _smoothUnit(t / warn)
      : sweeping
          ? -.22 + .56 * _strike
          : .34 * (1 - _recover);
  Offset get bodyShift => warning
      ? const Offset(8, 6) * _smoothUnit(t / warn)
      : sweeping
          ? Offset(8 - 20 * _strike, 6 - 6 * _strike)
          : const Offset(-12, 0) * (1 - _recover);
  double get crouch => warning
      ? 6 * _smoothUnit(t / warn)
      : sweeping
          ? 6 * (1 - _strike)
          : 0;
  double get wingSpread => warning
      ? .7 * _smoothUnit(t / warn)
      : sweeping
          ? .7 + .3 * sin(_strike * pi)
          : .7 * (1 - _recover);

  /// One complete turn: left-facing, right-facing, then left-facing again.
  double get bodyYaw => warning
      ? -.28 * _smoothUnit(t / warn)
      : sweeping
          ? -.28 - 2 * pi * _strike
          : -2 * pi - .28 * (1 - _recover);

  List<Offset>? posedCenterline;
  List<Offset> get localCenterline =>
      _dragonTailPoints(const Offset(62, -32), 1, restClock,
          attackTime: t, warn: warn);
  List<Offset> get centerline =>
      posedCenterline ??
      _dragonTailPoints(Offset(root.x, root.y), visualScale, restClock,
          attackTime: t, warn: warn);

  Rect get _zone {
    final mid = (left + right) / 2;
    final half = road.halfWidth(mid) + 14;
    final c = road.centerY(mid);
    return Rect.fromLTRB(left, c - half, right, c + half);
  }

  @override
  bool hits(Rect box) {
    if (!sweeping || !box.overlaps(_zone)) return false;
    final points = centerline;
    for (var i = 0; i < points.length - 1; i++) {
      final radius =
          ((15 + 6 * bulk) * (1 - i / (points.length - 1)) + 2) * visualScale;
      if (_tailSegmentHits(points[i], points[i + 1], box.inflate(radius))) {
        return true;
      }
    }
    return false;
  }

  @override
  void render(Canvas canvas) {
    final zone = _zone;
    if (warning) {
      final k = t / warn;
      final pulse = .5 + .5 * sin(t * 24);
      final r = RRect.fromRectAndRadius(zone, const Radius.circular(18));
      canvas.drawRRect(
          r,
          Paint()
            ..color = Color.fromARGB(
                (40 + 60 * k + 30 * pulse).round(), 0xFF, 0x3A, 0x2A));
      canvas.drawRRect(
          r,
          Paint()
            ..color =
                Color.fromARGB((170 + 80 * pulse).round(), 0xFF, 0x5A, 0x3A)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3);
      // Follow the counterclockwise turn down the dragon's left side.
      final arrow = Paint()
        ..color = const Color(0xCCFFF4DA)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round;
      final c = zone.center;
      const startAngle = -pi * .55;
      const sweepAngle = -pi * .9;
      const endAngle = startAngle + sweepAngle;
      canvas.drawArc(
          Rect.fromCenter(
              center: c, width: zone.width * .7, height: zone.height * .8),
          startAngle,
          sweepAngle,
          false,
          arrow);
      final end = c +
          Offset(cos(endAngle) * zone.width * .35,
              sin(endAngle) * zone.height * .4);
      final tangent = Vector2(
          sin(endAngle) * zone.width * .35, -cos(endAngle) * zone.height * .4)
        ..normalize();
      final back = Offset(tangent.x, tangent.y) * -12;
      final side = Offset(-tangent.y, tangent.x) * 6;
      canvas.drawLine(end, end + back + side, arrow);
      canvas.drawLine(end, end + back - side, arrow);
      return;
    }
    // Only wind streaks and ground dust live here. The dragon draws its own
    // attached, tapered tail from this same centerline and attack clock.
    if (done) return;
    final fade = sweeping ? 1.0 : 1 - _recover;
    if (sweeping) {
      final points = centerline;
      final streak = Path();
      for (var i = 12; i < points.length; i++) {
        final p = points[i] + const Offset(8, -6);
        if (i == 12) {
          streak.moveTo(p.dx, p.dy);
        } else {
          streak.lineTo(p.dx, p.dy);
        }
      }
      canvas.drawPath(
          streak,
          Paint()
            ..color = const Color(0x88FFF4DA)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 5 * visualScale
            ..strokeCap = StrokeCap.round);
    }
    final tip = centerline.last;
    for (var i = 0; i < 5; i++) {
      final p = tip + Offset((i - 2) * 7.0, 12 + sin(i * 2 + t * 7) * 4);
      canvas.drawCircle(p, (3 + i % 3) * visualScale,
          Paint()..color = Color.fromARGB((90 * fade).round(), 216, 200, 164));
    }
  }
}

/// A damage number floating up from where the dragon was hit.
class ReturnHomeDamageText extends PositionComponent {
  ReturnHomeDamageText(
      {required Vector2 position,
      required this.text,
      this.color = const Color(0xFFFFF4DA)})
      : super(position: position, priority: 10);

  final String text;
  final Color color;
  double _t = 0;
  static const double _life = .75;

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    position.y -= 40 * dt;
    if (_t > _life) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final fade = 1 - _t / _life;
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w900,
          color: color.withAlpha((255 * fade).round()),
          shadows: [
            Shadow(
                color: const Color(0xFF4A1E14).withAlpha((255 * fade).round()),
                blurRadius: 3)
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, Offset(-painter.width / 2, -painter.height / 2));
  }
}
