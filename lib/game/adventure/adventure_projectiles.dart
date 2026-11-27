part of 'adventure_skills.dart';

// ===========================================================================
// Projectiles: fireball and ice shard.
// ===========================================================================

/// A flying skill shot. The fireball bursts on the first hazard; the ice shard
/// pierces and freezes everything along its lane.
class AdventureProjectile extends PositionComponent {
  AdventureProjectile({
    required Vector2 position,
    required this.direction,
    required this.attack,
  }) : super(position: position, anchor: Anchor.center, priority: 7);

  final Vector2 direction;
  final HomeAttack attack;
  double travelled = 0;
  double _t = 0;
  final _trail = <Vector2>[];

  /// Hazards already hit; a piercing shard hits each one once.
  final hit = <AdventureObstacle>{};
  bool hitBoss = false;

  bool get icy => attack == HomeAttack.iceShard;
  double get radius => attack.radius;
  bool get spent => travelled >= attack.range;

  Rect get hitRect =>
      Rect.fromCircle(center: Offset(position.x, position.y), radius: radius);

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    _trail.insert(0, position.clone());
    if (_trail.length > (icy ? 9 : 7)) _trail.removeLast();
    final step = (icy ? iceShardSpeed : fireballSpeed) * dt;
    position += direction * step;
    travelled += step;
  }

  @override
  void render(Canvas canvas) => icy ? _renderIce(canvas) : _renderFire(canvas);

  void _renderFire(Canvas canvas) {
    for (var i = 0; i < _trail.length; i++) {
      final p = _trail[i] - position;
      final k = 1 - i / _trail.length;
      canvas.drawCircle(Offset(p.x, p.y), radius * (.4 + .6 * k),
          Paint()..color = Color.fromARGB((120 * k).round(), 0xFF, 0x8A, 0x2A));
    }
    final flicker = 1 + sin(_t * 40) * .08;
    canvas.drawCircle(
        Offset.zero,
        radius * 1.7 * flicker,
        Paint()
          ..shader = const RadialGradient(colors: [
            Color(0x88FFB347),
            Color(0x00FF6A00),
          ]).createShader(
              Rect.fromCircle(center: Offset.zero, radius: radius * 1.7)));
    canvas.drawCircle(Offset.zero, radius * flicker,
        Paint()..color = const Color(0xFFFF6A2A));
    canvas.drawCircle(Offset(direction.x * 2, direction.y * 2 - 2), radius * .6,
        Paint()..color = const Color(0xFFFFD45C));
    canvas.drawCircle(Offset(direction.x * 3, direction.y * 3 - 3),
        radius * .28, Paint()..color = const Color(0xFFFFF6D8));
  }

  void _renderIce(Canvas canvas) {
    // Frost sparkles left behind.
    for (var i = 1; i < _trail.length; i++) {
      final p = _trail[i] - position;
      final k = 1 - i / _trail.length;
      final side = (i.isEven ? 1 : -1) * 5.0;
      final o = Offset(p.x - direction.y * side, p.y + direction.x * side);
      canvas.drawCircle(o, 2.5 * k + 1,
          Paint()..color = Color.fromARGB((200 * k).round(), 0xD8, 0xF4, 0xFF));
    }
    canvas.save();
    canvas.rotate(atan2(direction.y, direction.x));
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 56, height: 26),
        Paint()..color = const Color(0x445FC8F0));
    final shard = Path()
      ..moveTo(22, 0)
      ..lineTo(6, -8)
      ..lineTo(-18, -5)
      ..lineTo(-24, 0)
      ..lineTo(-18, 5)
      ..lineTo(6, 8)
      ..close();
    canvas.drawPath(shard, Paint()..color = const Color(0xFFE8FAFF));
    canvas.drawPath(
        Path()
          ..moveTo(22, 0)
          ..lineTo(6, -8)
          ..lineTo(-18, -5)
          ..lineTo(-24, 0)
          ..close(),
        Paint()..color = const Color(0xFF9EDCF5));
    canvas.drawPath(
        shard,
        Paint()
          ..color = const Color(0xFF2E7FA8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..strokeJoin = StrokeJoin.round);
    canvas.drawLine(
        const Offset(6, -7),
        const Offset(6, 7),
        Paint()
          ..color = const Color(0xAA2E7FA8)
          ..strokeWidth = 1.2);
    canvas.restore();
  }
}
