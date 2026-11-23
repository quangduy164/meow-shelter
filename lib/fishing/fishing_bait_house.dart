import 'package:flutter/painting.dart';
import 'fishing_river.dart';

class FishingBaitHouse {
  static const x = 4600.0;
  static Offset get center => Offset(x, FishingRiver.top(x) + 90);
  static const radius = 70.0;
  static Offset get mooring => center + const Offset(0, 145);
  static bool hit(Offset p) => Rect.fromCenter(
          center: center - const Offset(0, 50), width: 220, height: 250)
      .contains(p);
}
