import 'package:material_ui/material_ui.dart';

import '../../collection/fish_species.dart';
import 'fishing_fish_art.dart';
import '../design.dart';

class FishingCatchPopup extends StatelessWidget {
  const FishingCatchPopup(
      {super.key,
      required this.fish,
      required this.onNext,
      this.grams,
      this.newRecord = false,
      this.fishScale = 1});

  final FishSpecies fish;
  final VoidCallback onNext;
  final int? grams;
  final bool newRecord;
  final double fishScale;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 290),
            child: DecoratedBox(
              decoration: DS.card,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    DS.spaceLg, DS.spaceLg, DS.spaceLg, DS.spaceLg),
                child: SingleChildScrollView(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Text('CÂU ĐƯỢC RỒI!',
                      style: TextStyle(
                          color: DS.ink,
                          fontSize: DS.fontTitle,
                          fontWeight: FontWeight.w900)),
                  const SizedBox(height: DS.spaceXs),
                  SizedBox(
                      width: 150,
                      height: 92,
                      child: Center(
                          child: SizedBox(
                              width: 150 * (fishScale / 1.5).clamp(.55, 1.0),
                              height: 92 * (fishScale / 1.5).clamp(.55, 1.0),
                              child:
                                  CustomPaint(painter: FishingFishArt(fish))))),
                  Text(fish.label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: DS.goldEdge,
                          fontSize: DS.fontHeading,
                          fontWeight: FontWeight.bold)),
                  if (!fish.isJunk && grams != null) ...[
                    const SizedBox(height: DS.spaceXs),
                    Text(formatFishWeight(grams!),
                        style: const TextStyle(
                            fontSize: DS.fontTitle,
                            fontWeight: FontWeight.w900,
                            color: DS.ink)),
                    if (newRecord)
                      const Padding(
                        padding: EdgeInsets.only(top: DS.spaceXs),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.emoji_events_rounded,
                              color: DS.goldEdge, size: 19),
                          SizedBox(width: DS.spaceXs),
                          Text('KỶ LỤC MỚI!',
                              style: TextStyle(
                                  color: DS.goldEdge,
                                  fontWeight: FontWeight.w900,
                                  fontSize: DS.fontBody)),
                        ]),
                      ),
                  ],
                  const SizedBox(height: DS.spaceXs),
                  Text(fish.isJunk ? 'Đồ vật thất lạc' : fish.rarity,
                      style: const TextStyle(
                          color: DS.soft, fontSize: DS.fontBody)),
                  const SizedBox(height: DS.spaceMd),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: onNext,
                      icon: const Icon(Icons.phishing, size: 19),
                      label: const Text('CÂU TIẾP'),
                      style: DS.primary,
                    ),
                  )
                ])),
              ),
            ),
          ),
        ),
      );
}
