import 'dart:math' as math;
import 'package:flutter/painting.dart';
import '../moonlight.dart';

/// One lantern on the night yard. Tap to light it; it burns for a while,
/// then needs a short rest before it can be lit again.
class YardLantern {
  YardLantern(this.spot);

  /// Foot of the post, as fractions of the field.
  final Offset spot;
  double burn = 0, cool = 0, burnTotal = 1, ember = 0;
  bool chimed = false;
  bool get lit => burn > 0;
  bool get ready => burn <= 0 && cool <= 0;

  /// Lamp centre in pixels; the light pool is centred here.
  Offset lamp(Size size) =>
      Offset(spot.dx * size.width, spot.dy * size.height - 40);
}

/// State of the moonlit backyard: lanterns, the drifting moonlight patch and
/// the clouds that hide it. Cats in the light are calm and wait longer.
class MoonEcho {
  MoonEcho(this.point, this.left);
  final Offset point;
  double left;
}

class MoonlitYard {
  /// Post spots in the order extra lanterns are added.
  static const spots = [
    Offset(.50, .40),
    Offset(.27, .36),
    Offset(.73, .36),
    Offset(.31, .66),
    Offset(.69, .66),
  ];
  static const restTime = 5.0;

  final lanterns = <YardLantern>[];
  double burnTime = 10, lightScale = 1, emberDuration = 0;
  bool fullMoon = false, thickClouds = false;
  final moon = Moonlight();
  final echoes = <MoonEcho>[];
  double echoDuration = 0, linkSeconds = 0, _echoClock = 0;

  void setup(
      {required int count,
      required double burnTime,
      required double lightScale,
      required bool fullMoon,
      required bool thickClouds,
      double emberDuration = 0,
      double echoDuration = 0,
      double linkSeconds = 0}) {
    this.echoDuration = echoDuration;
    this.linkSeconds = linkSeconds;
    echoes.clear();
    _echoClock = 0;
    this.emberDuration = emberDuration;
    this.burnTime = burnTime;
    this.lightScale = lightScale;
    this.fullMoon = fullMoon;
    this.thickClouds = thickClouds;
    moon.reset(fullMoon: fullMoon, thickClouds: thickClouds);
    lanterns
      ..clear()
      ..addAll([for (final spot in spots.take(count)) YardLantern(spot)]);
  }

  bool light(YardLantern lantern) {
    if (!lantern.ready) return false;
    lantern
      ..burn = burnTime
      ..burnTotal = burnTime;
    if (linkSeconds > 0) {
      final neighbors = lanterns
          .where((other) => other != lantern && other.lit)
          .toList()
        ..sort((a, b) => (a.spot - lantern.spot)
            .distance
            .compareTo((b.spot - lantern.spot).distance));
      if (neighbors.isNotEmpty) {
        final other = neighbors.first;
        other.burn = math.min(other.burn + linkSeconds, burnTime * 2);
        other.burnTotal = math.max(other.burnTotal, other.burn);
      }
    }
    return true;
  }

  bool get cloudy => moon.cloudy;
  double get moonShown => moon.shown;

  void update(double dt) {
    moon.update(dt);
    for (final echo in echoes) {
      echo.left -= dt;
    }
    echoes.removeWhere((echo) => echo.left <= 0);
    if (echoDuration > 0) {
      _echoClock += dt;
      if (_echoClock >= .5 && moon.shown > .25) {
        _echoClock %= .5;
        echoes.add(MoonEcho(moon.center(const Size(1, 1)), echoDuration));
        if (echoes.length > 12) echoes.removeAt(0);
      }
    }
    for (final lantern in lanterns) {
      if (lantern.burn > 0) {
        lantern.burn -= dt;
        if (lantern.burn <= 0) {
          lantern.cool = restTime;
          lantern.ember = emberDuration;
        }
      } else if (lantern.cool > 0) {
        lantern.cool -= dt;
      }
      if (!lantern.lit && lantern.ember > 0) {
        lantern.ember = math.max(0, lantern.ember - dt);
      }
    }
  }

  Offset moonSource(Size size) => moon.source(size);
  Offset moonFoot(Size size) => moon.foot(size);
  Offset moonCenter(Size size) => moon.center(size);
  Path moonBeam(Size size) => moon.beam(size);

  double lanternRadius(Size size) => size.height * .22 * lightScale;

  /// Whether [point] is inside lantern or moon light.
  bool isLit(Offset point, Size size) {
    return isMoonLit(point, size) || isLanternLit(point, size);
  }

  bool isMoonLit(Offset point, Size size) =>
      moon.contains(point, size) ||
      echoes.any((echo) {
        final delta =
            Offset(point.dx / size.width, point.dy / size.height) - echo.point;
        return math.pow(delta.dx / .065, 2) + math.pow(delta.dy / .08, 2) <= 1;
      });

  bool isLanternLit(Offset point, Size size) => lanterns.any((l) =>
      (l.lit || l.ember > 0) &&
      (point - l.lamp(size)).distance <=
          lanternRadius(size) * .85 * (l.lit ? 1 : .75));

  /// Light pools punched into the darkness layer.
  Iterable<(Offset, double)> lights(Size size) sync* {
    for (final lantern in lanterns) {
      if (lantern.ember > 0 && !lantern.lit) {
        yield (lantern.lamp(size), lanternRadius(size) * .75);
      }
      if (lantern.lit) {
        // Dims a little in the last two seconds as a warning.
        final fade = (lantern.burn / 2).clamp(.6, 1.0);
        yield (lantern.lamp(size), lanternRadius(size) * fade);
      }
    }
  }
}
