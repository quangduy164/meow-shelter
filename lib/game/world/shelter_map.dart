import 'dart:ui';

enum ShelterMapKind { garden, warehouse, pond }

/// One infinite-mode map. Rects are normalized to the screen (0..1).
class ShelterMap {
  const ShelterMap({
    required this.kind,
    required this.name,
    required this.rule,
    this.obstacles = const [],
    this.gate,
    this.altObstacles = const [],
    this.mud = const [],
  });

  final ShelterMapKind kind;
  final String name;

  /// Short line explaining this map's own rule.
  final String rule;
  final List<Rect> obstacles;

  /// Garden gate: blocks while closed, see [gateClosed].
  final Rect? gate;

  /// Warehouse crates swap between [obstacles] and these.
  final List<Rect> altObstacles;

  /// Shallow mud that slows cats down.
  final List<Rect> mud;

  static const gatePeriod = 10.0, cratePeriod = 8.0, mudSpeed = .5;

  static const none =
      ShelterMap(kind: ShelterMapKind.garden, name: '', rule: '');

  bool gateClosed(double t) => gate != null && t % gatePeriod < gatePeriod / 2;
  bool cratesSwapped(double t) =>
      altObstacles.isNotEmpty && (t ~/ cratePeriod).isOdd;

  /// Seconds until the gate or crates change, for warnings.
  double untilChange(double t) => gate != null
      ? gatePeriod / 2 - t % (gatePeriod / 2)
      : cratePeriod - t % cratePeriod;

  List<Rect> blockersAt(double t) => [
        ...(cratesSwapped(t) ? altObstacles : obstacles),
        if (gateClosed(t)) gate!,
      ];

  static const garden = ShelterMap(
    kind: ShelterMapKind.garden,
    name: 'Vườn hoa',
    rule: 'Cổng giữa vườn đóng mở liên tục',
    obstacles: [
      Rect.fromLTWH(.25, .30, .12, .11),
      Rect.fromLTWH(.63, .30, .12, .11),
      Rect.fromLTWH(.23, .345, .17, .035),
      Rect.fromLTWH(.60, .345, .17, .035),
    ],
    gate: Rect.fromLTWH(.40, .345, .20, .035),
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
