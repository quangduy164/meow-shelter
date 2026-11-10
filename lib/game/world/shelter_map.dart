import 'dart:ui';

enum ShelterMapKind { garden, warehouse, pond }

/// One infinite-mode map. Rects are normalized to the screen (0..1).
class ShelterMap {
  const ShelterMap({
    required this.kind,
    required this.name,
    required this.rule,
    this.obstacles = const [],
    this.sprinkler,
    this.altObstacles = const [],
    this.mud = const [],
  });

  final ShelterMapKind kind;
  final String name;

  /// Short line explaining this map's own rule.
  final String rule;
  final List<Rect> obstacles;

  /// Water spray area; active for three seconds in each ten-second cycle.
  final Rect? sprinkler;

  /// Warehouse crates swap between [obstacles] and these.
  final List<Rect> altObstacles;

  /// Shallow mud that slows cats down.
  final List<Rect> mud;

  static const sprinklerPeriod = 10.0, cratePeriod = 8.0, mudSpeed = .5;

  static const none =
      ShelterMap(kind: ShelterMapKind.garden, name: '', rule: '');

  bool spraying(double t) => sprinkler != null && t % sprinklerPeriod >= 7;
  bool cratesSwapped(double t) =>
      altObstacles.isNotEmpty && (t ~/ cratePeriod).isOdd;

  /// Seconds until the gate or crates change, for warnings.
  double untilChange(double t) => sprinkler != null
      ? (spraying(t) ? sprinklerPeriod : 7) - t % sprinklerPeriod
      : cratePeriod - t % cratePeriod;

  List<Rect> blockersAt(double t) => [
        ...(cratesSwapped(t) ? altObstacles : obstacles),
        if (spraying(t)) sprinkler!,
      ];

  static const garden = ShelterMap(
    kind: ShelterMapKind.garden,
    name: 'Vườn hoa',
    rule: 'Vòi tưới báo trước rồi phun nước, mèo sẽ né nước',
    obstacles: [
      Rect.fromLTWH(.25, .30, .12, .11),
      Rect.fromLTWH(.63, .30, .12, .11),
    ],
    sprinkler: Rect.fromLTWH(.43, .32, .14, .17),
  );

  static const warehouse = ShelterMap(
    kind: ShelterMapKind.warehouse,
    name: 'Kho đồ',
    rule: 'Thùng hàng đổi chỗ sau vài giây',
    obstacles: [
      Rect.fromLTWH(.27, .28, .11, .10),
      Rect.fromLTWH(.60, .42, .11, .10),
    ],
    altObstacles: [
      Rect.fromLTWH(.27, .42, .11, .10),
      Rect.fromLTWH(.60, .28, .11, .10),
    ],
  );

  static const pond = ShelterMap(
    kind: ShelterMapKind.pond,
    name: 'Hồ sen',
    rule: 'Bùn ven hồ làm mèo đi chậm',
    obstacles: [Rect.fromLTWH(.41, .32, .18, .14)],
    mud: [Rect.fromLTWH(.32, .25, .36, .29)],
  );

  static const maps = <ShelterMap>[garden, warehouse, pond];
}
