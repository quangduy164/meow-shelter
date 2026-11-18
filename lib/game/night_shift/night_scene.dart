import 'dart:math';
import 'package:flutter/painting.dart';
import '../components/cat_component.dart';
import '../meow_shelter_game.dart';
import 'night_cards.dart';
import 'night_run.dart';
import 'maps/moonlit_yard_scene.dart';
import 'maps/night_market_scene.dart';
import 'maps/rooftop_bridges_scene.dart';
import 'maps/warehouse_traps_scene.dart';
import 'maps/reed_garden_scene.dart';
import 'maps/harbor_flow_scene.dart';
import 'maps/night_station_scene.dart';
import 'maps/claw_machine_scene.dart';

/// Each map owns its scenery, resource timers and lit-area rules.
abstract class NightScene {
  NightMap get map;
  double get lanternBurn;
  bool get cloudy;
  double get notificationTop;
  List<String> get rules;
  void onMistake();
  void onRescue() {}
  bool get peaceful => false;
  bool get usesTraps => false;
  bool get ownsBait => usesTraps;
  bool get noCarry => usesTraps;
  bool tapCat(CatComponent cat) => false;

  /// Relic help near [point] for maps without carryable cats. Returns how many
  /// cats were helped, or -1 to use the shared feed-a-step rule.
  int helpNear(Offset point, double reach, int targets) => -1;

  /// Himalaya helper on maps without carryable cats; -1 keeps the shared
  /// 'two cats are full at once' rule.
  int helperBoost(int count) => -1;
  bool placeBait(Offset point, {bool free = false}) => false;
  void prepareBait() {}
  bool get hasBaitInTransit => false;
  void mount();
  void remove();
  void begin(NightRun run,
      {required bool thickClouds, required double afterglowSeconds});
  void update(double dt);
  bool isLit(Offset point, Size size);
  bool overlappingLights(Offset point, Size size);

  /// Bounds are fractions of the field; map-specific walls and gaps.
  bool blocks(Rect bounds);

  bool allowsBait(Offset point, Size field) => true;

  /// Null means wait for a route; otherwise return the next walking point.
  Offset? lureWaypoint(Rect catBounds, Offset target, Size field) => target;

  /// Null keeps the shared spawn placement.
  Offset? spawnPosition(Size field, Size cat, Random random) => null;
}

NightScene createNightScene(NightMap map, MeowShelterGame game,
        {required void Function(Offset, double) onFirstLight}) =>
    switch (map) {
      NightMap.backyard => MoonlitYardScene(game, onFirstLight: onFirstLight),
      NightMap.marketAlley =>
        NightMarketScene(game, onFirstLight: onFirstLight),
      NightMap.rooftops =>
        RooftopBridgesScene(game, onFirstLight: onFirstLight),
      NightMap.warehouse =>
        WarehouseTrapsScene(game, onFirstLight: onFirstLight),
      NightMap.reedGarden => ReedGardenScene(game, onFirstLight: onFirstLight),
      NightMap.harbor => HarborFlowScene(game, onFirstLight: onFirstLight),
      NightMap.station => NightStationScene(game, onFirstLight: onFirstLight),
      NightMap.clawMachine =>
        ClawMachineScene(game, onFirstLight: onFirstLight),
    };
