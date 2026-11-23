import 'package:flutter/painting.dart';

/// Sea Cave shrine: three legendary fish light its three braziers.
class FishingShrine {
  static const center = Offset(8100, 960);
  static const radius = 105.0;
  static const mooring = Offset(8100, 1120);
  static const requiredFish = 3;
  static bool hit(Offset p) => Rect.fromCenter(
          center: center - const Offset(0, 45), width: 270, height: 250)
      .contains(p);
}
