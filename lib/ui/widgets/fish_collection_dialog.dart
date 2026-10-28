import 'package:flutter/material.dart';
import '../../collection/fish_collection.dart';
import '../../collection/fish_species.dart';
import 'fishing_fish_art.dart';

class FishCollectionDialog extends StatelessWidget {
  const FishCollectionDialog({super.key, required this.collection});
  final FishCollection collection;

  @override
  Widget build(BuildContext context) => Dialog(
        backgroundColor: const Color(0xFFF2F7EE),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: SizedBox(
          width: 620,
          height: MediaQuery.sizeOf(context).height * .75,
          child: Column(children: [
            Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 8, 8),
                child: Row(children: [
                  Expanded(
                      child: Text(
                          'Bộ sưu tập · ${collection.count} cá · ${collection.junkCount} đồ vật',
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF294941)))),
                  IconButton(
                      tooltip: 'Đóng',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close)),
                ])),
            const Divider(height: 1),
            Expanded(
                child: GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 210,
                  mainAxisExtent: 142,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8),
              itemCount: FishSpecies.values.length,
              itemBuilder: (context, index) {
                final fish = FishSpecies.values[index];
                final count = collection.countOf(fish);
                return DecoratedBox(
                  decoration: BoxDecoration(
                      color:
                          count == 0 ? const Color(0xFFE6ECE4) : Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFCEDACB))),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                            width: 90,
                            height: 55,
                            child: CustomPaint(
                                painter:
                                    FishingFishArt(fish, locked: count == 0))),
                        Text(fish.label,
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF294941))),
                        Text(fish.rarity,
                            style: const TextStyle(
                                fontSize: 11, color: Color(0xFF65786D))),
                        const SizedBox(height: 4),
                        Text(count == 0 ? 'Chưa câu được' : '× $count',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: count == 0
                                    ? const Color(0xFF7C8A81)
                                    : const Color(0xFF226D62))),
                      ]),
                );
              },
            )),
          ]),
        ),
      );
}
