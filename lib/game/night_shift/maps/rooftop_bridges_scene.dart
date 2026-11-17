import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/painting.dart';
import '../../../audio/game_audio.dart';
import '../../components/cat_component.dart';
import '../../components/darkness_component.dart';
import '../../components/hud_component.dart';
import '../../meow_shelter_game.dart';
import '../moonlight_art.dart';
import '../night_cards.dart';
import '../night_run.dart';
import '../night_scene.dart';
import 'rooftop_bridges.dart';
import 'rooftop_bridges_painter.dart';

class RooftopBridgesScene extends NightScene {
  RooftopBridgesScene(this.game, {required this.onFirstLight});
  final MeowShelterGame game;
  final void Function(Offset, double) onFirstLight;
  final roof = RooftopBridges();
  final _components = <Component>[];
  final _bridges = <RoofBridgeComponent>[];

  @override
  NightMap get map => NightMap.rooftops;
  @override
  double get lanternBurn => roof.openTime;
  @override
  bool get cloudy => roof.moon.cloudy;
  @override
  double get notificationTop => 46;
  @override
  List<String> get rules => const [
        'Ba mái: mèo xuất hiện ở cả ba mái',
        'Mái giữa: chỉ đặt cá ở mái giữa, hạ cầu cho mèo sang',
      ];
  @override
  void onMistake() {}
  @override
  bool blocks(Rect bounds) => roof.blocks(bounds);
  @override
  bool allowsBait(Offset point, Size field) => roof.allowsBait(point, field);
  @override
  Offset? lureWaypoint(Rect catBounds, Offset target, Size field) =>
      roof.lureWaypoint(catBounds, target, field);
  @override
  Offset? spawnPosition(Size field, Size cat, Random random) =>
      roof.spawnPosition(field, cat, random);
  @override
  bool isLit(Offset point, Size size) => roof.isLit(point, size);
  @override
  bool overlappingLights(Offset point, Size size) =>
      roof.moon.contains(point, size) && roof.bridgeLit(point, size);

  @override
  void mount() {
    _components.addAll([
      RooftopBackground(),
      RooftopAtmosphere(roof),
      DarknessComponent(
          lights: _lights,
          additionalLights: (canvas, size) =>
              paintMoonlitField(canvas, size, roof.moon),
          visible: () => game.hud.status == RoundStatus.playing,
          shade: const Color(0x30142932)),
    ]);
    game.addAll(_components);
  }

  @override
  void remove() {
    game.removeAll([..._components, ..._bridges]);
    _components.clear();
    _bridges.clear();
  }

  @override
  void begin(NightRun run,
      {required bool thickClouds, required double afterglowSeconds}) {
    roof.begin(run,
        thickClouds: thickClouds, afterglowSeconds: afterglowSeconds);
    game.removeAll(_bridges);
    _bridges
      ..clear()
      ..addAll([
        for (final bridge in roof.bridges)
          RoofBridgeComponent(bridge, roof, onTapBridge: _tapBridge)
      ]);
    game.addAll(_bridges);
  }

  void _tapBridge(RoofBridge bridge) {
    if (game.paused || game.hud.status != RoundStatus.playing) return;
    if (!roof.lower(bridge)) {
      if (!bridge.active) {
        game.hud.showBanner([
          bridge.repair > 0
              ? 'Cầu đang sửa · ${bridge.repair.ceil()}s'
              : 'Cầu ván đang được kéo lại'
        ], 1.2);
      }
      return;
    }
    GameAudio.instance.playRescue(GameSound.catGrab);
    _notifyOpened();
  }

  void _notifyOpened() {
    for (final (bridge, auto) in roof.opened) {
      if (!bridge.firstOpen && !auto) continue;
      bridge.firstOpen = false;
      final rect = roof.bridgeRect(bridge, game.size.toSize());
      onFirstLight(rect.center, rect.longestSide);
    }
    roof.opened.clear();
  }

  @override
  void update(double dt) {
    final field = game.size;
    roof.update(dt,
        occupied: game.children
            .whereType<CatComponent>()
            .where((cat) => !cat.isCarried && !cat.isDelivered)
            .map((cat) => Rect.fromLTWH(
                cat.position.x / field.x,
                cat.position.y / field.y,
                cat.size.x / field.x,
                cat.size.y / field.y)));
    _notifyOpened();
  }

  Iterable<(Offset, double)> _lights() sync* {
    final screen = game.size.toSize();
    for (final bridge in roof.bridges) {
      if (bridge.active) {
        yield (
          roof.bridgeRect(bridge, screen).center,
          roof.safetyLights ? 100 : 70
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
}
