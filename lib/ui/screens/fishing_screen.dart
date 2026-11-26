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
import '../widgets/fishing_clock_chip.dart';
import '../widgets/fishing_quest_hud.dart';
import '../widgets/fishing_dialog_kit.dart';
import '../../fishing/fishing_quests.dart';
import '../widgets/fishing_cave_run.dart';
import '../widgets/fishing_night_overlay.dart';
import '../widgets/fishing_weather_overlay.dart';
import '../../fishing/fishing_weather.dart';
import '../../fishing/fishing_trip.dart';
import '../widgets/fishing_rocky_bay_art.dart';
import '../widgets/fishing_oar_art.dart';
import '../../audio/game_audio.dart';
import '../widgets/game_glyphs.dart';
import '../widgets/game_surfaces.dart';
import '../widgets/round_button.dart';
import '../widgets/paw_loader.dart';
import '../../collection/fish_collection.dart';
import '../../fishing/fishing_boat.dart';
import '../../fishing/fishing_rod.dart';
import '../../fishing/fishing_lighting.dart';
import '../widgets/fishing_boats.dart';
import '../widgets/fishing_market_dialog.dart';
import '../widgets/fishing_shrine.dart';
import '../widgets/fishing_bait_house.dart';
import '../widgets/fishing_rod_house.dart';
import '../widgets/fishing_market_art.dart';

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
  bool _loadingCat = false;

  /// Everything the HUD shows except per-frame animation; it rebuilds only
  /// when this value changes (records compare by value).
  final _hud = ValueNotifier<Object?>(null);
  Object get _hudState => (
        _controller.phase,
        _controller.active,
        _river.island.ashore,
        _river.island.lookout,
        _river.island.phase,
        _controller.showFishingArt,
        _controller.phase == FishingPhase.caught && _controller.elapsed >= 1,
        _area,
        _controller.tutorialStep,
        _questToast,
      );

  /// Step just finished, shown as a banner for a few seconds.
  FishingQuest? _questToast;
  double _questToastLeft = 0;

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

  /// Day/night runs on a 40-minute game day (FishingLighting.gameHour).
  void _setHour(DateTime now) {
    final hour = FishingLighting.gameHour(now);
    _river.hour = hour;
    _river.weather = FishingWeather.at(now);
    _controller.setWorldHour(hour);
  }

  void _updateHud(double dt) {
    final quests = FishingQuests.instance;
    if (quests.justDone != null) {
      _questToast = quests.justDone;
      quests.justDone = null;
      _questToastLeft = 3;
    } else if (_questToast != null) {
      _questToastLeft -= dt;
      if (_questToastLeft <= 0) _questToast = null;
    }
    // A night in the cabin bed: jump the shared game clock to sunrise (6:00).
    if (_river.cabin.dawnDue) {
      _river.cabin.dawnDue = false;
      final now = DateTime.now();
      final hour = FishingLighting.gameHour(now);
      if (hour >= 18 || hour < 6) {
        FishCollection.instance.preferences
            .setInt(FishingLighting.shiftKey, FishingLighting.skipTo(6, now));
        _setHour(now);
      }
    }
    _sinceWeather += dt;
    if (_sinceWeather > .5) {
      _sinceWeather = 0;
      _river.weather = FishingWeather.at(DateTime.now());
    }
    _sinceClock += dt;
    // A 40-minute day moves 0.6 game minutes per second: refresh every second.
    if (_sinceClock > 1) {
      _sinceClock = 0;
      _setHour(DateTime.now());
    }
    _area = _areaName;
    GameAudio.instance.setAmbient(_ambientName);
  }

  String? get _ambientName {
    if (_river.cabin.inside) return null;
    if (_river.cave.inside || FishingRiver.inCave(_controller.angler)) {
      return 'ambientCave';
    }
    if (_river.weather.rain > .35) return 'ambientRain';
    if (_river.hour < 6 || _river.hour >= 18) return 'ambientNight';
    final region =
        FishingRiver.regionAt(_controller.angler.dx, y: _controller.angler.dy);
    if (_river.island.ashore && !_river.island.onBank ||
        region == FishingRegion.coast ||
        region == FishingRegion.rockyBay ||
        region == FishingRegion.openSea) {
      return 'ambientSea';
    }
    return region == FishingRegion.mangrove ? 'ambientRiver' : 'ambientVillage';
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
    final preferences = FishCollection.instance.preferences;
    FishingLighting.shiftMs = preferences.getInt(FishingLighting.shiftKey) ?? 0;
    final now = DateTime.now();
    _setHour(now);
    FishingQuests.instance.sync();
    FishingTrip.restore(preferences, _river);
    _savedBoat = _river.boat;
    _river.boatStyle = FishingBoat.load(preferences);
    _lastCat = FishingTrip.lastCat(preferences);
    _ticker = createTicker(_tick);
  }

  void _tick(Duration timestamp) {
    final previous = _lastTick;
    _lastTick = timestamp;
    if (previous == null || _paused || _collectionOpen) return;
    final dt = math.min((timestamp - previous).inMicroseconds / 1000000, .05);
    final swan = _river.boatStyle == FishingBoat.swan;
    final strokeBefore = swan
        ? (_river.clock * 9 / (2 * math.pi)).floor()
        : ((_river.clock / 1.65) % 1);
    _controller.update(dt);
    final strokeAfter = swan
        ? (_river.clock * 9 / (2 * math.pi)).floor()
        : ((_river.clock / 1.65) % 1);
    // Sync the sound to the swan's pedal push or the oar entering the water.
    if (_river.moving &&
        !_controller.showFishingArt &&
        (swan
            ? strokeAfter != strokeBefore
            : strokeBefore < .18 && strokeAfter >= .18)) {
      GameAudio.instance
          .playGameplay(swan ? GameSound.fishingPedal : GameSound.fishingRow);
    }
    // The boat picker only opens once the cat has reached the boathouse.
    switch (_controller.takeArrival()) {
      case FishingVisit.rodHouse:
        _openRodHouse();
      case FishingVisit.boatHouse:
        _openBoatPicker();
      case FishingVisit.market:
        _openMarket();
      case FishingVisit.shrine:
        _openShrine();
      case FishingVisit.baitHouse:
        _openBaitHouse();
      case null:
        break;
    }
    _updateHud(dt);
    _frames.value++;
    _hud.value = _hudState;
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
    if (_controller.tutorialAwaitsBasket) _controller.finishTutorial();
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
                                const FishingClockChip(),
                                const SizedBox(width: DS.spaceSm),
                                FlatRoundButton(
                                    glyph: GameGlyph.close,
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

  Future<void> _openQuests() async {
    if (_collectionOpen) return;
    setState(() => _collectionOpen = true);
    try {
      await showGameDialog<void>(
          context: context, builder: (_) => const FishingQuestDialog());
    } finally {
      if (mounted) setState(() => _collectionOpen = false);
      _lastTick = null;
    }
  }

  Future<void> _openBaitHouse() async {
    setState(() => _collectionOpen = true);
    try {
      await showGameDialog<void>(
          context: context, builder: (_) => const FishingBaitHouseDialog());
    } finally {
      if (mounted) setState(() => _collectionOpen = false);
      _lastTick = null;
    }
  }

  Future<void> _openShrine() async {
    setState(() => _collectionOpen = true);
    try {
      await showGameDialog<void>(
          context: context, builder: (_) => const FishingShrineDialog());
      await FishingQuests.instance.sync();
    } finally {
      if (mounted) setState(() => _collectionOpen = false);
      _lastTick = null;
    }
  }

  Future<void> _openMarket() async {
    setState(() => _collectionOpen = true);
    try {
      await showGameDialog<void>(
          context: context, builder: (_) => const FishingMarketDialog());
    } finally {
      if (mounted) setState(() => _collectionOpen = false);
      _lastTick = null;
    }
  }

  Future<void> _openRodHouse() async {
    setState(() => _collectionOpen = true);
    try {
      await showGameDialog<void>(
          context: context,
          builder: (_) => FishingRodHouseDialog(controller: _controller));
    } finally {
      if (mounted) setState(() => _collectionOpen = false);
      _lastTick = null;
    }
  }

  Future<void> _openBoatPicker() async {
    setState(() => _collectionOpen = true);
    try {
      await showGameDialog<void>(
          context: context,
          builder: (context) => GameDialog(
              maxWidth: 540,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                FishingDialogHeader(
                    icon: Icons.sailing_rounded,
                    title: 'Nhà thuyền',
                    onClose: () => Navigator.pop(context)),
                const SizedBox(height: DS.spaceSm),
                Row(children: [
                  for (final boat in FishingBoat.values) ...[
                    if (boat != FishingBoat.values.first)
                      const SizedBox(width: DS.spaceMd),
                    Expanded(
                        child: _BoatChoice(
                            boat: boat,
                            selected: boat == _river.boatStyle,
                            onTap: () {
                              _river.boatStyle = boat;
                              FishingBoat.save(
                                  FishCollection.instance.preferences, boat);
                              Navigator.pop(context);
                            })),
                  ],
                ]),
              ])));
    } finally {
      if (mounted) setState(() => _collectionOpen = false);
      _lastTick = null;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    GameAudio.instance.setAmbient(null);
    _saveTrip();
    _ticker.dispose();
    _controller.dispose();
    _frames.dispose();
    _hud.dispose();
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
                    onPressed: _loadingCat ? null : () => onSelected(breed.id),
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

  Future<void> _startWithCat(String type) async {
    if (!_choosingCat || _loadingCat) return;
    setState(() => _loadingCat = true);
    final scale = MediaQuery.sizeOf(context).height / FishingRiver.viewHeight;
    await CatSprite.precacheActions(context, type: type, actions: const [
      'idle',
      'row',
      'walk',
      'jump',
      'fish-cast',
      'fish-wait',
      'fish-reel',
      'fish-hold'
    ], sizes: [
      114 * scale,
      84 * scale
    ]);
    if (!mounted) return;
    setState(() {
      _cat = type;
      _choosingCat = false;
      _loadingCat = false;
      _lastTick = null;
    });
    _ticker.start();
  }

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
              FlatRoundButton(
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
            SizedBox(
                height: 32,
                child: Center(
                    child: _loadingCat
                        ? const PawLoader(size: 32, color: DS.cream)
                        : const Text('Chọn một bé mèo để bắt đầu chuyến đi câu',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: DS.cream, fontSize: DS.fontBody)))),
            Expanded(
                child: Center(
                    child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: DS.spaceLg),
              child: _catChoices(_startWithCat),
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
    _river.catFacingRight = facingRight;
    // Where the lantern rod's lantern hangs, for its glow in the dark.
    final f = _river.island.ashore ? .74 : 1.0;
    _river.rodLantern = fishing && !won && _controller.rod == FishingRod.lantern
        ? _controller.angler + Offset((facingRight ? 1 : -1) * 80, -62) * f
        : null;
    // The sheets animate casting, reeling and rowing; only the bite shakes.
    final lean = phase == FishingPhase.bite
        ? math.sin(_controller.clock * 20) * .035
        : 0.0;
    // The swan is pedalled: no oar, the cat bobs gently with each push.
    final pedalling =
        _river.boatStyle == FishingBoat.swan && _river.moving && !fishing;
    final rowing =
        _river.moving && !fishing && _river.boatStyle != FishingBoat.swan;
    final pedalBob = pedalling
        ? -math.sin(_river.clock * 9).abs() * 2.2 * _river.scale
        : 0.0;
    // The idle sheet sits lower than the row/fish sheets; on the swan's
    // raised seat lift it so the cat shows above the side like the others.
    double swanSeatLift(String action) =>
        _river.boatStyle == FishingBoat.swan && action == 'idle'
            ? 10 * _river.scale
            : 0;
    final (action, frames, frame) = _anglerPose(oar, rowing: rowing) ??
        ('idle', framesIdle, (_river.clock * 7).floor() % framesIdle);
    final bob = math.sin(_river.clock * 2.5) * 1.8 * _river.scale;
    return Stack(fit: StackFit.expand, children: [
      CustomPaint(
          painter: FishingRiverBoatPainter(_river,
              fishing: fishing && !_river.island.ashore)),
      // Passengers (online friends) sit in the seats behind the driver.
      if (!_river.island.ashore)
        for (final (seat, member) in _river.crew.passengers)
          Builder(builder: (context) {
            final p = _river.toScreen(_river.boat +
                _river.boatStyle.seatOffset(seat, facingRight: facingRight));
            return Positioned(
                left: p.dx - catSize / 2,
                top: p.dy - catSize * .69 + bob - swanSeatLift('idle'),
                child: CatSprite(
                    type: member.cat,
                    size: catSize,
                    action: 'idle',
                    frames: framesIdle,
                    frame: (_river.clock * 7).floor() % framesIdle,
                    flip: !facingRight));
          }),
      if (!_river.island.ashore)
        Positioned(
            left: point.dx - catSize / 2,
            top: point.dy -
                catSize * .69 +
                math.sin(_river.clock * 2.5) * 1.8 * _river.scale +
                pedalBob -
                swanSeatLift(action),
            child: Transform.rotate(
              angle: lean,
              alignment: Alignment.bottomCenter,
              child: CatSprite(
                  type: _cat,
                  size: catSize,
                  action: action,
                  frames: frames,
                  frame: frame,
                  flip: !facingRight),
            )),
      CustomPaint(
          painter: FishingRiverBoatPainter(_river,
              front: true, fishing: fishing && !_river.island.ashore)),
      if (fishing && !won)
        Builder(builder: (context) {
          final spot = _river.toScreen(_controller.spot);
          return CustomPaint(
              painter: FishingPainter(
            rod: _controller.rod,
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
      if (won)
        Builder(builder: (context) {
          // The catch flies into the cupped paws, then rides along with them.
          final t =
              Curves.easeInOut.transform(_controller.elapsed.clamp(0.0, 1.0));
          final paws = _anglerSheetPoint(fishHoldPaws[_holdFrame]);
          final position =
              Offset.lerp(_river.toScreen(_controller.spot), paws, t)! -
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

  /// Sheet, frame count and frame for the angler while fishing or rowing;
  /// null keeps the plain idle/walk choice.
  (String, int, int)? _anglerPose(FishingOarPose? oar, {required bool rowing}) {
    final elapsed = _controller.elapsed;
    if (rowing && oar != null) return ('row', framesRow, oar.rowFrame);
    if (!_controller.showFishingArt) return null;
    return switch (_controller.phase) {
      FishingPhase.casting => (
          'fish-cast',
          framesFishCast,
          (elapsed / .65 * framesFishCast).floor().clamp(0, framesFishCast - 1)
        ),
      FishingPhase.waiting => (
          'fish-wait',
          framesFishWait,
          (_river.clock * 5).floor() % framesFishWait
        ),
      // Yanked forward by the bite: the surprised reel frame.
      FishingPhase.bite => ('fish-reel', framesFishReel, 2),
      FishingPhase.reeling => (
          'fish-reel',
          framesFishReel,
          _controller.pulling ? (_river.clock * 5).floor() % framesFishReel : 5
        ),
      FishingPhase.saving => ('fish-reel', framesFishReel, 5),
      FishingPhase.caught => ('fish-hold', framesFishHold, _holdFrame),
      // The sulk plays briefly, then the normal idle/walk pose resumes.
      FishingPhase.lost => (
          'drop-wrong',
          framesDropWrong,
          (elapsed * 8).floor().clamp(0, framesDropWrong - 1)
        ),
      FishingPhase.ready => null,
    };
  }

  /// Paws stay cupped while the catch flies in, then lift it up to show off.
  int get _holdFrame {
    final t = _controller.elapsed;
    return t < 1 ? 0 : 1 + ((t - 1) * 3).floor() % 2;
  }

  /// Screen position of a point given in sheet pixels (256 x 256 frame,
  /// facing right) of the angler sprite, in the boat or on the bank.
  Offset _anglerSheetPoint((double, double) sheet) {
    final island = _river.island;
    final ashore = island.ashore;
    final point = _river.toScreen(_controller.angler);
    final size = (ashore ? 84 : 114) * _river.scale;
    final flip = _controller.spot.dx < _controller.angler.dx;
    final top = ashore
        ? point.dy - size * .78
        : point.dy -
            size * .69 +
            math.sin(_river.clock * 2.5) * 1.8 * _river.scale;
    final x = flip ? 256 - sheet.$1 : sheet.$1;
    return Offset(
        point.dx - size / 2 + x / 256 * size, top + sheet.$2 / 256 * size);
  }

  Widget _islandCat() {
    final island = _river.island;
    if (!island.ashore) return const SizedBox.shrink();
    final point = _river.toScreen(island.cat);
    final fishing = _controller.showFishingArt;
    final size = 84 * _river.scale;
    final hopping = island.hopProgress != null;
    final angling = fishing && !hopping && !island.walking
        ? _anglerPose(null, rowing: false)
        : null;
    final (action, frames, frame) = angling ??
        (hopping
            ? (
                'jump',
                framesJump,
                (island.hopProgress! * framesJump)
                    .floor()
                    .clamp(0, framesJump - 1)
              )
            : island.walking
                ? ('walk', framesWalk, (_river.clock * 10).floor() % framesWalk)
                : (
                    'idle',
                    framesIdle,
                    (_river.clock * 7).floor() % framesIdle
                  ));
    // The jump sheet already lifts the cat in its air frames.
    final sheetLift = hopping ? jumpSheetLift[frame] * size : 0.0;
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
          top: point.dy - size * .78 - island.jump * _river.scale + sheetLift,
          child: CatSprite(
              type: _cat,
              size: size,
              action: action,
              frames: frames,
              frame: frame,
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
                    FishingMarketStalls(round: _river, frames: _frames),
                    FishingShrineView(round: _river, frames: _frames),
                    FishingBaitHouseView(round: _river, frames: _frames),
                  ])),
                  FishingScenery(
                      round: _river,
                      frames: _frames,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapUp: (event) {
                          if (!_collectionOpen) {
                            _controller.setWorldHour(
                                FishingLighting.gameHour(DateTime.now()));
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
                  // HUD rebuilds only when its state changes; the reel
                  // button and distance bar animate on their own.
                  ValueListenableBuilder(
                      valueListenable: _hud,
                      builder: (context, _, __) =>
                          Stack(fit: StackFit.expand, children: [
                            Positioned(
                                left: padding.left + 8,
                                top: padding.top + 8,
                                child: FlatRoundButton(
                                    glyph: GameGlyph.home,
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
                                      child: AnimatedBuilder(
                                          animation: _frames,
                                          builder: (context, _) =>
                                              FishingDistance(
                                                  progress:
                                                      _controller.progress)))),
                            if (_river.island.ashore &&
                                !_river.island.lookout &&
                                !_controller.showFishingArt)
                              Positioned(
                                  right: padding.right + 164,
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
                                  width: 144,
                                  height: 80,
                                  child: AnimatedBuilder(
                                      animation: _frames,
                                      builder: (context, _) => FishingControls(
                                          controller: _controller))),
                            if (_controller.active &&
                                _controller.phase != FishingPhase.saving)
                              Positioned(
                                  right: padding.right + 98,
                                  bottom: padding.bottom + 22,
                                  child: FlatRoundButton(
                                      glyph: GameGlyph.close,
                                      tooltip: 'Cất cần để chèo tiếp',
                                      onPressed: _controller.cancelCast)),
                            Positioned.fill(
                                child: IgnorePointer(
                                    child: CustomPaint(
                                        painter: FishingQuestArrowPainter(
                                            _river, _frames,
                                            hidden: _controller.tutorial ||
                                                _controller.active)))),
                            if (!_controller.tutorial &&
                                _controller.phase != FishingPhase.reeling)
                              Positioned(
                                  left: padding.left + 56,
                                  right: padding.right + 132,
                                  top: padding.top + 8,
                                  child: Align(
                                      alignment: Alignment.topLeft,
                                      child: FishingQuestChip(
                                          onTap: _openQuests))),
                            if (_questToast case final quest?)
                              Positioned(
                                  top: padding.top + 12,
                                  left: 0,
                                  right: 0,
                                  child: Center(
                                      child: FishingQuestToast(quest: quest))),
                            if (_controller.tutorialStep case final step?)
                              ..._tutorialOverlay(step, padding),
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

extension on _FishingScreenState {
  /// Translucent step caption between Home and the minimap, a skip chip,
  /// and a bouncing arrow over the button the step needs.
  List<Widget> _tutorialOverlay(
      (String, FishingTutorialTarget) step, EdgeInsets padding) {
    final (text, target) = step;
    Widget arrow() => IgnorePointer(
        child: AnimatedBuilder(
            animation: _frames,
            builder: (context, _) => Transform.translate(
                offset: Offset(0, math.sin(_controller.clock * 6).abs() * -10),
                child: const Icon(Icons.arrow_downward_rounded,
                    size: 44,
                    color: Color(0xFFFFE08A),
                    shadows: [
                      Shadow(color: Color(0xFF4A2E1D), blurRadius: 4),
                      Shadow(color: Color(0xFF4A2E1D), blurRadius: 2),
                    ]))));
    return [
      Positioned(
          top: padding.top + 10,
          left: padding.left + 64,
          right: padding.right + 132,
          child: Center(
              child: Container(
                  constraints: const BoxConstraints(maxWidth: 520),
                  padding: const EdgeInsets.fromLTRB(14, 7, 6, 7),
                  decoration: BoxDecoration(
                      color: const Color(0xCCF1F8E7),
                      borderRadius: BorderRadius.circular(10)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Flexible(
                        child: Text(text,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: Color(0xFF28564C),
                                fontSize: DS.fontBody,
                                fontWeight: FontWeight.bold,
                                height: 1.25))),
                    const SizedBox(width: 6),
                    TextButton(
                        style: TextButton.styleFrom(
                            minimumSize: const Size(0, 28),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            foregroundColor: const Color(0xFF6B7F74)),
                        onPressed: _controller.finishTutorial,
                        child: const Text('Bỏ qua',
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w700))),
                  ])))),
      if (target == FishingTutorialTarget.rod)
        Positioned(
            right: padding.right + 22,
            bottom: padding.bottom + 88,
            child: arrow()),
      if (target == FishingTutorialTarget.basket)
        Positioned(
            left: padding.left + 22,
            bottom: padding.bottom + 82,
            child: arrow()),
    ];
  }
}

/// One boat card in the boathouse: preview, name and a "đang dùng" mark.
class _BoatChoice extends StatelessWidget {
  const _BoatChoice(
      {required this.boat, required this.selected, required this.onTap});
  final FishingBoat boat;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: selected ? DS.gold : Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DS.radiusMd),
            side: BorderSide(
                color: selected ? DS.goldEdge : DS.wood.withValues(alpha: .4),
                width: 2)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(DS.spaceSm),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              SizedBox(
                  height: 54,
                  child: CustomPaint(
                      size: Size.infinite, painter: _BoatPreview(boat))),
              const SizedBox(height: DS.spaceXs),
              Text(boat.label,
                  style: const TextStyle(
                      color: DS.ink,
                      fontSize: DS.fontButton,
                      fontWeight: FontWeight.w900)),
              Text(boat.effect,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Color(0xFFB0662F),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(selected ? 'Đang dùng' : 'Chọn',
                  style: const TextStyle(
                      color: DS.wood,
                      fontSize: DS.fontCaption,
                      fontWeight: FontWeight.w700)),
            ]),
          ),
        ),
      );
}

class _BoatPreview extends CustomPainter {
  _BoatPreview(this.boat);
  final FishingBoat boat;

  @override
  void paint(Canvas canvas, Size size) {
    // Scaled to fit the card height (the swan's roof reaches y = -112).
    final s = math.min(size.height / 140, size.width / 160);
    canvas.translate(size.width / 2, size.height * .8);
    canvas.scale(s);
    paintBoatBack(canvas, boat);
    paintBoatFront(canvas, boat);
  }

  @override
  bool shouldRepaint(_BoatPreview old) => old.boat != boat;
}
