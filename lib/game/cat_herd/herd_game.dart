import '../../ui/design.dart';
import 'dart:async';
import 'dart:ui' as ui;
import '../../audio/game_audio.dart';
import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/painting.dart';
import '../adventure/adventure_joystick.dart';
import 'herd_round.dart';
import 'herd_scene.dart';
import 'herd_map.dart';
import 'herd_text_cache.dart';
import 'herd_hud.dart';
import 'herd_market_painter.dart';
import 'herd_desert_painter.dart';
import 'herd_snow_painter.dart';
import 'herd_trait_painter.dart';
import '../../camp/camp_resident.dart' show campSleepFrames;
import 'herd_home_painter.dart';

/// Coordinates simulation, input and sprite rendering. Rules live in HerdRound.
class HerdGame extends FlameGame {
  HerdGame(
      {this.needsTutorial = false,
      this.onTutorialCompleted,
      this.introSeen,
      this.onIntroSeen});
  final bool needsTutorial;

  /// First map with special cats shows who they are before play starts.
  final bool Function(String key)? introSeen;
  final Future<void> Function(String key)? onIntroSeen;
  final Future<void> Function()? onTutorialCompleted;
  late final round = HerdRound(onSound: _playSound);

  void _playSound(HerdSound event) {
    final (sound, priority) = switch (event) {
      HerdSound.joined => (GameSound.herdJoin, 0),
      HerdSound.ready => (GameSound.homeCheckpoint, 2),
      HerdSound.locked => (GameSound.catWrong, 1),
      HerdSound.hit => (GameSound.homeHit, 3),
      HerdSound.scattered => (GameSound.catStartle, 2),
      HerdSound.bounced => (GameSound.herdBounce, 0),
      HerdSound.vendor => (GameSound.herdVendor, 2),
      HerdSound.storm => (GameSound.herdStorm, 2),
      HerdSound.overheated => (GameSound.herdTired, 2),
      HerdSound.iceWarning => (GameSound.homeIce, 2),
      HerdSound.iceBreak => (GameSound.herdIceBreak, 3),
      HerdSound.cuckoo => (GameSound.homeCheckpoint, 2),
      HerdSound.stuck => (GameSound.catWrong, 2),
      HerdSound.horn => (GameSound.homeImpact, 3),
      HerdSound.doors => (GameSound.homeCheckpoint, 1),
    };
    GameAudio.instance.playGameplay(sound, priority: priority);
  }

  late AdventureJoystick _joystick;

  /// Device safe area; the Flutter Home button sits inside it, so the HUD
  /// and joystick drawn on the canvas must be inset by the same amount.
  EdgeInsets _safe = EdgeInsets.zero;
  EdgeInsets get safeArea => _safe;
  set safeArea(EdgeInsets value) {
    if (value == _safe) return;
    _safe = value;
    if (_ready) _joystick.position.setFrom(_joystickAt);
  }

  Vector2 get _joystickAt =>
      Vector2(85 + _safe.left, size.y - 75 - _safe.bottom);
  final _walk = <String, SpriteAnimation>{};
  final _idle = <String, SpriteAnimation>{};
  bool _ready = false;
  bool pausedByApp = false;
  ui.Image? _background;
  ui.Picture? _home;
  HerdMap? _cachedMap;
  Size? _cachedSize;

  void _cacheScenery(Size viewport) {
    if (_background != null &&
        _cachedMap == round.map &&
        _cachedSize == viewport) {
      return;
    }
    _background?.dispose();
    _home?.dispose();
    final ratio =
        (ui.PlatformDispatcher.instance.implicitView?.devicePixelRatio ?? 2.0)
            .clamp(1.0, 3.0);
    _background = renderHerdBackground(viewport, round, ratio);
    final home = ui.PictureRecorder();
    paintHerdHome(Canvas(home), round.home.toOffset(), round.map.kind);
    _home = home.endRecording();
    _cachedMap = round.map;
    _cachedSize = viewport;
  }

  @override
  void onRemove() {
    _background?.dispose();
    _home?.dispose();
    _background = _home = null;
    super.onRemove();
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // Decode all ten sheets at once; one after another kept the screen blank
    // for the sum of every load.
    Future<void> loadSheet(String type, bool moving) async {
      final folder = 'Cat/${type[0].toUpperCase()}${type.substring(1)}';
      final img = await images
          .load('$folder/cat-$type-${moving ? 'walk' : 'idle'}.png');
      (moving ? _walk : _idle)[type] = SpriteAnimation.fromFrameData(
          img,
          SpriteAnimationData.sequenced(
              amount: img.width ~/ img.height,
              stepTime: .12,
              textureSize: Vector2.all(img.height.toDouble())));
    }

    await Future.wait([
      for (final type in ['orange', 'himalaya', 'scottish', 'calico', 'black'])
        for (final moving in [false, true]) loadSheet(type, moving),
    ]);
    _joystick = AdventureJoystick(position: _joystickAt);
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
    final key = map.introKey;
    if (key != null && introSeen != null && !introSeen!(key)) {
      overlays.add('traits');
      return;
    }
    round.started = true;
    if (!round.isTutorial) {
      round.message(map.hint, 5);
    }
  }

  void closeIntro() {
    final key = round.map.introKey, seen = onIntroSeen;
    if (key != null && seen != null) unawaited(seen(key));
    overlays.remove('traits');
    round.started = true;
    round.message(round.map.hint, 5);
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
      _joystick.position.setFrom(_joystickAt);
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
      GameAudio.instance.playGameplay(
          round.won ? GameSound.herdWin : GameSound.herdLose,
          priority: 4);
      if (round.isTutorial && round.won && onTutorialCompleted != null) {
        unawaited(onTutorialCompleted!());
      }
      overlays.add('result');
    }
  }

  @override
  void render(Canvas canvas) {
    if (!_ready) return;
    final viewport = Size(size.x, size.y);
    _cacheScenery(viewport);
    paintHerdField(canvas, viewport, round,
        background: _background, home: _home);
    if (round.isTutorial && !round.ended && round.tutorialStep > 1) {
      _tutorialGuide(canvas);
    }
    final visible = round.cats.where((c) => !c.home).toList();
    // Ground rings first, so no ring is drawn over a cat.
    for (final cat in visible) {
      if (cat.following) continue;
      _ring.color = cat.scared > 0 ? const Color(0x44E97159) : traitRing(cat);
      canvas.drawCircle(cat.position.toOffset(), 19, _ring);
    }
    // Depth order: lower on screen is nearer, so it is drawn last. Without
    // this, walking up or down made overlapping cats pop in front/behind.
    visible.sort((a, b) => a.position.y.compareTo(b.position.y));
    var leaderDrawn = false;
    for (final cat in visible) {
      if (!leaderDrawn && round.leader.y < cat.position.y) {
        _drawLeader(canvas);
        leaderDrawn = true;
      }
      _cat(canvas, cat.type, cat.position,
          moving:
              (cat.following && cat.velocity.length > 2) || cat.distracted > 0,
          leader: false,
          facingLeft: cat.facingLeft,
          hop: cat.hop,
          tumble: cat.tumble,
          scared: cat.scared,
          resting: !cat.following && cat.distracted == 0,
          asleep: !cat.awake && !cat.following,
          shiver: cat.chill > 0 || cat.hidden,
          scale: cat.trait == HerdTrait.chubby ? HerdTraits.chubbyScale : 1,
          buried: (round.map.kind == HerdMapKind.dunes && cat.group == 2) ||
              cat.hidden);
      if (round.map.kind == HerdMapKind.dunes) paintCatHeat(canvas, cat);
      paintCatChill(canvas, cat, round.time);
      paintCatTrait(canvas, cat, round.time);
    }
    if (!leaderDrawn) _drawLeader(canvas);
    paintMarketDarkness(canvas, round);
    if (round.map.kind == HerdMapKind.dunes && round.started) {
      paintDesertStorm(canvas, Size(size.x, size.y), round);
    }
    super.render(canvas);
    if (round.isTutorial && !round.ended && round.tutorialStep == 1) {
      _tutorialGuide(canvas);
    }
    paintHerdHud(canvas, Size(size.x, size.y), round, _safe);
    // Just the one-line hint at the start of a map; in-play status messages
    // are not shown.
    if (round.noticeTime > 0 &&
        !round.isTutorial &&
        round.notice == round.map.hint) {
      final text = herdLabel(round.notice, DS.fontBody, const Color(0xFF5A3214),
          weight: FontWeight.bold,
          maxWidth: math.min(560.0,
                  size.x - _safe.horizontal - round.map.topRowStart - 12) -
              24);
      // Top row, centred in the space right of the Home button and life pill
      // (same slot as the tutorial caption in paintHerdHud).
      final centerX =
          (round.map.topRowStart + _safe.left + size.x - _safe.right - 12) / 2;
      final at =
          Offset(centerX - text.width / 2, 36 + _safe.top - text.height / 2);
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              (at & text.size).inflate(6), const Radius.circular(6)),
          Paint()..color = const Color(0xEEFFF4DA));
      text.paint(canvas, at);
    }
  }

  final _ring = Paint();

  void _drawLeader(Canvas canvas) {
    if (round.immune > 0 && (round.time * 10).floor().isOdd) return;
    _cat(canvas, 'orange', round.leader,
        moving: round.velocity.length > 2,
        leader: true,
        facingLeft: round.leaderFacingLeft,
        tumble: round.landingTime);
  }

  void _tutorialGuide(Canvas canvas) {
    final radius = 4 * math.sin(round.time * 4);
    final guide = Paint()
      ..color = const Color(0xCCDF9F3E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    switch (round.tutorialStep) {
      case 1:
        canvas.drawCircle(_joystickAt.toOffset(), 65 + radius, guide);
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
      bool shiver = false,
      bool asleep = false,
      double scale = 1}) {
    final animation = (moving ? _walk : _idle)[type]!;
    // Napping holds the closed-eye idle frame, exactly like the camp.
    final frame = asleep
        ? _idle[type]!.frames[campSleepFrames[type] ?? 0]
        : animation
            .frames[(round.time / .12).floor() % animation.frames.length];
    canvas.drawOval(
        Rect.fromCenter(
            center: at.toOffset() + const Offset(0, 12),
            width: 26 * scale,
            height: 9 * scale),
        Paint()..color = const Color(0x33402A14));
    canvas.save();
    final bounce = hop > 0 ? math.sin((.65 - hop) / .65 * math.pi) : 0.0;
    canvas.translate(at.x + (shiver ? math.sin(round.time * 45) * 1.5 : 0),
        at.y - bounce * 16);
    if (tumble > 0) canvas.rotate(math.sin((.65 - tumble) * 14) * tumble * .8);
    if (scared > 1.1) canvas.rotate((2 - scared) * math.pi * 5);
    if (asleep) {
      // Slow breathing: the body swells a little, feet stay on the ground.
      final breath = 1 + .03 * math.sin(round.time * 2.2 + at.x);
      canvas.translate(0, 25 * scale);
      canvas.scale(1, breath);
      canvas.translate(0, -25 * scale);
    } else if (resting && scared == 0) {
      canvas.rotate(math.sin(round.time * 1.3 + at.x) * .10);
      if (buried) {
        canvas.translate(0, 9);
        canvas.clipRect(const Rect.fromLTWH(-30, -30, 60, 30));
      }
    }
    canvas.scale((1 + bounce * .12) * scale * (scale > 1 ? 1.08 : 1),
        (1 - bounce * .1) * scale);
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
