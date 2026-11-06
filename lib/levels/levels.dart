import 'level_config.dart';

/// A group of levels that introduces one breed and its catch rule, then mixes
/// it with breeds the player already knows.
class LevelChapter {
  const LevelChapter(this.title, this.breed, this.levels);
  final String title;

  /// The breed this chapter teaches; drawn on the chapter header.
  final String breed;
  final List<LevelConfig> levels;
}

const levelChapters = <LevelChapter>[
  LevelChapter('Sân trước', 'orange', [
    LevelConfig(
        id: 1,
        name: 'Làm quen',
        catTypes: ['orange'],
        timeLimit: 0,
        isTutorial: true,
        speedMultiplier: .5,
        readySeconds: 8,
        gripSeconds: 8,
        allowRun: false),
    LevelConfig(
        id: 2,
        name: 'Bữa trưa',
        catTypes: ['orange', 'orange'],
        timeLimit: 120,
        speedMultiplier: .6,
        readySeconds: 6,
        gripSeconds: 6,
        allowRun: false),
    LevelConfig(
        id: 3,
        name: 'Ba bé đói',
        catTypes: ['orange', 'orange', 'orange'],
        timeLimit: 110,
        speedMultiplier: .7,
        readySeconds: 5,
        gripSeconds: 5),
    LevelConfig(
        id: 4,
        name: 'Chạy vọt',
        catTypes: ['orange', 'orange', 'orange'],
        timeLimit: 100,
        speedMultiplier: .8,
        readySeconds: 4,
        gripSeconds: 5,
        skillTier: 1),
  ]),
  LevelChapter('Vườn hoa', 'himalaya', [
    LevelConfig(
        id: 5,
        name: 'Bé rụt rè',
        catTypes: ['himalaya', 'orange'],
        timeLimit: 120,
        speedMultiplier: .6,
        readySeconds: 6,
        gripSeconds: 6,
        allowRun: false),
    LevelConfig(
        id: 6,
        name: 'Giữ khoảng cách',
        catTypes: ['himalaya', 'himalaya', 'orange'],
        timeLimit: 120,
        speedMultiplier: .7,
        readySeconds: 5,
        gripSeconds: 5),
    LevelConfig(
        id: 7,
        name: 'Đổi hướng',
        catTypes: ['himalaya', 'himalaya', 'orange', 'orange'],
        timeLimit: 110,
        speedMultiplier: .8,
        readySeconds: 4,
        gripSeconds: 5,
        skillTier: 2),
  ]),
  LevelChapter('Bếp ăn', 'scottish', [
    LevelConfig(
        id: 8,
        name: 'Kén cá',
        catTypes: ['scottish', 'orange'],
        timeLimit: 130,
        speedMultiplier: .6,
        readySeconds: 6,
        gripSeconds: 6,
        allowRun: false),
    LevelConfig(
        id: 9,
        name: 'Bữa đôi',
        catTypes: ['scottish', 'scottish', 'himalaya'],
        timeLimit: 130,
        speedMultiplier: .7,
        readySeconds: 5,
        gripSeconds: 5),
    LevelConfig(
        id: 10,
        name: 'Zíc-zắc',
        catTypes: ['scottish', 'scottish', 'orange', 'himalaya'],
        timeLimit: 120,
        speedMultiplier: .85,
        readySeconds: 4,
        gripSeconds: 4.5,
        skillTier: 2),
  ]),
  LevelChapter('Phòng chơi', 'calico', [
    LevelConfig(
        id: 11,
        name: 'Bé ham chơi',
        catTypes: ['calico', 'orange'],
        timeLimit: 120,
        speedMultiplier: .6,
        readySeconds: 6,
        gripSeconds: 6,
        allowRun: false),
    LevelConfig(
        id: 12,
        name: 'Vừa ăn vừa chơi',
        catTypes: ['calico', 'calico', 'scottish'],
        timeLimit: 130,
        speedMultiplier: .7,
        readySeconds: 5,
        gripSeconds: 5),
    LevelConfig(
        id: 13,
        name: 'Tuột tay',
        catTypes: ['calico', 'calico', 'himalaya', 'orange'],
        timeLimit: 120,
        speedMultiplier: .85,
        readySeconds: 4,
        gripSeconds: 4.5,
        skillTier: 3),
  ]),
  LevelChapter('Góc tối', 'black', [
    LevelConfig(
        id: 14,
        name: 'Bóng đêm',
        catTypes: ['black', 'orange'],
        timeLimit: 120,
        speedMultiplier: .6,
        readySeconds: 6,
        gripSeconds: 6,
        allowRun: false),
    LevelConfig(
        id: 15,
        name: 'Chỗ vắng',
        catTypes: ['black', 'black', 'himalaya', 'orange'],
        timeLimit: 130,
        speedMultiplier: .75,
        readySeconds: 5,
        gripSeconds: 5),
    LevelConfig(
        id: 16,
        name: 'Ẩn hiện',
        catTypes: ['black', 'black', 'calico', 'scottish'],
        timeLimit: 120,
        speedMultiplier: .9,
        readySeconds: 4,
        gripSeconds: 4.5,
        skillTier: 3),
  ]),
  LevelChapter('Đại cứu hộ', 'calico', [
    LevelConfig(
        id: 17,
        name: 'Cả nhà',
        catTypes: ['orange', 'himalaya', 'scottish', 'calico', 'black'],
        timeLimit: 140,
        speedMultiplier: .9,
        readySeconds: 4,
        gripSeconds: 4.5,
        skillTier: 3),
    LevelConfig(
        id: 18,
        name: 'Đội cứu hộ',
        catTypes: [
          'orange',
          'orange',
          'himalaya',
          'scottish',
          'calico',
          'calico',
          'black',
          'black'
        ],
        timeLimit: 150,
        speedMultiplier: 1.05,
        readySeconds: 3,
        gripSeconds: 4,
        skillTier: 3),
  ]),
];

final gameLevels = <LevelConfig>[
  for (final chapter in levelChapters) ...chapter.levels,
];

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

/// Stars for a win: more time left means more stars. Untimed rounds give 3.
int starsFor(LevelConfig level, int secondsLeft) {
  if (level.timeLimit <= 0) return 3;
  final left = secondsLeft / level.timeLimit;
  return left >= .5
      ? 3
      : left >= .25
          ? 2
          : 1;
}

/// Levels open one by one: a level is playable once the previous one is won.
bool levelUnlocked(int index, Map<String, int> stars) =>
    index == 0 || (stars['${gameLevels[index - 1].id}'] ?? 0) > 0;
