import 'package:flame/components.dart';
import 'package:flutter/painting.dart';
import '../../../audio/game_audio.dart';
import '../../meow_shelter_game.dart';
import '../../components/cat_component.dart';
import '../../components/darkness_component.dart';
import '../../components/hud_component.dart';
import '../night_cards.dart';
import '../night_run.dart';
import '../night_scene.dart';
import '../moonlight_art.dart';
import 'moonlit_yard.dart';
import 'moonlit_yard_painter.dart';

class MoonlitYardScene extends NightScene {
  MoonlitYardScene(this.game, {required this.onFirstLight});
  final MeowShelterGame game;
  final void Function(Offset, double) onFirstLight;
  final yard = MoonlitYard();
  final _components = <Component>[];
  final _lanterns = <LanternComponent>[];
  @override
  double get notificationTop => 46;
  @override
  NightMap get map => NightMap.backyard;
  @override
  List<String> get rules => [
        if (game.night!.run!.has(NightCard.moonEcho))
          'Đốm trăng màu xanh nhạt còn sáng sau khi vệt trăng đi qua',
        if (game.night!.run!.has(NightCard.lanternRelay))
          'Bật đèn sẽ nối thêm thời gian cho đèn gần nhất đang sáng',
      ];
  @override
  bool blocks(Rect bounds) => false;
  @override
  void onMistake() {}
  @override
  double get lanternBurn => yard.burnTime;
  @override
  bool get cloudy => yard.cloudy;
  @override
  bool isLit(Offset point, Size size) => yard.isLit(point, size);
  @override
  bool overlappingLights(Offset point, Size size) =>
      yard.isMoonLit(point, size) && yard.isLanternLit(point, size);

  @override
  void mount() {
    _components.addAll([
      MoonlitYardBackground(),
      LanternLightComponent(yard),
      MoonlitYardOverlay(
          yard: yard, cats: () => game.children.whereType<CatComponent>()),
      DarknessComponent(
          lights: _yardLights,
          additionalLights: _eraseMoonlight,
          visible: () => game.hud.status == RoundStatus.playing,
          shade: const Color(0x30142932)),
    ]);
    game.addAll(_components);
  }

  @override
  void remove() {
    game.removeAll([..._components, ..._lanterns]);
    _components.clear();
    _lanterns.clear();
  }

  @override
  void begin(NightRun run,
      {required bool thickClouds, required double afterglowSeconds}) {
    yard.setup(
        count: run.lanterns,
        burnTime: run.lanternBurn,
        lightScale: run.lanternLight,
        fullMoon: run.has(NightCard.fullMoon),
        thickClouds: thickClouds,
        emberDuration: afterglowSeconds,
        echoDuration: run.has(NightCard.moonEcho)
            ? 1 + 2.0 * run.count(NightCard.moonEcho)
            : 0,
        linkSeconds: 2.0 * run.count(NightCard.lanternRelay));
    game.removeAll(_lanterns);
    _lanterns
      ..clear()
      ..addAll([
        for (final lantern in yard.lanterns)
          LanternComponent(lantern: lantern, onTapLantern: _tapLantern)
      ]);
    game.addAll(_lanterns);
  }

  @override
  void update(double dt) => yard.update(dt);

  /// Light pools for the night yard: lanterns and moonlight do the real
  /// lighting; fish, beds and cats glow just enough to be found.
  Iterable<(Offset, double)> _yardLights() sync* {
    yield* yard.lights(game.size.toSize());
    for (final fish in game.bait.positions) {
      yield (Offset(fish.x, fish.y), 55);
    }
    for (final shelter in game.shelters) {
      yield (shelter.center.toOffset(), 75);
    }
    for (final cat in game.children.whereType<CatComponent>()) {
      yield (cat.center.toOffset(), cat.catchWindow.canCatch ? 48 : 34);
    }
  }

  void _eraseMoonlight(Canvas canvas, Size size) {
    paintMoonlitField(canvas, size, yard.moon);
    paintMoonEchoes(canvas, size, yard, erase: true);
  }

  void _tapLantern(YardLantern lantern) {
    if (game.hud.status != RoundStatus.playing || game.paused) {
      return;
    }
    if (yard.light(lantern)) {
      GameAudio.instance.playRescue(GameSound.baitDrop);
      if (!lantern.chimed) {
        lantern.chimed = true;
        onFirstLight(lantern.lamp(game.size.toSize()),
            yard.lanternRadius(game.size.toSize()) * .85);
      }
    } else if (!lantern.lit) {
      game.hud.showBanner(['Đèn đang nguội, chờ một chút'], 1.2);
    }
  }
}
