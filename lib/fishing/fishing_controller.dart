import '../camp/camp_state.dart';
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
  FishingController(this.collection);

  final FishCollection collection;
  final _random = math.Random();
  FishSpecies _fish = FishSpecies.tilapia;
  FishSpecies get fish => _fish;
  FishingPhase _phase = FishingPhase.ready;
  Offset _spot = const Offset(.5, .66);
  double _clock = 0, _elapsed = 0, _wait = 0;
  double _tension = .32, _progress = .12, _fight = 0;
  double _drift = 0, _driftTarget = 0, _driftTimer = 0, _steer = 0;
  double _sweetCenter = .45, _comboTime = 0;
  int _combo = 0;
  double _worldHour = 12;
  bool _pulling = false, _savingCatch = false, _disposed = false;
  String? _error;

  FishingPhase get phase => _phase;
  Offset get spot =>
      _phase == FishingPhase.reeling ? _spot + Offset(_drift * .07, 0) : _spot;
  double get drift => _drift;
  double get steer => _steer;
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
      FishSpecies.koi => .4 + math.sin(t * 2) * .2,
      // Pretends to be tired, then bursts.
      FishSpecies.catMew => (t % 4.5) > 3.6 ? 1.0 : .1,
      _ => .45 + math.sin(t * 2.5) * .2,
    };
  }

  void setWorldHour(double hour) => _worldHour = hour;

  /// Horizontal swipe while reeling; push against the fish direction.
  void addSteer(double delta) {
    if (_phase != FishingPhase.reeling) return;
    _steer = (_steer + delta).clamp(-1.0, 1.0);
  }

  String get message => switch (_phase) {
        FishingPhase.ready => 'HỒ CÂU',
        FishingPhase.casting => 'Đang thả câu',
        FishingPhase.waiting => 'Chờ cá cắn…',
        FishingPhase.bite => 'CÁ CẮN!',
        FishingPhase.reeling => _surging ? 'Cá đang vùng mạnh!' : 'Đang kéo cá',
        FishingPhase.saving => _error ?? 'Đang lưu cá…',
        FishingPhase.caught => _fish.isJunk
            ? 'Ối! Câu được ${_fish.label.toLowerCase()}'
            : '+1 ${_fish.label} · Đã vào bộ sưu tập',
        FishingPhase.lost => _error ?? 'Cá đã thoát',
      };

  void _setPhase(FishingPhase phase) {
    _phase = phase;
    _elapsed = 0;
    _pulling = false;
    _steer = 0;
    _drift = 0;
    _driftTarget = 0;
    _driftTimer = 0;
    _combo = 0;
    _comboTime = 0;
  }

  void _updateDrift(double dt) {
    _driftTimer -= dt;
    if (_driftTimer <= 0) {
      final restless =
          _fish == FishSpecies.goldfish || _fish == FishSpecies.catMew;
      _driftTimer = restless
          ? .9 + _random.nextDouble() * .8
          : 1.8 + _random.nextDouble() * 1.6;
      _driftTarget = (_random.nextDouble() * 2 - 1) *
          (.45 + _fish.movementAmplitude * .35);
    }
    _drift += (_driftTarget - _drift) * math.min(1, dt * 2.5);
    // The counter-swipe relaxes, so the player has to keep responding.
    _steer *= math.max(0, 1 - dt * 1.4);
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
          HapticFeedback.mediumImpact();
        }
      case FishingPhase.bite:
        if (_elapsed > 1.5) _lose('Cá đã nhả mồi');
      case FishingPhase.reeling:
        _updateDrift(dt);
        _sweetCenter = .45 + math.sin(_elapsed * .8 + _fight) * .17;
        final pull = _fish.pullStrength;
        // Not countering the sideways run strains the line.
        final imbalance = (_drift + _steer).abs();
        _tension = (_tension +
                (_pulling ? (.12 + _surge * .32) * pull : -.32) * dt +
                imbalance * .22 * dt)
            .clamp(0.0, 1.0);
        final sweet = _pulling && inSweetZone;
        if (sweet) {
          _comboTime += dt;
          if (_comboTime >= .8) {
            _comboTime = 0;
            _combo++;
            HapticFeedback.selectionClick();
          }
        } else if (_pulling) {
          _comboTime = 0;
          if (_tension > _sweetCenter + sweetWidth) _combo = 0;
        }
        final reelRate = !_pulling
            ? -.045
            : _tension > .82
                ? .035
                : sweet
                    ? .2 * (1 + math.min(_combo, 5) * .08)
                    : .11;
        _progress = (_progress + reelRate * dt).clamp(0.0, 1.0);
        if (_tension <= 0 || _tension >= 1) {
          _lose('Dây câu bị đứt');
        } else if (_progress <= 0 || _elapsed > 35) {
          _lose('Cá đã tuột khỏi lưỡi câu');
        } else if (_progress >= 1) {
          _setPhase(FishingPhase.saving);
          _saveCatch();
        }
        assert(
            _tension >= 0 && _tension <= 1 && _progress >= 0 && _progress <= 1);
      default:
        break;
    }
    notifyListeners();
  }

  void _lose(String message) {
    _error = message;
    _setPhase(FishingPhase.lost);
    HapticFeedback.heavyImpact();
  }

  void cast(Offset position) {
    if (active) return;
    // Keep every cast readable: the progress bar carries the reel distance.
    _spot = const Offset(.5, .64);
    _fish = FishSpecies.fromRollAtTime(_random.nextInt(1000), _worldHour);
    _wait = 2.5 + _random.nextDouble() * 3.5;
    _fight = _random.nextDouble() * math.pi * 2;
    _error = null;
    _setPhase(FishingPhase.casting);
    HapticFeedback.selectionClick();
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
      _progress = .12;
      _setPhase(FishingPhase.reeling);
      HapticFeedback.mediumImpact();
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
      if (_disposed) return;
      _setPhase(FishingPhase.caught);
      HapticFeedback.heavyImpact();
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
    _disposed = true;
    super.dispose();
  }
}
