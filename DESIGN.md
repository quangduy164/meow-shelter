# Meow Shelter – Design

Visual rules for the game's menus. The level select screen is the reference
style: new menu screens should reuse its colours, card shapes and states.

## Colour tokens

In code these live in `lib/ui/design.dart` as `DS` (colours, `DS.card`,
`DS.dialogShape`, `DS.primary` gold button, `DS.secondary` cream button,
`DS.title`, `DS.scrim`). Use them instead of hard-coded colours.

| Token | Hex | Use |
|---|---|---|
| Ink | `#5A3214` | Main text, number badges, icons on light surfaces |
| Cream | `#FFF4DA` | Card fill (`#F2FFF4DA` with transparency), text on dark |
| Wood border | `#B27A3E` | Card and avatar borders |
| Gold | `#FFC24D` | Playable buttons and rows |
| Gold edge | `#9A6028` | Border of playable rows |
| Star | `#FFC23D` | Earned stars on dark/neutral backgrounds |
| Star (on gold) | `#FFF4DA` | Earned stars inside a gold row |
| Star empty | `#55704019` | Missing stars |
| Muted | `#D9CDB8` fill, `#AA9C86` border, `#8E8270` text | Locked items |
| Label brown | `#B0703A` | Small caps labels such as "CHƯƠNG 1" |
| Soft brown | `#8A6446`, `#7A4A22` | Secondary text |
| Backdrop dim | `#660F371E` | Layer over the garden painting |

Text is always bold: titles `w900`, secondary `w600` or regular. Small caps
labels use letter spacing 1–1.5.

## Level select screen

File: `lib/ui/screens/level_select_screen.dart`

### Layout

```
┌────────────────────────────────────────────────────────────┐
│ (←)  CHỌN MÀN                                    ★ 6/54    │  top bar
│ ┌──────────────┐ ┌──────────────┐ ┌──────────────┐  ···   │
│ │ (cat) CHƯƠNG 1│ │ (cat) CHƯƠNG 2│ │              │        │  chapter cards,
│ │  Sân trước    │ │  Vườn hoa     │ │              │        │  scroll sideways
│ │  Mèo cam·Ham ăn│ │ Himalaya·...  │ │              │        │
│ │ [1 Làm quen ★★★]│ │ [5 ...    🔒]│ │              │        │
│ │ [2 Bữa trưa ★★☆]│ │ [6 ...    🔒]│ │              │        │
│ └──────────────┘ └──────────────┘ └──────────────┘        │
└────────────────────────────────────────────────────────────┘
```

- Background: `ShelterGardenPainter` covered by the backdrop dim colour.
- Top bar: round back button, title "CHỌN MÀN" in cream 24 `w900` with an ink
  text shadow, total stars on the right (`earned/levels × 3`).
- Body: a horizontal `ListView` of chapter cards, 16 px side padding, 14 px gap.

### Chapter card

- Width 230, height fills the screen; padding 12/10.
- Fill cream, radius 20, wood border 3 px, shadow `#55000000` blur 8 offset y 4.
- Header row:
  - Cat avatar: 46 px circle, `#FFE3B0` fill, wood border 2 px, showing the
    **first idle frame** of the breed's sprite sheet (sheets are 6 frames
    wide; crop with `OverflowBox` aligned left).
  - "CHƯƠNG n" label (11, label brown), chapter title (18, ink), and
    "Breed · trait" from `CatCatchRule` (12, soft brown). The last chapter
    shows "Đủ 5 giống mèo". All lines are single line with ellipsis.
- Level rows below the header, 3 px vertical gap, up to 46 px tall each.
  Rows are `Flexible` so they shrink on short screens instead of overflowing.

### Level row

| State | Fill | Border | Number badge | Right side |
|---|---|---|---|---|
| Playable | Gold | Gold edge, 2 px | Ink circle, cream number | 3 stars (cream = earned) |
| Locked | Muted fill | Muted border | `#8E8270` circle | Lock icon |

- Radius 14, ink ripple through `InkWell`; locked rows are not tappable.
- Text block: level name (14 `w900`) and a detail line (11): "Màn tập" for
  tutorials, otherwise "`n` mèo · `t`s". Wrapped in a scale-down `FittedBox`
  so long names never overflow.

### Behaviour

- A level unlocks when the previous level has at least one star
  (`levelUnlocked` in `levels.dart`).
- Best stars per level are stored in `CampState.levelStars`.
- The screen refreshes after returning from a round, so new stars and unlocks
  appear immediately.

## Home screen

File: `lib/ui/screens/home_screen.dart`

### Layout

```
┌────────────────────────────────────────────────────────────┐
│  (paw) MEOW                ┌───────────┐ ┌───────────┐      │
│        SHELTER             │ 🐟        │ │ 🚩        │      │
│  [ ▶  BẮT ĐẦU        ]     │ CÂU CÁ    │ │ MÈO VỀ NHÀ│      │
│  [▦ CHỌN MÀN] (● 120)      └───────────┘ └───────────┘      │
│                            ┌───────────┐ ┌───────────┐      │
│                            │ 🐾 CỨU HỘ │ │ 🏠 TRẠI   │      │
│                            └───────────┘ └───────────┘      │
└────────────────────────────────────────────────────────────┘
```

- Content is laid out on a fixed 820×340 canvas inside a scale-down
  `FittedBox`, 16 px safe padding, so it fits every landscape screen.
- Left half: game logo, the main play button, then "CHỌN MÀN" and the coin
  chip side by side. Right half: a 2×2 grid of mode tiles, 12 px gaps.
- Coins refresh every time the player returns to this screen.

### Pressable button (shared shape)

Every home button is the same "game button": a coloured face on a darker
base that sinks when pressed.

- Radius 20, base depth 6 px; on press the face moves down 6 px in 70 ms.
- Face: vertical gradient from the colour lightened 18% (top) to the colour
  (bottom), border 2.5 px in the shade colour.
- Base: shade colour with shadow `#40000000` blur 8 offset y 4.
- Shade colour is the face colour mixed 35% toward black, unless set below.

| Button | Size | Face | Shade | Content |
|---|---|---|---|---|
| BẮT ĐẦU | 300×64 | `#FFB83F` | `#C0731F` | Play icon 34 + text 24 `w900`, spacing 2, ink |
| CHỌN MÀN | 172×46 | cream | `#B98A55` | Grid icon 22 + text 16 `w900`, ink |

"BẮT ĐẦU" opens the first level that has no stars yet.

### Mode tile

- 204×146 pressable, solid mode colour, padding 14/12/12/12.
- Top left: mode icon 54 px drawn with `onColor: true` (translucent white
  badge `#33FFFFFF` with a white symbol).
- Bottom: title in white 18 `w900` (spacing .5), one-line description in
  `#E6FFFFFF` 12.5 `w600`. Both single line with ellipsis.

| Mode | Colour | Icon | Description |
|---|---|---|---|
| CÂU CÁ | `#3E9FB0` | Fish | Sưu tập cá làm mồi |
| MÈO VỀ NHÀ | `#5E9A48` | Winding road with a flag | Né chướng ngại về nhà |
| CỨU HỘ VÔ HẠN | `#E0703F` | Paw | Cứu mèo không giới hạn |
| TRẠI MÈO | `#C85A7C` | House with a heart | Chăm mèo, trang trí sân |

Each mode must have its own icon; never reuse the house for two modes.

### Coin chip

46 px tall pill, fill ink at 80% (`#CC5A3214`), coin icon `#FFC94A` 24 px, amount in
cream 18 `w900`.

### Background

`HomeBackgroundPainter`, drawn in a 600-high space scaled to the screen:
dusk sky gradient `#6E6BB0 → #B08DC4 → #F2B6A0 → #FFD9A0`, small stars, a
setting sun behind three layered hills, and a dirt path with paw prints that
leads to a red-roofed shelter in the bottom right. Keep details near the
edges so the logo, buttons and tiles always sit on calm areas.
## Result card stars

The round result card shows three 30 px stars under the title when a level is
won (not in infinite mode): earned in star colour, missing in star-empty.

## Responsive checks

Menus are landscape only. Check every new menu at least at 740×340 (small
phone) and 1280×600 (tablet): no overflow, text on one line, nothing hidden
behind cards.