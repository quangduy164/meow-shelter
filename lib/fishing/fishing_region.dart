import '../collection/fish_species.dart';
import 'fishing_river.dart';

/// Land style used by scenery and the minimap.
enum FishingLand { village, bamboo, mangrove, beach, rocky }

/// One row per area of the fishing world. Names, x ranges, fish pools and
/// scenery style live here so a new area is added in one place.
///
/// The cave is an optional inlet inside the rocky bay: it has no x range of
/// its own and is detected by [FishingRiver.caveBlend].
enum FishingRegion {
  village('Làng', 0, FishingRiver.sectionLength, FishingLand.village, {
    FishSpecies.perch: 32.0,
    FishSpecies.tilapia: 32.0,
    FishSpecies.carp: 28.0,
    FishSpecies.goldfish: 3.0,
    FishSpecies.flipFlop: 3.0,
    FishSpecies.tinCan: 2.0,
  }),
  bamboo('Sông tre', FishingRiver.sectionLength, FishingRiver.mangroveStart,
      FishingLand.bamboo, {
    FishSpecies.catfish: 49.0,
    FishSpecies.koi: 43.0,
    FishSpecies.catMew: 1.0,
    FishSpecies.oldBoot: 4.0,
    FishSpecies.tinCan: 3.0,
  }),
  mangrove('Rừng ngập mặn', FishingRiver.mangroveStart, FishingRiver.seaStart,
      FishingLand.mangrove, {
    FishSpecies.goby: 45.0,
    FishSpecies.mudskipper: 22.0,
    FishSpecies.tilapia: 15.0,
    FishSpecies.catfish: 12.0,
    FishSpecies.pufferfish: 3.0,
    FishSpecies.tinCan: 3.0,
  }),
  coast('Cửa biển', FishingRiver.seaStart, FishingRiver.rockyBayStart,
      FishingLand.beach, _seaFish),
  rockyBay('Vịnh đá', FishingRiver.rockyBayStart, FishingRiver.openSeaStart,
      FishingLand.rocky, {
    FishSpecies.grouper: 40.0,
    FishSpecies.butterflyfish: 15.0,
    FishSpecies.sardine: 28.0,
    FishSpecies.mackerel: 12.0,
    FishSpecies.pufferfish: 3.0,
    FishSpecies.tinCan: 2.0,
  }),
  openSea('Biển rộng', FishingRiver.openSeaStart, FishingRiver.length,
      FishingLand.beach, _seaFish),
  cave('Hang biển', FishingRiver.rockyBayStart, FishingRiver.openSeaStart,
      FishingLand.rocky, {
    FishSpecies.cavefish: 52.0,
    FishSpecies.lanternfish: 4.0,
    FishSpecies.catfish: 24.0,
    FishSpecies.pufferfish: 8.0,
    FishSpecies.mackerel: 9.0,
    FishSpecies.tinCan: 3.0,
  });

  const FishingRegion(this.label, this.start, this.end, this.land, this.fish);
  final String label;
  final double start, end;
  final FishingLand land;

  /// Relative catch weights; neighbouring pools cross-fade at the borders.
  final Map<FishSpecies, double> fish;

  /// Area along the river by x only (never [cave]).
  static FishingRegion alongX(double x) {
    for (final region in values) {
      if (region != cave && x < region.end) return region;
    }
    return openSea;
  }
}

const _seaFish = {
  FishSpecies.sardine: 54.0,
  FishSpecies.mackerel: 29.0,
  FishSpecies.clownfish: 12.0,
  FishSpecies.pufferfish: 3.0,
  FishSpecies.flipFlop: 1.0,
  FishSpecies.tinCan: 1.0,
};
