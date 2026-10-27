import 'dart:async';
import 'package:flutter/material.dart';
import '../../collection/fish_collection.dart';
import '../widgets/fishing_landscape.dart';

class FishingScreen extends StatefulWidget {
  const FishingScreen({super.key});
  @override
  State<FishingScreen> createState() => _FishingScreenState();
}

class _FishingScreenState extends State<FishingScreen> {
  Timer? _timer;
  bool _busy = false;
  String _message = 'Chạm hồ để thả câu';
  bool _collectionOpen = false;
  void _fish() {
    if (_busy || _collectionOpen) return;
    setState(() {
      _busy = true;
      _message = 'Đang chờ cá cắn câu…';
    });
    _timer = Timer(const Duration(milliseconds: 1200), () async {
      try {
        await FishCollection.instance.catchFish();
        if (!mounted) return;
        setState(() {
          _busy = false;
          _message = 'Câu được 1 cá! Đã lưu vào bộ sưu tập.';
        });
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _busy = false;
          _message = 'Chưa lưu được cá. Hãy thử lại.';
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _openCollection() async {
    setState(() => _collectionOpen = true);
    await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
              backgroundColor: const Color(0xFFFFF3D8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
              title: const Text('Bộ sưu tập cá'),
              content: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.set_meal_rounded,
                    size: 64, color: Color(0xFF388EAD)),
                const SizedBox(height: 12),
                Text('Cá đã câu: ${FishCollection.instance.count}',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                const Text(
                    'Mang cá vào màn để dụ mèo. Dùng nhiều lần, không bị mất.',
                    textAlign: TextAlign.center),
              ]),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('ĐÓNG'))
              ],
            ));
    if (mounted) setState(() => _collectionOpen = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Stack(fit: StackFit.expand, children: [
          const CustomPaint(painter: FishingLandscape()),
          LayoutBuilder(
              builder: (context, constraints) => Stack(children: [
                    Positioned(
                      left: constraints.maxWidth * .214,
                      top: constraints.maxHeight * (293 / 600),
                      width: constraints.maxWidth * .572,
                      height: constraints.maxHeight * (212 / 600),
                      child: ClipOval(
                          child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _busy ? null : _fish,
                          child: Center(
                              child: _busy
                                  ? const CircularProgressIndicator(
                                      color: Colors.white)
                                  : const Icon(Icons.phishing_rounded,
                                      size: 38, color: Colors.white)),
                        ),
                      )),
                    ),
                  ])),
          SafeArea(
              child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(children: [
              Row(children: [
                IconButton.filled(
                    tooltip: 'Về Trang chủ',
                    style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFFFFD477),
                        foregroundColor: const Color(0xFF603312)),
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded)),
                const SizedBox(width: 10),
                const Expanded(
                    child: Text('HỒ CÂU',
                        style: TextStyle(
                            color: Color(0xFF304E40),
                            fontSize: 22,
                            fontWeight: FontWeight.w900))),
                FilledButton.icon(
                    onPressed: _busy ? null : _openCollection,
                    style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFFFD477),
                        foregroundColor: const Color(0xFF603312)),
                    icon: const Icon(Icons.inventory_2_outlined),
                    label: const Text('Bộ sưu tập')),
              ]),
              const Spacer(),
              IgnorePointer(
                  child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                    color: const Color(0xEFFFF3D8),
                    borderRadius: BorderRadius.circular(16)),
                child: Text(_message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Color(0xFF304E40), fontWeight: FontWeight.w600)),
              )),
            ]),
          )),
        ]),
      );
}
