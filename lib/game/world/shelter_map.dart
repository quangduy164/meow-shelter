import 'dart:ui';

enum ShelterMapKind { garden, kitchen, hedge, playroom, attic, yard, storm }

/// One chapter map of the rescue mode; [none] is the plain lawn of the
/// practice rounds. Rects are normalized to the screen (0..1).
class ShelterMap {
  const ShelterMap({
    required this.kind,
    required this.name,
    required this.rule,
    this.obstacles = const [],
    this.bushes = const [],
    this.bushRadius = .055,
    this.moonbeams = const [],
    this.moonWindow = Offset.zero,
    this.rack,
    this.napMats = const [],
  });

  final ShelterMapKind kind;
  final String name;

  /// Short line explaining this map's own rule.
  final String rule;
  final List<Rect> obstacles;

  /// Flower bushes Himalaya hides in (centres, radius as a width fraction).
  /// They are walkable; only shy cats use them as cover.
  final List<Offset> bushes;
  final double bushRadius;

  /// Attic: base ellipses of moonlight on the floor (they drift) and the
  /// window they shine from. A map with moonbeams is always dark.
  final List<Rect> moonbeams;
  final Offset moonWindow;

  /// Yard: the drying rack dropping free fish, and the straw mats where the
  /// orange boss agrees to nap.
  final Rect? rack;
  final List<Rect> napMats;

  static const none =
      ShelterMap(kind: ShelterMapKind.garden, name: '', rule: '');

  /// Chapter 3: a kitchen island and a serving trolley block the floor.
  static const kitchen = ShelterMap(
    kind: ShelterMapKind.kitchen,
    name: 'Bếp ăn',
    rule: 'Bàn bếp và xe đẩy món chắn lối đi',
    obstacles: [
      Rect.fromLTWH(.40, .34, .20, .11),
      Rect.fromLTWH(.66, .47, .07, .10),
    ],
  );

  /// Chapter 2: flower bushes where Himalaya cats hide until it is quiet.
  static const hedge = ShelterMap(
    kind: ShelterMapKind.hedge,
    name: 'Vườn hoa',
    rule: 'Himalaya trốn trong bụi hoa, đủ yên tĩnh mới ló ra',
    bushes: [
      Offset(.30, .33),
      Offset(.63, .30),
      Offset(.48, .52),
      Offset(.31, .70),
      Offset(.68, .68),
    ],
  );

  /// Chapter 4: a toy chest and a play tent; yarn bounces off both.
  static const playroom = ShelterMap(
    kind: ShelterMapKind.playroom,
    name: 'Phòng chơi',
    rule: 'Cuộn len lăn khắp phòng, nảy khỏi rương đồ chơi và lều',
    obstacles: [
      Rect.fromLTWH(.40, .32, .17, .11),
      Rect.fromLTWH(.66, .50, .07, .10),
    ],
  );

  /// Chapter 5: a dark attic lit only by drifting pools of moonlight.
  static const attic = ShelterMap(
    kind: ShelterMapKind.attic,
    name: 'Gác xép',
    rule: 'Mèo đen chỉ ra ăn cá đặt trong vệt trăng; mây trôi qua sẽ che trăng',
    obstacles: [
      Rect.fromLTWH(.40, .30, .16, .10),
      Rect.fromLTWH(.82, .36, .07, .10),
    ],
    moonbeams: [
      Rect.fromLTWH(.20, .40, .20, .17),
      Rect.fromLTWH(.52, .62, .20, .17),
      Rect.fromLTWH(.30, .74, .18, .15),
    ],
    moonWindow: Offset(.47, .08),
  );

  /// Chapter 1: a sunny front yard with a fish-drying rack.
  static const yard = ShelterMap(
    kind: ShelterMapKind.yard,
    name: 'Sân trước',
    rule: 'Giàn phơi rung là sắp rơi cá khô miễn phí; mèo cam lao tới ngay',
    obstacles: [Rect.fromLTWH(.40, .27, .20, .05)],
    rack: Rect.fromLTWH(.38, .19, .24, .10),
    napMats: [
      Rect.fromLTWH(.22, .70, .13, .13),
      Rect.fromLTWH(.65, .70, .13, .13),
    ],
  );

  /// Chapter 6: the rescue station on a stormy night; sandbags block.
  static const storm = ShelterMap(
    kind: ShelterMapKind.storm,
    name: 'Trạm cứu hộ',
    rule: 'Đêm mưa bão: nước ngập làm mèo đi chậm, không thả cá xuống nước',
    obstacles: [
      Rect.fromLTWH(.27, .40, .11, .06),
      Rect.fromLTWH(.62, .44, .11, .06),
    ],
  );
}
