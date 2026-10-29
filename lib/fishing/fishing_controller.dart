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
  double _worldHour = 12;
  bool _pulling = false, _savingCatch = false, _disposed = false;
  String? _error;

  FishingPhase get phase => _phase;
  Offset get spot => _spot;
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
  bool get _surging =>
      math.sin(_elapsed * (2.2 + _fish.movementSpeed) + _fight) > .35;

  void setWorldHour(double hour) => _worldHour = hour;

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
        final pull = _fish.pullStrength;
        _tension = (_tension +
                (_pulling ? (_surging ? .40 * pull : .21 * pull) : -.32) * dt)
            .clamp(0.0, 1.0);
        _progress = (_progress +
                (_pulling ? (_tension > .82 ? .035 : .15) : -.045) * dt)
            .clamp(0.0, 1.0);
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
