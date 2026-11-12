import 'dart:ui';
import 'package:flame/components.dart';
import 'herd_route.dart';
import 'herd_market.dart';
import 'herd_snow.dart';

export 'herd_market.dart';
export 'herd_desert.dart';
export 'herd_snow.dart';

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
      this.snowPads = const [],
      this.vendors = const [],
      this.lanternZones = const [],
      this.shade = const [],
      this.thinIce = const [],
      this.chutes = const []});
  final HerdMapKind kind;
  final HerdRoute route;
  final String name, hint;
  final Color color;
  final List<Rect> walls, softSand, slopes, ice, landings, snowPads;
  final List<HerdVendor> vendors;

  /// Each zone has its own lantern cycle; points outside zones stay lit.
  final List<Rect> lanternZones;

  /// Cool shade where desert followers lose heat.
  final List<Rect> shade;

  /// Snow sheets that crack under a crowd; snowPads inside them stay safe.
  final List<Rect> thinIce;
  final List<HerdChute> chutes;
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
      'Bác bán hàng thấy mèo trong vùng sáng sẽ xua cả đàn. Chờ bác quay đi hoặc đèn lồng tắt rồi lẻn qua.',
      Color(0xFF8470B4),
      route: HerdRoute.market,
      walls: [
        Rect.fromLTWH(.14, .20, .23, .04),
        Rect.fromLTWH(.14, .42, .07, .05),
        Rect.fromLTWH(.43, .19, .035, .20),
        Rect.fromLTWH(.75, .19, .035, .20),
        Rect.fromLTWH(.59, .70, .07, .07),
        Rect.fromLTWH(.80, .70, .07, .07),
      ],
      vendors: [
        HerdVendor(Offset(.255, .215), 1.5708, .6, 0),
        HerdVendor(Offset(.448, .29), 0, .5, 3),
        HerdVendor(Offset(.835, .735), 3.1416, .5, 6),
      ],
      lanternZones: [
        // Zone i is watched by vendor i.
        Rect.fromLTWH(.08, .17, .34, .27),
        Rect.fromLTWH(.43, .17, .33, .27),
        Rect.fromLTWH(.55, .63, .42, .32),
      ]);
  static const desert = HerdMap(
      HerdMapKind.dunes,
      'ĐỒI CÁT',
      'Nắng làm mèo trong đàn nóng dần; đi qua bóng râm để mát lại. Bão cát có báo trước: nấp sau đá hoặc lều.',
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
      ],
      shade: [
        Rect.fromLTWH(.07, .20, .28, .21),
        Rect.fromLTWH(.42, .33, .08, .10),
        Rect.fromLTWH(.355, .60, .12, .18),
        Rect.fromLTWH(.595, .56, .10, .16),
        Rect.fromLTWH(.76, .75, .16, .12),
        Rect.fromLTWH(.79, .44, .10, .10),
      ]);
  static const winter = HerdMap(
      HerdMapKind.snow,
      'XỨ TUYẾT',
      'Băng mỏng trên hồ chỉ chịu được ít mèo: đàn đông đi qua sẽ làm băng nứt vỡ. Làn trượt một chiều đưa đàn đi rất nhanh.',
      Color(0xFF6AAEC5),
      route: HerdRoute.snow,
      walls: [
        Rect.fromLTWH(.13, .21, .20, .045),
        Rect.fromLTWH(.13, .21, .035, .18),
        Rect.fromLTWH(.24, .65, .075, .10),
        Rect.fromLTWH(.55, .64, .075, .11),
        Rect.fromLTWH(.68, .62, .12, .065),
      ],
      ice: [
        Rect.fromLTWH(.37, .19, .36, .41),
        Rect.fromLTWH(.65, .67, .29, .22)
      ],
      thinIce: [
        Rect.fromLTWH(.37, .19, .36, .41)
      ],
      snowPads: [
        Rect.fromLTWH(.48, .27, .15, .17),
        Rect.fromLTWH(.30, .36, .06, .12),
      ],
      chutes: [
        HerdChute(Rect.fromLTWH(.27, .855, .32, .065), Offset(1, 0)),
        HerdChute(Rect.fromLTWH(.875, .36, .06, .30), Offset(0, -1)),
      ]);

  Rect pixels(Rect r, Vector2 size) => Rect.fromLTWH(
      r.left * size.x, r.top * size.y, r.width * size.x, r.height * size.y);
  bool contains(List<Rect> patches, Vector2 at, Vector2 size) =>
      patches.any((r) => pixels(r, size).contains(Offset(at.x, at.y)));
  bool blocked(Vector2 at, Vector2 size, {double radius = 15}) => walls
      .any((r) => pixels(r, size).inflate(radius).contains(Offset(at.x, at.y)));
  HerdChute? chuteAt(Vector2 at, Vector2 size) {
    for (final chute in chutes) {
      if (pixels(chute.area, size).contains(Offset(at.x, at.y))) return chute;
    }
    return null;
  }

  bool green(double t) => t % 10 < 5;

  /// Index of the lantern zone containing [at], or null outside every zone.
  int? lanternZoneAt(Vector2 at, Vector2 size) {
    for (var i = 0; i < lanternZones.length; i++) {
      if (pixels(lanternZones[i], size).contains(Offset(at.x, at.y))) return i;
    }
    return null;
  }

  bool litAt(Vector2 at, Vector2 size, double t) {
    final zone = lanternZoneAt(at, size);
    return zone == null || HerdLanterns.lit(zone, t);
  }

  // Freeze all traffic during the five-second pedestrian green interval.
  double patrolTime(double t) => kind == HerdMapKind.nightMarket
      ? (t ~/ 10) * 5 + (t % 10 - 5).clamp(0.0, 5.0)
      : t;
}
