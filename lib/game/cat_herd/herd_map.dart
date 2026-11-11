import 'dart:ui';
import 'package:flame/components.dart';
import 'herd_route.dart';

enum HerdMapKind { nightMarket, dunes, snow, playground, tutorial }

/// Layout and terrain tuning shared by the simulation and painters.
/// Coordinates use fractions of the playable viewport, not pixels.
class HerdMap {
  const HerdMap(this.kind, this.name, this.hint, this.color,
      {required this.route,
      this.walls = const [],
      this.softSand = const [],
      this.slopes = const [],
      this.ice = const [],
      this.landings = const [],
      this.snowPads = const []});
  final HerdMapKind kind;
  final HerdRoute route;
  final String name, hint;
  final Color color;
  final List<Rect> walls, softSand, slopes, ice, landings, snowPads;
  static const all = [playground, market, desert, winter];
  static const tutorial = HerdMap(HerdMapKind.tutorial, 'SÂN TẬP DẪN ĐÀN',
      'Tập joystick, né các tảng đá và đón đủ 12 bé về nhà.', Color(0xFF8DB6A2),
      route: HerdRoute.tutorial,
      walls: [
        Rect.fromLTWH(.36, .37, .05, .16),
        Rect.fromLTWH(.54, .52, .055, .17),
        Rect.fromLTWH(.73, .42, .055, .12),
      ]);
  static const playground = HerdMap(
      HerdMapKind.playground,
      'SÂN ĐỒ CHƠI',
      'Len qua khối gỗ, canh xe chạy vòng và né bóng nảy. Bóng chỉ đẩy lệch đàn, không mất mạng.',
      Color(0xFF74A46B),
      route: HerdRoute.playground,
      walls: [
        Rect.fromLTWH(.14, .19, .035, .28),
        Rect.fromLTWH(.14, .19, .325, .035),
        Rect.fromLTWH(.43, .19, .035, .28),
      ]);
  static const market = HerdMap(
      HerdMapKind.nightMarket,
      'PHỐ CHỢ ĐÊM',
      'Đón mèo ở quầy cá, ngõ hàng và bên kia phố. Đèn xanh dừng xe máy; xe đẩy vẫn di chuyển.',
      Color(0xFF8470B4),
      route: HerdRoute.market,
      walls: [
        Rect.fromLTWH(.14, .20, .23, .04),
        Rect.fromLTWH(.14, .42, .07, .05),
        Rect.fromLTWH(.43, .19, .035, .20),
        Rect.fromLTWH(.75, .19, .035, .20),
        Rect.fromLTWH(.59, .70, .07, .07),
        Rect.fromLTWH(.80, .70, .07, .07),
      ]);
  static const desert = HerdMap(
      HerdMapKind.dunes,
      'ĐỒI CÁT',
      'Ghé ốc đảo và khe đá, né bụi gai. Dốc đẩy cả đàn xuống bãi cát; có đường vòng cát cứng.',
      Color(0xFFD69C55),
      route: HerdRoute.desert,
      walls: [
        Rect.fromLTWH(.13, .25, .10, .09),
        Rect.fromLTWH(.30, .61, .055, .15),
        Rect.fromLTWH(.54, .55, .055, .15),
        Rect.fromLTWH(.78, .69, .12, .06),
      ],
      softSand: [
        Rect.fromLTWH(.22, .45, .20, .13),
        Rect.fromLTWH(.53, .68, .18, .15)
      ],
      slopes: [
        Rect.fromLTWH(.59, .28, .20, .28)
      ],
      landings: [
        Rect.fromLTWH(.59, .56, .23, .10)
      ]);
  static const winter = HerdMap(
      HerdMapKind.snow,
      'XỨ TUYẾT',
      'Đón mèo ngủ ở trại củi và đảo tuyết. Hãm tốc trên tuyết khô; bóng tròn báo cầu tuyết sắp lăn.',
      Color(0xFF6AAEC5),
      route: HerdRoute.snow,
      walls: [
        Rect.fromLTWH(.13, .21, .20, .045),
        Rect.fromLTWH(.13, .21, .035, .18),
        Rect.fromLTWH(.24, .65, .075, .10),
        Rect.fromLTWH(.55, .64, .075, .11),
        Rect.fromLTWH(.75, .63, .15, .065),
      ],
      ice: [
        Rect.fromLTWH(.40, .20, .31, .32),
        Rect.fromLTWH(.65, .67, .29, .22)
      ],
      snowPads: [
        Rect.fromLTWH(.49, .26, .15, .18),
        Rect.fromLTWH(.33, .35, .07, .13),
        Rect.fromLTWH(.70, .45, .08, .10),
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
