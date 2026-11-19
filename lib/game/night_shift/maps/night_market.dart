import 'dart:math' as math;
import 'package:flutter/painting.dart';
import '../moonlight.dart';
import '../night_cards.dart';
import '../night_run.dart';
import '../night_variants.dart';

/// Traffic and mistakes build noise; a loud burst scares the cats. The player
/// flags each cart down before it passes so it rolls by quietly.
class NightMarket {
  final moon = Moonlight();
  double clock = 0, noise = 0, alarm = 0;

  /// Seconds of warning before a cart; signs card adds more.
  double warnSeconds = 2;

  /// Trip index already flagged, and whether it was flagged before it came.
  int _hushedTrip = -1;
  bool _hushedEarly = false;
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
    warnSeconds = 2 + 1.5 * run.count(NightCard.backupPower);
    cartDuration = run.has(NightCard.gentleCart) ? 6 : 4;
    closingBonus = 8 * run.count(NightCard.closingBell);
    // Embers relic: the hush after a cart lingers.
    quietDuration += afterglowSeconds / 2;
    _hushedTrip = -1;
    moon.reset(fullMoon: run.has(NightCard.fullMoon), thickClouds: thickClouds);
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
    for (var i = _noiseIndex - passed; i < _noiseIndex; i++) {
      // A flagged cart rolls by softly; flagged before it came, silently.
      final hush = i == _hushedTrip ? (_hushedEarly ? 0.0 : .35) : 1.0;
      noise = (noise + 42 * _trafficScale * hush).clamp(0.0, 100.0);
    }
    if (!alreadyLoud && noise < 100) return false;
    noise = 25;
    alarm = 2.5;
    return true;
  }

  void onRescue() {
    if (quietLeft > 0) noise = math.max(0, noise - closingBonus);
  }

  /// The cart about to pass (or passing) can still be flagged down.
  bool get canHush =>
      (cartWarning || cartProgress != null) &&
      _hushedTrip != cartTrips &&
      _noiseIndex == cartTrips;

  /// Whether the current cart has been flagged down.
  bool get hushed => _hushedTrip == cartTrips;

  /// Flags the coming cart; returns false when there is nothing to flag.
  bool hush() {
    if (!canHush) return false;
    _hushedTrip = cartTrips;
    _hushedEarly = cartProgress == null;
    return true;
  }

  double get _phase => clock - _tripStart;
  bool get cartWarning =>
      _phase >= trafficPeriod - cartDuration - warnSeconds &&
      _phase < trafficPeriod - cartDuration;
  double? get cartProgress => _phase >= trafficPeriod - cartDuration
      ? (_phase - trafficPeriod + cartDuration) / cartDuration
      : null;
  bool isLit(Offset point, Size size) => moon.contains(point, size);
}
