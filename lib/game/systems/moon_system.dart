import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

import '../../audio/game_audio.dart';
import '../components/cat_component.dart';
import '../world/shelter_map.dart';

class _Print {
  _Print(this.at, this.angle, this.delay);
  final Vector2 at;
  final double angle, delay;
}

class _Phantom {
  _Phantom(this.cat);
  final CatComponent cat;
  double stay = MoonSystem.phantomStay;
  double jump = -1;
  final from = Vector2.zero(), to = Vector2.zero();
  final prints = <_Print>[];
  double printAge = 0;
}

/// Chapter 5 attic: moonbeam pools drift with the clouds and are now and
/// then covered. Black cats only come out to eat fish lying in moonlight,
/// and only show up inside it. The boss jumps between dark corners, leaving
/// paw prints that point to where it will appear.
class MoonSystem {
  MoonSystem(this.map);
  final ShelterMap map;
  Vector2 _size = Vector2.zero();
  double _clock = 0;
  final _phantoms = <_Phantom>[];
  final _random = Random();
  final _visibleCats = <CatComponent>{};

  static const drift = .10, driftPeriod = 18.0;
  static const cloudPeriod = 13.0, cloudSeconds = 3.5, fade = .8;
  static const phantomStay = 7.0, jumpSeconds = 1.6;

  /// Brightness 0..1 of beam [i]: a passing cloud dims it for a while.
  double brightness(int i) => _brightnessAt(i, _clock);

  double _brightnessAt(int i, double clock) {
    final t = (clock + i * 4.3) % cloudPeriod;
    if (t > cloudSeconds) return 1;
    if (t < fade) return 1 - t / fade;
    if (t > cloudSeconds - fade) return (t - (cloudSeconds - fade)) / fade;
    return 0;
  }

  /// Seconds until beam [i] is covered, for the warning flicker.
  double untilCloud(int i) => cloudPeriod - (_clock + i * 4.3) % cloudPeriod;

  Rect beam(int i) {
    final base = map.moonbeams[i];
    final dx = sin(_clock * 2 * pi / driftPeriod + i * 2.1) * drift;
    return Rect.fromLTWH((base.left + dx) * _size.x, base.top * _size.y,
        base.width * _size.x, base.height * _size.y);
  }

  bool _inside(Rect r, Vector2 p) {
    final dx = (p.x - r.center.dx) / (r.width / 2);
    final dy = (p.y - r.center.dy) / (r.height / 2);
    return dx * dx + dy * dy <= 1;
  }

  /// Whether [p] stands in a moonbeam that is bright enough to count.
  bool lit(Vector2 p) {
    for (var i = 0; i < map.moonbeams.length; i++) {
      if (brightness(i) > .5 && _inside(beam(i), p)) return true;
    }
    return false;
  }

  void update(double dt, Vector2 size, Iterable<CatComponent> cats) {
    _size = size;
    final previousClock = _clock;
    _clock += dt;
    _visibleCats.removeWhere((cat) => !cat.isMounted || cat.isDelivered);
    for (var i = 0; i < map.moonbeams.length; i++) {
      if (_brightnessAt(i, previousClock) > .5 &&
          brightness(i) <= .5 &&
          cats.any((cat) =>
              cat.catType == 'black' &&
              cat.isLoaded &&
              !cat.isDelivered &&
              !cat.isCarried &&
              !cat.hiddenInCover &&
              _inside(beam(i), cat.center))) {
        GameAudio.instance.playRescue(GameSound.moonCloud);
        break;
      }
    }
    _phantoms.removeWhere((p) => !p.cat.isMounted || p.cat.isDelivered);
    for (final cat in cats) {
      if (cat.isBoss &&
          cat.catType == 'black' &&
          cat.isLoaded &&
          !_phantoms.any((p) => p.cat == cat)) {
        _phantoms.add(_Phantom(cat));
      }
    }
    for (final p in _phantoms) {
      p.printAge += dt;
      final cat = p.cat;
      if (p.jump >= 0) {
        p.jump += dt;
        if (p.jump >= jumpSeconds) {
          p.jump = -1;
          p.stay = phantomStay;
          cat.emergeFromCover(p.to - cat.size / 2, line: 'Hù! Ở đây nè!');
        }
        continue;
      }
      final busy = cat.fishTarget != null ||
          cat.hasEaten ||
          cat.catchWindow.canCatch ||
          cat.isCarried;
      if (busy) {
        p.stay = phantomStay;
        continue;
      }
      p.stay -= dt;
      if (p.stay <= 0) _startJump(p, cats);
    }
    for (final cat in cats) {
      if (cat.catType != 'black' || !cat.isLoaded || cat.isDelivered) continue;
      if (!cat.hiddenInCover && lit(cat.center)) {
        if (_visibleCats.add(cat) && !cat.isLit && !cat.hasEaten) {
          GameAudio.instance.playRescue(GameSound.moonReveal);
        }
      } else {
        _visibleCats.remove(cat);
      }
    }
  }

  void _startJump(_Phantom p, Iterable<CatComponent> cats) {
    final cat = p.cat;
    p.from.setFrom(cat.center);
    Vector2? best;
    for (var i = 0; i < 30; i++) {
      final spot = Vector2(_size.x * (.22 + _random.nextDouble() * .56),
          _size.y * (.34 + _random.nextDouble() * .4));
      if (spot.distanceTo(p.from) < 180 || lit(spot)) continue;
      if (cats.any((c) => c != cat && c.center.distanceTo(spot) < 90)) {
        continue;
      }
      best = spot;
      break;
    }
    if (best == null) {
      p.stay = 2;
      return;
    }
    p.to.setFrom(best);
    p.jump = 0;
    p.printAge = 0;
    p.prints.clear();
    final delta = p.to - p.from;
    final steps = max(4, (delta.length / 36).floor());
    final angle = atan2(delta.y, delta.x);
    for (var i = 1; i <= steps; i++) {
      final along = p.from + delta * (i / (steps + 1));
      final side = Vector2(-sin(angle), cos(angle)) * (i.isEven ? 6 : -6);
      p.prints.add(_Print(along + side, angle, jumpSeconds * i / (steps + 1)));
    }
    cat.hideInCover(cat.position.clone());
  }

  static final _hole = Paint()
    ..blendMode = BlendMode.dstOut
    ..shader = Gradient.radial(Offset.zero, 1, const [
      Color(0xFF000000),
      Color(0xDD000000),
      Color(0x00000000),
    ], const [
      0,
      .6,
      1
    ]);

  /// Cuts the moon pools out of the darkness layer.
  void cutLight(Canvas canvas, Size size) {
    // The round window itself always shows the night sky.
    final window =
        Offset(map.moonWindow.dx * _size.x, map.moonWindow.dy * _size.y + 6);
    canvas
      ..save()
      ..translate(window.dx, window.dy)
      ..scale(46);
    _hole.color = const Color(0xFF000000);
    canvas
      ..drawCircle(Offset.zero, 1, _hole)
      ..restore();
    for (var i = 0; i < map.moonbeams.length; i++) {
      final b = brightness(i);
      if (b <= 0) continue;
      final r = beam(i);
      canvas
        ..save()
        ..translate(r.center.dx, r.center.dy)
        ..scale(r.width / 2 * (.85 + .15 * b), r.height / 2 * (.85 + .15 * b));
      _hole.color = Color.fromRGBO(0, 0, 0, b);
      canvas
        ..drawCircle(Offset.zero, 1, _hole)
        ..restore();
    }
  }

  /// Moon shafts from the window, cool tint on the pools, and paw prints.
  void render(Canvas canvas) {
    for (var i = 0; i < map.moonbeams.length; i++) {
      final b = brightness(i);
      final r = beam(i);
      final warn = untilCloud(i) < 1.5 ? .5 + .5 * sin(_clock * 12) : 1.0;
      if (b > 0) {
        final top =
            Offset(map.moonWindow.dx * _size.x, map.moonWindow.dy * _size.y);
        canvas.drawPath(
            Path()
              ..moveTo(top.dx - 14, top.dy)
              ..lineTo(top.dx + 14, top.dy)
              ..lineTo(r.right - r.width * .1, r.center.dy)
              ..lineTo(r.left + r.width * .1, r.center.dy)
              ..close(),
            Paint()..color = Color.fromRGBO(190, 215, 255, .07 * b));
        canvas.drawOval(
            r, Paint()..color = Color.fromRGBO(170, 200, 255, .16 * b * warn));
        canvas.drawOval(
            r.deflate(3),
            Paint()
              ..color = Color.fromRGBO(220, 235, 255, .35 * b * warn)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5);
      }
    }
    for (final p in _phantoms) {
      for (final print in p.prints) {
        final shown = p.jump >= 0 ? p.jump >= print.delay : true;
        if (!shown) continue;
        final age = p.jump >= 0 ? 0.0 : p.printAge;
        final alpha = (1 - age / 2.5).clamp(0.0, 1.0);
        if (alpha <= 0) continue;
        _paw(canvas, print.at.toOffset(), print.angle,
            Color.fromRGBO(186, 160, 255, .85 * alpha));
      }
      if (p.jump >= 0) {
        // A faint swirl where the boss is about to appear.
        final k = p.jump / jumpSeconds;
        canvas.drawCircle(
            p.to.toOffset(),
            10 + 18 * k,
            Paint()
              ..color = Color.fromRGBO(186, 160, 255, .6 * k)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.5);
      }
    }
  }

  void _paw(Canvas canvas, Offset at, double angle, Color color) {
    final paint = Paint()..color = color;
    canvas.save();
    canvas.translate(at.dx, at.dy);
    canvas.rotate(angle + pi / 2);
    canvas.drawOval(
        Rect.fromCenter(center: const Offset(0, 2), width: 8, height: 7),
        paint);
    for (final d in [
      const Offset(-4, -4),
      const Offset(0, -6),
      const Offset(4, -4)
    ]) {
      canvas.drawCircle(d, 1.8, paint);
    }
    canvas.restore();
  }
}
