import 'package:material_ui/material_ui.dart';
import '../../camp/camp_state.dart';
import '../../game/cats/cat_breed.dart';
import '../design.dart';
import 'cat_sprite.dart';
import 'fishing_menu_button.dart';
import 'game_glyphs.dart';
import 'paw_loader.dart';

/// Cat-choice presentation only. Entry/loading/navigation stay owned by the screen.
class FishingCatSelection extends StatelessWidget {
  const FishingCatSelection(
      {super.key,
      required this.loading,
      required this.visitingFriend,
      required this.onSelected,
      required this.onOpenLobby,
      this.error,
      this.lastCat});
  final bool loading, visitingFriend;
  final String? error, lastCat;
  final ValueChanged<String> onSelected;
  final VoidCallback onOpenLobby;

  @override
  Widget build(BuildContext context) => DecoratedBox(
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
              FishingMenuButton(
                  tooltip: 'Về Trang chủ',
                  onPressed: () => Navigator.pop(context),
                  child: const GameGlyphView(GameGlyph.home, size: 22)),
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
            const SizedBox(height: DS.spaceSm),
            Row(children: [
              FishingMenuButton(
                  tooltip: 'Phòng chơi',
                  onPressed: loading ? null : onOpenLobby,
                  child: const Icon(Icons.people_alt_rounded, size: 22)),
              Expanded(
                  child: Center(
                      child: loading
                          ? const PawLoader(size: 32, color: DS.cream)
                          : Text(
                              error ??
                                  (visitingFriend
                                      ? 'Chọn một bé mèo để vào phòng'
                                      : 'Chọn một bé mèo để bắt đầu chuyến đi câu'),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  color: DS.cream, fontSize: DS.fontBody)))),
              const SizedBox(width: 44),
            ]),
            Expanded(
                child: Center(
                    child: SingleChildScrollView(
                        padding:
                            const EdgeInsets.symmetric(vertical: DS.spaceLg),
                        child: _catChoices(onSelected)))),
          ]),
        )),
      );

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
                    onPressed: loading ? null : () => onSelected(breed.id),
                    child: Padding(
                      padding: const EdgeInsets.all(DS.spaceSm),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        CatFace(breed.id, size: 84),
                        const SizedBox(height: DS.spaceSm),
                        Text(CampState.instance.nameOf(breed.id),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        if (breed.id == lastCat)
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
}
