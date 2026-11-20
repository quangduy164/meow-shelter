import 'fishing_river.dart';
import '../camp/camp_state.dart';
import '../audio/game_audio.dart';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../collection/fish_collection.dart';
import '../collection/fish_species.dart';

enum FishingPhase {
  ready,
  casting,
  waiting,
  bite,
  reeling,
  saving,
  caught,
  lost
}

class FishingController extends ChangeNotifier {
  FishingController(this.collection, {math.Random? random})
      : _random = random ?? math.Random();

  final FishCollection collection;
  final math.Random _random;
  final river = FishingRiverRound();
  static const boatGuideKey = 'mode:fishing:boat:v1';
  bool get beginner => !CampState.instance.seenGuides.contains(boatGuideKey);
  bool get canSail =>
      _phase == FishingPhase.ready || _phase == FishingPhase.lost;
  bool get surging => _surging;
  String get guide => switch (_phase) {
        FishingPhase.ready => river.moving
            ? 'Đang chèo · Bấm cần câu góc phải để câu tại đây'
            : 'Bấm mặt nước để chèo · Bấm cần câu góc phải để câu',
        FishingPhase.casting => 'Mèo đang thả cần…',
        FishingPhase.waiting => 'Chờ phao động rồi bấm giật cần',
        FishingPhase.bite => 'Cá cắn! Bấm nút giật cần!',
        FishingPhase.reeling => river.hitTime > .8
            ? 'Vướng bờ rồi! Vuốt lái thuyền ra giữa sông'
            : _surging
                ? 'Cá vùng! Thả nút kéo · Vuốt để lái thuyền'
                : 'Cá mệt! Giữ nút kéo · Vuốt để lái thuyền',
        FishingPhase.saving => _error ?? 'Đang cất cá vào giỏ…',
        FishingPhase.caught => message,
        FishingPhase.lost =>
          '${_error ?? "Cá thoát rồi"} · Bấm cần câu để thử lại',
      };

  void tapRiver(Offset screen) {
    if (_phase == FishingPhase.saving || _phase == FishingPhase.caught) return;
    final point = river.toWorld(screen);
    if (!FishingRiver.contains(point)) return;
    if (active) cancelCast();
    if (_phase == FishingPhase.lost) {
      _error = null;
      _setPhase(FishingPhase.ready);
    }
    river.sailTo(point);
    notifyListeners();
  }

  void steerBoat(Offset delta) {
    if (_phase == FishingPhase.reeling) river.steer(delta);
  }

  void stopSteering() => river.steering = Offset.zero;

  void cancelNavigation() {
    river.stop();
  }

  void cancelCast() {
    if (!active || _phase == FishingPhase.saving) return;
    cancelNavigation();
    _error = null;
    _setPhase(FishingPhase.ready);
    notifyListeners();
  }

  FishSpecies _fish = FishSpecies.tilapia;
  FishSpecies get fish => _fish;
  FishingPhase _phase = FishingPhase.ready;
  Offset _spot = const Offset(.5, .66);
  Offset _castOffset = const Offset(280, -25);
  double _hookProgress = .16;
  double _clock = 0, _elapsed = 0, _wait = 0;
  double _tension = .32, _progress = .12, _fight = 0;
  double _drift = 0;
  double _sweetCenter = .45, _comboTime = 0;
  int _combo = 0;
  double _worldHour = 12;
  bool _pulling = false, _savingCatch = false, _disposed = false;
  bool _tensionWarned = false;
  String? _error;

  FishingPhase get phase => _phase;
  Offset get spot {
    if (_phase != FishingPhase.reeling) return _spot;
    final reeled =
        ((_progress - _hookProgress) / (1 - _hookProgress)).clamp(0.0, 1.0);
    final startDistance = _castOffset.distance;
    final distance = startDistance + (95 - startDistance) * reeled;
    // Steering changes boat motion, never teleports the fish behind the cat.
    return FishingRiver.constrain(
        river.boat + _castOffset / startDistance * distance);
  }

  double get drift => _drift;
  double get sweetCenter => _sweetCenter;
  static const sweetWidth = .16;
  int get combo => _combo;
  bool get inSweetZone => (_tension - _sweetCenter).abs() <= sweetWidth / 2;
  double get clock => _clock;
  double get elapsed => _elapsed;
  double get tension => _tension;
  double get progress => _progress;
  bool get pulling => _pulling;
  String? get error => _error;
  bool get active => const [
        FishingPhase.casting,
        FishingPhase.waiting,
        FishingPhase.bite,
        FishingPhase.reeling,
        FishingPhase.saving
      ].contains(_phase);
  bool get _surging => _surge > .6;

  /// 0..1 fight strength; each species has its own readable rhythm.
  double get _surge {
    final t = _elapsed + _fight;
    return switch (_fish) {
      // Short, frequent jerks.
      FishSpecies.perch => math.sin(t * 7).abs() > .8 ? 1.0 : .25,
      // Strong but steady.
      FishSpecies.carp => .55 + math.sin(t * 1.2) * .1,
      // Quiet, then a hard dive every few seconds.
      FishSpecies.catfish => (t % 3.2) < .7 ? 1.0 : .2,
      // Gentle pull; it mostly changes direction.
      FishSpecies.goldfish => .35,
      FishSpecies.sardine => .25 + math.sin(t * 3).abs() * .25,
      FishSpecies.mackerel => t % 2.6 < .5 ? 1.0 : .25,
      FishSpecies.clownfish => .3 + math.sin(t * 2.8).abs() * .3,
      FishSpecies.pufferfish => t % 4.2 < 1.1 ? 1.0 : .15,
      FishSpecies.koi => .4 + math.sin(t * 2) * .2,
      // Pretends to be tired, then bursts.
      FishSpecies.catMew => (t % 4.5) > 3.6 ? 1.0 : .1,
      _ => .45 + math.sin(t * 2.5) * .2,
    };
  }

  void setWorldHour(double hour) => _worldHour = hour;

  void _vibrate(Future<void> Function() feedback) {
    if (!_disposed && GameAudio.instance.vibrationEnabled.value) feedback();
  }

  String get message => switch (_phase) {
        FishingPhase.ready => 'SÔNG CÂU',
        FishingPhase.casting => 'Đang thả câu',
        FishingPhase.waiting => 'Chờ cá cắn…',
        FishingPhase.bite => 'CÁ CẮN!',
        FishingPhase.reeling => _surging ? 'Cá đang vùng mạnh!' : 'Đang kéo cá',
        FishingPhase.saving => _error ?? 'Đang lưu cá…',
        FishingPhase.caught => _fish.isJunk
            ? 'Ối! Câu được ${_fish.label.toLowerCase()}'
            : '+1 ${_fish.label} · Đã vào giỏ cá',
        FishingPhase.lost => _error ?? 'Cá đã thoát',
      };

  void _setPhase(FishingPhase phase) {
    GameAudio.instance.setFishingReeling(false);
    final sound = switch (phase) {
      FishingPhase.casting => GameSound.fishingCast,
      FishingPhase.bite => GameSound.fishingBite,
      FishingPhase.reeling => GameSound.fishingHook,
      FishingPhase.caught => GameSound.fishingCatch,
      _ => null,
    };
    if (sound != null) GameAudio.instance.play(sound);
    _phase = phase;
    if (phase != FishingPhase.reeling) {
      river.chasing = false;
      stopSteering();
    }
    _elapsed = 0;
    _pulling = false;
    _tensionWarned = false;
    _drift = 0;
    _combo = 0;
    _comboTime = 0;
  }

  void update(double dt) {
    assert(dt >= 0 && dt <= .05);
    _clock += dt;
    _elapsed += dt;
    switch (_phase) {
      case FishingPhase.casting:
        if (_elapsed >= .65) _setPhase(FishingPhase.waiting);
      case FishingPhase.waiting:
        if (_elapsed >= _wait) {
          _setPhase(FishingPhase.bite);
          _vibrate(HapticFeedback.mediumImpact);
        }
      case FishingPhase.bite:
        if (_elapsed > (beginner ? 3 : 2)) _lose('Cá đã nhả mồi');
      case FishingPhase.reeling:
        if (river.chase(dt, _fish, _elapsed + _fight, _surge,
            pulling: _pulling, beginner: beginner)) {
          _progress = math.max(.08, _progress - (beginner ? .05 : .1));
          _combo = 0;
          _vibrate(HapticFeedback.mediumImpact);
        }
        _drift = river.heading.dx;
        _sweetCenter = .45 + math.sin(_elapsed * .8 + _fight) * .17;
        final pull = _fish.pullStrength * (beginner ? .75 : 1);
        _tension =
            (_tension + (_pulling ? (.12 + _surge * .32) * pull : -.32) * dt)
                .clamp(0.0, 1.0);
        final sweet = _pulling && inSweetZone;
        if (sweet) {
          _comboTime += dt;
          if (_comboTime >= .8) {
            _comboTime = 0;
            _combo++;
            _vibrate(HapticFeedback.selectionClick);
          }
        } else if (_pulling) {
          _comboTime = 0;
          if (_tension > _sweetCenter + sweetWidth) _combo = 0;
        }
        final reelRate = !_pulling
            ? -.015
            : _tension > .82
                ? .035
                : sweet
                    ? .2 * (1 + math.min(_combo, 5) * .08)
                    : .11;
        _progress = (_progress + reelRate * dt).clamp(0.0, 1.0);
        // Slack lets the fish gain distance; it does not snap the line.
        if (_tension >= 1) {
          _lose('Dây câu bị đứt', snapped: true);
        } else if (_progress <= 0 || _elapsed > 35) {
          _lose('Cá đã tuột khỏi lưỡi câu');
        } else if (_progress >= 1) {
          _spot = spot;
          _setPhase(FishingPhase.saving);
          _saveCatch();
        }
        if (_phase == FishingPhase.reeling) {
          if (_tension >= .82 && !_tensionWarned) {
            GameAudio.instance.play(GameSound.fishingTension);
            _tensionWarned = true;
          } else if (_tension < .7) {
            _tensionWarned = false;
          }
        }
        assert(
            _tension >= 0 && _tension <= 1 && _progress >= 0 && _progress <= 1);
      default:
        break;
    }
    river.update(dt);
    notifyListeners();
  }

  void _lose(String message, {bool snapped = false}) {
    _spot = spot;
    _error = message;
    _setPhase(FishingPhase.lost);
    GameAudio.instance
        .play(snapped ? GameSound.fishingSnap : GameSound.fishingEscape);
    _vibrate(HapticFeedback.heavyImpact);
  }

  void castHere() {
    if (!canSail) return;
    final location = river.boat;
    final direction = river.heading.dx >= 0 ? 1.0 : -1.0;
    river.stop();
    _spot = FishingRiver.constrain(location + Offset(direction * 280, -25));
    if ((_spot - location).distance < 200) {
      _spot = FishingRiver.constrain(location + Offset(-direction * 280, -25));
    }
    _castOffset = _spot - location;
    // The boat's casting location owns the pool, even if the float lands
    // across a regional boundary or the fish later pulls the boat elsewhere.
    _fish = beginner
        ? (location.dx >= FishingRiver.seaStart
            ? FishSpecies.sardine
            : location.dx < FishingRiver.sectionLength
                ? FishSpecies.tilapia
                : FishSpecies.catfish)
        : FishingRiver.rollFish(
            _random.nextInt(10000), location.dx, _worldHour);
    _wait = 1.2 + _random.nextDouble() * 2;
    _fight = _random.nextDouble() * math.pi * 2;
    _error = null;
    _setPhase(FishingPhase.casting);
    _vibrate(HapticFeedback.selectionClick);
    notifyListeners();
  }

  void dismissResult() {
    if (_phase != FishingPhase.caught && _phase != FishingPhase.lost) return;
    _error = null;
    _setPhase(FishingPhase.ready);
    notifyListeners();
  }

  void hook() {
    if (_phase == FishingPhase.bite) {
      _tension = .32;
      _progress = beginner ? .25 : .16;
      _hookProgress = _progress;
      river.beginFight(_spot);
      _setPhase(FishingPhase.reeling);
      _vibrate(HapticFeedback.mediumImpact);
    } else if (_phase == FishingPhase.waiting) {
      _lose('Giật cần quá sớm');
    }
    notifyListeners();
  }

  void setPulling(bool value) {
    if (_disposed || _phase != FishingPhase.reeling || _pulling == value) {
      return;
    }
    _pulling = value;
    GameAudio.instance.setFishingReeling(value);
    notifyListeners();
  }

  void retrySave() {
    if (_phase != FishingPhase.saving || _savingCatch) return;
    _error = null;
    notifyListeners();
    _saveCatch();
  }

  Future<void> _saveCatch() async {
    if (_savingCatch) return;
    _savingCatch = true;
    try {
      await collection.catchFish(_fish);
      await CampState.instance.addCoins(2);
      await CampState.instance.markGuidesSeen([boatGuideKey]);
      if (_disposed) return;
      _setPhase(FishingPhase.caught);
      _vibrate(HapticFeedback.heavyImpact);
    } catch (_) {
      if (_disposed) return;
      _error = 'Chưa lưu được cá';
    } finally {
      _savingCatch = false;
    }
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    GameAudio.instance.setFishingReeling(false);
    _disposed = true;
    super.dispose();
  }
}
