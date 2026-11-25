# Design review, round 4: Home feed

Commit reviewed: `0607cdf` on `feat/design-overhaul` ("feat(home): redesign the home feed"). Scope: `lib/features/home/presentation/home_screen.dart`, `test/home_screen_test.dart`, `test/helpers/real_fonts.dart`, the `test/auth_layout_test.dart` refactor, and how Home sits in the shell (`routes.dart`, `ClBottomNavBar`). Shared components (`ClPressable`, `ClPosterImage`, `ClSectionHeader`) are in scope where Home exposes a problem in them.

## Verdict

**Not ready to merge: 3 blocking findings.**

The redesign closes most of the audit's Home P0s:
- The QA toggle and the "tap section titles" hint are gone.
- "Join live" works, and the discussion cards are tappable.
- RSVP no longer opens the live room.
- There is no premature WINNER. The poll ranks by votes, ties go to the earliest suggestion, and the leader is purple.
- The demo poll no longer contradicts itself.
- The screen has one gold content owner (the hero CTA).
- The screen uses tokens and Cl* components almost everywhere.
- Bottom padding clears the floating nav.
- Reduced motion turns off parallax, stretch, entrances and bar fills.

Three problems remain, all on the hero, which is the first thing anyone sees on the default tab:
1. **Hero text sits on an under-scrimmed poster at 1.3× text size.** On 320 and 375 pt phones the block starts at scrim alpha 0.39. The glass "DRAMA · 2023" badge drops to 2.2:1 on a light poster, and the title starts at alpha 0.72. This is the same failure as round 3 B2.
2. **The logo wordmark and the bell are unreadable on a light poster.** The fixed 120dp `scrimTop` is mostly used up by the status bar. On a notched iPhone the wordmark and bell sit at alpha 0.26, which gives 1.7:1.
3. **The screen's only primary CTA is truncated at the default text size.** It reads "Watch pa…" on 320 and on 375×667 (iPhone SE), and again at 1.3× on 390.

Below those:
- The pull-to-refresh spinner is gold. Rule 1 names the refresh indicator explicitly.
- Each section header merges with its card into a single "button, header" node.
- Several destinations don't match their labels: the discussion cards, "Cast your vote", and the Everything Everywhere party.
- The screen has no loading or error state, and refresh is still a fake delay.
- The tests check that no exceptions are thrown, but not truncation, scrim, shell padding or semantics.

**Tool runs**
- `flutter analyze --no-fatal-infos`: 15 infos, 0 warnings, 0 errors. None are in `home_screen.dart` or the new tests. The baseline is the same as round 3.
- `flutter test`: 85 of 85 tests pass. That includes the 12 new tests in `home_screen_test.dart` and the refactored `auth_layout_test.dart`.

**How the layout was checked.** The layout claims come from a scratch widget test, deleted after use. It mounts `HomeScreen` inside the real `ClBottomNavBar` shell through a `ShellRoute`, loads the real fonts through `test/helpers/real_fonts.dart`, and sets `ClPosterImage.debugDisableNetwork = true` with the `path_provider` channel mocked. It renders at 320×568 and 375×667 (top inset 20) and at 390×844 (top 47, bottom 34), at 1.0× and 1.3× text, with reduced motion on and off.

For each run it records:
- Overflow exceptions, while scrolling top to bottom.
- `didExceedMaxLines` on every paragraph.
- The size of every `ClPressable` and `IconButton`.
- Each hero text line's position as a fraction of the poster height, converted to `scrimBottom` and `scrimTop` alpha. Contrast is then computed against a worst-case white poster.
- Every gold-coloured `Icon`, text, fill, gradient, border and `SvgPicture` in the tree.
- The gap between the last card and the nav.
- The `RefreshIndicator` value colour, mid-pull.
- A dump of the semantics tree.

No configuration overflowed. Under reduced motion, a frame sampled mid-fling looked misplaced. Once it settled, the layout matched the motion-on runs, so it is not a finding.

## Findings

Severity: **B** = blocking, **S** = should-fix, **N** = nit.

| id | sev | file:line | finding | concrete fix |
|---|---|---|---|---|
| B1 | **B** | `home_screen.dart:39` (hero height), `:230-247` (text block) | **The hero text block starts above the 0.85 scrim line at larger text.** The hero height is fixed: `0.58 × screen`, clamped to 420–540, plus the inset. It is 440 on 320 and 375 phones. The text block is bottom-anchored and grows with the text scale. Measured top of each line as a fraction of the poster height, with the scrim alpha there:<br>• **320×568 @1.3×:** "DRAMA · 2023" badge 0.44 (alpha **0.39**); title 0.52 (alpha **0.72**).<br>• **375×667 @1.3×:** the same values.<br>• **390×844 @1.3×:** badge 0.54 (0.81).<br>• **320 @1.0×:** badge 0.51 (0.69).<br>The glass badge (`glassFlat` is defined only "over a known dark surface") falls to **2.2:1** on a light poster at 1.3×, which fails AA. The title is 7.7:1 there, so it is still readable. It still breaks the tokens.md rule that "any text block must start where alpha ≥ 0.85". The purple "This week's pick" badge is opaque, so it is fine. | Tie the cover to the content, as in the round 3 B2 fix. Either put a `bg` panel or gradient behind the `Positioned` column that is at least 0.85 opaque from 24dp above the block's top, or grow `expandedHeight` with `MediaQuery.textScalerOf(context).scale(1)` so the block always starts below 55%. Add a test that asserts the badge's top fraction is ≥ 0.55 at 320×568 and 375×667 @1.3×. |
| B2 | **B** | `home_screen.dart:58-68`, `:229` (`ClScrim.both`); `cl_poster_image.dart:66-75`; tokens.md `scrimTop` | **The logo wordmark and the bell sit on almost bare poster.** `scrimTop` fades from 0.70 to 0 over a fixed 120dp measured from the top of the poster, and the status bar uses most of that. The toolbar's centre line falls at:<br>• y=48 with a 20dp inset: alpha 0.42, which gives **2.6:1** for the `textPrimary` "CLUVIE" wordmark (16.8dp, so it needs 4.5:1) on a white poster.<br>• y=75 with a 47dp inset (any notched iPhone): alpha 0.26, which gives **1.7:1**.<br>The bell's 8% `glassFlat` disc doesn't help. The glyph fails the 3:1 non-text minimum, and it is the only way to reach Notifications. The code follows the token exactly; the token is wrong for screens with a top inset. | Make the top scrim relative to the inset: height = `padding.top + kToolbarHeight + 24`, at least 0.85 opaque under the toolbar content and fading below it. Add a `topInset` parameter to `ClPosterImage`, or apply the scrim in `_Hero`. Update `scrimTop` in tokens.md to match. Alternatively, give the logo and the bell a `surfaceGlass` pill. Check that the wordmark reaches 4.5:1 on a white poster at 390×844. |
| B3 | **B** | `home_screen.dart:248-266`; `cl_button.dart:103-131` | **The primary CTA label is truncated at 1.0×.** Two `Expanded` buttons, each with 24dp side padding plus an icon, leave "Watch party" (90.8px wide) only **58px** at 320 and **85.5px** at 375×667. On screen it reads "Watch pa…". At 390 it fits at 1.0× but truncates at 1.3× (93 of 118px). "Discuss" also truncates at 320 @1.3×. This is the one gold action on the screen. | Below about 360dp of available width, or when the text scale is above 1.15, stack the two buttons vertically (a `Column`, CTA first). Or make "Discuss" a 48dp `ClIconButton` with a tooltip, so "Watch party" gets the whole row. A size-`sm` `ClButton` uses 16dp padding instead of 24, which also helps. Add a `didExceedMaxLines` assertion on both labels to the layout test. |
| S1 | S | `home_screen.dart:43-45` | **The pull-to-refresh spinner is gold.** `RefreshIndicator` takes its colour from `colorScheme.primary` (gold), not from `progressIndicatorTheme`. It was measured mid-pull as `#FFD27D`. Rule 1 lists the "refresh indicator" among the controls that are purple. Nine screens use `RefreshIndicator` this way, so this is app-wide, but Home is the one under review. | Pass `color: AppColors.purpleText, backgroundColor: AppColors.surfaceRaised` here. Then add a `ClRefreshIndicator` wrapper, or override the `colorScheme` locally, so every screen gets it, and extend the gold-budget test to pull and check the spinner. |
| S2 | S | `cl_pressable.dart:70`; `cl_section_header.dart:29`; seen through `home_screen.dart:202-210` | **Each section heading merges with its card into one node.** Neither `ClPressable`'s nor `ClSectionHeader`'s `Semantics` sets `container: true`, so both merge into the parent node. The dump (with motion on and off) shows a single node flagged `[button, header]`, labelled "Active poll / A24 Lovers · closes in 2 days / …every poll row… / 24 votes · 22 of 31 members". "Live now" and its card merge the same way. Heading navigation lands on a button. Activating the heading opens the vote screen, and the whole card is read as the heading. | Add `container: true` to the `Semantics` in `ClPressable` and in `ClSectionHeader`. Add a semantics test: "Active poll" is a header and not a button, and the poll card is a separate button whose label begins with the leader. |
| S3 | S | `home_screen.dart:476-483` | "Join live" uses `ClButtonVariant.purple`, a solid purple fill with `glowPurple`. That variant is not for card CTAs. The project rule, and `ClButton`'s own doc ("inverse — card CTAs (RSVP, Join)"), say card CTAs use `inverse` or `secondary`. The LIVE badge and the ring already carry the colour. | Use `variant: ClButtonVariant.inverse`. |
| S4 | S | `home_screen.dart:151`, `:263`, `:594`; `disscusion_thread.dart:196` | **Discussion destinations don't match their labels.** Every discussion card (Oppenheimer, Mission: Impossible), hero "Discuss" and "Start a thread" push the bare `/discussionThread`, which always shows a hardcoded **Past Lives** thread. Tapping the Oppenheimer card opens a Past Lives thread. The route exists, but this is the audit's "label doesn't match destination" problem in a new form. | Pass the film or thread: `/communities/:id/discussion` (an existing route that takes a `communityId`), or add a `movieId` extra and have the thread show it. Until the thread screen takes a parameter, point the cards at the one matching thread, or label them honestly. |
| S5 | S | `home_screen.dart:288`, `:312`, `:727`; `vote_summary_screen.dart:33-36`, `:128` | "Cast your vote" (A24 Lovers: Everything Everywhere 11, Oppenheimer 8, Mission: Impossible 5) opens `/communities/demo/vote`. That screen shows **"Weekly Pick — demo"** with a different poll: Past Lives, Oppenheimer, Zone of Interest, Poor Things. This contradicts the commit's "demo data is self-consistent". The raw id `demo` also shows in the destination's title. | Share one demo poll fixture between Home and Vote Summary, keyed by `communityId`, and use a real-looking id. At the least, make the destination's title come from the club name, not the id. |
| S6 | S | `home_screen.dart:507`, `:566-572`; `watch_party_list_screen.dart:20-35` | The party card and RSVP both open the generic list, which contains only Past Lives and Oppenheimer. The Everything Everywhere card's RSVP leads to a list where that party doesn't exist, and nothing on the list is highlighted. "RSVP" doesn't RSVP; it is "see parties". | Pass the party id (`extra` or query) and scroll to and highlight it on the list. Or label the card CTA "Details", and keep RSVP for when it can act in place (an RSVP sheet). Keep the demo lists consistent. |
| S7 | S | `home_screen.dart:26-34`, `:47`, `:85-161` | **No loading or error state.** All data is `const`, so the empty states are dead code that can't be reached or tested. Pull-to-refresh is still a fake delay (600ms; the audit flagged 700ms). Bumping `ValueKey(_generation)` rebuilds the whole `CustomScrollView`, which resets the scroll position and the hero, and replays every entrance. The project rule requires loading, empty and error states. | Add a `homeFeedProvider` (`FutureProvider` returning the demo fixture for now) and render it with `AsyncValue.when`. Loading: `ClSkeleton` blocks shaped like the hero, poll and party cards. Error: `ClStatusWidget` with Retry. Data: the current tree. Refresh with `ref.refresh(homeFeedProvider.future)`, and drop the key bump. Add widget tests that override the provider with empty, error and loading values, and assert the `'No active polls — suggest a film!'` contract. |
| S8 | S | `test/home_screen_test.dart:13-30`, `:65-88` | **The tests would not have caught B1–B3, S1 or S2.**<br>• The layout test only checks `takeException()`. It doesn't check truncation or scrim position, and it doesn't run at 320 @1.0×, where the CTA already truncates.<br>• It runs outside the shell with zero insets, so neither the nav padding nor the status bar is tested.<br>• The gold test only looks for `goldGradient`, so a gold `Icon`, text, fill or spinner would pass.<br>• There is no reduced-motion test and no semantics test.<br>• The empty states can't be tested, because the data is not injectable. | Mount `HomeScreen` under `ClBottomNavBar` with realistic `padding` (top 47, bottom 34). Then:<br>• Assert `didExceedMaxLines == false` for the CTA labels.<br>• Assert the hero badge's top fraction is ≥ 0.55.<br>• Assert the last card ends above the nav.<br>• Scan for any `AppColors.gold` in `Icon`, text and `BoxDecoration`, and pull to check the spinner.<br>• Under `disableAnimations: true`, assert there is no `Animate` in the tree.<br>• Check the header and button semantics.<br>• Add empty and error states once S7 lands. |
| N1 | N | `home_screen.dart:55` | `surfaceTintColor: Colors.transparent` is the screen's only use of `Colors.*`. | Use `surfaceTintColor: AppColors.bg`, or set `scrolledUnderElevation: 0` in the theme. |
| N2 | N | `home_screen.dart:381-382`, `:397`, `:419`, `:455`, `:525-552`, `:538`, `:621`, `:625` | Off-scale values:<br>• Font sizes 11 (w800), 14, 15 and 16, overriding `caption`, `title` and `h3`.<br>• Padding of 14, 10, 6 and 2, and gaps of 6 and 4 written as literals.<br>• `Positioned(top: -5)`. | Use `AppTextStyles.overline`, `label` and `h3` unchanged, or add tokens. Use `AppSpacing.md`, `sm`, `xs` and `xxs`. |
| N3 | N | `home_screen.dart:251-255` | The hero `ClButton` relies on the default `primary` variant. The project rule is to pass `variant:` explicitly, so that the single gold owner is visible at the call site. | Add `variant: ClButtonVariant.primary`. |
| N4 | N | `home_screen.dart:76` | Bottom padding is written inline as `paddingOf(context).bottom + AppSpacing.lg`. It measures correctly: the last card ends 58dp above the nav at every size. `ClBottomNavBar.contentPadding(context)` exists for exactly this. | Use `ClBottomNavBar.contentPadding(context)`. |
| N5 | N | `home_screen.dart:447-458` | Screen readers hear the ring as "41m remaining", value "72%", then "41m" and "left" again. They aren't told what 72% means. | Exclude the child's semantics, and use the label "41 minutes left" with no percent value, or the value "72% watched". |
| N6 | N | `home_screen.dart:244` | The hero title "Past Lives" is the most prominent text on the screen, but it isn't a header. Only the section titles are. | Wrap it in `Semantics(header: true)`. |
| N7 | N | `home_screen.dart:470-474`, `:540-545`, `:396-399` | At 1.3× the club names are cut off ("Tonight 8:00 PM · Nolan…", "Action Heads · 12 wat…"), and the leading film's title is truncated at every size. These are acceptable ellipses, but the club, which says *where* the party is, is the part that gets lost. | Put the club on its own line, or put it first. Allow 2 lines for poll titles at text scales above 1.15. |
| N8 | N | `cl_bottom_nav_bar.dart:150-156` | At 320 width each nav tab's hit area is 47×50, 1dp under `minTouch`. This is in the shell, not in Home, and Home is where it shows. | Reduce the bar's horizontal padding at narrow widths, or drop the 4dp tab inset when `slot < 56`. |
| N9 | N | `lib/features/home/components/*` | Confirmed unused. Nothing in `lib/` imports them. `MovieListScreen` declares its own `SectionTitle`, and `test/voting_card_test.dart` and `test/discussion_card_test.dart` declare their own `VotingCard` and `DiscussionCard`. Home uses its private `_DiscussionCard` and similar classes. Deletion is planned for the cleanup phase, so this is not blocking. | Delete the directory in the cleanup phase. |

## Gold budget

| Element | Rule 1 slot | Measured |
|---|---|---|
| Hero "Watch party" `goldGradient` button | (a) the one content owner | 1 at every size, scrolls away with the hero |
| Logo mark (`SvgPicture`) | (c) | in the pinned toolbar |
| Active "Home" tab: 12% gold pill, gold icon, gold label | (b) | shell |
| Focus ring | (d) | only when focused |
| **`RefreshIndicator` spinner** | none (the rule names it as purple) | **gold, `#FFD27D` (S1)** |

Everything else is purple or white:
- Poll leader bar (`purpleContainer`), rank dot (`purpleBadge`), "Leading" badge and percentage (`purpleText`).
- The "This week's pick", Tonight and Pinned badges.
- The progress ring (`purple`).
- "Cast your vote" and RSVP (`inverse`).

Purple carries identity on the screen.

## Contrast spot checks

Worst case is a white poster; the scrim alpha is measured at the top of each line.

| Pair | Where | Ratio | Result |
|---|---|---|---|
| "DRAMA · 2023" (`textPrimary` on `glassFlat`) | 390×844 @1.0× (alpha 0.87) | 10.4 | Pass |
| same | 320/375 @1.3× (alpha 0.39) | **2.2** | **Fail (B1)** |
| Hero title (`display`, `textPrimary`) | 390 @1.0× (0.89) | 13.9 | Pass |
| same | 320/375 @1.3× (0.72) | 7.7 | Passes AA, breaks the 0.85 rule (B1) |
| "Cinema Sundays · Watch party…" (`textSecondary`) | all sizes (≥ 0.88) | ≥ 6.1 | Pass |
| "CLUVIE" wordmark and bell (`textPrimary`) | 20dp inset (scrimTop 0.42) | **2.6** | **Fail (B2)** |
| same | 47dp inset (scrimTop 0.26) | **1.7** | **Fail (B2)** |
| Poll row text on a `purpleContainer` bar | on the card | ≥ 13.5 / 5.5 | Pass |
| Discussion meta in `textMuted` on `surface` | flat surface, allowed by rule 3 | 5.6 | Pass |
| "Cast your vote" / RSVP (`onInverse` on `inverse`) | | ≈ 16 | Pass |
| LIVE badge (`onSemantic` on `error`) | | 6.7 | Pass |

## Navigation check

Every tappable control pushes a path that exists in `routes.dart`:

| Control | Path | Route |
|---|---|---|
| Bell | `/notifications` | `routes.dart:95-100` |
| Hero CTA, party card, RSVP, "See all" | `/watch-parties` | `:107-112` |
| Discuss, discussion cards, "Start a thread" | `/discussionThread` | `:147-152` |
| Poll card, "Cast your vote" | `/communities/demo/vote` | `:253-277` |
| Live card, "Join live" | `/watchParty` | `:101-106` |
| "Suggest a film" (empty poll) | `go('/suggest')` | shell tab, `:210-215` |

None of them is a dead end. Some destinations show the wrong content (S4–S6).

## What works

- **The audit's Home P0s are closed:**
  - The QA toggle and hint are gone.
  - "Join Live" is a real button.
  - The whole discussion card is tappable.
  - RSVP no longer opens the live room.
  - The tie-with-WINNER contradiction is gone: "Leading" is shown instead of a premature WINNER.
  - The ranking is tested.
  - The `'No active polls — suggest a film!'` copy contract is kept.
- **The poll card is good work:**
  - Ranked rows with vote-share bars behind them.
  - Rank isn't conveyed by colour alone: there is a number, a badge and a percentage.
  - Each row has one clear semantics label ("…, 11 votes, 46 percent, leading").
  - The "votes · voters of members" footer has a `Wrap` fallback for the badge.
- **Tokens and Cl* components** are used almost everywhere: `ClCard`, `ClButton`, `ClBadge`, `ClEmptyState` (with illustrations and one action each), `ClSectionHeader`, `ClProgressRing`, `ClAvatarStack`, `ClTicketDivider`, `ClPosterImage` and `ClEntrance`. There are no `Icons.*`, `Color(0x…)`, `GoogleFonts` or `TextStyle(` uses. The style debt was the highest in the app (95) and is now 1 `Colors.*` (N1).
- **The shell contract is met.** Bottom padding includes the floating nav: the last card ends 58dp above the bar at every size and inset. `RefreshIndicator.edgeOffset` clears the pinned toolbar.
- **Reduced motion is handled:**
  - Parallax switches to pin, and stretch is off.
  - `ClEntrance` returns the child as is.
  - The bar and ring tweens use `motion.slow`, which is zero under reduced motion.
  - There are no hardcoded animation durations. The only literal `Duration` is the fake refresh delay (S7).
- **Touch targets:** every control on Home is at least 48dp. The `sm` buttons pad their hit area to 48, and the bell is 44 visual with a 48 hit area.
- **The bell reads its count aloud** ("Notifications, 3 unread"). The red always-on dot is replaced by a purple badge that is driven by the data.
- **No overflow** in any of the 12 measured configurations, including 320×568 @1.3×.
- **`test/helpers/real_fonts.dart`** is a good extraction. `auth_layout_test.dart` now shares it, and its behaviour is unchanged.

---

## Resolution of the remaining findings (2026-11-25)

All round 4 and round 4b findings are now closed. B1–B3, S1 and S3 were fixed in `f4107b6`; round 4b's B4–B7 in `dd3f930`. This pass closes the rest.

**Data and states (S7; 4b S1, S7)**
- New `lib/features/home/data/home_feed.dart`: public models plus `homeFeedProvider` (a `FutureProvider` serving the demo feed until an API exists).
- Home is a `ConsumerWidget`. First load shows a skeleton, a failed load shows `ClErrorState` with retry, and a failed refresh keeps the feed and shows a snackbar.
- Refresh re-runs the provider. The `ValueKey(_generation)` bump is gone, so the scroll position survives a refresh.
- "Live now" is hidden when nothing is live, and the hero is hidden when there's no pick. The empty discussions action is "Discuss <pick>" and opens that thread (it was "Start a thread", which opened an existing one).

**Destinations match their labels (S4–S6; 4b S2)**
- "Cast your vote" passes the poll; `VoteSummaryScreen` takes `clubName` and `options`, so it shows the same three films under "Friday Film Club" (no more raw `demo` id).
- Card RSVP and the hero CTA pass their party; `WatchPartyListScreen` takes `focus` and lists that party first, outlined in purple.
- "Join live" passes the film and minutes left; `WatchPartyScreen` shows them (it was always "Arrival").
- The hero CTA is now "RSVP" (mood board), opening the pick's party.

**Accessibility**
- S2: `container: true` on `ClPressable` and on `ClSectionHeader`'s header node, so this is fixed in the components, not just Home.
- N5 / 4b S3: `ClProgressRing` gains `semanticValue`; the live ring reads "41 minutes left" with no percent and doesn't repeat its child text.
- 4b S4: "9 going" is excluded; the avatar stack's names and count are read once.
- 4b S5: `ClPosterImage(decorative: true)`, used for every poster on Home.
- N6: the hero title is a header.

**Layout**
- N7: party cards put time and club on separate lines; the card height grows with text scale. The live card puts the club on its own line, and "Join live" moves below the ring when it would truncate. Poll titles get two lines above 1.15× text.
- The hero stacks its buttons when *either* label wouldn't fit (it measured only the CTA, which is now the shorter one).
- N8: nav tabs drop their side inset when a slot is under 48dp. Nav labels clamp to 1.3× text (fixes the FYI 2.0× nav overflow).

**Tokens (N1–N4, 4b S6, N2, N3)**
- `scrolledUnderElevation: 0` replaces `Colors.transparent`.
- Off-scale font sizes and spacing literals were replaced with tokens. The rank digit uses `caption` in a circle that grows with the text.
- The bottom padding uses `ClBottomNavBar.contentPadding`.

**Demo data (4b N5):** the poll club is "Friday Film Club", not "A24 Lovers".

**Cleanup (N9):** `lib/features/home/components/` deleted.

**Tests (S8; 4b S8–S10)**
`test/home_screen_test.dart` now covers:
- the 3 sizes × 1.0/1.3/2.0 matrix with truncation checks on every control label and a sideways scroll of the party list
- a shell-mounted check that the last card clears the nav
- a gold scan of every icon, text, fill, gradient, border, SVG and the mid-pull spinner (only the hero CTA, logo and active tab may be gold)
- destination tests that check the film or club each control passes
- one tap stop per action
- loading, error, failed refresh, empty feed and the empty-state actions
- semantics for headings, hero title, ring, posters and party count
- ranking finders scoped to the poll card

Results: 117/117 tests pass. The analyzer has 0 errors and 0 warnings (15 infos, the same as before).
