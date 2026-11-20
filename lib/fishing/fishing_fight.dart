import 'dart:math' as math;
import '../collection/fish_species.dart';

enum FishFightMove { steady, warning, dive, inflate, dash, rest, orbit }

/// One timeline for simulation and visual cues; warnings always precede bursts.
class FishingFight {
  const FishingFight(this.move, this.surge, this.cue, {this.lateral = 0});
  final FishFightMove move;
  final double surge, lateral;
  final String cue;
  bool get blocked => move == FishFightMove.inflate;
  bool get dangerous =>
      move == FishFightMove.dive || move == FishFightMove.dash || blocked;
  bool get warning => move == FishFightMove.warning;
  double get reelBonus => move == FishFightMove.rest ? 1.4 : 1;

  static FishingFight at(FishSpecies fish, double elapsed) {
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
        final t = elapsed % 5.5;
        if (t < 3.5) {
          return const FishingFight(
              FishFightMove.rest, .1, 'Giả vờ ngoan · Tranh thủ kéo');
        }
        if (t < 4.3) {
          return const FishingFight(
              FishFightMove.warning, .3, 'Quẫy đuôi! Sắp kéo ngược');
        }
        return const FishingFight(
            FishFightMove.dash, 1, 'Kéo ngược! Nới dây và lái thuyền');
      default:
        return const FishingFight(
            FishFightMove.steady, .3, 'Kéo đều · Canh kim trong khung vàng');
    }
  }
}
