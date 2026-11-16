import 'dart:math' as math;
import 'package:flutter/painting.dart';
import '../moonlight.dart';
import '../night_cards.dart';
import '../night_run.dart';
import '../night_variants.dart';

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
  final _tripEnds = <double>[];
  int _noiseIndex = 0;
  bool alternateDirections = false;
  double get _tripStart => cartTrips == 0 ? 0 : _tripEnds[cartTrips - 1];
  double get trafficPeriod => _tripEnds[cartTrips] - _tripStart;
  bool get cartFromRight => alternateDirections && cartTrips.isOdd;
  double cartX(double width) {
    final progress = cartProgress ?? 0;
    return -100 + (width + 200) * (cartFromRight ? 1 - progress : progress);
  }

  double quietLeft = 0, quietDuration = 4, cartDuration = 4;
  int cartTrips = 0, closingBonus = 0;
  bool carryingFish = false;

  void begin(NightRun run,
      {required bool thickClouds, required double afterglowSeconds}) {
    clock = noise = alarm = 0;
    _noiseIndex = 0;
    _tripEnds.clear();
    cartTrips = 0;
    quietLeft = 0;
    carryingFish = false;
    quietDuration = 4 + 2.0 * run.count(NightCard.afterHours);
    cartDuration = run.has(NightCard.gentleCart) ? 6 : 4;
    closingBonus = 8 * run.count(NightCard.closingBell);
    afterglow = afterglowSeconds;
    moon.reset(fullMoon: run.has(NightCard.fullMoon), thickClouds: thickClouds);
    lampDuration = (18 + 8 * run.count(NightCard.backupPower)) *
        (1 + .5 * run.count(NightCard.longWick)) /
        (run.has(NightCard.nightWind) ? 2 : 1);
    lightScale = run.lanternLight;
    _mistakeScale = math.pow(.5, run.count(NightCard.quietSteps)).toDouble();
    _trafficScale = math.pow(.7, run.count(NightCard.softWheels)).toDouble() *
        (run.has(NightCard.gentleCart) ? .5 : 1);
    _quietRate = 1.5 + run.count(NightCard.quietCorner);
    final periods = switch (run.variant) {
      NightVariant.marketRush => const [11.0, 17.0, 10.0, 18.0],
      NightVariant.marketConvoy => const [9.0, 9.0, 20.0],
      _ => const [16.0],
    };
    alternateDirections = run.variant == NightVariant.marketConvoy;
    var total = 0.0;
    for (var i = 0; total < run.seconds + 30; i++) {
      total += math.max(
          cartDuration + 2.5,
          periods[i % periods.length] *
              (run.has(NightCard.busyMarket) ? .75 : 1));
      _tripEnds.add(total);
    }
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
    while (cartTrips < _tripEnds.length - 1 && clock >= _tripEnds[cartTrips]) {
      cartTrips++;
    }
    quietLeft =
        cartTrips > 0 ? math.max(0, quietDuration - (clock - _tripStart)) : 0;
    alarm = math.max(0, alarm - dt);
    noise = math.max(0, noise - (_quietRate + (quietLeft > 0 ? 5 : 0)) * dt);
    var passed = 0;
    while (_noiseIndex < _tripEnds.length &&
        clock >= _tripEnds[_noiseIndex] - cartDuration / 2) {
      _noiseIndex++;
      passed++;
    }
    if (passed > 0) {
      noise = (noise + 42 * _trafficScale * passed).clamp(0.0, 100.0);
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

  void onRescue() {
    if (quietLeft > 0) noise = math.max(0, noise - closingBonus);
  }

  bool light(MarketLamp lamp) {
    if (lamp.lit || lamp.cool > 0) return false;
    lamp.burn = lampDuration;
    return true;
  }

  double get _phase => clock - _tripStart;
  bool get cartWarning =>
      _phase >= trafficPeriod - cartDuration - 2 &&
      _phase < trafficPeriod - cartDuration;
  double? get cartProgress => _phase >= trafficPeriod - cartDuration
      ? (_phase - trafficPeriod + cartDuration) / cartDuration
      : null;
  double radius(Size size) => size.height * .2 * lightScale;
  bool lampLit(Offset point, Size size) => lamps.any((lamp) =>
      (lamp.lit || lamp.ember > 0) &&
      (point - lamp.center(size)).distance <=
          radius(size) * .85 * (lamp.lit ? 1 : .75));
  bool isLit(Offset point, Size size) =>
      moon.contains(point, size) || lampLit(point, size);
}
