import 'dart:math' as math;
import '../night_cards.dart';
import '../night_run.dart';
import '../night_variants.dart';

enum ClawPhase { idle, dropping, closing, lifting, carrying, releasing }

enum ClawEvent { grabbed, missed, slipped, delivered }

/// One cat walking on the tank floor, as fractions of the field.
class TankCat {
  TankCat(this.id, this.breed, this.x);
  final int id;
  final String breed;
  double x, target = 0, rest = 0, scared = 0;
  bool held = false, gone = false;
}

/// Toys in the tank: grabbing one pays a little Moonlight.
enum ClawPrize { yarn, mouse, can }

class TankItem {
  TankItem(this.kind, this.x);
  final ClawPrize kind;
  double x;
  bool held = false;
}

/// The claw machine without sprites: claw timing, aim, grab and hold rules.
class ClawMachine {
  static const tankLeft = .17, tankRight = .86, railY = .255, floorY = .76;
  static const dropSeconds = .75, closeSeconds = .3, liftSeconds = .75;
  static const releaseSeconds = .35;

  /// Sideways claw speed, in field widths per second.
  static const baseSpeed = .3;

  final cats = <TankCat>[];
  var phase = ClawPhase.idle;

  /// -1 / 0 / 1 while a left or right button is held.
  int steer = 0;
  double x = .5, target = .5, depth = 0, timer = 0, clock = 0;
  double radius = .055, secureShare = 0, speed = baseSpeed, catSpeed = .05;
  bool twinChutes = false, swing = false, doubleGrab = false;
  int stage = 1, _id = 0;
  final held = <TankCat>[];
  final items = <TankItem>[];

  /// Toys dropped into a chute since the scene last asked.
  final deliveredPrizes = <ClawPrize>[];

  /// Fish on the tank floor; cats gather until it is eaten.
  double? fishX;
  double fishLeft = 0, fishSeconds = 4;

  void begin(NightRun run, math.Random random, {double afterglow = 0}) {
    stage = (run.night - 1) ~/ NightRun.mapOrder.length + 1;
    radius = .055 * (1 + .25 * run.count(NightCard.wideClaw));
    secureShare = .2 * run.count(NightCard.strongClaw);
    speed = baseSpeed * (run.has(NightCard.fastClaw) ? 1.35 : 1);
    catSpeed = .05 * (stage >= 2 ? 1.3 : 1);
    twinChutes = run.variant == NightVariant.clawTwin;
    swing = run.variant == NightVariant.clawSwing || stage >= 3;
    doubleGrab = run.has(NightCard.doubleGrab);
    fishSeconds = 4 + afterglow / 2;
    cats.clear();
    held.clear();
    phase = ClawPhase.idle;
    x = target = .5;
    depth = timer = 0;
    fishX = null;
    items.clear();
    deliveredPrizes.clear();
    for (var i = 0; i < 3; i++) {
      _addItem(
          random,
          (tankLeft + .06) +
              (i + random.nextDouble() * .6) *
                  (tankRight - tankLeft - .12) /
                  3);
    }
  }

  void _addItem(math.Random random, double at) => items.add(
      TankItem(ClawPrize.values[random.nextInt(ClawPrize.values.length)], at));

  double get chuteLeft => .08;
  double get chuteRight => .935;
  double get nearestChute => twinChutes && x > .53 ? chuteRight : chuteLeft;

  /// Where the claw really is: it sways while dropping on swing machines.
  double get aimX =>
      swing ? (x + math.sin(clock * 3.2) * .035 * (depth > 0 ? 1 : .6)) : x;

  /// Share of [radius] that grabs firmly for each breed.
  double securePart(String breed) => (switch (breed) {
            'orange' => .7,
            'himalaya' => .6,
            'black' => .5,
            'scottish' => .45,
            _ => .35,
          } +
          secureShare)
      .clamp(.2, 1)
      .toDouble();

  TankCat add(String breed, math.Random random) {
    final cat = TankCat(_id++, breed,
        tankLeft + .05 + random.nextDouble() * (tankRight - tankLeft - .1));
    cat.target = cat.x;
    cats.add(cat);
    return cat;
  }

  bool drop() {
    if (phase != ClawPhase.idle) return false;
    phase = ClawPhase.dropping;
    timer = dropSeconds / (speed / baseSpeed);
    return true;
  }

  void putFish(double at) {
    fishX = at.clamp(tankLeft + .03, tankRight - .03).toDouble();
    fishLeft = fishSeconds;
  }

  /// Advances claw and cats; [pace]/[frozen] come from helpers.
  List<(TankCat, ClawEvent)> update(double dt, math.Random random,
      {double pace = 1,
      bool frozen = false,
      bool calm = false,
      bool firm = false}) {
    clock += dt;
    final events = <(TankCat, ClawEvent)>[];
    _walk(dt * (frozen ? 0 : pace), random, calm: calm);
    final fast = speed / baseSpeed;
    switch (phase) {
      case ClawPhase.idle:
        if (steer != 0) {
          x = (x + steer * speed * dt).clamp(tankLeft, tankRight).toDouble();
          target = x;
        } else {
          x += (target - x).clamp(-speed * dt, speed * dt);
        }
      case ClawPhase.dropping:
        timer -= dt;
        depth = 1 - (timer * fast / dropSeconds).clamp(0, 1);
        if (timer <= 0) {
          phase = ClawPhase.closing;
          timer = closeSeconds;
          _grab(events, firm: firm);
        }
      case ClawPhase.closing:
        timer -= dt;
        if (timer <= 0) {
          phase = ClawPhase.lifting;
          timer = liftSeconds / fast;
        }
      case ClawPhase.lifting:
        timer -= dt;
        depth = (timer * fast / liftSeconds).clamp(0, 1).toDouble();
        // A loose grip loses the cat halfway up.
        if (depth < .55) {
          for (final cat in held.where((c) => c.scared < 0).toList()) {
            held.remove(cat);
            cat
              ..held = false
              ..scared = 1.2
              ..rest = 0;
            events.add((cat, ClawEvent.slipped));
          }
        }
        if (timer <= 0) {
          depth = 0;
          final empty = held.isEmpty && !items.any((i) => i.held);
          phase = empty ? ClawPhase.idle : ClawPhase.carrying;
          target = empty ? x : nearestChute;
        }
      case ClawPhase.carrying:
        x += (target - x).clamp(-speed * dt, speed * dt);
        if ((target - x).abs() < .002) {
          phase = ClawPhase.releasing;
          timer = releaseSeconds;
        }
      case ClawPhase.releasing:
        timer -= dt;
        if (timer <= 0) {
          for (final cat in held) {
            cat.gone = true;
            events.add((cat, ClawEvent.delivered));
          }
          held.clear();
          cats.removeWhere((c) => c.gone);
          for (final item in items.where((i) => i.held).toList()) {
            items.remove(item);
            deliveredPrizes.add(item.kind);
            _addItem(
                random,
                tankLeft +
                    .05 +
                    random.nextDouble() * (tankRight - tankLeft - .1));
          }
          phase = ClawPhase.idle;
          target = x;
        }
    }
    return events;
  }

  void _grab(List<(TankCat, ClawEvent)> events, {required bool firm}) {
    final aim = aimX;
    final inRing = cats
        .where((c) => !c.held && (c.x - aim).abs() <= radius)
        .toList()
      ..sort((a, b) => (a.x - aim).abs().compareTo((b.x - aim).abs()));
    final take = inRing.take(doubleGrab ? 2 : 1).toList();
    if (take.isEmpty) {
      // No cat under the claw: it can still pick up a toy.
      final toys = items.where((i) => (i.x - aim).abs() <= radius * .8).toList()
        ..sort((a, b) => (a.x - aim).abs().compareTo((b.x - aim).abs()));
      if (toys.isNotEmpty) {
        toys.first.held = true;
        return;
      }
      events.add((TankCat(-1, '', aim), ClawEvent.missed));
      return;
    }
    for (final cat in take) {
      final secure =
          firm || (cat.x - aim).abs() <= radius * securePart(cat.breed);
      cat
        ..held = true
        // Negative scared marks a loose grip, resolved while lifting.
        ..scared = secure ? 0 : -1;
      held.add(cat);
      events.add((cat, ClawEvent.grabbed));
    }
  }

  void _walk(double dt, math.Random random, {required bool calm}) {
    if (fishX != null) {
      fishLeft -= dt;
      if (fishLeft <= 0) fishX = null;
    }
    for (final cat in cats) {
      if (cat.held) continue;
      // Black cats sidestep a claw coming down on them.
      if (!calm &&
          cat.breed == 'black' &&
          phase == ClawPhase.dropping &&
          depth < .4 &&
          (cat.x - aimX).abs() < radius * 1.2 &&
          cat.scared <= 0) {
        cat
          ..scared = .8
          ..target = (cat.x + (cat.x < aimX ? -.12 : .12))
              .clamp(tankLeft, tankRight)
              .toDouble();
      }
      final runFast = cat.scared > 0 ? 3.0 : 1.0;
      if (cat.scared > 0) cat.scared -= dt;
      if (fishX != null && (fishX! - cat.x).abs() < .3) {
        cat.target = fishX! + (cat.id.isEven ? -.015 : .015);
      } else if (cat.rest > 0) {
        cat.rest -= dt;
        continue;
      } else if ((cat.target - cat.x).abs() < .004) {
        cat
          ..rest = cat.breed == 'orange'
              ? 3 + random.nextDouble() * 3
              : .8 + random.nextDouble() * 1.6
          ..target = tankLeft +
              .03 +
              random.nextDouble() * (tankRight - tankLeft - .06);
        continue;
      }
      final pace = catSpeed *
          runFast *
          switch (cat.breed) {
            'orange' => .6,
            'scottish' => .8,
            'calico' => 1.3,
            _ => 1.0,
          };
      cat.x += (cat.target - cat.x).clamp(-pace * dt, pace * dt);
    }
  }
}
