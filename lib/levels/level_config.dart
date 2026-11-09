import '../game/cats/cat_catch_rule.dart';
import '../game/cats/cat_skill.dart';
import 'level_goal.dart';
import '../game/world/shelter_map.dart';

class LevelConfig {
  const LevelConfig({
    required this.id,
    required this.catTypes,
    required this.timeLimit,
    required this.name,
    this.isTutorial = false,
    this.speedMultiplier = 1,
    this.readySeconds = 3,
    this.gripSeconds = 4,
    this.allowRun = true,
    this.skillTier = 0,
    this.isInfinite = false,
    this.fishLimit = 0,
    this.waveSize = 0,
    this.movingBeds = false,
    this.darkness = false,
    this.bossType,
    this.goals = const [],
    this.map,
  });

  /// Field layout with its own rule; null keeps the open lawn.
  final ShelterMap? map;

  final int id;
  final String name;
  final List<String> catTypes;
  final int timeLimit;
  final bool isTutorial, allowRun;
  final bool isInfinite;
  final double speedMultiplier, readySeconds, gripSeconds;
  final int skillTier;

  // Twists: each gives a level its own way to play.
  /// Bait for the whole round; 0 means unlimited.
  final int fishLimit;

  /// Cats on the field at once; the rest arrive as others are rescued.
  /// 0 means everybody starts on the field.
  final int waveSize;

  /// Beds swap places every few seconds.
  final bool movingBeds;

  /// Lights off: only fish, beds and ready cats are lit.
  final bool darkness;

  /// The first cat of this breed is a big boss with a harder catch rule.
  final String? bossType;

  /// Up to two missions; winning is the first star, each goal one more.
  final List<LevelGoal> goals;

  bool get isBoss => bossType != null;
  int get shelterCount => catTypes.toSet().length;

  String get mission => isInfinite
      ? 'Cứu càng nhiều mèo'
      : 'Cứu ${catTypes.length} mèo vào $shelterCount ổ';

  /// Short line under the level name in the level list.
  String get tag {
    if (isTutorial) return 'Màn tập';
    final cats = '${catTypes.length} mèo';
    if (isBoss) return 'Màn trùm · $cats';
    final twists = [
      if (map != null) map!.name,
      if (fishLimit > 0) 'Chỉ $fishLimit cá',
      if (waveSize > 0) 'Từng đợt',
      if (movingBeds) 'Ổ dời chỗ',
      if (darkness) 'Tắt đèn',
    ];
    return twists.isEmpty
        ? '$cats · ${timeLimit}s'
        : '${twists.join(' · ')} · $cats';
  }

  /// Short toast lines about this level's twist, shown when it starts.
  List<String> get twistLines => [
        if (map != null) '${map!.name}: ${map!.rule}',
        if (bossType != null) 'Trùm: ${CatCatchRule.bossHint(bossType!)}',
        if (fishLimit > 0) 'Chỉ có $fishLimit cá mồi',
        if (waveSize > 0) 'Mèo đến từng đợt',
        if (movingBeds) 'Các ổ sẽ dời chỗ',
        if (darkness) 'Tắt đèn! Thả cá để soi đường',
      ];

  CatSkill skillFor(String type) => switch (type) {
        'orange' when skillTier >= 1 => CatSkill.sprint,
        'himalaya' when skillTier >= 2 => CatSkill.feint,
        'scottish' when skillTier >= 2 => CatSkill.zigzag,
        'calico' when skillTier >= 3 => CatSkill.slippery,
        'black' when skillTier >= 3 => CatSkill.vanish,
        _ => CatSkill.none,
      };

  LevelConfig forInfiniteProgress(int rescued) {
    final wave = rescued ~/ 5;
    return LevelConfig(
      id: id,
      name: name,
      catTypes: catTypes,
      timeLimit: timeLimit,
      isTutorial: isTutorial,
      speedMultiplier: (speedMultiplier + wave * .10).clamp(.8, 1.6),
      readySeconds: (readySeconds - wave * .18).clamp(1.4, readySeconds),
      gripSeconds: (gripSeconds - wave * .12).clamp(2.2, gripSeconds),
      allowRun: allowRun,
      skillTier: (skillTier + wave).clamp(0, 3),
      isInfinite: isInfinite,
    );
  }
}
