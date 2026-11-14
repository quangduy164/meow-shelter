import 'dart:math' as math;
import 'package:flutter/painting.dart';
import '../moonlight.dart';
import '../night_cards.dart';
import '../night_run.dart';

class MarketLamp {
  MarketLamp(this.spot);
  final Offset spot;
  double burn = 0, cool = 0, ember = 0;
  bool firstLight = true;
  bool get lit => burn > 0;
  Offset center(Size size) =>
      Offset(spot.dx * size.width, spot.dy * size.height);
}

/// Traffic and mistakes build noise; a loud burst scares only unprotected cats.
class NightMarket {
  final moon = Moonlight();
  final lamps = <MarketLamp>[];
  double clock = 0, noise = 0, alarm = 0;
  double lampDuration = 18, lightScale = 1, afterglow = 0;
  double _mistakeScale = 1, _trafficScale = 1, _quietRate = 1.5;
  double trafficPeriod = 16;
  int _lastCart = 0;

  void begin(NightRun run,
      {required bool thickClouds, required double afterglowSeconds}) {
    clock = noise = alarm = 0;
    _lastCart = 0;
    afterglow = afterglowSeconds;
    moon.reset(fullMoon: run.has(NightCard.fullMoon), thickClouds: thickClouds);
    lampDuration = (18 + 8 * run.count(NightCard.backupPower)) *
        (1 + .5 * run.count(NightCard.longWick)) /
        (run.has(NightCard.nightWind) ? 2 : 1);
    lightScale = run.lanternLight;
    _mistakeScale = math.pow(.5, run.count(NightCard.quietSteps)).toDouble();
    _trafficScale = math.pow(.7, run.count(NightCard.softWheels)).toDouble();
    _quietRate = 1.5 + run.count(NightCard.quietCorner);
    trafficPeriod = run.has(NightCard.busyMarket) ? 12 : 16;
    lamps
      ..clear()
      ..addAll([
        MarketLamp(const Offset(.27, .43)),
        MarketLamp(const Offset(.5, .55)),
        MarketLamp(const Offset(.73, .43)),
      ]);
  }

  void mistake() => noise = (noise + 8 * _mistakeScale).clamp(0.0, 100.0);

  /// Returns true once when noise reaches the alarm threshold.
  bool update(double dt) {
    final alreadyLoud = noise >= 100;
    clock += dt;
    moon.update(dt);
    alarm = math.max(0, alarm - dt);
    noise = math.max(0, noise - _quietRate * dt);
    final cart = ((clock + 2) / trafficPeriod).floor();
    if (cart > _lastCart) {
      noise =
          (noise + 42 * _trafficScale * (cart - _lastCart)).clamp(0.0, 100.0);
      _lastCart = cart;
    }
    for (final lamp in lamps) {
      if (lamp.lit) {
        lamp.burn = math.max(0, lamp.burn - dt);
        if (!lamp.lit) {
          lamp.cool = 5;
          lamp.ember = afterglow;
        }
      } else {
        lamp.cool = math.max(0, lamp.cool - dt);
        lamp.ember = math.max(0, lamp.ember - dt);
      }
    }
    if (!alreadyLoud && noise < 100) return false;
    noise = 25;
    alarm = 2.5;
    return true;
  }

  bool light(MarketLamp lamp) {
    if (lamp.lit || lamp.cool > 0) return false;
    lamp.burn = lampDuration;
    return true;
  }

  double get _phase => clock % trafficPeriod;
  bool get cartWarning =>
      _phase >= trafficPeriod - 6 && _phase < trafficPeriod - 4;
  double? get cartProgress =>
      _phase >= trafficPeriod - 4 ? (_phase - trafficPeriod + 4) / 4 : null;
  double radius(Size size) => size.height * .2 * lightScale;
  bool lampLit(Offset point, Size size) => lamps.any((lamp) =>
      (lamp.lit || lamp.ember > 0) &&
      (point - lamp.center(size)).distance <=
          radius(size) * .85 * (lamp.lit ? 1 : .75));
  bool isLit(Offset point, Size size) =>
      moon.contains(point, size) || lampLit(point, size);
}
