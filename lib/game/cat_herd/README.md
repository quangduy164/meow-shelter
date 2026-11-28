# Lead the Herd

Independent of rescue and Adventure; never imports rescue maps.

## Files

- `herd_round.dart`: deterministic simulation when seeded: recruiting, the
  distance-sampled leader trail, followers, hits, scattering, delivery,
  score, win/loss. `reset` starts a round; `update` takes a normalized
  direction and a small step. `resize` scales positions in place and keeps
  the run, score and result overlay.
- `herd_game.dart`: Flame lifecycle, joystick, sprite cache, fixed substeps,
  overlays. Reports wins (`onMapWon`, `onTutorialCompleted`); does not write
  camp progress itself.
- `herd_navigation.dart`: cached visibility graph at expanded obstacle
  corners; followers detour by the shortest clear path. Uses the same 15-unit
  clearance as collision; rebuilt on map/viewport change.
- `herd_map.dart`: maps, normalized walls, terrain, traffic clock, rule text.
  `herd_route.dart`: suggested paths and four group anchors (guides only).
- `herd_map_painter.dart` / `herd_route_painter.dart`: scenery and
  footprints, reading the same rectangles as collision.
- `herd_scene.dart`: home and hazards; no rule mutations.
- `ui/screens/herd_screen.dart`: results, replay, app lifecycle.
  `ui/widgets/herd_map_select.dart`: scrolling region cards.

## Maps

Each map has its own rule file and painter. None of them costs lives except
the original patrol hits.

- Playground: wooden blocks, `HerdPatrol.loop` cars, bouncing ball
  (`herd_ball.dart`, pushes keep followers).
- Market (`herd_market.dart`): stealth. Vendor i watches lantern zone i;
  cats seen in a lit zone scatter (2.5 s cooldown).
- Desert (`herd_desert.dart`): `HerdHeat` (shade cools) and
  `HerdSandstorm` (2 s warning, 4.5 s gust every 16 s); walls shelter.
- Snow (`herd_snow.dart`): thin ice breaks above `HerdThinIce.safeLoad`;
  `chutes` are one-way lanes. Spawns avoid both.
- Grandma's house (`herd_grandma.dart`, map 5): cuckoo wakes sleepy cats,
  robot vacuums scatter. Special cats start here (`herd_traits.dart`:
  chubby, curious, sleepy, golden).
- Station (`herd_station.dart`, map 6): train track is solid except the
  open train; `HerdTrait.shy` hides at the horn.
- Farm (`herd_farm.dart`, map 7): pen gates open on pressure plates;
  geese scatter; `HerdTrait.sulky` never holds plates.

## Progress

- Maps unlock in order: `CampState.markHerdMapCleared` stores
  `mode:herd:cleared:<kind>` in `seenGuides`; the picker shows a lock and
  "QUA VÙNG N" until the previous map is won.
- `HerdMap.tutorial` is not in the picker. Only a finished tutorial writes
  `herdTutorialDone`; the picker offers Tập chơi for replays.

## Tuning and performance

- Tuning starts in `HerdRound`: `target`, `spacing`, `requiredCats` (8),
  speed, radii, score formula. Keep spawn anchors reachable and off traffic.
- `renderHerdBackground` rasterises the base map once per map/viewport (DPR
  capped at 3). Base painters never read round state. Text goes through
  `herdLabel`; ice cracks are cached; darkness uses rects, not blur.
