import 'dart:math' as math;
import 'package:flutter/painting.dart';

/// Moon/cloud timing and a shared shaft of light, independent of the map art.
class Moonlight {
  double _clock = 0, shown = 1;
  bool fullMoon = false, thickClouds = false;

  void reset({required bool fullMoon, required bool thickClouds}) {
    this.fullMoon = fullMoon;
    this.thickClouds = thickClouds;
    _clock = 0;
    shown = 1;
  }

  bool get cloudy {
    if (fullMoon) return false;
    final period = thickClouds ? 12.0 : 16.0;
    final covered = thickClouds ? 7.0 : 5.0;
    return _clock % period >= period - covered;
  }

  void update(double dt) {
    _clock += dt;
    shown += ((cloudy ? 0.0 : 1.0) - shown).clamp(-dt, dt);
  }

  Offset source(Size size) => Offset(size.width * .22, size.height * .07);
  Offset foot(Size size) => Offset(
      size.width * (.18 + .64 * (.5 + .5 * math.sin(_clock * .16))),
      size.height * .8);
  Offset center(Size size) => Offset.lerp(source(size), foot(size), .73)!;

  Path beam(Size size, {double widthScale = 1}) {
    final start = source(size), end = foot(size);
    final halfWidth = size.width * .14 * widthScale;
    return Path()
      ..moveTo(start.dx - 5, start.dy)
      ..lineTo(end.dx - halfWidth, end.dy)
      ..lineTo(end.dx + halfWidth, end.dy)
      ..lineTo(start.dx + 5, start.dy)
      ..close();
  }

  bool contains(Offset point, Size size) =>
      shown > .25 &&
      point.dy >= size.height * .18 &&
      beam(size).contains(point);
}
