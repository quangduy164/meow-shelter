import 'fishing_fight.dart';
import 'fishing_activity.dart';
import 'fishing_river.dart';
import 'fishing_island.dart';
import 'fishing_cabin.dart';
import 'fishing_boat.dart';
import 'fishing_rod.dart';
import 'fishing_market.dart';
import 'fishing_shrine.dart';
import 'fishing_quests.dart';
import 'fishing_bait_house.dart';
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

  bool _preparingCast = false;
  bool get preparingCast => _preparingCast;
  bool useLegendaryBait = false;
  void toggleLegendaryBait() {
    if (!canSail || _preparingCast) return;
    useLegendaryBait = !useLegendaryBait;
    notifyListeners();
  }

  late FishingRod rod = FishingRod.load(collection.preferences);
  Future<bool> selectRod(FishingRod choice) async {
    if (!await choice.save(collection.preferences)) return false;
    rod = choice;
    if (!_disposed) notifyListeners();
    return true;
  }

  final FishCollection collection;
  final math.Random _random;
  final river = FishingRiverRound();
  final activities = FishingActivities();
  bool _activeWater = false, _shoreCastPending = false;
  FishFightMove? _soundMove;

  /// Place the cat is heading to; its screen opens on arrival (see
  /// [takeArrival]).
  FishingVisit? _visit, _arrived;
  FishingVisit? get visitRequested => _visit;

  /// The place the cat just reached, once; null otherwise.
  FishingVisit? takeArrival() {
    final arrived = _arrived;
    _arrived = null;
    return arrived;
  }

  Offset get angler => river.island.ashore ? river.island.cat : river.boat;
  bool get shoreFishing => river.island.ashore;
  bool get showFishingArt =>
      active ||
      _phase == FishingPhase.caught ||
      (_phase == FishingPhase.lost && _elapsed < .6);
  FishingQuests get quests => FishingQuests.instance;

  /// Where the current cast was made from; quests use its region.
  Offset _castFrom = Offset.zero;
  static const boatGuideKey = 'mode:fishing:boat:v1';
  bool get beginner => !CampState.instance.seenGuides.contains(boatGuideKey);

  // ---- First-visit tutorial -------------------------------------------
  // Five steps on the very first trip: row, cast, strike, reel, open the
  // basket. The tutorial catch can never be lost. Done after the basket is
  // opened or when skipped; existing players never see it.
  static const tutorialKey = 'mode:fishing:tutorial:v1';
  late bool _tutorial =
      beginner && !CampState.instance.seenGuides.contains(tutorialKey);
  bool _tutorialRowed = false, _tutorialCaught = false;
  String? _tutorialNudge;
  double _nudgeUntil = 0;
  FishingPhase? _nudgePhase;
  bool get tutorial => _tutorial;

  /// The tutorial is waiting for the player to open the fish basket.
  bool get tutorialAwaitsBasket => _tutorial && _tutorialCaught;

  /// Caption and the button it points at, or null when nothing to show.
  (String, FishingTutorialTarget)? get tutorialStep {
    if (!_tutorial || river.cabin.inside || river.cave.inside) return null;
    if (_tutorialNudge != null &&
        _clock < _nudgeUntil &&
        _nudgePhase == _phase) {
      return (_tutorialNudge!, FishingTutorialTarget.none);
    }
    const none = FishingTutorialTarget.none, rod = FishingTutorialTarget.rod;
    return switch (_phase) {
      FishingPhase.ready || FishingPhase.lost => _tutorialCaught
          ? (
              'Bước 5/5 · Bấm giỏ cá ở góc trái dưới để xem cá vừa câu',
              FishingTutorialTarget.basket
            )
          : !_tutorialRowed
              ? ('Bước 1/5 · Bấm vào mặt nước để chèo thuyền tới đó', none)
              : ('Bước 2/5 · Bấm nút cần câu ở góc phải để thả câu', rod),
      FishingPhase.casting || FishingPhase.waiting => (
          'Bước 3/5 · Chờ phao chìm xuống, đừng bấm vội…',
          none
        ),
      FishingPhase.bite => ('Bước 3/5 · Cá cắn rồi! Bấm nút giật cần!', rod),
      FishingPhase.reeling => fight.dangerous || fight.blocked
          ? ('Bước 4/5 · Thả tay ra! Cá đang giật mạnh', rod)
          : _tension > .7
              ? ('Bước 4/5 · Dây căng quá, thả tay cho dây chùng', rod)
              : ('Bước 4/5 · Giữ nút để kéo cá vào', rod),
      FishingPhase.saving || FishingPhase.caught => (
          'Câu được rồi! Giỏi lắm',
          none
        ),
    };
  }

  void _nudge(String text) {
    _tutorialNudge = text;
    _nudgeUntil = _clock + 2;
    _nudgePhase = _phase;
  }

  /// Ends the tutorial (after the basket, or when the player skips it).
  Future<void> finishTutorial() async {
    if (!_tutorial) return;
    _tutorial = false;
    notifyListeners();
    await CampState.instance.markGuidesSeen([tutorialKey]);
  }

  bool get canSail =>
      _phase == FishingPhase.ready || _phase == FishingPhase.lost;
  bool get surging => _surging;

  /// One-line hint for the HUD. Checked top to bottom; the first match wins,
  /// so travel/visit hints outrank the fishing phase.
  String get guide {
    final island = river.island;
    if (river.cabin.pending) return 'Đang chèo tới thuyền gỗ…';
    if (!island.ashore &&
        !active &&
        (river.boat - FishingCabin.ship).distance < 650) {
      return 'Bấm thuyền lớn để vào khoang nghỉ';
    }
    if (island.lookout) return 'Ngắm toàn vùng biển · Bấm để leo xuống';
    switch (_visit) {
      case FishingVisit.rodHouse:
        return 'Đang tới nhà đổi cần câu…';
      case FishingVisit.boatHouse:
        return island.ashore
            ? 'Mèo đang tới nhà thuyền…'
            : 'Đang chèo về bến nhà thuyền…';
      case FishingVisit.market:
        return 'Đang chèo tới chợ cá nổi…';
      case FishingVisit.shrine:
        return 'Đang chèo tới đền hiến tế…';
      case FishingVisit.baitHouse:
        return 'Đang chèo tới nhà pha mồi…';
      case null:
        break;
    }
    if (!island.ashore &&
        !active &&
        (river.boat - FishingShrine.center).distance < 500) {
      return collection.shrineOfferings >= FishingShrine.requiredFish
          ? 'Đền Hang biển đã thức tỉnh'
          : 'Bấm đền đá để dâng 3 loài huyền thoại';
    }
    if (!island.ashore &&
        !active &&
        (river.boat - FishingMarket.center).distance < 600) {
      return 'Bấm chợ cá nổi để bán cá lấy xu';
    }
    if (!island.ashore &&
        !active &&
        (river.boat - FishingBaitHouse.center).distance < 400) {
      return 'Nhà pha mồi · Đổi 5 cá phổ biến lấy mồi huyền thoại';
    }
    if (island.lookoutRequested) return 'Mèo đang tới hải đăng…';
    if (island.caveRequested) return 'Mèo đang tới cửa hang trong núi…';
    if (_shoreCastPending) return 'Mèo đang ra mép nước để câu…';
    if (island.ashore && !showFishingArt) {
      if (island.boardRequested) return 'Mèo đang quay lại thuyền…';
      if (island.onBank) return 'Bấm trên bờ để đi · Về thuyền để chèo tiếp';
      return 'Sò ${island.collectedShells.length}/6 · Bấm Về thuyền để quay lại bến';
    }
    if (island.dockRequested) return 'Đang cập bến…';
    if (canSail && (river.boat - FishingIslandVisit.mooring).distance < 600) {
      return 'Bấm cầu gỗ trên đảo để cập bến khám phá';
    }
    return switch (_phase) {
      FishingPhase.ready => river.moving
          ? 'Đang chèo · Bấm cần câu góc phải để câu tại đây'
          : activities.nearby(FishingActivities.worldClock(), river.boat,
                      reach: river.boatStyle.activeReach) !=
                  null
              ? 'Có cá động gần đây! Bấm cần câu để thử vận may'
              : 'Bấm nước để chèo · Bấm bờ để xuống đi bộ',
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
  }

  void tapRiver(Offset screen) {
    if (_phase == FishingPhase.saving || _phase == FishingPhase.caught) return;
    if (river.cabin.inside || river.cave.inside) return;
    if (_preparingCast) return;
    final point = river.toWorld(screen);
    river.cabin.pending = false;
    final island = river.island;
    _shoreCastPending = false;
    _visit = null;
    if (island.lookout) {
      island.climbDown();
      notifyListeners();
      return;
    }
    if ((FishingBoatHouse.hit(point) && _goTo(FishingVisit.boatHouse)) ||
        (FishingMarket.hit(point) && _goTo(FishingVisit.market)) ||
        (FishingShrine.hit(point) && _goTo(FishingVisit.shrine)) ||
        (FishingBaitHouse.hit(point) && _goTo(FishingVisit.baitHouse)) ||
        (FishingRodHouse.hit(point) && _goTo(FishingVisit.rodHouse))) {
      notifyListeners();
      return;
    }
    if (island.ashore) {
      if (active) cancelCast();
      if (!island.onBank && FishingIslandVisit.hitsLighthouse(point)) {
        island.climbLighthouse();
      } else if (!island.onBank && FishingIslandVisit.inMountain(point)) {
        island.goToCave();
      } else if ((point - river.boat).distance < 70) {
        returnToBoat();
      } else if (island.landContains(point)) {
        island.walkTo(point);
      }
      notifyListeners();
      return;
    }
    if (FishingCabin.hit(point)) {
      if (active) cancelCast();
      if (_phase == FishingPhase.lost) _setPhase(FishingPhase.ready);
      river.sailTo(FishingCabin.mooring);
      river.cabin.pending = true;
      notifyListeners();
      return;
    }
    final docking = FishingIslandVisit.contains(point) ||
        (point - FishingIslandVisit.dockTap).distance < 45;
    final bank = point.dx >= 80 &&
        point.dx <= FishingRiver.length - 80 &&
        point.dy >= 150 &&
        point.dy <= FishingRiver.height - 30 &&
        (point.dy < FishingRiver.top(point.dx) - 10 ||
            point.dy > FishingRiver.bottom(point.dx) + 10);
    if (!docking && !bank && !FishingRiver.contains(point)) return;
    if (active) cancelCast();
    if (_phase == FishingPhase.lost) {
      _error = null;
      _setPhase(FishingPhase.ready);
    }
    if (bank && !docking) {
      island.chooseBank(point);
      island.bankMooring = river.props.resolve(island.visitMooring);
    } else if (docking) {
      island.chooseIsland();
    }
    island.dockRequested = docking || bank;
    river.sailTo(island.dockRequested ? island.visitMooring : point);
    notifyListeners();
  }

  /// Rows (or, for the boathouse, also walks along the near bank) to
  /// [visit]; its screen only opens there. False when it cannot be reached
  /// from here (e.g. the market while ashore), so the tap is handled as usual.
  bool _goTo(FishingVisit visit) {
    final island = river.island;
    final walk = island.ashore;
    if (walk && (visit.bankDoor == null || island.northBank != false)) {
      return false;
    }
    if (active) cancelCast();
    if (_phase == FishingPhase.lost) {
      _error = null;
      _setPhase(FishingPhase.ready);
    }
    _visit = visit;
    if (walk) {
      island.walkTo(visit.bankDoor!);
    } else {
      river.sailTo(visit.mooring);
    }
    return true;
  }

  void _updateVisit() {
    final visit = _visit;
    if (visit == null) return;
    final island = river.island;
    if (island.ashore ? island.walking : river.moving) return;
    _visit = null;
    final arrived = island.ashore
        ? visit.bankDoor != null &&
            (island.cat - visit.bankDoor!).distance < 110
        : (river.boat - visit.mooring).distance < 30;
    if (arrived) _arrived = visit;
  }

  void steerBoat(Offset delta) {
    if (_phase == FishingPhase.reeling) river.steer(delta);
  }

  void stopSteering() => river.steering = Offset.zero;

  void cancelNavigation() {
    river.stop();
  }

  void cancelCast() {
    _shoreCastPending = false;
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
  // Legendary fish always look huge: up to twice a trophy common fish.
  double get fishScale => _fish.isJunk
      ? 1
      : FishSpecies.legendary.contains(_fish)
          ? 1.6 + sizeFraction * .5
          : .8 + sizeFraction * .7;
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
    final finishDistance = math.min(95.0, startDistance * .5);
    final distance = startDistance + (finishDistance - startDistance) * reeled;
    if (startDistance < .001) return angler;
    final target = angler + _castOffset / startDistance * distance;
    // Keep the float on this side of walls while the boat moves.
    return shoreFishing
        ? FishingRiver.constrain(target)
        : river.clipCast(angler, target, caveOnly: FishingRiver.inCave(angler));
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
      FishingPhase.caught => _fish.isJunk
          ? GameSound.fishingJunk
          : _fish.isLegendary || _newRecord
              ? GameSound.fishingRare
              : GameSound.fishingCatch,
      _ => null,
    };
    if (sound != null) GameAudio.instance.play(sound);
    _phase = phase;
    _soundMove = null;
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
    activities.density =
        FishingActivities.densityAt(_worldHour, rain: river.weather.rain);
    if (river.cabin.inside) {
      river.cabin.update(dt);
      notifyListeners();
      return;
    }
    if (river.cave.inside) {
      river.cave.update(dt);
      notifyListeners();
      return;
    }
    assert(dt >= 0 && dt <= .05);
    _clock += dt;
    _elapsed += dt;
    switch (_phase) {
      case FishingPhase.casting:
        if (_elapsed >= .65) {
          _setPhase(FishingPhase.waiting);
          if (_activeWater) GameAudio.instance.play(GameSound.rescueSplash);
        }
      case FishingPhase.waiting:
        if (_elapsed >= _wait) {
          _setPhase(FishingPhase.bite);
          _vibrate(HapticFeedback.mediumImpact);
        }
      case FishingPhase.bite:
        if (!_tutorial && _elapsed > (beginner ? 3 : 2)) {
          _lose('Cá đã nhả mồi');
        }
      case FishingPhase.reeling:
        final behavior = fight;
        if (behavior.move != _soundMove) {
          if (behavior.warning) {
            GameAudio.instance.play(GameSound.rescueFlood);
          } else if (behavior.dangerous) {
            GameAudio.instance.play(GameSound.fishingSurge);
          }
          _soundMove = behavior.move;
        }
        final steeringError =
            (river.steering.dy * 140 + behavior.lateral * (beginner ? 25 : 42))
                .abs();
        final orbitControlled =
            behavior.move == FishFightMove.orbit && steeringError < 15;
        if (!shoreFishing &&
            river.chase(dt, _fish, _elapsed, _surge,
                pulling: _pulling,
                beginner: beginner,
                weightPull: weightPull)) {
          _progress = math.max(.08, _progress - (beginner ? .05 : .1));
          _combo = 0;
          GameAudio.instance.play(GameSound.fishingSurge);
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
            if (_combo == 1 || _combo % 3 == 0) {
              GameAudio.instance.play(GameSound.toyBeat);
            }
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
                rod.reel *
                behavior.reelBonus *
                (behavior.move == FishFightMove.orbit
                    ? (orbitControlled ? 1.25 : .75)
                    : 1)
            : baseReelRate;
        _progress = (_progress + reelRate * dt).clamp(0.0, 1.0);
        // The tutorial fish cannot escape: the line holds and it stays on.
        if (_tutorial) {
          if (_tension >= .97) {
            _tension = .97;
            _nudge('Bước 4/5 · Dây sắp đứt! Thả tay ra');
          }
          _progress = math.max(_progress, .1);
          _elapsed = math.min(_elapsed, 30);
        }
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
    quests.onBoatAt(river.boat);
    if (_tutorial && !_tutorialRowed && river.moving) _tutorialRowed = true;
    if (river.cabin.pending &&
        !river.moving &&
        (river.boat - FishingCabin.mooring).distance < 2) {
      river.cabin.enter();
      stopSteering();
    }
    _updateVisit();
    if (_shoreCastPending &&
        river.island.phase == IslandVisitPhase.exploring &&
        !river.island.walking) {
      _shoreCastPending = false;
      _startCast();
    }
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

  void returnToBoat() {
    if (_phase == FishingPhase.saving || _phase == FishingPhase.caught) return;
    _shoreCastPending = false;
    if (active) cancelCast();
    river.island.returnToBoat();
    notifyListeners();
  }

  void castHere() {
    if (!canSail || _preparingCast || river.cabin.inside || river.cave.inside) {
      return;
    }
    if (shoreFishing) {
      if (river.island.phase != IslandVisitPhase.exploring) return;
      final edge = river.island.fishingEdge;
      if ((edge - angler).distance > 5) {
        river.island.walkTo(edge);
        _shoreCastPending = true;
        notifyListeners();
        return;
      }
      river.island.stopWalking();
    }
    _startCast();
  }

  /// Bad-luck protection: casts in legendary water without one. Each miss
  /// adds 1/30 to the legendary odds (up to x4); a legendary catch resets it.
  static const legendMissKey = 'fishing_legend_misses_v1';
  late int _legendMisses = collection.preferences.getInt(legendMissKey) ?? 0;
  double get legendaryBoost => 1 + math.min(_legendMisses, 90) / 30;
  void _setLegendMisses(int value) {
    _legendMisses = value;
    collection.preferences.setInt(legendMissKey, value);
  }

  Future<void> _startCast() async {
    if (!canSail || _preparingCast) return;
    _preparingCast = true;
    notifyListeners();
    try {
      var baited = false;
      if (useLegendaryBait && collection.legendaryBait > 0) {
        baited = await collection.consumeLegendaryBait();
        if (!baited) {
          _error = 'Chưa lưu được mồi câu, hãy thử lại';
          _setPhase(FishingPhase.lost);
          return;
        }
      }
      if (_disposed) return;
      _finishCast(baited);
    } catch (_) {
      if (!_disposed) {
        _error = 'Chưa chuẩn bị được mồi câu, hãy thử lại';
        _setPhase(FishingPhase.lost);
      }
    } finally {
      _preparingCast = false;
      if (!_disposed) notifyListeners();
    }
  }

  void _finishCast(bool baited) {
    if (shoreFishing) river.island.stopWalking();
    final location = angler;
    _castFrom = location;
    final direction = river.heading.dx >= 0 ? 1.0 : -1.0;
    river.stop();
    _spot = shoreFishing
        ? river.island.fishingWater(location)
        : river.castPoint(location, direction);
    if (shoreFishing) {
      river.island.facingRight = _spot.dx >= location.dx;
    }
    var activity = shoreFishing
        ? null
        : activities.nearby(FishingActivities.worldClock(), location,
            reach: river.boatStyle.activeReach);
    if (activity != null &&
        (!river.props.clearLine(location, activity.position) ||
            (FishingRiver.inCave(location) &&
                !FishingRiver.inCave(activity.position)))) {
      activity = null;
    }
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
    _fish = beginner && !baited
        ? (FishingRiver.caveBlend(location.dx, y: location.dy) > .1
            ? FishSpecies.catfish
            : location.dx >= FishingRiver.seaStart
                ? FishSpecies.sardine
                : location.dx >= FishingRiver.mangroveStart
                    ? FishSpecies.tilapia
                    : location.dx < FishingRiver.sectionLength
                        ? FishSpecies.tilapia
                        : FishSpecies.catfish)
        : FishingRiver.rollFish(_random.nextInt(10000), location.dx, _worldHour,
            activeWater: _activeWater,
            y: location.dy,
            weatherBoost: river.weather.boost,
            legendaryBait: baited,
            legendaryBoost: legendaryBoost,
            nightLure: rod == FishingRod.lantern);
    if (!_fish.isLegendary &&
        FishingRiver.legendaryHere(location.dx, _worldHour, y: location.dy)) {
      _setLegendMisses(_legendMisses + 1);
    }
    _grams = _fish.rollGrams(_random);
    _newRecord = false;
    _catchSaved = false;
    _coinsSaved = false;
    _wait = (1.2 + _random.nextDouble() * 2) * rod.biteWait;
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
      if (!shoreFishing) river.beginFight(_spot);
      _setPhase(FishingPhase.reeling);
      _vibrate(HapticFeedback.mediumImpact);
    } else if (_phase == FishingPhase.waiting) {
      if (_tutorial) {
        _nudge('Bước 3/5 · Chưa đâu! Chờ phao chìm hẳn rồi mới bấm');
      } else {
        _lose('Giật cần quá sớm');
      }
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
        if (_fish.isLegendary) _setLegendMisses(0);
        if (_tutorial) _tutorialCaught = true;
        await quests.onCatch(_fish, _castFrom, activeWater: _activeWater);
      }
      if (!_coinsSaved) {
        if (!await CampState.instance.addCoins(2)) {
          throw StateError('Could not save coins');
        }
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

/// Places that open their own screen once the cat gets there.
/// Button the tutorial arrow points at.
enum FishingTutorialTarget { none, rod, basket }

enum FishingVisit {
  boatHouse,
  market,
  shrine,
  baitHouse,
  rodHouse;

  Offset? get bankDoor => switch (this) {
        boatHouse => FishingBoatHouse.door,
        rodHouse => FishingRodHouse.door,
        _ => null,
      };

  /// Where the boat stops for this place.
  Offset get mooring => switch (this) {
        boatHouse => FishingRiver.startBoat,
        market => FishingMarket.mooring,
        shrine => FishingShrine.mooring,
        baitHouse => FishingBaitHouse.mooring,
        rodHouse => FishingRodHouse.mooring,
      };
}
