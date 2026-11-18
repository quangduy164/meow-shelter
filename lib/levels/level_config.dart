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
    this.dishes = false,
    this.toys = false,
    this.flood = 0,
    this.bossParade = false,
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

  /// Kitchen chapter: the tray offers three dishes and Scottish cats only
  /// eat the one in their thought bubble.
  final bool dishes;

  /// Playroom chapter: the tray adds a ball of yarn. It rolls when dropped;
  /// Calico plays with it, but any other cat nearby bats it away.
  final bool toys;

  /// Storm chapter: highest the flood water rises (fraction of the field
  /// from the top); 0 means no flood. Lower beds can go under.
  final double flood;

  /// Finale: every cat is a boss, one after another.
  final bool bossParade;

  /// Up to two missions; winning is the first star, each goal one more.
  final List<LevelGoal> goals;

  bool get isBoss => bossType != null;
  int get shelterCount => catTypes.toSet().length;

  String get mission => isInfinite
      ? 'Trụ qua càng nhiều đêm'
      : 'Cứu ${catTypes.length} mèo vào $shelterCount ổ';

  /// Short toast lines about this level's twist, shown when it starts.
  List<String> get twistLines => [
        if (map != null) '${map!.name}: ${map!.rule}',
        if (bossType != null)
          'Trùm: ${CatCatchRule.bossHint(bossType!, dishes: dishes, bushes: map?.bushes.isNotEmpty == true, toys: toys, moon: map?.moonbeams.isNotEmpty == true, yard: map?.rack != null)}',
        if (dishes) 'Kéo đúng món Scottish đang nghĩ trong bong bóng',
        if (toys)
          'Thả cuộn len cho Tam thể chơi; mèo khác ở gần cũng chạy theo',
        if (flood > 0)
          'Nước dâng! Xe cứu hộ đỗ một lúc: thả mèo nào lên xe cũng được',
        if (bossParade) 'Cả nhà trùm kéo đến, từng con một',
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
}
