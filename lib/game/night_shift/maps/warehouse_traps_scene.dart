import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/painting.dart';
import '../../../audio/game_audio.dart';
import '../../components/cat_component.dart';
import '../../components/darkness_component.dart';
import '../../components/hud_component.dart';
import '../../meow_shelter_game.dart';
import '../moonlight.dart';
import '../moonlight_art.dart';
import '../night_cards.dart';
import '../night_run.dart';
import '../night_scene.dart';
import 'warehouse_traps.dart';
import 'warehouse_traps_painter.dart';

class _TrapCat {
  _TrapCat(this.cat) : size = cat.size.clone();
  final CatComponent cat;
  final Vector2 size;
  final route = <Vector2>[];
}

class WarehouseTrapsScene extends NightScene {
  WarehouseTrapsScene(this.game, {required this.onFirstLight});
  final MeowShelterGame game;
  final void Function(Offset, double) onFirstLight;
  final traps = WarehouseTraps();
  final moon = Moonlight();
  final _parts = <Component>[];
  final _cages = <Component>[];
  final _cats = <TrapSlot, _TrapCat>{};
  NightRun get run => game.night!.run!;
  @override
  NightMap get map => NightMap.warehouse;
  @override
  bool get usesTraps => true;
  @override
  double get lanternBurn => 0;
  @override
  bool get cloudy => moon.cloudy;
  @override
  double get notificationTop => 46;
  @override
  bool get hasBaitInTransit => traps.slots.any((s) => s.baited || s.occupied);
  @override
  List<String> get rules => const [
        'Lồng bắt: mọi giống mèo đều vào lồng, không cần bế',
        'Chốt xanh: chạm khi lồng sáng xanh; trùm nán ngắn hơn',
      ];
  @override
  void onMistake() {}
  @override
  bool blocks(Rect bounds) => traps.blocks(bounds);
  @override
  bool allowsBait(Offset point, Size field) => traps.at(point, field) != null;
  @override
  Offset? spawnPosition(Size field, Size cat, math.Random random) {
    for (var i = 0; i < 40; i++) {
      final point = Offset(random.nextDouble() * (field.width - cat.width),
          field.height * (.2 + random.nextDouble() * .5));
      if (!traps.blocks(Rect.fromLTWH(
          point.dx / field.width,
          point.dy / field.height,
          cat.width / field.width,
          cat.height / field.height))) {
        return point;
      }
    }
    return Offset(field.width * .04, field.height * .2);
  }

  @override
  bool isLit(Offset point, Size size) =>
      moon.contains(point, size) || _cageLit(point, size);
  bool _cageLit(Offset point, Size size) => traps.slots.any((s) =>
      (s.baited || s.occupied || s.cool > 0) &&
      _pixels(s.area).inflate(22).contains(point));
  @override
  bool overlappingLights(Offset point, Size size) =>
      moon.contains(point, size) && _cageLit(point, size);

  Rect _pixels(Rect r) => Rect.fromLTWH(r.left * game.size.x,
      r.top * game.size.y, r.width * game.size.x, r.height * game.size.y);

  @override
  void mount() {
    _parts.addAll([
      WarehouseBackground(),
      DarknessComponent(
          lights: _lights,
          visible: () => game.hud.status == RoundStatus.playing,
          additionalLights: (canvas, size) =>
              paintMoonlitField(canvas, size, moon),
          shade: const Color(0x24142932)),
      WarehouseMoon(moon),
    ]);
    game.addAll(_parts);
  }

  @override
  void remove() {
    for (final actor in _cats.values) {
      actor.cat.size.setFrom(actor.size);
      actor.cat.leaveTrap();
    }
    _cats.clear();
    game.removeAll([..._parts, ..._cages]);
    _parts.clear();
    _cages.clear();
  }

  @override
  void begin(NightRun run,
      {required bool thickClouds, required double afterglowSeconds}) {
    traps.begin(run);
    traps.holdBonus += afterglowSeconds / 4;
    moon.reset(fullMoon: run.has(NightCard.fullMoon), thickClouds: thickClouds);
    game.removeAll(_cages);
    _cages.clear();
    for (final slot in traps.slots) {
      _cages.addAll([
        WarehouseCageBack(slot, traps),
        WarehouseDoor(slot, traps,
            onClose: close,
            canClose: (s) =>
                traps.catchable(s, forgiving: game.night!.acceptsAnyBed)),
      ]);
    }
    game.addAll(_cages);
  }

  @override
  void prepareBait() {
    final slot = traps.slots.firstWhere((s) => s.canBait);
    placeBait(_pixels(slot.area).center, free: true);
  }

  @override
  bool placeBait(Offset point, {bool free = false}) {
    final slot = traps.at(point, game.size.toSize());
    if (slot == null || !slot.canBait) {
      game.hud.showBanner([
        slot == null
            ? 'Thả cá vào trong lồng trống'
            : 'Ngăn này đang bận, hãy chọn ngăn khác'
      ], 1.5);
      return false;
    }
    if (!free && !game.bait.spend()) return false;
    traps.bait(slot, paid: !free && game.bait.limited);
    if (game.bait.limited) game.hud.fishLeft = game.bait.fishCount;
    GameAudio.instance.playRescue(GameSound.baitDrop);
    if (!slot.chimed) {
      slot.chimed = true;
      onFirstLight(_pixels(slot.area).center, game.size.x * .16);
    }
    return true;
  }

  Vector2 _entry(TrapSlot s, CatComponent cat) {
    final area = _pixels(s.area);
    final x = s.opensRight
        ? area.right + game.size.x * .014
        : area.left - cat.size.x - game.size.x * .014;
    return Vector2(x, area.bottom - cat.size.y * .92);
  }

  Vector2 _inside(TrapSlot s, CatComponent cat) {
    final area = _pixels(s.area);
    final depth = run.has(NightCard.deepBait) ? .67 : .58;
    final center = s.opensRight
        ? area.right - area.width * depth
        : area.left + area.width * depth;
    return Vector2(center - cat.size.x / 2, area.bottom - cat.size.y * .92);
  }

  bool _clear(Vector2 from, Vector2 to, Vector2 size) {
    final steps = math.max(1, ((to - from).length / 8).ceil());
    for (var i = 0; i <= steps; i++) {
      final p = from + (to - from) * (i / steps);
      if (traps.blocks(Rect.fromLTWH(p.x / game.size.x, p.y / game.size.y,
          size.x / game.size.x, size.y / game.size.y))) {
        return false;
      }
    }
    return true;
  }

  List<Vector2> _route(CatComponent cat, Vector2 target) {
    final start = cat.position.clone();
    final yTop = game.size.y * .2;
    final yBottom = game.size.y * .7;
    final gaps = [
      0.0,
      for (var i = 0; i < traps.cages.length - 1; i++)
        (traps.cages[i].right + traps.cages[i + 1].left) / 2 * game.size.x -
            cat.size.x / 2,
      game.size.x - cat.size.x,
    ];
    final candidates = <List<Vector2>>[
      [target],
      for (final y in [yTop, yBottom])
        [Vector2(start.x, y), Vector2(target.x, y), target],
      for (final x in gaps)
        for (final y in [yTop, yBottom])
          [Vector2(x, start.y), Vector2(x, y), Vector2(target.x, y), target],
    ];
    bool valid(List<Vector2> path) {
      var from = start;
      for (final point in path) {
        if (!_clear(from, point, cat.size)) return false;
        from = point;
      }
      return true;
    }

    return candidates.firstWhere(valid, orElse: () => [target]);
  }

  void _release(TrapSlot slot, {bool startled = false}) {
    final actor = _cats.remove(slot);
    if (actor == null) return;
    final cat = actor.cat;
    cat.size.setFrom(actor.size);
    final exit = _entry(slot, cat);
    cat.position.setFrom(exit);
    cat.position.x =
        cat.position.x.clamp(0, math.max(0, game.size.x - cat.size.x));
    cat.position.y = cat.position.y.clamp(game.size.y * .2, game.size.y * .7);
    cat.leaveTrap(startled: startled);
  }

  void close(TrapSlot selected) {
    final night = game.night!;
    if (game.paused ||
        night.phase != NightPhase.playing ||
        selected.phase == TrapPhase.closing) {
      return;
    }
    if (!_cats.containsKey(selected)) {
      game.hud.showBanner(['Chờ mèo vào rồi mới chốt cửa'], 1.3);
      return;
    }
    for (final slot in traps.closingGroup(selected).toList()) {
      final actor = _cats[slot];
      if (actor == null) continue;
      if (traps.shut(slot, forgiving: night.acceptsAnyBed)) {
        actor.cat.positionInTrap(_inside(slot, actor.cat), walking: false);
        GameAudio.instance.playRescue(GameSound.catRescue, important: true);
      } else {
        _release(slot, startled: !night.assist.calm);
        traps.reset(slot);
        game.stats.startles++;
        final light = _pixels(slot.area).center;
        final center = Vector2(light.dx, light.dy);
        for (final cat in game.children.whereType<CatComponent>()) {
          if (!cat.trapManaged &&
              (cat.center - center).length < traps.scareRadius) {
            cat.reactToNoise();
          }
        }
        game.hud.showBanner(
            ['Đóng hụt! Chờ tín hiệu xanh khi mèo vào trọn lồng'], 1.8);
        GameAudio.instance.playRescue(GameSound.catWrong);
      }
    }
  }

  @override
  void update(double dt) {
    moon.update(dt);
    final night = game.night!;
    final events = traps.update(dt,
        frozen: night.assist.frozen,
        windowScale: night.assist.pace,
        frozenSlot: (slot) =>
            _cats[slot] != null && night.freezesCat(_cats[slot]!.cat));
    for (final (slot, event) in events) {
      switch (event) {
        case TrapEvent.escaped:
          _release(slot);
        case TrapEvent.fed:
          final cat = _cats[slot]?.cat;
          if (cat != null) night.cardEffects.onFed(cat);
        case TrapEvent.captured:
          final actor = _cats.remove(slot);
          if (night.phase == NightPhase.playing) actor?.cat.rescueFromTrap();
      }
    }
    for (final slot in traps.slots) {
      if (slot.baited && slot.baitAge >= 12 && run.has(NightCard.fishReserve)) {
        if (slot.paid) game.bait.fishCount++;
        slot.baited = slot.paid = false;
        continue;
      }
      if (slot.baited && !_cats.containsKey(slot)) {
        final candidates = game.children
            .whereType<CatComponent>()
            .where((c) =>
                c.isLoaded && !c.isDelivered && !c.trapManaged && !c.isRemoving)
            .toList()
          ..sort((a, b) => (a.position - _entry(slot, a))
              .length2
              .compareTo((b.position - _entry(slot, b)).length2));
        if (candidates.isNotEmpty) {
          final cat = candidates.first;
          final actor = _TrapCat(cat);
          _cats[slot] = actor;
          final area = _pixels(slot.area);
          final scale = math.min(
              1.0,
              math.min(area.width * (cat.isBoss ? .82 : .74) / cat.size.x,
                  area.height * .82 / cat.size.y));
          cat.size.scale(scale);
          actor.route.addAll(_route(cat, _entry(slot, cat)));
          traps.assign(slot, boss: cat.isBoss, trusting: cat.hasEaten);
          cat.hasEaten = false;
          cat.enterTrap();
        }
      }
    }
    for (final entry in _cats.entries.toList()) {
      final slot = entry.key, actor = entry.value, cat = actor.cat;
      if (slot.phase == TrapPhase.approaching) {
        final target =
            actor.route.isEmpty ? _entry(slot, cat) : actor.route.first;
        final delta = target - cat.position;
        final step = 85 * run.lure * dt;
        if (delta.length <= step + 1) {
          cat.positionInTrap(target, walking: actor.route.length > 1);
          if (actor.route.isNotEmpty) actor.route.removeAt(0);
          if (actor.route.isEmpty) traps.arrive(slot);
        } else {
          cat.positionInTrap(cat.position + delta.normalized() * step,
              walking: true);
        }
      } else {
        final from = _entry(slot, cat), to = _inside(slot, cat);
        cat.positionInTrap(from + (to - from) * traps.progress(slot),
            walking: slot.phase == TrapPhase.entering ||
                slot.phase == TrapPhase.leaving);
      }
    }
  }

  Iterable<(Offset, double)> _lights() sync* {
    for (final slot in traps.slots) {
      if (slot.baited || slot.occupied || slot.cool > 0) {
        yield (_pixels(slot.area).center, 65);
      }
    }
    for (final cat in game.children.whereType<CatComponent>()) {
      yield (cat.center.toOffset(), 34);
    }
  }
}
