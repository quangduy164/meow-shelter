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
}

class WarehouseTrapsScene extends NightScene {
  WarehouseTrapsScene(this.game, {required this.onFirstLight});
  final MeowShelterGame game;
  final void Function(Offset, double) onFirstLight;
  final traps = WarehouseTraps();
  final moon = Moonlight();
  final _parts = <Component>[];
  final _doors = <WarehouseDoor>[];
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
        'Lồng áp dụng cho mọi giống mèo; trùm nán lại ngắn hơn. Không cần bế vào ổ',
        'Thẻ bế/ổ dùng ở các map bế mèo; trợ thủ ở đây hỗ trợ thời điểm chốt lồng',
      ];
  @override
  void onMistake() {}
  @override
  bool blocks(Rect bounds) => false;
  @override
  bool allowsBait(Offset point, Size field) => traps.at(point, field) != null;
  @override
  bool isLit(Offset point, Size size) =>
      moon.contains(point, size) || _cageLit(point, size);
  bool _cageLit(Offset point, Size size) => traps.slots.any((s) =>
      (s.baited || s.occupied || s.cool > 0) &&
      Rect.fromLTWH(s.area.left * size.width, s.area.top * size.height,
              s.area.width * size.width, s.area.height * size.height)
          .inflate(22)
          .contains(point));
  @override
  bool overlappingLights(Offset point, Size size) =>
      moon.contains(point, size) && _cageLit(point, size);

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
    game.removeAll([..._parts, ..._doors]);
    _parts.clear();
    _doors.clear();
  }

  @override
  void begin(NightRun run,
      {required bool thickClouds, required double afterglowSeconds}) {
    traps.begin(run);
    moon.reset(fullMoon: run.has(NightCard.fullMoon), thickClouds: thickClouds);
    game.removeAll(_doors);
    _doors.clear();
    _doors.addAll([
      for (final slot in traps.slots)
        WarehouseDoor(slot, traps,
            onClose: close,
            canClose: (s) =>
                traps.catchable(s, forgiving: game.night!.acceptsAnyBed))
    ]);
    game.addAll(_doors);
  }

  @override
  void prepareBait() {
    final slot = traps.slots.firstWhere((s) => s.canBait);
    placeBait(
        Offset(slot.area.center.dx * game.size.x,
            slot.area.center.dy * game.size.y),
        free: true);
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
      onFirstLight(
          Offset(slot.area.center.dx * game.size.x,
              slot.area.center.dy * game.size.y),
          game.size.x * .16);
    }
    return true;
  }

  Vector2 _entry(TrapSlot s, CatComponent cat) => Vector2(
      s.area.left * game.size.x - cat.size.x * .6,
      s.area.center.dy * game.size.y - cat.size.y / 2);
  Vector2 _inside(TrapSlot s, CatComponent cat) => Vector2(
      (s.area.left + s.area.width * (run.has(NightCard.deepBait) ? .64 : .55)) *
              game.size.x -
          cat.size.x / 2,
      s.area.center.dy * game.size.y - cat.size.y / 2);
  void _release(TrapSlot slot, {bool startled = false}) {
    final actor = _cats.remove(slot);
    if (actor == null) return;
    final cat = actor.cat;
    final center = cat.center.clone();
    cat.size.setFrom(actor.size);
    cat.position = center - cat.size / 2;
    cat.position.x =
        cat.position.x.clamp(0, math.max(0, game.size.x - cat.size.x));
    cat.position.y = cat.position.y.clamp(game.size.y * .2, game.size.y * .7);
    cat.leaveTrap(startled: startled);
  }

  void close(TrapSlot selected) {
    final night = game.night!;
    if (game.paused || night.phase != NightPhase.playing) return;
    if (!_cats.containsKey(selected)) {
      game.hud.showBanner(['Chờ mèo vào rồi mới chốt cửa'], 1.3);
      return;
    }
    for (final slot in traps.closingGroup(selected).toList()) {
      if (night.phase != NightPhase.playing) break;
      final actor = _cats[slot];
      if (actor == null) continue;
      final caught = traps.catchable(slot, forgiving: night.acceptsAnyBed);
      if (caught) {
        // Mark the cat before notifying the controller, so a linked door cannot pay twice.
        _cats.remove(slot);
        traps.reset(slot);
        actor.cat.rescueFromTrap();
        GameAudio.instance.playRescue(GameSound.catRescue, important: true);
      } else {
        _release(slot, startled: !night.assist.calm);
        traps.reset(slot);
        game.stats.startles++;
        final center = Vector2(slot.area.center.dx * game.size.x,
            slot.area.center.dy * game.size.y);
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
      if (event == TrapEvent.escaped) {
        _release(slot);
      } else {
        final cat = _cats[slot]?.cat;
        if (cat != null) night.cardEffects.onFed(cat);
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
          ..sort((a, b) => (a.position - _inside(slot, a))
              .length2
              .compareTo((b.position - _inside(slot, b)).length2));
        if (candidates.isNotEmpty) {
          final cat = candidates.first;
          _cats[slot] = _TrapCat(cat);
          final available =
              slot.area.width * game.size.x * (cat.isBoss ? .7 : .62);
          cat.size.scale(math.min(1, available / cat.size.x));
          traps.assign(slot, boss: cat.isBoss, trusting: cat.hasEaten);
          cat.hasEaten = false;
          cat.enterTrap();
        }
      }
    }
    for (final entry in _cats.entries.toList()) {
      final slot = entry.key, cat = entry.value.cat;
      if (slot.phase == TrapPhase.approaching) {
        final target = _entry(slot, cat), delta = target - cat.position;
        final step = 85 * run.lure * dt;
        if (delta.length <= step + 1) {
          cat.positionInTrap(target, walking: false);
          traps.arrive(slot);
        } else {
          cat.positionInTrap(cat.position + delta.normalized() * step,
              walking: true);
        }
      } else {
        final from = _entry(slot, cat), to = _inside(slot, cat);
        cat.positionInTrap(from + (to - from) * traps.progress(slot),
            walking: slot.phase != TrapPhase.inside &&
                slot.phase != TrapPhase.peeking);
      }
    }
  }

  Iterable<(Offset, double)> _lights() sync* {
    for (final slot in traps.slots) {
      if (slot.baited || slot.occupied || slot.cool > 0) {
        yield (
          Offset(slot.area.center.dx * game.size.x,
              slot.area.center.dy * game.size.y),
          65
        );
      }
    }
    for (final cat in game.children.whereType<CatComponent>()) {
      yield (cat.center.toOffset(), 34);
    }
  }
}
