import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import '../../audio/game_audio.dart';

import '../../camp/camp_state.dart';
import '../../collection/fish_collection.dart';
import '../../collection/fish_species.dart';
import '../widgets/fishing_fish_art.dart';
import '../../camp/camp_room_painter.dart';
import '../../camp/camp_resident.dart';
import '../../camp/camp_social.dart';
import '../../game/cats/cat_breed.dart';
import '../widgets/cat_sprite.dart';
import '../widgets/paw_loader.dart';
import '../../camp/camp_decor_painter.dart';
import '../design.dart';
import '../widgets/round_button.dart';
import '../widgets/game_glyphs.dart';
import '../widgets/game_surfaces.dart';

/// The cat camp: rescued cats wander the yard, the player pets them and buys
/// decorations with coins earned in every other mode.
class CampScreen extends StatefulWidget {
  const CampScreen({super.key});

  @override
  State<CampScreen> createState() => _CampScreenState();
}

class _CampScreenState extends State<CampScreen>
    with SingleTickerProviderStateMixin {
  final _random = Random();
  late final _social = CampSocial(_random);
  final _cats = <CampResident>[];
  late final Ticker _tick;
  late final Timer _clock;
  final _animation = ValueNotifier(0);
  int _roomHour = DateTime.now().hour;
  Duration _last = Duration.zero;
  CampResident? _carried;
  CampResident? _pressed;
  Size _room = Size.zero;
  _Panel _panel = _Panel.none;

  /// Fish being dragged out of the basket, and the cat under it.
  FishSpecies? _dragging;
  CampResident? _hover;
  bool _fedThisDrag = false;
  final _roomKey = GlobalKey();

  /// Short line after feeding ("Mướp ăn cá rô · +2 ♥").
  String? _toast;
  Timer? _toastTimer;

  /// Panels are built the first time they open, not with the room.
  final _builtPanels = <_Panel>{};
  CampState get camp => CampState.instance;

  /// Floor toys the cats can visit (wall items are out of reach). Rebuilt
  /// only when decorations are bought or moved, not every frame.
  var _toys = <(String, double, double)>[];

  /// Decoded sprite sheets by asset path, downscaled to the on-screen size.
  /// Only [_coreSheets] stay loaded; the rest are decoded when a cat starts
  /// (or is about to start) that action and freed after [_evictAfter] unused.
  final _sprites = <String, ui.Image>{};
  final _requested = <String>{};
  final _missing = <String>{};
  final _lastUsed = <String, double>{};
  double _now = 0, _nextSweep = 0;

  /// Sheets every resident keeps: what it does most of the time, and what
  /// must show the instant the player picks it up.
  static final _coreSheets = [
    CampAct.idle.sheet,
    CampAct.walk.sheet,
    campSleepSheet,
    CampAct.held.sheet,
  ];
  static const _evictAfter = 20.0;
  final _labels = _CatLabels();

  /// Adds a resident for every owned breed that is not in the room yet
  /// (on open, and right after a cat is bought).
  void _syncResidents() {
    for (final type in camp.residents) {
      if (_cats.any((cat) => cat.type == type)) continue;
      _cats.add(CampResident(type, _random.nextDouble() * .7 + .1,
          _random.nextDouble() * .25 + .64));
    }
    _loadSprites();
  }

  void _refreshToys() {
    _toys = [
      for (final item in CampDecoration.all)
        if (camp.owned.contains(item.id) && campToyActs.containsKey(item.id))
          (item.id, camp.positionOf(item).$1, camp.positionOf(item).$2),
    ];
  }

  /// Sheets waiting to be decoded, one at a time so opening the camp never
  /// decodes dozens of images in the same frames as the screen change.
  final _queue = <String>[];
  bool _loading = false, _transitionWaited = false;

  /// Paw loader over the room until every cat's idle sheet is decoded.
  bool _ready = false;
  bool _coverGone = false;

  void _markReady() {
    if (_ready || !mounted) return;
    setState(() => _ready = true);
  }

  /// Idle sheets first so every cat shows up quickly; the other core sheets
  /// wait until the screen change has finished. Until a sheet is ready the
  /// cat holds its idle pose.
  void _loadSprites() {
    for (final cat in _cats) {
      final idle = CatBreed.of(cat.type).sheet(CampAct.idle.sheet);
      if (!_queue.contains(idle)) _queue.insert(0, idle);
    }
    for (final sheet in _coreSheets.skip(1)) {
      for (final cat in _cats) {
        final path = CatBreed.of(cat.type).sheet(sheet);
        if (!_queue.contains(path)) _queue.add(path);
      }
    }
    _pumpSprites();
  }

  /// Marks the sheets cats are using (or about to use) and decodes any that
  /// are not loaded yet, ahead of the core queue.
  void _requestUsedSheets() {
    for (final cat in _cats) {
      final breed = CatBreed.of(cat.type);
      for (final sheet in [
        cat.sleeping ? campSleepSheet : cat.act.sheet,
        if (cat.upcoming != null) cat.upcoming!.sheet,
      ]) {
        final path = breed.sheet(sheet);
        _lastUsed[path] = _now;
        if (_requested.contains(path) || _queue.contains(path)) continue;
        _queue.insert(0, path);
      }
    }
    if (_queue.isNotEmpty) _pumpSprites();
  }

  /// Frees action sheets nobody has used for a while; core sheets stay.
  void _evictUnused() {
    final core = {
      for (final cat in _cats)
        for (final sheet in _coreSheets) CatBreed.of(cat.type).sheet(sheet)
    };
    final stale = [
      for (final path in _sprites.keys)
        if (!core.contains(path) && _now - (_lastUsed[path] ?? 0) > _evictAfter)
          path
    ];
    for (final path in stale) {
      _sprites.remove(path)?.dispose();
      _requested.remove(path);
      _lastUsed.remove(path);
    }
  }

  Future<void> _pumpSprites() async {
    if (_loading) return;
    _loading = true;
    while (_queue.isNotEmpty && mounted) {
      final path = _queue.removeAt(0);
      final idle = path.endsWith('-${CampAct.idle.sheet}.png');
      if (!idle) _markReady();
      // Only the very first non-idle sheet waits for the screen change;
      // sheets requested later during play decode straight away.
      if (!idle && !_transitionWaited) {
        _transitionWaited = true;
        await Future<void>.delayed(DS.pageTransitionDuration);
        if (!mounted) break;
      }
      await _loadSheet(path);
    }
    _loading = false;
    _markReady();
  }

  Future<void> _loadSheet(String path) async {
    if (!_requested.add(path)) return;
    final dpr = WidgetsBinding
            .instance.platformDispatcher.implicitView?.devicePixelRatio ??
        2;
    try {
      final data = await rootBundle.load('assets/images/$path');
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
          targetHeight: (_CampCatsPainter.spriteSize * dpr).ceil(),
          allowUpscaling: false);
      final ui.FrameInfo frame;
      try {
        frame = await codec.getNextFrame();
      } finally {
        codec.dispose();
      }
      if (!mounted) return frame.image.dispose();
      _sprites[path] = frame.image;
    } catch (_) {
      _missing.add(path);
    }
  }

  @override
  void initState() {
    super.initState();
    _syncResidents();
    _refreshToys();
    // Per-frame updates keep the walk smooth instead of stepping 8 times/s.
    // Only the cat painter repaints; no widgets are rebuilt per frame.
    _tick = createTicker((elapsed) {
      final dt = ((elapsed - _last).inMicroseconds / 1e6).clamp(0.0, .1);
      _last = elapsed;
      _now += dt;
      for (final cat in _cats) {
        cat.update(dt, _random, _toys);
      }
      _requestUsedSheets();
      if (_now >= _nextSweep) {
        _nextSweep = _now + 5;
        _evictUnused();
      }
      _social.update(dt, _cats);
      // Back to front, so lower cats are drawn over (and hit before) higher.
      _cats.sort((a, b) => a.y.compareTo(b.y));
      _animation.value++;
    })
      ..start();
    _clock = Timer.periodic(const Duration(seconds: 30), (_) {
      final hour = DateTime.now().hour;
      if (hour != _roomHour) setState(() => _roomHour = hour);
    });
  }

  @override
  void dispose() {
    _tick.dispose();
    _clock.cancel();
    _toastTimer?.cancel();
    _animation.dispose();
    _labels.dispose();
    for (final image in _sprites.values) {
      image.dispose();
    }
    super.dispose();
  }

  /// The front-most cat under [p] (sprite plus name tag), if any.
  CampResident? _catAt(Offset p) {
    for (final cat in _cats.reversed) {
      if (_CampCatsPainter.hitBox(cat, _room).contains(p)) return cat;
    }
    return null;
  }

  void _drop(CampResident cat, {bool sound = true}) {
    _carried = null;
    cat.drop();
    if (sound) {
      GameAudio.instance.playGameplay(GameSound.campDrop, priority: 1);
    }
  }

  Future<void> _pet(CampResident cat) async {
    cat.pet();
    final reachesBond =
        (camp.affection[cat.type] ?? 0) == CampState.bondedAffection - 1;
    await camp.pet(cat.type);
    if (!mounted) return;
    GameAudio.instance.playGameplay(
        reachesBond ? GameSound.campBond : GameSound.campPet,
        priority: reachesBond ? 3 : 2);
    setState(() {});
  }

  /// Picking a fish up slides the basket away so every cat is reachable.
  void _startDrag(FishSpecies fish) {
    GameAudio.instance.play(GameSound.click);
    _fedThisDrag = false;
    setState(() {
      _dragging = fish;
      _hover = null;
      _panel = _Panel.none;
    });
  }

  /// The cat under a dragged fish ([global] is the pointer position).
  CampResident? _catAtGlobal(Offset global) {
    final box = _roomKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return null;
    return _catAt(box.globalToLocal(global));
  }

  void _endDrag() {
    if (!mounted) return;
    final fed = _fedThisDrag;
    setState(() {
      _dragging = null;
      _hover = null;
      // Missed every cat: bring the basket back to try again.
      if (!fed && FishCollection.instance.basket.isNotEmpty) {
        _panel = _Panel.basket;
      }
    });
  }

  Future<void> _feed(CampResident cat, FishSpecies fish) async {
    final basket = FishCollection.instance;
    if (!await basket.takeOne(fish)) return;
    final before = camp.affection[cat.type] ?? 0;
    cat.pet();
    await camp.feed(cat.type, fish.affection);
    if (!mounted) return;
    final reachesBond = before < CampState.bondedAffection &&
        before + fish.affection >= CampState.bondedAffection;
    GameAudio.instance.playGameplay(
        reachesBond ? GameSound.campBond : GameSound.catEat,
        priority: reachesBond ? 3 : 2);
    _toastTimer?.cancel();
    _toastTimer = Timer(const Duration(milliseconds: 1800), () {
      if (mounted) setState(() => _toast = null);
    });
    setState(() {
      _toast = reachesBond
          ? '${camp.nameOf(cat.type)} đã thân thiết với bạn!'
          : '${camp.nameOf(cat.type)} ăn ${fish.label.toLowerCase()}'
              ' · +${fish.affection}';
    });
  }

  Future<void> _renameCat(CatBreed breed) async {
    final name = await showGameDialog<String>(
      context: context,
      builder: (_) => _CatNameDialog(
        breed: breed,
        initialName: camp.nameOf(breed.id),
      ),
    );
    if (!mounted || name == null) return;
    final oldName = camp.nameOf(breed.id);
    final saved = await camp.renameCat(breed.id, name);
    if (!mounted) return;
    if (saved) _labels.forget(oldName);
    setState(() {});
    if (!saved) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Chưa lưu được tên. Hãy thử lại.'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    _labels.update(
        Theme.of(context)
            .textTheme
            .bodyMedium!
            .merge(DS.captionText.copyWith(color: DS.ink)),
        MediaQuery.textScalerOf(context));
    return Scaffold(
      // The name dialog handles keyboard insets; keep the room/panels full size.
      resizeToAvoidBottomInset: false,
      body: Stack(fit: StackFit.expand, children: [
        LayoutBuilder(builder: (context, box) {
          final w = box.maxWidth, h = box.maxHeight;
          _room = Size(w, h);
          // Expand so the yard fills the screen; a loose Stack would shrink to
          // the height of the top bar and leave the rest blank.
          return Stack(fit: StackFit.expand, children: [
            Positioned.fill(
                child: RepaintBoundary(
                    child: CustomPaint(
                        painter: CampRoomPainter(hour: _roomHour)))),
            for (final item in [
              ...CampDecoration.all.where((d) => d.id == 'rug'),
              ...CampDecoration.all.where((d) => d.id != 'rug'),
            ])
              if (camp.owned.contains(item.id))
                _PlacedDecoration(
                    key: ValueKey(item.id),
                    item: item,
                    room: Size(w, h),
                    onPlaced: _refreshToys),
            // All cats are painted by one painter that repaints every frame
            // without rebuilding widgets. One gesture detector serves every
            // cat; touches that miss a cat fall through to the decorations.
            Positioned.fill(
              key: _roomKey,
              // A fish dragged out of the basket is dropped onto a cat here.
              child: DragTarget<FishSpecies>(
                onMove: (d) {
                  final cat = _catAtGlobal(d.offset);
                  if (cat != _hover) setState(() => _hover = cat);
                },
                onLeave: (_) => setState(() => _hover = null),
                // Accept anywhere in the room (the check runs once on entry,
                // far from any cat); a drop that misses every cat is ignored.
                onWillAcceptWithDetails: (_) => true,
                onAcceptWithDetails: (d) {
                  final cat = _catAtGlobal(d.offset);
                  if (cat == null) return;
                  _fedThisDrag = true;
                  _feed(cat, d.data);
                },
                builder: (context, _, __) => RepaintBoundary(
                  child: GestureDetector(
                    onTapUp: (d) {
                      final cat = _catAt(d.localPosition);
                      if (cat != null) _pet(cat);
                    },
                    onPanDown: (d) {
                      if (_carried == null) _pressed = _catAt(d.localPosition);
                    },
                    // Only one cat can be carried at a time.
                    onPanStart: (_) {
                      final cat = _pressed;
                      if (cat == null || _carried != null) return;
                      _carried = cat..pickUp();
                      GameAudio.instance
                          .playGameplay(GameSound.campLift, priority: 1);
                    },
                    onPanUpdate: (d) {
                      final cat = _carried;
                      if (cat == null) return;
                      cat.x = (cat.x + d.delta.dx / w).clamp(.03, .97);
                      cat.y = (cat.y + d.delta.dy / h).clamp(.3, .95);
                    },
                    onPanEnd: (_) {
                      final cat = _carried;
                      if (cat != null) _drop(cat);
                    },
                    onPanCancel: () {
                      final cat = _carried;
                      if (cat != null) _drop(cat, sound: false);
                    },
                    child: CustomPaint(
                      size: Size.infinite,
                      painter: _CampCatsPainter(
                        cats: _cats,
                        sprites: _sprites,
                        missing: _missing,
                        labels: _labels,
                        hit: (p) => _catAt(p) != null,
                        repaint: _animation,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Tapping anywhere outside an open panel closes it.
            if (_panel != _Panel.none)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _panel = _Panel.none),
                ),
              ),
            // Panels slide up from the bottom; the room stays visible above.
            for (final (panel, child) in [
              if (_builtPanels.contains(_Panel.shop))
                (
                  _Panel.shop,
                  _ShopBar(
                    onBought: () => setState(() {
                      _syncResidents();
                      _refreshToys();
                    }),
                    onClose: () => setState(() => _panel = _Panel.none),
                  ) as Widget,
                ),
              if (_builtPanels.contains(_Panel.cats))
                (
                  _Panel.cats,
                  _BondBar(
                    onClose: () => setState(() => _panel = _Panel.none),
                    onRename: _renameCat,
                  ),
                ),
              if (_builtPanels.contains(_Panel.basket))
                (
                  _Panel.basket,
                  _BasketBar(
                    onDragStart: _startDrag,
                    onDragEnd: _endDrag,
                    onClose: () => setState(() => _panel = _Panel.none),
                  ),
                ),
            ])
              AnimatedPositioned(
                duration: DS.transitionDuration,
                curve: Curves.easeOut,
                left: 0,
                right: 0,
                bottom: _panel == panel ? 0 : -(h * .36 + 20),
                height: panel == _Panel.basket ? 82 : h * .36,
                child: child,
              ),
            Align(
              alignment: Alignment.topCenter,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(DS.spaceMd),
                  // Only navigation and panel controls stay in the top bar.
                  // Progress counters belong inside the panel that uses them.
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RoundButton(
                            glyph: GameGlyph.home,
                            onPressed: () => Navigator.of(context).pop()),
                        const SizedBox(width: DS.spaceSm),
                        Expanded(
                          child: Align(
                            alignment: Alignment.topRight,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerRight,
                              child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _PanelButton(
                                      label: 'CỬA HÀNG',
                                      icon: _CampIcon.shop,
                                      active: _panel == _Panel.shop,
                                      onTap: () => _toggle(_Panel.shop),
                                    ),
                                    const SizedBox(width: DS.spaceSm),
                                    _PanelButton(
                                      label: 'GIỎ CÁ',
                                      icon: _CampIcon.fish,
                                      active: _panel == _Panel.basket,
                                      onTap: () => _toggle(_Panel.basket),
                                    ),
                                    const SizedBox(width: DS.spaceSm),
                                    _PanelButton(
                                      label: 'THÂN THIẾT',
                                      icon: _CampIcon.heart,
                                      active: _panel == _Panel.cats,
                                      onTap: () => _toggle(_Panel.cats),
                                    ),
                                  ]),
                            ),
                          ),
                        ),
                      ]),
                ),
              ),
            ),
          ]);
        }),
        // While dragging: who will eat it; right after: what it gave.
        if (_dragging != null || _toast != null)
          IgnorePointer(
            child: Align(
              alignment: Alignment.topCenter,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(top: 66),
                  child: _FeedHint(
                    fish: _dragging,
                    target: _hover == null ? null : camp.nameOf(_hover!.type),
                    toast: _toast,
                  ),
                ),
              ),
            ),
          ),
        if (!_coverGone)
          // Same loader as the game modes; fades out once the cats can show.
          IgnorePointer(
            ignoring: _ready,
            child: AnimatedOpacity(
              opacity: _ready ? 0 : 1,
              duration: DS.loadingFadeDuration,
              curve: Curves.easeOut,
              onEnd: () => setState(() => _coverGone = true),
              child: const GameLoading(),
            ),
          ),
      ]),
    );
  }

  void _toggle(_Panel p) {
    GameAudio.instance.play(GameSound.click);
    if (_builtPanels.add(p)) {
      // First open: build it hidden below the edge, then slide it up.
      setState(() {});
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _panel = p);
      });
      return;
    }
    setState(() => _panel = _panel == p ? _Panel.none : p);
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.icon, this.text, this.color);
  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(
            horizontal: DS.spaceMd, vertical: DS.spaceXs),
        decoration: BoxDecoration(
            color: const Color(0xEEFFF4DA),
            borderRadius: BorderRadius.circular(DS.radiusLg),
            border: Border.all(color: DS.wood, width: 2)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: DS.spaceXs),
          Text(text,
              style:
                  const TextStyle(fontWeight: FontWeight.w900, color: DS.ink)),
        ]),
      );
}

/// Simple painted art for each decoration, sized 60x60.
class _DecorationArt extends StatelessWidget {
  const _DecorationArt(this.id);
  final String id;

  @override
  Widget build(BuildContext context) => SizedBox(
      width: 60, height: 60, child: CustomPaint(painter: CampDecorPainter(id)));
}

class _CatNameDialog extends StatefulWidget {
  const _CatNameDialog({required this.breed, this.initialName});
  final CatBreed breed;
  final String? initialName;

  @override
  State<_CatNameDialog> createState() => _CatNameDialogState();
}

class _CatNameDialogState extends State<_CatNameDialog> {
  late final _name = TextEditingController(text: widget.initialName);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _confirm() => Navigator.of(context).pop(_name.text.trim());

  @override
  Widget build(BuildContext context) => GameDialog(
        maxWidth: 360,
        scrollable: true,
        header: GameDialogHeader(
            title:
                widget.initialName == null ? 'ĐẶT TÊN CHO MÈO' : 'ĐỔI TÊN MÈO',
            onClose: () => Navigator.of(context).pop()),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: DS.spaceSm),
              TextField(
                controller: _name,
                maxLength: 20,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _confirm(),
                style: DS.bodyText,
                decoration: InputDecoration(
                  labelText: 'Tên của bé',
                  hintText: widget.breed.name,
                  filled: true,
                  fillColor: DS.surfaceRaised,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(DS.radiusMd)),
                ),
              ),
              const Text('Để trống để dùng tên giống mèo.',
                  style: DS.captionText),
              const SizedBox(height: DS.spaceMd),
              ElevatedButton.icon(
                onPressed: _confirm,
                icon: const Icon(Icons.pets_rounded, size: DS.iconSm),
                label: Text(widget.initialName == null
                    ? 'ĐÓN VỀ · ${CampState.catPrices[widget.breed.id]} XU'
                    : 'LƯU TÊN'),
              ),
            ]),
      );
}

/// Compact shop docked at the bottom: categories, items and coin balance.
class _ShopBar extends StatefulWidget {
  const _ShopBar({required this.onBought, required this.onClose});
  final VoidCallback onBought;
  final VoidCallback onClose;

  @override
  State<_ShopBar> createState() => _ShopBarState();
}

class _ShopBarState extends State<_ShopBar> {
  /// Selected section; null is the cats tab.
  CampCategory? _tab;
  CampState get camp => CampState.instance;

  @override
  Widget build(BuildContext context) {
    final items = [
      for (final d in CampDecoration.all)
        if (d.cat == _tab) d
    ];
    return Container(
      decoration: const BoxDecoration(
        color: DS.surfaceGlass,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: DS.wood, width: 3)),
        boxShadow: [BoxShadow(color: DS.shadowColor, blurRadius: 10)],
      ),
      child: SafeArea(
        top: false,
        child: Column(children: [
          SizedBox(
            height: 40,
            child: Row(children: [
              Expanded(
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(
                      DS.spaceSm, DS.spaceXs, 0, DS.space2),
                  children: [
                    _chip(null),
                    for (final c in CampCategory.values) _chip(c),
                  ],
                ),
              ),
              _Chip(Icons.monetization_on_rounded, '${camp.coins}',
                  const Color(0xFFE7A72F)),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    DS.spaceXs, DS.space2, DS.spaceSm, 0),
                child: RoundButton(
                    glyph: GameGlyph.close,
                    size: 30,
                    onPressed: widget.onClose),
              ),
            ]),
          ),
          Expanded(
            child: LayoutBuilder(builder: (context, box) {
              final width = _campCardWidth(box.maxWidth,
                  preferred: _tab == null ? 190 : 176);
              return ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(
                    DS.spaceSm, DS.spaceXs, DS.spaceSm, DS.spaceSm),
                children: _tab == null
                    ? [
                        for (final breed in CatBreed.all)
                          if (breed.id != 'orange') _catCard(breed, width)
                      ]
                    : [for (final item in items) _card(item, width)],
              );
            }),
          ),
        ]),
      ),
    );
  }

  Widget _chip(CampCategory? c) {
    final on = c == _tab;
    return Padding(
      padding: const EdgeInsets.only(right: DS.spaceXs),
      child: ChoiceChip(
        selected: on,
        onSelected: (_) {
          GameAudio.instance.play(GameSound.click);
          setState(() => _tab = c);
        },
        avatar: Icon(c == null ? Icons.pets_rounded : _categoryIcons[c],
            size: 16, color: DS.ink),
        label: Text(c?.label ?? 'Mèo'),
        showCheckmark: false,
        visualDensity: VisualDensity.compact,
        labelStyle: const TextStyle(
            color: DS.ink, fontWeight: FontWeight.w800, fontSize: DS.fontBody),
        backgroundColor: DS.cream,
        selectedColor: DS.gold,
        side: BorderSide(color: on ? DS.goldEdge : DS.wood, width: 1.5),
        shape: const StadiumBorder(),
      ),
    );
  }

  /// A breed for sale: face, catch trait and price.
  Widget _catCard(CatBreed breed, double width) {
    final owned = camp.unlocked(breed.id);
    final price = CampState.catPrices[breed.id] ?? 0;
    final afford = camp.coins >= price;
    return Container(
      width: width,
      margin: const EdgeInsets.only(right: DS.spaceSm),
      padding: const EdgeInsets.all(DS.spaceXs),
      decoration: BoxDecoration(
        color: owned ? DS.surfaceMuted : Colors.white,
        borderRadius: BorderRadius.circular(DS.radiusMd),
        border: Border.all(color: owned ? DS.mutedBorder : DS.wood, width: 2),
      ),
      child: Row(children: [
        AspectRatio(
          aspectRatio: 1,
          child: FittedBox(
              child: CatFace(breed.id,
                  background: const Color(0xFFFFE3B0), border: DS.wood)),
        ),
        const SizedBox(width: DS.spaceXs),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(breed.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: DS.ink,
                      fontWeight: FontWeight.w900,
                      fontSize: DS.fontBody)),
              const SizedBox(height: DS.spaceXs),
              SizedBox(
                height: 26,
                width: double.infinity,
                child: owned
                    ? const Align(
                        alignment: Alignment.centerLeft,
                        child: Text('✓ Đang ở trại',
                            style: TextStyle(
                                color: DS.success,
                                fontSize: DS.fontBody,
                                fontWeight: FontWeight.w800)))
                    : ElevatedButton.icon(
                        style: DS.primary.copyWith(
                            padding:
                                const WidgetStatePropertyAll(EdgeInsets.zero),
                            textStyle: const WidgetStatePropertyAll(TextStyle(
                                fontSize: DS.fontBody,
                                fontWeight: FontWeight.w900))),
                        onPressed: afford
                            ? () async {
                                final name = await showGameDialog<String>(
                                  context: context,
                                  builder: (_) => _CatNameDialog(breed: breed),
                                );
                                if (!mounted || name == null) return;
                                final bought =
                                    await camp.buyCat(breed.id, name: name);
                                if (!mounted) return;
                                if (!bought) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(const SnackBar(
                                    content: Text(
                                        'Chưa mua được mèo. Hãy kiểm tra số xu và thử lại.'),
                                  ));
                                  return;
                                }
                                GameAudio.instance.playGameplay(
                                    GameSound.campWelcome,
                                    priority: 3);
                                setState(() {});
                                widget.onBought();
                              }
                            : null,
                        icon:
                            const Icon(Icons.monetization_on_rounded, size: 14),
                        label: Text('$price')),
              ),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _card(CampDecoration item, double width) {
    final owned = camp.owned.contains(item.id);
    final afford = camp.coins >= item.price;
    return Container(
      width: width,
      margin: const EdgeInsets.only(right: DS.spaceSm),
      padding: const EdgeInsets.all(DS.spaceXs),
      decoration: BoxDecoration(
        color: owned ? DS.surfaceMuted : Colors.white,
        borderRadius: BorderRadius.circular(DS.radiusMd),
        border: Border.all(color: owned ? DS.mutedBorder : DS.wood, width: 2),
      ),
      // Art on the left keeps it large even on short screens.
      child: Row(children: [
        AspectRatio(
            aspectRatio: 1,
            child: FittedBox(
                child: RepaintBoundary(child: _DecorationArt(item.id)))),
        const SizedBox(width: DS.spaceXs),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: DS.ink,
                      fontWeight: FontWeight.w800,
                      fontSize: DS.fontBody)),
              const SizedBox(height: DS.spaceXs),
              SizedBox(
                height: 26,
                width: double.infinity,
                child: owned
                    ? const Align(
                        alignment: Alignment.centerLeft,
                        child: Text('✓ Đã có',
                            style: TextStyle(
                                color: DS.success,
                                fontSize: DS.fontBody,
                                fontWeight: FontWeight.w800)))
                    : ElevatedButton.icon(
                        style: DS.primary.copyWith(
                            padding:
                                const WidgetStatePropertyAll(EdgeInsets.zero),
                            textStyle: const WidgetStatePropertyAll(TextStyle(
                                fontSize: DS.fontBody,
                                fontWeight: FontWeight.w900))),
                        onPressed: afford
                            ? () async {
                                final bought = await camp.buy(item);
                                if (!mounted || !bought) return;
                                GameAudio.instance.playGameplay(
                                    GameSound.campBuy,
                                    priority: 3);
                                setState(() {});
                                widget.onBought();
                              }
                            : null,
                        icon:
                            const Icon(Icons.monetization_on_rounded, size: 14),
                        label: Text('${item.price}')),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

const _categoryIcons = {
  CampCategory.toys: Icons.toys_rounded,
  CampCategory.beds: Icons.bed_rounded,
  CampCategory.furniture: Icons.weekend_rounded,
  CampCategory.wall: Icons.photo_rounded,
  CampCategory.plants: Icons.local_florist_rounded,
};

enum _Panel { none, shop, cats, basket }

enum _CampIcon { shop, heart, fish }

/// Top-bar toggle for a bottom panel, with a hand-drawn icon.
class _PanelButton extends StatelessWidget {
  const _PanelButton(
      {required this.label,
      required this.icon,
      required this.active,
      required this.onTap});
  final String label;
  final _CampIcon icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: active ? DS.gold : DS.cream,
        shape: StadiumBorder(
            side: BorderSide(color: active ? DS.goldEdge : DS.wood, width: 2)),
        elevation: 2,
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                DS.spaceXs, DS.spaceXs, DS.spaceMd, DS.spaceXs),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              SizedBox.square(
                  dimension: 30,
                  child: CustomPaint(painter: _CampIconPainter(icon))),
              const SizedBox(width: DS.spaceXs),
              Text(label,
                  style: const TextStyle(
                      color: DS.ink,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .5)),
            ]),
          ),
        ),
      );
}

/// Shop: a little market stall with a striped awning and a fish sign.
/// Heart: a plump heart with a paw print and a shine.
class _CampIconPainter extends CustomPainter {
  const _CampIconPainter(this.icon);
  final _CampIcon icon;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 30, size.height / 30);
    Paint p(int c) => Paint()..color = Color(c);
    if (icon == _CampIcon.fish) {
      // A little wicker basket with a blue fish peeking out.
      final fish = Path()
        ..addOval(Rect.fromCenter(
            center: const Offset(14, 11), width: 15, height: 8.5))
        ..moveTo(20.5, 11)
        ..lineTo(26, 6.5)
        ..lineTo(26, 15.5)
        ..close();
      canvas.drawPath(fish, p(0xFF5AA7D6));
      canvas.drawCircle(const Offset(10, 10), 1.3, p(0xFF2B3A4A));
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              const Rect.fromLTWH(4, 14, 22, 12), const Radius.circular(4)),
          p(0xFFC98B4E));
      final weave = p(0xFF8C5A34)..strokeWidth = 1.4;
      for (final y in [18.0, 22.0]) {
        canvas.drawLine(Offset(6, y), Offset(24, y), weave);
      }
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              const Rect.fromLTWH(3, 13, 24, 3), const Radius.circular(1.5)),
          p(0xFF8C5A34));
    } else if (icon == _CampIcon.shop) {
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              const Rect.fromLTWH(5, 12, 20, 15), const Radius.circular(2)),
          p(0xFFE7C3A3));
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              const Rect.fromLTWH(12, 17, 7, 10), const Radius.circular(2)),
          p(0xFF8C5A34));
      canvas.drawRect(const Rect.fromLTWH(7, 16, 4, 4), p(0xFF7FB3C7));
      for (var i = 0; i < 5; i++) {
        final x = 3.0 + i * 4.8;
        canvas.drawPath(
            Path()
              ..moveTo(x, 6)
              ..lineTo(x + 4.8, 6)
              ..lineTo(x + 4.8, 11)
              ..arcToPoint(Offset(x, 11), radius: const Radius.circular(2.4))
              ..close(),
            p(i.isEven ? 0xFFE0533F : 0xFFFFF4DA));
      }
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              const Rect.fromLTWH(3, 3.5, 24, 3), const Radius.circular(1.5)),
          p(0xFF8C5A34));
      canvas.drawOval(
          Rect.fromCenter(center: const Offset(23, 20), width: 5, height: 3),
          p(0xFFF28A3A));
    } else {
      final heart = Path()
        ..moveTo(15, 26)
        ..cubicTo(2, 18, 3, 6, 10, 6)
        ..cubicTo(13, 6, 15, 9, 15, 10)
        ..cubicTo(15, 9, 17, 6, 20, 6)
        ..cubicTo(27, 6, 28, 18, 15, 26)
        ..close();
      canvas.drawPath(heart.shift(const Offset(0, 1.2)), p(0xFFA8323F));
      canvas.drawPath(heart, p(0xFFE85D6F));
      canvas.drawOval(
          Rect.fromCenter(center: const Offset(9.5, 10), width: 5, height: 3),
          p(0x99FFFFFF));
      final pad = p(0xFFFFF4DA);
      canvas.drawOval(
          Rect.fromCenter(center: const Offset(15, 17), width: 6, height: 4.5),
          pad);
      for (final d in const [
        Offset(11.6, 13.6),
        Offset(14, 12),
        Offset(16, 12),
        Offset(18.4, 13.6)
      ]) {
        canvas.drawCircle(d, 1.2, pad);
      }
    }
  }

  @override
  bool shouldRepaint(_CampIconPainter oldDelegate) => oldDelegate.icon != icon;
}

/// One inventory slot per edible species; only stocked fish can be dragged.
class _BasketBar extends StatelessWidget {
  const _BasketBar(
      {required this.onDragStart,
      required this.onDragEnd,
      required this.onClose});
  final ValueChanged<FishSpecies> onDragStart;
  final VoidCallback onDragEnd;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final basket = FishCollection.instance;
    final fish = FishSpecies.values.where((f) => !f.isJunk);
    return SafeArea(
      top: false,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: SizedBox(
          height: 74,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Flexible(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(12, 8, 8, 12),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  for (final f in fish) _draggable(f, basket.stockOf(f)),
                ]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: RoundButton(
                  glyph: GameGlyph.close, size: 30, onPressed: onClose),
            ),
          ]),
        ),
      ),
    );
  }

  /// Sideways swipes scroll the basket; dragging up lifts the fish out.
  Widget _draggable(FishSpecies fish, int left) => Padding(
        padding: const EdgeInsets.only(right: DS.spaceSm),
        child: left == 0
            ? _fishCard(fish, left)
            : Draggable<FishSpecies>(
                data: fish,
                affinity: Axis.vertical,
                dragAnchorStrategy: pointerDragAnchorStrategy,
                onDragStarted: () => onDragStart(fish),
                onDragEnd: (_) => onDragEnd(),
                feedback: Transform.translate(
                  offset: const Offset(-40, -30),
                  child: Transform.rotate(
                    angle: -.25,
                    child: SizedBox(
                        width: 80,
                        height: 52,
                        child: CustomPaint(painter: FishingFishArt(fish))),
                  ),
                ),
                childWhenDragging:
                    Opacity(opacity: .4, child: _fishCard(fish, left)),
                child: _fishCard(fish, left),
              ),
      );

  Widget _fishCard(FishSpecies fish, int left) => Tooltip(
        message: '${fish.label} · +${fish.affection} thân thiết · Còn $left',
        child: Semantics(
          label: '${fish.label}, còn $left, kéo vào mèo để cho ăn',
          child: SizedBox.square(
            dimension: 54,
            child: Stack(clipBehavior: Clip.none, children: [
              Positioned(
                left: 1.5,
                right: 1.5,
                top: 1.5,
                bottom: 1,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(6, 6, 6, 9),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: left > 0
                          ? const [Color(0xFFFFDE85), Color(0xFFF7B940)]
                          : const [Color(0xFFD2C6B0), Color(0xFFB4A58C)],
                    ),
                    borderRadius: BorderRadius.circular(13),
                    border:
                        Border.all(color: const Color(0xFF774016), width: 2.5),
                    boxShadow: const [
                      BoxShadow(color: Color(0x44402616), offset: Offset(0, 3)),
                    ],
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: left > 0
                          ? const Color(0xFFFFF4DA)
                          : const Color(0xFFE8E0D0),
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(
                          color: const Color(0x55B27A3E), width: 1.5),
                    ),
                    child: Opacity(
                      opacity: left > 0 ? 1 : .3,
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: CustomPaint(painter: FishingFishArt(fish)),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: -5,
                top: -5,
                child: Container(
                  constraints:
                      const BoxConstraints(minWidth: 21, minHeight: 21),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: left > 0
                        ? const Color(0xFF31586C)
                        : const Color(0xFFC0503A),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: const Color(0xFFFFEFCA), width: 1.5),
                  ),
                  child: Text('$left',
                      style: const TextStyle(
                          color: Color(0xFFFFFAEE),
                          fontSize: 11,
                          fontWeight: FontWeight.w900)),
                ),
              ),
            ]),
          ),
        ),
      );
}

/// Floating pill while a fish is dragged, or the result right after feeding.
class _FeedHint extends StatelessWidget {
  const _FeedHint(
      {required this.fish, required this.target, required this.toast});
  final FishSpecies? fish;
  final String? target;
  final String? toast;

  @override
  Widget build(BuildContext context) {
    final held = fish;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      if (held != null)
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: DS.spaceMd, vertical: DS.spaceXs),
          decoration: BoxDecoration(
              color: target == null ? DS.cream : DS.gold,
              borderRadius: BorderRadius.circular(DS.radiusXl),
              border: Border.all(
                  color: target == null ? DS.wood : DS.goldEdge, width: 2),
              boxShadow: DS.controlShadow),
          child: Text(
              target == null
                  ? 'Thả lên bé mèo để cho ăn ${held.label.toLowerCase()}'
                  : 'Thả cho $target ăn · +${held.affection}',
              style: const TextStyle(
                  color: DS.ink,
                  fontSize: DS.fontBody,
                  fontWeight: FontWeight.w900)),
        )
      else if (toast != null)
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: DS.spaceMd, vertical: DS.spaceXs),
          decoration: BoxDecoration(
              color: const Color(0xE6FFF0F2),
              borderRadius: BorderRadius.circular(DS.radiusLg),
              border: Border.all(color: const Color(0xFFE85D6F), width: 1.5)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(toast!,
                style: const TextStyle(
                    color: Color(0xFFB23A4E),
                    fontSize: DS.fontBody,
                    fontWeight: FontWeight.w900)),
            const SizedBox(width: DS.spaceXs),
            const Icon(Icons.favorite_rounded,
                size: 14, color: Color(0xFFE85D6F)),
          ]),
        ),
    ]);
  }
}

/// Bond panel: one card per breed with its face, a heart meter toward the
/// bonus, and what the bond unlocks. Locked breeds show how to get them.
class _BondBar extends StatelessWidget {
  const _BondBar({required this.onClose, required this.onRename});
  final VoidCallback onClose;
  final ValueChanged<CatBreed> onRename;

  @override
  Widget build(BuildContext context) {
    final camp = CampState.instance;
    return Container(
      decoration: const BoxDecoration(
        color: DS.surfaceGlass,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: DS.wood, width: 3)),
        boxShadow: [BoxShadow(color: DS.shadowColor, blurRadius: 10)],
      ),
      child: SafeArea(
        top: false,
        child: Column(children: [
          SizedBox(
            height: 36,
            child: Row(children: [
              const SizedBox(width: DS.spaceMd),
              const Text('ĐỘ THÂN THIẾT',
                  style: TextStyle(
                      color: DS.ink,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1)),
              const SizedBox(width: DS.spaceSm),
              const Expanded(
                child: Text(
                    'Vuốt ve hoặc cho ăn cá trong giỏ để tăng độ thân thiết',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: DS.soft, fontSize: DS.fontCaption)),
              ),
              Padding(
                padding:
                    const EdgeInsets.fromLTRB(DS.spaceXs, 0, DS.spaceSm, 0),
                child: RoundButton(
                    glyph: GameGlyph.close, size: 30, onPressed: onClose),
              ),
            ]),
          ),
          Expanded(
            child: LayoutBuilder(builder: (context, box) {
              final width = _campCardWidth(box.maxWidth, preferred: 190);
              return ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(
                    DS.spaceSm, 0, DS.spaceSm, DS.spaceSm),
                children: [
                  for (final breed in CatBreed.all) _card(camp, breed, width),
                ],
              );
            }),
          ),
        ]),
      ),
    );
  }

  Widget _card(CampState camp, CatBreed breed, double width) {
    final unlocked = camp.unlocked(breed.id);
    final love =
        (camp.affection[breed.id] ?? 0).clamp(0, CampState.bondedAffection);
    final bonded = camp.bonded(breed.id);
    return Container(
      width: width,
      margin: const EdgeInsets.only(right: DS.spaceSm),
      padding: const EdgeInsets.all(DS.spaceXs),
      decoration: BoxDecoration(
        color: unlocked ? Colors.white : DS.surfaceMuted,
        borderRadius: BorderRadius.circular(DS.radiusMd),
        border: Border.all(
            color: bonded
                ? DS.goldEdge
                : unlocked
                    ? DS.wood
                    : DS.mutedBorder,
            width: bonded ? 3 : 2),
      ),
      child: Row(children: [
        Opacity(
          opacity: unlocked ? 1 : .35,
          child: AspectRatio(
            aspectRatio: 1,
            child: Stack(children: [
              Positioned.fill(
                child: FittedBox(
                    child: CatFace(breed.id,
                        background: const Color(0xFFFFE3B0),
                        border: bonded ? DS.goldEdge : DS.wood)),
              ),
              if (bonded)
                const Positioned(
                    right: 0,
                    top: 0,
                    child: Icon(Icons.star_rounded, color: DS.star, size: 18)),
            ]),
          ),
        ),
        const SizedBox(width: DS.spaceXs),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Tooltip(
                message:
                    unlocked ? 'Đổi tên ${camp.nameOf(breed.id)}' : breed.name,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: unlocked ? () => onRename(breed) : null,
                    borderRadius: BorderRadius.circular(DS.radiusXs),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: DS.spaceXs),
                      child: Row(children: [
                        Expanded(
                            child: Text(camp.nameOf(breed.id),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: DS.ink,
                                    fontWeight: FontWeight.w900,
                                    fontSize: DS.fontBody))),
                        if (unlocked) ...[
                          const SizedBox(width: DS.space2),
                          const Icon(Icons.edit_rounded,
                              size: DS.iconSm, color: DS.goldEdge),
                        ],
                      ]),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 1),
              if (!unlocked)
                const Row(children: [
                  Icon(Icons.lock_rounded, size: 13, color: DS.mutedText),
                  SizedBox(width: DS.spaceXs),
                  Expanded(
                    child: Text('Mua ở cửa hàng',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: DS.mutedText, fontSize: DS.fontCaption)),
                  ),
                ])
              else ...[
                // Ten small hearts fill up as affection grows.
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    for (var i = 0; i < CampState.bondedAffection; i++)
                      Padding(
                        padding: EdgeInsets.only(
                            right: i == CampState.bondedAffection - 1 ? 0 : 1),
                        child: Icon(Icons.favorite_rounded,
                            size: 10,
                            color: i < love
                                ? const Color(0xFFE85D6F)
                                : const Color(0x33A8323F)),
                      ),
                  ]),
                ),
                const SizedBox(height: 1),
                Text(
                    bonded
                        ? 'Thân thiết ♥'
                        : '$love/${CampState.bondedAffection} ♥',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: bonded ? DS.goldEdge : DS.soft,
                        fontSize: DS.fontCaption,
                        fontWeight: FontWeight.w700)),
              ],
            ],
          ),
        ),
      ]),
    );
  }
}

/// Cards keep their designed width; only a very narrow screen shrinks them.
double _campCardWidth(double available, {required double preferred}) {
  final usable = available - DS.spaceSm * 2;
  return min(preferred, max(150.0, usable));
}

/// A bought decoration in the room. Dragging it rebuilds only this widget;
/// the spot is saved when released.
class _PlacedDecoration extends StatefulWidget {
  const _PlacedDecoration(
      {super.key,
      required this.item,
      required this.room,
      required this.onPlaced});
  final CampDecoration item;
  final Size room;
  final VoidCallback onPlaced;

  @override
  State<_PlacedDecoration> createState() => _PlacedDecorationState();
}

class _PlacedDecorationState extends State<_PlacedDecoration> {
  bool _dragging = false;
  CampState get camp => CampState.instance;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final w = widget.room.width, h = widget.room.height;
    final (x, y) = camp.positionOf(item);
    return Positioned(
      left: w * x - 30 * item.scale,
      top: h * y - 30 * item.scale,
      child: GestureDetector(
        onPanStart: (_) => setState(() => _dragging = true),
        onPanUpdate: (d) {
          final (x, y) = camp.positionOf(item);
          setState(() => camp.placement[item.id] = (
                (x + d.delta.dx / w).clamp(.03, .97),
                (y + d.delta.dy / h).clamp(.05, .95),
              ));
        },
        onPanEnd: (_) {
          final (nx, ny) = camp.positionOf(item);
          camp.place(item.id, nx, ny);
          GameAudio.instance.playGameplay(GameSound.campPlace, priority: 1);
          setState(() => _dragging = false);
          widget.onPlaced();
        },
        child: AnimatedScale(
          scale: _dragging ? 1.08 : 1,
          duration: DS.fastDuration,
          child: Opacity(
            opacity: _dragging ? .85 : 1,
            child: SizedBox.square(
                dimension: 60 * item.scale,
                child: FittedBox(
                    child: RepaintBoundary(child: _DecorationArt(item.id)))),
          ),
        ),
      ),
    );
  }
}

/// Laid-out name tags and the petting heart, reused across frames. Rebuilt
/// only when a name, the text style or the text scale changes.
class _CatLabels {
  TextStyle? _style;
  TextScaler _scaler = TextScaler.noScaling;
  final _names = <String, TextPainter>{};
  TextPainter? _heart;

  void update(TextStyle style, TextScaler scaler) {
    if (style == _style && scaler == _scaler) return;
    _style = style;
    _scaler = scaler;
    dispose();
  }

  TextPainter name(String text) => _names[text] ??= TextPainter(
        text: TextSpan(text: text, style: _style),
        textDirection: TextDirection.ltr,
        textScaler: _scaler,
        maxLines: 1,
        ellipsis: '…',
      )..layout(maxWidth: _CampCatsPainter.spriteSize - 2 * DS.spaceXs);

  TextPainter get heart => _heart ??= TextPainter(
        text: TextSpan(
          text: String.fromCharCode(Icons.favorite.codePoint),
          style: TextStyle(
            fontSize: 18,
            fontFamily: Icons.favorite.fontFamily,
            package: Icons.favorite.fontPackage,
            color: const Color(0xFFE85D6F),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

  void forget(String text) => _names.remove(text)?.dispose();

  void dispose() {
    for (final painter in _names.values) {
      painter.dispose();
    }
    _names.clear();
    _heart?.dispose();
    _heart = null;
  }
}

/// Draws every camp cat (sprite frame, name tag, heart) straight onto the
/// canvas. Repaints on [repaint] without any widget rebuild or layout.
class _CampCatsPainter extends CustomPainter {
  _CampCatsPainter({
    required this.cats,
    required this.sprites,
    required this.missing,
    required this.labels,
    required this.hit,
    required Listenable repaint,
  }) : super(repaint: repaint);

  final List<CampResident> cats;
  final Map<String, ui.Image> sprites;
  final Set<String> missing;
  final _CatLabels labels;
  final bool Function(Offset) hit;

  static const double spriteSize = 80;
  static const double _tagHeight = 20;

  static final _spritePaint = Paint()..filterQuality = FilterQuality.medium;
  static final _tagPaint = Paint()..color = DS.cream.withValues(alpha: .92);

  /// Same footprint as the old widget: an 80px-wide name row over the sprite,
  /// with the sprite centred on the cat's room position.
  static Rect hitBox(CampResident cat, Size room) => Rect.fromLTWH(
      room.width * cat.x - spriteSize / 2,
      room.height * cat.y - spriteSize / 2 - _tagHeight,
      spriteSize,
      spriteSize + _tagHeight);

  @override
  void paint(Canvas canvas, Size size) {
    for (final cat in cats) {
      final cx = size.width * cat.x, cy = size.height * cat.y;
      _sprite(canvas, cat, Offset(cx, cy));
      final tagY = cy - spriteSize / 2 - _tagHeight / 2;
      if (cat.heart > 0) {
        final heart = labels.heart;
        heart.paint(
            canvas, Offset(cx - heart.width / 2, tagY - _tagHeight / 2 - 18));
      }
      final name = labels.name(CampState.instance.nameOf(cat.type));
      final tag = Rect.fromCenter(
          center: Offset(cx, tagY),
          width: name.width + 2 * DS.spaceXs,
          height: name.height + 2 * DS.space2);
      canvas.drawRRect(
          RRect.fromRectAndRadius(tag, const Radius.circular(DS.radiusSm)),
          _tagPaint);
      name.paint(canvas, Offset(tag.left + DS.spaceXs, tag.top + DS.space2));
    }
  }

  void _sprite(Canvas canvas, CampResident cat, Offset c) {
    final breed = CatBreed.of(cat.type);
    final path = breed.sheet(cat.act.sheet);
    var image = sprites[path];
    var frames = cat.act.frames, frame = cat.frame;
    // While a sheet is still decoding, hold the idle pose.
    if (image == null && !missing.contains(path)) {
      image = sprites[breed.sheet(CampAct.idle.sheet)];
      frames = CampAct.idle.frames;
      frame = 0;
    }
    if (cat.sleeping) {
      // Curled-up sleep sheet once loaded; until then the closed-eye idle frame.
      final sleep = sprites[breed.sheet(campSleepSheet)];
      if (sleep != null) {
        image = sleep;
        frames = campSleepFrameCount;
        frame = (cat.clock * 3).floor() % campSleepFrameCount;
      }
    }
    var dst = Rect.fromCenter(center: c, width: spriteSize, height: spriteSize);
    if (cat.sleeping) {
      // Slow breathing: the body swells a little, feet stay on the floor.
      final breath = 1 + .03 * sin(cat.clock * 2.2);
      dst = Rect.fromLTRB(
          dst.left, dst.bottom - spriteSize * breath, dst.right, dst.bottom);
      _snore(canvas, c, cat.clock, cat.facingLeft);
    }
    if (image == null) {
      if (missing.contains(path)) {
        canvas.drawCircle(c, spriteSize / 2, Paint()..color = breed.color);
      }
      return;
    }
    final cell = image.width / frames;
    final src = Rect.fromLTWH(cell * frame, 0, cell, image.height.toDouble());
    if (cat.facingLeft) {
      canvas.save();
      canvas.translate(c.dx * 2, 0);
      canvas.scale(-1, 1);
      canvas.drawImageRect(image, src, dst, _spritePaint);
      canvas.restore();
    } else {
      canvas.drawImageRect(image, src, dst, _spritePaint);
    }
  }

  static final _zPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  /// Three "z"s drifting up from the sleeping cat's head, fading in and out.
  void _snore(Canvas canvas, Offset c, double clock, bool left) {
    final side = left ? -1.0 : 1.0;
    for (var i = 0; i < 3; i++) {
      final t = (clock * .45 + i / 3) % 1;
      final s = 5 + t * 5;
      final o =
          c + Offset(side * (12 + t * 14) - s / 2, -spriteSize * .32 - t * 24);
      _zPaint.color = DS.ink.withValues(alpha: .85 * sin(pi * t));
      canvas.drawPath(
          Path()
            ..moveTo(o.dx, o.dy)
            ..lineTo(o.dx + s, o.dy)
            ..lineTo(o.dx, o.dy + s)
            ..lineTo(o.dx + s, o.dy + s),
          _zPaint);
    }
  }

  @override
  bool? hitTest(Offset position) => hit(position);

  @override
  bool shouldRepaint(_CampCatsPainter oldDelegate) => true;
}
