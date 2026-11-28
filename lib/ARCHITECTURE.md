# Project structure

Map of the code and rules that apply everywhere. Mode details live next to
their code:

- Fishing: `lib/fishing/README.md`
- Online fishing rooms and chat: `lib/online/README.md`
- Lead the Herd: `lib/game/cat_herd/README.md`
- Night shift: `lib/game/night_shift/README.md`
- UI tokens, layout and dialogs: `DESIGN.md`

## Folders

- `main.dart`: app start, landscape lock, loading saved progress, local
  installation ID, background Firebase login.
- `ui/`: Flutter screens and widgets.
  - `design.dart`: colours, fonts (Nunito body, Baloo2 titles/buttons),
    spacing, shapes, motion and the Material theme (`DS`).
  - `responsive.dart`: `UiScaleBox` scales the app from a 375-tall design
    screen (see DESIGN.md › Responsive layout).
  - `screens/`: Home, Level Select, Game (Flame host), Fishing, Adventure,
    Herd, Camp.
  - `widgets/`: shared pieces. `CatSprite` / `CatFace` own all sprite
    cropping. `game_pressable.dart` owns raised/round buttons;
    `game_surfaces.dart` owns panels, `GameDialog`, stats and badges. These
    foundations depend on no game mode.
- `game/cats/`: cat data shared by every mode. `cat_breed.dart` is the
  single source per breed (name, colour, bed, catch rule text, Adventure
  skill, sheet path); `cat_catch_rule.dart` holds catch-rule numbers.
- `game/`: the rescue mode (Flame).
  - `meow_shelter_game.dart`: catching engine, level flow, bait, beds,
    results. `game.night` exists only for infinite levels.
  - `components/`: `cat_component.dart` (movement, dragging, escapes),
    `cat_catch_behaviour.dart` (per-breed rules).
  - `systems/`: bait, catch window and per-chapter systems (below);
    `world/`: maps and their painters.
  - `night_shift/`: independent night rules (own README).
- `game/adventure/`: Adventure mode, one concern per file.
  - `adventure_game.dart` is the only state/lifecycle owner. Behaviour parts:
    `adventure_targeting`, `adventure_combat`, `adventure_boss_fight`,
    `adventure_run_rules`. Keep the existing update order.
  - `adventure_dragon.dart` (boss AI, shared tail geometry) with art parts
    `adventure_dragon_*_art.dart`; `adventure_dragon_attacks.dart` owns
    telegraphed attacks. Collision and art share the same geometry.
  - `adventure_skills.dart`: effect library and tuning; components are split
    by family (`adventure_*_effects.dart`, projectiles, aim indicator).
  - Parts never add a second game instance, ticker, cache or lifecycle owner.
  - `ui/screens/adventure_screen.dart` owns entry, navigation and pause; the
    skill controls, combo help and victory overlay are separate widgets.
- `game/cat_herd/`: Lead the Herd (own README).
- `fishing/`: fishing rules and the river world (own README).
- `online/`: Firebase session, fishing rooms, presence, chat (own README).
- `camp/`: the cat camp. `camp_state.dart` saves coins, owned cats
  (`cat:<breed>`), cat nicknames, rescue counts, affection, decorations,
  level stars, seen guides and paid legendary bait. `camp_resident.dart`
  (cat behaviour), `camp_room_painter.dart`, `camp_decor_painter.dart`.
- `collection/`: caught fish. `FishCollection` keeps permanent journal
  counts and record grams (`fish_collection_journal_v2`) and a separate
  basket (`fish_basket_v1`). Feeding a camp cat removes a fish from the
  basket only and adds `FishSpecies.affection`. Lost items are not food.
- `levels/`: `level_config.dart`, `level_goal.dart` (missions) and
  `levels.dart` (chapters, stars, unlock rules).
- `audio/game_audio.dart`: all music, effects and ambience.

## Rescue chapters

Each chapter adds one twist through a `ShelterMap` field or `LevelConfig`
option, a system and a painter in `world/`:

- Yard (ch. 1, levels 202-203): `rack_system.dart` holds 5 fish and drops
  one as free bait every 8-11 s. The orange boss naps on a straw mat
  (`napMats`) and is catchable only asleep. Level 201 is the plain tutorial.
- Garden (ch. 2): `bush_system.dart` hides Himalayas in bushes until quiet
  (`quietSeconds`); noise makes them bolt back (`LevelGoal.quiet`).
- Kitchen (ch. 3): `LevelConfig.dishes` adds fish/shrimp/salmon slots; a
  Scottish only accepts its current `craving` (`LevelGoal.rightDish`).
- Playroom (ch. 4): `LevelConfig.toys` adds rolling yarn; the Calico boss
  counts only taps on its beat ring.
- Attic (ch. 5): `moon_system.dart` drifts moonbeams; black cats take fish
  only where lit. The boss jumps to dark spots, showing paw prints first.
- Storm (ch. 6): `LevelConfig.flood` creates `storm_system.dart` (rising
  water, rescue truck every 24 s). `bossParade` makes every cat a boss.

## Common changes

- **New breed:** `CatBreed` entry and sprite sheets, a bed slot in
  `world/shelter_layout.dart`, a catch rule in `cat_catch_behaviour.dart`,
  a skill in `AdventureCat.activateSkill`.
- **New level:** add it to a chapter in `levels/levels.dart` with a new id
  (201+, never reuse). Give it a twist or `bossType` and up to two
  `LevelGoal`s for stars 2 and 3.
- **New decoration:** `CampDecoration` entry plus a case in
  `CampDecorPainter`.
- **New Adventure area:** an `AdventureBiome` and a scenery painter.
- **New fishing region, place, boat or rod:** see `lib/fishing/README.md`.

## Rules

- UI does not own game rules; games talk to UI through overlays/callbacks.
- Draw cats in widgets only through `CatSprite` / `CatFace`.
- Rescue entry uses `requiredCatchTutorial`: unfamiliar breeds open practice
  first. Only a won practice or round counts as familiarity; reading a guide
  does not.
- Saves never crash the app: unreadable data is kept under `<key>_broken`
  and the game starts fresh; failed writes are logged with `debugPrint`.
- Coins and the item they pay for are saved together, with rollback when the
  save fails. Quest rewards use stable `quest-reward:<name>` keys.
- New enum values (fish, boats, rods) are appended so saved indices and names
  stay valid.
- Releasing resources:
  - A component caching a `ui.Picture`/`ui.Image` disposes it in
    `onRemove` and before re-recording.
  - Never build a `TextPainter` in `render`/`paint`. Use `TextCache`
    (rescue/camp) or `herdLabel` (herd); callers never dispose what they get.
    A label kept in a field is disposed when replaced and in `onRemove`.
  - Sprite sheets live in Flame's shared image cache: never call
    `game.images.clearCache()` or a game's `dispose` on screen exit.
  - Widgets dispose controllers and timers and remove every listener or
    observer they add.
  - Sounds go through `GameAudio`; no `AudioPlayer` per event, no loops a
    screen does not stop.
- `CatSprite` keeps the previous image and its crop until a new sheet loads,
  ignores late deliveries and never evicts shared caches. Decode sizes use
  64-pixel buckets shared with `precacheActions`.
- Input dialogs follow the `GameDialog` keyboard contract in DESIGN.md; keep
  focused fields mounted and never switch the scroll wrapper on keyboard state.

Validation: `flutter analyze lib` and Android builds. Use temporary tests
outside the repo; do not add project-local tools or test files.

## Assets

- Cat sheets, stickers and previews are lossless WebP. Keep dimensions,
  frame order, transparent padding and alpha exactly (256-pixel animation
  cells, 192-pixel sticker cells). `CatBreed.sheet` is the path source; Flame
  caches must use the same extension. Never ship PNG and WebP side by side.
- Keep originals outside the repo before replacing media and compare decoded
  RGBA after conversion. Smaller files do not reduce decoded memory.
- Music: MP3 44.1 kHz stereo 96 kbps. Short effects stay PCM WAV for low
  latency; ambience is Vorbis OGG. Keep loop lengths and attribution.
- Fonts in `assets/fonts/` are static instances subset to Latin and
  Vietnamese; keep the OFL licence files next to them.
