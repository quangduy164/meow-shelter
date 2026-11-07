import 'dart:math';

import 'package:flutter/painting.dart';

/// Which roadside decoration set a stretch paints.
enum ReturnHomeScenery {
  fence,
  garden,
  stream,
  bamboo,
  field,
  bridge,
  village,
  lane,
}

/// One stretch of the road. Each stretch has its own palette and scenery and,
/// more importantly, its own way to play: which hazards appear, how often
/// rocks and birds arrive, how wide the lane is and whether wind pushes the cat.
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
    required this.scenery,
    this.spikes = 0,
    this.logs = 0,
    this.springs = 0,
    this.rockRate = 0,
    this.rockSpeed = 1,
    this.birdRate = 0,
    this.wind = 0,
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

  /// Share of seeded hazards per kind; whatever is left becomes a rolling rock.
  /// A stretch with no seeded hazards at all is a calm rest stop.
  final double spikes;
  final double logs;
  final double springs;

  /// Timed pressure: 0 disables, 1 is the base spawner rate.
  final double rockRate;
  final double rockSpeed;
  final double birdRate;

  /// Peak vertical push in px/s from gusts on exposed stretches.
  final double wind;

  bool get calm => spikes + logs + springs == 0 && rockRate == 0;

  static const all = <ReturnHomeBiome>[
    // 1. Learn the basics: spikes and slow rocks on a wide dirt road.
    ReturnHomeBiome(
      name: 'Đường đất',
      from: 0,
      sky: Color(0xFF75C8DF),
      grass: Color(0xFF93C16C),
      road: Color(0xFFD5B47D),
      roadLight: Color(0xFFE8D09E),
      edge: Color(0x667C9A63),
      halfWidth: .20,
      spikes: .70,
      rockRate: .6,
      rockSpeed: .75,
      scenery: ReturnHomeScenery.fence,
    ),
    // 2. A narrower garden path full of logs: steering, not dodging.
    ReturnHomeBiome(
      name: 'Vườn sau',
      from: .125,
      sky: Color(0xFF8CCFE0),
      grass: Color(0xFF79B85C),
      road: Color(0xFFC9A876),
      roadLight: Color(0xFFE0C694),
      edge: Color(0x666E8F52),
      halfWidth: .16,
      spikes: .20,
      logs: .65,
      rockRate: .35,
      scenery: ReturnHomeScenery.garden,
    ),
    // 3. Stepping stones over the stream; little else to distract.
    ReturnHomeBiome(
      name: 'Bờ suối',
      from: .25,
      sky: Color(0xFF9BC7D8),
      grass: Color(0xFF6FA88C),
      road: Color(0xFF9FB59A),
      roadLight: Color(0xFFBCCDB4),
      edge: Color(0x664F8290),
      halfWidth: .16,
      spikes: .35,
      rockRate: .3,
      scenery: ReturnHomeScenery.stream,
    ),
    // 4. Hidden springs everywhere under the bamboo.
    ReturnHomeBiome(
      name: 'Rừng tre',
      from: .375,
      sky: Color(0xFF9FD3C6),
      grass: Color(0xFF5E9A55),
      road: Color(0xFFB69A6A),
      roadLight: Color(0xFFCDB487),
      edge: Color(0x66406F3A),
      halfWidth: .17,
      spikes: .15,
      logs: .15,
      springs: .55,
      rockRate: .4,
      scenery: ReturnHomeScenery.bamboo,
    ),
    // 5. Wide open field: birds dive constantly, nothing sits on the road.
    ReturnHomeBiome(
      name: 'Cánh đồng',
      from: .50,
      sky: Color(0xFF86CDEB),
      grass: Color(0xFFC6C565),
      road: Color(0xFFD9BE7E),
      roadLight: Color(0xFFEAD4A0),
      edge: Color(0x66A08A3E),
      halfWidth: .22,
      spikes: .15,
      rockRate: .3,
      birdRate: 3,
      scenery: ReturnHomeScenery.field,
    ),
    // 6. Narrow bridge with gusts pushing the cat toward the rails.
    ReturnHomeBiome(
      name: 'Cầu gỗ',
      from: .625,
      sky: Color(0xFFA8D4E6),
      grass: Color(0xFF6FA88C),
      road: Color(0xFFA9774B),
      roadLight: Color(0xFFC18D5E),
      edge: Color(0xFF6E4A2E),
      halfWidth: .13,
      spikes: .30,
      rockRate: .45,
      wind: 85,
      scenery: ReturnHomeScenery.bridge,
    ),
    // 7. Brick village street: fast, frequent rolling rocks.
    ReturnHomeBiome(
      name: 'Làng nhỏ',
      from: .75,
      sky: Color(0xFFB6C6D2),
      grass: Color(0xFF87A06B),
      road: Color(0xFFB0705A),
      roadLight: Color(0xFFC98A72),
      edge: Color(0x66704A3A),
      dash: Color(0x55FFE6CF),
      halfWidth: .18,
      spikes: .25,
      logs: .10,
      rockRate: 2.2,
      rockSpeed: 1.35,
      scenery: ReturnHomeScenery.village,
    ),
    // 8. The calm lane home: no hazards, just the walk to the door.
    ReturnHomeBiome(
      name: 'Ngõ về nhà',
      from: .875,
      sky: Color(0xFFF2C79A),
      grass: Color(0xFF8CB86A),
      road: Color(0xFFDCC9A3),
      roadLight: Color(0xFFEBDDBE),
      edge: Color(0x667E8B5E),
      halfWidth: .18,
      scenery: ReturnHomeScenery.lane,
    ),
  ];
}

/// The winding lane, and the single source of truth for "where is the road at
/// world x". Hazards, the cat's clamp, the rolling rocks and the scenery all
/// read it, so the curve can be retuned in one place.
class ReturnHomeRoad {
  ReturnHomeRoad({
    this.worldMultiplier = 8,
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

  /// Lane half-height at x. Stretches have different widths, so the width
  /// eases from one to the next over [borderBlend] on each side of a border;
  /// a hard step made the lane edge jump and shoved a cat standing on the
  /// border up or down.
  double halfWidth(double x) =>
      _viewportHeight * _blended(x, (biome) => biome.halfWidth);

  /// Wind strength at x, eased in and out at stretch borders the same way.
  double windAt(double x) => _blended(x, (biome) => biome.wind);

  /// Half-length of the smooth hand-over between two stretches, in world px.
  static const double borderBlend = 70;

  double _blended(double x, double Function(ReturnHomeBiome biome) pick) {
    for (var i = 1; i < biomes.length; i++) {
      final d = x - biomes[i].from * _worldWidth;
      if (d.abs() >= borderBlend) continue;
      final t = (d + borderBlend) / (2 * borderBlend);
      final s = t * t * (3 - 2 * t);
      return pick(biomes[i - 1]) + (pick(biomes[i]) - pick(biomes[i - 1])) * s;
    }
    return pick(biomeAt(x));
  }

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
