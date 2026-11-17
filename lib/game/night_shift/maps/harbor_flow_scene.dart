import 'dart:math' as math;
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
import 'harbor_flow.dart';
import 'harbor_flow_painter.dart';

class HarborFlowScene extends NightScene {
  HarborFlowScene(this.game, {required this.onFirstLight});
  final MeowShelterGame game;
  final void Function(Offset, double) onFirstLight;
  final flow = HarborFlow();
  final moon = Moonlight();
  final _parts = <Component>[];
  final _gates = <HarborGateComponent>[];
  final _cats = <HarborRaft, CatComponent>{};
  final _sizes = <CatComponent, Vector2>{};
  final _waiting = <CatComponent>[];
  bool _preparedAnchor = false;

  @override
  NightMap get map => NightMap.harbor;
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
  bool get hasBaitInTransit => _cats.isNotEmpty || _waiting.isNotEmpty;
  @override
  List<String> get rules => [
        'Chạm cửa nước để đổi hướng bè ở mỗi chặng',
        'Kéo cá lên bè để neo bè 2.5 giây',
      ];
  @override
  void onMistake() {}
  @override
  bool blocks(Rect bounds) => false;
  @override
  bool allowsBait(Offset point, Size field) =>
      flow.near(Offset(point.dx / field.width, point.dy / field.height)) !=
      null;
  @override
  bool isLit(Offset point, Size size) =>
      moon.contains(point, size) || _nearRaft(point);
  bool _nearRaft(Offset point) => flow.rafts
      .any((r) => (_px(r.center) - point).distance < game.size.x * .07);
  @override
  bool overlappingLights(Offset point, Size size) =>
      moon.contains(point, size) && _nearRaft(point);

  Offset _px(Offset p) => Offset(p.dx * game.size.x, p.dy * game.size.y);

  @override
  void mount() {
    _parts.addAll([
      HarborBackground(flow),
      HarborRaftsComponent(flow),
      DarknessComponent(
          lights: _lights,
          visible: () => game.hud.status == RoundStatus.playing,
          additionalLights: (canvas, size) =>
              paintMoonlitField(canvas, size, moon),
          shade: const Color(0x28142932)),
      HarborMoon(moon),
    ]);
    game.addAll(_parts);
  }

  @override
  void remove() {
    for (final cat in [..._cats.values, ..._waiting]) {
      final size = _sizes[cat];
      if (size != null) cat.size.setFrom(size);
      cat.leaveTrap();
    }
    _cats.clear();
    _sizes.clear();
    game.removeAll([..._parts, ..._gates]);
    _parts.clear();
    _gates.clear();
  }

  @override
  void begin(NightRun run,
      {required bool thickClouds, required double afterglowSeconds}) {
    flow.begin(run);
    moon.reset(fullMoon: run.has(NightCard.fullMoon), thickClouds: thickClouds);
    _cats.clear();
    _sizes.clear();
    game.removeAll(_gates);
    _gates
      ..clear()
      ..addAll([
        for (final gate in flow.gates)
          HarborGateComponent(gate, flow,
              onTapGate: tapGate, onSwipeGate: swipeGate)
      ]);
    game.addAll(_gates);
  }

  void swipeGate(HarborGate gate, int direction) {
    if (game.paused || game.night?.phase != NightPhase.playing) return;
    flow.setDirection(gate, direction);
    _changedGate(gate);
  }

  void tapGate(HarborGate gate) {
    if (game.paused || game.night?.phase != NightPhase.playing) return;
    flow.turn(gate);
    _changedGate(gate);
  }

  void _changedGate(HarborGate gate) {
    GameAudio.instance.playRescue(GameSound.click);
    if (!gate.chimed) {
      gate.chimed = true;
      onFirstLight(
          _px(Offset(gate.x, HarborFlow.laneY[gate.lane])), game.size.x * .16);
    }
  }

  @override
  void prepareBait() {
    final raft = flow.rafts.firstOrNull;
    if (raft != null) raft.anchor = 2.5;
  }

  @override
  bool placeBait(Offset point, {bool free = false}) {
    final raft =
        flow.near(Offset(point.dx / game.size.x, point.dy / game.size.y));
    if (raft == null ||
        (_px(raft.center) - point).distance > game.size.x * .09) {
      game.hud.showBanner(['Thả cá lên một chiếc bè'], 1.4);
      return false;
    }
    if (!free && !game.bait.spend()) return false;
    raft.anchor = 2.5;
    if (game.bait.limited) game.hud.fishLeft = game.bait.fishCount;
    GameAudio.instance.playRescue(GameSound.baitDrop);
    final cat = _cats[raft];
    if (cat != null) game.night!.cardEffects.onFed(cat);
    return true;
  }

  void _seat(HarborRaft raft, CatComponent cat) {
    final center = _px(raft.center);
    cat.positionInTrap(
        Vector2(center.dx - cat.size.x / 2, center.dy - cat.size.y * .82),
        walking: false);
  }

  @override
  void update(double dt) {
    moon.update(dt);
    final night = game.night!;
    for (final cat in game.children.whereType<CatComponent>()) {
      if (!cat.isLoaded ||
          cat.isDelivered ||
          cat.trapManaged ||
          _cats.containsValue(cat)) {
        continue;
      }
      _sizes[cat] = cat.size.clone();
      cat.enterTrap();
      cat.size.scale(math.min(1, game.size.y * .15 / cat.size.y));
      _waiting.add(cat);
    }
    for (var i = 0; i < _waiting.length; i++) {
      final cat = _waiting[i];
      cat.positionInTrap(
          Vector2(game.size.x * .028 - cat.size.x / 2,
              game.size.y * (.25 + i * .12)),
          walking: false);
    }
    for (final cat in _waiting.toList()) {
      final lanes = [0, 1, 2].where(flow.startClear).toList();
      if (lanes.isEmpty) break;
      final relabel = flow.assignDock(cat.catType, [
        for (final raft in flow.rafts) raft.breed,
        for (final other in _waiting)
          if (other != cat) other.catType,
      ]);
      if (relabel == null) continue;
      if (relabel >= 0) {
        game.hud.showBanner(
            ['Bến ${relabel + 1} đổi sang ${CatBreed.of(cat.catType).name}'],
            1.5);
      }
      _waiting.remove(cat);
      final raft =
          flow.launch(lanes[game.random.nextInt(lanes.length)], cat.catType);
      if (_preparedAnchor) {
        raft.anchor = 2.5;
        _preparedAnchor = false;
      }
      _cats[raft] = cat;
      _seat(raft, cat);
    }
    final pace = night.assist.frozen ? 0.0 : night.assist.pace;
    for (final (raft, event) in flow.update(dt, pace: pace)) {
      final cat = _cats[raft];
      if (event == HarborEvent.docked) {
        _cats.remove(raft);
        if (cat != null && night.phase == NightPhase.playing) {
          GameAudio.instance.playRescue(GameSound.catRescue, important: true);
          cat.rescueFromTrap();
        }
      } else {
        if (!night.assist.calm) game.stats.startles++;
        game.hud.showBanner([
          switch (event) {
            HarborEvent.wrongDock => 'Nhầm bến! Bè phải về bến cùng màu',
            HarborEvent.collided => 'Hai bè va nhau! Quay lại bến xuất phát',
            _ => 'Bè lạc luồng! Quay lại bến xuất phát',
          }
        ], 1.4);
        GameAudio.instance.playRescue(GameSound.catWrong);
      }
    }
    for (final entry in _cats.entries) {
      _seat(entry.key, entry.value);
    }
  }

  Iterable<(Offset, double)> _lights() sync* {
    for (final lane in flow.dockBreeds.keys) {
      yield (_px(Offset(.962, HarborFlow.laneY[lane] - .05)), 48);
    }
    for (final raft in flow.rafts) {
      yield (_px(raft.center), 64);
    }
    for (final gate in flow.gates) {
      yield (_px(Offset(gate.x, HarborFlow.laneY[gate.lane])), 26);
    }
  }
}
