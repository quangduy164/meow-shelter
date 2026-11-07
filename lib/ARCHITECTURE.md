# Project structure

## Folders

- `main.dart`: app start, landscape lock, loading saved progress.
- `ui/`: Flutter screens and widgets.
  - `design.dart`: shared colours and button/card styles (`DS`); see
    `DESIGN.md` at the repo root.
  - `screens/`: Home, Level Select, Game (Flame host), Fishing, Return Home,
    Camp.
  - `widgets/`: shared pieces such as `CatSprite` / `CatFace` (all sprite
    cropping), `RoundButton`, the catch guide and result overlays, fishing art.
- `game/cats/`: cat data shared by every mode.
  - `cat_breed.dart`: **single source of truth per breed** — name, colour,
    bed asset, catch rule text, Return Home skill (label, icon, cooldown).
  - `cat_catch_rule.dart`: catch-rule tuning numbers.
  - `cat_animations.dart`, `cat_state.dart`, `cat_dialogue.dart`.
- `game/`: the rescue mode (Flame).
  - `meow_shelter_game.dart`: round flow, rescues, stars.
  - `components/cat_component.dart`: movement, dragging and escapes.
  - `components/cat_catch_behaviour.dart`: per-breed catch rules (part of the
    cat component library).
  - `systems/bait_system.dart`, `catch_window.dart`, `world/`.
- `game/return_home/`: the Return Home mode. Road and biomes, spawner,
  obstacles, cat, scenery, HUD, joystick — one concern per file.
- `fishing/`: fishing controller (rules, timing, saving catches).
- `camp/`: the cat camp.
  - `camp_state.dart`: coins, bought cats (`cat:<breed>` in owned), rescue counts, affection, owned and placed
    decorations, level stars, seen guides. Saved with shared_preferences.
  - `camp_resident.dart`: what camp cats do (wander, play, nap, react).
  - `camp_room_painter.dart`, `camp_decor_painter.dart`: room and item art.
- `levels/`: `level_config.dart` (data model) and `level_goal.dart` (missions), `levels.dart` (chapters,
  levels, stars and unlock rules).
- `collection/`: caught fish.

## Common changes

- **New breed:** add a `CatBreed` entry and its sprite sheets, a bed slot in
  `world/shelter_layout.dart`, its catch rule in `cat_catch_behaviour.dart`
  and its skill effect in `ReturnHomeCat.activateSkill`.
- **New level:** add it to a chapter in `levels/levels.dart` with a new id
  (ids 201+; never reuse one). Give it a twist (`fishLimit`, `waveSize`,
  `movingBeds`, `darkness`) or a `bossType`, plus up to two `LevelGoal`s
  (`levels/level_goal.dart`) for stars 2 and 3.
- **New decoration:** add a `CampDecoration` entry and a case in
  `CampDecorPainter`.
- **New Return Home area:** add a `ReturnHomeBiome` and a scenery painter.

## Rules

- UI does not own game rules; games talk to UI through overlays/callbacks.
- Draw cats in widgets only through `CatSprite` / `CatFace`.
- Saves never crash the app: unreadable data is kept under `<key>_broken`
  and the game starts fresh; failed writes are logged with `debugPrint`.

Validation: `flutter analyze` and Android builds. Do not add project-local
tools or test files.