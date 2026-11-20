import 'fishing_fight.dart';
import 'fishing_activity.dart';
import 'fishing_river.dart';
import 'fishing_island.dart';
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
  final activities = FishingActivities();
  bool _activeWater = false;
  static const boatGuideKey = 'mode:fishing:boat:v1';
  bool get beginner => !CampState.instance.seenGuides.contains(boatGuideKey);
  bool get canSail =>
      _phase == FishingPhase.ready || _phase == FishingPhase.lost;
  bool get surging => _surging;
  String get guide => river.island.ashore
      ? river.island.boardRequested
          ? 'Mèo đang quay lại thuyền…'
          : 'Sò ${river.island.collectedShells.length}/6 · Bấm Về thuyền để quay lại bến'
      : river.island.dockRequested
          ? 'Đang tới bến đảo…'
          : (river.boat - FishingIslandVisit.mooring).distance < 600 && canSail
              ? 'Bấm cầu gỗ trên đảo để cập bến khám phá'
              : switch (_phase) {
                  FishingPhase.ready => river.moving
                      ? 'Đang chèo · Bấm cần câu góc phải để câu tại đây'
                      : activities.nearby(river.clock, river.boat) != null
                          ? 'Có cá động gần đây! Bấm cần câu để thử vận may'
                          : 'Tìm cá quẫy, bọt nước · Mọi chỗ đều câu được',
                  FishingPhase.casting => _activeWater
                      ? 'Thả vào chỗ cá động · Cơ hội cá hiếm tăng!'
                      : 'Mèo đang thả cần…',
                  FishingPhase.waiting => 'Chờ phao động rồi bấm giật cần',
                  FishingPhase.bite => 'Cá cắn! Bấm nút giật cần!',
                  FishingPhase.reeling => '',
                  FishingPhase.saving => _error ?? 'Đang cất cá vào giỏ…',
                  FishingPhase.caught => message,
                  FishingPhase.lost =>
                    '${_error ?? "Cá thoát rồi"} · Bấm cần câu để thử lại',
                };

  void tapRiver(Offset screen) {
    if (_phase == FishingPhase.saving || _phase == FishingPhase.caught) return;
    final point = river.toWorld(screen);
    final island = river.island;
    if (island.ashore) {
      if ((point - river.boat).distance < 70) {
        island.returnToBoat();
      } else if (FishingIslandVisit.contains(point)) {
        island.walkTo(point);
      }
      notifyListeners();
      return;
    }
    final docking = FishingIslandVisit.contains(point) ||
        (point - FishingIslandVisit.dockTap).distance < 45;
    if (!docking && !FishingRiver.contains(point)) return;
    if (active) cancelCast();
    if (_phase == FishingPhase.lost) {
      _error = null;
      _setPhase(FishingPhase.ready);
    }
    island.dockRequested = docking;
    river.sailTo(docking ? FishingIslandVisit.mooring : point);
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
  int _grams = 0;
  int get grams => _grams;
  bool _newRecord = false, _catchSaved = false, _coinsSaved = false;
  bool get newRecord => _newRecord;
  double get sizeFraction => _fish.weightFraction(_grams);
  double get fishScale => _fish.isJunk ? 1 : .8 + sizeFraction * .7;
  double get weightPull =>
      beginner || _fish.isJunk ? 1 : .95 + sizeFraction * .2;
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

  FishingFight get fight =>
      FishingFight.at(_fish, _phase == FishingPhase.reeling ? _elapsed : 0);
  double get _surge => fight.surge;

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
        final behavior = fight;
        final steeringError =
            (river.steering.dy * 140 + behavior.lateral * (beginner ? 25 : 42))
                .abs();
        final orbitControlled =
            behavior.move == FishFightMove.orbit && steeringError < 15;
        if (river.chase(dt, _fish, _elapsed, _surge,
            pulling: _pulling, beginner: beginner, weightPull: weightPull)) {
          _progress = math.max(.08, _progress - (beginner ? .05 : .1));
          _combo = 0;
          _vibrate(HapticFeedback.mediumImpact);
        }
        _drift = river.heading.dx;
        _sweetCenter = .45 + math.sin(_elapsed * .8 + _fight) * .17;
        final pull = _fish.pullStrength * (beginner ? .75 : weightPull);
        final strain = behavior.blocked
            ? .62
            : behavior.dangerous
                ? .48
                : (.12 + _surge * .32);
        final orbitStrain =
            behavior.move == FishFightMove.orbit && !orbitControlled
                ? .035
                : 0.0;
        _tension =
            (_tension + ((_pulling ? strain * pull : -.32) + orbitStrain) * dt)
                .clamp(0.0, 1.0);
        final sweet =
            _pulling && !behavior.blocked && !behavior.dangerous && inSweetZone;
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
        final baseReelRate = !_pulling
            ? (behavior.blocked ? 0.0 : -.015)
            : behavior.blocked
                ? 0.0
                : behavior.dangerous
                    ? .015
                    : _tension > .82
                        ? .035
                        : sweet
                            ? .2 * (1 + math.min(_combo, 5) * .08)
                            : .11;
        final reelRate = baseReelRate > 0
            ? baseReelRate *
                behavior.reelBonus *
                (behavior.move == FishFightMove.orbit
                    ? (orbitControlled ? 1.25 : .75)
                    : 1)
            : baseReelRate;
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
    if (!canSail || river.island.ashore) return;
    final location = river.boat;
    final direction = river.heading.dx >= 0 ? 1.0 : -1.0;
    river.stop();
    _spot = FishingRiver.constrain(location + Offset(direction * 280, -25));
    if ((_spot - location).distance < 200) {
      _spot = FishingRiver.constrain(location + Offset(-direction * 280, -25));
    }
    final activity = activities.nearby(river.clock, location);
    _activeWater = activity != null;
    if (activity != null) {
      if ((activity.position - location).distance >= 110) {
        _spot = activity.position;
      }
      activities.consume(activity);
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
        : FishingRiver.rollFish(_random.nextInt(10000), location.dx, _worldHour,
            activeWater: _activeWater);
    _grams = _fish.rollGrams(_random);
    _newRecord = false;
    _catchSaved = false;
    _coinsSaved = false;
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
      if (!_catchSaved) {
        _newRecord = await collection.catchFish(_fish,
            grams: _fish.isJunk ? null : _grams);
        _catchSaved = true;
      }
      if (!_coinsSaved) {
        await CampState.instance.addCoins(2);
        _coinsSaved = true;
      }
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
