import 'package:flutter/material.dart';

class FishingDistance extends StatelessWidget {
  const FishingDistance({super.key, required this.progress});
  final double progress;

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Khoảng cách còn lại đến bờ',
        value: '${((1 - progress) * 100).round()} phần trăm',
        child: Column(children: [
          const Icon(Icons.landscape_rounded,
              size: 23, color: Color(0xFF395D48)),
          const Text('BỜ',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF253F36))),
          const SizedBox(height: 5),
          Expanded(
              child: Container(
            width: 38,
            decoration: BoxDecoration(
                color: const Color(0xEAF0F7ED),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF688C7C), width: 2)),
            clipBehavior: Clip.antiAlias,
            child: Stack(fit: StackFit.expand, children: [
              FractionallySizedBox(
                  heightFactor: progress,
                  alignment: Alignment.bottomCenter,
                  child: const ColoredBox(color: Color(0x6656B2A2))),
              Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 15, horizontal: 4),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(
                          6,
                          (_) => const Align(
                              alignment: Alignment.centerRight,
                              child: SizedBox(
                                  width: 7,
                                  height: 1,
                                  child:
                                      ColoredBox(color: Color(0x66688C7C))))))),
              Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Align(
                      alignment: Alignment(0, 1 - progress * 2),
                      child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                              color: const Color(0xFF187C83),
                              borderRadius: BorderRadius.circular(6)),
                          child: const Icon(Icons.set_meal_rounded,
                              size: 21, color: Color(0xFFFFE2A0))))),
            ]),
          )),
          const SizedBox(height: 5),
          Text('${((1 - progress) * 100).round()}%',
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF253F36))),
          const Text('CÁCH BỜ',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF253F36))),
        ]),
      );
}
