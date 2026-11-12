import 'package:flutter/material.dart';

import '../../camp/camp_state.dart';
import '../../game/cats/cat_breed.dart';
import 'cat_sprite.dart';
import '../design.dart';

/// Explains how to catch each breed. Shown before a round when it contains a
/// breed the player has not met yet, and on demand from the help button.
class CatGuideOverlay extends StatelessWidget {
  const CatGuideOverlay(
      {super.key, required this.types, required this.onDone, this.onPractice});

  final List<String> types;
  final VoidCallback onDone;

  /// Opens the guided practice round for a breed; hidden when null.
  final void Function(String type)? onPractice;

  /// Breeds of [level] the player still needs to read about.
  static List<String> unseen(Iterable<String> catTypes) => catTypes
      .toSet()
      .where((type) => !CampState.instance.seenGuides.contains(type))
      .toList();

  @override
  Widget build(BuildContext context) => Material(
        color: DS.scrim,
        child: SafeArea(
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 560, maxHeight: 340),
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
              decoration: DS.card,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('CÁCH BẮT MÈO', style: DS.title),
                const SizedBox(height: 8),
                Flexible(
                  child: ListView(shrinkWrap: true, children: [
                    for (final type in types) _row(type),
                  ]),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () async {
                    await CampState.instance.markGuidesSeen(types);
                    onDone();
                  },
                  style: DS.primary,
                  child: const Text('ĐÃ HIỂU',
                      style: TextStyle(fontWeight: FontWeight.w900)),
                ),
              ]),
            ),
          ),
        ),
      );

  Widget _row(String type) {
    final breed = CatBreed.of(type);
    final rule = breed.catchRule;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        CatSprite(type: type, size: 56),
        const SizedBox(width: 10),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${breed.name} · ${rule.trait}',
                style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: DS.fontHeading,
                    color: DS.ink)),
            const SizedBox(height: 2),
            Text(rule.how,
                style: const TextStyle(color: DS.soft, fontSize: DS.fontBody)),
          ]),
        ),
        if (onPractice != null)
          TextButton.icon(
            onPressed: () async {
              await CampState.instance.markGuidesSeen(types);
              onPractice!(type);
            },
            icon: const Icon(Icons.school_rounded, size: 18),
            label: const Text('TẬP'),
            style: TextButton.styleFrom(foregroundColor: DS.goldEdge),
          ),
      ]),
    );
  }
}
