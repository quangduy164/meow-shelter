import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

import '../components/cat_component.dart';
import '../world/shelter_map.dart';
import 'bait_system.dart';

class _Drop {
  _Drop(this.x, this.land);
  final double x;
  final Vector2 land;
  double age = 0;
}

/// Chapter 1 yard: dried fish now and then falls off the drying rack. It is
/// free bait, so greedy orange cats crowd under the rack. The rack shakes a
/// second before each drop so the player can plan around it.
class RackSystem {
  RackSystem(this.map, this.random);
  final ShelterMap map;
  final Random random;
  Vector2 _size = Vector2.zero();
  double _timer = 5, _clock = 0;
  double? _shakeX;
  final _drops = <_Drop>[];

  /// Seconds between drops, the warning shake and the fall itself.
  static const minGap = 8.0, maxGap = 11.0, shake = 1.0, fall = .55;

  Rect get _rack => Rect.fromLTWH(
      map.rack!.left * _size.x,
      map.rack!.top * _size.y,
      map.rack!.width * _size.x,
      map.rack!.height * _size.y);

  void update(
      double dt, Vector2 size, BaitSystem bait, Iterable<CatComponent> cats) {
    _size = size;
    _clock += dt;
    _timer -= dt;
    if (_timer <= shake && _shakeX == null) {
      final r = _rack;
      _shakeX = r.left + 14 + random.nextDouble() * (r.width - 28);
    }
    if (_timer <= 0) {
      final r = _rack;
      final x = _shakeX ?? r.center.dx;
      final land = Vector2(x + (random.nextDouble() - .5) * 30,
          r.bottom + 34 + random.nextDouble() * 30);
      _drops.add(_Drop(x, land));
      _shakeX = null;
      _timer = minGap + random.nextDouble() * (maxGap - minGap);
    }
    for (final drop in List<_Drop>.of(_drops)) {
      drop.age += dt;
      if (drop.age < fall) continue;
      _drops.remove(drop);
      bait.place(drop.land, size, cats, free: true);
    }
  }

  /// Fish hanging on the rack (one shakes before it falls) and falling fish.
  void render(Canvas canvas) {
    final r = _rack;
    if (r.width <= 0) return;
    for (var i = 0; i < 5; i++) {
      final x = r.left + 18 + i * (r.width - 36) / 4;
      final shaking = _shakeX != null && (x - _shakeX!).abs() < 30;
      final sway =
          shaking ? sin(_clock * 40) * .35 : sin(_clock * 1.5 + i) * .08;
      canvas.save();
      canvas.translate(x, r.top + 6);
      canvas.rotate(sway);
      canvas.drawLine(
          Offset.zero,
          const Offset(0, 10),
          Paint()
            ..color = const Color(0xFF7A5A41)
            ..strokeWidth = 1.5);
      canvas.translate(0, 22);
      canvas.rotate(pi / 2);
      canvas.scale(.6);
      _driedFish(canvas);
      canvas.restore();
    }
    for (final drop in _drops) {
      final k = (drop.age / fall).clamp(0.0, 1.0);
      final y = r.top + 28 + (drop.land.y - r.top - 28) * k * k;
      final x = drop.x + (drop.land.x - drop.x) * k;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(k * pi * 1.5);
      canvas.scale(.8);
      _driedFish(canvas);
      canvas.restore();
    }
  }

  static final _body = Paint()..color = const Color(0xFFC98B4E);
  static final _belly = Paint()..color = const Color(0xFFE6B676);
  static final _line = Paint()
    ..color = const Color(0xFF8A5A2E)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.4;

  /// Dried fish: golden brown body, pale belly, scored skin.
  void _driedFish(Canvas canvas) {
    canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: 30, height: 15), _body);
    canvas.drawOval(
        Rect.fromCenter(center: const Offset(1, 3), width: 22, height: 6),
        _belly);
    canvas.drawPath(
        Path()
          ..moveTo(-12, 0)
          ..lineTo(-23, -9)
          ..lineTo(-23, 9)
          ..close(),
        _body);
    for (final x in [-5.0, 0.0, 5.0]) {
      canvas.drawLine(Offset(x, -5), Offset(x - 2, 4), _line);
    }
    canvas.drawCircle(
        const Offset(9, -2), 1.8, Paint()..color = const Color(0xFF3A2A20));
  }
}
