import '../widgets/fishing_chat_notice.dart';
import '../widgets/fishing_chat_panel.dart';
import '../widgets/fishing_chat_bubbles.dart';
import '../widgets/fishing_boat_picker.dart';
import '../widgets/fishing_cat_selection.dart';
import '../widgets/fishing_player_layer.dart';
import '../widgets/fishing_arrival_notice.dart';
import '../../fishing/fishing_environment.dart';
import '../../online/fishing_world.dart';
import '../../online/fishing_peer.dart';
import '../widgets/fishing_world_lobby.dart';
import '../widgets/fishing_remote_players.dart';
import 'dart:async';
import 'dart:math' as math;
import '../../online/firebase_session.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/scheduler.dart';

import '../../camp/camp_state.dart';
import '../../fishing/fishing_player.dart';
import '../../fishing/fishing_river.dart';
import '../../fishing/fishing_controller.dart';
import '../../fishing/fishing_island.dart';
import '../widgets/fishing_controls.dart';
import '../widgets/fishing_distance.dart';
import '../widgets/fishing_catch_popup.dart';
import '../../game/cats/cat_breed.dart';
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
import '../../fishing/fishing_quests.dart';
import '../widgets/fishing_cave_run.dart';
import '../widgets/fishing_night_overlay.dart';
import '../widgets/fishing_weather_overlay.dart';
import '../../fishing/fishing_trip.dart';
import '../widgets/fishing_rocky_bay_art.dart';
import '../../audio/game_audio.dart';
import '../widgets/game_glyphs.dart';
import '../widgets/game_surfaces.dart';
import '../widgets/round_button.dart';
import '../../collection/fish_collection.dart';
import '../../fishing/fishing_boat.dart';
import '../../fishing/fishing_lighting.dart';
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
  final _landscape = FishingLandscapeCache();
  late final Ticker _ticker;
  late final FishingWorld _world;
  Duration? _lastTick;
  bool _collectionOpen = false, _paused = false, _choosingCat = true;
  bool _loadingCat = false;
  bool get _visitingFriend => _visitCode.text.trim().isNotEmpty;
  final _visitCode = TextEditingController();
  String? _lobbyError;

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
    final time = _world.environmentTime(now);
    final environment = _world.environment;
    final hour = environment.hourAt(time);
    _river.hour = hour;
    _river.cabin.canSkipNight = !_world.online && !_world.visiting;
    _river.weather = environment.weatherAt(time);
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
    if (_river.cabin.dawnDue || _world.takeSleepDawn()) {
      _river.cabin.dawnDue = false;
      final now = DateTime.now();
      final hour = FishingLighting.gameHour(now);
      if (!_world.visiting && (hour >= 18 || hour < 6)) {
        final shift = FishingLighting.skipTo(6, now);
        unawaited(FishCollection.instance.preferences
            .setInt(FishingLighting.shiftKey, shift)
            .then((saved) {
          if (saved && mounted) unawaited(_world.publishEnvironment());
        }));
        _setHour(now);
      }
    }
    _sinceWeather += dt;
    if (_sinceWeather > .5) {
      _sinceWeather = 0;
      _river.weather =
          _world.environment.weatherAt(_world.environmentTime(DateTime.now()));
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

  String get _cat => _controller.player.cat;

  /// Nearest outdoor friend close enough for a two-cat sticker.
  String? _stickerPartner() {
    if (_river.cabin.inside || _river.cave.inside) return null;
    final me = _controller.angler;
    String? best;
    var bestDistance = 420.0;
    for (final peer in _world.peers.values) {
      final location = peer.target.location;
      if (location != FishingPlayerLocation.water &&
          location != FishingPlayerLocation.land) {
        continue;
      }
      final d = (peer.position - me).distance;
      if (d < bestDistance) {
        bestDistance = d;
        best = peer.uid;
      }
    }
    return best;
  }

  String? _lastCat;
  double _sinceSave = 0;
  Offset _savedBoat = Offset.zero;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = FishingController(FishCollection.instance);
    _world = FishingWorld(
        preferences: FishCollection.instance.preferences,
        capture: (stamp) {
          _controller.syncLocalPlayer();
          return FishingPeerSnapshot.local(_controller, stamp);
        },
        onVisitChanged: _worldChanged);
    unawaited(FirebaseSession.instance.connect());
    final preferences = FishCollection.instance.preferences;
    final now = DateTime.now();
    unawaited(FishingEnvironment.initialize(preferences, now,
            firstTrip: !preferences.containsKey(FishingTrip.key) &&
                !CampState.instance.seenGuides
                    .contains(FishingController.boatGuideKey) &&
                FishCollection.instance.count == 0)
        .then((_) {
      if (mounted) {
        _setHour(DateTime.now());
        unawaited(_world.prepare());
      }
    }));
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
    _river.cabin.canSkipNight = !_world.online && !_world.visiting;
    _controller.update(dt);
    _world.update(dt);
    _river.cabin.sharedSleepDark =
        _world.online ? _world.sharedSleepDark : null;
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
      case FishingVisit.cabinShip:
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
    if (_choosingCat || _world.visiting) return;
    _sinceSave = 0;
    _savedBoat = _river.boat;
    FishingTrip.save(FishCollection.instance.preferences, _river, _cat);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _paused = state != AppLifecycleState.resumed;
    if (_paused) {
      _saveTrip();
      if (!_choosingCat) unawaited(_world.setActive(false));
    } else {
      unawaited(FirebaseSession.instance.connect());
      if (!_choosingCat) unawaited(_world.setActive(true));
    }
    _controller.setPulling(false);
    _controller.stopSteering();
    _lastTick = null;
  }

  void _worldChanged(bool visiting) {
    _controller.cancelCast();
    _river.stop();
    _river.cabin.inside = false;
    _river.cabin.pending = false;
    _river.cave.inside = false;
    _river.island.phase = IslandVisitPhase.aboard;
    _river.island.dockRequested = false;
    _river.island.boardRequested = false;
    if (visiting) {
      _river.restore(boat: FishingRiver.startBoat, heading: 0);
    } else {
      FishingTrip.restore(FishCollection.instance.preferences, _river);
    }
    _setHour(DateTime.now());
    _controller.syncLocalPlayer();
    _savedBoat = _river.boat;
    _lastTick = null;
    if (mounted) setState(() {});
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
                                FishingClockChip(
                                    hourProvider: () => _world.environment
                                        .hourAt(_world
                                            .environmentTime(DateTime.now()))),
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
          builder: (context) => FishingBoatPicker(
              selected: _river.boatStyle,
              onSelected: (boat) {
                _river.boatStyle = boat;
                FishingBoat.save(FishCollection.instance.preferences, boat);
                Navigator.pop(context);
              }));
    } finally {
      if (mounted) setState(() => _collectionOpen = false);
      _lastTick = null;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _world.dispose();
    _visitCode.dispose();
    GameAudio.instance.setAmbient(null);
    _saveTrip();
    _ticker.dispose();
    _controller.dispose();
    _frames.dispose();
    _landscape.dispose();
    _hud.dispose();
    super.dispose();
  }

  Future<void> _startWithCat(String type) async {
    if (!_choosingCat || _loadingCat) return;
    final code = FishingWorld.normalizeCode(_visitCode.text);
    if (_visitingFriend && !FishingWorld.validCode(code)) {
      setState(() => _lobbyError = 'Mã phòng cần đủ 7 chữ hoặc số.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _loadingCat = true;
      _lobbyError = null;
    });
    try {
      await _controller.identity.saved;
      if (!mounted) return;
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
      await _landscape.warm();
      if (!mounted) return;
      _controller.selectCat(type);
      if (_visitingFriend) {
        if (!await _world.waitForOnline()) {
          if (mounted) {
            setState(() => _lobbyError = _world.error ??
                'Chưa kết nối được. Xóa mã phòng để chơi offline.');
          }
          await _world.leaveGameplay();
          return;
        }
        if (!mounted) return;
        await FishingTrip.save(
            FishCollection.instance.preferences, _river, _cat);
        if (!mounted) return;
        if (!await _world.visit(code)) {
          if (mounted) {
            setState(
                () => _lobbyError = _world.error ?? 'Chưa vào được phòng này.');
          }
          await _world.leaveGameplay();
          return;
        }
      }
      if (!mounted) return;
      setState(() {
        _choosingCat = false;
        _lastTick = null;
      });
      _ticker.start();
      if (!_visitingFriend) unawaited(_world.start());
    } finally {
      if (mounted) setState(() => _loadingCat = false);
    }
  }

  Future<void> _openChat() async {
    if (_collectionOpen) return;
    _controller.stopSteering();
    setState(() => _collectionOpen = true);
    try {
      await showGameDialog<void>(
          context: context,
          builder: (_) => FishingChatPanel(
              chat: _world.chat,
              name: () => CampState.instance.nameOf(_cat),
              cat: _cat,
              partner: _stickerPartner,
              onReconnect: _world.retry));
    } finally {
      if (mounted) {
        setState(() {
          _collectionOpen = false;
          _lastTick = null;
        });
      }
    }
  }

  Future<void> _openLobby() async {
    if (_loadingCat || _collectionOpen) return;
    setState(() => _collectionOpen = true);
    var enter = false;
    try {
      enter = await showGameDialog<bool>(
              context: context,
              builder: (dialogContext) => StatefulBuilder(
                  builder: (context, updateDialog) => GameDialog(
                      maxWidth: 560,
                      padding: EdgeInsets.zero,
                      insetPadding: const EdgeInsets.all(12),
                      child: FishingWorldLobby(
                          world: _world,
                          code: _visitCode,
                          enabled: !_loadingCat,
                          error: _lobbyError,
                          onClose: () => Navigator.pop(dialogContext),
                          onEnter: () => Navigator.pop(dialogContext, true),
                          onChanged: (_) {
                            setState(() {
                              _lobbyError = null;
                            });
                            updateDialog(() {});
                          })))) ??
          false;
    } finally {
      if (mounted) setState(() => _collectionOpen = false);
    }
    if (!mounted || !enter) return;
    final remembered = _lastCat;
    final type = remembered != null &&
            CatBreed.all.any((breed) => breed.id == remembered) &&
            CampState.instance.unlocked(remembered)
        ? remembered
        : _cat;
    await _startWithCat(type);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        // Input dialogs handle the keyboard without shrinking the game behind them.
        resizeToAvoidBottomInset: false,
        body: Stack(fit: StackFit.expand, children: [
          Positioned.fill(
              child: _choosingCat
                  ? FishingCatSelection(
                      loading: _loadingCat,
                      visitingFriend: _visitingFriend,
                      error: _lobbyError,
                      lastCat: _lastCat,
                      onSelected: _startWithCat,
                      onOpenLobby: _openLobby)
                  : LayoutBuilder(builder: (context, constraints) {
                      _river.resize(
                          Size(constraints.maxWidth, constraints.maxHeight));
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
                          FishingRiverBackdrop(
                              round: _river,
                              frames: _frames,
                              landscape: _landscape),
                          CustomPaint(
                              painter: FishingRiverSurface(_river, _frames,
                                  fishing: _controller)),
                          CustomPaint(
                              painter: FishingIslandPainter(_river, _frames)),
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
                                  _setHour(DateTime.now());
                                  _controller.tapRiver(event.localPosition);
                                }
                              },
                              onPanUpdate: (event) => _controller.steerBoat(
                                  Offset(event.delta.dx / 90,
                                      event.delta.dy / 70)),
                              onPanEnd: (_) => _controller.stopSteering(),
                              onPanCancel: _controller.stopSteering,
                              child: IgnorePointer(
                                  child: AnimatedBuilder(
                                      animation: _frames,
                                      builder: (context, _) => Stack(
                                              fit: StackFit.expand,
                                              children: [
                                                FishingRemotePlayers(
                                                    round: _river,
                                                    peers: _world.peers.values),
                                                FishingPlayerLayer(
                                                    controller: _controller)
                                              ]))),
                            )),
                        // Light and weather overlays share one layer.
                        IgnorePointer(
                            child: RepaintBoundary(
                                child: Stack(fit: StackFit.expand, children: [
                          CustomPaint(
                              painter: FishingCaveLight(_river, _frames)),
                          CustomPaint(
                              painter: FishingNightOverlay(_river, _frames)),
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
                                          onPressed: () =>
                                              Navigator.pop(context))),
                                  if (!(_controller.phase ==
                                      FishingPhase.reeling))
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
                                                          constraints: const BoxConstraints(
                                                              maxWidth: 110),
                                                          margin:
                                                              const EdgeInsets.only(
                                                                  top: 3),
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  horizontal: 7,
                                                                  vertical: 2),
                                                          decoration: BoxDecoration(
                                                              color: const Color(
                                                                  0xB31E2A30),
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                      8)),
                                                          child: Text(_area,
                                                              textAlign: TextAlign
                                                                  .center,
                                                              maxLines: 1,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                              style: const TextStyle(
                                                                  color: Colors
                                                                      .white,
                                                                  fontSize: 11,
                                                                  fontWeight:
                                                                      FontWeight.w700))),
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
                                                        progress: _controller
                                                            .progress)))),
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
                                            builder: (context, _) =>
                                                FishingControls(
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
                                                  hidden: _controller
                                                          .tutorial ||
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
                                            child: FishingQuestToast(
                                                quest: quest))),
                                  if (_controller.tutorialStep case final step?)
                                    ..._tutorialOverlay(step, padding),
                                  if (_controller.phase ==
                                          FishingPhase.caught &&
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
                    })),
          if (!_choosingCat) ...[
            Positioned.fill(
                child: IgnorePointer(
                    child: Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                            padding: EdgeInsets.only(
                                left: MediaQuery.paddingOf(context).left + 12),
                            child: SizedBox(
                                width: math.min(310,
                                    MediaQuery.sizeOf(context).width * .44),
                                child:
                                    FishingChatNotice(chat: _world.chat)))))),
            Positioned.fill(
                child: FishingChatBubbles(
                    controller: _controller, world: _world, frames: _frames)),
            Positioned(
                right: MediaQuery.paddingOf(context).right + 24,
                top: MediaQuery.paddingOf(context).top + 158,
                child:
                    FishingChatButton(chat: _world.chat, onPressed: _openChat)),
          ],
          if (!_choosingCat)
            Positioned(
                top: MediaQuery.paddingOf(context).top + 48,
                left: 64,
                right: 64,
                child: FishingArrivalNotice(world: _world)),
        ]),
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
