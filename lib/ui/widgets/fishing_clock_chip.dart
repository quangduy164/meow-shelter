import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../fishing/fishing_lighting.dart';
import '../design.dart';

/// In-game time for the map header, e.g. "07:30 · Buổi sáng". The 40-minute
/// day moves 0.6 game minutes per second, so it refreshes every second.
class FishingClockChip extends StatefulWidget {
  const FishingClockChip({super.key});
  @override
  State<FishingClockChip> createState() => _FishingClockChipState();
}

class _FishingClockChipState extends State<FishingClockChip> {
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hour = FishingLighting.gameHour(DateTime.now());
    final day = hour >= 6 && hour < 18;
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
            color: const Color(0xCC2B1B12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: DS.goldEdge, width: 1.5)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(day ? Icons.wb_sunny_rounded : Icons.nightlight_round,
              size: 16,
              color: day ? const Color(0xFFFFD54F) : const Color(0xFFC9D4FF)),
          const SizedBox(width: 5),
          Text(
              '${FishingLighting.clock(hour)} · '
              '${FishingLighting.partOfDay(hour)}',
              style: const TextStyle(
                  color: DS.cream, fontWeight: FontWeight.w800, fontSize: 13)),
        ]));
  }
}
