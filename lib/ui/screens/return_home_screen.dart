import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

import '../../game/return_home/return_home_game.dart';
import '../../game/cats/cat_breed.dart';
import '../design.dart';
import '../widgets/cat_sprite.dart';
import '../widgets/return_home_buttons.dart';
import '../widgets/game_glyphs.dart';
import '../widgets/round_button.dart';
import '../widgets/skill_glyphs.dart';

class ReturnHomeScreen extends StatefulWidget {
  const ReturnHomeScreen({super.key});

  @override
  State<ReturnHomeScreen> createState() => _ReturnHomeScreenState();
}

class _ReturnHomeScreenState extends State<ReturnHomeScreen> {
  late final ReturnHomeGame _game;
  bool _showingComboHelp = false;

  @override
  void initState() {
    super.initState();
    _game = ReturnHomeGame();
  }

  Future<void> _showComboHelp(BuildContext context) async {
    if (_showingComboHelp) return;
    _showingComboHelp = true;
    final resumeAfter = !_game.paused;
    _game.cancelAim();
    if (_game.isLoaded) _game.joystick.delta.setZero();
    _game.pauseEngine();
    try {
      await showDialog<void>(
        context: context,
        builder: (_) => _ComboHelpDialog(
            selectedCat: _game.started ? _game.selectedCat : null),
      );
    } finally {
      _showingComboHelp = false;
      if (mounted && resumeAfter) _game.resumeEngine();
    }
  }

  @override
  Widget build(BuildContext context) {
    _game.hudPadding = MediaQuery.paddingOf(context);
    return Scaffold(
      body: GameWidget<ReturnHomeGame>(
        game: _game,
        overlayBuilderMap: {
          'chooseCat': (context, game) => _ChooseCatOverlay(
              game: game, onHelp: () => _showComboHelp(context)),
          'skill': (context, game) => _SkillButton(game: game),
          'exit': (context, game) => SafeArea(
                child: Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      _ComboHelpButton(
                          onPressed: () => _showComboHelp(context)),
                      const SizedBox(width: 10),
                      ReturnHomeHomeButton(
                          onPressed: () => Navigator.of(context).pop()),
                    ]),
                  ),
                ),
              ),
        },
        initialActiveOverlays: const ['exit', 'chooseCat'],
      ),
    );
  }
}

class _SkillButton extends StatefulWidget {
  const _SkillButton({required this.game});
  final ReturnHomeGame game;

  @override
  State<_SkillButton> createState() => _SkillButtonState();
}

class _SkillButtonState extends State<_SkillButton> {
  Timer? _timer;
  final _cancelKey = GlobalKey();
  bool _cancelHot = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Widget _attackButton(int slot, double size) {
    final game = widget.game;
    final attack = game.attacks[slot];
    return Column(mainAxisSize: MainAxisSize.min, children: [
      ReturnHomeAimButton(
        key: ValueKey(attack),
        label: attack.label,
        glyph: attack.glyph,
        color: attack.color,
        size: size,
        aimable: attack.aimable,
        activeLeft: game.attackActive(slot),
        cooldownLeft: game.attackCooldown[slot],
        cooldownTotal: attack.cooldown,
        cancelKey: _cancelKey,
        onCancelHover: (hot) => setState(() => _cancelHot = hot),
        onAim: (stick) {
          final was = game.aimingSlot;
          game.aimAttack(slot, stick);
          if (was != game.aimingSlot) setState(() {});
        },
        onCast: (stick) => setState(() => game.castAttack(slot, stick)),
        onCancel: () => setState(game.cancelAim),
      ),
      const SizedBox(height: 2),
      Text(attack.label,
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              shadows: [Shadow(color: Color(0xFF3A2010), blurRadius: 3)])),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    if (!game.started) return const SizedBox.shrink();
    // Keep the thumb resting position inboard of the screen edges.
    const main = 84.0, small = 62.0, arc = 116.0, label = 16.0;
    const box = Size(main / 2 + arc + small / 2 + 20,
        main / 2 + arc + small / 2 + label + 8);
    final mainCenter = Offset(box.width - main / 2, box.height - main / 2 - 4);
    Widget onArc(double degrees, Widget child) {
      final a = degrees * pi / 180;
      final c = mainCenter + Offset(cos(a) * arc, -sin(a) * arc);
      return Positioned(
          left: c.dx - small / 2 - 20,
          top: c.dy - small / 2,
          width: small + 40,
          child: Center(child: child));
    }

    // Original corner placement, raised 20px for easier thumb access.
    const right = 18.0, bottom = 34.0;
    final aiming = game.aimingSlot != null;
    return SafeArea(
      child: Stack(children: [
        Positioned(
          key: const ValueKey('cluster'),
          right: right,
          bottom: bottom,
          child: SizedBox.fromSize(
            size: box,
            child: Stack(clipBehavior: Clip.none, children: [
              Positioned(
                left: mainCenter.dx - main / 2,
                top: mainCenter.dy - main / 2,
                child: ReturnHomeSkillButton(
                  catType: game.selectedCat,
                  size: main,
                  ready: game.skillReady,
                  cooldownLeft: game.skillCooldown,
                  cooldownTotal:
                      CatBreed.of(game.selectedCat).homeSkill.cooldown,
                  onPressed: game.activateSkill,
                ),
              ),
              onArc(187, _attackButton(0, small)),
              onArc(139, _attackButton(1, small)),
              onArc(91, _attackButton(2, small)),
            ]),
          ),
        ),
        // Added after the cluster so showing it never rebuilds the buttons
        // (that used to drop the held finger and need a second press).
        if (aiming)
          Positioned(
            key: const ValueKey('cancel'),
            right: 54,
            top: 66,
            child: SizedBox.square(
              dimension: 76,
              child: Center(
                child: ReturnHomeCancelButton(key: _cancelKey, hot: _cancelHot),
              ),
            ),
          ),
      ]),
    );
  }
}

class _ChooseCatOverlay extends StatelessWidget {
  const _ChooseCatOverlay({required this.game, required this.onHelp});
  final ReturnHomeGame game;
  final VoidCallback onHelp;

  @override
  Widget build(BuildContext context) => Material(
        color: DS.scrim,
        child: Stack(children: [
          // The picker covers the in-game exit button, so it has its own.
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  RoundButton(
                      glyph: GameGlyph.home,
                      tooltip: 'Về Trang chủ',
                      onPressed: () => Navigator.of(context).pop()),
                  _ComboHelpButton(onPressed: onHelp),
                ],
              ),
            ),
          ),
          Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 420),
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              decoration: DS.card,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('CHỌN MÈO', style: DS.title),
                const SizedBox(height: 16),
                Wrap(
                    spacing: 9,
                    runSpacing: 9,
                    alignment: WrapAlignment.center,
                    children: [
                      for (final breed in CatBreed.all)
                        _catButton(context, breed),
                    ])
              ]),
            ),
          ),
        ]),
      );

  Widget _catButton(BuildContext context, CatBreed breed) => SizedBox(
        width: 165,
        height: 52,
        child: ElevatedButton.icon(
          onPressed: () => game.chooseCat(breed.id),
          icon: CatFace(breed.id, size: 34),
          label: Text(breed.name),
          style: DS.primary,
        ),
      );
}

class _ComboHelpButton extends StatelessWidget {
  const _ComboHelpButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => RoundGameButton(
        tooltip: 'Hướng dẫn combo',
        size: 44,
        onPressed: onPressed,
        child: const Text('?',
            style: TextStyle(
                color: DS.ink, fontSize: 27, fontWeight: FontWeight.w900)),
      );
}

class _ComboHelpDialog extends StatefulWidget {
  const _ComboHelpDialog({this.selectedCat});
  final String? selectedCat;

  @override
  State<_ComboHelpDialog> createState() => _ComboHelpDialogState();
}

class _ComboHelpDialogState extends State<_ComboHelpDialog> {
  late int _selected;
  late final ScrollController _tabs;
  final _content = ScrollController();

  @override
  void initState() {
    super.initState();
    _selected =
        max(0, CatBreed.all.indexWhere((b) => b.id == widget.selectedCat));
    _tabs =
        ScrollController(initialScrollOffset: max(0, _selected - 2) * 100.0);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _content.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Dialog(
        backgroundColor: DS.cream,
        shape: DS.dialogShape,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: SizedBox(
          width: 700,
          height: min(
              440,
              MediaQuery.sizeOf(context).height -
                  MediaQuery.paddingOf(context).vertical -
                  24),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(children: [
              Row(children: [
                const Expanded(child: Text('THẺ COMBO', style: DS.title)),
                IconButton(
                  constraints:
                      const BoxConstraints(minWidth: 40, minHeight: 40),
                  tooltip: 'Đóng hướng dẫn',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const GameGlyphView(GameGlyph.close),
                ),
              ]),
              SizedBox(
                height: 44,
                child: ListView.separated(
                  controller: _tabs,
                  scrollDirection: Axis.horizontal,
                  itemCount: CatBreed.all.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, index) {
                    final breed = CatBreed.all[index];
                    return Center(
                        child: ChoiceChip(
                      avatar: CatFace(breed.id, size: 28),
                      label: Text(breed.name),
                      selected: index == _selected,
                      showCheckmark: false,
                      selectedColor: DS.gold.withOpacity(.45),
                      backgroundColor: Colors.white.withOpacity(.6),
                      side: BorderSide(
                          color: index == _selected
                              ? DS.goldEdge
                              : DS.mutedBorder),
                      labelStyle: const TextStyle(
                          color: DS.ink,
                          fontSize: 13,
                          fontWeight: FontWeight.w800),
                      onSelected: (_) {
                        _content.jumpTo(0);
                        setState(() => _selected = index);
                      },
                    ));
                  },
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                  child: Scrollbar(
                controller: _content,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: _content,
                  padding: const EdgeInsets.only(right: 8),
                  child: _comboCard(CatBreed.all[_selected]),
                ),
              )),
              const SizedBox(height: 8),
              const Text('Chọn mèo để xem combo · Trò chơi đang tạm dừng',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: DS.soft, fontSize: 12)),
            ]),
          ),
        ),
      );

  Widget _comboCard(CatBreed breed) {
    final combo = breed.homeCombo;
    final selected = breed.id == widget.selectedCat;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.75),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DS.wood, width: 2),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CatFace(breed.id, size: 34),
          const SizedBox(width: 10),
          Expanded(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(breed.name,
                  style: const TextStyle(color: DS.soft, fontSize: 12)),
              Text(combo.name,
                  style: const TextStyle(
                      color: DS.ink,
                      fontSize: 19,
                      fontWeight: FontWeight.w900)),
            ],
          )),
          if (selected)
            const Text('ĐANG CHƠI',
                style: TextStyle(
                    color: DS.label,
                    fontSize: 11,
                    fontWeight: FontWeight.w800)),
        ]),
        const SizedBox(height: 8),
        LayoutBuilder(builder: (_, constraints) {
          final steps = Column(children: [
            for (var i = 0; i < combo.steps.length; i++) ...[
              if (i > 0)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 2),
                  child: Icon(Icons.keyboard_arrow_down_rounded,
                      color: DS.label, size: 20),
                ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: combo.steps[i].attack.color.withOpacity(.09),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: combo.steps[i].attack.color.withOpacity(.4)),
                ),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: combo.steps[i].attack.color.withOpacity(.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                            child: SkillGlyphView(combo.steps[i].attack.glyph,
                                size: 30)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                          child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Bước ${i + 1} · ${combo.steps[i].attack.label}',
                              style: const TextStyle(
                                  color: DS.ink,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900)),
                          const SizedBox(height: 4),
                          Text(combo.steps[i].instruction,
                              style: const TextStyle(
                                  color: DS.ink, fontSize: 13, height: 1.35)),
                        ],
                      )),
                    ]),
              ),
            ],
          ]);
          final effect = Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: DS.gold.withOpacity(.2),
                borderRadius: BorderRadius.circular(10)),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Row(children: [
                Icon(Icons.auto_awesome_rounded, color: DS.goldEdge, size: 18),
                SizedBox(width: 6),
                Expanded(
                    child: Text('HIỆU ỨNG COMBO',
                        style: TextStyle(
                            color: DS.ink,
                            fontSize: 12,
                            fontWeight: FontWeight.w900))),
              ]),
              const SizedBox(height: 8),
              Text(combo.effect,
                  style: const TextStyle(
                      color: DS.ink, fontSize: 13, height: 1.45)),
            ]),
          );
          if (constraints.maxWidth >= 480) {
            return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(flex: 3, child: steps),
              const SizedBox(width: 12),
              Expanded(flex: 2, child: effect),
            ]);
          }
          return Column(children: [steps, const SizedBox(height: 12), effect]);
        }),
      ]),
    );
  }
}
