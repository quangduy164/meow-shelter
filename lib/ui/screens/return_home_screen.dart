import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../game/return_home_game.dart';

class ReturnHomeScreen extends StatefulWidget {
  const ReturnHomeScreen({super.key});

  @override
  State<ReturnHomeScreen> createState() => _ReturnHomeScreenState();
}

class _ReturnHomeScreenState extends State<ReturnHomeScreen> {
  late final ReturnHomeGame _game;

  @override
  void initState() {
    super.initState();
    _game = ReturnHomeGame(onExit: () => Navigator.of(context).pop());
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: GameWidget<ReturnHomeGame>(
          game: _game,
          overlayBuilderMap: {
            'exit': (context, game) => SafeArea(
                  child: Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: IconButton.filled(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.home_rounded),
                      ),
                    ),
                  ),
                ),
          },
          initialActiveOverlays: const ['exit'],
        ),
      );
}
