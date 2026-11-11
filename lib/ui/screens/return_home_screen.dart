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
          'victory': (context, game) => _VictoryOverlay(game: game),
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

class _VictoryOverlay extends StatelessWidget {
  const _VictoryOverlay({required this.game});
  final ReturnHomeGame game;

  @override
  Widget build(BuildContext context) {
    final seconds = game.elapsed.floor();
    final time = '${(seconds ~/ 60).toString().padLeft(2, '0')}:'
        '${(seconds % 60).toString().padLeft(2, '0')}';
    return Material(
      color: DS.scrim,
      child: SafeArea(
          child: Center(
              child: Padding(
        padding: const EdgeInsets.all(16),
        child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Container(
              width: 440,
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 18),
              decoration: DS.card,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('CHIẾN THẮNG!', style: DS.title),
                const SizedBox(height: 4),
                const Text('Mèo đã về nhà an toàn',
                    style: TextStyle(color: DS.soft, fontSize: 14)),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  CatSprite(type: game.selectedCat, size: 70),
                  const SizedBox(width: 10),
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    for (var i = 0; i < 3; i++)
                      Icon(
                          i < game.stars
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          size: 38,
                          color: i < game.stars ? DS.goldEdge : DS.mutedBorder),
                  ]),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                      child: _stat(Icons.timer_outlined, 'Thời gian', time)),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _stat(Icons.set_meal_rounded, 'Cá thu thập',
                          '${game.fish}')),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                      child: ElevatedButton.icon(
                    style: DS.secondary,
                    onPressed: () => Navigator.of(context).pushReplacement(
                        MaterialPageRoute<void>(
                            builder: (_) => const ReturnHomeScreen())),
                    icon: const Icon(Icons.replay_rounded, size: 20),
                    label: const Text('Chơi lại',
                        style: TextStyle(fontFamily: 'Roboto')),
                  )),
                  const SizedBox(width: 10),
                  Expanded(
                      child: ElevatedButton.icon(
                    style: DS.primary,
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const GameGlyphView(GameGlyph.home, size: 20),
                    label: const Text('Về nhà',
                        style: TextStyle(fontFamily: 'Roboto')),
                  )),
                ]),
              ]),
            )),
      ))),
    );
  }

  Widget _stat(IconData icon, String label, String value) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
            color: Colors.white.withOpacity(.65),
            borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          Icon(icon, color: DS.label, size: 22),
          const SizedBox(width: 8),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(label,
                    style: const TextStyle(color: DS.soft, fontSize: 11)),
                Text(value,
                    style: const TextStyle(
                        color: DS.ink,
                        fontSize: 18,
                        fontWeight: FontWeight.w900)),
              ])),
        ]),
      );
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

  @override
  void initState() {
    super.initState();
    _selected =
        max(0, CatBreed.all.indexWhere((b) => b.id == widget.selectedCat));
  }

  @override
  Widget build(BuildContext context) => Dialog(
        backgroundColor: DS.cream,
        shape: DS.dialogShape,
        insetPadding: const EdgeInsets.all(12),
        child: SizedBox(
          width: 860,
          height: min(
              540,
              MediaQuery.sizeOf(context).height -
                  MediaQuery.paddingOf(context).vertical -
                  24),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: LayoutBuilder(builder: (_, constraints) {
              final wide = constraints.maxWidth >= 480;
              return Column(children: [
                Row(children: [
                  const Expanded(
                      child: Text('THẺ COMBO',
                          style: TextStyle(
                              color: DS.ink,
                              fontSize: 19,
                              fontWeight: FontWeight.w900))),
                  IconButton(
                    constraints:
                        const BoxConstraints(minWidth: 36, minHeight: 36),
                    padding: const EdgeInsets.all(6),
                    tooltip: 'Đóng hướng dẫn',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const GameGlyphView(GameGlyph.close, size: 24),
                  ),
                ]),
                SizedBox(
                    height: 48,
                    child: Row(children: [
                      for (var index = 0; index < CatBreed.all.length; index++)
                        Expanded(
                            child: Padding(
                          padding: EdgeInsets.only(
                              right: index == CatBreed.all.length - 1 ? 0 : 6),
                          child: _catTab(index, wide),
                        )),
                    ])),
                const SizedBox(height: 6),
                Expanded(child: _comboCard(CatBreed.all[_selected], wide)),
                const SizedBox(height: 6),
                const Text('Chọn mèo để xem combo · Trò chơi đang tạm dừng',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: DS.soft, fontSize: 11)),
              ]);
            }),
          ),
        ),
      );

  Widget _catTab(int index, bool wide) {
    final breed = CatBreed.all[index];
    final selected = index == _selected;
    final name = FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(breed.name,
            style: TextStyle(
                color: DS.ink,
                fontSize: wide ? 12 : 10.5,
                fontWeight: FontWeight.w800)));
    return Semantics(
      selected: selected,
      child: Material(
        color:
            selected ? DS.gold.withOpacity(.45) : Colors.white.withOpacity(.6),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(
                color: selected ? DS.goldEdge : DS.mutedBorder,
                width: selected ? 2 : 1)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => setState(() => _selected = index),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
            child: wide
                ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    CatFace(breed.id, size: 25),
                    const SizedBox(width: 4),
                    Flexible(child: name),
                  ])
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                        CatFace(breed.id, size: 22),
                        name,
                      ]),
          ),
        ),
      ),
    );
  }

  Widget _comboCard(CatBreed breed, bool wide) {
    final combo = breed.homeCombo;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(.75),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: DS.wood, width: 2)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CatFace(breed.id, size: 26),
          const SizedBox(width: 6),
          Expanded(
              child: Text(combo.name,
                  style: const TextStyle(
                      color: DS.ink,
                      fontSize: 17,
                      fontWeight: FontWeight.w900))),
          if (breed.id == widget.selectedCat)
            const Text('ĐANG CHƠI',
                style: TextStyle(
                    color: DS.label,
                    fontSize: 10,
                    fontWeight: FontWeight.w800)),
        ]),
        const SizedBox(height: 6),
        Expanded(child: LayoutBuilder(builder: (_, constraints) {
          final panels = [
            for (var i = 0; i < combo.steps.length; i++) _stepPanel(breed, i),
            _effectPanel(breed),
          ];
          // Scale only when a small viewport or larger text needs extra room.
          return FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: constraints.maxWidth,
              child: wide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                          for (var i = 0; i < panels.length; i++) ...[
                            if (i > 0)
                              const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 2),
                                  child: Icon(Icons.chevron_right_rounded,
                                      color: DS.label, size: 18)),
                            Expanded(flex: i == 2 ? 6 : 5, child: panels[i]),
                          ],
                        ])
                  : Column(children: [
                      for (var i = 0; i < panels.length; i++) ...[
                        if (i > 0) const SizedBox(height: 6),
                        panels[i],
                      ],
                    ]),
            ),
          );
        })),
      ]),
    );
  }

  Widget _stepPanel(CatBreed breed, int index) {
    final step = breed.homeCombo.steps[index];
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
          color: step.attack.color.withOpacity(.09),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: step.attack.color.withOpacity(.4))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                  color: step.attack.color.withOpacity(.2),
                  borderRadius: BorderRadius.circular(8)),
              child:
                  Center(child: SkillGlyphView(step.attack.glyph, size: 25))),
          const SizedBox(width: 6),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('BƯỚC ${index + 1}',
                    style: const TextStyle(
                        color: DS.soft,
                        fontSize: 10,
                        fontWeight: FontWeight.w800)),
                Text(step.attack.label,
                    style: const TextStyle(
                        color: DS.ink,
                        fontSize: 13,
                        fontWeight: FontWeight.w900)),
              ])),
        ]),
        const SizedBox(height: 6),
        Text(step.instruction,
            style: const TextStyle(color: DS.ink, fontSize: 12.5, height: 1.3)),
      ]),
    );
  }

  Widget _effectPanel(CatBreed breed) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: DS.gold.withOpacity(.2),
            borderRadius: BorderRadius.circular(10)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [
            Icon(Icons.auto_awesome_rounded, color: DS.goldEdge, size: 16),
            SizedBox(width: 4),
            Expanded(
                child: Text('HIỆU ỨNG COMBO',
                    style: TextStyle(
                        color: DS.ink,
                        fontSize: 11,
                        fontWeight: FontWeight.w900))),
          ]),
          const SizedBox(height: 6),
          Text(breed.homeCombo.effect,
              style:
                  const TextStyle(color: DS.ink, fontSize: 12.5, height: 1.3)),
        ]),
      );
}
