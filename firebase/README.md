# Firebase Realtime Database setup

Project: `meow-shelter-428db` (Singapore).

1. Open Firebase Console > Realtime Database > Rules.
2. Replace the editor contents with `database.rules.json` in this folder.
3. Click Publish. Anonymous Authentication must already be enabled.
4. Install the new APK on two devices and open the fishing cat-selection screen.
5. Tap the social button below Home to open the destination dialog. Copy device A's seven-character world code, then
   choose a cat on A to start its home world. On B open the map/code dialog, enter A's code, close it
   and choose a cat. The host must be actively fishing for a guest to enter.
6. Move each boat, go ashore and test airplane mode. Leave via Home and reopen
   fishing with the guest-code input empty to start your own world again. The lobby alone does not
   announce a live host/player; home play also works offline.

Alternatively, with Firebase CLI authenticated to the project:

```powershell
firebase deploy --only database --project meow-shelter-428db
```

The rules were verified against the local Database Emulator. They allow only
signed-in users to resolve specific world codes, owners to edit their own world,
and players to write their own validated live state. They do not upload fish,
coins, quest progress or inventory. This release uses possession of a world code
as the visit permission. The eight-player admission check is client-side; do not
use it as a hard server-side capacity limit. Sharing a network-controlled boat,
indoor multiplayer rendering and voice chat are not included in this release.

## Extending content

Rules accept bounded content IDs (1-64 letters/digits/underscores/hyphens,
starting with a letter), frame indices 0-255, signed coordinates within
+/-1,000,000 and positive integer map versions up to 2,147,483,647.
Adding breeds, boats, animations, locations or expanding the map within these
bounds does not require publishing new rules. Clients still need the matching
assets and gameplay code; older clients ignore unknown content rather than load
arbitrary assets. Current-map coordinate checks derive from FishingRiver size.
Increment FishingWorld.mapVersion for incompatible map changes: a host updates
its own world version, and visitors must match it. These checks validate message
shape and ownership, not legal movement, inventory or anti-cheat.

## Stable presentation extension

Publish this baseline Rules file once. World metadata and each player's live
state now support an optional `display` field: a JSON object encoded as a string,
limited to 8,192 characters. Put new visual properties inside that object (for
example environmental effects, decorations, boat skins or emotes). Adding keys
inside `display` requires game code updates, not another Rules deployment.

World time/weather now use `worlds/{ownerUid}/display`, containing an
`environment` object with `shiftMs` and `sunnyUntil`. The client validates the
known environment fields after decoding; unknown display properties are kept
when the host republishes its environment. A guest only reads the host display.
New clients can still read legacy `worlds/{uid}/environment`; its older Rules
are retained for migration. Install the updated APK on devices using the new
format. New trips get 08:00 and five minutes of sun, existing clocks are retained.

Only owners write their own world; players write only their own presence. Core
position/type/freshness checks stay in Rules. New top-level fields and arbitrary
paths remain denied. Malformed display JSON is ignored by clients. Display data
is cosmetic: never derive coins, rewards, inventory, trade confirmation or boat
control authority from it. New shared permissions (trading, shared boat control,
world storage) still require explicit Rules and an authoritative implementation.

Online shared sleep uses `display.sleep` under the existing presentation envelope.
All active players must be lying asleep before the owner advances to morning;
waking before the dawn point cancels it. Guests never write the owner's clock.
This feature needs the existing display-enabled baseline Rules, not new Rules.
