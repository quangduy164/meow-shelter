import 'dart:async';
import '../../audio/game_audio.dart';
import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/painting.dart';
import '../return_home/return_home_joystick.dart';
import 'herd_round.dart';
import 'herd_scene.dart';
import 'herd_map.dart';
import 'herd_hud.dart';
import 'herd_market_painter.dart';
import 'herd_desert_painter.dart';
import 'herd_snow_painter.dart';

/// Coordinates simulation, input and sprite rendering. Rules live in HerdRound.
class HerdGame extends FlameGame {
  HerdGame({this.needsTutorial = false, this.onTutorialCompleted});
  final bool needsTutorial;
  final Future<void> Function()? onTutorialCompleted;
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
    if (needsTutorial) {
      chooseMap(HerdMap.tutorial);
    } else {
      overlays.add('maps');
    }
  }

  void chooseMap(HerdMap map) {
    round.map = map;
    round.reset(size);
    overlays.remove('maps');
    round.started = true;
    if (!round.isTutorial) {
      round.message(map.hint, 5);
    }
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
      // Overlay/layout rebuilds can report the same size again after a win.
      // Preserve the run and its result even when the viewport really changes.
      round.resize(size);
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
    if (round.ended && !overlays.isActive('result')) {
      GameAudio.instance.play(round.won ? GameSound.win : GameSound.lose);
      if (round.isTutorial && round.won && onTutorialCompleted != null) {
        unawaited(onTutorialCompleted!());
      }
      overlays.add('result');
    }
  }

  @override
  void render(Canvas canvas) {
    if (!_ready) return;
    paintHerdField(canvas, Size(size.x, size.y), round);
    if (round.isTutorial && !round.ended && round.tutorialStep > 1) {
      _tutorialGuide(canvas);
    }
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
          tumble: cat.tumble,
          scared: cat.scared,
          resting: !cat.following,
          shiver: cat.chill > 0,
          buried: round.map.kind == HerdMapKind.dunes && cat.group == 2);
      if (round.map.kind == HerdMapKind.dunes) paintCatHeat(canvas, cat);
      paintCatChill(canvas, cat, round.time);
    }
    if (round.immune == 0 || (round.time * 10).floor().isEven) {
      _cat(canvas, 'orange', round.leader,
          moving: round.velocity.length > 2,
          leader: true,
          facingLeft: round.leaderFacingLeft,
          tumble: round.landingTime);
    }
    paintMarketDarkness(canvas, round);
    if (round.map.kind == HerdMapKind.dunes && round.started) {
      paintDesertStorm(canvas, Size(size.x, size.y), round);
    }
    super.render(canvas);
    if (round.isTutorial && !round.ended && round.tutorialStep == 1) {
      _tutorialGuide(canvas);
    }
    paintHerdHud(canvas, Size(size.x, size.y), round);
    if (round.noticeTime > 0 && !round.isTutorial) {
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

  void _tutorialGuide(Canvas canvas) {
    final radius = 4 * math.sin(round.time * 4);
    final guide = Paint()
      ..color = const Color(0xCCDF9F3E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    switch (round.tutorialStep) {
      case 1:
        canvas.drawCircle(Offset(85, size.y - 75), 65 + radius, guide);
      case 2:
        for (final cat in round.cats.where((c) => !c.following)) {
          canvas.drawCircle(cat.position.toOffset(), 25 + radius, guide);
        }
      case 3:
        canvas.drawCircle(round.home.toOffset(), 43 + radius, guide);
    }
  }

  void _cat(Canvas canvas, String type, Vector2 at,
      {required bool moving,
      required bool leader,
      required bool facingLeft,
      double hop = 0,
      double tumble = 0,
      double scared = 0,
      bool resting = false,
      bool buried = false,
      bool shiver = false}) {
    final animation = (moving ? _walk : _idle)[type]!;
    final frame =
        animation.frames[(round.time / .12).floor() % animation.frames.length];
    canvas.drawOval(
        Rect.fromCenter(
            center: at.toOffset() + const Offset(0, 12), width: 26, height: 9),
        Paint()..color = const Color(0x33402A14));
    canvas.save();
    final bounce = hop > 0 ? math.sin((.65 - hop) / .65 * math.pi) : 0.0;
    canvas.translate(at.x + (shiver ? math.sin(round.time * 45) * 1.5 : 0),
        at.y - bounce * 16);
    if (tumble > 0) canvas.rotate(math.sin((.65 - tumble) * 14) * tumble * .8);
    if (scared > 1.1) canvas.rotate((2 - scared) * math.pi * 5);
    if (resting && scared == 0) {
      canvas.rotate(math.sin(round.time * 1.3 + at.x) * .10);
      if (buried) {
        canvas.translate(0, 9);
        canvas.clipRect(const Rect.fromLTWH(-30, -30, 60, 30));
      }
    }
    canvas.scale(1 + bounce * .12, 1 - bounce * .1);
    if (facingLeft) canvas.scale(-1, 1);
    frame.sprite
        .render(canvas, position: Vector2.all(-25), size: Vector2.all(50));
    canvas.restore();
    if (round.map.kind == HerdMapKind.snow && hop > 0) {
      final progress = (.65 - hop) / .65;
      for (var i = 0; i < 4; i++) {
        final angle = i * math.pi / 2;
        canvas.drawCircle(
            Offset(at.x + math.cos(angle) * (10 + progress * 15),
                at.y + 8 + math.sin(angle) * 6),
            3 * (1 - progress),
            Paint()..color = const Color(0xBBFFFFFF));
      }
    }
    if (scared > 0) {
      for (var i = 0; i < 3; i++) {
        final angle = round.time * 6 + i * math.pi * 2 / 3;
        canvas.drawCircle(
            Offset(
                at.x + math.cos(angle) * 13, at.y - 25 + math.sin(angle) * 4),
            2.5,
            Paint()..color = const Color(0xFFFFD258));
      }
    } else if (resting && !shiver && round.map.kind == HerdMapKind.snow) {
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
