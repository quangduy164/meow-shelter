part of 'adventure_skills.dart';

// ===========================================================================
// Ice: frozen hazards, frost nova, ice bridge.
// ===========================================================================

/// Ice block drawn over a frozen hazard (call with the canvas at its center).
void paintIceBlock(Canvas canvas, double timeLeft,
    {double width = 46, double height = 40}) {
  if (timeLeft < .6 && (timeLeft * 12).floor().isEven) return;
  final block = RRect.fromRectAndRadius(
      Rect.fromCenter(
          center: const Offset(0, -2), width: width, height: height),
      const Radius.circular(8));
  canvas.drawRRect(block, Paint()..color = const Color(0xA6C4ECFF));
  canvas.drawRRect(
      block,
      Paint()
        ..color = const Color(0xFF4E9CC4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5);
  canvas.drawRRect(
      block.deflate(2),
      Paint()
        ..color = const Color(0xFFF0FBFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5);
  final shine = Paint()
    ..color = const Color(0xCCFFFFFF)
    ..strokeWidth = 2.5
    ..strokeCap = StrokeCap.round;
  canvas.drawLine(Offset(-width / 2 + 7, -height / 2 + 8),
      Offset(-width / 2 + 15, -height / 2 + 4), shine);
  canvas.drawLine(Offset(width / 2 - 9, height / 2 - 10),
      Offset(width / 2 - 5, height / 2 - 16), shine..strokeWidth = 1.8);
}

/// Ring of ice spikes bursting out to [HomeAttack.frostNova] radius.
class AdventureFrostWave extends PositionComponent {
  AdventureFrostWave({required Vector2 position, this.radius = 140})
      : super(position: position, anchor: Anchor.center, priority: 3);

  double _t = 0;
  static const double _life = .8;
  final double radius;

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    if (_t > _life) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final grow = min(1.0, _t / .3);
    final ease = 1 - (1 - grow) * (1 - grow);
    final fade = 1 - (_t / _life);
    final r = radius * ease;
    final ground = Rect.fromCircle(center: Offset.zero, radius: r);
    canvas.drawOval(
        ground, Paint()..color = _a(const Color(0xFFCFF0FF), .35 * fade));
    canvas.drawOval(
        ground,
        Paint()
          ..color = _a(const Color(0xFFFFFFFF), .9 * fade)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3);
    // Crystals around the ring.
    for (var i = 0; i < 14; i++) {
      final a = i * pi * 2 / 14;
      final p = Offset(cos(a) * r, sin(a) * r);
      final h = (16 + (i % 3) * 6) * ease;
      final spike = Path()
        ..moveTo(p.dx - 5, p.dy)
        ..lineTo(p.dx, p.dy - h)
        ..lineTo(p.dx + 5, p.dy)
        ..close();
      canvas.drawPath(
          spike, Paint()..color = _a(const Color(0xFFE8FAFF), fade));
      canvas.drawPath(
          spike,
          Paint()
            ..color = _a(const Color(0xFF3FA6D6), fade)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4);
    }
    // Snowflake flash in the middle.
    if (_t < .35) {
      final k = 1 - _t / .35;
      final flake = Paint()
        ..color = _a(const Color(0xFFFFFFFF), k)
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round;
      for (var i = 0; i < 6; i++) {
        final a = i * pi / 3;
        canvas.drawLine(Offset.zero, Offset(cos(a), sin(a)) * 30, flake);
      }
    }
  }
}

/// A strip of ice laid from the cat along the aim: water under it is dry
/// ground until it melts.
class AdventureIceBridge extends PositionComponent {
  AdventureIceBridge({required Vector2 origin, required Vector2 direction})
      : _dir = direction.normalized(),
        super(position: origin.clone(), priority: 2);

  final Vector2 _dir;
  double _t = 0;

  /// The game freezes hazards under the ice once, when it is fully laid.
  bool frozeHazards = false;
  bool get built => _t >= .25;

  double get length => HomeAttack.iceBridge.range;
  double get halfWidth => HomeAttack.iceBridge.radius;
  double get _life => HomeAttack.iceBridge.duration;
  double get _built => length * min(1.0, _t / .25);

  /// Whether [p] stands on the ice.
  bool covers(Offset p) {
    final d = Vector2(p.dx, p.dy) - position;
    final along = d.dot(_dir);
    final across = d.x * -_dir.y + d.y * _dir.x;
    return along >= -halfWidth * .5 &&
        along <= _built + halfWidth * .5 &&
        across.abs() <= halfWidth;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    if (_t > _life) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final left = _life - _t;
    if (left < 1 && (left * 10).floor().isEven) return;
    canvas.save();
    canvas.rotate(atan2(_dir.y, _dir.x));
    final slab = RRect.fromRectAndRadius(
        Rect.fromLTRB(
            -halfWidth * .5, -halfWidth, _built + halfWidth * .5, halfWidth),
        Radius.circular(halfWidth * .6));
    canvas.drawRRect(slab.shift(const Offset(0, 4)),
        Paint()..color = const Color(0x33204050));
    canvas.drawRRect(slab, Paint()..color = const Color(0xE0D4F2FF));
    canvas.drawRRect(
        slab,
        Paint()
          ..color = const Color(0xFF7CC6EA)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5);
    // Plank joints and frosty highlights.
    final joint = Paint()
      ..color = const Color(0xAA8FCDEB)
      ..strokeWidth = 2;
    for (var x = 26.0; x < _built; x += 30) {
      canvas.drawLine(
          Offset(x, -halfWidth + 4), Offset(x - 4, halfWidth - 4), joint);
    }
    final shine = Paint()
      ..color = const Color(0xDDFFFFFF)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (var x = 8.0; x < _built - 10; x += 60) {
      canvas.drawLine(
          Offset(x, -halfWidth + 7), Offset(x + 16, -halfWidth + 7), shine);
    }
    // Cracks spread as it starts melting.
    if (left < 2) {
      final crack = Paint()
        ..color = const Color(0xCC4E9CC4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      final k = 1 - left / 2;
      for (var x = 40.0; x < _built; x += 70) {
        canvas.drawPath(
            Path()
              ..moveTo(x, -halfWidth * k)
              ..lineTo(x + 8, -4)
              ..lineTo(x - 4, 6)
              ..lineTo(x + 6, halfWidth * k),
            crack);
      }
    }
    canvas.restore();
  }
}
