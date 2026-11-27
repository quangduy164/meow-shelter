part of 'adventure_skills.dart';

// ===========================================================================
// Shadow: blink, decoy, time stop.
// ===========================================================================

/// Smoke where the cat left and where it arrived, joined by a fading trail.
class AdventureShadowStep extends PositionComponent {
  AdventureShadowStep({required Vector2 from, required Vector2 to})
      : _to = to - from,
        super(position: from.clone(), anchor: Anchor.center, priority: 7);

  final Vector2 _to;
  double _t = 0;
  static const double _life = .55;

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    if (_t > _life) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final k = (_t / _life).clamp(0.0, 1.0);
    final fade = 1 - k;
    final trail = Paint()
      ..color = _a(const Color(0xFF7B5FC4), .55 * fade)
      ..strokeWidth = 10 * fade + 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset.zero, Offset(_to.x, _to.y), trail);
    for (final end in [Offset.zero, Offset(_to.x, _to.y)]) {
      for (var i = 0; i < 6; i++) {
        final a = i * pi / 3 + k * 2;
        final r = 8 + 22 * k;
        canvas.drawCircle(
            end + Offset(cos(a) * r, sin(a) * r * .6 - 12),
            9 * fade + 3,
            Paint()..color = _a(const Color(0xFF3A2A6A), .7 * fade));
      }
      canvas.drawOval(
          Rect.fromCenter(
              center: end + const Offset(0, 6),
              width: 46 * (1 - k * .5),
              height: 14),
          Paint()..color = _a(const Color(0xFF1E1438), .6 * fade));
    }
  }
}

/// A ghostly copy of the cat that lures birds. When it fades it bursts and
/// shoves nearby hazards away ([HomeAttack.decoy] radius).
class AdventureDecoy extends SpriteAnimationGroupComponent<CatState> {
  AdventureDecoy({
    required Map<CatState, SpriteAnimation> animations,
    required Vector2 center,
    required this.flip,
  }) : super(
          animations: animations,
          current: CatState.idle,
          size: Vector2(catWidth, catHeight),
          position: center - Vector2(catWidth / 2, 52),
          priority: 5,
        ) {
    paint = Paint()
      ..colorFilter =
          const ColorFilter.mode(Color(0x887B5FC4), BlendMode.srcATop)
      ..color = const Color(0xBBFFFFFF);
  }

  final bool flip;
  double timeLeft = HomeAttack.decoy.duration;
  double timeScale = 1;
  bool recalled = false;
  bool empowered = false;
  double _t = 0;

  /// Where birds aim: the middle of its paws, like the real cat's hitbox.
  Vector2 get lureCenter => position + Vector2(catWidth / 2, 52);
  bool get expired => timeLeft <= 0;

  @override
  void update(double dt) {
    final elapsed = dt * timeScale;
    super.update(elapsed);
    _t += elapsed;
    timeLeft -= elapsed;
  }

  @override
  void render(Canvas canvas) {
    final c = Offset(size.x / 2, 56);
    // Lure rings pulsing out of the ground.
    for (var i = 0; i < 2; i++) {
      final k = ((_t * .9 + i * .5) % 1);
      canvas.drawOval(
          Rect.fromCenter(
              center: c,
              width: 30 + 90 * k,
              height: (30 + 90 * k) * groundSquash),
          Paint()
            ..color = _a(const Color(0xFFB9A2FF), .7 * (1 - k))
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
    }
    canvas.drawOval(Rect.fromCenter(center: c, width: 40, height: 12),
        Paint()..color = const Color(0x553A2A6A));
    if (timeLeft < 1 && (timeLeft * 10).floor().isEven) return;
    canvas.save();
    if (flip) {
      canvas.translate(size.x, 0);
      canvas.scale(-1, 1);
    }
    super.render(canvas);
    canvas.restore();
    // Wisps of shadow rising off it.
    for (var i = 0; i < 3; i++) {
      final k = (_t * .8 + i / 3) % 1;
      canvas.drawCircle(
          Offset(size.x / 2 + sin(_t * 3 + i * 2) * 14, 60 - 50 * k),
          5 * (1 - k) + 1,
          Paint()..color = _a(const Color(0xFF5B4A9E), .6 * (1 - k)));
    }
  }
}

/// The clock ring that sweeps out from the cat when time stops, then a small
/// clock above its head counting down while hazards stand still.
class AdventureTimeStopAura extends Component {
  AdventureTimeStopAura() : super(priority: 8);

  Vector2 center = Vector2.zero();
  double timeLeft = 0;
  double _since = 99;

  void start() => _since = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _since += dt;
  }

  @override
  void render(Canvas canvas) {
    final c = Offset(center.x, center.y);
    if (_since < .6) {
      final k = _since / .6;
      final r = 40 + 700 * (1 - (1 - k) * (1 - k));
      final ring = Paint()
        ..color = _a(const Color(0xFFCFE6FF), 1 - k)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6;
      canvas.drawCircle(c, r, ring);
      for (var i = 0; i < 12; i++) {
        final a = i * pi / 6;
        canvas.drawLine(c + Offset(cos(a), sin(a)) * (r - 14),
            c + Offset(cos(a), sin(a)) * r, ring..strokeWidth = 3);
      }
    }
    if (timeLeft <= 0) return;
    if (timeLeft < .8 && (timeLeft * 10).floor().isEven) return;
    final m = c + const Offset(0, -62);
    canvas.drawCircle(m, 13, Paint()..color = const Color(0xFFF2F7FF));
    canvas.drawCircle(
        m,
        13,
        Paint()
          ..color = const Color(0xFF3D6FA8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3);
    final share = timeLeft / HomeAttack.timeStop.duration;
    canvas.drawArc(Rect.fromCircle(center: m, radius: 9), -pi / 2,
        pi * 2 * share, true, Paint()..color = const Color(0x993D6FA8));
    canvas.drawLine(
        m,
        m + const Offset(0, -8),
        Paint()
          ..color = const Color(0xFF1F3A5C)
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round);
  }
}

/// Screen tint while time is stopped; drawn by the game over the world.
void paintTimeStopTint(Canvas canvas, Size size, double timeLeft) {
  if (timeLeft <= 0) return;
  final fadeIn = min(1.0, (HomeAttack.timeStop.duration - timeLeft) / .2);
  final fadeOut = min(1.0, timeLeft / .3);
  final k = min(fadeIn, fadeOut);
  final rect = Offset.zero & size;
  canvas.drawRect(rect, Paint()..color = _a(const Color(0xFF6C8FC0), .22 * k));
  canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(colors: [
          const Color(0x00000000),
          _a(const Color(0xFF1F3A5C), .45 * k),
        ], stops: const [
          .55,
          1
        ]).createShader(rect));
}
