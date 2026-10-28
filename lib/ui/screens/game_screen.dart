import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../../game/meow_shelter_game.dart';
import '../../levels/level_config.dart';
import '../../levels/levels.dart';
import '../widgets/round_button.dart';
import '../../collection/fish_collection.dart';
import 'fishing_screen.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.level});

  final LevelConfig level;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  MeowShelterGame? _game;

  @override
  Widget build(BuildContext context) {
    if (!widget.level.isTutorial && FishCollection.instance.count == 0) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cần cá mồi')),
        body: Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Câu ít nhất 1 cá để mở mồi dùng mãi trong các màn.'),
          const SizedBox(height: 16),
          ElevatedButton(
              onPressed: () async {
                await Navigator.of(context).push(MaterialPageRoute<void>(
                    builder: (_) => const FishingScreen()));
                if (mounted) setState(() {});
              },
              child: const Text('ĐẾN HỒ CÂU')),
        ])),
      );
    }
    final index = gameLevels.indexWhere((level) => level.id == widget.level.id);
    _game ??= MeowShelterGame(
        level: widget.level,
        onNextLevel: index >= 0 && index < gameLevels.length - 1
            ? () => Navigator.of(context).pushReplacement(
                MaterialPageRoute<void>(
                    builder: (_) => GameScreen(level: gameLevels[index + 1])))
            : null);
    return Scaffold(
      body: Stack(
        children: [
          GameWidget(game: _game!),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Align(
                alignment: Alignment.topLeft,
                child: RoundButton(
                  icon: Icons.home_rounded,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
