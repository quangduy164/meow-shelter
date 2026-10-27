import 'level_config.dart';

const gameLevels = <LevelConfig>[
  LevelConfig(
    id: 1,
    name: 'Làm quen',
    catTypes: [
      'orange',
      'orange',
      'himalaya',
      'himalaya',
      'scottish',
      'scottish',
      'calico',
      'calico',
      'black',
      'black'
    ],
    timeLimit: 90,
    lives: 3,
  ),
  LevelConfig(
    id: 2,
    name: 'Đuổi bắt',
    catTypes: [
      'orange',
      'orange',
      'himalaya',
      'himalaya',
      'scottish',
      'scottish'
    ],
    timeLimit: 105,
    lives: 4,
  ),
  LevelConfig(
    id: 3,
    name: 'Sân đông',
    catTypes: [
      'orange',
      'orange',
      'himalaya',
      'himalaya',
      'scottish',
      'scottish',
      'calico',
      'calico'
    ],
    timeLimit: 90,
    lives: 3,
  ),
  LevelConfig(
    id: 4,
    name: 'Nhanh tay',
    catTypes: [
      'orange',
      'himalaya',
      'scottish',
      'calico',
      'orange',
      'himalaya',
      'scottish',
      'calico'
    ],
    timeLimit: 75,
    lives: 3,
  ),
  LevelConfig(
    id: 5,
    name: 'Cứu hộ khẩn',
    catTypes: [
      'orange',
      'orange',
      'himalaya',
      'himalaya',
      'scottish',
      'scottish',
      'calico',
      'calico'
    ],
    timeLimit: 60,
    lives: 2,
  ),
  LevelConfig(
    id: 6,
    name: 'Thử thách',
    catTypes: [
      'orange',
      'orange',
      'himalaya',
      'himalaya',
      'scottish',
      'scottish',
      'calico',
      'calico'
    ],
    timeLimit: 50,
    lives: 2,
  ),
];
