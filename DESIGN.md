# Meow Shelter – Design

Shared foundation for menus, dialogs, overlays and HUD labels. Tokens live in
`lib/ui/design.dart`; `main.dart` installs `DS.theme` once. Prefer the shared
components below before creating another decoration or button implementation.

## Foundation and components

All measurements below are design units, scaled by `UiScaleBox`.

| Group | Tokens / rule |
| --- | --- |
| Spacing | `space2` 2, `spaceXs` 4, `spaceSm` 8, `spaceMd` 12, `spaceLg` 16, `spaceXl` 24, `space2xl` 32 |
| Radius | `radiusXs` 6, `radiusSm` 8, `radiusMd` 12, `radiusControl` 14, `radiusLg` 16, `radiusCard` 20, `radiusXl` 24 |
| Border | `borderThin` 1, `borderSubtle` 1.5, `borderControl` 2, `borderRaised` 2.5, `borderStrong` 3 |
| Icons | `iconSm` 16, `iconMd` 20, `iconLg` 24, `iconXl` 32 |
| Controls | `controlHeight` 40, `compactHeight` 32; round/icon actions use `touchTarget` 48 |
| Raised depth | `buttonDepth` 4; home feature buttons use `featureDepth` 6 |
| Width limits | `dialogWidth` 600, `wideDialogWidth` 860, `resultWidth` 500; always constrain to available space |
| Motion | `pressDuration` 70 ms, `fastDuration` 120 ms, `transitionDuration` 220 ms, `overlayDuration` 260 ms |
| Elevation | `cardShadow` for panels, `controlShadow` for raised controls |

`DS.theme` also defines Material buttons, icon buttons, dialogs, chips,
tooltips, switches, sliders and progress indicators. Standard controls inherit
these defaults; use `DS.primary`, `DS.secondary` or `DS.outlined` for action roles.
Keep local overrides limited to layout and meaningful domain colours.

| Component | File | Purpose |
| --- | --- | --- |
| `GamePressable` | `widgets/game_pressable.dart` | Raised rectangular/circular action; shared sound, ripple, focus, keyboard input and pressed animation |
| `RoundGameButton` | `widgets/game_pressable.dart` | Round action with tooltip; also exported from `return_home_buttons.dart` for existing callers |
| `RoundButton` | `widgets/round_button.dart` | Existing icon/glyph shortcut for home and other round actions |
| `GamePanel` | `widgets/game_surfaces.dart` | Cream card or inset section (`inset: true`) |
| `GameDialog` | `widgets/game_surfaces.dart` | Common modal surface, border, safe inset and maximum width |
| `GameDialogHeader` | `widgets/game_surfaces.dart` | Title, optional icon, labelled close action |
| `showGameDialog` | `widgets/game_surfaces.dart` | Opens a modal with the shared scrim |
| `GameStat` | `widgets/game_surfaces.dart` | Icon, value and caption used by result screens |
| `GameBadge` | `widgets/game_surfaces.dart` | Compact status label with tinted background |

Paths in this table are relative to `lib/ui/`. Components own appearance and
input feedback; screens own layout, navigation and scrolling. `GameDialog`
does not add scrolling automatically: short settings fit directly, while
collections use an explicitly constrained scrollable body.

```dart
showGameDialog<void>(
  context: context,
  builder: (context) => GameDialog(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      GameDialogHeader(
        title: 'TIÊU ĐỀ',
        onClose: () => Navigator.of(context).pop(),
      ),
      const SizedBox(height: DS.spaceMd),
      const GamePanel(inset: true, child: Text('Nội dung', style: DS.bodyText)),
    ]),
  ),
);
```

### Interaction states

- Enabled actions receive a callback; disabled actions use `onPressed: null`.
  `GamePressable` uses muted face/border/text and never calls a disabled action.
  Avoid hard-coded child colours if the child should inherit disabled colours.
- Pressed controls sink by their configured depth. Focus, hover, keyboard
  activation and semantics come from Material/InkWell. Give icon-only actions
  a tooltip. Reduced-motion mode disables the raised-button movement.
- Selected items use `selectedFill` with the normal accent border; dark cat
  selection panels use `selectionBackdrop`, `selectionSurface` and
  `selectionBorder`. Keep selection distinct from disabled state.
- During asynchronous work, disable the triggering action and retain the
  screen's progress feedback to prevent duplicate requests.
- Aiming skills, joystick and hold-to-reel controls retain their specialised
  gestures. Reuse tokens, but do not replace those gestures with a tap button.

### Extending a screen

1. Choose a shared surface and action component; use `DS.theme` defaults for
   ordinary Material controls.
2. Use the typography scale, semantic colours and spacing/radius tokens.
   Add a token only for a genuinely shared role, not every illustration value.
3. Keep game rules and persistence outside these widgets. Pass callbacks and
   display values into components.
4. Check the landscape sizes listed below, text scale 1.15, disabled actions,
   long labels and close/home navigation.

Scene painting, logo geometry, sprite sizes, rarity/breed colours and map
palettes remain domain artwork. Their coordinates and colours do not need to
follow interface spacing or surface tokens. Shared HUD typography does.

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

Additional semantic colours: `surfaceRaised` for inset content,
`surfaceMuted` for quiet areas, `surfaceGlass` for translucent cards,
`borderSoft`/`borderMedium` for internal dividers, `success`, `danger` and
`info` for status, and `selectedFill` for selected items. Mode tiles and badges
share `modeFishing`, `modeReturnHome`, `modeRescue`, `modeHerd`, `modeCamp`.

Text is always bold: titles `w900`, secondary `w600` or regular. Small caps
labels use letter spacing 1–1.5.

## Typography

All interface text uses the scale in `lib/ui/design.dart`. These are **design
units**, not physical pixels; `UiScaleBox` applies device scaling and the
system text scale (up to 1.15×). Do not multiply font sizes by screen width.

| Role | Token | Size | Shared style |
| --- | --- | --- | --- |
| Screen/dialog/result title | `DS.fontTitle` | 16 | `DS.title` |
| Card/section heading, selected cat name | `DS.fontHeading` | 14 | `DS.headingText` |
| Body, descriptions, menu names | `DS.fontBody` | 12 | `DS.bodyText` |
| Button label | `DS.fontButton` | 12 | `DS.buttonText` |
| Hint, subtitle, HUD label | `DS.fontCaption` | 10 | `DS.captionText` |
| Compact badge, overline, small cooldown | `DS.fontMicro` | 9 | `DS.microText` |
| Timer, count, skill countdown | `DS.fontValue` | 16 | `DS.valueText` |
| Main home action, highlighted reward | `DS.fontDisplay` | 18 | `DS.displayText` |

`MaterialApp` installs `DS.theme` (including `DS.textTheme`) so text without an explicit size follows
the same scale. `DS.primary` and `DS.secondary` both use `DS.buttonText`.
Canvas HUD labels and world captions use these tokens as well.

Use a shared style directly, or preserve the widget's colour/weight while
referencing a size token:

```dart
const Text('CÀI ĐẶT', style: DS.title);

const TextStyle(
  fontSize: DS.fontCaption,
  color: DS.cream,
  fontWeight: FontWeight.w800,
);
```

Never add a new numeric `fontSize` to a screen. Update the relevant token here
and in `design.dart` when changing the scale. Prefer wrapping or ellipsis for
long text rather than introducing an extra font size for one screen.

Logo lettering and drawn symbols are artwork, not UI text:
`DS.fontLogo` (60), `DS.fontLogoCaption` (18), `DS.fontSymbol` (28).
The fish journal's mystery mark scales with its illustration. These sizes
must not be used for normal labels or titles.

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
- Top bar: round home button, title "CHỌN MÀN" in cream `DS.fontTitle` with an
  ink text shadow, total stars on the right (`earned/levels × 3`).
- Body: a horizontal `ListView` of chapter cards using the shared spacing scale.

### Chapter card

- Width 230, height fills the screen; padding uses the shared spacing scale.
- Fill cream, radius 20, wood border 3 px, shadow `#55000000` blur 8 offset y 4.
- Header row:
  - Cat avatar: 46 px circle, `#FFE3B0` fill, wood border 2 px, showing the
    **first idle frame** of the breed's sprite sheet (sheets are 6 frames
    wide; crop with `OverflowBox` aligned left).
  - "CHƯƠNG n" label (`fontCaption`, label brown), chapter title
    (`fontHeading`, ink), and "Breed · trait" from `CatCatchRule`
    (`fontBody`, soft brown). The last chapter
    shows "Đủ 5 giống mèo". All lines are single line with ellipsis.
- Level rows below the header, 3 px vertical gap, up to 46 px tall each.
  Rows are `Flexible` so they shrink on short screens instead of overflowing.

### Level row

| State | Fill | Border | Number badge | Right side |
|---|---|---|---|---|
| Playable | Gold | Gold edge, 2 px | Ink circle, cream number | 3 stars (cream = earned) |
| Locked | Muted fill | Muted border | `#8E8270` circle | Lock icon |

- Radius 14, ink ripple through `InkWell`; locked rows are not tappable.
- Text block: level name (`fontBody`, `w900`) and a detail line (`fontCaption`): "Màn tập" for
  tutorials, otherwise "`n` mèo · `t`s". Wrapped in a scale-down `FittedBox`
  so long names never overflow.

### Behaviour

- Level rows share the card height (46 on phones, up to 62 on tall
  screens); see Responsive layout.
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
│  [▦ CHỌN MÀN]             └───────────┘ └───────────┘      │
│                            ┌───────────┐ ┌───────────┐      │
│                            │ 🐾 CỨU HỘ │ │ 🏠 TRẠI   │      │
│                            └───────────┘ └───────────┘      │
│ (⚙)                        [ TRẠI MÈO ]                     │
└────────────────────────────────────────────────────────────┘
```

- Content is laid out on a fixed 820×340 design-unit board inside a
  scale-down `FittedBox`, 16 units safe padding, so it fits every landscape
  screen (see Responsive layout).
- Left half: game logo, the main play button, then "CHỌN MÀN".
  Right half: five mode tiles in two columns, 12-unit gaps.
- Settings is a small gear in the bottom-left safe area, with a 48-unit touch
  target. Home does not show coins; the balance is inside the camp shop.

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
| BẮT ĐẦU | 240×52 | `#FFB83F` | `#C0731F` | Play icon 28 + `fontDisplay`, `w900`, ink |
| CHỌN MÀN | 148×42 | cream | `#B98A55` | Grid icon 18 + `fontButton`, `w900`, ink |

"BẮT ĐẦU" opens the first level that has no stars yet.

### Mode tile

- 168×88 pressable, solid mode colour, padding 8/10.
- Icon (30 units) and title are centred as one block. The icon uses
  `onColor: true` (translucent white badge and a white symbol).
- Title uses `DS.fontButton`, white, `w900`, with one line and ellipsis.
  Mode tiles have no description line.

| Mode | Colour | Icon |
|---|---|---|
| CÂU CÁ | `#3E9FB0` | Fish |
| MÈO VỀ NHÀ | `#5E9A48` | Winding road with a flag |
| CỨU HỘ VÔ HẠN | `#E0703F` | Paw |
| DẪN ĐÀN VỀ NHÀ | `#8277B2` | Three cats |
| TRẠI MÈO | `#C85A7C` | House with a heart |

Each mode must have its own icon; never reuse the house for two modes.

### Background

`HomeBackgroundPainter`, drawn in a 600-high space scaled to the screen:
dusk sky gradient `#6E6BB0 → #B08DC4 → #F2B6A0 → #FFD9A0`, small stars, a
setting sun behind three layered hills, and a dirt path with paw prints that
leads to a red-roofed shelter in the bottom right. Keep details near the
edges so the logo, buttons and tiles always sit on calm areas.
## Result card stars

The round result card shows three 30 px stars under the title when a level is
won (not in infinite mode): earned in star colour, missing in star-empty.

## Responsive layout

The game runs on every landscape screen, from small phones to 4:3 tablets.
Sizes are never tied to physical pixels.

### Design units

- The app is designed on a reference screen **375 units tall**
  (`UiScale.designHeight`, a typical phone held sideways).
- `UiScaleBox` (`lib/ui/responsive.dart`), installed once in `main.dart`
  through `MaterialApp.builder`, scales every route, dialog, overlay and
  Flame game canvas uniformly:
  `scale = shortestSide / 375`, clamped to **0.8–2.0**.
- Dimensions written in widgets and painters (`width: 48`,
  `fontSize: DS.fontBody`, `EdgeInsets.all(12)`, a cat 80 wide) are **design units**.
  On a 375-tall phone it equals 1 px; on a tablet it grows; on a small phone
  it shrinks a little.
- Inside the box, `MediaQuery.sizeOf(context)` is already in design units:
  height is always about 375–470 and width about 500–960 depending on the
  aspect ratio (4:3 tablet ≈ 512, phone ≈ 800, 21:9 phone ≈ 880).
- System font size is honoured up to **1.15×** (`UiScale.maxTextScale`).
- `UiScale.of(context)` returns the current factor; it is rarely needed.

### Rules for new UI

1. Write sizes as plain design units. Do not multiply by the screen size or
   device pixel ratio yourself, and do not read `View`/`window` sizes
   directly. Use `MediaQuery` or `LayoutBuilder`, which are already scaled.
2. Every layout must fit widths from **500 to 960** units at a height of
   **375**. Long rows use `Flexible`/`Expanded`, and groups that may not fit
   go inside `FittedBox(fit: BoxFit.scaleDown)`. Never let a `Row` of fixed
   chips run off the edge.
3. Fixed-size boards (home hero, result card) sit inside a scale-down
   `FittedBox` so they shrink on narrow screens.
4. Things that should use extra height (level rows, panels) take a share of
   the available space with a min and max clamp, e.g. level rows are
   `available / 3.6 − 6`, clamped to 30–62.
5. Dialog widths come from the screen width with a clamp
   (e.g. `(width − 48).clamp(320, 780)`), and inner columns take a share
   of that width instead of a fixed number.
6. Flame games read `size` (already in design units). Place things as
   fractions of `size`, or as design units from an edge (the joystick sits
   92 units from the bottom-left corner).

### Checking

Before finishing a screen, render it with `UiScaleBox` at these physical
sizes and confirm there is no overflow and nothing is hidden:

| Device | Physical size | Scale | Design-unit screen |
|---|---|---|---|
| Small phone | 640×300 | 0.8 | 800×375 |
| Phone | 844×390 | 1.04 | 811×375 |
| Wide phone | 960×411 | 1.1 | 876×375 |
| 4:3 tablet | 1024×768 | 2.0 | 512×384 |
| Tablet | 1280×800 | 2.0 | 640×400 |

## Lead the Herd mode

Home now uses a two-column, three-row mode grid with 168x88 tiles to fit the
820x340 board. Lead the Herd has its own three-cat badge and purple tile.
Its Flame field uses the shared joystick; intro and result use DS cards and
buttons. The HUD shows delivered cats, current chain, score and remaining
lives. Cat art comes from the existing idle/walk sprite sheets.
