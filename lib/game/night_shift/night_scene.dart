import 'dart:math';
import 'package:flutter/painting.dart';
import '../meow_shelter_game.dart';
import 'night_cards.dart';
import 'night_run.dart';
import 'maps/moonlit_yard_scene.dart';
import 'maps/night_market_scene.dart';
import 'maps/rooftop_bridges_scene.dart';

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
    };
