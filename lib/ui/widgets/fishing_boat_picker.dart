import 'dart:math' as math;
import 'package:material_ui/material_ui.dart';
import '../../fishing/fishing_boat.dart';
import '../design.dart';
import 'game_surfaces.dart';
import 'fishing_dialog_kit.dart';
import 'fishing_boats.dart';

/// Boat-choice presentation; the screen owns saving and dialog lifetime.
class FishingBoatPicker extends StatelessWidget {
  const FishingBoatPicker(
      {super.key, required this.selected, required this.onSelected});
  final FishingBoat selected;
  final ValueChanged<FishingBoat> onSelected;
  @override
  Widget build(BuildContext context) => GameDialog(
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
                    selected: boat == selected,
                    onTap: () => onSelected(boat))),
          ]
        ]),
      ]));
}

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
