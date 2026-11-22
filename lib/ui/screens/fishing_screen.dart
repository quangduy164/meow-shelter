import 'dart:math' as math;
import 'package:material_ui/material_ui.dart';
import 'package:flutter/scheduler.dart';

import '../../camp/camp_state.dart';
import '../../fishing/fishing_river.dart';
import '../../fishing/fishing_controller.dart';
import '../../fishing/fishing_island.dart';
import '../widgets/fishing_controls.dart';
import '../widgets/fishing_painter.dart';
import '../widgets/fishing_distance.dart';
import '../widgets/fishing_catch_popup.dart';
import '../widgets/fishing_fish_art.dart';
import '../../game/cats/cat_breed.dart';
import '../../game/constants.dart';
import '../design.dart';
import '../widgets/cat_sprite.dart';
import '../widgets/fish_collection_dialog.dart';
import '../widgets/fishing_action_button.dart';
import '../widgets/fishing_river_scene.dart';
import '../widgets/fishing_island_art.dart';
import '../widgets/fishing_scenery.dart';
import '../widgets/fishing_cabin_art.dart';
import '../widgets/fishing_minimap.dart';
import '../widgets/fishing_cave_run.dart';
import '../widgets/fishing_night_overlay.dart';
import '../widgets/fishing_weather_overlay.dart';
import '../../fishing/fishing_weather.dart';
import '../../fishing/fishing_trip.dart';
import '../widgets/fishing_rocky_bay_art.dart';
import '../widgets/fishing_oar_art.dart';
import '../widgets/game_glyphs.dart';
import '../widgets/game_surfaces.dart';
import '../widgets/round_button.dart';
import '../../collection/fish_collection.dart';

class FishingScreen extends StatefulWidget {
  const FishingScreen({super.key});

  @override
  State<FishingScreen> createState() => _FishingScreenState();
}

class _FishingScreenState extends State<FishingScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final FishingController _controller;
  FishingRiverRound get _river => _controller.river;
  final _frames = ValueNotifier(0);
  late final Ticker _ticker;
  Duration? _lastTick;
  bool _collectionOpen = false, _paused = false, _choosingCat = true;

  /// Scene shown by the last build; a change triggers one rebuild.
  bool _shownCabin = false, _shownCave = false;

  /// Area name shown under the minimap.
  String _area = '';

  String get _areaName => _river.island.lookout
      ? 'Đỉnh hải đăng'
      : _river.island.ashore
          ? (_river.island.onBank ? 'Dạo bờ sông' : 'Đảo dừa')
          : FishingRiver.sectionName(_controller.angler.dx,
              y: _controller.angler.dy);

  double _sinceClock = 0, _sinceWeather = 0;

  /// Day/night follows the device clock; refreshed every few seconds.
  void _setHour(DateTime now) {
    final hour = now.hour + now.minute / 60 + now.second / 3600;
    _river.hour = hour;
    _river.weather = FishingWeather.at(now);
    _controller.setWorldHour(hour);
  }

  void _updateHud(double dt) {
    _sinceWeather += dt;
    if (_sinceWeather > .5) {
      _sinceWeather = 0;
      _river.weather = FishingWeather.at(DateTime.now());
    }
    _sinceClock += dt;
    if (_sinceClock > 10) {
      _sinceClock = 0;
      _setHour(DateTime.now());
    }
    _area = _areaName;
  }

  String _cat = 'orange';
  String? _lastCat;
  double _sinceSave = 0;
  Offset _savedBoat = Offset.zero;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = FishingController(FishCollection.instance);
    final now = DateTime.now();
    _setHour(now);
    final preferences = FishCollection.instance.preferences;
    FishingTrip.restore(preferences, _river);
    _savedBoat = _river.boat;
    _lastCat = FishingTrip.lastCat(preferences);
    _ticker = createTicker(_tick);
  }

  void _tick(Duration timestamp) {
    final previous = _lastTick;
    _lastTick = timestamp;
    if (previous == null || _paused || _collectionOpen) return;
    final dt = math.min((timestamp - previous).inMicroseconds / 1000000, .05);
    _controller.update(dt);
    _updateHud(dt);
    _frames.value++;
    if (_river.cabin.inside != _shownCabin ||
        _river.cave.inside != _shownCave) {
      setState(() {});
    }
    _sinceSave += (timestamp - previous).inMicroseconds / 1000000;
    if (_sinceSave > 4 &&
        (_river.exploration.changed ||
            (_river.boat - _savedBoat).distance > 40)) {
      _saveTrip();
    }
  }

  void _saveTrip() {
    if (_choosingCat) return;
    _sinceSave = 0;
    _savedBoat = _river.boat;
    FishingTrip.save(FishCollection.instance.preferences, _river, _cat);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _paused = state != AppLifecycleState.resumed;
    if (_paused) _saveTrip();
    _controller.setPulling(false);
    _controller.stopSteering();
    _lastTick = null;
  }

  Future<void> _openCollection() async {
    if (_collectionOpen || _controller.active) return;
    setState(() => _collectionOpen = true);
    try {
      await showGameDialog<void>(
          context: context,
          builder: (_) =>
              FishCollectionDialog(collection: FishCollection.instance));
    } finally {
      if (mounted) setState(() => _collectionOpen = false);
      _lastTick = null;
    }
  }

  Future<void> _openMap() async {
    if (_collectionOpen) return;
    setState(() => _collectionOpen = true);
    final cells = _river.exploration.cells;
    final percent = cells.where((seen) => seen).length * 100 ~/ cells.length;
    try {
      await showGameDialog<void>(
          context: context,
          builder: (context) => LayoutBuilder(builder: (context, box) {
                final width = math.min(
                    box.maxWidth * .9,
                    (box.maxHeight * .7) *
                        FishingRiver.length /
                        FishingRiver.height);
                return Center(
                    child: Material(
                        color: Colors.transparent,
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                          SizedBox(
                              width: width + 6,
                              child: Row(children: [
                                Expanded(
                                    child: Text(
                                        'BẢN ĐỒ · ĐÃ KHÁM PHÁ $percent%',
                                        style: const TextStyle(
                                            color: DS.cream,
                                            fontWeight: FontWeight.w900,
                                            fontSize: DS.fontButton))),
                                RoundButton(
                                    glyph: GameGlyph.close,
                                    size: 40,
                                    tooltip: 'Đóng bản đồ',
                                    onPressed: () => Navigator.pop(context)),
                              ])),
                          const SizedBox(height: DS.spaceSm),
                          FishingMinimap(
                              round: _river,
                              frames: _frames,
                              size: width,
                              full: true),
                        ])));
              }));
    } finally {
      if (mounted) setState(() => _collectionOpen = false);
      _lastTick = null;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _saveTrip();
    _ticker.dispose();
    _controller.dispose();
    _frames.dispose();
    super.dispose();
  }

  Widget _catChoices(ValueChanged<String> onSelected) => Wrap(
        alignment: WrapAlignment.center,
        spacing: DS.spaceSm,
        runSpacing: DS.spaceSm,
        children: [
          for (final breed in CatBreed.all)
            if (CampState.instance.unlocked(breed.id))
              SizedBox(
                  width: 140,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(backgroundColor: DS.cream),
                    onPressed: () => onSelected(breed.id),
                    child: Padding(
                      padding: const EdgeInsets.all(DS.spaceSm),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        CatFace(breed.id, size: 84),
                        const SizedBox(height: DS.spaceSm),
                        Text(CampState.instance.nameOf(breed.id),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        if (breed.id == _lastCat)
                          const Text('Chuyến trước',
                              style: TextStyle(
                                  color: DS.wood,
                                  fontSize: DS.fontCaption,
                                  fontWeight: FontWeight.w900)),
                      ]),
                    ),
                  )),
        ],
      );

  Widget _catSelection() => DecoratedBox(
        decoration: const BoxDecoration(
            gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [DS.selectionBackdrop, Color(0xFF477471)],
        )),
        child: SafeArea(
            child: Padding(
          padding: const EdgeInsets.all(DS.spaceMd),
          child: Column(children: [
            Row(children: [
              RoundButton(
                  glyph: GameGlyph.home,
                  tooltip: 'Về Trang chủ',
                  onPressed: () => Navigator.pop(context)),
              const Expanded(
                  child: Text('CHỌN MÈO ĐI CÂU',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: DS.cream,
                          fontSize: DS.fontTitle,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1))),
              const SizedBox(width: 48),
            ]),
            const SizedBox(height: DS.spaceMd),
            const Text('Chọn một bé mèo để bắt đầu chuyến đi câu',
                textAlign: TextAlign.center,
                style: TextStyle(color: DS.cream, fontSize: DS.fontBody)),
            Expanded(
                child: Center(
                    child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: DS.spaceLg),
              child: _catChoices((type) {
                if (!_choosingCat) return;
                setState(() {
                  _cat = type;
                  _choosingCat = false;
                  _lastTick = null;
                });
                _ticker.start();
              }),
            ))),
          ]),
        )),
      );

  Widget _boat() {
    final point = _river.toScreen(_controller.angler);
    final catSize = (_river.island.ashore ? 84 : 114) * _river.scale;
    final phase = _controller.phase;
    final won = phase == FishingPhase.caught;
    final fishing = _controller.showFishingArt;
    final facingRight = fishing
        ? _controller.spot.dx >= _controller.angler.dx
        : _river.heading.dx >= 0;
    final oar = FishingOarPose(_river.clock,
        moving: _river.moving && !fishing, facingRight: facingRight);
    final side = facingRight ? 1.0 : -1.0;
    final lean = switch (phase) {
      FishingPhase.casting =>
        side * math.sin(_controller.elapsed / .65 * math.pi * 2) * -.12,
      FishingPhase.bite => math.sin(_controller.clock * 20) * .035,
      FishingPhase.reeling => _controller.pulling
          ? -side * (.08 + _controller.tension * .12)
          : side * .025,
      _ => oar.lean,
    };
    final action = won ? 'celebrate' : 'idle';
    final frames = won ? framesCelebrate : framesIdle;
    return Stack(fit: StackFit.expand, children: [
      CustomPaint(
          painter: FishingRiverBoatPainter(_river,
              fishing: fishing && !_river.island.ashore)),
      if (!_river.island.ashore)
        Positioned(
            left: point.dx - catSize / 2,
            top: point.dy -
                catSize * .69 +
                math.sin(_river.clock * 2.5) * 1.8 * _river.scale,
            child: Transform.rotate(
              angle: lean,
              alignment: Alignment.bottomCenter,
              child: CatSprite(
                  type: _cat,
                  size: catSize,
                  action: action,
                  frames: frames,
                  frame: (_river.clock * 7).floor() % frames,
                  flip: !facingRight),
            )),
      CustomPaint(
          painter: FishingRiverBoatPainter(_river,
              front: true,
              fishing: fishing && !_river.island.ashore,
              pawColor: CatBreed.of(_cat).color)),
      if (fishing)
        Builder(builder: (context) {
          final spot = _river.toScreen(_controller.spot);
          return CustomPaint(
              painter: FishingPainter(
            phase: phase,
            fish: _controller.fish,
            boat: Offset(point.dx / _river.viewport.width,
                point.dy / _river.viewport.height),
            spot: Offset(spot.dx / _river.viewport.width,
                spot.dy / _river.viewport.height),
            facingRight: facingRight,
            artScale: _river.scale * (_river.island.ashore ? .74 : 1),
            clock: _controller.clock,
            elapsed: _controller.elapsed,
            progress: _controller.progress,
            tension: _controller.tension,
            pulling: _controller.pulling,
            drift: _controller.drift,
            sweetCenter: _controller.sweetCenter,
            combo: _controller.combo,
          ));
        }),
      if (won && _controller.elapsed < 1)
        Builder(builder: (context) {
          final t =
              Curves.easeInOut.transform(_controller.elapsed.clamp(0.0, 1.0));
          final position =
              Offset.lerp(_river.toScreen(_controller.spot), point, t)! -
                  Offset(0, math.sin(t * math.pi) * 45);
          final fishSize = _controller.fishScale;
          return Positioned(
              left: position.dx - 20 * fishSize,
              top: position.dy - 14 * fishSize,
              child: SizedBox(
                  width: 40 * fishSize,
                  height: 28 * fishSize,
                  child:
                      CustomPaint(painter: FishingFishArt(_controller.fish))));
        }),
    ]);
  }

  Widget _islandCat() {
    final island = _river.island;
    if (!island.ashore) return const SizedBox.shrink();
    final point = _river.toScreen(island.cat);
    final fishing = _controller.showFishingArt;
    final size = 84 * _river.scale;
    final action = island.walking ? 'walk' : 'idle';
    final frames = island.walking ? framesWalk : framesIdle;
    return Stack(children: [
      if (!island.lookout)
        Positioned(
            left: point.dx - 14 * _river.scale,
            top: point.dy - 3 * _river.scale,
            child: Container(
                width: 28 * _river.scale,
                height: 10 * _river.scale,
                decoration: const BoxDecoration(
                    color: Color(0x3359553B), shape: BoxShape.circle))),
      Positioned(
          left: point.dx - size / 2,
          top: point.dy - size * .78 - island.jump * _river.scale,
          child: CatSprite(
              type: _cat,
              size: size,
              action: action,
              frames: frames,
              frame:
                  (_river.clock * (island.walking ? 10 : 7)).floor() % frames,
              flip: fishing
                  ? _controller.spot.dx < island.cat.dx
                  : !island.facingRight)),
    ]);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: _choosingCat
            ? _catSelection()
            : LayoutBuilder(builder: (context, constraints) {
                _river
                    .resize(Size(constraints.maxWidth, constraints.maxHeight));
                final padding = MediaQuery.paddingOf(context);
                _shownCabin = _river.cabin.inside;
                _shownCave = _river.cave.inside;
                // Cabin and cave scenes still rebuild every frame (they read
                // the round directly); the river scene below does not.
                if (_shownCabin) {
                  return AnimatedBuilder(
                      animation: _frames,
                      builder: (context, _) => FishingCabinRoom(
                          round: _river.cabin,
                          cat: _cat,
                          onExit: _river.cabin.requestExit,
                          hour: _river.hour));
                }
                if (_shownCave) {
                  return AnimatedBuilder(
                      animation: _frames,
                      builder: (context, _) => FishingCaveRun(
                          cave: _river.cave,
                          cat: _cat,
                          onExit: () => setState(_river.cave.exit)));
                }
                // Painters repaint themselves through [_frames]; only the
                // cat/boat widgets and the HUD rebuild per frame.
                return Stack(fit: StackFit.expand, children: [
                  // Everything under the cat shares one layer.
                  RepaintBoundary(
                      child: Stack(fit: StackFit.expand, children: [
                    const ColoredBox(color: Color(0xFFA7BF78)),
                    FishingRiverBackdrop(round: _river, frames: _frames),
                    CustomPaint(
                        painter: FishingRiverSurface(_river, _frames,
                            fishing: _controller)),
                    CustomPaint(painter: FishingIslandPainter(_river, _frames)),
                    FishingCabinShip(round: _river, frames: _frames),
                  ])),
                  FishingScenery(
                      round: _river,
                      frames: _frames,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapUp: (event) {
                          if (!_collectionOpen) {
                            final now = DateTime.now();
                            _controller
                                .setWorldHour(now.hour + now.minute / 60);
                            _controller.tapRiver(event.localPosition);
                          }
                        },
                        onPanUpdate: (event) => _controller.steerBoat(
                            Offset(event.delta.dx / 90, event.delta.dy / 70)),
                        onPanEnd: (_) => _controller.stopSteering(),
                        onPanCancel: _controller.stopSteering,
                        child: IgnorePointer(
                            child: AnimatedBuilder(
                                animation: _frames,
                                builder: (context, _) => Stack(
                                    fit: StackFit.expand,
                                    children: [_boat(), _islandCat()]))),
                      )),
                  // Light and weather overlays share one layer.
                  IgnorePointer(
                      child: RepaintBoundary(
                          child: Stack(fit: StackFit.expand, children: [
                    CustomPaint(painter: FishingCaveLight(_river, _frames)),
                    CustomPaint(painter: FishingNightOverlay(_river, _frames)),
                    CustomPaint(
                        painter: FishingWeatherOverlay(_river, _frames)),
                  ]))),
                  AnimatedBuilder(
                      animation: _frames,
                      builder: (context, _) =>
                          Stack(fit: StackFit.expand, children: [
                            Positioned(
                                left: padding.left + 8,
                                top: padding.top + 8,
                                child: RoundButton(
                                    glyph: GameGlyph.home,
                                    size: 44,
                                    tooltip: 'Về Trang chủ',
                                    onPressed: () => Navigator.pop(context))),
                            if (!(_controller.phase == FishingPhase.reeling))
                              Positioned(
                                  right: padding.right + 8,
                                  top: padding.top + 8,
                                  child: GestureDetector(
                                      onTap: _openMap,
                                      child: Tooltip(
                                          message: 'Mở bản đồ',
                                          child: Opacity(
                                              opacity: .9,
                                              child: Column(children: [
                                                FishingMinimap(
                                                    round: _river,
                                                    frames: _frames),
                                                Container(
                                                    width: 110,
                                                    margin: const EdgeInsets
                                                        .only(top: 3),
                                                    padding: const EdgeInsets
                                                        .symmetric(vertical: 2),
                                                    decoration: BoxDecoration(
                                                        color: const Color(
                                                            0xB31E2A30),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8)),
                                                    child: Text(
                                                        _area,
                                                        textAlign:
                                                            TextAlign.center,
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: const TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 11,
                                                            fontWeight:
                                                                FontWeight
                                                                    .w700))),
                                              ]))))),
                            Positioned(
                                left: padding.left + 12,
                                bottom: padding.bottom + 12,
                                child: Opacity(
                                    opacity: _controller.phase ==
                                            FishingPhase.reeling
                                        ? .35
                                        : 1,
                                    child: FishingActionButton(
                                        tooltip: 'Bộ sưu tập cá',
                                        onPressed: _controller.active
                                            ? null
                                            : _openCollection,
                                        tool: FishingTool.basket))),
                            if (_controller.phase == FishingPhase.reeling)
                              Positioned(
                                  left: padding.left + 10,
                                  top: padding.top + 80,
                                  bottom: padding.bottom + 85,
                                  width: 54,
                                  child: IgnorePointer(
                                      child: FishingDistance(
                                          progress: _controller.progress))),
                            if (_river.island.ashore &&
                                !_river.island.lookout &&
                                !_controller.showFishingArt)
                              Positioned(
                                  right: padding.right + 98,
                                  bottom: padding.bottom + 22,
                                  child: FishingActionButton(
                                      tool: FishingTool.boat,
                                      tooltip: 'Về thuyền',
                                      onPressed: _controller.phase ==
                                                  FishingPhase.saving ||
                                              _controller.phase ==
                                                  FishingPhase.caught
                                          ? null
                                          : _controller.returnToBoat)),
                            if (!_river.island.lookout &&
                                (!_river.island.ashore ||
                                    _river.island.phase ==
                                        IslandVisitPhase.exploring))
                              Positioned(
                                  right: padding.right + 8,
                                  bottom: padding.bottom + 8,
                                  width: 80,
                                  height: 80,
                                  child:
                                      FishingControls(controller: _controller)),
                            if (_controller.active &&
                                _controller.phase != FishingPhase.saving)
                              Positioned(
                                  right: padding.right + 98,
                                  bottom: padding.bottom + 26,
                                  child: RoundButton(
                                      glyph: GameGlyph.close,
                                      size: 36,
                                      tooltip: 'Cất cần để chèo tiếp',
                                      onPressed: _controller.cancelCast)),
                            if (_controller.phase == FishingPhase.caught &&
                                _controller.elapsed >= 1)
                              Positioned.fill(
                                  child: FishingCatchPopup(
                                      fish: _controller.fish,
                                      grams: _controller.grams,
                                      newRecord: _controller.newRecord,
                                      fishScale: _controller.fishScale,
                                      onNext: _controller.dismissResult)),
                          ])),
                ]);
              }),
      );
}
