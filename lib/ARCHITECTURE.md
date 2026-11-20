# Project structure

## Folders

- `main.dart`: app start, landscape lock, loading saved progress.
- `ui/`: Flutter screens and widgets.
  - `design.dart`: colours, typography, spacing, shapes, motion and Material
    theme (`DS`); see
    `DESIGN.md` at the repo root.
  - `screens/`: Home, Level Select, Game (Flame host), Fishing, Adventure,
    Camp.
  - `widgets/`: shared pieces such as `CatSprite` / `CatFace` (all sprite
    cropping), `RoundButton`, the catch guide and result overlays, fishing art.
    `game_pressable.dart` owns raised and round action input/feedback;
    `game_surfaces.dart` owns panels, modal shells/headers, stats and badges.
    These foundations depend on no game mode; screens supply values/callbacks.
- `game/cats/`: cat data shared by every mode.
  - `cat_breed.dart`: **single source of truth per breed** — name, colour,
    bed asset, catch rule text, Adventure skill (label, icon, cooldown).
  - `cat_catch_rule.dart`: catch-rule tuning numbers.
  - `cat_animations.dart`, `cat_state.dart`, `cat_dialogue.dart`.
- `game/`: the rescue mode (Flame).
  - `meow_shelter_game.dart`: shared cat-catching engine, normal-level flow,
    bait, beds and results. The night-shift controller is `game.night` and
    is created only for infinite levels. `Random` can be injected for debugging.
  - `night_shift/`: the independent night rules (see its README).
    - `night_game.dart`: night lifecycle, objectives, card/shop transitions;
      `NightPhase` is the current phase to inspect in the debugger.
    - `night_run.dart`: run progress, silver wallet, purchases and card bonuses.
    - `night_cards.dart`, `night_relics.dart`, `night_helpers.dart`: definitions.
    - `night_relic_effects.dart`, `night_helper_effects.dart`: effect triggers.
    - `night_scene.dart`: map contract and factory; new maps implement this.
    - `maps/moonlit_yard.dart`: lantern/moon/cloud simulation;
      `moonlit_yard_painter.dart`: artwork/components;
      `moonlit_yard_scene.dart`: mounts the scene and handles its input.
    - `maps/night_market.dart`, `night_market_scene.dart`,
      `night_market_painter.dart`: market noise/traffic, scene input and art.
      `moonlight.dart` / `moonlight_art.dart` are shared moon/cloud rules and art.
      Night maps rotate; map-specific cards are offered for the next map.
    UI is split into `night_setup_overlay.dart`, `night_cards_overlay.dart`,
    `night_skill_bar.dart`, `night_info_overlay.dart`, `night_relic_shop.dart`.
    Relic icons are shared through `night_relic_icon.dart`; stall artwork is
    separate in `night_relic_stall_painter.dart`. No panel imports another
    panel just to get artwork.
  - `components/cat_component.dart`: movement, dragging and escapes.
  - `components/cat_catch_behaviour.dart`: per-breed catch rules (part of the
    cat component library).
  - `systems/bait_system.dart`, `catch_window.dart`, `world/`.
- `game/adventure/`: the Adventure mode. Road and biomes, spawner,
  obstacles, cat, scenery, HUD, joystick — one concern per file.
- `game/cat_herd/`: Lead the Herd mode, independent of rescue and Adventure.
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
  - `herd_traits.dart` / `herd_trait_painter.dart`: special cats appear only
    from map 5 (Nhà bà ngoại). `HerdMap.specials[group][i]` sets
    `HerdCat.trait`. Chubby: slower follower, leader x0.9, weight 2 on thin
    ice, 1.3x desert heat, jammed by `HerdMap.catFlaps` (pops back, leaves the
    herd, `stuck` bubble). Curious: leaves after 6-11 s for a butterfly, or at
    once within `HerdLure.radius` of a `HerdMap.lures` point (`lured`). Sleepy:
    leader stays ~1 s (`wake`) or the cuckoo wakes it. Golden: +30 score.
  - `herd_grandma.dart` / `herd_grandma_painter.dart`: Nhà bà ngoại layout
    (`HerdHouse`), `HerdCuckoo` (rings every 15 s, wakes sleepy cats in
    `HerdMap.cuckooRoom`) and `HerdRobot` (rectangular `HerdMap.robots` loop;
    bumping scatters, never costs a life).
  - `herd_station.dart` / `herd_station_painter.dart`: Nhà ga tàu nhỏ (map 6).
    `HerdMap.track` is solid except inside `HerdTrain.rect` while its doors
    are open, or for whoever is already aboard (`HerdRound._solid`). The
    train (14 s cycle, `HerdTrain.offset`) stops 4 s at Ga Tây then Ga Đông;
    `_carryTrain` moves riders with it. On departure `_depart` puts riders
    off unless the leader rides from the west stop, and drops followers on a
    different side (`_zone`) than the leader; Ga Đông is the end of the line.
    The horn sends Bé Nhát Gan (`HerdTrait.shy`) within `HerdShy.hearing`
    to the nearest same-side `HerdMap.hideSpots`; standing beside it for
    `coaxSeconds` brings it out, then it stays calm for `calmSeconds`.
    Intro cards are keyed by `HerdMap.introKey` (`HerdTraitIntro`).
  - `herd_farm.dart` / `herd_farm_painter.dart`: Nông trại bác Ba (map 7).
    `HerdMap.pens` gates are solid (`_solid`) unless their plate is pressed,
    someone stands in the gap, or a follower is still inside the pen. The
    first follower over a free plate sits on it (`HerdCat.plate`); heavy
    plates take only Bé Mập. A sitter rejoins once the leader has left and
    come back (`plateReady`), then the plate rests `HerdPlate.restSeconds`.
    `HerdMap.geese` flocks scatter the herd without costing lives. Bé Hay
    Dỗi (`HerdTrait.sulky`) never holds plates; whenever it drops out of the
    chain it sulks, backs away from the leader and is coaxed by staying close.
  - Rendering cost: `renderHerdBackground` rasterises `paintHerdMapBase` plus
    the footprints once per map/viewport (device pixel ratio, capped at 3)
    into a `ui.Image`; frames draw that image, then only motion layers.
    Base painters must not read round state. Per-frame text goes through
    `herdLabel` (`herd_text_cache.dart`), thin-ice cracks are cached per
    sheet, and lantern darkness uses stacked rects instead of a blur filter.
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
- `fishing/`: fishing rules and the river exploration scene.
  - `fishing_river.dart`: a continuous 5400 x 2200 world with three 1800-unit
    stretches. One shared centerline and width define both painted banks and
    movement limits. Click-to-row paths follow bends without cutting over land;
    screen/world transforms share the camera, which follows smoothly and clamps
    to all four world edges. The viewport stays 600 world units high, so the
    taller world scrolls vertically instead of shrinking the boat and artwork.
    Resizing preserves boat position and its destination. New trips start
    moored beside the first near-bank dock (`startDockX`), with no auto-rowing.
  - `ui/widgets/fishing_river_art.dart`: detailed village/flower banks blend into
    bamboo/rock and rice-field banks; props use seeded world coordinates.
    `fishing_coast_art.dart` adds the estuary/beach, palms, lighthouse and islands.
    `fishing_river_details.dart` caches mossy rocks and submerged coral. Visible
    lotus pads, vegetable rafts and driftwood bob/rotate on the animated surface;
    duck families and fish schools flee the boat, while gulls fly overhead.
    `river_props.dart` owns one seeded layout for artwork, solid rock clearance,
    buoyant spring/damped props, contact ripples and wildlife avoidance. Floating
    props yield to the hull and slow it gently, without damaging the boat.
    `river_navigation.dart` runs A* only when a click's lane route crosses rocks;
    exact segment/circle checks and sampled bank edges keep detours navigable.
    Clicking a rock resolves to clear water, and fight steering slides off rocks
    without triggering the bank-hit penalty. These objects live only in the round. Three smooth `FishingRiver.coves` extend the
    banks into a lotus inlet, bamboo backwater and coastal lagoon. Geometry,
    rendering, water taps, casts and lane-based routes use those same bounds.
    Clusters leave the main channel open. Mossy water rocks are solid; coral is
    submerged scenery. Floating props do not block click-to-row routes.
    `coastBlend` widens the shared channel into open sea from x=3360..4080.
    Chunk clips disable antialiasing so fractional camera offsets do not expose seams.
  - `fishing_river_scene.dart`: owns and disposes three cached background Pictures,
    draws only visible stretches, then animated water, boat hull and front rim.
    `FishingScreen` first shows owned cats; selecting one starts the ticker and
    mounts the river. Leaving this picker returns home. Only owned cats appear,
    including custom camp names; there is no cat-change button during play.
    `FishingScreen` draws the selected owned cat through `CatSprite`, handles
    water taps and pauses for dialogs/app backgrounding. Taps only choose a
    rowing destination; background fish are ambient scenery without target rings.
    `fishing_activity.dart` schedules short-lived splash/bubble/large-shadow
    sightings in world time. `fishing_activity_art.dart` draws them without
    target circles or labels. The rod auto-aims at a nearby sighting (within 330
    world units; very close sightings keep a normal-length cast), consuming its opportunity once even if the cast is canceled.
    At active water, rare-species weights are x3 and junk weights x0.3 within
    the existing regional pool. Normal water remains fishable. Scrolling does
    not reset sightings; first-catch help still overrides the species roll.
  - `FishingController` owns the river round and casting/reeling/save phases.
    The bottom-right rod button calls `castHere`, stops rowing and casts from
    the current boat position. Any valid water point can be fished. Tapping a new
    destination during fishing stows the rod before rowing; saving/results finish first. Fish pull the boat along
    the river; swipes steer, banks constrain movement and contact has a cooldown.
    `FishingPainter` receives positions through the same camera transform as
    the boat and draws the attached rod, line, float and tension gauge.
    `fishing_oar_art.dart` shares the entry/power/recovery pose between the cat,
    wooden paddle and water splashes. The paddle parks on the rim during fishing;
    rod artwork uses the river's world scale, extends ahead of the cat and draws
    forepaws to the grip. The tension bar follows the float, flips below it near the top HUD, and
    pulses at tension >= .82 together with a red line. It shows only colors,
    a sweet-zone bracket and a needle, without labels or move instructions.
    `fishing_fight.dart` is the shared per-species fight timeline for rules and art:
    catfish warns with bubbles before diving, mackerel warns before a dash, puffer
    warns before inflation (no reel progress, higher strain if pulled), koi's
    vertical loops reward counter-steering, carp keeps a steady load. Rest windows
    increase reel rate. Bursts start only after a warning; timelines reset at hook.
    `fishing_fight_art.dart` draws the matching bubbles, body inflation, dash wakes
    and koi steering arrows. Fish behavior is conveyed visually, without advance
    text instructions in the HUD or the float's tension bar.
  - `FishingRiver.rollFish` owns regional weights: village (perch, tilapia,
    carp, rare goldfish), bamboo (catfish, koi, very rare catMew), and sea
    (sardine, mackerel, clownfish, pufferfish), plus lost items. Pools blend across
    x=1560..2040 and x=3360..3840; night boosts nocturnal fish. A fish is rolled
    at the boat position when casting starts, so crossing regions while reeling never
    changes the catch. Catches use the existing journal/basket and camp coin
    save. First-catch help uses `mode:fishing:boat:v1` in saved seen guides.
    `FishSpecies.weightRange` and `rollGrams` set a per-species cubic size roll;
    grams are fixed at casting, independently of species rarity. Relative weight
    scales fish artwork and adds at most 15% pull/boat speed; it does not extend
    the fight timer. First-catch help keeps the original force. The result popup
    shows kilograms and the new-record badge only after saving. Retry flags keep
    the measured catch and coin award from being applied twice.
- `camp/`: the cat camp.
  - `camp_state.dart`: coins, bought cats (`cat:<breed>` in owned), optional
    `catNames` by breed (fallback to breed name), rescue counts, affection, owned and placed
    decorations, level stars, seen guides. Saved with shared_preferences.
  - `camp_resident.dart`: what camp cats do (wander, play, nap, react).
  - `camp_room_painter.dart`, `camp_decor_painter.dart`: room and item art.
- `ui/responsive.dart`: `UiScaleBox` scales the whole app from design units
  (375-tall reference screen) to the real screen; see DESIGN.md › Responsive
  layout.
- `levels/`: `level_config.dart` (data model) and `level_goal.dart` (missions), `levels.dart` (chapters,
  levels, stars and unlock rules).
- `collection/`: caught fish. `FishCollection` keeps permanent journal counts
  and a separate basket (`fish_basket_v1`) of edible fish. Camp "GIỎ CÁ":
  drag a fish (upward; sideways scrolls) onto a cat; it leaves the basket (never the journal) and adds
  `FishSpecies.affection` (2 common up to 10 legendary). Lost items are not
  food. Saves from before the basket start with everything caught so far.
  Counts and heaviest whole grams commit atomically in `fish_collection_journal_v2`.
  Missing v2 imports the legacy species counts without inventing old weights;
  the basket retains its existing key. Invalid weight records are backed up and
  discarded while valid counts are preserved. Feeding never alters best weights.
  The journal detail panel shows the species record, or "Chưa cân" for old catches.
  The journal groups fish by `FishSpecies.habitat` in river/sea travel order,
  then rarity within each group. Lost items keep their own tab. Habitat and
  the real nocturnal bonus are shown in details; display order never rewrites saves.

## Common changes

- **New breed:** add a `CatBreed` entry and its sprite sheets, a bed slot in
  `world/shelter_layout.dart`, its catch rule in `cat_catch_behaviour.dart`
  and its skill effect in `AdventureCat.activateSkill`.
- **New level:** add it to a chapter in `levels/levels.dart` with a new id
  (ids 201+; never reuse one). Give it a twist (`fishLimit`, `waveSize`,
  `movingBeds`, `darkness`) or a `bossType`, plus up to two `LevelGoal`s
  (`levels/level_goal.dart`) for stars 2 and 3.
- **Yard rack (chapter 1, levels 202-203):** `ShelterMap.yard` has a `rack`;
  `systems/rack_system.dart` holds only 5 fish; it shakes one, then drops it
  as free bait every 8-11 s. The orange boss may eat its last fish anywhere,
  then walks to the nearest `napMats` straw mat (`CatComponent.napSpot`) and
  only becomes catchable once asleep there; the mats glow from its last fish
  until it naps.
  Level 201 stays the plain guided tutorial. Art: `world/yard_painter.dart`.
- **Garden bushes (chapter 2):** `ShelterMap.hedge` lists bush centres;
  `systems/bush_system.dart` hides every Himalaya in one (`hideInCover`)
  until it has `quietSeconds` without noise near its bush. Noise = fish
  dropped, a carried cat passing, or a startle nearby; an unfed Himalaya out
  in the open bolts back (`RoundStats.retreats`, `LevelGoal.quiet`). The boss
  sneaks from bush to bush until fish lures it; `CatComponent.ignoresBait`
  blocks bait while a cat runs for cover. Art: `world/hedge_garden_painter.dart`.
- **Attic moonlight (chapter 5):** `ShelterMap.attic` has `moonbeams`, so
  the round is dark. `systems/moon_system.dart` drifts each beam and covers it
  with a cloud every 13 s; `cutLight` erases the pools from the darkness layer.
  Black cats take fish only where `MoonSystem.lit` (`CatComponent.moonlit`)
  and are not lit up outside moonlight unless busy. The black boss jumps to a
  dark spot every 7 s when idle, showing paw prints toward it first.
  Art: `world/attic_painter.dart`.
- **Playroom yarn (chapter 4):** `LevelConfig.toys` adds a free `Dish.yarn`
  slot. Yarn rolls (`BaitSystem` velocity, bounces off map obstacles) and is
  only claimed once it stops. Calico accepts it from anywhere and becomes
  ready; any other cat within `CatCatchRule.yarnPull` may claim it first and
  bats it away (`onKickToy`, `RoundStats.distractions`). The Calico boss only
  counts taps on its beat ring (`beatPhase`); off-beat taps reset it and knock
  two yarn balls loose (`onTantrum`, `RoundStats.offBeats`). Art:
  `world/playroom_painter.dart`.
- **Storm finale (chapter 6):** `LevelConfig.flood` > 0 creates a
  `systems/storm_system.dart` StormSystem: water rises from the bottom to
  `flood` over 60 % of the time limit (cats in it move at .55, no fish can be
  dropped in it), a bed whose middle is under water stops accepting cats,
  and a rescue truck parks on the road every 24 s for 10.5 s and accepts any
  cat (`StormSystem.onTruck`). `StormLayer`s draw water/truck under the cats
  and rain/flood marks above them. `LevelConfig.bossParade` makes every cat a
  boss and, with `waveSize: 1`, they arrive one by one with their hint.
  Art: `world/storm_station_painter.dart`.
- **Kitchen dishes (chapter 3):** `LevelConfig.dishes` gives the tray three
  slots (`cats/dish.dart`: fish, shrimp, salmon); `BaitSystem` carries the
  dish with each bait. A Scottish gets a `menu` (2 courses, the boss 3 and it
  changes its mind once) and `acceptsBait` only takes its current `craving`.
  Serving the wrong dish to the closest hungry Scottish counts as
  `RoundStats.wrongDishes` (`LevelGoal.rightDish`). Map: `ShelterMap.kitchen`
  drawn by `world/kitchen_painter.dart`.
- **New decoration:** add a `CampDecoration` entry and a case in
  `CampDecorPainter`.
- **New Adventure area:** add a `AdventureBiome` and a scenery painter.

## Rules

- UI does not own game rules; games talk to UI through overlays/callbacks.
- Rescue entry uses `requiredCatchTutorial`: unfamiliar breeds open practice
  before the requested round. Winning practice records its existing level stars;
  Continue rechecks remaining breeds, then opens the requested round. Closing
  unfinished practice does not mark it complete. Previously won rounds also
  count as familiarity for older saves; merely reading a guide does not.
- Draw cats in widgets only through `CatSprite` / `CatFace`.
- Saves never crash the app: unreadable data is kept under `<key>_broken`
  and the game starts fresh; failed writes are logged with `debugPrint`.
- Releasing resources (checked for rescue and herd modes):
  - A component that caches a `ui.Picture`/`ui.Image` disposes it in
    `onRemove` and before re-recording (map or size change). Leaving a game
    screen calls `onDispose`/`onRemove`; restarts remove every component.
  - Never build a `TextPainter` inside `render`/`paint`. Use `TextCache`
    (rescue/camp) or `herdLabel` (herd); both evict only the least recently
    used label, and callers must not dispose what they return. A label kept
    in a field (e.g. fish tray count) is disposed when replaced and in
    `onRemove`.
  - Sprite sheets live in Flame's shared image cache: never call
    `game.images.clearCache()` or a game's `dispose` on screen exit.
  - Widgets dispose their `AnimationController`s, `ScrollController`s and
    timers, and remove every listener/observer they add (`CampState`
    notifiers, `WidgetsBinding` observers).
  - Game sounds go through `GameAudio`; do not create `AudioPlayer`s per
    event or start loops a screen does not stop.

Validation: `flutter analyze` and Android builds. Do not add project-local
tools or test files.

- Night-shift relics: `NightRun` owns a temporary silver wallet and up to three
  relics. Each cleared night grants silver; after the free card on even nights,
  `nightShop` opens before the next briefing. No run currency/relics are saved
  to camp progress. `night_relic_shop.dart` displays prices and card synergies.
  Embers extend lantern light; bell/charm advance one catch-rule step (never
  auto-deliver); moon pouch has a 10s trigger cooldown; prism freezes catch
  timers only in intersecting moon/lantern light.
