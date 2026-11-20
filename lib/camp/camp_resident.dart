import 'dart:math';
import '../audio/game_audio.dart';

/// What a camp cat is doing; each maps to one sprite sheet.
enum CampAct {
  idle('idle', 6, 5),
  walk('walk', 6, 9),
  run('run', 8, 13),
  turn('turn-around', 6, 10),
  celebrate('celebrate', 5, 8),
  panic('panic', 4, 9),
  dash('dash-escape', 6, 12),
  vanish('vanish', 6, 6),
  held('dragged', 4, 7),
  land('drop-success', 5, 9),
  sulk('drop-wrong', 5, 7);

  const CampAct(this.sheet, this.frames, this.fps);
  final String sheet;
  final int frames;
  final double fps;

  /// One full play of the sheet, for actions that run once.
  double get length => frames / fps;
}

/// Decorations a cat can walk to, and what it does on arrival.
const campToyActs = {
  'yarn': CampAct.celebrate, // bats the yarn around
  'post': CampAct.dash, // scratches and pounces off the post
  'bowl': CampAct.idle, // sits and watches the fish
  'bed': CampAct.idle, // naps (see [campNapToys])
  'house': CampAct.idle,
  'rug': CampAct.idle,
  'sofa': CampAct.idle,
  'flowers': CampAct.idle, // sits and sniffs the flowers
  'lamp': CampAct.idle,
};

/// Soft spots where a cat falls asleep instead of just sitting.
const campNapToys = {'bed', 'sofa', 'rug'};

/// Idle-sheet frame where each breed has its eyes closed. There is no sleep
/// sheet yet, so a nap holds this frame, breathes and puffs "z"s.
const campSleepFrames = {
  'orange': 2,
  'black': 3,
  'himalaya': 1,
  'scottish': 2,
  'calico': 1,
};

/// A cat living in the room. It wanders, runs zoomies, plays with owned
/// toys, naps in its bed, reacts to petting and can be picked up and moved.
/// Positions are room fractions so it behaves the same on every screen.
class CampResident {
  CampResident(this.type, this.x, this.y)
      : _timer = .5 + Random().nextDouble() * 2;
  final String type;
  double x, y;
  double? _tx, _ty;
  double _speed = .07;
  CampAct act = CampAct.idle;
  CampAct _arrive = CampAct.idle;
  double _arriveTime = 2;
  double _timer;
  double _anim = 0;
  double heart = 0;
  bool facingLeft = false;
  bool held = false;

  /// Napping: drawn with the closed-eye idle frame, breathing and "z"s.
  bool sleeping = false;
  bool _arriveSleep = false;

  /// The toy this cat is sitting at, if it walked to one and stayed.
  String? atToy;
  String? _toyGoing;
  void Function()? _onArrive;

  static const minX = .06, maxX = .94, minY = .64, maxY = .9;

  int get frame => sleeping
      ? campSleepFrames[type] ?? 0
      : (_anim * act.fps).floor() % act.frames;

  /// Seconds into the current action; drives breathing and the "z"s.
  double get clock => _anim;
  bool get moving => _tx != null;
  double? get targetX => _tx;
  double? get targetY => _ty;

  /// Seconds left in the current action.
  double get remaining => _timer;

  /// Not busy: may start something new with another cat.
  bool get free =>
      !held &&
      !sleeping &&
      _onArrive == null &&
      (act == CampAct.idle || act == CampAct.walk);

  void _play(CampAct a, double time) {
    sleeping = false;
    act = a;
    _anim = 0;
    _timer = time;
    if (a == CampAct.vanish || a == CampAct.sulk) {
      GameAudio.instance.playCampAmbient(
          a == CampAct.vanish ? GameSound.moonCloud : GameSound.campSulk);
    }
  }

  void _goTo(double tx, double ty, CampAct how, double speed) {
    atToy = null;
    final left = tx < x;
    _tx = tx.clamp(minX, maxX);
    _ty = ty.clamp(minY, maxY);
    _speed = speed;
    // Turning around is its own little animation before setting off.
    if (left != facingLeft && how == CampAct.walk) {
      facingLeft = left;
      _play(CampAct.turn, CampAct.turn.length);
      return;
    }
    facingLeft = left;
    _play(how, double.infinity);
  }

  void update(double dt, Random random, List<(String, double, double)> toys) {
    _anim += dt;
    if (heart > 0) heart -= dt;
    if (held) return;
    final tx = _tx, ty = _ty;
    if (tx != null && ty != null && act != CampAct.turn) {
      final dx = tx - x, dy = (ty - y) * 2;
      final dist = sqrt(dx * dx + dy * dy);
      final step = _speed * dt;
      if (dist <= step) {
        x = tx;
        y = ty;
        _tx = _ty = null;
        _play(_arrive, _arriveTime);
        sleeping = _arriveSleep;
        _arriveSleep = false;
        atToy = _toyGoing;
        final sound = sleeping
            ? GameSound.catNap
            : switch (atToy) {
                'post' => GameSound.campScratch,
                'yarn' => GameSound.yarnBounce,
                _ => null,
              };
        if (sound != null) GameAudio.instance.playCampAmbient(sound);
        _toyGoing = null;
        _arrive = CampAct.idle;
        _arriveTime = 1.5 + random.nextDouble() * 3;
        final arrived = _onArrive;
        _onArrive = null;
        arrived?.call();
      } else {
        x += dx / dist * step;
        y += dy / dist * step / 2;
      }
      return;
    }
    _timer -= dt;
    if (_timer > 0) return;
    if (act == CampAct.turn && tx != null) {
      _play(CampAct.walk, double.infinity);
      return;
    }
    _decide(random, toys);
  }

  void _decide(Random random, List<(String, double, double)> toys) {
    atToy = null; // whatever it was doing at a toy is over
    final roll = random.nextDouble();
    if (toys.isNotEmpty && roll < .35) {
      // Visit a toy and use it.
      final (id, toyX, toyY) = toys[random.nextInt(toys.length)];
      _arrive = campToyActs[id] ?? CampAct.idle;
      _arriveSleep = campNapToys.contains(id);
      _toyGoing = id;
      _arriveTime = _arriveSleep
          ? 6 + random.nextDouble() * 5
          // The picky Scottish lingers over its food.
          : id == 'bowl' && type == 'scottish'
              ? 8 + random.nextDouble() * 4
              : _arrive.length * 3;
      _goTo(toyX + (random.nextDouble() - .5) * .04, toyY + .02, CampAct.walk,
          .07);
    } else if (roll < .5) {
      // Zoomies: a fast run across the room.
      _goTo(facingLeft ? minX + .05 : maxX - .05,
          minY + random.nextDouble() * (maxY - minY), CampAct.run, .2);
    } else if (roll < .58 && type == 'black') {
      // The black cat blinks out and reappears somewhere else.
      _play(CampAct.vanish, CampAct.vanish.length);
      x = minX + random.nextDouble() * (maxX - minX);
    } else if (roll < .66) {
      _play(CampAct.celebrate, CampAct.celebrate.length * 2);
    } else if (roll < .72) {
      // A short nap right where it is.
      _play(CampAct.idle, 5 + random.nextDouble() * 4);
      sleeping = true;
      GameAudio.instance.playCampAmbient(GameSound.catNap);
    } else {
      double target;
      do {
        target = minX + random.nextDouble() * (maxX - minX);
      } while ((target - x).abs() < .12);
      _goTo(target, minY + random.nextDouble() * (maxY - minY), CampAct.walk,
          .07);
    }
  }

  // ---- Used by [CampSocial] to make cats react to each other. ----

  /// Stops and plays [a] once (or for [time]), optionally facing [faceX].
  void react(CampAct a, {double? time, double? faceX}) {
    _tx = _ty = null;
    _onArrive = null;
    atToy = null;
    if (faceX != null) facingLeft = faceX < x;
    _play(a, time ?? a.length);
  }

  /// Walks (or runs) to a spot and calls [onArrive] there.
  void approach(double tx, double ty,
      {CampAct how = CampAct.walk,
      double speed = .07,
      String? toy,
      void Function()? onArrive}) {
    _arrive = CampAct.idle;
    _arriveTime = 1.5;
    _arriveSleep = false;
    _goTo(tx, ty, how, speed);
    _toyGoing = toy;
    _onArrive = onArrive;
  }

  /// Falls asleep right here for [time] seconds.
  void nap(double time) {
    react(CampAct.idle, time: time);
    sleeping = true;
    GameAudio.instance.playCampAmbient(GameSound.catNap);
  }

  /// Keeps sleeping a bit longer (a friend just lay down next to it).
  void sleepOn(double time) {
    if (sleeping) _timer = max(_timer, time);
  }

  /// The black cat's trick: vanish and reappear at a new spot.
  void appearAt(double nx, double ny, {required double faceX}) {
    react(CampAct.vanish);
    x = nx.clamp(minX, maxX);
    y = ny.clamp(minY, maxY);
    facingLeft = faceX < x;
  }

  /// Petting: the cat stops and celebrates.
  void pet() {
    heart = 1.4;
    _tx = _ty = null;
    _onArrive = null;
    _play(CampAct.celebrate, CampAct.celebrate.length * 2);
  }

  void pickUp() {
    sleeping = false;
    held = true;
    _onArrive = null;
    atToy = null;
    _tx = _ty = null;
    act = CampAct.held;
  }

  void drop() {
    held = false;
    y = y.clamp(minY, maxY);
    x = x.clamp(minX, maxX);
    _play(CampAct.land, CampAct.land.length);
  }
}
