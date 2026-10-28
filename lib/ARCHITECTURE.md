# Project structure

- `main.dart`: app startup and device orientation.
- `ui/screens/`: Home, Level Select and the Flutter host for Flame.
- `ui/widgets/`: reusable level cards, title plaque and navigation button.
- `fishing/fishing_controller.dart`: fishing phases, bite timing, line tension, reeling progress and saving catches.
- `ui/screens/fishing_screen.dart`: fishing screen layout, ticker, lifecycle and collection dialog.
- `ui/widgets/fishing_controls.dart`: fishing buttons and progress meters.
- `ui/widgets/fishing_painter.dart`: rod, line, float, ripples and catch rendering.
- `ui/widgets/fishing_landscape.dart`: static lake scenery.
- `levels/level_config.dart`: level data model.
- `levels/levels.dart`: playable level definitions (cats and time limit).
- `game/meow_shelter_game.dart`: round orchestration, rescue progress and component wiring.
- `game/components/`: rendered objects and their input handling (cats, beds, pond, fish inventory and HUD).
- `game/cats/`: cat animation states and sprite-sheet loading.
- `game/systems/bait_system.dart`: reusable bait, waiting fish and target selection.
- `game/world/shelter_layout.dart`: bed assets and normalized placement.
- `game/catch_window.dart`: catch and grip timing, independent of rendering.

Add levels in `levels/levels.dart`; change bed placement in `shelter_layout.dart`.
UI does not own fishing rules. The game connects components to the bait system
through callbacks. Cat movement and gesture transitions remain together in
`CatComponent` so their state changes stay coordinated.

Validation: `flutter analyze` and Android builds. Do not add project-local tools or test files.
