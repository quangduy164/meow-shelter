import 'dart:math' as math;
import '../collection/fish_species.dart';

enum FishFightMove { steady, warning, dive, inflate, dash, rest, orbit }

/// One timeline for simulation and visual cues; warnings always precede bursts.
class FishingFight {
  const FishingFight(this.move, this.surge, this.cue,
      {this.lateral = 0, this.pullMultiplier = 1});
  final FishFightMove move;
  final double surge, lateral, pullMultiplier;
  final String cue;
  bool get blocked => move == FishFightMove.inflate;
  bool get dangerous =>
      move == FishFightMove.dive || move == FishFightMove.dash || blocked;
  bool get warning => move == FishFightMove.warning;
  double get reelBonus => move == FishFightMove.rest ? 1.4 : 1;

  static FishingFight at(FishSpecies fish, double elapsed) {
    fish = switch (fish) {
      FishSpecies.goby => FishSpecies.perch,
      FishSpecies.mudskipper => FishSpecies.goldfish,
      FishSpecies.grouper => FishSpecies.carp,
      FishSpecies.butterflyfish => FishSpecies.clownfish,
      FishSpecies.cavefish => FishSpecies.catfish,
      FishSpecies.lanternfish => FishSpecies.koi,
      _ => fish,
    };
    switch (fish) {
      case FishSpecies.catfish:
        final t = elapsed % 4.8;
        if (t < 1.5) {
          return const FishingFight(
              FishFightMove.steady, .2, 'Cá trê đang bơi · Kéo đều');
        }
        if (t < 2.3) {
          return const FishingFight(
              FishFightMove.warning, .3, 'Sắp lặn! Chuẩn bị nới dây');
        }
        if (t < 3.1) {
          return const FishingFight(
              FishFightMove.dive, 1, 'Cá lặn! Thả nút kéo');
        }
        return const FishingFight(
            FishFightMove.rest, .1, 'Cá nổi lại · Tranh thủ kéo!');
      case FishSpecies.pufferfish:
        final t = elapsed % 5.2;
        if (t < 1.8) {
          return const FishingFight(
              FishFightMove.rest, .15, 'Cá đang xẹp · Kéo vào!');
        }
        if (t < 2.6) {
          return const FishingFight(
              FishFightMove.warning, .3, 'Sắp phồng! Chuẩn bị thả');
        }
        if (t < 4.1) {
          return const FishingFight(
              FishFightMove.inflate, 1, 'Cá phồng! Nới dây, đợi xẹp');
        }
        return const FishingFight(FishFightMove.rest, .1, 'Xẹp rồi! Kéo vào!');
      case FishSpecies.mackerel:
        final t = elapsed % 4.2;
        if (t < 1.4) {
          return const FishingFight(
              FishFightMove.rest, .12, 'Cá đang nghỉ · Kéo vào!');
        }
        if (t < 2.1) {
          return const FishingFight(
              FishFightMove.warning, .3, 'Sắp lao! Chuẩn bị nới dây');
        }
        if (t < 3) {
          return const FishingFight(
              FishFightMove.dash, 1, 'Cá lao nhanh! Thả nút kéo');
        }
        return const FishingFight(
            FishFightMove.rest, .12, 'Cá mệt rồi · Kéo vào!');
      case FishSpecies.koi:
        final lateral = math.sin(elapsed * 1.2) * .9;
        return FishingFight(
            FishFightMove.orbit,
            .35,
            lateral > .18
                ? 'Cá vòng xuống · Vuốt lên để ghìm'
                : lateral < -.18
                    ? 'Cá vòng lên · Vuốt xuống để ghìm'
                    : 'Đổi vòng · Giữ thuyền giữa sông',
            lateral: lateral);
      case FishSpecies.carp:
        return const FishingFight(
            FishFightMove.steady, .52, 'Cá chép lì · Giữ lực kéo ổn định');
      case FishSpecies.perch:
        return FishingFight(
            FishFightMove.steady,
            math.sin(elapsed * 7).abs() > .8 ? .7 : .2,
            'Cá rô giật ngắn · Kéo vừa tay');
      case FishSpecies.goldfish:
      case FishSpecies.clownfish:
        return const FishingFight(
            FishFightMove.steady, .35, 'Cá lượn nhanh · Vuốt lái và kéo đều');
      case FishSpecies.catMew:
        // Two reverse pulls alternate direction, separated by a breather.
        final t = elapsed % 6.8;
        if (t < 2.6) {
          return const FishingFight(
              FishFightMove.rest, .1, 'Nước lặng · Tranh thủ kéo');
        }
        if (t < 3.3 || (t >= 4.6 && t < 5.3)) {
          return const FishingFight(
              FishFightMove.warning, .3, 'Đuôi quẫy ngược · Chuẩn bị nới dây');
        }
        if (t < 4.1 || (t >= 5.3 && t < 6.1)) {
          return FishingFight(
              FishFightMove.dash, .9, 'Kéo ngược! Nới dây và ghìm thuyền',
              lateral: t < 4.1 ? -.7 : .7);
        }
        return const FishingFight(
            FishFightMove.rest, .12, 'Ngừng quẫy · Kéo vào!');
      case FishSpecies.seaDragon:
        // Three warned surges get faster, followed by a long recovery.
        final t = elapsed % 9;
        if ((t >= 2 && t < 2.7) ||
            (t >= 3.3 && t < 4) ||
            (t >= 4.8 && t < 5.5)) {
          return const FishingFight(
              FishFightMove.warning, .35, 'Sóng dồn lại · Chuẩn bị nới dây');
        }
        if (t >= 2.7 && t < 3.3) {
          return const FishingFight(
              FishFightMove.dash, .7, 'Lao đợt đầu · Thả nút kéo',
              pullMultiplier: 1);
        }
        if (t >= 4 && t < 4.8) {
          return const FishingFight(
              FishFightMove.dash, .85, 'Lao nhanh hơn · Thả nút và ghìm thuyền',
              pullMultiplier: 1.2);
        }
        if (t >= 5.5 && t < 6.5) {
          return const FishingFight(
              FishFightMove.dash, 1, 'Sóng cuộn mạnh · Nới dây!',
              pullMultiplier: 1.4);
        }
        return const FishingFight(
            FishFightMove.rest, .1, 'Sóng dịu xuống · Tranh thủ kéo!');
      case FishSpecies.moonfish:
        final t = elapsed % 8;
        if (t < 2.3 || t >= 6.2) {
          return const FishingFight(
              FishFightMove.rest, .12, 'Ánh bạc hiện lên · Tranh thủ kéo');
        }
        if (t < 3.1) {
          return const FishingFight(
              FishFightMove.warning, .3, 'Bóng cá chìm dần · Chuẩn bị nới dây');
        }
        if (t < 4.6) {
          return const FishingFight(
              FishFightMove.dive, .9, 'Cá lặn mất bóng · Nới dây, chờ nổi',
              pullMultiplier: .65);
        }
        return FishingFight(
            FishFightMove.orbit, .3, 'Ánh bạc trở lại · Ghìm thuyền và kéo',
            lateral: math.sin((t - 4.6) * math.pi / 1.6) * .7);
      default:
        return const FishingFight(
            FishFightMove.steady, .3, 'Kéo đều · Canh kim trong khung vàng');
    }
  }
}
