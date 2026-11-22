import 'dart:math' as math;
import 'package:flutter/painting.dart';
import '../collection/fish_collection.dart';
import '../collection/fish_species.dart';

/// One-way ledge: the cat lands on [top] between [left] and [right].
class CaveLedge {
  const CaveLedge(this.left, this.right, this.top, {this.ground = false});
  final double left, right, top;
  final bool ground;
}

enum CaveRunState { ready, running, falling, finished }

/// Side-scrolling parkour inside the island mountain. The cat runs on its
/// own; a tap jumps and a second tap in the air jumps again. Pits and
/// crystal spikes send it back to the last checkpoint. Session-only except
/// the once-a-day chest reward.
class FishingCave {
  static const height = 480.0, length = 3600.0, floor = 400.0;
  static const speed = 235.0, gravity = 1750.0, jumpSpeed = 660.0;
  static const doubleJumpSpeed = 560.0, finishX = 3440.0;
  static const rewardKey = 'fishing_cave_day_v1';

  static const ledges = [
    CaveLedge(0, 520, floor, ground: true),
    CaveLedge(640, 1000, floor, ground: true),
    CaveLedge(1060, 1170, 330),
    CaveLedge(1230, 1380, floor, ground: true),
    CaveLedge(1430, 1540, 310),
    CaveLedge(1590, 1690, 250),
    CaveLedge(1750, 2080, floor, ground: true),
    CaveLedge(2150, 2260, 330),
    CaveLedge(2310, 2400, 270),
    CaveLedge(2450, 2760, floor, ground: true),
    CaveLedge(2830, 2930, 320),
    CaveLedge(2990, 3080, 260),
    CaveLedge(3140, length, floor, ground: true),
  ];

  /// Crystal spike clusters on the ground: centre x and half width.
  static const spikes = [(820.0, 20.0), (1960.0, 22.0), (2640.0, 20.0)];

  /// Respawn points (start of each ground run).
  static const checkpoints = [40.0, 660.0, 1770.0, 2470.0, 3160.0];

  /// Golden fish tokens to collect.
  static final tokens = <Offset>[
    const Offset(300, 350),
    const Offset(380, 320),
    const Offset(580, 300),
    const Offset(820, 300),
    const Offset(1110, 280),
    const Offset(1200, 300),
    const Offset(1480, 260),
    const Offset(1640, 200),
    const Offset(1960, 300),
    const Offset(2200, 280),
    const Offset(2360, 220),
    const Offset(2640, 300),
    const Offset(2880, 270),
    const Offset(3040, 210),
    const Offset(3300, 350),
  ];

  bool inside = false;
  CaveRunState state = CaveRunState.ready;
  Offset cat = const Offset(40, floor);
  double vy = 0, clock = 0, runTime = 0, hurt = 0;
  bool grounded = true, doubleJumpUsed = false;
  int checkpoint = 0, falls = 0;
  final collected = <int>{};
  double _coyote = 0, _buffer = 0;

  /// Fish given by the chest on the first finish today, or null.
  List<FishSpecies>? reward;
  bool rewardChecked = false;

  void enter() {
    inside = true;
    restart();
  }

  void exit() => inside = false;

  void restart() {
    state = CaveRunState.ready;
    cat = Offset(checkpoints.first, floor);
    vy = 0;
    runTime = 0;
    hurt = 0;
    grounded = true;
    doubleJumpUsed = false;
    checkpoint = 0;
    falls = 0;
    collected.clear();
    reward = null;
    rewardChecked = false;
  }

  /// Tap: start the run, then jump / double jump.
  void tap() {
    switch (state) {
      case CaveRunState.ready:
        state = CaveRunState.running;
      case CaveRunState.running:
        _buffer = .12;
      case CaveRunState.falling || CaveRunState.finished:
        break;
    }
  }

  void update(double dt) {
    clock += dt;
    hurt = math.max(0, hurt - dt);
    if (state == CaveRunState.falling) {
      vy += gravity * dt;
      cat += Offset(0, vy * dt);
      if (cat.dy > height + 120) _respawn();
      return;
    }
    if (state != CaveRunState.running) return;
    runTime += dt;
    _buffer = math.max(0, _buffer - dt);
    _coyote = grounded ? .09 : math.max(0, _coyote - dt);
    if (_buffer > 0) {
      if (grounded || _coyote > 0) {
        vy = -jumpSpeed;
        grounded = false;
        _coyote = 0;
        _buffer = 0;
      } else if (!doubleJumpUsed) {
        vy = -doubleJumpSpeed;
        doubleJumpUsed = true;
        _buffer = 0;
      }
    }
    final before = cat;
    vy += gravity * dt;
    var next = Offset(cat.dx + speed * dt, cat.dy + vy * dt);
    grounded = false;
    if (vy >= 0) {
      for (final l in ledges) {
        if (next.dx < l.left - 6 || next.dx > l.right + 6) continue;
        if (before.dy <= l.top + .5 && next.dy >= l.top) {
          next = Offset(next.dx, l.top);
          vy = 0;
          grounded = true;
          doubleJumpUsed = false;
          break;
        }
      }
    }
    cat = next;
    for (var i = checkpoints.length - 1; i > checkpoint; i--) {
      if (cat.dx >= checkpoints[i] && grounded) {
        checkpoint = i;
        break;
      }
    }
    for (var i = 0; i < tokens.length; i++) {
      if ((tokens[i] - (cat - const Offset(0, 30))).distance < 34) {
        collected.add(i);
      }
    }
    for (final (x, half) in spikes) {
      if ((cat.dx - x).abs() < half + 10 && cat.dy > floor - 26) {
        _fall(hit: true);
        return;
      }
    }
    if (cat.dy > floor + 60) _fall();
    if (cat.dx >= finishX && grounded) state = CaveRunState.finished;
  }

  void _fall({bool hit = false}) {
    state = CaveRunState.falling;
    falls++;
    hurt = .6;
    if (hit) vy = -420;
  }

  void _respawn() {
    state = CaveRunState.running;
    cat = Offset(checkpoints[checkpoint], floor);
    vy = 0;
    grounded = true;
    doubleJumpUsed = false;
    _buffer = 0;
  }

  static String _day(DateTime now) => '${now.year}-${now.month}-${now.day}';

  /// First finish each day: one fish plus one per five tokens, into the basket.
  Future<void> claimReward(FishCollection collection,
      {math.Random? random}) async {
    if (rewardChecked) return;
    rewardChecked = true;
    final today = _day(DateTime.now());
    if (collection.preferences.getString(rewardKey) == today) return;
    final rng = random ?? math.Random();
    const pool = [
      FishSpecies.cavefish,
      FishSpecies.cavefish,
      FishSpecies.catfish,
      FishSpecies.lanternfish,
    ];
    final fish = [
      for (var i = 0; i < 1 + collected.length ~/ 5; i++)
        pool[rng.nextInt(pool.length)]
    ];
    if (!await collection.addToBasket(fish)) return;
    await collection.preferences.setString(rewardKey, today);
    reward = fish;
  }
}
