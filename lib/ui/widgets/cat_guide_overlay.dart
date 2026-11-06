import 'package:flutter/material.dart';

import '../../camp/camp_state.dart';
import '../../game/cats/cat_catch_rule.dart';

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
        color: const Color(0x99302010),
        child: SafeArea(
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 560, maxHeight: 340),
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3D8),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF9A6028), width: 3),
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('CÁCH BẮT MÈO',
                    style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF603312))),
                const SizedBox(height: 8),
                Flexible(
                  child: ListView(shrinkWrap: true, children: [
                    for (final type in types) _row(type),
                  ]),
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: () async {
                    await CampState.instance.markGuidesSeen(types);
                    onDone();
                  },
                  style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFE0703F)),
                  child: const Text('ĐÃ HIỂU',
                      style: TextStyle(fontWeight: FontWeight.w900)),
                ),
              ]),
            ),
          ),
        ),
      );

  Widget _row(String type) {
    final rule = CatCatchRule.all[type]!;
    final folder = type[0].toUpperCase() + type.substring(1);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          width: 56,
          height: 56,
          child: ClipRect(
            child: OverflowBox(
              maxWidth: 56 * 6,
              maxHeight: 56,
              alignment: Alignment.centerLeft,
              child: Image.asset('assets/images/Cat/$folder/cat-$type-idle.png',
                  width: 56 * 6, height: 56, fit: BoxFit.fill),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${CatCatchRule.names[type]} · ${rule.trait}',
                style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    color: Color(0xFF603312))),
            const SizedBox(height: 2),
            Text(rule.how,
                style: const TextStyle(color: Color(0xFF6E5034), fontSize: 13)),
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
            style:
                TextButton.styleFrom(foregroundColor: const Color(0xFFE0703F)),
          ),
      ]),
    );
  }
}
