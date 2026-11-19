import 'package:flame/components.dart';
import 'package:flutter/painting.dart';
import '../../../audio/game_audio.dart';
import '../../cats/cat_breed.dart';
import '../../components/cat_component.dart';
import '../../components/darkness_component.dart';
import '../../components/hud_component.dart';
import '../../meow_shelter_game.dart';
import '../moonlight.dart';
import '../moonlight_art.dart';
import '../night_cards.dart';
import '../night_run.dart';
import '../night_scene.dart';
import 'night_station.dart';
import 'night_station_painter.dart';

class _Walk {
  _Walk(this.target, {this.board = false});
  final Vector2 target;
  final bool board;
}

class NightStationScene extends NightScene {
  NightStationScene(this.game, {required this.onFirstLight});
  final MeowShelterGame game;
  final void Function(Offset, double) onFirstLight;
  final line = StationLine();
  final moon = Moonlight();
  final _parts = <Component>[];
  final _marksUi = <StationMarkComponent>[];
  final benches = List<CatComponent?>.filled(6, null);
  var marks = <CatComponent?>[];
  final _walks = <CatComponent, _Walk>{};
  final _sizes = <CatComponent, Vector2>{};
  CatComponent? selected;
  bool _chimed = false;

  @override
  NightMap get map => NightMap.station;
  @override
  bool get ownsBait => true;
  @override
  bool get noCarry => true;
  @override
  double get lanternBurn => 0;
  @override
  bool get cloudy => moon.cloudy;
  @override
  double get notificationTop => 46;
  @override
  bool get hasBaitInTransit => _sizes.isNotEmpty;
  @override
  List<String> get rules => [
        'Biển toa: mèo chỉ lên toa có biển cùng màu vòng chân',
        'Xếp vạch: chạm mèo rồi chạm vạch toa',
        if (!line.preview) 'Biển muộn: biển chỉ hiện khi tàu vào ga',
        if (line.stage >= 2) 'Dừng ngắn: tàu đứng ga ít hơn',
        if (line.stage >= 3) 'Tàu dày: chuyến sau tới sớm hơn',
      ];
  @override
  void onMistake() {}
  @override
  bool blocks(Rect bounds) => false;
  @override
  bool allowsBait(Offset point, Size field) => _markAt(point) != null;
  @override
  bool isLit(Offset point, Size size) =>
      moon.contains(point, size) || _platformLit(point);
  @override
  bool overlappingLights(Offset point, Size size) =>
      moon.contains(point, size) && _platformLit(point);
  bool _platformLit(Offset point) => List.generate(line.cars, (c) => c).any(
      (car) =>
          (point.dx - game.size.x * line.markX(car)).abs() <
              game.size.x * .09 &&
          point.dy > game.size.y * .42);

  Vector2 get _catSize => Vector2.all(game.size.y * .2);
  Vector2 benchSpot(int i, CatComponent cat) =>
      Vector2(game.size.x * (.1 + i * .16) - cat.size.x / 2, game.size.y * .22);
  Vector2 markSpot(int car, CatComponent cat) => Vector2(
      game.size.x * line.markX(car) - cat.size.x / 2, game.size.y * .47);
  Vector2 doorSpot(int car, CatComponent cat) =>
      Vector2(game.size.x * line.markX(car) - cat.size.x / 2, game.size.y * .7);
  int? _markAt(Offset point) {
    for (var car = 0; car < line.cars; car++) {
      final c = Offset(game.size.x * line.markX(car), game.size.y * .58);
      if ((point - c).dx.abs() < game.size.x * .09 &&
          (point - c).dy.abs() < game.size.y * .14) {
        return car;
      }
    }
    return null;
  }

  @override
  void mount() {
    _parts.addAll([
      NightStationBackground(this),
      NightStationTrain(this),
      StationSelectionComponent(this),
      DarknessComponent(
          lights: _lights,
          visible: () => game.hud.status == RoundStatus.playing,
          additionalLights: (canvas, size) =>
              paintMoonlitField(canvas, size, moon),
          shade: const Color(0x20142932)),
      StationMoon(moon),
    ]);
    game.addAll(_parts);
  }

  @override
  void remove() {
    for (final entry in _sizes.entries) {
      entry.key.size.setFrom(entry.value);
      entry.key.leaveTrap();
    }
    _sizes.clear();
    _walks.clear();
    _arrived.clear();
    benches.fillRange(0, benches.length, null);
    marks = [];
    selected = null;
    game.removeAll([..._parts, ..._marksUi]);
    _parts.clear();
    _marksUi.clear();
  }

  @override
  void begin(NightRun run,
      {required bool thickClouds, required double afterglowSeconds}) {
    line.begin(run);
    line.stopSeconds += afterglowSeconds / 4;
    moon.reset(fullMoon: run.has(NightCard.fullMoon), thickClouds: thickClouds);
    benches.fillRange(0, benches.length, null);
    marks = List.filled(line.cars, null);
    _walks.clear();
    _sizes.clear();
    _arrived.clear();
    selected = null;
    _chimed = false;
    game.removeAll(_marksUi);
    _marksUi
      ..clear()
      ..addAll([
        for (var car = 0; car < line.cars; car++)
          StationMarkComponent(this, car, onTapMark: tapMark)
      ]);
    game.addAll(_marksUi);
  }

  /// Cats on the platform in arrival order; the oldest gets the next free car.
  final _arrived = <CatComponent>[];

  /// True when the coming train has no car left for this cat: it must wait.
  bool waitsNextTrain(CatComponent cat) {
    if (line.sharedCar != null) return false;
    if (line.phase != TrainPhase.waiting && line.phase != TrainPhase.leaving) {
      return false;
    }
    final before = _arrived
        .takeWhile((c) => c != cat)
        .where((c) => c.catType == cat.catType);
    return line.next.where((s) => s == cat.catType).length <= before.length;
  }

  void _plan() =>
      line.plan([for (final cat in _arrived) cat.catType], game.random);

  @override
  bool tapCat(CatComponent cat) {
    if (game.paused || game.night?.phase != NightPhase.playing) return false;
    if (!benches.contains(cat) && !marks.contains(cat)) return false;
    selected = selected == cat ? null : cat;
    GameAudio.instance.playRescue(GameSound.click);
    return true;
  }

  @override
  int helpNear(Offset point, double reach, int targets) {
    var helped = 0;
    for (final cat in benches.whereType<CatComponent>().toList()) {
      if (helped >= targets) break;
      final car = List.generate(line.cars, (c) => c)
          .where((c) =>
              marks[c] == null &&
              (c == line.sharedCar || line.shownSign(c) == cat.catType))
          .firstOrNull;
      if (car == null) continue;
      _assign(cat, car);
      helped++;
    }
    return helped;
  }

  @override
  int helperBoost(int count) => helpNear(Offset.zero, 0, count);

  void tapMark(int car) {
    if (game.paused || game.night?.phase != NightPhase.playing) return;
    final cat = selected;
    if (cat == null) {
      if (marks[car] != null) selected = marks[car];
      return;
    }
    _assign(cat, car);
  }

  void _assign(CatComponent cat, int car) {
    selected = null;
    final fromBench = benches.indexOf(cat), fromMark = marks.indexOf(cat);
    if (fromMark == car) return;
    final other = marks[car];
    if (fromBench >= 0) benches[fromBench] = null;
    if (fromMark >= 0) marks[fromMark] = null;
    marks[car] = cat;
    _walks[cat] = _Walk(markSpot(car, cat));
    if (other != null) {
      if (fromMark >= 0) {
        marks[fromMark] = other;
        _walks[other] = _Walk(markSpot(fromMark, other));
      } else {
        _sendToBench(other, prefer: fromBench);
      }
    }
    GameAudio.instance.playRescue(GameSound.click);
    if (!_chimed) {
      _chimed = true;
      onFirstLight(Offset(game.size.x * line.markX(car), game.size.y * .58),
          game.size.x * .16);
    }
  }

  void _sendToBench(CatComponent cat, {int prefer = -1}) {
    var slot =
        prefer >= 0 && benches[prefer] == null ? prefer : benches.indexOf(null);
    if (slot < 0) slot = 0;
    benches[slot] = cat;
    _walks[cat] = _Walk(benchSpot(slot, cat));
  }

  @override
  void prepareBait() {}

  @override
  bool placeBait(Offset point, {bool free = false}) {
    final car = _markAt(point);
    final waiting = benches.whereType<CatComponent>().toList();
    if (car == null || waiting.isEmpty || marks[car] != null) {
      game.hud.showBanner(['Thả cá vào vạch trống để gọi mèo đang chờ'], 1.4);
      return false;
    }
    if (!free && !game.bait.spend()) return false;
    final sign = line.shownSign(car);
    final cat = waiting.firstWhere((c) => c.catType == sign,
        orElse: () => waiting.first);
    _assign(cat, car);
    if (game.bait.limited) game.hud.fishLeft = game.bait.fishCount;
    GameAudio.instance.playRescue(GameSound.baitDrop);
    game.night!.cardEffects.onFed(cat);
    return true;
  }

  void _boardReady() {
    final night = game.night!;
    for (var car = 0; car < marks.length; car++) {
      final cat = marks[car];
      if (cat == null || _walks.containsKey(cat)) continue;
      if (!line.accepts(car, cat.catType) && night.assist.calm) continue;
      marks[car] = null;
      if (line.accepts(car, cat.catType)) {
        _walks[cat] = _Walk(doorSpot(car, cat), board: true);
      } else {
        if (!night.assist.calm) game.stats.startles++;
        game.hud.showBanner(
            ['Sai toa! ${CatBreed.of(cat.catType).name} quay lại ghế chờ'],
            1.4);
        GameAudio.instance.playRescue(GameSound.catWrong);
        _sendToBench(cat);
      }
    }
  }

  @override
  void update(double dt) {
    moon.update(dt);
    final night = game.night!;
    for (final cat in game.children.whereType<CatComponent>()) {
      if (!cat.isLoaded || cat.isDelivered || cat.trapManaged) continue;
      final slot = benches.indexOf(null);
      if (slot < 0) break;
      _sizes[cat] = cat.size.clone();
      cat.enterTrap();
      cat.size.setFrom(_catSize);
      benches[slot] = cat;
      cat.positionInTrap(benchSpot(slot, cat), walking: false);
      _arrived.add(cat);
    }
    line.anyCar = night.acceptsAnyBed;
    // Helpers only hold a train that is already at the platform: holding an
    // arriving train would just make everyone wait longer.
    final stopped = line.phase == TrainPhase.stopped;
    final pace = !stopped
        ? 1.0
        : night.assist.frozen
            ? 0.0
            : night.assist.pace;
    line.update(dt * pace);
    _plan();
    if (line.phase == TrainPhase.stopped) _boardReady();
    // Calm cats (black helper) trot to their marks twice as fast.
    final step = 150 * line.walkSpeed * (night.assist.calm ? 2 : 1) * dt;
    for (final entry in _walks.entries.toList()) {
      final cat = entry.key, walk = entry.value;
      final delta = walk.target - cat.position;
      if (delta.length <= step) {
        cat.positionInTrap(walk.target, walking: false);
        _walks.remove(cat);
        if (walk.board) {
          _sizes.remove(cat);
          _arrived.remove(cat);
          if (selected == cat) selected = null;
          if (night.phase == NightPhase.playing) {
            GameAudio.instance.playRescue(GameSound.catRescue, important: true);
            cat.rescueFromTrap();
          }
        }
      } else {
        cat.positionInTrap(cat.position + delta.normalized() * step,
            walking: true);
      }
    }
  }

  Iterable<(Offset, double)> _lights() sync* {
    for (var car = 0; car < line.cars; car++) {
      yield (Offset(game.size.x * line.markX(car), game.size.y * .6), 60);
    }
    for (var i = 0; i < benches.length; i++) {
      yield (Offset(game.size.x * (.1 + i * .16), game.size.y * .3), 40);
    }
    if (line.phase != TrainPhase.waiting) {
      for (var car = 0; car < line.cars; car++) {
        yield (
          Offset(
              game.size.x * (line.markX(car) + line.offset), game.size.y * .84),
          58
        );
      }
    }
  }
}
