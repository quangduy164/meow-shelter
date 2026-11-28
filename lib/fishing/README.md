# Fishing

Rules live here; art lives in `lib/ui/widgets/fishing_*.dart`; online code
in `lib/online/`.

## Main pieces

- `ui/screens/fishing_screen.dart`: entry/preload, ticker, input, world
  session, saving, dialogs, disposal. Presentation is split into
  `fishing_cat_selection.dart`, `fishing_player_layer.dart` and
  `fishing_boat_picker.dart`; they add no ticker, listener or cache.
- `fishing_controller.dart`: casting/waiting/reeling/saving phases, input
  guards, cast cancel, notifications. Delegates movement to
  `fishing_navigation.dart` (destinations, tap routing, arrivals) and
  exposes `takeArrival()` so the screen knows which dialog to open.
- `fishing_river.dart`: the 12600 x 3600 world (7 sections of 1800 units).
  One centreline/width defines painted banks and movement limits, plus three
  coves and the Sea Cave inlet. `rollFish` / `catchWeights` choose fish.
- `fishing_region.dart`: the single region table (label, x range, land
  style, fish pool): Làng, Sông tre, Rừng ngập mặn, Cửa biển, Vịnh đá,
  Biển rộng; `regionAt` adds Hang biển.
- `fishing_place.dart`: `FishingVisit` is the single definition of every
  interactive structure (anchor, tap bounds, bank door, berth, optional
  floating prop). Art, quests, taps and collision all read it.
- `river_props.dart`, `river_navigation.dart`: seeded props, solid rocks,
  floating props, A* detours. `fishing_crew.dart`: boat seats by player ID.
- `fishing_trip.dart`: saves cat, boat spot, heading and fog
  (`fishing_trip_v1`) after changes, on pause and on exit. Restored spots are
  clamped to water.

## Adding things

- **Region:** add a `FishingRegion` row and its blend layer in
  `FishingRiver.fishLayers`; raise `sectionCount` if the world grows. Names,
  minimap and land art read the table. Recheck startup time on device.
- **Place:** add one `FishingVisit` value; routing, arrival and collision
  follow. Verify `props.resolve` leaves the berth unchanged.
- **Boat:** append to `FishingBoat` (label, one-line effect) and add one
  case in `paintBoatBack` / `paintBoatFront`.
- **Rod:** append to `FishingRod` (label, effect, price; 0 = free). Bought
  rods are `rod:<name>` in `CampState.owned`; `FishingRod.load` falls back
  to classic if not owned.
- **Fish:** append to `FishSpecies` (never reorder) with art, rarity, gram
  range, habitat and fight profile.

## Catch rules

- A fish and its grams are rolled at the casting position when the cast
  starts; crossing regions while reeling never changes the catch.
- Pools blend across region borders; night doubles `nightActive` fish and
  `nightOnly` fish never bite by day. Weather boosts some fish.
- Active water (`fishing_activity.dart`, real-time clock): rare x3, junk
  x0.3 inside the regional pool. The rod auto-aims only at reachable
  sightings in a 120° forward cone.
- Legendary fish bite only in their home region. Legendary bait is x6;
  bad-luck protection multiplies by `1 + misses/30` up to x4
  (`fishing_legend_misses_v1`). Bait is debited at the waiting-to-bite step:
  cancelling before that is free, a failed debit fails the cast.
- Clue hunts (`fishing_legendary_hunts.dart`) guarantee the species after a
  qualifying cast and do not spend bait. Failed attempts never fall through
  to another rare fish. All three legends must stay catchable.
- `castPoint` follows the current heading and clips at obstacles and cave
  walls; never search opposite angles for a longer cast.
- Fish-pulled boat motion uses `RiverProps.slide`; never `resolve`, which is
  only for click targets and placement.
- Gear effects: basket boat 0.7 drag, paper boat 1.25 speed, swan 1.5 active
  reach; classic rod 1.1 reel, bamboo 0.75 bite wait, lantern `nightLure`.

## Economy and progress

- Market prices: lost item 3, common 6, rare 16, precious 30, very rare 60,
  legendary 120; today's wanted species pays double. Coins are added before
  fish are removed, with refund on failure.
- Legendary bait: 5 common basket fish or 30 coins. Exchanged bait lives in
  the basket JSON, paid bait in `CampState`; use exchanged bait first.
- Shrine: one of each legendary, saved atomically with fish removal.
- Quests (`fishing_quests.dart`, `fishing_quests_v3`) save by stable name.
  Keep v1/v2 migration; never give an old count to a reordered step.
  Arrows and minimap use `navigationTarget`.
- Island shells refill daily (`island_shells_v1`); the cabin chest gives sea
  fish once per day; the cave run saves best stars/time and gives fish on the
  first clear per day. Cave level changes must still allow a 3-star run.
- First-trip tutorial (`tutorialStep`) runs only for new players.

## Time and weather

- 40-minute game day from epoch time (`FishingLighting.gameHour`), so it
  keeps running while closed. Sleeping in the cabin bed from 18:00 to 06:00
  skips to 06:00 through a saved shift (`fishing_clock_shift_v1`).
- A new trip starts at 08:00 with five sunny minutes
  (`fishing_environment.dart`). Weather follows the real clock in 5-minute
  slots and is not saved.

## Drawing (keeps FPS independent of map detail)

- Static art (land, trees, rocks, buildings, island) goes into the landscape
  recording through `_paintLandscape`; `FishingLandscapeCache` warms it
  while the cat picker shows and keeps it until screen disposal.
- Anything that moves or changes during play goes in a live painter
  (`FishingRiverSurface`, `FishingIslandPainter`, overlays), never in the
  chunks.
- Live painters draw only what is in view and never rebuild large `Path`s or
  shader `Paint`s per frame; keep them in `final`/top-level fields.
- Only the player layer and the HUD rebuild per frame; the HUD rebuilds when
  its state key changes. The minimap repaints on exploration changes.
- Cat selection warms only the chosen cat's needed sheets at normal decode
  sizes; never preload every breed.
- After editing static art, hot restart or re-enter the mode to see it.
