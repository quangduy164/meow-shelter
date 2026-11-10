import 'dart:ui';
import 'package:flame/components.dart';
import 'herd_route.dart';

enum HerdMapKind { nightMarket, dunes, snow, playground }

/// Layout and terrain tuning shared by the simulation and painters.
/// Coordinates use fractions of the playable viewport, not pixels.
class HerdMap {
  const HerdMap(this.kind, this.name, this.hint, this.color,
      {required this.route,
      this.walls = const [],
      this.softSand = const [],
      this.slopes = const [],
      this.ice = const []});
  final HerdMapKind kind;
  final HerdRoute route;
  final String name, hint;
  final Color color;
  final List<Rect> walls, softSand, slopes, ice;
  static const all = [playground, market, desert, winter];
  static const playground = HerdMap(
      HerdMapKind.playground,
      'SÂN ĐỒ CHƠI',
      'Xe đồ chơi chạy liên tục. Gom đàn rồi luồn qua các đường xe để về nhà.',
      Color(0xFF74A46B),
      route: HerdRoute.playground);
  static const market = HerdMap(
      HerdMapKind.nightMarket,
      'PHỐ CHỢ ĐÊM',
      'Đèn xanh: xe dừng. Đèn đỏ: xe chạy qua đường; nhớ chờ cả đuôi đàn!',
      Color(0xFF8470B4),
      route: HerdRoute.market,
      walls: [
        Rect.fromLTWH(.25, .36, .12, .10),
        Rect.fromLTWH(.12, .62, .12, .10),
      ]);
  static const desert = HerdMap(
      HerdMapKind.dunes,
      'ĐỒI CÁT',
      'Cát sẫm làm cả đàn chậm lại. Dốc có mũi tên đẩy mèo trượt xuống; né bụi gai lăn.',
      Color(0xFFD69C55),
      route: HerdRoute.desert,
      walls: [
        Rect.fromLTWH(.44, .48, .09, .12),
      ],
      softSand: [
        Rect.fromLTWH(.24, .32, .20, .22),
        Rect.fromLTWH(.61, .62, .17, .16)
      ],
      slopes: [
        Rect.fromLTWH(.56, .25, .22, .21)
      ]);
  static const winter = HerdMap(
      HerdMapKind.snow,
      'XỨ TUYẾT',
      'Trên băng, thả joystick vẫn trượt. Đổi hướng sớm và tránh những quả cầu tuyết.',
      Color(0xFF6AAEC5),
      route: HerdRoute.snow,
      walls: [
        Rect.fromLTWH(.28, .47, .09, .11),
        Rect.fromLTWH(.68, .30, .09, .12),
      ],
      ice: [
        Rect.fromLTWH(.40, .27, .23, .34),
        Rect.fromLTWH(.59, .65, .22, .16)
      ]);

  Rect pixels(Rect r, Vector2 size) => Rect.fromLTWH(
      r.left * size.x, r.top * size.y, r.width * size.x, r.height * size.y);
  bool contains(List<Rect> patches, Vector2 at, Vector2 size) =>
      patches.any((r) => pixels(r, size).contains(Offset(at.x, at.y)));
  bool blocked(Vector2 at, Vector2 size, {double radius = 15}) => walls
      .any((r) => pixels(r, size).inflate(radius).contains(Offset(at.x, at.y)));
  bool green(double t) => t % 10 < 5;
  // Freeze all traffic during the five-second pedestrian green interval.
  double patrolTime(double t) => kind == HerdMapKind.nightMarket
      ? (t ~/ 10) * 5 + (t % 10 - 5).clamp(0.0, 5.0)
      : t;
}
