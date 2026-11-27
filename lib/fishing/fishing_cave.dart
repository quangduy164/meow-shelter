import '../game/constants.dart';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/painting.dart';
import '../collection/fish_collection.dart';
import '../collection/fish_species.dart';
import '../audio/game_audio.dart';

/// One-way ledge: the cat lands on [top] between [left] and [right].
/// A [crumble] ledge drops away [CaveRun.crumbleDelay] after it is stood on.
class CaveLedge {
  const CaveLedge(this.left, this.right, this.top,
      {this.ground = false, this.crumble = false});
  final double left, right, top;
  final bool ground, crumble;
}

/// Bat flying in place at [base]; bobs vertically by [swing].
class CaveBat {
  const CaveBat(this.base, {this.swing = 45, this.phase = 0});
  final Offset base;
  final double swing, phase;
}

/// Low ceiling between [left] and [right]: the cat's head bumps at [bottom].
class CaveCeiling {
  const CaveCeiling(this.left, this.right, this.bottom);
  final double left, right, bottom;
}

enum CaveRunState { ready, running, falling, finished }

/// Side-scrolling parkour inside the island mountain, in three sections that
/// get harder: the cat runs faster and faster; a tap jumps and a second tap in
/// the air jumps again. Pits, crystal spikes, falling stalactites, bats and
/// crumbling ledges send it back to the section start; low ceilings stop high
/// jumps. Stars rate the run; the best stars/time and a once-a-day chest
/// reward are saved.
class FishingCave {
  static const height = 480.0, length = 7200.0, floor = 400.0;
  static const startSpeed = 235.0, endSpeed = 320.0;
  static const gravity = 1750.0, jumpSpeed = 660.0;
  static const doubleJumpSpeed = 560.0, finishX = 7040.0;
  static const crumbleDelay = .45, headHeight = 58.0;
  static const rewardKey = 'fishing_cave_day_v1';
  static const bestKey = 'fishing_cave_best_v1';

  static double speedAt(double x) =>
      startSpeed + (endSpeed - startSpeed) * (x / length).clamp(0.0, 1.0);

  static const sectionNames = ['Cửa hang', 'Hang sâu', 'Lòng núi'];

  /// Respawn points: the start of each section.
  static const checkpoints = [40.0, 2420.0, 4820.0];

  static const ledges = [
    // Section 1: easy.
    CaveLedge(0, 520, floor, ground: true),
    CaveLedge(660, 1000, floor, ground: true),
    CaveLedge(1060, 1170, 330),
    CaveLedge(1230, 1380, floor, ground: true),
    CaveLedge(1430, 1540, 310),
    CaveLedge(1590, 1690, 250),
    CaveLedge(1750, 2080, floor, ground: true),
    CaveLedge(2240, 2700, floor, ground: true),
    // Section 2: medium.
    CaveLedge(2900, 3150, floor, ground: true),
    CaveLedge(3230, 3330, 330, crumble: true),
    CaveLedge(3400, 3500, 270, crumble: true),
    CaveLedge(3570, 3900, floor, ground: true),
    CaveLedge(4100, 4800, floor, ground: true),
    // Section 3: hard.
    CaveLedge(4800, 5050, floor, ground: true),
    CaveLedge(5270, 5520, floor, ground: true),
    CaveLedge(5610, 5700, 320, crumble: true),
    CaveLedge(5770, 5860, 260, crumble: true),
    CaveLedge(5930, 6020, 210, crumble: true),
    CaveLedge(6090, 6360, floor, ground: true),
    CaveLedge(6560, length, floor, ground: true),
  ];

  /// Crystal spike clusters on the ground: centre x and half width.
  static const spikes = [
    (840.0, 20.0),
    (1960.0, 22.0),
    (3040.0, 22.0),
    (3730.0, 20.0),
    (4320.0, 24.0),
    (5400.0, 24.0),
    (6250.0, 22.0),
    (6760.0, 26.0),
  ];

  /// Stalactites: x; each drops when the cat comes within [stalactiteTrigger]
  /// and shatters into a shard pile the cat must jump.
  static const stalactites = [1880.0, 3840.0, 4620.0, 5160.0, 6900.0];
  static const stalactiteTrigger = 230.0, stalactiteTop = 70.0;

  /// Half width of the shard pile a stalactite leaves on the floor.
  static const shardHalf = 18.0;

  static const bats = [
    CaveBat(Offset(2560, 320), phase: 0),
    CaveBat(Offset(4480, 300), phase: 1.4),
    CaveBat(Offset(5140, 250), swing: 60, phase: .6),
    CaveBat(Offset(6460, 300), swing: 55, phase: 2.2),
  ];

  static const ceilings = [
    CaveCeiling(3640, 3820, 250),
    CaveCeiling(6150, 6330, 260),
  ];

  /// Golden fish tokens; the harder ones sit high or right by a hazard.
  static final tokens = <Offset>[
    const Offset(300, 350),
    const Offset(590, 300),
    const Offset(840, 290),
    const Offset(1110, 280),
    const Offset(1480, 260),
    const Offset(1640, 190),
    const Offset(1960, 300),
    const Offset(2160, 290),
    const Offset(2560, 230),
    const Offset(2800, 260),
    const Offset(3040, 300),
    const Offset(3280, 270),
    const Offset(3450, 200),
    const Offset(3730, 350),
    const Offset(4000, 260),
    const Offset(4320, 290),
    const Offset(4480, 220),
    const Offset(5160, 230),
    const Offset(5400, 280),
    const Offset(5650, 260),
    const Offset(5980, 140),
    const Offset(6250, 350),
    const Offset(6460, 220),
    const Offset(6760, 280),
  ];

  (String, int, double) get pose {
    // Pit or crystal spike: the cat panics while it drops.
    if (state == CaveRunState.falling) {
      return ('panic', (clock * 8).floor() % framesPanic, 0);
    }
    // Double jump: a somersault through the curled frames 1-4 of the roll.
    if (spin > 0) {
      final t = 1 - spin / FishingCave.spinTime;
      return ('roll', 1 + (t * 4).floor().clamp(0, 3), 0);
    }
    final airborne = !grounded || state == CaveRunState.falling;
    if (airborne) {
      final frame = vy < -280
          ? 1
          : vy < 280
              ? 2
              : 3;
      return ('jump', frame, jumpSheetLift[frame]);
    }
    if (landing > 0) return ('jump', 4, 0);
    if (state == CaveRunState.running) {
      return ('run', (clock * 10).floor() % framesRun, 0);
    }
    return ('idle', (clock * 7).floor() % framesIdle, 0);
  }

  bool inside = false;
  CaveRunState state = CaveRunState.ready;
  Offset cat = const Offset(40, floor);
  double vy = 0, clock = 0, runTime = 0, hurt = 0;

  /// Seconds left of the landing pose after touching down.
  double landing = 0;

  /// Seconds left of the somersault after a double jump.
  double spin = 0;
  static const spinTime = .8;

  /// Seconds left of the head-bump wobble under a low ceiling.
  double bonk = 0;
  bool grounded = true, doubleJumpUsed = false;
  int checkpoint = 0, falls = 0;
  final collected = <int>{};
  double _coyote = 0, _buffer = 0;

  /// Per crumbling ledge: seconds stood on (null = untouched), gone when
  /// past [crumbleDelay].
  final crumbleTime = List<double?>.filled(ledges.length, null);

  /// Per stalactite: current tip y once falling (null = still hanging).
  final stalactiteY = List<double?>.filled(stalactites.length, null);
  final _stalactiteSpeed = List<double>.filled(stalactites.length, 0);

  /// Results of the finished run.
  int stars = 0;
  bool newBest = false;
  ({int stars, double time})? best;

  /// Fish given by the chest on the first finish today, or null.
  List<FishSpecies>? reward;
  bool rewardChecked = false;

  bool ledgeGone(int i) => (crumbleTime[i] ?? 0) >= crumbleDelay;
  int get section {
    var s = 0;
    for (var i = 0; i < checkpoints.length; i++) {
      if (cat.dx >= checkpoints[i] - 20) s = i;
    }
    return s;
  }

  Offset batAt(int i) {
    final b = bats[i];
    return b.base +
        Offset(math.sin(clock * 1.3 + b.phase) * 14,
            math.sin(clock * 2.2 + b.phase) * b.swing);
  }

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
    bonk = 0;
    grounded = true;
    doubleJumpUsed = false;
    checkpoint = 0;
    falls = 0;
    collected.clear();
    _resetHazards(0);
    stars = 0;
    newBest = false;
    reward = null;
    rewardChecked = false;
  }

  /// Hazards from [fromX] on are restored (crumbled ledges, stalactites).
  void _resetHazards(double fromX) {
    for (var i = 0; i < ledges.length; i++) {
      if (ledges[i].right >= fromX) crumbleTime[i] = null;
    }
    for (var i = 0; i < stalactites.length; i++) {
      if (stalactites[i] >= fromX) {
        stalactiteY[i] = null;
        _stalactiteSpeed[i] = 0;
      }
    }
  }

  /// Tap: start the run, then jump / double jump.
  void tap() {
    switch (state) {
      case CaveRunState.ready:
        state = CaveRunState.running;
        GameAudio.instance.playGameplay(GameSound.fishingJump);
      case CaveRunState.running:
        _buffer = .12;
      case CaveRunState.falling || CaveRunState.finished:
        break;
    }
  }

  void update(double dt) {
    clock += dt;
    hurt = math.max(0, hurt - dt);
    landing = math.max(0, landing - dt);
    spin = math.max(0, spin - dt);
    bonk = math.max(0, bonk - dt);
    _updateStalactites(dt);
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
        GameAudio.instance.playGameplay(GameSound.fishingJump);
        grounded = false;
        _coyote = 0;
        _buffer = 0;
      } else if (!doubleJumpUsed) {
        vy = -doubleJumpSpeed;
        GameAudio.instance.playGameplay(GameSound.adventureWings);
        doubleJumpUsed = true;
        spin = spinTime;
        _buffer = 0;
      }
    }
    final before = cat;
    final wasGrounded = grounded;
    vy += gravity * dt;
    var next = Offset(cat.dx + speedAt(cat.dx) * dt, cat.dy + vy * dt);
    // Low ceilings stop the head.
    for (final c in ceilings) {
      if (next.dx < c.left - 12 || next.dx > c.right + 12) continue;
      if (vy < 0 && next.dy - headHeight < c.bottom) {
        next = Offset(next.dx, c.bottom + headHeight);
        vy = 80;
        if (bonk <= 0) GameAudio.instance.playGameplay(GameSound.homeImpact);
        bonk = .25;
        spin = 0;
      }
    }
    grounded = false;
    if (vy >= 0) {
      for (var i = 0; i < ledges.length; i++) {
        final l = ledges[i];
        if (ledgeGone(i)) continue;
        if (next.dx < l.left - 6 || next.dx > l.right + 6) continue;
        if (before.dy <= l.top + .5 && next.dy >= l.top) {
          next = Offset(next.dx, l.top);
          if (!wasGrounded && vy > 120) {
            landing = .12;
            GameAudio.instance.playGameplay(GameSound.rackShake);
          }
          vy = 0;
          grounded = true;
          doubleJumpUsed = false;
          spin = 0;
          if (l.crumble) crumbleTime[i] ??= 0;
          break;
        }
      }
    }
    cat = next;
    for (var i = 0; i < ledges.length; i++) {
      final t = crumbleTime[i];
      if (t != null && t < crumbleDelay) crumbleTime[i] = t + dt;
    }
    for (var i = checkpoints.length - 1; i > checkpoint; i--) {
      if (cat.dx >= checkpoints[i] && grounded) {
        checkpoint = i;
        break;
      }
    }
    final body = cat - const Offset(0, 30);
    for (var i = 0; i < tokens.length; i++) {
      if ((tokens[i] - body).distance < 34 && collected.add(i)) {
        GameAudio.instance.playGameplay(GameSound.toyBeat);
      }
    }
    for (final (x, half) in spikes) {
      if ((cat.dx - x).abs() < half + 10 && cat.dy > floor - 26) {
        _fall(hit: true);
        return;
      }
    }
    for (var i = 0; i < bats.length; i++) {
      if ((batAt(i) - body).distance < 32) {
        _fall(hit: true);
        return;
      }
    }
    for (var i = 0; i < stalactites.length; i++) {
      final tip = stalactiteY[i];
      if (tip == null) continue;
      // Shattered: a pile of sharp shards on the floor, like a spike.
      final hit = tip >= floor
          ? (cat.dx - stalactites[i]).abs() < shardHalf + 10 &&
              cat.dy > floor - 22
          : (cat.dx - stalactites[i]).abs() < 20 &&
              tip > cat.dy - headHeight &&
              tip - 50 < cat.dy;
      if (hit) {
        _fall(hit: true);
        return;
      }
    }
    if (cat.dy > floor + 60) _fall();
    if (cat.dx >= finishX && grounded) _finish();
  }

  void _updateStalactites(double dt) {
    for (var i = 0; i < stalactites.length; i++) {
      final y = stalactiteY[i];
      if (y == null) {
        if (state == CaveRunState.running &&
            cat.dx > stalactites[i] - stalactiteTrigger &&
            cat.dx < stalactites[i]) {
          stalactiteY[i] = stalactiteTop;
          GameAudio.instance.playGameplay(GameSound.rescueFlood);
        }
        continue;
      }
      if (y >= floor) continue;
      _stalactiteSpeed[i] += gravity * .8 * dt;
      stalactiteY[i] = math.min(floor, y + _stalactiteSpeed[i] * dt);
      if (stalactiteY[i] == floor) {
        GameAudio.instance.playGameplay(GameSound.adventureStoneBreak);
      }
    }
  }

  void _fall({bool hit = false}) {
    state = CaveRunState.falling;
    falls++;
    spin = 0;
    hurt = .6;
    GameAudio.instance.playGameplay(GameSound.homeHit, priority: 2);
    if (hit) vy = -420;
  }

  void _respawn() {
    state = CaveRunState.running;
    cat = Offset(checkpoints[checkpoint], floor);
    vy = 0;
    grounded = true;
    doubleJumpUsed = false;
    _buffer = 0;
    _resetHazards(checkpoints[checkpoint]);
  }

  /// 1 star for finishing, +1 for 60% of the golden fish, +1 for 90% of
  /// them with at most one fall.
  static int rate(int tokensCollected, int falls) {
    final share = tokensCollected / tokens.length;
    return 1 + (share >= .6 ? 1 : 0) + (share >= .9 && falls <= 1 ? 1 : 0);
  }

  void _finish() {
    state = CaveRunState.finished;
    stars = rate(collected.length, falls);
    GameAudio.instance.playGameplay(GameSound.homeWin, priority: 3);
  }

  static String _day(DateTime now) => '${now.year}-${now.month}-${now.day}';

  static ({int stars, double time})? loadBest(FishCollection collection) {
    final saved = collection.preferences.getString(bestKey);
    if (saved == null) return null;
    try {
      final m = jsonDecode(saved) as Map<String, dynamic>;
      return (
        stars: (m['stars'] as num).toInt(),
        time: (m['time'] as num).toDouble()
      );
    } catch (_) {
      return null;
    }
  }

  /// Saves the best run (more stars, then faster) and, on the first finish
  /// each day, puts [stars] cave fish into the basket; 3 stars guarantees a
  /// lanternfish.
  Future<void> claimReward(FishCollection collection,
      {math.Random? random}) async {
    if (rewardChecked) return;
    rewardChecked = true;
    final old = loadBest(collection);
    if (old == null ||
        stars > old.stars ||
        (stars == old.stars && runTime < old.time)) {
      newBest = true;
      await collection.preferences
          .setString(bestKey, jsonEncode({'stars': stars, 'time': runTime}));
      best = (stars: stars, time: runTime);
    } else {
      best = old;
    }
    final today = _day(DateTime.now());
    if (collection.preferences.getString(rewardKey) == today) return;
    final rng = random ?? math.Random();
    const pool = [
      FishSpecies.cavefish,
      FishSpecies.cavefish,
      FishSpecies.catfish,
    ];
    final fish = [
      if (stars >= 3) FishSpecies.lanternfish,
      for (var i = stars >= 3 ? 1 : 0; i < stars; i++)
        pool[rng.nextInt(pool.length)],
    ];
    if (!await collection.addToBasket(fish)) return;
    await collection.preferences.setString(rewardKey, today);
    reward = fish;
    GameAudio.instance.playGameplay(GameSound.fishingCoins, priority: 2);
  }
}
