# Online fishing

Online is an optional visual layer over the offline game. Fish, coins,
quests and daily rewards stay personal and local; nothing here can award them.

## Files

- `firebase_session.dart`: Android-only Core/Auth/RTDB start in the
  background after `runApp`; anonymous login, shared retry future. Failure
  never blocks offline play.
- `fishing_world_directory.dart`: room codes (7 chars), home-code
  reservation by transaction, world metadata, destination lookup. Starts no
  timers or subscriptions.
- `fishing_world.dart`: live presence, admission (8 players, client-side),
  room switching, environment/sleep sync, epochs, disposal.
- `fishing_presence_gate.dart`: decides when to send the local snapshot.
- `fishing_peer.dart`: validated display-only snapshot and `FishingPeer`
  interpolation. `fishing_arrivals.dart`: join notices.
- `fishing_sleep.dart`: shared bedtime. `fishing_chat.dart`: room chat.
  `visual_state.dart`: bounded `display` JSON envelope.
- Rules: `firebase/database.rules.json` (deploy before new fields work).

## Data layout

- `worlds/{uid}`: code, `mapVersion`, `hosts/{connection}`, `display`.
- `worldCodes/{code}` -> uid.
- `sessions/{world}/players/{uid}/{connection}`: one snapshot per connection.
- `sessions/{world}/chat`: messages.

Auth UID controls access; the local installation ID is metadata, never a
credential. Joining needs the same `mapVersion` and a live host.

## Presence

- Starts after choosing a cat; ends on exit or app suspension. Arm
  `onDisconnect().remove()` before publishing; new connection ID after each
  reconnect; ignore states older than 15 s. Losing the host or network
  returns a visitor home.
- Sending: at most one write in flight, decisions every 125 ms. Ignore sprite
  frame/stamp changes and movement under 3 units; send the exact final spot
  when stopping. Idle heartbeat 1 s. Alone in the room: one full state, then
  stamp-only every 5 s; a guest arrival forces a full snapshot.
- Never queue positions while disconnected or from frame loops.
- Receiving: listen to child events on `sessions/{world}/players` (one player
  per event), skip your own UID, and read the full roster once so existing
  players are not announced as arrivals.
- Remote cats animate locally; packets only carry state changes.
- Interiors (cabin, cave) are separate location values; remote cats are
  drawn outdoors only.

## Shared world

- Host publishes `display.environment` (clock shift, sunny deadline in server
  time) on entry/reconnect and after sleep, never per frame. Guests read it
  and never write world time.
- Shared sleep: the host starts a barrier when every fresh snapshot (<= 2.5 s)
  is asleep in the bedroom and rechecks before changing the clock once. Any
  waking player cancels it.
- Visitors never save their trip over the home trip.

## Chat

- Attached only after presence is acknowledged; detached on leave, room
  change, suspend, disconnect and disposal. Old-room events are ignored.
- Reads at most 51 messages, shows 50; history before joining is hidden.
- One send in flight; text single-line, max 120 code points; names max 40.
  Rules enforce membership, immutable messages, server time and a 1 s
  per-sender cooldown.
- Emoji-only messages show as head bubbles, text in the left feed; both
  expire after 6 s. Opening chat does not pause the world.

## Rules for changes

- `.info/serverTimeOffset` and `.info/connected`: use listeners or
  `once()`, never `get()`.
- Add cosmetic fields inside `display` (max 8,192 chars); do not add new
  top-level snapshot fields. Unknown display keys are preserved and ignored.
- Never sync inventory, rewards, quests, camera or physics.
- New shared authority needs explicit Rules.
