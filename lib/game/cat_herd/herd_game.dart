import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/painting.dart';
import '../return_home/return_home_joystick.dart';
import 'herd_round.dart';
import 'herd_scene.dart';
import 'herd_map.dart';

/// Coordinates simulation, input and sprite rendering. Rules live in HerdRound.
class HerdGame extends FlameGame {
  final round = HerdRound();
  late ReturnHomeJoystick _joystick;
  final _walk = <String, SpriteAnimation>{};
  final _idle = <String, SpriteAnimation>{};
  bool _ready = false;
  bool pausedByApp = false;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    for (final type in ['orange', 'himalaya', 'scottish', 'calico', 'black']) {
      final folder = 'Cat/${type[0].toUpperCase()}${type.substring(1)}';
      for (final moving in [false, true]) {
        final img = await images
            .load('$folder/cat-$type-${moving ? 'walk' : 'idle'}.png');
        final animation = SpriteAnimation.fromFrameData(
            img,
            SpriteAnimationData.sequenced(
                amount: img.width ~/ img.height,
                stepTime: .12,
                textureSize: Vector2.all(img.height.toDouble())));
        (moving ? _walk : _idle)[type] = animation;
      }
    }
    _joystick = ReturnHomeJoystick(position: Vector2(85, size.y - 75));
    add(_joystick);
    _ready = true;
    round.reset(size);
    overlays.add('maps');
  }

  void chooseMap(HerdMap map) {
    round.map = map;
    round.reset(size);
    overlays.remove('maps');
    round.started = true;
    round.message(
        'Gom ít nhất ${HerdRound.requiredCats} bé để mở nhà. Theo dấu chân tới các cụm!');
  }

  void showMaps() {
    round.reset(size);
    overlays.remove('result');
    overlays.add('maps');
  }

  void restart() {
    round.reset(size);
    round.started = true;
    overlays.remove('result');
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (_ready) {
      _joystick.position.setValues(85, size.y - 75);
      // Scene coordinates depend on the viewport; restart after a resize.
      final running = round.started;
      round.reset(size);
      round.started = running;
      overlays.remove('result');
    }
  }

  @override
  void update(double dt) {
    if (pausedByApp) return;
    super.update(dt);
    if (!_ready) return;
    // Substeps keep collisions reliable after slow frames.
    var remaining = math.min(dt, .2);
    while (remaining > 0) {
      final step = math.min(remaining, 1 / 60);
      round.update(step, _joystick.relativeDelta);
      remaining -= step;
    }
    if (round.ended && !overlays.isActive('result')) overlays.add('result');
  }

  @override
  void render(Canvas canvas) {
    if (!_ready) return;
    paintHerdField(canvas, Size(size.x, size.y), round);
    for (final cat in round.cats.where((c) => !c.home)) {
      if (!cat.following) {
        canvas.drawCircle(
            cat.position.toOffset(),
            19,
            Paint()
              ..color = cat.scared > 0
                  ? const Color(0x44E97159)
                  : const Color(0x66FFF6CB));
      }
      _cat(canvas, cat.type, cat.position,
          moving: cat.following && cat.velocity.length > 2,
          leader: false,
          facingLeft: cat.facingLeft,
          hop: cat.hop,
          scared: cat.scared,
          resting: !cat.following);
      if (!cat.following &&
          cat.scared == 0 &&
          cat.id % 3 == 0 &&
          round.map.kind != HerdMapKind.snow) {
        final line = switch (round.map.kind) {
          HerdMapKind.nightMarket => 'Cá đâu?',
          HerdMapKind.dunes => 'Nóng quá!',
          HerdMapKind.playground => 'Brừm brừm!',
          HerdMapKind.snow => '',
        };
        final bubble = TextPainter(
            text: TextSpan(
                text: line,
                style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF5A3214),
                    fontWeight: FontWeight.bold)),
            textDirection: TextDirection.ltr)
          ..layout();
        final at =
            Offset(cat.position.x - bubble.width / 2, cat.position.y + 18);
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                (at & bubble.size).inflate(3), const Radius.circular(6)),
            Paint()..color = const Color(0xEEFFF4DA));
        bubble.paint(canvas, at);
      }
    }
    if (round.immune == 0 || (round.time * 10).floor().isEven) {
      _cat(canvas, 'orange', round.leader,
          moving: round.velocity.length > 2,
          leader: true,
          facingLeft: round.leaderFacingLeft);
    }
    super.render(canvas);
    final panel = RRect.fromRectAndRadius(
        Rect.fromLTWH(65, 9, size.x - 130, 36), const Radius.circular(12));
    canvas.drawRRect(panel, Paint()..color = const Color(0xEEFFF4DA));
    herdText(
        canvas,
        'ĐÀN ${round.chain.length}/${HerdRound.target} · MỞ NHÀ ${HerdRound.requiredCats} BÉ · MẠNG ${round.lives}',
        const Offset(78, 19),
        12);
    herdText(
        canvas,
        '${round.map.name}${round.map.kind == HerdMapKind.nightMarket ? (round.map.green(round.time) ? " · XE DỪNG ${(5 - round.time % 5).ceil()}s" : " · XE CHẠY ${(5 - round.time % 5).ceil()}s") : ""}',
        const Offset(78, 49),
        11);
    if (round.noticeTime > 0) {
      final text = TextPainter(
          text: TextSpan(
              text: round.notice,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5A3214))),
          textDirection: TextDirection.ltr)
        ..layout(maxWidth: size.x - 200);
      final at = Offset((size.x - text.width) / 2, size.y - text.height - 14);
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              (at & text.size).inflate(6), const Radius.circular(6)),
          Paint()..color = const Color(0xEEFFF4DA));
      text.paint(canvas, at);
    }
  }

  void _cat(Canvas canvas, String type, Vector2 at,
      {required bool moving,
      required bool leader,
      required bool facingLeft,
      double hop = 0,
      double scared = 0,
      bool resting = false}) {
    final animation = (moving ? _walk : _idle)[type]!;
    final frame =
        animation.frames[(round.time / .12).floor() % animation.frames.length];
    canvas.drawOval(
        Rect.fromCenter(
            center: at.toOffset() + const Offset(0, 12), width: 26, height: 9),
        Paint()..color = const Color(0x33402A14));
    canvas.save();
    final bounce = hop > 0 ? math.sin((.65 - hop) / .65 * math.pi) : 0.0;
    canvas.translate(at.x, at.y - bounce * 16);
    if (scared > 1.1) canvas.rotate((2 - scared) * math.pi * 5);
    if (resting && scared == 0) {
      canvas.rotate(math.sin(round.time * 1.3 + at.x) * .10);
      if (round.map.kind == HerdMapKind.dunes) {
        canvas.translate(0, 9);
        canvas.clipRect(const Rect.fromLTWH(-30, -30, 60, 30));
      }
    }
    canvas.scale(1 + bounce * .12, 1 - bounce * .1);
    if (facingLeft) canvas.scale(-1, 1);
    frame.sprite
        .render(canvas, position: Vector2.all(-25), size: Vector2.all(50));
    canvas.restore();
    if (scared > 0) {
      for (var i = 0; i < 3; i++) {
        final angle = round.time * 6 + i * math.pi * 2 / 3;
        canvas.drawCircle(
            Offset(
                at.x + math.cos(angle) * 13, at.y - 25 + math.sin(angle) * 4),
            2.5,
            Paint()..color = const Color(0xFFFFD258));
      }
    } else if (resting && round.map.kind == HerdMapKind.snow) {
      herdText(canvas, 'zZ', Offset(at.x + 10, at.y - 28), 11);
    }
    if (leader) {
      canvas.drawPath(
          Path()
            ..moveTo(at.x - 7, at.y - 25)
            ..lineTo(at.x, at.y - 19)
            ..lineTo(at.x + 7, at.y - 25)
            ..close(),
          Paint()..color = const Color(0xFFDCA62F));
    }
  }
}
