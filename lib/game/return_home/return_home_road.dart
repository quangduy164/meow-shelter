import 'dart:math';

import 'package:flutter/painting.dart';

/// Which roadside decoration set a stretch paints.
enum ReturnHomeScenery { fence, garden, stream, street }

/// One stretch of the road: its own palette, lane width, hazard mix and scenery,
/// so the run reads as a journey through places instead of one long corridor.
///
/// Add a biome by appending an entry to [all] (or passing a custom list to
/// [ReturnHomeRoad]) and giving it a [ReturnHomeScenery] painter.
class ReturnHomeBiome {
  const ReturnHomeBiome({
    required this.name,
    required this.from,
    required this.sky,
    required this.grass,
    required this.road,
    required this.roadLight,
    required this.edge,
    required this.halfWidth,
    required this.spikes,
    required this.logs,
    required this.scenery,
    this.dash,
  });

  final String name;

  /// World fraction where this stretch begins.
  final double from;
  final ReturnHomeScenery scenery;
  final Color sky;
  final Color grass;
  final Color road;
  final Color roadLight;
  final Color edge;
  final Color? dash;

  /// Half of the walkable lane height, as a fraction of the viewport height.
  final double halfWidth;
  final double spikes;
  final double logs;

  double get rocks => 1 - spikes - logs;

  static const all = <ReturnHomeBiome>[
    ReturnHomeBiome(
      name: 'Đường đất',
      from: 0,
      sky: Color(0xFF75C8DF),
      grass: Color(0xFF93C16C),
      road: Color(0xFFD5B47D),
      roadLight: Color(0xFFE8D09E),
      edge: Color(0x667C9A63),
      halfWidth: .20,
      spikes: .55,
      logs: .10,
      scenery: ReturnHomeScenery.fence,
    ),
    ReturnHomeBiome(
      name: 'Vườn sau',
      from: .26,
      sky: Color(0xFF8CCFE0),
      grass: Color(0xFF79B85C),
      road: Color(0xFFC9A876),
      roadLight: Color(0xFFE0C694),
      edge: Color(0x666E8F52),
      halfWidth: .18,
      spikes: .30,
      logs: .35,
      scenery: ReturnHomeScenery.garden,
    ),
    ReturnHomeBiome(
      name: 'Bờ suối',
      from: .54,
      sky: Color(0xFF9BC7D8),
      grass: Color(0xFF6FA88C),
      road: Color(0xFFC2B28E),
      roadLight: Color(0xFFDACEB4),
      edge: Color(0x664F8290),
      halfWidth: .16,
      spikes: .30,
      logs: .05,
      scenery: ReturnHomeScenery.stream,
    ),
    ReturnHomeBiome(
      name: 'Ngoại ô',
      from: .78,
      sky: Color(0xFFB6C6D2),
      grass: Color(0xFF87A06B),
      road: Color(0xFF8C8F93),
      roadLight: Color(0xFF9FA3A7),
      edge: Color(0x665C6066),
      dash: Color(0x8CFFF0C2),
      halfWidth: .17,
      spikes: .15,
      logs: .10,
      scenery: ReturnHomeScenery.street,
    ),
  ];
}

/// The winding lane, and the single source of truth for "where is the road at
/// world x". Hazards, the cat's clamp, the rolling rocks and the scenery all
/// read it, so the curve can be retuned in one place.
class ReturnHomeRoad {
  ReturnHomeRoad({
    this.worldMultiplier = 3,
    this.curveAmplitude = .075,
    this.curveHarmonic = 2.6,
    this.sweepAmplitude = .028,
    this.sweepHarmonic = 1.3,
    this.sweepPhase = 1.1,
    List<ReturnHomeBiome>? biomes,
  }) : biomes = biomes ?? ReturnHomeBiome.all;

  /// Stretches of the run, ordered by [ReturnHomeBiome.from].
  final List<ReturnHomeBiome> biomes;

  /// Length of the run in viewport widths.
  final double worldMultiplier;

  /// Primary wander of the ribbon, as a fraction of the viewport height.
  final double curveAmplitude;
  final double curveHarmonic;

  /// Slower second harmonic that keeps the curve from reading as a sine wave.
  final double sweepAmplitude;
  final double sweepHarmonic;
  final double sweepPhase;

  double _viewportHeight = 1;
  double _worldWidth = 1;

  /// Called on load and on every viewport resize; the road is rebuilt in place
  /// so components never see a stale geometry object.
  void resize(double viewportWidth, double viewportHeight) {
    _viewportHeight = viewportHeight;
    _worldWidth = max(1.0, viewportWidth * worldMultiplier);
  }

  double get worldWidth => _worldWidth;
  double get viewportHeight => _viewportHeight;

  double fraction(double x) => (x / _worldWidth).clamp(0.0, 1.0);

  ReturnHomeBiome biomeAtFraction(double f) {
    var match = biomes.first;
    for (final biome in biomes) {
      if (f >= biome.from) match = biome;
    }
    return match;
  }

  ReturnHomeBiome biomeAt(double x) => biomeAtFraction(fraction(x));

  /// Vertical center of the lane at world x.
  double centerY(double x) {
    final t = fraction(x);
    return _viewportHeight *
        (.5 +
            sin(t * pi * curveHarmonic) * curveAmplitude +
            sin(t * pi * sweepHarmonic + sweepPhase) * sweepAmplitude);
  }

  double halfWidth(double x) => _viewportHeight * biomeAt(x).halfWidth;

  double topEdge(double x) => centerY(x) - halfWidth(x);

  double bottomEdge(double x) => centerY(x) + halfWidth(x);

  /// Point on the lane boundary; `side` is -1 for the top edge, 1 for the bottom.
  Offset edgePoint(double x, double side) =>
      Offset(x, centerY(x) + side * halfWidth(x));

  /// The cat's sprite is clamped between these x positions, and the run is
  /// measured from start to end so reaching the house is exactly 100%.
  static const double startX = 72;
  static const double endMargin = 104;
  double get endX => _worldWidth - endMargin;
}
