import 'package:flutter/painting.dart';

/// Sea Cave shrine: three legendary fish light its three statues.
class FishingShrine {
  static const center = Offset(8100, 700);
  // The island carries three big statues, so it is about 420 wide.
  static const radius = 165.0;
  static const waterDepth = 100.0;
  static const mooring = Offset(8100, 700 + waterDepth + 55);
  static const requiredFish = 3;
  static bool hit(Offset p) => Rect.fromLTRB(
          center.dx - 215, center.dy - 300, center.dx + 215, center.dy + 80)
      .contains(p);
}
