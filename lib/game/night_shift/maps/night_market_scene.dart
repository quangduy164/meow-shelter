import 'package:flame/components.dart';
import 'package:flutter/painting.dart';
import '../../../audio/game_audio.dart';
import '../../components/cat_component.dart';
import '../../components/darkness_component.dart';
import '../../components/hud_component.dart';
import '../../meow_shelter_game.dart';
import '../night_cards.dart';
import '../night_run.dart';
import '../night_scene.dart';
import '../moonlight_art.dart';
import 'night_market.dart';
import 'night_market_painter.dart';

class NightMarketScene implements NightScene {
  NightMarketScene(this.game, {required this.onFirstLight});
  final MeowShelterGame game;
  final void Function(Offset, double) onFirstLight;
  final market = NightMarket();
  final _components = <Component>[];
  final _lamps = <MarketLampComponent>[];

  @override
  double get notificationTop => 104;
  @override
  NightMap get map => NightMap.marketAlley;
  @override
  double get lanternBurn => market.lampDuration;
  @override
  bool get cloudy => market.moon.cloudy;
  @override
  List<String> get rules => const [
        'Độ ồn 100: mèo ngoài vùng sáng hoảng; bế mèo đang cầm vẫn an toàn'
      ];
  @override
  void onMistake() => market.mistake();
  @override
  bool isLit(Offset point, Size size) => market.isLit(point, size);
  @override
  bool overlappingLights(Offset point, Size size) =>
      market.moon.contains(point, size) && market.lampLit(point, size);

  @override
  void mount() {
    _components.addAll([
      NightMarketBackground(),
      MarketLightPools(market),
      NightMarketAtmosphere(market),
      DarknessComponent(
          lights: _lights,
          additionalLights: _eraseMoon,
          visible: () => game.hud.status == RoundStatus.playing,
          shade: const Color(0x30142932)),
    ]);
    game.addAll(_components);
  }

  @override
  void remove() {
    game.removeAll([..._components, ..._lamps]);
    _components.clear();
    _lamps.clear();
  }

  @override
  void begin(NightRun run,
      {required bool thickClouds, required double afterglowSeconds}) {
    market.begin(run,
        thickClouds: thickClouds, afterglowSeconds: afterglowSeconds);
    game.removeAll(_lamps);
    _lamps
      ..clear()
      ..addAll([
        for (final lamp in market.lamps)
          MarketLampComponent(lamp, market, onTapLamp: _tapLamp)
      ]);
    game.addAll(_lamps);
  }

  void _tapLamp(MarketLamp lamp) {
    if (game.paused || game.hud.status != RoundStatus.playing) return;
    if (!market.light(lamp)) return;
    GameAudio.instance.playRescue(GameSound.baitDrop);
    if (lamp.firstLight) {
      lamp.firstLight = false;
      onFirstLight(lamp.center(game.size.toSize()),
          market.radius(game.size.toSize()) * .85);
    }
  }

  @override
  void update(double dt) {
    if (market.update(dt)) {
      GameAudio.instance.playRescue(GameSound.rescueNotice, important: true);
      for (final cat in game.children.whereType<CatComponent>()) {
        cat.reactToNoise();
      }
    }
  }

  Iterable<(Offset, double)> _lights() sync* {
    final screen = game.size.toSize();
    for (final lamp in market.lamps) {
      if (lamp.lit || lamp.ember > 0) {
        yield (
          lamp.center(screen),
          market.radius(screen) * (lamp.lit ? 1 : .75)
        );
      }
    }
    for (final shelter in game.shelters) {
      yield (shelter.center.toOffset(), 75);
    }
    for (final fish in game.bait.positions) {
      yield (fish.toOffset(), 55);
    }
    for (final cat in game.children.whereType<CatComponent>()) {
      yield (cat.center.toOffset(), 34);
    }
  }

  void _eraseMoon(Canvas canvas, Size size) =>
      paintMoonlitField(canvas, size, market.moon);
}
