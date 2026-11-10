import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../../game/cat_herd/herd_game.dart';
import '../../game/cat_herd/herd_round.dart';
import '../widgets/herd_map_select.dart';
import '../design.dart';

class HerdScreen extends StatefulWidget {
  const HerdScreen({super.key});
  @override
  State<HerdScreen> createState() => _HerdScreenState();
}

class _HerdScreenState extends State<HerdScreen> with WidgetsBindingObserver {
  final _game = HerdGame();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _game.pausedByApp = state != AppLifecycleState.resumed;
  }

  Widget _card(
          {required String title,
          required String body,
          required String action,
          required VoidCallback onPressed,
          VoidCallback? onMap}) =>
      Material(
        color: DS.scrim,
        child: Center(
            child: SingleChildScrollView(
                child: Container(
          width: 420,
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(20),
          decoration: DS.card,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(title, style: DS.title, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text(body,
                style: const TextStyle(color: DS.ink, height: 1.5),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Wrap(
                spacing: 12,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: DS.secondary,
                      child: const Text('TRANG CHỦ')),
                  if (onMap != null)
                    ElevatedButton(
                        onPressed: onMap,
                        style: DS.secondary,
                        child: const Text('CHỌN MAP')),
                  ElevatedButton(
                      onPressed: onPressed,
                      style: DS.primary,
                      child: Text(action)),
                ]),
          ]),
        ))),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
          body: GameWidget<HerdGame>(
        game: _game,
        initialActiveOverlays: const ['exit'],
        overlayBuilderMap: {
          'exit': (context, game) => SafeArea(
              child: Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                      tooltip: 'Trang chủ',
                      onPressed: () => Navigator.pop(context),
                      style: IconButton.styleFrom(
                          backgroundColor: DS.cream, foregroundColor: DS.ink),
                      icon: const Icon(Icons.home_rounded)))),
          'maps': (context, game) => HerdMapSelect(
              onPlay: game.chooseMap, onHome: () => Navigator.pop(context)),
          'result': (context, game) => _card(
              title: game.round.won ? 'CẢ ĐÀN VỀ NHÀ!' : 'MÈO MỆT RỒI!',
              body:
                  'Đã đưa về ${game.round.delivered}/${HerdRound.target} bạn\nĐiểm: ${game.round.score}\n${game.round.won ? 'Đàn đã về an toàn! Gom đủ 12 bé ở lượt sau để lấy điểm cao nhất.' : 'Ghé các cụm gom đủ 8 bé, rồi dẫn đàn về nhà nhé!'}',
              action: 'CHƠI LẠI',
              onPressed: game.restart,
              onMap: game.showMaps),
        },
      ));
}
