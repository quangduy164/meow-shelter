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
import 'reed_garden.dart';
import 'reed_garden_painter.dart';

class ReedGardenScene extends NightScene {
  ReedGardenScene(this.game, {required this.onFirstLight});
  final MeowShelterGame game;
  final void Function(Offset, double) onFirstLight;
  final garden = ReedGarden();
  final moon = Moonlight();
  final _parts = <Component>[];
  final _patches = <ReedPatchComponent>[];
  final _hidden = <ReedPatch, CatComponent>{};
  final _moveLeft = <CatComponent, double>{};
  final _runners = <_ReedRunner>[];
  NightRun get run => game.night!.run!;

  @override
  NightMap get map => NightMap.reedGarden;
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
  bool get hasBaitInTransit =>
      _hidden.isNotEmpty ||
      _runners.isNotEmpty ||
      garden.patches.any((p) => p.baited);
  @override
  List<String> get rules => const [
        'Mèo trốn trong bụi lau và để lại vết khi đổi bụi',
        'Chạm đúng bụi để mèo lộ ra; mèo lộ ra đã sẵn sàng bế',
      ];
  @override
  void onMistake() {}
  @override
  bool blocks(Rect bounds) => garden.blocks(bounds);
  @override
  bool allowsBait(Offset point, Size field) => garden.at(point, field) != null;
  @override
  Offset? spawnPosition(Size field, Size cat, math.Random random) {
    for (var i = 0; i < 30; i++) {
      final p = Offset(random.nextDouble() * (field.width - cat.width),
          field.height * (.2 + random.nextDouble() * .5));
      if (!blocks(Rect.fromLTWH(p.dx / field.width, p.dy / field.height,
          cat.width / field.width, cat.height / field.height))) {
        return p;
      }
    }
    return Offset(field.width * .05, field.height * .2);
  }

  Rect _px(ReedPatch p) => Rect.fromLTWH(
      p.area.left * game.size.x,
      p.area.top * game.size.y,
      p.area.width * game.size.x,
      p.area.height * game.size.y);
  bool _patchLit(Offset point) => garden.patches.any(
      (p) => (p.shake > 0 || p.baited) && _px(p).inflate(24).contains(point));
  @override
  bool isLit(Offset point, Size size) =>
      moon.contains(point, size) || _patchLit(point);
  @override
  bool overlappingLights(Offset point, Size size) =>
      moon.contains(point, size) && _patchLit(point);

  @override
  void mount() {
    _parts.addAll([
      ReedGardenBackground(),
      DarknessComponent(
          lights: _lights,
          visible: () => game.hud.status == RoundStatus.playing,
          additionalLights: (canvas, size) =>
              paintMoonlitField(canvas, size, moon),
          shade: const Color(0x2C142932)),
      ReedMoon(moon),
      ReedExitComponent(garden),
      ReedTrailsComponent(garden),
    ]);
    game.addAll(_parts);
  }

  @override
  void remove() {
    for (final cat in _hidden.values) {
      cat.hiddenInCover = false;
      cat.trapManaged = false;
    }
    _hidden.clear();
    _moveLeft.clear();
    _runners.clear();
    game.removeAll([..._parts, ..._patches]);
    _parts.clear();
    _patches.clear();
  }

  @override
  void begin(NightRun run,
      {required bool thickClouds, required double afterglowSeconds}) {
    garden.begin(run);
    moon.reset(fullMoon: run.has(NightCard.fullMoon), thickClouds: thickClouds);
    _hidden.clear();
    _moveLeft.clear();
    _runners.clear();
    game.removeAll(_patches);
    _patches
      ..clear()
      ..addAll([
        for (final patch in garden.patches)
          ReedPatchComponent(patch, onTapPatch: tapPatch)
      ]);
    game.addAll(_patches);
  }

  Vector2 _coverSpot(ReedPatch patch, CatComponent cat) {
    final r = _px(patch);
    return Vector2(r.center.dx - cat.size.x / 2, r.bottom - cat.size.y * .9);
  }

  void _hide(CatComponent cat, ReedPatch patch) {
    patch.occupied = true;
    _hidden[patch] = cat;
    _moveLeft[cat] = garden.moveSeconds * (.65 + game.random.nextDouble() * .7);
    cat.hideInCover(_coverSpot(patch, cat));
  }

  void _move(ReedPatch from, ReedPatch to) {
    final cat = _hidden.remove(from);
    if (cat == null) return;
    garden.move(from, to);
    _hidden[to] = cat;
    cat.position.setFrom(_coverSpot(to, cat));
    _moveLeft[cat] = garden.moveSeconds;
  }

  @override
  void prepareBait() {
    final patch = garden.patches.firstWhere((p) => !p.occupied && !p.baited);
    placeBait(_px(patch).center, free: true);
  }

  @override
  bool placeBait(Offset point, {bool free = false}) {
    final patch = garden.at(point, game.size.toSize());
    if (patch == null || patch.occupied || patch.baited || patch.cool > 0) {
      game.hud.showBanner([
        patch == null
            ? 'Đặt cá vào một bụi lau'
            : patch.occupied
                ? 'Bụi này có tiếng động, hãy chạm để tìm'
                : 'Bụi này chưa dùng được'
      ], 1.5);
      return false;
    }
    if (!free && !game.bait.spend()) return false;
    garden.bait(patch, paid: !free && game.bait.limited);
    if (game.bait.limited) game.hud.fishLeft = game.bait.fishCount;
    GameAudio.instance.playRescue(GameSound.baitDrop);
    return true;
  }

  void _escape(ReedPatch from, ReedPatch exit) {
    final cat = _hidden.remove(from);
    if (cat == null) return;
    garden.move(from, exit);
    _moveLeft.remove(cat);
    cat.hiddenInCover = false;
    final r = _px(exit);
    _runners.add(_ReedRunner(cat,
        Vector2(r.center.dx - cat.size.x / 2, r.bottom - cat.size.y * .9)));
  }

  void tapPatch(ReedPatch patch) {
    final night = game.night!;
    if (game.paused || night.phase != NightPhase.playing || patch.cool > 0) {
      return;
    }
    patch
      ..cool = 1.2
      ..shake = .8;
    if (!patch.chimed) {
      patch.chimed = true;
      onFirstLight(_px(patch).center, game.size.x * .18);
    }
    final quiet = garden.softParting || night.assist.calm;
    if (patch.occupied && !quiet) {
      game.stats.startles++;
      final to = garden.emptyNear(patch, game.random);
      if (to != null) _move(patch, to);
      game.hud.showBanner(['Chạm trúng chỗ nấp! Mèo chạy loạn'], 1.4);
      GameAudio.instance.playRescue(GameSound.catWrong);
      return;
    }
    var moved = 0, saved = 0;
    for (final from
        in garden.neighbors(patch).where((p) => p.occupied).toList()) {
      final to = garden.fleeTarget(from, patch);
      if (to == null) continue;
      moved++;
      if (to.index < 0) {
        saved++;
        _escape(from, to);
      } else {
        _move(from, to);
      }
    }
    GameAudio.instance.playRescue(
        saved > 0 ? GameSound.catRescue : GameSound.baitDrop,
        important: saved > 0);
    game.hud.showBanner([
      saved > 0
          ? 'Lùa thành công · $saved mèo ra lối'
          : moved > 0
              ? 'Mèo bị lùa sang bụi xa hơn'
              : patch.occupied
                  ? 'Mèo nép yên trong bụi'
                  : 'Không có mèo cạnh bụi này'
    ], 1.3);
  }

  @override
  void update(double dt) {
    moon.update(dt);
    if (garden.update(dt) != null) {
      game.hud.showBanner(['Chuông lau: có bụi vừa rung mạnh'], 1.2);
    }
    for (final cat in game.children.whereType<CatComponent>()) {
      if (!cat.isLoaded ||
          cat.isDelivered ||
          cat.hiddenInCover ||
          cat.trapManaged) {
        continue;
      }
      final empty =
          garden.patches.where((p) => !p.occupied && !p.baited).toList();
      if (empty.isNotEmpty) {
        _hide(cat, empty[game.random.nextInt(empty.length)]);
      }
    }
    for (final runner in _runners.toList()) {
      final delta = runner.target - runner.cat.position;
      final step = 170 * dt;
      if (delta.length <= step) {
        _runners.remove(runner);
        runner.cat.positionInTrap(runner.target, walking: false);
        if (game.night!.phase == NightPhase.playing) {
          runner.cat.rescueFromTrap();
        }
      } else {
        runner.cat.positionInTrap(
            runner.cat.position + delta.normalized() * step,
            walking: true);
      }
    }
    for (final entry in _hidden.entries.toList()) {
      final cat = entry.value;
      final left = (_moveLeft[cat] ?? garden.moveSeconds) - dt;
      if (left > 0) {
        _moveLeft[cat] = left;
        continue;
      }
      final to = garden.emptyNear(entry.key, game.random);
      if (to == null) {
        _moveLeft[cat] = 1;
      } else {
        _move(entry.key, to);
      }
    }
    for (final patch in garden.patches.where((p) => p.baited && p.bait <= 0)) {
      final source = garden
          .neighbors(patch, reach: garden.baitReach)
          .where((p) => p.occupied)
          .firstOrNull;
      if (source == null) continue;
      _move(source, patch);
      patch.baited = patch.paid = false;
      patch.shake = 1.2;
      final cat = _hidden[patch];
      if (cat != null) game.night!.cardEffects.onFed(cat);
      game.hud.showBanner(['Có mèo vừa chui vào bụi có cá'], 1.3);
    }
  }

  Iterable<(Offset, double)> _lights() sync* {
    for (final patch in garden.patches) {
      if (patch.shake > 0 || patch.baited) yield (_px(patch).center, 70);
    }
    for (final cat in game.children.whereType<CatComponent>()) {
      if (!cat.hiddenInCover) {
        yield (cat.center.toOffset(), cat.catchWindow.canCatch ? 48 : 34);
      }
    }
  }
}

class _ReedRunner {
  _ReedRunner(this.cat, this.target);
  final CatComponent cat;
  final Vector2 target;
}
