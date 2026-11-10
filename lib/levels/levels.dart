import 'level_config.dart';
import 'level_goal.dart';
import '../game/world/shelter_map.dart';

export 'level_goal.dart';

/// A group of levels that introduces one breed and its catch rule, then mixes
/// it with breeds the player already knows.
class LevelChapter {
  const LevelChapter(this.title, this.breed, this.levels);
  final String title;

  /// The breed this chapter teaches; drawn on the chapter header.
  final String breed;
  final List<LevelConfig> levels;
}

// Ids start at 201 so stars saved by the old 18-level layout (ids 1–18,
// judged on time only) never mix with the new mission stars.
// Every chapter: an intro level, a twist level, then a boss.
const levelChapters = <LevelChapter>[
  LevelChapter('Sân trước', 'orange', [
    LevelConfig(
        id: 201,
        name: 'Làm quen',
        catTypes: ['orange'],
        timeLimit: 0,
        isTutorial: true,
        speedMultiplier: .5,
        readySeconds: 8,
        gripSeconds: 8,
        allowRun: false),
    LevelConfig(
        id: 202,
        name: 'Bữa trưa',
        catTypes: ['orange', 'orange', 'orange'],
        timeLimit: 120,
        speedMultiplier: .6,
        readySeconds: 6,
        gripSeconds: 6,
        allowRun: false,
        fishLimit: 4,
        goals: [LevelGoal.fishMax(3), LevelGoal.timeLeft(70)]),
    LevelConfig(
        id: 203,
        name: 'Mèo cam béo',
        catTypes: ['orange', 'orange', 'orange'],
        timeLimit: 120,
        speedMultiplier: .7,
        readySeconds: 5,
        gripSeconds: 5,
        skillTier: 1,
        bossType: 'orange',
        goals: [LevelGoal.noStartle(), LevelGoal.timeLeft(50)]),
  ]),
  LevelChapter('Vườn hoa', 'himalaya', [
    LevelConfig(
        id: 204,
        map: ShelterMap.garden,
        name: 'Mèo rụt rè',
        catTypes: ['himalaya', 'orange', 'orange'],
        timeLimit: 120,
        speedMultiplier: .65,
        readySeconds: 6,
        gripSeconds: 6,
        allowRun: false,
        goals: [LevelGoal.noStartle(), LevelGoal.timeLeft(60)]),
    LevelConfig(
        id: 205,
        map: ShelterMap.garden,
        name: 'Từng mèo một',
        catTypes: ['himalaya', 'orange', 'himalaya', 'orange', 'himalaya'],
        timeLimit: 130,
        speedMultiplier: .75,
        readySeconds: 5,
        gripSeconds: 5,
        waveSize: 2,
        goals: [LevelGoal.noWrongBed(), LevelGoal.timeLeft(45)]),
    LevelConfig(
        id: 206,
        map: ShelterMap.garden,
        name: 'Himalaya siêu nhát',
        catTypes: ['himalaya', 'himalaya', 'orange'],
        timeLimit: 120,
        speedMultiplier: .8,
        readySeconds: 4.5,
        gripSeconds: 5,
        skillTier: 2,
        bossType: 'himalaya',
        goals: [LevelGoal.noStartle(), LevelGoal.fishMax(5)]),
  ]),
  LevelChapter('Bếp ăn', 'scottish', [
    LevelConfig(
        id: 207,
        map: ShelterMap.warehouse,
        name: 'Kén cá',
        catTypes: ['scottish', 'orange', 'himalaya'],
        timeLimit: 130,
        speedMultiplier: .65,
        readySeconds: 6,
        gripSeconds: 6,
        allowRun: false,
        goals: [LevelGoal.fishMax(5), LevelGoal.timeLeft(55)]),
    LevelConfig(
        id: 208,
        map: ShelterMap.warehouse,
        name: 'Ổ dời chỗ',
        catTypes: ['scottish', 'scottish', 'orange', 'himalaya'],
        timeLimit: 130,
        speedMultiplier: .75,
        readySeconds: 5,
        gripSeconds: 5,
        movingBeds: true,
        goals: [LevelGoal.noWrongBed(), LevelGoal.timeLeft(40)]),
    LevelConfig(
        id: 209,
        map: ShelterMap.warehouse,
        name: 'Scottish sành ăn',
        catTypes: ['scottish', 'scottish', 'himalaya'],
        timeLimit: 140,
        speedMultiplier: .85,
        readySeconds: 4.5,
        gripSeconds: 4.5,
        skillTier: 2,
        bossType: 'scottish',
        fishLimit: 9,
        goals: [LevelGoal.fishMax(8), LevelGoal.timeLeft(40)]),
  ]),
  LevelChapter('Phòng chơi', 'calico', [
    LevelConfig(
        id: 210,
        map: ShelterMap.pond,
        name: 'Mèo ham chơi',
        catTypes: ['calico', 'orange', 'scottish'],
        timeLimit: 120,
        speedMultiplier: .65,
        readySeconds: 6,
        gripSeconds: 6,
        allowRun: false,
        goals: [LevelGoal.noStartle(), LevelGoal.timeLeft(55)]),
    LevelConfig(
        id: 211,
        map: ShelterMap.pond,
        name: 'Hết cá rồi',
        catTypes: ['calico', 'calico', 'scottish', 'orange'],
        timeLimit: 130,
        speedMultiplier: .8,
        readySeconds: 5,
        gripSeconds: 5,
        fishLimit: 4,
        goals: [LevelGoal.fishMax(3), LevelGoal.noWrongBed()]),
    LevelConfig(
        id: 212,
        map: ShelterMap.pond,
        name: 'Tam thể quậy',
        catTypes: ['calico', 'calico', 'himalaya', 'orange'],
        timeLimit: 130,
        speedMultiplier: .85,
        readySeconds: 4.5,
        gripSeconds: 4.5,
        skillTier: 3,
        bossType: 'calico',
        goals: [LevelGoal.noStartle(), LevelGoal.timeLeft(40)]),
  ]),
  LevelChapter('Góc tối', 'black', [
    LevelConfig(
        id: 213,
        map: ShelterMap.garden,
        name: 'Bóng đêm',
        catTypes: ['black', 'orange', 'himalaya'],
        timeLimit: 120,
        speedMultiplier: .65,
        readySeconds: 6,
        gripSeconds: 6,
        allowRun: false,
        goals: [LevelGoal.noStartle(), LevelGoal.timeLeft(55)]),
    LevelConfig(
        id: 214,
        map: ShelterMap.warehouse,
        name: 'Tắt đèn',
        catTypes: ['black', 'black', 'orange', 'scottish'],
        timeLimit: 140,
        speedMultiplier: .75,
        readySeconds: 5,
        gripSeconds: 5,
        darkness: true,
        goals: [LevelGoal.noWrongBed(), LevelGoal.timeLeft(45)]),
    LevelConfig(
        id: 215,
        map: ShelterMap.pond,
        name: 'Mèo đen bóng ma',
        catTypes: ['black', 'black', 'calico', 'scottish'],
        timeLimit: 140,
        speedMultiplier: .9,
        readySeconds: 4.5,
        gripSeconds: 4.5,
        skillTier: 3,
        bossType: 'black',
        goals: [LevelGoal.noStartle(), LevelGoal.fishMax(7)]),
  ]),
  LevelChapter('Đại cứu hộ', 'calico', [
    LevelConfig(
        id: 216,
        map: ShelterMap.garden,
        name: 'Cả nhà',
        catTypes: [
          'orange',
          'himalaya',
          'scottish',
          'calico',
          'black',
          'orange'
        ],
        timeLimit: 150,
        speedMultiplier: .85,
        readySeconds: 4.5,
        gripSeconds: 4.5,
        skillTier: 2,
        waveSize: 3,
        goals: [LevelGoal.noWrongBed(), LevelGoal.timeLeft(45)]),
    LevelConfig(
        id: 217,
        map: ShelterMap.pond,
        name: 'Đêm dời ổ',
        catTypes: ['orange', 'himalaya', 'scottish', 'calico', 'black'],
        timeLimit: 160,
        speedMultiplier: .9,
        readySeconds: 4.5,
        gripSeconds: 4.5,
        skillTier: 3,
        darkness: true,
        movingBeds: true,
        goals: [LevelGoal.noStartle(), LevelGoal.timeLeft(40)]),
    LevelConfig(
        id: 218,
        map: ShelterMap.warehouse,
        name: 'Đội cứu hộ',
        catTypes: [
          'orange',
          'orange',
          'himalaya',
          'scottish',
          'calico',
          'black',
          'black'
        ],
        timeLimit: 170,
        speedMultiplier: 1,
        readySeconds: 4,
        gripSeconds: 4,
        skillTier: 3,
        bossType: 'orange',
        movingBeds: true,
        fishLimit: 14,
        goals: [LevelGoal.fishMax(11), LevelGoal.timeLeft(35)]),
  ]),
];

final gameLevels = <LevelConfig>[
  for (final chapter in levelChapters) ...chapter.levels,
];

/// 1-based position shown to the player; ids are internal only.
int? levelNumber(LevelConfig level) {
  final index = gameLevels.indexWhere((l) => l.id == level.id);
  return index < 0 ? null : index + 1;
}

const infiniteLevel = LevelConfig(
    id: 99,
    name: 'Cứu hộ vô hạn',
    catTypes: ['orange', 'himalaya', 'scottish', 'calico', 'black'],
    timeLimit: 0,
    speedMultiplier: .8,
    readySeconds: 3,
    gripSeconds: 4,
    skillTier: 0,
    isInfinite: true);

/// One-cat practice rounds that teach each breed's catch rule, in the same
/// guided style as the first level. The orange tutorial is level 1 itself.
LevelConfig tutorialLevelFor(String type) => type == 'orange'
    ? gameLevels.first
    : LevelConfig(
        id: 100 +
            const ['himalaya', 'scottish', 'calico', 'black'].indexOf(type),
        name: 'Tập bắt mèo',
        catTypes: [type],
        timeLimit: 0,
        isTutorial: true,
        speedMultiplier: .5,
        readySeconds: 8,
        gripSeconds: 8,
        allowRun: false,
      );

/// Winning is one star; each met goal adds one.
/// Levels without goals (practice) give all three.
int starsFor(LevelConfig level, RoundStats stats) => level.goals.isEmpty
    ? 3
    : 1 + level.goals.where((goal) => goal.met(stats)).take(2).length;

/// Chapter the player had reached in the old layout (old ids 1–18), so
/// nobody loses access to chapters they had already opened.
int _legacyChapter(Map<String, int> stars) {
  const lastOfChapter = [4, 7, 10, 13, 16, 18];
  var reached = -1;
  for (var id = 1; id <= 18; id++) {
    if ((stars['$id'] ?? 0) == 0) continue;
    final chapter = lastOfChapter.indexWhere((last) => id <= last);
    final next = lastOfChapter.contains(id) ? chapter + 1 : chapter;
    if (next > reached) reached = next;
  }
  return reached.clamp(-1, levelChapters.length - 1);
}

/// Levels open one by one: a level is playable once the previous one is won.
/// Chapters opened in the old layout stay open.
bool levelUnlocked(int index, Map<String, int> stars) {
  if (index == 0 || (stars['${gameLevels[index - 1].id}'] ?? 0) > 0) {
    return true;
  }
  if ((stars['${gameLevels[index].id}'] ?? 0) > 0) return true;
  final chapter = levelChapters
      .indexWhere((c) => c.levels.any((l) => l.id == gameLevels[index].id));
  return chapter <= _legacyChapter(stars);
}

/// Stars earned in the current layout only.
int totalStars(Map<String, int> stars) =>
    gameLevels.fold(0, (sum, l) => sum + (stars['${l.id}'] ?? 0));

/// Where "play" continues: the first unwon level of the furthest open
/// chapter, or the last level once everything is won.
LevelConfig continueLevel(Map<String, int> stars) {
  var last = 0;
  for (var i = 0; i < gameLevels.length; i++) {
    if (levelUnlocked(i, stars)) last = i;
  }
  final chapter = levelChapters
      .firstWhere((c) => c.levels.any((l) => l.id == gameLevels[last].id));
  return chapter.levels.firstWhere((l) => (stars['${l.id}'] ?? 0) == 0,
      orElse: () => gameLevels.firstWhere((l) => (stars['${l.id}'] ?? 0) == 0,
          orElse: () => gameLevels.last));
}
