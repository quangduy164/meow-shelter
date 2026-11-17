/// Special cats with a personality. Each map gives one per cluster.
enum HerdTrait { normal, chubby, curious, sleepy, golden, shy, sulky }

abstract final class HerdTraits {
  /// Bé Mập: slower, slows the leader, weighs two on thin ice and heats up
  /// faster in the desert sun.
  static const chubbySpeed = 105.0, chubbyLeaderFactor = .9;
  static const chubbyIceWeight = 2, chubbyHeat = 1.3, chubbyScale = 1.22;

  /// Bé Tò Mò: after a while in the herd it runs off after a butterfly.
  static const itchMin = 6.0, itchSpread = 5.0, warnBefore = 1.4;
  static const wanderSeconds = 1.8, wanderDistance = 75.0, wanderSpeed = 95.0;

  /// Bé Ngủ Say: the leader must stay beside it this long to wake it.
  static const wakeSeconds = 1.0, dozeRate = .5;

  /// Bé Vàng: extra points when it reaches home.
  static const goldenBonus = 30;

  static String name(HerdTrait trait) => switch (trait) {
        HerdTrait.chubby => 'Bé Mập',
        HerdTrait.curious => 'Bé Tò Mò',
        HerdTrait.sleepy => 'Bé Ngủ Say',
        HerdTrait.golden => 'Bé Vàng',
        HerdTrait.shy => 'Bé Nhát Gan',
        HerdTrait.sulky => 'Bé Hay Dỗi',
        HerdTrait.normal => '',
      };
}
