# Cluvie Design Tokens — v1.1 (Refined Cinematic, dark only)

Source of truth for `lib/core/theme/*`. Any Dart token must match this file; change here first.
v1.1 applies review round 1 blocking fixes B1–B8 (see `design/review/round-1.md`).

## Rules (read first)
1. **Gold budget.** Per screen, gold may appear on: (a) **one** content owner — the screen's primary CTA *or* its key data highlight, never both; (b) the active nav tab (system chrome); (c) the logo mark; (d) the focus ring. Everything else that needs emphasis uses purple (`purpleContainer`, `purpleBadge`, `purpleText`) or white/glass. Secondary CTAs on cards are glass or white, not gold.
2. **Purple carries identity.** Tags, badges, the centre "+" action, own chat bubbles, selected chips and poll leaders use the purple tokens. Purple should be visible on every screen.
3. **Muted text only on flat surfaces.** `textMuted` is allowed only on `bg`, `surface`, `surfaceRaised`. On any tint, glass, scrim or fill use `textSecondary` or higher.
4. **Every fill has a defined "on" colour** (table below). No text on a fill without one.
5. **Touch targets ≥ 48dp** (`minTouch`), enforced by button/icon-button themes; visual size may be smaller with padded hit area.

## Color

### Surfaces (layered, darkest → lightest)
| Token | Hex | Use |
|---|---|---|
| `bg` | `#0A0812` | Scaffold background, under posters |
| `surface` | `#14101F` | Cards, list rows, sheets |
| `surfaceRaised` | `#1D1730` | Inputs, chips at rest, nested cards, bubbles (others) |
| `surfaceGlass` | `#14101F` @ 88% + blur σ 20 (+ `border`) | Nav bar, app bar on scroll. Worst case (white content behind): `textSecondary` 5.5:1. **Only** nav + app bar get real blur (wrap in one `BackdropGroup`); other "glass" chips/buttons use `glassFlat`. |
| `glassFlat` | `#FFFFFF` @ 8% over a known dark surface, no blur | Secondary buttons, tags on scrimmed posters |
| `border` | `#FFFFFF` @ 8% | Hairline card borders (decorative only) |
| `borderStrong` | `#FFFFFF` @ 14% | Selected outlines on glass (decorative, never the only state cue) |
| `borderInput` | `#6A6380` | Resting input border — 3.05:1 on raised, 3.30:1 on surface (WCAG 1.4.11 ✓) |
| `focusRing` | `#FFD27D`, 2px, 2px offset | All focusable controls — 13:1 |
| `scrimBottom` | `bg` 0% @ 35% → 85% @ 55% → 96% @ 100% | Posters: any text block must start where alpha ≥ 0.85 (worst-case white poster → `textPrimary` 12.3, `textSecondary` 5.6) |
| `scrimTop` | `bg` 70% → 0% over top 120dp | Behind status bar, logo, icon buttons on posters |

### Text
| Token | Hex | On bg | On surface | On raised | Rule |
|---|---|---|---|---|---|
| `textPrimary` | `#F5F3FA` | 18.1 | 17.0 | 15.7 | Titles, body |
| `textSecondary` | `#A8A3B8` | 8.1 | 7.7 | 7.1 | Supporting copy, metadata |
| `textMuted` | `#8F899F` | 5.9 | 5.6 | 5.1 | Timestamps, captions, placeholders (AA ✓) |
| `onGold` | `#14101F` | — | — | — | Text/icons on gold fills (13.1:1) |

### Brand & accent
| Token | Hex | Contrast (on surface) | Rule |
|---|---|---|---|
| `gold` | `#FFD27D` | 13.1 | **Primary.** CTAs, active nav, selected states, winner. Use sparingly — one gold focal point per screen. |
| `goldDeep` | `#F2B544` | 10.2 | Gradient end for primary CTA, pressed state |
| `purple` | `#7C5CFF` | 4.3 ✗ text | **Fills & glows only** (badges bg, progress tracks, ambient glow). Never body text; never white text on it. |
| `purpleText` | `#A48BFF` | 6.9 | Purple used as text/links/mentions/tags |
| `purpleDeep` / `purpleContainer` | `#2E1F4A` | — | **The original brand purple, now a container colour**: tags, selected chips, own chat bubbles, poll-leader bar, "Pinned"/"Host" badges. Text on it: `textPrimary` 13.5, `purpleText` 5.5, `textSecondary` 6.1 |
| `purpleBadge` | `#6545E0` | — | Solid purple fills that carry text: centre "+" button, count badges, TONIGHT/LIVE-style pills. White text 6.0:1 |

### "On" colours (text/icon on fills)
| Fill | On colour | Ratio |
|---|---|---|
| `gold`, `goldDeep` | `onGold #14101F` | 13.1 / 10.2 |
| `purpleBadge` | `#FFFFFF` | 6.0 |
| `purpleContainer` | `textPrimary` / `purpleText` | 13.5 / 5.5 |
| `success`, `error`, `warning` | `onSemantic #14101F` | 9.1 / 6.7 / 11.5 |
| gold tint ≤16% (bars, own bubble) | `textPrimary`, `textSecondary` | ≥5.9 |
| `purple #7C5CFF` | **none — no text allowed** | — |

### Semantic
| Token | Hex | On surface |
|---|---|---|
| `success` | `#4DC8B5` | 9.1 |
| `error` | `#FF6B6B` | 6.7 |
| `warning` | `#FFC107` | 11.5 |

### Gradients
- `goldGradient`: `#FFD27D → #F2B544`, top-left → bottom-right — primary buttons only.
- `brandGlow`: radial `#7C5CFF` @ 35% → transparent — ambient light behind heroes / splash / empty states.
- `posterScrim`: linear top→bottom `bg@0%` (40%) → `bg@92%` (100%).

## Typography
Bundled locally in `assets/fonts/` (no runtime fetch).

- **Display / headings: Sora** (600, 700, 800). Tight tracking at large sizes.
- **Body / UI: Plus Jakarta Sans** (400, 500, 600, 700).
- *Alternative shown on mood board:* Clash-like geometric display → **Space Grotesk** + **Inter**.

| Style | Font | Size/Line | Weight | Tracking |
|---|---|---|---|---|
| `display` | Sora | 40/44 | 800 | -1.2 |
| `h1` | Sora | 28/34 | 700 | -0.6 |
| `h2` | Sora | 22/28 | 700 | -0.3 |
| `h3` | Sora | 18/24 | 600 | -0.2 |
| `title` | Jakarta | 16/22 | 700 | 0 |
| `body` | Jakarta | 15/22 | 400 | 0 |
| `bodySm` | Jakarta | 13/18 | 500 | 0 |
| `label` | Jakarta | 14/18 | 600 | 0.1 |
| `caption` | Jakarta | 12/16 | 500 | 0.1 |
| `overline` | Jakarta | 11/14 | 700 | 1.4, UPPERCASE |

Default color: `textPrimary` for display→body, `textSecondary` for bodySm/caption, `textMuted` for overline unless accented.

## Spacing (4-pt)
`xxs 2 · xs 4 · sm 8 · md 12 · lg 16 · xl 24 · xxl 32 · xxxl 48`
Screen gutter: **20**. Section gap: **28**. Card padding: **16**.

## Radius
`sm 8 · md 12 · lg 16 · xl 24 · pill 999`
Cards `lg`, posters `md`, sheets `xl` (top), buttons & chips `pill`, nav bar `xl`.

## Touch
`minTouch` **48dp**. Buttons: height md 48, sm 40 visual with 48 hit area. Icon buttons 44 visual / 48 hit. Text links ("See all") get 48 hit via padding.

## Elevation
No Material shadows on dark. Depth = surface step + border + optional glow:
- `glowGold`: `#FFD27D` @ 35%, blur 24, y 8 — primary CTA, active nav item.
- `glowPurple`: `#7C5CFF` @ 30%, blur 40 — hero ambient.
- `shadowFloat`: black @ 50%, blur 30, y 12 — floating nav, sheets.

## Motion
| Token | Value | Use |
|---|---|---|
| `instant` | 120ms | Press feedback, toggles |
| `quick` | 220ms | Chips, icon swaps, nav pill slide |
| `standard` | 360ms | Page transitions, sheets, cards entering |
| `slow` | 600ms | Hero reveals, progress fills, countdown |
| `stagger` | 40ms | Per-item delay in lists (cap 8 items) |
| `easeOut` | `Curves.easeOutCubic` | Default enter |
| `emphasized` | `Cubic(0.2, 0, 0, 1)` | Hero/sheet/page |
| `spring` | `SpringDescription(mass 1, stiffness 400, damping 28)` | Nav "+", like pop |

Principles: (1) motion explains — something moves only because it came from / goes somewhere; (2) one hero motion per screen; (3) press = scale 0.97 + haptic.light; (4) respect reduced motion.

**Reduced motion** (`MediaQuery.disableAnimationsOf(context)`), single helper `AppMotion.of(context)` returns zeroed durations. Each mechanism handled explicitly:
- Implicit/explicit animations & `flutter_animate`: duration 0, no stagger (`Animate` gets `.animate(autoPlay: !reduce)` or effects skipped).
- Springs (nav "+", like pop): replaced by instant state change.
- Page transitions: fade 0ms (theme `PageTransitionsTheme` swaps to a no-op builder).
- `Hero`: disabled via `HeroMode(enabled: !reduce)`.
- Confetti (`ClConfetti` painter): not shown; final state only.
- Skeleton shimmer: static `surfaceRaised` blocks.
- Haptics still fire.

## States
| State | Treatment |
|---|---|
| Focus | `focusRing` |
| Pressed | scale .97 + overlay white 6% |
| Disabled | content `textMuted`, fill `surfaceRaised`, no glow; never reduce opacity of text below AA — disabled text is exempt from AA but must still read as disabled |
| Error (field) | border `error` 2px, helper text `error`, leading icon; shake 220ms |
| Selected (chip/segment) | `purpleContainer` fill + `purpleText` label + check icon (not colour alone) |
| Loading | shape-matched skeleton on `surfaceRaised` |
| Empty | illustration + title + one CTA |
| Error (screen) | icon + plain-language message + Retry |
| Toast | floating `surfaceRaised` pill, 12dp from nav, icon + text, 3s |
| Sheet | `surface`, top radius 24, drag handle 36×4 `borderStrong`, max 90% height |
| Composer | `surfaceGlass` bar pinned above keyboard (`viewInsets`), field `surfaceRaised`, send = `purpleBadge` circle 44dp |

## Iconography
- **Phosphor** (`phosphor_icons` fork, Flutter 3.43+ compatible). Regular at rest, **Fill** when active/selected. Duotone for empty-state glyphs. **Pin exact version** (`3.0.1`); all icons go through one `AppIcons` map so a swap to bundled SVGs is a one-file change if the fork goes stale.
- Inactive nav tabs keep their label (small, `textSecondary`) — not icon-only.
- Sizes: 20 (inline), 24 (nav/actions), 32 (feature), 56 (empty state).
- Custom SVGs for brand-specific glyphs: popcorn, ticket, clapper, reel — same 1.5px stroke, round caps, 24 grid.

## Illustration
Line-art, 1.5–2px stroke `textSecondary`, single `gold` accent shape, sitting on a soft `brandGlow`. No full-color scenes.
