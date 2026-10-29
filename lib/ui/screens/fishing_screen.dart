import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../collection/fish_collection.dart';
import '../../fishing/fishing_controller.dart';
import '../../fishing/fishing_lighting.dart';
import '../widgets/fish_collection_dialog.dart';
import '../widgets/fishing_controls.dart';
import '../widgets/fishing_action_button.dart';
import '../widgets/fishing_distance.dart';
import '../widgets/fishing_landscape.dart';
import '../widgets/fishing_lake_layout.dart';
import '../widgets/fishing_painter.dart';
import '../widgets/fishing_water_painter.dart';
import '../widgets/fishing_sky_painter.dart';
import '../widgets/fishing_ambient_painter.dart';
import '../widgets/fishing_catch_popup.dart';

class FishingScreen extends StatefulWidget {
  const FishingScreen({super.key});

  @override
  State<FishingScreen> createState() => _FishingScreenState();
}

class _FishingScreenState extends State<FishingScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final FishingController _controller;
  late final Ticker _ticker;
  late final Timer _lightingTimer;
  FishingLighting _lighting = FishingLighting(DateTime.now());
  Duration? _lastTick;
  bool _collectionOpen = false, _paused = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = FishingController(FishCollection.instance);
    _controller.setWorldHour(_lighting.hour);
    _ticker = createTicker(_tick)..start();
    _lightingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!_paused) _refreshLighting();
    });
  }

  void _refreshLighting() {
    setState(() {
      _lighting = FishingLighting(DateTime.now());
      _controller.setWorldHour(_lighting.hour);
    });
  }

  void _tick(Duration timestamp) {
    final previous = _lastTick;
    _lastTick = timestamp;
    if (previous == null || _paused || _collectionOpen) return;
    _controller
        .update(math.min((timestamp - previous).inMicroseconds / 1000000, .05));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _paused = state != AppLifecycleState.resumed;
    _controller.setPulling(false);
    _lastTick = null;
    if (!_paused) _refreshLighting();
  }

  Future<void> _openCollection() async {
    if (_controller.active || _collectionOpen) return;
    setState(() => _collectionOpen = true);
    try {
      await showDialog<void>(
          context: context,
          builder: (context) =>
              FishCollectionDialog(collection: FishCollection.instance));
    } finally {
      if (mounted) setState(() => _collectionOpen = false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker.dispose();
    _lightingTimer.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: LayoutBuilder(builder: (context, constraints) {
          final padding = MediaQuery.paddingOf(context);
          final controlsSpace = 48 + padding.bottom;
          final sceneHeight =
              math.max(1.0, constraints.maxHeight - controlsSpace);
          assert(sceneHeight > 0 && controlsSpace >= 48);
          return Stack(fit: StackFit.expand, children: [
            IgnorePointer(
                child: RepaintBoundary(
                    child: AnimatedBuilder(
                        animation: _controller,
                        builder: (context, _) => CustomPaint(
                            painter: FishingSkyPainter(
                                sceneHeight: sceneHeight,
                                lighting: _lighting,
                                clock: _controller.clock))))),
            RepaintBoundary(
                child: CustomPaint(
                    painter: FishingLandscape(
                        sceneHeight: sceneHeight, lighting: _lighting))),
            AnimatedBuilder(
                animation: _controller,
                builder: (context, _) => Stack(fit: StackFit.expand, children: [
                      Positioned(
                          left: 0,
                          right: 0,
                          top: 0,
                          height: sceneHeight,
                          child: Stack(fit: StackFit.expand, children: [
                            IgnorePointer(
                                child: RepaintBoundary(
                                    child: CustomPaint(
                                        painter: FishingWaterPainter(
                                            lighting: _lighting,
                                            fish: _controller.fish,
                                            clock: _controller.clock,
                                            phase: _controller.phase,
                                            spot: _controller.spot,
                                            progress: _controller.progress)))),
                            IgnorePointer(
                                child: RepaintBoundary(
                                    child: CustomPaint(
                                        painter: FishingAmbientPainter(
                                            clock: _controller.clock,
                                            lighting: _lighting)))),
                            LayoutBuilder(
                                builder: (context, scene) => GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTapUp: (event) {
                                        if (_collectionOpen) return;
                                        final p = Offset(
                                            event.localPosition.dx /
                                                scene.maxWidth,
                                            event.localPosition.dy /
                                                scene.maxHeight);
                                        if (FishingLakeLayout.contains(p)) {
                                          _controller.cast(p);
                                        }
                                      },
                                      child: CustomPaint(
                                          painter: FishingPainter(
                                              fish: _controller.fish,
                                              phase: _controller.phase,
                                              spot: _controller.spot,
                                              clock: _controller.clock,
                                              elapsed: _controller.elapsed,
                                              progress: _controller.progress,
                                              tension: _controller.tension,
                                              pulling: _controller.pulling)),
                                    )),
                          ])),
                      if (_controller.phase == FishingPhase.reeling)
                        Positioned(
                            left: padding.left + 12,
                            top: padding.top + 62,
                            bottom: padding.bottom + 72,
                            width: 64,
                            child: IgnorePointer(
                                child: FishingDistance(
                                    progress: _controller.progress))),
                      SafeArea(
                          child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Align(
                                  alignment: Alignment.topLeft,
                                  child: FishingActionButton(
                                      tooltip: 'Về Trang chủ',
                                      onPressed: () => Navigator.pop(context),
                                      tool: FishingTool.back)))),
                      Positioned(
                          left: padding.left + 12,
                          bottom: padding.bottom + 12,
                          child: FishingActionButton(
                              tooltip: 'Bộ sưu tập cá',
                              onPressed:
                                  _controller.active ? null : _openCollection,
                              tool: FishingTool.basket)),
                      Positioned(
                          right: padding.right + 8,
                          bottom: padding.bottom + 8,
                          width: 132,
                          height: 80,
                          child: FishingControls(controller: _controller)),
                      if (_controller.phase == FishingPhase.caught)
                        Positioned.fill(
                            child: FishingCatchPopup(
                                fish: _controller.fish,
                                onNext: _controller.dismissResult)),
                    ])),
          ]);
        }),
      );
}
