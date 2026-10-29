import 'package:flutter/material.dart';

import '../../collection/fish_species.dart';
import 'fishing_fish_art.dart';

class FishingCatchPopup extends StatelessWidget {
  const FishingCatchPopup(
      {super.key, required this.fish, required this.onNext});

  final FishSpecies fish;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 290),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFFF2F7EE),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF456E5D), width: 3),
                boxShadow: const [
                  BoxShadow(
                      color: Color(0x660E3C35),
                      blurRadius: 18,
                      offset: Offset(0, 8))
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Text('CÂU ĐƯỢC RỒI!',
                      style: TextStyle(
                          color: Color(0xFF294941),
                          fontSize: 19,
                          fontWeight: FontWeight.w900)),
                  const SizedBox(height: 6),
                  SizedBox(
                      width: 150,
                      height: 92,
                      child: CustomPaint(painter: FishingFishArt(fish))),
                  Text(fish.label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Color(0xFF226D62),
                          fontSize: 22,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 3),
                  Text(fish.isJunk ? 'Đồ vật thất lạc' : fish.rarity,
                      style: const TextStyle(
                          color: Color(0xFF65786D), fontSize: 13)),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: onNext,
                      icon: const Icon(Icons.phishing, size: 19),
                      label: const Text('CÂU TIẾP'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF397D70),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8))),
                    ),
                  )
                ]),
              ),
            ),
          ),
        ),
      );
}
