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
  - `adventure_game.dart`: run state, Flame load/resize/update/render/disposal,
    overlays and rewards. Its behavior parts share this one state owner:
    `adventure_targeting.dart` handles aim/target selection and cast entry;
    `adventure_combat.dart` handles effects, cooldowns, combos and damage;
    `adventure_boss_fight.dart` connects the dragon to cat/hazard combat;
    `adventure_run_rules.dart` handles hazards, wind, water, pickups,
    checkpoints and respawn. Keep the existing update order in the game.
  - `adventure_dragon.dart`: boss state, AI, phase timing and shared tail
    geometry. Its artwork parts separate the common drawing/turn poses
    (`adventure_dragon_art.dart`), original body/wings (`*_body_art.dart`),
    evolved body/head (`*_ascended_art.dart`) and original head/status effects
    (`*_head_art.dart`). `adventure_dragon_attacks.dart` owns telegraphed attack
    components and damage text; collision and art share the same geometry.
  - `adventure_skills.dart`: the public effect library, tuning constants and
    common ground geometry. Components live in parts by effect family:
    `adventure_projectiles.dart`, `adventure_fire_effects.dart`,
    `adventure_shadow_effects.dart`, `adventure_ice_effects.dart`,
    `adventure_earth_effects.dart`, `adventure_support_effects.dart` and
    `adventure_aim_indicator.dart`. Existing imports still expose these types.
    Behavior/art parts keep private state private; do not add a second game
    instance, ticker, cache or lifecycle owner just to split a file.
  - `ui/screens/adventure_screen.dart` owns screen entry, navigation and the
    pause/resume contract for combo help. Widgets `adventure_skill_controls.dart`,
    `adventure_combo_help.dart` and `adventure_victory_overlay.dart` own the skill
    controls, combo guide and results. The screen supplies replay navigation;
    the controls cancel their refresh timer on disposal.
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
  - `fishing_river.dart`: a continuous 12600 x 3600 world with seven cached 1800-unit
    stretches (two river stretches and four coastal stretches). One shared centerline and width define both painted banks and
    movement limits. Click-to-row paths follow bends without cutting over land;
    screen/world transforms share the camera, which follows smoothly and clamps
    to all four world edges. The viewport stays 600 world units high, so the
    taller world scrolls vertically instead of shrinking the boat and artwork.
    Resizing preserves boat position and its destination. New trips start
    moored beside the first near-bank dock (`startDockX`), with no auto-rowing.
  - `ui/widgets/fishing_river_art.dart`: detailed village/flower banks blend into
    bamboo/rock and rice-field banks; props use seeded world coordinates.
    `fishing_coast_art.dart` adds the estuary/beach, palms, lighthouse and islands.
    `fishing_scenery.dart` owns cached scenic clusters: village trellises/jars,
    bicycle/clothesline, bamboo shelters/plank crossings, coastal fishing huts,
    nets/crates/overturned boats and an abandoned island shelter. Static Pictures
    record once, cull by viewport and dispose on exit. Two layers sort new scenery
    around the walking cat; overlapping foreground clusters fade to 40% opacity.
    Only clothes, bamboo tips, flags, chimney smoke and the existing mill wheel
    animate per frame. Paths stay open; these additions are decorative scenery.
    `river_sea_land.dart` defines a solid 430-unit sand island at (9750,1750)
    and fourteen sea rocks in six clusters. The cached island artwork, solid-prop
    clearance and A* routing share these footprints. Water queries and cast
    positions exclude dry island land; surface waves and fish are clipped out.
    Bank-hit penalties still use bank-only bounds, so island contact is harmless.
    `fishing_island.dart` owns the prototype visit: click the pier/island to route
    to its fixed mooring, hop ashore, walk within the circular beach, collect six
    shells by proximity and chase three fleeing crabs. Clicking the parked boat
    walks back to the landing then hops aboard. The on-island `Về thuyền`
    button does the same when the parked boat is off camera. `FishingRiverRound` keeps the
    boat parked and follows the cat while ashore; `FishingController` dispatches
    island/water taps and allows casting from the shoreline. Water taps cancel a
    pending docking approach; saving and catch results retain their input guard.
    `fishing_island_art.dart` draws the cached pier and live shells/crabs. The
    selected `CatSprite` switches to walk/idle on land; the rod is attached to
    that cat when casting from land.
    The larger island has a coconut grove to the north, winding sandy paths,
    a central clearing, open southern beach and a marked western landing. Mooring,
    pier and walk limits derive from island radius. Six shells and the three
    crabs are spread across the enlarged island. The view scale stays unchanged;
    the camera follows the cat while crossing the island. Terrain details are
    recorded once in the chunk cache, including across the island's chunk seam.
    The same visit also supports both riverbanks and the mainland beach: click
    dry ground to moor opposite that point, hop ashore and walk along that bank.
    A bank visit stores its mooring and landing; depth-from-bank waypoints follow
    bends without crossing water. Walking is clamped inside world land bounds;
    the return button follows the same land route back to the parked boat.
    A small flag marks the temporary landing. Island shells/crabs remain island-only.
    The rod also works ashore: `castHere` walks to the nearest water edge before
    casting. The angler position owns rod art, fish pool and line retrieval;
    shore fights leave cat and moored boat fixed. Movement or return cancels a
    pending cast/current fight; save/results stay guarded. Boarding transitions
    cannot start a cast. Shore casting shares catches, weights and rewards with
    boat fishing and does not create a second save path.
    Shells remain collected across visits in this round, without persistent
    currency, inventory writes or changes to fishing rewards.
    `fishing_river_details.dart` caches mossy rocks and submerged coral. Visible
    lotus pads, vegetable rafts and driftwood bob/rotate on the animated surface;
    ducks swim independently with seeded scattered anchors, individual pace,
    facing, separation and boat avoidance; fish schools flee and gulls fly overhead.
    Duck movement is simulated in `RiverProps`, not a shared painted formation.
    Sparse layout: 10 ducks in two loose groups, 45 lily pads, two vegetable
    rafts and four logs. `river_encounters.dart` adds separated basking turtles
    on existing rocks (dive when approached, return after the boat leaves) and
    occasional nearby fish leaps with a cooldown. Landing positions validate
    shared rock/island clearance. `river_encounter_art.dart` draws only visible
    encounters, their jump arcs and splash rings, without labels or rewards.
    `river_props.dart` owns one seeded layout for artwork, solid rock clearance,
    buoyant spring/damped props, contact ripples and wildlife avoidance. Floating
    props yield to the hull and slow it gently, without damaging the boat.
    Five paper boats drift downstream, rotate when nudged and deflect off rocks;
    they use the same floating-prop simulation. `river_frog.dart` keeps each frog
    on a separate lily: sitting -> jumping -> submerged -> returning. Frogs stay
    hidden while the boat is near and hop back onto their moving lily after it
    leaves. `river_toy_art.dart` draws paper folds, frog leaps and landing splashes.
    These encounters do not modify fishing rewards or saved progress.
    `river_navigation.dart` runs A* only when a click's lane route crosses rocks;
    exact segment/circle checks and sampled bank edges keep detours navigable.
    Clicking a rock resolves to clear water, and fight steering slides off rocks
    without triggering the bank-hit penalty. These objects live only in the round. Three smooth `FishingRiver.coves` extend the
    banks into a lotus inlet, bamboo backwater and coastal lagoon. Geometry,
    rendering, water taps, casts and lane-based routes use those same bounds.
    Clusters leave the main channel open. Mossy water rocks are solid; coral is
    submerged scenery. Floating props do not block click-to-row routes.
    Travel order is village x=0..1800, bamboo x=1800..3600, mangrove
    x=3600..5400, estuary x=5400..7200, rocky bay x=7200..9000 and open sea
    x=9000..12600. The large island is offshore in the final sea region.
    `mangroveBlend` fades in/out around its two boundaries; `coastBlend` opens
    the estuary, and `rockyBlend` narrows then releases the bay into open sea.
    `fishing_mangrove_art.dart` records mud, stilt roots and its wooden landing;
    solid roots share their tree anchors with sailing clearance.
    The sea cave is an optional northward inlet centered at x=8100, not a
    mandatory eastward tunnel. `caveDepth` extends the top bank into a chamber;
    the main bay remains open to sail east. `caveBlend(x,y)` classifies cave
    names, fish pools and darkness by position, so the main bay does not become
    dark just because it shares the cave's x coordinate. Shore walks, casting
    and A* continue using the same bank geometry and solid rock footprints.
    `fishing_rocky_bay_art.dart` caches shingle, cliffs, cave slate and crystals,
    then draws solid rocks above the new ground. World-fixed masks blend biome
    borders. `FishingCaveLight` keeps reflections, droplets and light above the
    world but below HUD controls. Mangrove/bay art stops before the final sea.
    Regional pools add goby/mudskipper in mangroves, grouper/butterflyfish in
    the bay and cavefish/lanternfish in the cave; each new pair is exclusive to
    its region, with smooth boundary blending. Cave catches use the angler's
    vertical position as well as x, never the float's projected landing point.
    The six species append to the enum, preserving earlier indices and saved
    names. They have species art, rarity-ordered pull, gram ranges, journal
    habitat, affection and existing fight profiles. Lanternfish are nocturnal.
    New records and feeding reuse the same journal/basket keys; no weight totals
    or catch history are added. The journal has six habitat groups.
    `fishing_cabin.dart` defines a moored cabin ship at (11500,1000), its solid
    hull clearance, mooring and a separate 800x480 walkable room. A water tap on
    the ship stows fishing and routes to the mooring before entering. Another
    destination or casting cancels that approach; saving/results keep their guard.
    Inside, the controller updates only cabin movement, pausing the river round.
    `fishing_cabin_art.dart` (library) with parts `fishing_cabin_ship_art.dart`,
    `fishing_cabin_room.dart` (widget, chest popup) and `fishing_cabin_room_art.dart`
    caches and disposes exterior/interior Pictures; chest and door art read the
    `FishingCabin.chest` / `door` constants used for tapping. It draws
    the selected cat via CatSprite and scales input with the room viewport.
    Furnishings sit outside the walkable floor rectangle. A right-wall door
    (`switchRoom`) leads to a bedroom with its own floor and Picture; the bed sits
    right of `bedroomFloor`. Exiting from the bedroom walks back through the door.
    Tapping the bedroom treasure chest walks the cat to `chestSpot`; on arrival
    `fishing_cabin_chest.dart` gives three weighted sea fish once per calendar day
    via `FishCollection.addToBasket` (basket only, journal untouched).
    Door, exit button and
    system Back walk the cat to the hatch then return to the parked small boat.
    Leaving restores normal fishing controls; no catch or camp save is written.
    Fishing HUD: small Home top-left; minimap (80px) top-right with the area name
    under it, tap opens a full-world map dialog (pauses the round, shows explored %).
    Area changes flash a centered banner (~2.6 s). `guide` shows as a dark pill at
    top center for 4 s per new hint; basic control hints only while `beginner`.
    While reeling the minimap/banner hide and the basket dims.
    `fishing_minimap.dart` (also `full: true` for the dialog) draws: a cached,
    disposed world Picture in a 3600-unit window following `cameraFocus`, plus
    fog from `FishingExploration` (`fishing_exploration.dart`, 200-unit cells
    revealed each update, `round.exploration`).
    It hides while reeling and inside the cabin. `fishing_trip.dart` saves the
    last cat, boat spot, heading and fog (key `fishing_trip_v1`) every few
    seconds after changes, on app pause and on exit; ashore/cabin trips resume
    in the parked boat. Restored spots are clamped to water; bad saves are ignored.
    Chunk clips disable antialiasing so fractional camera offsets do not expose seams.
    Shared scenery helpers live in `fishing_art_kit.dart` (`artNoise`,
    `fillPaint`, `strokePaint`, `bankBand`). Mangrove, rocky bay and cave art use
    deterministic `artNoise(i, salt)` for
    species, size, offset and mirroring (cached chunks stay identical each run).
    The village harbour at the start (`fishing_harbor_art.dart`: boathouse with beacon tower, cargo and pier lamp) is static and recorded into the landscape chunks; tapping `FishingVisit.boatHouse.bounds` rows the boat to its own berth (or walks the cat there along the near bank) and the boat picker opens only on arrival (`FishingController.takeArrival`); from the island or the far bank the tap is ignored. Visits share one flow: `FishingVisit` in `fishing_place.dart` with its shared anchor, hit bounds, footprint and `mooring`, `FishingNavigation._goTo` rows there and `FishingController.takeArrival()` tells the screen which dialog to open; a new place adds one enum value. The floating fish market (`fishing_market.dart`, Cửa biển) is a solid `RiverPropKind.market` prop (collision, routing, `FishingRiver.contains/constrain`), drawn above the water by `FishingMarketStalls` from one recorded picture (`fishing_market_art.dart`); `FishingMarketDialog` sells basket fish for camp coins by rarity, today's `wantedOn` species at double price. Boats (`FishingBoat`: basket with a stern lantern that glows at night, paper, melon) are drawn only through `paintBoatBack`/`paintBoatFront` in `fishing_boats.dart`; a new boat adds an enum value and one case there. The world is 7 x 1800 = 12600 units; the last chunk is open sea east of the island so the lookout view stays centered. Fog saves from shorter worlds load row by row. The island centre is a cartoon rock massif (`fishing_volcano_art.dart`: snow-capped peaks, grassy hill with boulders, pines, a waterfall into a pool and a stream). Its footprint (`FishingIslandVisit.inMountain`) blocks walking and routes go around its foot; `mountainSilhouette()` keeps water effects off the peaks. Tapping it walks to `caveMouth` and opens the cave parkour (`fishing_cave.dart` + `fishing_cave_run.dart`): auto-run (`run` sheet), tap to jump/double jump (`jump` sheet: take-off, apex and fall frames chosen by vertical speed with a per-frame lift correction, landing frame for 0.12 s), the double jump plays a roll somersault. The level is 7200 units in three sections (`sectionNames`, respawn only at `checkpoints`) and speeds up from 235 to 320. Hazards: pits, crystal spikes, stalactites that drop near the cat and leave a shard pile, bobbing bats, crumbling ledges (gone `crumbleDelay` after landing, restored on respawn) and low ceilings that stop high jumps. Static art is one recorded picture; crumbling ledges, stalactites, bats, tokens and torches are drawn live and culled to the view. `rate()` gives 1-3 stars (finish, 60% of the 24 golden fish, 90% with at most one fall); the best stars/time is saved under `bestKey` and the first clear per day gives `stars` cave fish, with a lanternfish at 3 stars. Any level change must still pass a tap-timing search bot that clears the run with 3 stars. The world pauses while inside, like the cabin. The ashore return button is the `FishingTool.boat` icon.
    Day/night runs on a 40-minute game day (`FishingLighting.gameHour`, from epoch time so it keeps running while closed; `FishingRiverRound.hour` refreshed every 1 s by the screen; also feeds night fish weights). `fishing_night_overlay.dart` multiplies one tint over the world (`FishingLighting.at`) and adds glows: lighthouse lamp and beam, campfire, ship windows, cave crystals, a soft light around the cat and mangrove fireflies. Village cottage windows glow at night (`fishingCottageWindows`). The cabin follows the same hour (`FishingCabinRoom.hour`): windows show a starry night sea with moon, the rooms stay nearly daylight-bright under a light tint, lanterns and a live bedroom chandelier glow. The old lake sky/ambient painters were removed. Weather (`fishing_weather.dart`) comes from the real clock in 5-minute slots (about 80% sunny, otherwise one slot of cloud/rain/fog; 30 s blend, no save); `round.weather` boosts some fish in `rollFish` and `fishing_weather_overlay.dart` draws cloud shadows, rain streaks and ripples, and fog above the night tint. Effects are kept light; the HUD does not show weather. `fishing_water_art.dart`: `paintWaterBody` (cached; sea-only depth bands, clear shallows, sand ripples, reef shadows, optional region tint; also used by mangrove and rocky bay) and live, view-limited `paintWaterSparkles`, `paintSeaSwells`, `paintShoreWash` and `paintIslandWash`. Region layers are inflated 4 units so their faded edges leave no seam. `fishing_rock_art.dart` holds the warm outlined rock style: `paintBoulder` (all water rocks via `paintRiverRock`, and land outcrops with `inWater: false`), `paintCliffBand` (continuous north cliff, open at the cave inlet, plus a stepped south shelf in the rocky bay) and live `paintRockFoam` rings drawn by `FishingRiverSurface`. Bay sea stacks are `fishingSeaRocks` with radius >= 45, so art, collision and
    minimap share one list. The cave dimming uses an elliptical radial mask.
    `fishing_land_art.dart` fills far land per region (weighted, deterministic
    features on a jittered 175-unit grid, kept back from the water by a
    per-region margin) plus a footpath or paw-print trail along each bank.
    Decorations are visual only; shore walking has no collisions.
  - `fishing_river_scene.dart`: `FishingLandscapeCache` owns the seven static
    landscape Pictures for one fishing session. Warm them sequentially while
    the cat-selection paw loader is visible, yielding between regions; retain
    them until screen disposal so changing biomes never records a full-height
    scene during movement. Stop warming after disposal and reuse completed work
    if a visit fails/retries. Do not persist this cache globally.
    `_BackdropTiles` rasterises 256-unit image tiles (`toImageSync`, coarser
    levels when zoomed out, at most 2 new tiles per frame, 40 kept, LRU disposed).
    Missing tiles share one clip and replay each visible chunk once. No raster
    prefetch queue competing with frame rendering. Both caches are disposed on
    exit; adding new regions must recheck startup time and `cache.bytes` on device.
    Then animated water, boat hull and front rim.
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
    rod artwork uses the river's world scale and floats ahead of the cat,
    without drawn arms or paws connecting to it. The tension bar follows the float, flips below it near the top HUD, and
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
  - `fishing_region.dart` is the single region table: `FishingRegion` rows hold
    label, x range, `FishingLand` scenery style and the fish pool. To add an area,
    add a row (and its blend layer in `FishingRiver.fishLayers`); names, minimap
    and land art read from it. `FishingRiver.regionAt` adds the cave inlet.
  - `FishingRiver.rollFish` layers those pools in order (`fishLayers`): village (perch, tilapia,
    carp, rare goldfish), bamboo (catfish, koi, very rare catMew), mangrove
    (goby, mudskipper and brackish species), sea (sardine, mackerel, clownfish,
    pufferfish), rocky bay (grouper, butterflyfish) and cave (cavefish, lanternfish),
    plus lost items. Pools blend across
    x=1560..2040, the mangrove boundaries and x=5160..5640; night boosts nocturnal fish. A fish is rolled
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
- Fishing movement takes the shortest clear path: `sailTo` goes straight when `props.clearLine` allows, else follows the channel lanes (A* `riverDetour` around obstacles) and `pullTight` removes every unneeded bend; bank walks do the same with `landContains`.
- Fishing world drawing (keeps FPS independent of map detail):
  - Static art (land, trees, rocks, buildings, cliffs, island and mountain
    shapes) goes into the chunk recording via `_paintLandscape` and its
    region painters. It is tiled automatically, including new regions added
    by raising `sectionCount` and adding a `FishingRegion` row.
  - Anything that moves, animates, or changes during play (water effects,
    waterfall, fire, animals, collectibles, night lights, weather) goes in a
    live painter (`FishingRiverSurface`, `FishingIslandPainter`, overlays),
    never in the chunks.
  - Live painters draw only what intersects the camera view, and do not
    rebuild large `Path`s or shader `Paint`s each frame: build them once in
    a `final`/static field.
  - Landscape recordings warm during cat entry; raster tiles follow the camera.
    After editing static art, hot restart or re-enter the mode to see it.

Validation: `flutter analyze` and Android builds. Do not add project-local
tools or test files.

- Night-shift relics: `NightRun` owns a temporary silver wallet and up to three
  relics. Each cleared night grants silver; after the free card on even nights,
  `nightShop` opens before the next briefing. No run currency/relics are saved
  to camp progress. `night_relic_shop.dart` displays prices and card synergies.
  Embers extend lantern light; bell/charm advance one catch-rule step (never
  auto-deliver); moon pouch has a 10s trigger cooldown; prism freezes catch
  timers only in intersecting moon/lantern light.

- Sea Cave shrine (`FishingShrine`, `FishingVisit.shrine`): rows to its
  mooring before opening the offering dialog. `FishingShrineView` records
  stonework once above water, disposes the picture on exit, and draws only
  its visible flames/halo live. One of EACH species in `FishSpecies.legendary` completes it: catMew (bamboo), seaDragon (open sea), moonfish (sea cave). Duplicate offerings are rejected.
  `FishCollection.offerToShrine` saves fish removal and progress atomically
  in the basket JSON (`_shrine_v2_<species>` reserved metadata; legacy `_rocky_shrine_offerings_v1` credits catMew once), without
  changing collection counts or weight records. Completion is permanent.

- Legendary fish append enum values to preserve saves. `FishingRegion.openSea`
  has its own fish layer after the rocky bay; region pools are sampled from
  the casting position. Sea dragon uses the dash fight, moonfish orbits and
  is more active at night. Their art and journal details share FishSpecies.

- Mangrove bait workshop (`FishingVisit.baitHouse`)
  uses the visit/mooring flow and solid-prop navigation. Its static stilt
  house is recorded once by `FishingBaitHouseView`, culled and disposed.
  `FishCollection.exchangeLegendaryBait` exchanges 5 mixed common basket
  fish for one bait in one basket-JSON write (`_legendary_bait_v1`). The
  fishing controls expose an optional bait toggle. `_startCast` guards
  asynchronous preparation and persists one consumed bait before selecting
  the fish. A baited cast multiplies only regional legendary weights by 3;
  it never introduces fish outside that region. Canceled or failed catches
  still used that cast's bait. Shore bait is consumed only after reaching
  the casting edge. Counts survive re-entry; toggle starts off per session.

- Market prices: common 6, rare 16, precious 30, very rare 60, legendary
  120 coins; daily wanted species still doubles its base price. The market
  dialog owns a scroll view so full baskets fit short landscape screens.
- Bait workshop accepts either 5 common fish or 30 camp coins. Coin-bought
  bait is stored in CampState alongside coins (`legendaryBait`), so purchase
  and paid-bait consumption each use one save with rollback on failure.
  FishCollection.legendaryBait combines exchanged basket bait and camp paid
  bait; consumption uses exchanged bait first, then paid bait. Exchanging
  fish updates only the basket portion; it must never copy the combined count.

- Fish-pulled boat movement uses `RiverProps.slide(from, delta)` (bounded,
  swept steps with tangential sliding and boundary clipping). Never use
  `resolve` for this motion: it projects click destinations out of overlapping
  obstacles and can jump far across rock/root clusters. Keep `resolve` for
  navigation targets and initial placement. The ashore return-boat button
  sits left of the bait control, with separate hit areas for all three actions.

- Casting uses `FishingRiverRound.castPoint` to choose a clear water ray,
  shortening casts near obstructions instead of projecting through banks.
  Cave casts and activity targets stay in the cave; `clipCast` stops the
  reeling float at the first obstruction. Short casts reel inward too.
  A fight begun in the Sea Cave uses a small orbit around its casting point
  instead of the main bay's horizontal slope, keeping automatic pulls in
  the inlet. Player steering can still leave the cave deliberately.

- Village rod workshop (`FishingRodHouse`, next to the boathouse) is static
  chunk art (`paintFishingRodHouse`); meadow/far-land decoration leaves its
  footprint clear. `FishingVisit.bankDoor` shares ashore arrival handling for
  both village shops; boats use each shop's own mooring.
  `FishingRod` (classic, bamboo) saves by name in `fishing_rod_v1`, defaults
  to the existing classic rod, and is selected through the controller.
  FishingPainter reads the selected rod for both directions and every cast/
  reeling pose. Bamboo uses shaft nodes and a tip-tied line, without the
  classic reel or guide rings; gameplay tuning is shared.

- Flutter CatSprite owns an ImageStream subscription and its delivered
  ImageInfo handle. While a new sheet/decode size loads, retain the previous
  image AND its frame-count/crop; switch them together on successful load.
  Late deliveries cannot replace a newer request. Remove listeners on swap/
  dispose and release old ImageInfo handles after painting, without evicting
  shared image caches. CatSprite.decodeHeight/provider defines the same
  64-pixel decode buckets used by precacheActions.
- Fishing cat selection warms only the chosen cat's idle/row/walk/jump and
  four fishing sheets at the normal boat/shore decode sizes before starting
  the ticker. Keep selection disabled while preparing; do not preload every
  breed or decode full-size sheets. Other newly encountered actions keep
  the previous frame visible while loading through CatSprite.

- Bamboo rod is a green branch through to its cut butt, with no machine-rod
  handle/reel. Its two leaf sprigs use cached shared paths in
  `fishing_rod_art.dart` and follow shaft tangents, facing and bending in
  both live rod art and the workshop preview/sign.

- Sea Cave is a round chamber (`caveRadius`, centre `caveStart`/`caveCenterY`)
  with one neck (`caveNeckHalf`) into the bay. `caveDepth` gives the chamber
  top; `inCaveLip` is the land between the chamber floor and the bay, excluded
  by `contains`/`constrain`. Art draws the water shape `seaCaveWater` once;
  the bay cliff runs across the lip and breaks only at the neck. Channel lanes,
  fish pulls and depth shading use `bayCenter`, ignoring the chamber.

## Legendary fish art and shrine statues

- `ui/widgets/fishing_legendary_art.dart` draws the three legendary fish (Mèo Nessie, Rồng biển, Cá nguyệt quang) in the shared 100x64 fish box. `FishingFishArt` routes legendary species there, so journals, baskets, fights and popups all use it. `locked: true` renders the same art as grey stone.
- Legendary fish use a bigger `FishingController.fishScale` (1.6 to 2.1) and a larger catch popup frame.
- The Sea Cave shrine (`ui/widgets/fishing_shrine.dart`) places one statue per species at `shrineStatues`. Stone statues are recorded in the static shrine Picture; coloured statues are recorded once per species and drawn only after `hasShrineOffering`. Glow gradients are built once; per frame only opacity, rays and sparkles change. All three offered adds a light beam and threads to the arch.
- `FishingShrine.radius`, `hit` and `mooring` match the wider statue island; the night overlay lamps read `shrineStatues` positions.
- Ship cabin bed: `FishingCabin.bed` is the single source for the double bed art and tap area, and it sits inside the bedroom walls. `FishingCabin.bedSpots` holds one sleeping spot per side. The local cat uses the left one (`bedSpot`); the right one is reserved for a second player's cat if the mode goes online.
- Sleeping through the night: while the cat sleeps in the cabin bed, `FishingCabin.sleepDark` fades the room to black. At the darkest moment `dawnDue` is raised, and the fishing screen calls `FishingLighting.skipTo(6)`. That adds a saved shift (`FishingLighting.shiftMs`, prefs key `fishing_clock_shift_v1`) to the shared 40-minute game clock, so the whole world wakes at sunrise (06:00). Only sleep begun from 18:00 to before 06:00 fades and requests dawn; daytime bed use is a nap without darkening or changing the clock. The screen rechecks the current hour before skipping, so crossing 06:00 naturally never skips an extra day. Fade, hold and fade-in take 3 s in total; tapping elsewhere hops the cat off the bed and cancels pending dawn. The full map header shows the in-game time through `FishingClockChip`.
- Catch odds live in `FishingRiver.catchWeights` (used by `rollFish`). Legendary fish bite only in their home region (`regionAt(...).fish`), with base weight 1.5 (moonfish 2). Night doubles `nightActive` fish, and `nightOnly` fish (lanternfish, moonfish) never bite by day. Active water uses `FishSpecies.activeWaterBoost` (common 1, rare 1.6, legendary 2, other rare tiers 3, junk 0.3). Legendary bait is x6. Bad-luck protection: `FishingController` counts casts in legendary water without a legendary (prefs `fishing_legend_misses_v1`) and multiplies legendary odds by `1 + misses/30`, up to x4. It resets when a legendary is saved.
- First-trip fishing tutorial: `FishingController.tutorialStep` returns the caption and the button to point at (`FishingTutorialTarget`) for 5 steps: row, cast, wait and strike, reel, open the basket. It runs only for brand new players (no `boatGuideKey`) until the basket is opened or "Bỏ qua" is tapped (saved as `tutorialKey`). During it the bite never times out, an early strike only shows a nudge, tension is capped below snapping and the fish cannot slip off. `fishing_screen.dart` draws the translucent caption between Home and the minimap plus a bouncing arrow (`_tutorialOverlay`).
- Fishing quests (`fishing/fishing_quests.dart`): ten steps lead from village fishing, bamboo rare fish, active water and the market through shrine discovery and all seven regions, then Nessie, moonfish, sea dragon and offering. `fishing_quests_v3` saves completion by stable name, per-quest counts, visited regions and reached destinations. Migrate v1/v2 counts using their original orders, never assign an old count to the newly reordered current step; already completed finales stay complete. Rewards retain stable `quest-reward:<name>` IDs. All visits are recorded, including before the exploration quest becomes current. `navigationTarget` picks the next unvisited region or hides a normal quest destination after it has been reached; both edge arrow and minimap must use this getter, not the enum's static target. `onBoatAt` gets the world cat position ashore and boat position afloat; no duplicate visit/save work each frame. Shrine discovery requires actually entering the cave. Existing fish catches and inventory remain valid; this changes quest order, not fish spawn pools. The quest trail derives its length from the enum and the exploration card lists the seven visited states.
- Fishing UI kit (`ui/widgets/fishing_dialog_kit.dart`): use it for every new fishing-mode panel. `FishingDialogHeader` (icon badge, title, optional subtitle and trailing widget, close), `FishingCoinPill`, `FishingFishTile` (fish in a rarity-tinted frame with count badge, caption, optional shield for legendaries) and `FishingRewardPanel` (full-screen reward card: glowing hero such as `FishingChestHero` or `FishingStarsHero`, title, optional record badge and stat chips, fish tiles popping in one by one, note and actions). Used by the market, bait house, rod house, boathouse, quest journey, cabin chest and cave run finish. The shrine keeps its own night-blue panel on purpose.
- Fishing rods (`fishing/fishing_rod.dart`): each rod has a label, a one-line `effect` and a `price` (0 = free). Bought rods are stored in `CampState.owned` as `rod:<name>` via `CampState.buyItem`, so coins and ownership save together. `FishingRod.load` falls back to the classic rod if the saved one is not owned. The lantern rod (200 xu) is sold once the Sea Cave shrine has been found (quest past "find shrine" or any offering). Its effect is `nightLure` in `FishingRiver.catchWeights`: night fish x3 at night instead of x2. Art: `paintRodLantern` in `fishing_rod_art.dart` (painter and shop preview); the screen sets `FishingRiverRound.rodLantern` while fishing so the night overlay adds its glow.
- Local player identity (`fishing/player_identity.dart`): `PlayerIdentity.load(preferences)` creates a cryptographically random 128-bit installation ID under `player_id_v1`, retains it across cat changes and mode re-entry, and exposes the checked asynchronous save as `saved`. Malformed IDs are kept under `_broken`; write errors log without blocking offline play. This is a local identity, not an authentication token; future Firebase guest auth must link its UID separately.
- Per-player visible state (`fishing/fishing_player.dart`): `FishingPlayerState` holds ID, cat/display name (from `CatBreed`), position, facing, location, pose and boat/seat membership. `FishingController` owns the local instance and updates it before listeners are notified. Cabin/bedroom/parkour use separate location values because their positions are room coordinates, not world coordinates. Pose logic lives in the controller/cabin/cave, shared by widgets and state; `rowingFrame` shares the same stroke mapping with the oar. No networking, account, world code or shared inventory is introduced.
- Boat crew (`fishing/fishing_crew.dart`): a boat has a stable `boatId`; `FishingCrew` seats `FishingPlayerState` objects by ID, with no special `'local'` ID. First aboard drives; driver departure promotes the next player and updates their seat metadata; shrinking the boat returns displaced players and clears their membership. A player cannot board two crews at once. `FishingRiverRound.playerPosition` derives anchors from the actual seat, including a local passenger; the screen draws every other occupied seat (including a remote driver) from that player's cat/pose, even when the local cat is ashore; boat riders keep their boat sprite size independently of the local land sprite. Casting, canceling and reeling as a passenger never stop, steer or fish-pull the shared boat. Local cabin/shore visits remove the local member and reboard on return. Future multiplayer must still implement multiple world boats, join/disconnect handling, ownership transfer and remote fishing lines/rewards.

- Selling lost items and shells: `FishCollection.catchFish` now stores junk in the basket as well. `basket` stays edible-only (camp feeding, bait), `sellable` lists everything the market buys. Lost items sell for 3 xu, `FishSpecies.seashell` (appended, junk, never hooked) for 8 xu. Island shells: picking one calls `catchFish(seashell)` through a serial save chain, and the picked set is saved per real day (prefs `island_shells_v1`), so the six shells refill daily. Finishing the shrine quest pays 99999 xu.
- Gear effects (one small effect each, labelled in the boathouse and rod house): boats in `FishingBoat` (`effect`, `dragByFish` basket 0.7 in `FishingRiverRound.chase`, `speed` paper 1.25 on the top rowing speed, `activeReach` swan 1.5 for `FishingActivities.nearby`); rods in `FishingRod` (`reel` classic 1.1 on the reeling rate, `biteWait` bamboo 0.75 on the wait before a bite, lantern = `nightLure`). Boats change how you move and fight; rods change what bites and how fast.
- Active water ("cá động", `fishing/fishing_activity.dart`): a 560-unit square grid over the whole map; each cell runs a 27 s cycle (16 s visible), offset per column and row. A fixed random per (cell, cycle) decides whether it shows (`density`) and where (up to four tries for open water away from the banks; land cells are skipped). `density` is set every update from `densityAt(hour, rain)`: 0.5 by day, up to 0.75 around 6:00 and 18:00, +0.2 in full rain, capped at 0.85. The clock is real time (`FishingActivities.worldClock`), so reopening the mode keeps the same sightings. `visible` takes the camera rect (left/right plus top/bottom); `nearby` searches a square around the boat.

- Fishing journey migration: current order and v3 persistence are described above. Legacy v2 ordered Nessie before active water; retain that old order only for migration. Lantern unlock still checks shrine-discovery completion by name; moonfish hints use 18:00 to before 06:00.
- Legendary fights share `FishingFight.at` between rules, boat motion and live effects: Nessie has two warned reverse pulls per 6.8 s, sea dragon has three increasingly fast warned dashes per 9 s (`pullMultiplier` affects boat pull), moonfish rests, warns, dives out of view and resurfaces into an orbit per 8 s. Moonfish ripples/bubbles and dragon wakes are drawn only in the existing visible fight layer; no new text or fish-name reveal is added. Shore fishing treats orbit steering as controlled because the parked boat cannot be steered.

- Firebase bootstrap (`online/firebase_session.dart`): Android Firebase options come from `android/app/google-services.json`, processed by the Google Services Gradle plugin. `FirebaseSession` initializes Core, Auth and RTDB (Singapore URL) in the background after `runApp` at app launch; fishing entry/resume retries failures and concurrent attempts share one future. `main` also creates/persists the local installation ID at first launch, even offline. Existing Auth credentials are reused, otherwise anonymous sign-in runs. Failures log and return false without blocking local play or changing the installation ID, inventory or saves. `authenticated` indicates identity only; it does not claim RTDB is connected. No world reads/writes, rules changes or presence subscriptions exist yet. Future world code must use Auth UID for access control and link the local installation ID as metadata, never treat the local ID as a credential.

- Fishing worlds (`online/fishing_world.dart`): create one persistent world per Firebase Auth UID under `worlds/{uid}` and reserve a random 7-character code at `worldCodes/{code}` using a transaction. The local installation ID is not an authorization credential. The code is both the owner's displayed world code and the visitor's entry code; map geometry stays in code (`mapVersion=1`). `firebase/database.rules.json` and `firebase.json` are the deployable RTDB rules/config; rules remain closed until deliberately published through Console/CLI. Only authenticated users can resolve a specific code/read specific world metadata (no root listing); only the owner writes their metadata/code and only each UID writes its own live state. This prototype uses code possession for visiting, not a friend ACL. The 8-player admission check is client-side; a hard server-enforced cap needs a transactional slot allocator before public matchmaking.
- World presence: only starts after selecting a fishing cat, ends on mode exit/app suspension. Each connection has its own push ID at `sessions/{world}/players/{uid}/{connection}` and the owner also registers `worlds/{uid}/hosts/{connection}`. Arm `onDisconnect().remove()` before publishing; remove/cancel on normal exit, rotate connection IDs after reconnect, filter states older than 15 seconds and restore the home trip when visiting loses its host or network. Epoch checks discard callbacks from old visits. Failures report in the world dialog and leave offline play usable. Do not enqueue movement from frame loops while disconnected; publish at most 8 snapshots/s, one write in flight, with server-time-offset timestamps and matching freshness rules.
- `online/fishing_peer.dart` validates a small display-only snapshot (breed, location, pose/frame, world cat/boat positions, boat type/facing, rowing, timestamp). Never synchronize inventory, fish rewards, quest completion, camera or physics through this snapshot. `FishingPeer` interpolates peer positions without mutating local simulation. `FishingRemotePlayers` draws only peers in view, uses shared boat art and `CatSprite`, hides interior cats from outdoor space but keeps their parked boats. Indoor multiplayer rendering, remote lines and shared-boat network ownership are not included yet. Local land/cabin/parkour coordinate spaces are sent as separate location values.
- Fishing social UI: `FishingWorldLobby` on the cat-selection screen shows/copies your code and selects home or a friend's destination before entering gameplay. Visiting requires the host to be actively fishing and the same map version. Save the home trip before departure; skip trip saves while visiting and restore it when leaving so a guest's exploration/position never overwrites the home save. All fish, coins, daily rewards and quests remain personal.

- Extensible RTDB validation: Rules validate content IDs by bounded format instead of a fixed breed/boat/action/location list, frames as integer 0..255, signed coordinates within +/-1,000,000 and positive integer map versions. Keep ownership, required fields, timestamp freshness and unknown-field rejection unchanged. Client rendering still accepts only locally supported assets/actions and current-map bounds (derived from FishingRiver); world joining requires an exact mapVersion match. Existing hosts update their metadata version on entry when the app map version changes. New shared permissions/features still need dedicated Rules, not arbitrary extra snapshot fields.

- First fishing environment (`fishing/fishing_environment.dart`): a genuinely new trip starts at 08:00 with five real minutes of clear weather. Save the existing clock shift, a once-only marker and sunny-until epoch; repeat entries never reset them. Migrate previous trips/guide/catch progress without resetting the time, and retain any existing sleep shift. The 40-minute day continues against wall-clock time while the app is closed.
- Shared environment: world metadata has an optional owner-writable `environment` object (`shiftMs`, `sunnyUntil`); publish on host entry/reconnect or after host sleep, not per frame. Convert the host's local shift/sunny deadline using RTDB serverTimeOffset so host and guests compute the same hour and real-time weather slots from server time. A guest subscribes only to the current world's environment, uses it for world light, catch pools and map clock, and restores their own settings on return/disconnect. Guests never write world time; online dawn is coordinated by the shared sleep barrier after all active players sleep. New visitors require compatible environment metadata. Republish database.rules.json to allow this field; all ownership checks stay unchanged.

- Stable online presentation extension (`online/visual_state.dart`): both world metadata and each connection accept an optional `display` JSON-object string capped at 8,192 characters. Extend cosmetic/environment data inside this envelope without changing Rules; don't add arbitrary top-level snapshot fields. Ownership, core snapshot validation and timestamp freshness remain enforced. `VisualState` bounds decoding and ignores malformed/non-object payloads. `FishingPeerSnapshot.display` preserves future optional display properties; unknown properties never affect local inventory, physics or control rights. World `display.environment` now carries clock/weather; hosts preserve unknown display keys while updating it, guests parse the supported fields and new clients retain a read fallback for legacy `world.environment`. Existing legacy Rules stay solely for compatibility. Any new shared authority still needs explicit permissions/Rules.

- Fishing entry lobby (`FishingWorldLobby` in the cat-selection screen): destination defaults to home/offline play; optional visit code is entered before choosing a cat. A flat social button directly below Home on cat selection opens the scrollable destination dialog; the owner code and guest input live only inside that dialog. Cat choices keep the original full-width centered layout. `FishingWorld.prepare()` allocates/reads metadata without registering player/host presence; live listeners/publishing start only after choosing a cat. Guest entry validates the code, warms that cat, waits for online readiness, saves the home trip and visits before showing gameplay; a failed visit keeps the selection screen and cleans up live presence. The old in-game code dialog/social button was removed. Home play never waits for network metadata. Starting and pending authentication use epoch checks so a canceled lobby visit cannot later announce a ghost player.

- World-code dialog layout: the guest input is directly below the header, the own map code is one compact row, and the image is a bundled actual daytime sea/island/pirate-ship capture (`assets/images/previews/fishing_island.png`) rendered with production map painters. No live map recording/simulation runs for the preview. The modal has no scrolling: image/helper collapse first as available height shrinks for landscape keyboards; the input and close control stay accessible. Cat selection stays full width behind the modal; empty guest code means home/offline.

- Fishing destination visual revision: the modal uses a scenic postcard with overlaid own code/copy action beside the guest form on wide screens, and a stacked form on narrow screens. The entry action immediately starts the existing preload/join flow with the last played owned cat; incomplete guest codes keep it disabled. Low-height/keyboard views collapse image and helper text, keeping input/confirm/close usable without scrolling. The opener under Home now has a gold face and cream outline for contrast.

- Fishing selection navigation: `FishingMenuButton` shares the flat gold face, cream border and rounded-square shape for selection Home, social opener and destination close. Gameplay's compact flat navigation stays independent. Destination panel max width is 560 design units; the horizontal postcard/form layout starts at 520, preserving the composition in the narrower modal.

- Fishing menu palette: selection Home/social, destination close/copy and confirm use flat white/cream surfaces with dark icons and subtle borders. Preserve the 560-unit postcard layout and keyboard adaptation; no raised gold faces in this menu.

- Shared sleep (`online/fishing_sleep.dart`): online bedtime uses a host-owned barrier in the existing world `display.sleep` envelope, so no new Rules deployment is required. A vote is a fresh (<=2.5 s) live snapshot with bedroom location and sleep pose. Wait until the initial player list arrives and everyone is asleep; host publishes a start timestamp 400 ms ahead, waits for successful publication and rechecks all votes at the 1.5 s dawn point before changing the clock once. Any awake arrival/wake-up before dawn cancels the barrier and fade; sleeping again starts a new timer. Guests consume the owner's shared timestamps for the 3 s fade and never write world time. Offline solo sleeping retains the original cabin timer. No consent dialogs or banners. Missing players leave through existing disconnect/expiry handling.

- Fishing visitor names: snapshot `display.name` comes from `CampState.nameOf` (the camp nickname), with bounded single-line parsing and breed fallback for older clients. Only remote outdoor cats receive Flutter text labels; the local cat has no label. `FishingArrivals` ignores the initial roster and suppresses reconnects within 10 s, announcing new remote UIDs once rather than on each movement packet. A bounded world queue feeds `FishingArrivalNotice` across outdoor/interior scenes; its three-second timer/listener are disposed on exit. No new Rules fields are needed.

- Fishing room keyboard layout: keep the room form and code field in keyed `Positioned` subtrees while constraints change. Budget header, form and preview against the actual remaining dialog height; hide scenery/title first, then place input and confirm side by side for short landscape keyboards. Never reparent the focused field between row/column branches.

- Shared input-dialog contract (`ui/widgets/game_surfaces.dart`, see DESIGN.md):
  `GameDialog` owns keyboard insets and caps vertical margins/padding at 8 units
  while typing. Simple forms use `scrollable: true` and a pinned `header`;
  custom responsive forms fit the remaining LayoutBuilder constraints without
  subtracting insets a second time. Keep focused inputs/controllers mounted;
  hide decoration before compressing controls, never switch the scroll wrapper
  on keyboard state. Camp naming uses the shared scroll/header; fishing rooms
  keep their stable keyed layout. Both game-screen Scaffolds disable background
  resizing for the dialog keyboard. Future input dialogs follow this contract
  and validate focus/text/save/close with small landscape keyboard insets, using
  temporary tests outside the repo and UiScaleBox coverage.

- Cast direction: `FishingRiverRound.castPoint` follows the full current heading (including vertical travel) and clips the ray at obstacles/cave walls; never search opposite angles for a longer cast. `FishingController` uses one forward-activity selector for the HUD and the actual cast: only reachable sightings within a 120-degree forward cone are eligible, so a nearer blocked or rear sighting cannot steal the cast. Shore fishing retains its outward-to-water rule.

- Room entry action: `FishingWorldLobby.onEnter` is separate from dismissal. The button and keyboard Done return an entry intent; closing/back only dismisses. After the dialog closes, `FishingScreen` immediately runs the existing guarded cat-preload/world-join flow with the last played owned cat (otherwise the current/default orange cat), with paw loading, code validation and normal offline/error cleanup. No second cat-selection tap is required. Empty code enters the home map.

- Reel presentation: stop the float at 180 world units from the cat afloat (140 ashore), capped by the initial cast distance so short casts never move outward. Preserve wall/cave clipping. Rod geometry is independent of reel progress; only float/line distance shortens before the catch animation brings the fish to the paws.

- Structure geometry (`fishing/fishing_place.dart`): `FishingVisit` is the single definition of the six interactive structures. Each row owns art anchor, tap bounds/padding, optional bank door, berth offset and optional floating prop kind/radius/depth. Rendering, quest targets, tap navigation and collision read this definition directly; economy/gear/interior classes own only their behavior. `createRiverProps` and `FishingRiver` enumerate `FishingVisit.floating`, so adding a floating structure does not require a second geometry list or a depth switch. `river_prop_kind.dart` holds the pure shared kind enum, re-exported by `river_props.dart` for existing art consumers. The pirate ship uses the same hit/berth data but enters its interior through the cabin's pending-arrival flow. All original coordinates, hit rectangles and berths are preserved; verify `props.resolve` leaves each berth unchanged and tap-to-arrival still opens all six places.

- Legendary bait consumption: remember whether a cast used bait for its fish roll, but debit stock only at the waiting-to-bite transition. Canceling casting/waiting costs no bait. `_beginBite` serializes the inventory save before exposing the bite; guard duplicate ticks/cancel during this short commit, and fail the cast if the debit cannot save (never grant a free boosted catch). Once a fish bites, missed hooks/escaped fish still consume that single bait.

- Rod grip alignment: the curved shaft of reel/lantern rods starts at the straight grip collar, along its tangent, instead of curving underneath the grip. Shop previews use the same straight-grip/curved-shaft junction rule and anchor their reel to that grip; bamboo remains a continuous stem. Verify both facings and loaded poses when changing rod artwork.

- Presence change filter (`online/fishing_presence_gate.dart`): decisions are capped at 125 ms, with a 1 s idle heartbeat. Ignore sprite frame/stamp changes, filter cat/boat movement below 3 units relative to the last acknowledged state, and flush the exact final coordinates after a stationary sample or a pose/movement-state change. Capture only the latest state when a write slot is available; never enqueue intermediate positions. A 3 s timeout reports trouble but does not unlock an outstanding RTDB write (Future.timeout cannot cancel it). Accept acknowledgements only for the current session/ref. `display.animating` and `display.pose` distinguish animation playback/frozen reel states without new Rules fields. Remote peers animate locally, retaining animation time across movement/heartbeat packets and resetting only on breed/location/action/playback/phase changes. Frame remains a compatible initial keyframe, not a per-frame send trigger. No shared physics or authority is inferred from animation.

- Solo online presence: when the host has no live remote peers, publish one full state on entering solo mode, then update only `stamp` every 5 s. Skip local snapshot capture/JSON work on other timer ticks. Keep host/code/presence subscriptions active, so guests can still join within existing 15 s freshness checks. A guest arrival forces a fresh full snapshot on the next available 125 ms send slot; while shared, use the normal movement filter and 1 s idle heartbeat. Returning to solo forces one final snapshot, then timestamp-only keepalives. Guests retain normal publishing even while the host roster loads. Existing single-flight/epoch checks apply to both writes; no new Rules fields.

- Removed obsolete surfaces: backdrop tile cache no longer accepts/calls a no-op visibility callback after full-session landscape warmup; `FishingPlayerState` has no unused breed-name `displayName` getter. Online names still come through the validated peer snapshot/camp-name path. The old geometry-only bait-house model is replaced by the central place definition; the bait-house UI/economy remain.


- Fishing module boundaries: `ui/screens/fishing_screen.dart` owns entry/preload,
  ticker, input, world session, saving, dialogs and disposal. Presentation lives
  in `fishing_cat_selection.dart` (owned-cat choices and entry state),
  `fishing_player_layer.dart` (local cat, occupied boat seats, rod and catch), and
  `fishing_boat_picker.dart` (boat choices). The screen supplies callbacks and
  keeps save/pause/entry behavior. Player rendering remains under the existing
  frame-driven builder; widgets add no ticker, listener or scenery cache.
- Fishing navigation (`fishing/fishing_navigation.dart`): `FishingNavigation`
  owns destination requests, boat/shore tap routing and arrival detection.
  `FishingController` keeps fishing phases, input guards, cast cancellation and
  notifications; it delegates movement routing and exposes arrivals to the
  screen. Destination geometry still comes only from `FishingVisit`.
- Fishing room directory (`online/fishing_world_directory.dart`):
  `FishingWorldDirectory` owns code generation/validation, home-code reservation,
  metadata loading/writing and destination lookup. Preserve unknown world
  display fields and cached reservations on retry. `FishingWorld` keeps live
  presence, admission, session switching, environment/sleep synchronization,
  epoch checks and disposal; the directory starts no timers or subscriptions.
