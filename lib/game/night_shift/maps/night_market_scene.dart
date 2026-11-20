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

class NightMarketScene extends NightScene {
  NightMarketScene(this.game, {required this.onFirstLight});
  final MeowShelterGame game;
  final void Function(Offset, double) onFirstLight;
  final market = NightMarket();
  final _components = <Component>[];

  @override
  double get notificationTop => 104;
  @override
  NightMap get map => NightMap.marketAlley;
  @override
  double get lanternBurn => 0;
  @override
  bool get cloudy => market.moon.cloudy;
  @override
  List<String> get rules => const [
        'Ra hiệu xe: chạm xe đẩy để nó đi nhẹ; chạm khi biển báo còn sáng thì xe đi êm hẳn',
        'Yên tĩnh sau xe: mèo ngoan, độ ồn giảm nhanh',
        'Xe chở cá: cá chưa ai nhận ven đường được chở đi',
      ];
  @override
  bool blocks(Rect bounds) => false;
  @override
  void onMistake() => market.mistake();
  @override
  void onRescue() => market.onRescue();
  @override
  bool get peaceful => market.quietLeft > 0;
  @override
  bool get hasBaitInTransit => market.carryingFish;
  @override
  bool isLit(Offset point, Size size) => market.isLit(point, size);
  @override
  bool overlappingLights(Offset point, Size size) => false;

  @override
  void mount() {
    _components.addAll([
      NightMarketBackground(),
      NightMarketAtmosphere(market),
      MarketCartSignal(market, onSignal: _signal),
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
    game.removeAll(_components);
    _components.clear();
  }

  @override
  void begin(NightRun run,
      {required bool thickClouds, required double afterglowSeconds}) {
    market.begin(run,
        thickClouds: thickClouds, afterglowSeconds: afterglowSeconds);
    _signalled = false;
  }

  bool _signalled = false;

  void _signal() {
    if (game.paused || game.hud.status != RoundStatus.playing) return;
    if (!market.hush()) return;
    GameAudio.instance.playRescue(GameSound.moonReveal);
    final screen = game.size;
    final at = Offset(
        market.cartProgress == null
            ? (market.cartFromRight ? screen.x - 40 : 40)
            : market.cartX(screen.x),
        screen.y * .85);
    game.hud.showBanner(
        [market.cartProgress == null ? 'Xe sẽ đi êm hẳn' : 'Xe đi nhẹ lại'],
        1.1);
    if (!_signalled) {
      _signalled = true;
      onFirstLight(at, screen.x * .2);
    }
  }

  @override
  void update(double dt) {
    final trips = market.cartTrips;
    final wasWarning = market.cartWarning;
    final wasMoving = market.cartProgress != null;
    final alarm = market.update(dt);
    if (!wasWarning && market.cartWarning) {
      GameAudio.instance.playRescue(GameSound.rescueFlood, important: true);
    } else if (!wasMoving && market.cartProgress != null && !market.hushed) {
      GameAudio.instance.playRescue(GameSound.nightCart);
    }
    final screen = game.size;
    final cats = game.children.whereType<CatComponent>();
    if (market.cartTrips > trips) {
      final carried = market.carryingFish;
      market.carryingFish = false;
      if (carried) {
        game.bait.place(Vector2(screen.x * .73, screen.y * .65), screen, cats,
            free: true);
      }
      if (game.night!.run!.has(NightCard.cartFish)) {
        for (var i = trips; i < market.cartTrips; i++) {
          game.bait.place(Vector2(screen.x * .5, screen.y * .62), screen, cats,
              free: true);
        }
      }
    }
    final progress = market.cartProgress;
    if (progress != null && !market.carryingFish) {
      market.carryingFish = game.bait
          .takeWaitingNear(Vector2(market.cartX(screen.x), screen.y * .89), 65);
    }
    if (alarm) {
      GameAudio.instance.playRescue(GameSound.rescueNotice, important: true);
      for (final cat in game.children.whereType<CatComponent>()) {
        cat.reactToNoise();
      }
    }
  }

  Iterable<(Offset, double)> _lights() sync* {
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
