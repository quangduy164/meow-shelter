import 'dart:math';
import 'package:material_ui/material_ui.dart';
import '../../game/cats/cat_breed.dart';
import '../design.dart';
import 'cat_sprite.dart';
import 'skill_glyphs.dart';
import 'game_surfaces.dart';
import 'adventure_buttons.dart';

class AdventureComboHelpButton extends StatelessWidget {
  const AdventureComboHelpButton({super.key, required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => RoundGameButton(
        tooltip: 'Hướng dẫn combo',
        size: 44,
        onPressed: onPressed,
        child: const Text('?',
            style: TextStyle(
                color: DS.ink,
                fontSize: DS.fontSymbol,
                fontWeight: FontWeight.w900)),
      );
}

class AdventureComboHelpDialog extends StatefulWidget {
  const AdventureComboHelpDialog({super.key, this.selectedCat});
  final String? selectedCat;

  @override
  State<AdventureComboHelpDialog> createState() =>
      _AdventureComboHelpDialogState();
}

class _AdventureComboHelpDialogState extends State<AdventureComboHelpDialog> {
  late int _selected;

  @override
  void initState() {
    super.initState();
    _selected =
        max(0, CatBreed.all.indexWhere((b) => b.id == widget.selectedCat));
  }

  @override
  Widget build(BuildContext context) => GameDialog(
        maxWidth: DS.wideDialogWidth,
        padding: EdgeInsets.zero,
        insetPadding: const EdgeInsets.all(DS.spaceMd),
        child: SizedBox(
          width: 860,
          height: min(
              540,
              MediaQuery.sizeOf(context).height -
                  MediaQuery.paddingOf(context).vertical -
                  24),
          child: Padding(
            padding: const EdgeInsets.all(DS.spaceSm),
            child: LayoutBuilder(builder: (_, constraints) {
              final wide = constraints.maxWidth >= 480;
              return Column(children: [
                GameDialogHeader(
                  title: 'THẺ COMBO',
                  closeTooltip: 'Đóng hướng dẫn',
                  onClose: () => Navigator.of(context).pop(),
                ),
                SizedBox(
                    height: 48,
                    child: Row(children: [
                      for (var index = 0; index < CatBreed.all.length; index++)
                        Expanded(
                            child: Padding(
                          padding: EdgeInsets.only(
                              right: index == CatBreed.all.length - 1
                                  ? 0
                                  : DS.spaceXs),
                          child: _catTab(index, wide),
                        )),
                    ])),
                const SizedBox(height: DS.spaceXs),
                Expanded(child: _comboCard(CatBreed.all[_selected], wide)),
                const SizedBox(height: DS.spaceXs),
                const Text('Chọn mèo để xem combo · Trò chơi đang tạm dừng',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: DS.soft, fontSize: DS.fontCaption)),
              ]);
            }),
          ),
        ),
      );

  Color _comboColor(CatBreed breed) =>
      Color.lerp(breed.attacks.first.color, Colors.black, .25)!;

  Widget _catTab(int index, bool wide) {
    final breed = CatBreed.all[index];
    final selected = index == _selected;
    final name = FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(breed.name,
            style: TextStyle(
                color: selected ? Colors.white : _comboColor(breed),
                fontSize: wide ? DS.fontBody : DS.fontCaption,
                fontWeight: FontWeight.w800)));
    return Semantics(
      selected: selected,
      child: Material(
        color: selected
            ? _comboColor(breed)
            : Color.lerp(Colors.white, _comboColor(breed), .18)!,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DS.radiusMd),
            side:
                BorderSide(color: _comboColor(breed), width: selected ? 2 : 1)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => setState(() => _selected = index),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: DS.spaceXs, vertical: DS.spaceXs),
            child: wide
                ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    CatFace(breed.id, size: 25),
                    const SizedBox(width: DS.spaceXs),
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
      padding: const EdgeInsets.all(DS.spaceSm),
      decoration: BoxDecoration(
          color: Color.lerp(DS.cream, _comboColor(breed), .1),
          borderRadius: BorderRadius.circular(DS.radiusControl),
          border: Border.all(color: _comboColor(breed), width: 2)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CatFace(breed.id, size: 26),
          const SizedBox(width: DS.spaceXs),
          Expanded(
              child: Text(combo.name,
                  style: TextStyle(
                      color: _comboColor(breed),
                      fontSize: DS.fontHeading,
                      fontWeight: FontWeight.w900))),
          if (breed.id == widget.selectedCat)
            const Text('ĐANG CHƠI',
                style: TextStyle(
                    color: DS.label,
                    fontSize: DS.fontCaption,
                    fontWeight: FontWeight.w800)),
        ]),
        const SizedBox(height: DS.spaceXs),
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
                                  padding: EdgeInsets.symmetric(
                                      horizontal: DS.space2),
                                  child: Icon(Icons.chevron_right_rounded,
                                      color: DS.label, size: 18)),
                            Expanded(flex: i == 2 ? 6 : 5, child: panels[i]),
                          ],
                        ])
                  : Column(children: [
                      for (var i = 0; i < panels.length; i++) ...[
                        if (i > 0) const SizedBox(height: DS.spaceXs),
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
      padding: const EdgeInsets.all(DS.spaceSm),
      decoration: BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(step.attack.color, Colors.black, .32)!,
                Color.lerp(step.attack.color, Colors.black, .5)!
              ]),
          borderRadius: BorderRadius.circular(DS.radiusMd),
          border: Border.all(
              color: Color.lerp(step.attack.color, Colors.black, .55)!)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .18),
                  borderRadius: BorderRadius.circular(DS.radiusSm)),
              child:
                  Center(child: SkillGlyphView(step.attack.glyph, size: 25))),
          const SizedBox(width: DS.spaceXs),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('BƯỚC ${index + 1}',
                    style: const TextStyle(
                        color: Color(0xFFFFE5AE),
                        fontSize: DS.fontCaption,
                        fontWeight: FontWeight.w800)),
                Text(step.attack.label,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: DS.fontButton,
                        fontWeight: FontWeight.w900)),
              ])),
        ]),
        const SizedBox(height: DS.spaceXs),
        Text(step.instruction,
            style: const TextStyle(
                color: Colors.white, fontSize: DS.fontBody, height: 1.3)),
      ]),
    );
  }

  Widget _effectPanel(CatBreed breed) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(DS.spaceSm),
        decoration: BoxDecoration(
            gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFDE79), Color(0xFFFFB64D)]),
            border: Border.all(color: DS.goldEdge, width: 1.2),
            borderRadius: BorderRadius.circular(DS.radiusMd)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [
            Icon(Icons.auto_awesome_rounded, color: DS.goldEdge, size: 16),
            SizedBox(width: DS.spaceXs),
            Expanded(
                child: Text('HIỆU ỨNG COMBO',
                    style: TextStyle(
                        color: DS.ink,
                        fontSize: DS.fontCaption,
                        fontWeight: FontWeight.w900))),
          ]),
          const SizedBox(height: DS.spaceXs),
          Text(breed.homeCombo.effect,
              style: const TextStyle(
                  color: DS.ink, fontSize: DS.fontBody, height: 1.3)),
        ]),
      );
}
