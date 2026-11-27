part of 'adventure_skills.dart';

// ===========================================================================
// Earth: stone wall and reflect aura.
// ===========================================================================

/// A short wall of boulders standing across the aim direction for
/// [HomeAttack.stoneWall] duration. Rocks bounce off it, crabs turn back and
/// diving birds are scared away. The cat is not blocked by its own wall.
class AdventureStoneWall extends PositionComponent {
  AdventureStoneWall({required Vector2 center, required Vector2 facing})
      : _n = facing.normalized(),
        super(position: center.clone(), priority: 4);

  /// Aim direction (wall normal) and the wall's own axis.
  final Vector2 _n;
  Vector2 get _u => Vector2(-_n.y, _n.x);
  double _t = 0;

  double get length => HomeAttack.stoneWall.radius;
  static const double thickness = 22;
  bool get standing => _t < HomeAttack.stoneWall.duration;

  /// Closest point of the wall footprint to [p].
  Vector2 closest(Vector2 p) {
    final d = p - position;
    final along = d.dot(_u).clamp(-length / 2, length / 2).toDouble();
    final across = d.dot(_n).clamp(-thickness / 2, thickness / 2).toDouble();
    return position + _u * along + _n * across;
  }

  /// Footprint corners, for the aim preview and the drawing.
  static List<Offset> footprint(Vector2 c, Vector2 n, double length) {
    final u = Vector2(-n.y, n.x);
    final a = u * (length / 2), b = n * (thickness / 2);
    return [c + a + b, c + a - b, c - a - b, c - a + b]
        .map((v) => Offset(v.x, v.y))
        .toList();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    if (_t > HomeAttack.stoneWall.duration + .3) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final life = HomeAttack.stoneWall.duration;
    // Rises out of the ground, sinks back at the end.
    final rise = _t < .2
        ? _t / .2
        : _t > life
            ? max(0.0, 1 - (_t - life) / .3)
            : 1.0;
    final u = _u;
    const count = 5;
    final blocks = [
      for (var i = 0; i < count; i++)
        u * ((i - (count - 1) / 2) * length / count),
    ]..sort((a, b) => a.y.compareTo(b.y));
    final height = 26 * rise;
    for (final b in blocks) {
      final base = Offset(b.x, b.y);
      canvas.drawOval(
          Rect.fromCenter(
              center: base + const Offset(0, 4), width: 30, height: 12),
          Paint()..color = const Color(0x44000000));
    }
    for (var i = 0; i < blocks.length; i++) {
      final base = Offset(blocks[i].x, blocks[i].y);
      final w = 26.0 + (i % 2) * 4;
      final body = RRect.fromRectAndRadius(
          Rect.fromLTRB(base.dx - w / 2, base.dy - height - 8, base.dx + w / 2,
              base.dy + 4),
          const Radius.circular(9));
      canvas.drawRRect(body, Paint()..color = const Color(0xFF8E7C68));
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTRB(
                  body.left + 3, body.top + 2, body.right - 3, body.top + 12),
              const Radius.circular(6)),
          Paint()..color = const Color(0xFFB4A28C));
      canvas.drawRRect(
          body,
          Paint()
            ..color = const Color(0xFF4A3C30)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
      canvas.drawLine(
          Offset(base.dx - 6, base.dy - height * .4),
          Offset(base.dx + 2, base.dy - height * .3),
          Paint()
            ..color = const Color(0xFF6E5E4E)
            ..strokeWidth = 1.6);
    }
    // Dust while rising.
    if (_t < .4) {
      final k = _t / .4;
      for (var i = 0; i < 6; i++) {
        final side = (i - 2.5) / 2.5;
        final p = u * (side * length / 2);
        canvas.drawCircle(Offset(p.x, p.y + 4), 6 + 10 * k,
            Paint()..color = _a(const Color(0xFFD8C8A4), .6 * (1 - k)));
      }
    }
  }
}

/// Mirror shards circling the cat while [HomeAttack.reflect] is up.
class AdventureReflectAura extends Component {
  AdventureReflectAura() : super(priority: 6);

  Vector2 center = Vector2.zero();
  double timeLeft = 0;
  double _t = 0;
  double _flash = 0;

  void flash() => _flash = .25;

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    _flash = max(0, _flash - dt);
  }

  @override
  void render(Canvas canvas) {
    if (timeLeft <= 0) return;
    if (timeLeft < .8 && (timeLeft * 10).floor().isEven) return;
    final r = HomeAttack.reflect.radius;
    final c = Offset(center.x, center.y - 6);
    final ring = Rect.fromCenter(center: c, width: r * 2, height: r * 2 * .8);
    canvas.drawOval(
        ring, Paint()..color = _a(const Color(0xFF7FE0CF), .12 + _flash * 1.6));
    canvas.drawOval(
        ring,
        Paint()
          ..color = const Color(0x997FE0CF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
    for (var i = 0; i < 3; i++) {
      final a = _t * 3 + i * pi * 2 / 3;
      final p = c + Offset(cos(a) * r, sin(a) * r * .8);
      canvas.save();
      canvas.translate(p.dx, p.dy);
      canvas.rotate(a + pi / 2);
      final shard = Path()
        ..moveTo(0, -11)
        ..lineTo(6, 0)
        ..lineTo(0, 11)
        ..lineTo(-6, 0)
        ..close();
      canvas.drawPath(shard, Paint()..color = const Color(0xFFE6FFFA));
      canvas.drawPath(
          shard,
          Paint()
            ..color = const Color(0xFF2E8A7C)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6);
      canvas.drawLine(
          const Offset(-1, -6),
          const Offset(2, 2),
          Paint()
            ..color = const Color(0xFF8FD8CC)
            ..strokeWidth = 1.5);
      canvas.restore();
    }
  }
}
