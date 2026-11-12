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
- `game/cat_herd/`: Lead the Herd mode, independent of rescue and Return Home.
  - `herd_round.dart`: deterministic simulation when seeded: recruitment,
    distance-sampled leader trail, followers, patrol hits, scattering,
    delivery, score and win/loss. `reset` starts a fresh round; `update`
    consumes a normalized direction and a small time step.
  - `herd_game.dart`: Flame lifecycle, shared joystick adapter, sprite cache,
    fixed substeps and overlays. It does not write camp progress.
  - `herd_navigation.dart`: cached visibility graph at expanded obstacle corners.
    Followers take a shortest clear detour to their assigned leader-trail point,
    even after older trail samples expire or hazards push them aside. Exact
    segment/rectangle checks share the same 15-unit clearance as collision;
    the graph rebuilds when the map or viewport changes.
  - `herd_map.dart`: the four exclusive maps (market/desert/snow/playground), normalized
    walls and terrain patches, traffic clock and player-facing rule text.
  - `herd_route.dart`: suggested paths, optional branch and four group
    anchors per map. Paths guide placement; they do not constrain movement.
  - `herd_route_painter.dart`: optional footprints and group counters. The whole
    field is open except for the map's visible solid obstacles.
  - `herd_map_painter.dart`: map-specific scenery; reads the same rectangles
    as collision/terrain rules. Never imports rescue-mode maps.
  - `herd_ball.dart`: bouncing-ball trajectory and visual bounce height. The
    simulation uses its ground footprint for contact, with a one-second
    per-cat cooldown; pushes preserve followers and never remove lives.
  - Playground walls are wooden blocks in `HerdMap.playground`; the first
    cluster is inside an open U. `HerdPatrol.loop` drives both elliptical track
    art and car collision, with two cars guarding the second cluster.
  - Market is a stealth map. Its two scooters keep `trafficLight=true`; there
    are no delivery carts. `herd_market.dart` holds the vendor watch/rest cycle
    (`HerdVendor`) and lantern on/off cycle (`HerdLanterns`). Vendor i watches
    only lantern zone i: a leader or follower inside a lit zone, inside the cone,
    while that vendor watches, is scattered from that point. No life is lost; a
    2.5 s cooldown prevents repeated shouts. `herd_market_painter.dart` draws the
    zone-clipped cones and vendors under cats, and dark zones over cats.
  - Desert is a heat-and-wind map; it has no moving hazards. `herd_desert.dart`
    holds `HerdHeat` (followers heat in sun, tail cats slightly faster, cool in
    `HerdMap.shade`) and `HerdSandstorm` (2 s warning, 4.5 s gust every 16 s,
    alternating direction). An overheated follower leaves the chain alone and
    rests for 3 s before it can rejoin. The gust is added in `_groundStep` unless
    the cat is within `shelterReach` downwind of a wall. No lives are lost here.
    Soft sand, slopes and landing wobble remain. `herd_desert_painter.dart`
    draws heat bars, steam and the storm over the cats.
  - `herd_snow.dart` / `herd_snow_painter.dart`: winter has no moving hazards
    and never costs lives. `HerdMap.thinIce` sheets crack while more than
    `HerdThinIce.safeLoad` followers stand on them (snowPads inside are safe,
    including the island cluster) and heal when the load is light. On break,
    those followers leave the chain, land on the nearest solid shore and shiver
    (`HerdCat.chill`, 3 s) before they can rejoin. `HerdMap.chutes` are one-way
    lanes: `_groundStep` overrides steering with the lane direction, so they
    are shortcuts that cannot be entered backwards. Spawns avoid thin ice and
    chutes via `_onHazardLane`. Dry `snowPads` still override ice friction.
  - `HerdMap.tutorial` is excluded from the four-region picker. It has no
    damaging hazards, twelve cats in four clusters, three slalom rocks and a
    three-step move/recruit/return guide driven by
    `HerdRound.tutorialStep`. HUD and pulsing targets reflect the current step.
    `herd_hud.dart` draws only lives at the top and a transparent top-centred tutorial
    caption without step labels or progress counters; Home uses the shared RoundButton.
    `HerdScreen` reads `CampState.herdTutorialDone` at entry; the game reports
    a win through `onTutorialCompleted`. Only a completed tutorial writes the
    versioned mode key into the existing saved `seenGuides` set. Aborted runs
    start the tutorial again; later visits open the region picker directly.
    The picker also offers Tập chơi for replay without resetting saved progress.
  - `herd_scene.dart`: home and map-specific hazards; no rule mutations.
  - `ui/screens/herd_screen.dart`: result/replay and app lifecycle.
  - `ui/widgets/herd_map_select.dart`: horizontally scrolling region cards.
    Preview art reuses `paintHerdField`; tapping a card starts immediately.
  - Debug tuning starts in `HerdRound`: `target`, `spacing`, patrol setup,
    `requiredCats` (8 to open the home), movement speed, pickup/hit radii and
    the score formula. Spawns use four authored anchors with a jittered
    three-cat formation, rejecting walls, overlap and traffic lanes; keep all
    anchors reachable and off traffic when adding a route. Viewport resize scales positions in place through `HerdRound.resize`; repeated
    layout notifications preserve the run, score and result overlay.
- `fishing/`: fishing controller (rules, timing, saving catches).
- `camp/`: the cat camp.
  - `camp_state.dart`: coins, bought cats (`cat:<breed>` in owned), rescue counts, affection, owned and placed
    decorations, level stars, seen guides. Saved with shared_preferences.
  - `camp_resident.dart`: what camp cats do (wander, play, nap, react).
  - `camp_room_painter.dart`, `camp_decor_painter.dart`: room and item art.
- `ui/responsive.dart`: `UiScaleBox` scales the whole app from design units
  (375-tall reference screen) to the real screen; see DESIGN.md › Responsive
  layout.
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