import 'dart:math' as math;
import 'package:material_ui/material_ui.dart';
import 'package:flutter/scheduler.dart';

import '../../camp/camp_state.dart';
import '../../fishing/fishing_river.dart';
import '../../fishing/fishing_controller.dart';
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
  bool _collectionOpen = false, _paused = false;
  String _cat = 'orange';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = FishingController(FishCollection.instance);
    final now = DateTime.now();
    _controller.setWorldHour(now.hour + now.minute / 60);
    _ticker = createTicker(_tick)..start();
  }

  void _tick(Duration timestamp) {
    final previous = _lastTick;
    _lastTick = timestamp;
    if (previous == null || _paused || _collectionOpen) return;
    _controller
        .update(math.min((timestamp - previous).inMicroseconds / 1000000, .05));
    _frames.value++;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _paused = state != AppLifecycleState.resumed;
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

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker.dispose();
    _controller.dispose();
    _frames.dispose();
    super.dispose();
  }

  Future<void> _chooseCat() async {
    if (_collectionOpen || _controller.active) return;
    setState(() => _collectionOpen = true);
    try {
      final selected = await showGameDialog<String>(
        context: context,
        builder: (context) => GameDialog(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            GameDialogHeader(
                title: 'CHỌN MÈO ĐI THUYỀN',
                onClose: () => Navigator.pop(context)),
            const SizedBox(height: DS.spaceMd),
            Flexible(
                child: SingleChildScrollView(
                    child: Wrap(
              spacing: DS.spaceSm,
              runSpacing: DS.spaceSm,
              children: [
                for (final breed in CatBreed.all)
                  if (CampState.instance.unlocked(breed.id))
                    SizedBox(
                        width: 130,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context, breed.id),
                          child: Padding(
                            padding: const EdgeInsets.all(DS.spaceSm),
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CatFace(breed.id, size: 48),
                                  const SizedBox(height: DS.spaceXs),
                                  Text(CampState.instance.nameOf(breed.id),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                ]),
                          ),
                        )),
              ],
            ))),
          ]),
        ),
      );
      if (mounted && selected != null) setState(() => _cat = selected);
    } finally {
      if (mounted) setState(() => _collectionOpen = false);
      _lastTick = null;
    }
  }

  Widget _boat() {
    final point = _river.toScreen(_river.boat);
    final catSize = 114 * _river.scale;
    final phase = _controller.phase;
    final won = phase == FishingPhase.caught;
    final fishing = _controller.active || won;
    final facingRight = fishing
        ? _controller.spot.dx >= _river.boat.dx
        : _river.heading.dx >= 0;
    final hit = phase == FishingPhase.lost || _river.hitTime > .8;
    final action = won
        ? 'celebrate'
        : hit
            ? 'panic'
            : 'idle';
    final frames = won
        ? framesCelebrate
        : hit
            ? framesPanic
            : framesIdle;
    return Stack(fit: StackFit.expand, children: [
      CustomPaint(painter: FishingRiverBoatPainter(_river)),
      Positioned(
          left: point.dx - catSize / 2,
          top: point.dy -
              catSize * .69 +
              math.sin(_river.clock * 2.5) * 1.8 * _river.scale,
          child: Transform.rotate(
            angle: _controller.pulling
                ? -.08 * _controller.tension
                : _river.rowing
                    ? math.sin(_river.clock * 7) * .035
                    : 0,
            alignment: Alignment.bottomCenter,
            child: CatSprite(
                type: _cat,
                size: catSize,
                action: action,
                frames: frames,
                frame: (_river.clock * 7).floor() % frames,
                flip: !facingRight),
          )),
      CustomPaint(painter: FishingRiverBoatPainter(_river, front: true)),
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
            pawColor: CatBreed.of(_cat).color,
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
          return Positioned(
              left: position.dx - 20,
              top: position.dy - 14,
              child: SizedBox(
                  width: 40,
                  height: 28,
                  child:
                      CustomPaint(painter: FishingFishArt(_controller.fish))));
        }),
    ]);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: LayoutBuilder(builder: (context, constraints) {
          _river.resize(Size(constraints.maxWidth, constraints.maxHeight));
          final padding = MediaQuery.paddingOf(context);
          return AnimatedBuilder(
              animation: _frames,
              builder: (context, _) => Stack(fit: StackFit.expand, children: [
                    const ColoredBox(color: Color(0xFFA7BF78)),
                    FishingRiverBackdrop(round: _river, frames: _frames),
                    RepaintBoundary(
                        child: CustomPaint(
                            painter: FishingRiverSurface(_river, _frames,
                                fishing: _controller))),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapUp: (event) {
                        if (!_collectionOpen) {
                          final now = DateTime.now();
                          _controller.setWorldHour(now.hour + now.minute / 60);
                          _controller.tapRiver(event.localPosition);
                        }
                      },
                      onPanUpdate: (event) => _controller.steerBoat(
                          Offset(event.delta.dx / 90, event.delta.dy / 70)),
                      onPanEnd: (_) => _controller.stopSteering(),
                      onPanCancel: _controller.stopSteering,
                      child: IgnorePointer(child: _boat()),
                    ),
                    Positioned(
                        left: padding.left + 8,
                        top: padding.top + 8,
                        child: RoundButton(
                            glyph: GameGlyph.home,
                            tooltip: 'Về Trang chủ',
                            onPressed: () => Navigator.pop(context))),
                    Positioned(
                      left: padding.left + 70,
                      right: padding.right + 170,
                      top: padding.top + 9,
                      child: IgnorePointer(
                          child: Center(
                              child: AnimatedBuilder(
                        animation: _frames,
                        builder: (context, _) => Container(
                          constraints: const BoxConstraints(maxWidth: 430),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                              color: const Color(0xEAFFF4DA),
                              borderRadius: BorderRadius.circular(DS.radiusMd),
                              border: Border.all(color: DS.wood, width: 1.5)),
                          child:
                              Column(mainAxisSize: MainAxisSize.min, children: [
                            Text(
                                'KHÚC ${_river.section} · ${FishingRiver.sectionName(_river.boat.dx).toUpperCase()}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: DS.ink,
                                    fontWeight: FontWeight.w900,
                                    fontSize: DS.fontBody)),
                            const SizedBox(height: 2),
                            Text(_controller.guide,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    color: DS.ink, fontSize: DS.fontCaption)),
                          ]),
                        ),
                      ))),
                    ),
                    Positioned(
                        right: padding.right + 10,
                        top: padding.top + 9,
                        width: 150,
                        child: OutlinedButton(
                          onPressed: _controller.active ? null : _chooseCat,
                          style: OutlinedButton.styleFrom(
                              backgroundColor: DS.cream,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4)),
                          child: Row(children: [
                            CatFace(_cat, size: 30),
                            const SizedBox(width: 5),
                            Expanded(
                                child: Text(CampState.instance.nameOf(_cat),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis)),
                            const Icon(Icons.expand_more_rounded, size: 16),
                          ]),
                        )),
                    Positioned(
                        left: padding.left + 12,
                        bottom: padding.bottom + 12,
                        child: FishingActionButton(
                            tooltip: 'Bộ sưu tập cá',
                            onPressed:
                                _controller.active ? null : _openCollection,
                            tool: FishingTool.basket)),
                    if (_controller.phase == FishingPhase.reeling)
                      Positioned(
                          left: padding.left + 10,
                          top: padding.top + 80,
                          bottom: padding.bottom + 85,
                          width: 54,
                          child: IgnorePointer(
                              child: FishingDistance(
                                  progress: _controller.progress))),
                    Positioned(
                        right: padding.right + 8,
                        bottom: padding.bottom + 8,
                        width: 80,
                        height: 80,
                        child: FishingControls(controller: _controller)),
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
                              onNext: _controller.dismissResult)),
                  ]));
        }),
      );
}
