import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/painting.dart';
import '../../../audio/game_audio.dart';
import '../../components/cat_component.dart';
import '../../components/darkness_component.dart';
import '../../components/hud_component.dart';
import '../../meow_shelter_game.dart';
import '../moonlight.dart';
import '../night_cards.dart';
import '../night_run.dart';
import '../night_scene.dart';
import 'claw_machine.dart';
import 'claw_machine_painter.dart';

class ClawMachineScene extends NightScene {
  ClawMachineScene(this.game, {required this.onFirstLight});
  final MeowShelterGame game;
  final void Function(Offset, double) onFirstLight;
  final machine = ClawMachine();
  final moon = Moonlight();
  final _parts = <Component>[];
  final _cats = <TankCat, CatComponent>{};
  final _sizes = <CatComponent, Vector2>{};
  bool _chimed = false;
  final _held = <int>{};
  final _landing = <_Landing>[];

  @override
  NightMap get map => NightMap.clawMachine;
  @override
  bool get ownsBait => true;
  @override
  bool get noCarry => true;
  @override
  double get lanternBurn => 0;
  @override
  bool get cloudy => moon.cloudy;
  @override
  double get notificationTop => 46;
  @override
  bool get hasBaitInTransit => _cats.isNotEmpty || _landing.isNotEmpty;
  @override
  List<String> get rules => [
        'Gắp giữa người: càng hạ lệch thì mèo dễ tuột giữa chừng',
        'Tính nết: mèo đen né càng, tam thể quẫy dễ rơi',
        if (machine.swing) 'Càng lắc: càng đung đưa khi hạ',
        if (machine.stage >= 2) 'Mèo nhanh: mèo trong thùng đi nhanh hơn',
      ];
  @override
  void onMistake() {}
  @override
  bool blocks(Rect bounds) => false;
  @override
  bool allowsBait(Offset point, Size field) => _inTank(point);
  bool _inTank(Offset p) =>
      p.dx > game.size.x * ClawMachine.tankLeft &&
      p.dx < game.size.x * ClawMachine.tankRight &&
      p.dy > game.size.y * .2 &&
      p.dy < game.size.y * .9;

  Offset _chute(double x) => clawChuteBox(x, game.size).center;
  @override
  bool isLit(Offset point, Size size) => [
        machine.chuteLeft,
        if (machine.twinChutes) machine.chuteRight
      ].any((x) => (point - _chute(x)).distance < size.width * .09);
  @override
  bool overlappingLights(Offset point, Size size) => false;

  double get catHeight => game.size.y * .17;

  /// Resting claw height: hangs below the rail so it never covers it.
  double get _restY => game.size.y * (ClawMachine.railY + .085);
  double get _clawY =>
      _restY +
      machine.depth *
          (game.size.y * ClawMachine.floorY - catHeight * .75 - _restY);
  Offset get clawTip => Offset(game.size.x * machine.aimX, _clawY);

  @override
  void mount() {
    _parts.addAll([
      ClawRoomBackground(),
      ClawChutes(machine),
      ClawPrizes(this),
      DarknessComponent(
          lights: _lights,
          visible: () => game.hud.status == RoundStatus.playing,
          shade: const Color(0x2A140C24)),
      ClawRig(this),
      ClawSteerButton(-1, onSteer: steer),
      ClawSteerButton(1, onSteer: steer),
      ClawDropButton(onDrop: drop),
    ]);
    game.addAll(_parts);
  }

  @override
  void remove() {
    for (final entry in _sizes.entries) {
      entry.key.size.setFrom(entry.value);
      entry.key.leaveTrap();
    }
    _cats.clear();
    _sizes.clear();
    game.removeAll(_parts);
    _parts.clear();
  }

  @override
  void begin(NightRun run,
      {required bool thickClouds, required double afterglowSeconds}) {
    machine.begin(run, game.random, afterglow: afterglowSeconds);
    moon.reset(fullMoon: true, thickClouds: false);
    _cats.clear();
    _sizes.clear();
    _landing.clear();
    _held.clear();
    _chimed = false;
  }

  bool get playing => !game.paused && game.night?.phase == NightPhase.playing;

  /// Left/right buttons are held; the newest pressed one wins.
  void steer(int direction, bool held) {
    if (held) {
      _held.add(direction);
    } else {
      _held.remove(direction);
    }
    machine.steer =
        !playing || _held.isEmpty ? 0 : (held ? direction : _held.last);
  }

  void drop() {
    if (!playing || !machine.drop()) return;
    GameAudio.instance.playRescue(GameSound.click);
    if (!_chimed) {
      _chimed = true;
      onFirstLight(
          Offset(game.size.x * machine.x, game.size.y * ClawMachine.floorY),
          game.size.x * .2);
    }
  }

  @override
  void prepareBait() {}

  @override
  bool placeBait(Offset point, {bool free = false}) {
    if (!_inTank(point)) {
      game.hud.showBanner(['Thả cá vào trong thùng máy'], 1.4);
      return false;
    }
    if (!free && !game.bait.spend()) return false;
    machine.putFish(point.dx / game.size.x);
    if (game.bait.limited) game.hud.fishLeft = game.bait.fishCount;
    GameAudio.instance.playRescue(GameSound.baitDrop);
    return true;
  }

  @override
  int helpNear(Offset point, double reach, int targets) {
    final near = machine.cats
        .where((c) => !c.held && (c.x * game.size.x - point.dx).abs() <= reach)
        .take(targets)
        .toList();
    for (final cat in near) {
      cat
        ..rest = 3
        ..target = cat.x;
    }
    return near.length;
  }

  @override
  int helperBoost(int count) {
    final edge = machine.twinChutes && machine.x > .53
        ? ClawMachine.tankRight - .04
        : ClawMachine.tankLeft + .04;
    final cats = machine.cats.where((c) => !c.held).toList()
      ..sort((a, b) => (b.x - edge).abs().compareTo((a.x - edge).abs()));
    for (final cat in cats.take(count)) {
      cat
        ..target = edge
        ..rest = 0;
    }
    return math.min(count, cats.length);
  }

  void _seat(TankCat tank, CatComponent cat) {
    if (tank.held) {
      final tip = clawTip;
      cat.positionInTrap(
          Vector2(tip.dx - cat.size.x / 2, tip.dy - cat.size.y * .15),
          walking: false);
      return;
    }
    final moving = (tank.target - tank.x).abs() > .004 && tank.rest <= 0;
    cat.positionInTrap(
        Vector2(
            tank.x * game.size.x - cat.size.x / 2,
            // Paws sink a little into the cushion.
            game.size.y * ClawMachine.floorY - cat.size.y * .9),
        walking: moving);
  }

  @override
  void update(double dt) {
    final night = game.night!;
    for (final cat in game.children.whereType<CatComponent>()) {
      if (!cat.isLoaded ||
          cat.isDelivered ||
          cat.trapManaged ||
          _cats.containsValue(cat)) {
        continue;
      }
      final tank = machine.add(cat.catType, game.random);
      _cats[tank] = cat;
      _sizes[cat] = cat.size.clone();
      cat.enterTrap();
      cat.size.setValues(catHeight, catHeight);
    }
    final events = machine.update(dt, game.random,
        pace: night.assist.pace,
        frozen: night.assist.frozen,
        calm: night.assist.calm,
        firm: night.acceptsAnyBed);
    for (final (tank, event) in events) {
      final cat = _cats[tank];
      switch (event) {
        case ClawEvent.missed:
          game.hud.showBanner(['Gắp trượt!'], .9);
        case ClawEvent.grabbed:
          GameAudio.instance.playRescue(GameSound.catGrab);
        case ClawEvent.slipped:
          game.hud
              .showBanner(['Mèo tuột khỏi càng! Ngắm vào giữa người mèo'], 1.4);
          GameAudio.instance.playRescue(GameSound.catWrong);
        case ClawEvent.delivered:
          _cats.remove(tank);
          // The cat drops into the chute and sits there before it leaves.
          if (cat != null) _landing.add(_Landing(cat, machine.nearestChute));
      }
    }
    for (final _ in machine.deliveredPrizes) {
      night.run?.earnMoonlight(1);
      game.hud.showBanner(['Gắp được đồ chơi! +1 Nguyệt quang'], 1.1);
      GameAudio.instance.playRescue(GameSound.click);
    }
    machine.deliveredPrizes.clear();
    for (final entry in _cats.entries) {
      _seat(entry.key, entry.value);
    }
    _land(dt);
  }

  void _land(double dt) {
    final night = game.night!;
    for (final drop in _landing.toList()) {
      final cat = drop.cat;
      final box = clawChuteBox(drop.chute, game.size);
      final seat =
          Vector2(box.center.dx - cat.size.x / 2, box.bottom - cat.size.y - 4);
      if (drop.fall < 1) {
        drop.fall = math.min(1, drop.fall + dt / .4);
        final y = drop.fromY + (seat.y - drop.fromY) * drop.fall * drop.fall;
        cat.positionInTrap(Vector2(seat.x, y), walking: false);
        if (drop.fall >= 1) {
          GameAudio.instance.playRescue(GameSound.catRescue, important: true);
        }
        continue;
      }
      drop.sit += dt;
      cat.positionInTrap(seat, walking: false);
      if (drop.sit < .9) continue;
      _landing.remove(drop);
      _sizes.remove(cat);
      if (night.phase == NightPhase.playing) cat.rescueFromTrap();
    }
  }

  Iterable<(Offset, double)> _lights() sync* {
    yield (_chute(machine.chuteLeft), 70);
    if (machine.twinChutes) yield (_chute(machine.chuteRight), 70);
    yield (
      Offset(game.size.x * machine.aimX, game.size.y * ClawMachine.floorY),
      60
    );
    yield (clawTip, 46);
    for (final cat in _cats.values) {
      yield (cat.center.toOffset(), 32);
    }
  }
}

class _Landing {
  _Landing(this.cat, this.chute) : fromY = cat.position.y;
  final CatComponent cat;
  final double chute;
  final double fromY;
  double fall = 0, sit = 0;
}
