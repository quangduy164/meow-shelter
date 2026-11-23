import 'dart:math';

import '../audio/game_audio.dart';
import 'camp_resident.dart';

/// Makes camp cats notice each other: they greet, chase, nap together and
/// fight over toys, and each breed has one habit of its own. At most one
/// interaction starts every ~20 s so the room stays calm.
class CampSocial {
  CampSocial(this._random);
  final Random _random;

  double _cooldown = 6;
  final _later = <(double, void Function())>[];
  final _startled = <CampResident, double>{};

  void update(double dt, List<CampResident> cats) {
    _runLater(dt);
    _himalayaStartle(dt, cats);
    _cooldown -= dt;
    if (_cooldown > 0 || cats.length < 2) return;
    final options = <bool Function()>[
      () => _greet(cats),
      () => _chase(cats),
      () => _napTogether(cats),
      () => _toyFight(cats),
      () => _bowl(cats),
      () => _calicoPoke(cats),
      () => _blackHaunt(cats),
    ]..shuffle(_random);
    final started = options.any((start) => start());
    // Nothing fitted right now: look again soon.
    _cooldown = started ? 16 + _random.nextDouble() * 12 : 2;
  }

  // ---- helpers ----

  void _runLater(double dt) {
    for (var i = _later.length - 1; i >= 0; i--) {
      final (left, action) = _later[i];
      if (left - dt > 0) {
        _later[i] = (left - dt, action);
      } else {
        _later.removeAt(i);
        action();
      }
    }
  }

  static double _dist(CampResident a, CampResident b) {
    final dx = a.x - b.x, dy = (a.y - b.y) * 2;
    return sqrt(dx * dx + dy * dy);
  }

  /// A spot beside [b] on the side [a] is coming from.
  static double _besideX(CampResident a, CampResident b, double gap) =>
      b.x + (a.x < b.x ? -gap : gap);

  CampResident? _pick(Iterable<CampResident> cats) {
    final list = cats.toList();
    return list.isEmpty ? null : list[_random.nextInt(list.length)];
  }

  static void _sound(GameSound sound) {
    if (sound == GameSound.catStartle) {
      GameAudio.instance.playGameplay(sound, priority: 1);
    } else {
      GameAudio.instance.playCampAmbient(sound);
    }
  }

  // ---- for every cat ----

  /// Two nearby cats meet, face each other and rub noses.
  bool _greet(List<CampResident> cats) {
    for (final a in cats) {
      if (!a.free) continue;
      final b = _pick(cats
          .where((b) => b != a && b.free && !b.moving && _dist(a, b) < .35));
      if (b == null) continue;
      b.react(CampAct.idle, time: 6, faceX: a.x);
      b.prepare = CampAct.nuzzle;
      // Close enough that the two noses meet when both lean in.
      a.approach(_besideX(a, b, .065), b.y, arrive: CampAct.nuzzle,
          onArrive: () {
        if (b.held) return;
        a.react(CampAct.nuzzle, time: CampAct.nuzzle.length * 2, faceX: b.x);
        b.react(CampAct.nuzzle, time: CampAct.nuzzle.length * 2, faceX: a.x);
        a.heart = b.heart = 1.4;
        _sound(GameSound.campWelcome);
      });
      return true;
    }
    return false;
  }

  /// A cat on zoomies gets chased by the nearest free cat.
  bool _chase(List<CampResident> cats) {
    final runner = _pick(cats
        .where((c) => c.act == CampAct.run && c.moving && c.targetX != null));
    if (runner == null) return false;
    final chasers = cats.where((c) => c != runner && c.free).toList()
      ..sort((a, b) => _dist(a, runner).compareTo(_dist(b, runner)));
    if (chasers.isEmpty) return false;
    final chaser = chasers.first;
    final side = runner.targetX! < runner.x ? 1 : -1;
    chaser.approach(runner.targetX! + side * .07, runner.targetY!,
        how: CampAct.run,
        speed: .19,
        onArrive: () => chaser.react(CampAct.celebrate,
            time: CampAct.celebrate.length, faceX: runner.x));
    return true;
  }

  /// A cat curls up next to one that is already asleep.
  bool _napTogether(List<CampResident> cats) {
    final sleeper = _pick(cats.where((c) => c.sleeping && c.remaining > 4));
    if (sleeper == null) return false;
    final friend = _pick(cats.where((c) => c != sleeper && c.free));
    if (friend == null) return false;
    sleeper.sleepOn(12);
    friend.approach(_besideX(friend, sleeper, .09), sleeper.y, onArrive: () {
      friend.nap(7 + _random.nextDouble() * 4);
      friend.facingLeft = sleeper.x < friend.x;
      if (sleeper.sleeping) {
        sleeper.sleepOn(8);
        friend.heart = sleeper.heart = 1.4;
      }
    });
    return true;
  }

  /// Someone is playing with the yarn or post; another cat wants it too,
  /// arrives too late and sulks off.
  bool _toyFight(List<CampResident> cats) {
    final player = _pick(cats.where((c) =>
        (c.atToy == 'yarn' || c.atToy == 'post') &&
        (c.act == CampAct.celebrate || c.act == CampAct.dash) &&
        c.remaining > 2));
    if (player == null) return false;
    final rival = _pick(cats.where((c) => c != player && c.free));
    if (rival == null) return false;
    final toy = player.atToy;
    rival.approach(_besideX(rival, player, .1), player.y, onArrive: () {
      if (player.atToy == toy) {
        rival.react(CampAct.sulk,
            time: CampAct.sulk.length * 2,
            faceX: rival.x * 2 - player.x); // turns its back
      } else {
        rival.react(CampAct.celebrate, time: CampAct.celebrate.length * 2);
      }
    });
    return true;
  }

  /// Food bowl: the greedy orange cat squeezes in next to whoever is
  /// eating; the picky Scottish turns its back on anyone who comes close.
  bool _bowl(List<CampResident> cats) {
    final eater = _pick(cats.where((c) => c.atToy == 'bowl' && !c.moving));
    if (eater == null) return false;
    final orange =
        cats.where((c) => c.type == 'orange' && c != eater && c.free);
    final visitor = orange.isNotEmpty
        ? orange.first
        : eater.type == 'scottish'
            ? _pick(cats.where((c) => c != eater && c.free))
            : null;
    if (visitor == null) return false;
    final greedy = visitor.type == 'orange';
    visitor.approach(_besideX(visitor, eater, .08), eater.y,
        how: greedy ? CampAct.run : CampAct.walk,
        speed: greedy ? .16 : .07,
        toy: 'bowl', onArrive: () {
      if (eater.atToy != 'bowl') return;
      if (eater.type == 'scottish') {
        eater.react(CampAct.sulk,
            time: CampAct.sulk.length * 2, faceX: eater.x * 2 - visitor.x);
      } else {
        eater.react(CampAct.idle, time: 3, faceX: visitor.x);
      }
      if (greedy) {
        visitor.react(CampAct.celebrate,
            time: CampAct.celebrate.length * 2, faceX: eater.x);
        _sound(GameSound.rescueSplash);
      }
    });
    return true;
  }

  // ---- breed habits ----

  /// The shy Himalaya jumps when a cat races past, then edges away.
  void _himalayaStartle(double dt, List<CampResident> cats) {
    _startled.updateAll((_, t) => t - dt);
    for (final h in cats) {
      if (h.type != 'himalaya' || h.held || (_startled[h] ?? 0) > 0) continue;
      if (!h.free && !h.sleeping) continue;
      for (final o in cats) {
        if (o == h || o.act != CampAct.run || _dist(o, h) > .12) continue;
        _startled[h] = 20;
        h.react(CampAct.panic, time: CampAct.panic.length * 2, faceX: o.x);
        _sound(GameSound.catStartle);
        _later.add((
          CampAct.panic.length * 2,
          () {
            if (h.held || h.act != CampAct.panic) return;
            final away = h.x < o.x ? -.25 : .25;
            h.approach(h.x + away, h.y + (_random.nextDouble() - .5) * .1);
          }
        ));
        return;
      }
    }
  }

  /// The playful calico sneaks up on a sleeping cat and pokes it awake.
  bool _calicoPoke(List<CampResident> cats) {
    final calico = _pick(cats.where((c) => c.type == 'calico' && c.free));
    if (calico == null) return false;
    final sleeper =
        _pick(cats.where((c) => c != calico && c.sleeping && c.remaining > 3));
    if (sleeper == null) return false;
    calico.approach(_besideX(calico, sleeper, .07), sleeper.y, speed: .05,
        onArrive: () {
      calico.react(CampAct.dash, faceX: sleeper.x);
      _sound(GameSound.campDrop);
      _later.add((
        CampAct.dash.length * .5,
        () {
          if (!sleeper.sleeping) return;
          sleeper.react(CampAct.panic,
              time: CampAct.panic.length * 2, faceX: calico.x);
          _sound(GameSound.catStartle);
        }
      ));
      _later.add((
        CampAct.dash.length,
        () {
          if (calico.held) return;
          calico.react(CampAct.celebrate,
              time: CampAct.celebrate.length * 2, faceX: sleeper.x);
        }
      ));
    });
    return true;
  }

  /// The ghostly black cat blinks out and pops up right beside another cat.
  bool _blackHaunt(List<CampResident> cats) {
    final black = _pick(cats.where((c) => c.type == 'black' && c.free));
    if (black == null) return false;
    final victim = _pick(cats.where((c) => c != black && c.free && !c.moving));
    if (victim == null) return false;
    final side = victim.x > .5 ? -1 : 1;
    black.appearAt(victim.x + side * .08, victim.y, faceX: victim.x);
    _later.add((
      CampAct.vanish.length * .8,
      () {
        if (victim.held || victim.sleeping) return;
        victim.react(CampAct.panic,
            time: CampAct.panic.length * 2, faceX: black.x);
        _sound(GameSound.catStartle);
      }
    ));
    return true;
  }
}
