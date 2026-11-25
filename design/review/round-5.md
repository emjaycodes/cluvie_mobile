# Design review, round 5: Home feed (closing round 4)

**Commit reviewed:** `ac6aaae` on `feat/design-overhaul` ("fix(home): close the remaining round 4 findings").

**Scope:**
- `home_screen.dart`, `home_feed.dart` and `test/home_screen_test.dart`.
- The shared components the commit changed: `ClPressable`, `ClSectionHeader`, `ClPosterImage`, `ClProgressRing` and `ClBottomNavBar`.
- The new parameters and route wiring for `VoteSummaryScreen`, `WatchPartyListScreen` and `WatchPartyScreen`. Their old styling is out of scope.

**Checks run:**
- `flutter analyze --no-fatal-infos`: 15 infos, 0 warnings, 0 errors. This matches the baseline. Three of the infos are the pre-existing `withOpacity` calls in `watch_party_list_screen.dart`. None are in Home.
- `flutter test`: 117 of 117 pass.

**Measurements:** taken with a throwaway probe in `test/_probe/`, since deleted. Setup:
- Real fonts, `ClPosterImage.debugDisableNetwork = true` and a `ProviderScope`.
- Home mounted under `ClBottomNavBar` through a `ShellRoute`.
- Insets of 20/34 on 320×568 and 375×667, and 47/34 on 390×844.
- Text at 1.0×, 1.3× and 2.0×.

For each run the probe recorded:
- Hero geometry against the toolbar.
- `didExceedMaxLines` on every paragraph, scrolling top to bottom and sideways through the party list.
- Every `ClPressable` smaller than 48dp.
- Nav tab sizes.
- Clearance between the last card and the nav.
- Thrown exceptions.

It also ran:
- an unrestricted gold scan
- a semantics dump
- a retry with the load still pending
- the position of the failed-refresh snackbar
- a reduced-motion run

## Verdict

**Not ready to merge: 2 blocking findings.**

Most of the claimed resolutions hold up against the code and the probe:
- States: loading, error, failed refresh and per-section empty states.
- Destinations: each control passes its film, club or party.
- Semantics: separate header and card nodes, a countdown ring, decorative posters, the party count read once, and a header on the hero title.
- Hero CTA: it stacks and is never truncated.
- Nav: tabs are at least 48dp, and labels are clamped.
- Tokens, and the deletion of `home/components`.
- None of the shared-component changes caused a regression elsewhere.

Two problems remain:
1. **At 2.0× text, the hero still runs under the toolbar and off the top of the screen on 320 and 375 phones.** Round 4b B2 named this exact case, and the resolution says it is covered. The cap added in `_heroHeight` is what brings it back.
2. **The new gold-budget test can't fail.** It treats everything under `ClBottomNavBar` as allowed gold, and in the shell Home itself sits under `ClBottomNavBar`. The test is listed as resolving round 4 S8 and round 4b S9. The code itself has no gold leak: an unrestricted scan finds only the hero CTA and the active tab. But the guard the commit claims isn't there.

## Findings

Severity: **B** = blocking, **S** = should-fix, **N** = nit.

| id | sev | file:line | finding | concrete fix |
|---|---|---|---|---|
| B1 | **B** | `home_screen.dart:119-127` (`_heroHeight`), `:353-401` (text block) | **At 2.0×, the hero text block starts under the toolbar or above the screen.** The height is capped at `size.height − top − 96`, so the bottom-anchored block grows upward past the top of the hero. Measured (toolbar bottom = inset + 56):<br>• **320×568 @2.0 (hero 472):** panel top −82. The "THIS WEEK'S PICK" badge is at −78 and "DRAMA · 2023" at −33 to −5, so both are clipped off screen. The title "Past Lives" runs from 12 to 188, under the status bar and behind the logo and bell (toolbar 20–76).<br>• **375×667 @2.0 (hero 571):** panel top 17. The pick badge is at 21 and collides with the logo (bottom 63). "DRAMA · 2023" (66–94) crosses the toolbar edge at 76.<br>• 390×844 @2.0 is fine: the badge is at 198 and the toolbar ends at 103. So are all sizes at 1.0× and 1.3×; the closest is 320 @1.3, with the badge at 135 and the toolbar ending at 76.<br>Round 4b B2 asked for "≥ `padding.top + kToolbarHeight` across the size × scale matrix". The hero test (`home_screen_test.dart:209`) only runs 1.0× and 1.3×, and only checks that each line is below the panel's top, never the toolbar's bottom. | Size the hero from the measured block: `expandedHeight ≥ blockHeight + 48 (fade) + kToolbarHeight + AppSpacing.lg`, and let that override the "peek" cap. When even that doesn't fit, move the meta line and the badges into the first sliver under a shorter poster. Extend the hero legibility test to 2.0×. Assert `badge.top ≥ padding.top + kToolbarHeight` and `badge.top ≥ 0`. |
| B2 | **B** | `test/home_screen_test.dart:128-142`, `:244-264` | **The gold scan is vacuous.** `allowed` includes the `ClBottomNavBar` element, and the test pumps with `shell: true`. In the shell, every Home widget is a descendant of `ClBottomNavBar`; the probe confirmed this for "Cast your vote" and "Active poll". So `underAllowed()` is true for the whole screen. A gold icon, text, fill or border on any card would pass. Only the spinner line (`:260`) asserts anything. An unrestricted scan of the current code finds just the hero `goldGradient` and the active tab's icon and label, so this is a test defect, not a leak. | Allow only the nav subtree. For example: `find.ancestor(of: find.bySemanticsLabel('Home'), matching: find.byType(Stack)).first`. Or run the content scan with `shell: false` and check the nav separately. Add a negative control: wrap a gold `Icon` in a test-only feed card, or temporarily allow nothing, and assert that the scan flags it. |
| S1 | S | `home_screen.dart:53-63`, `:60` | **"Try again" gives no feedback.** After `ref.invalidate`, Riverpod keeps the previous error in the loading state, so `async.hasError` stays true and the error view stays up unchanged until the request resolves. In the probe, with the retry pending: error shown, no skeleton, no spinner. On a slow network the tap looks dead. | Check `async.isLoading` before `hasError`, and show the skeleton (or `ClButton(isLoading: true)` on the retry) while a retry is in flight. Add a test with a pending `Completer` on the second call. |
| S2 | S | `vote_summary_screen.dart:44-53`; `home_feed.dart:81-86` | **The vote screen still doesn't show "the same poll".**<br>• `'year': ''` makes each row read " · 11 votes" (`:221` renders `'${year} · …'`).<br>• Home says "closes in 2 days", but the destination shows "OPEN · 17h 59m left" and a closing date of tomorrow, because `closesIn` isn't passed.<br>• `'id': '${o['order']}'` makes a vote POST to `/movies/0/vote`, an order index rather than a film id.<br>• The member count is dropped. | Add `closesAt` (or `closesIn`), `members` and a real option `id` to `voteExtra`, and use them. Omit the year segment when it's empty. Have the destination test assert the deadline as well as the club. |
| S3 | S | `home_screen.dart:849-858` | The pinned discussion title is truncated at **default** text on 320: "Oppenheimer" has 94dp beside the PINNED badge. It is also truncated on 375 @1.3 (137dp) and on 320 @2.0 (53dp). The title is the film, so it's the part that should never be cut. | Put the Pinned badge on the meta row, or above the title, so the title gets the full width. Allow 2 lines above 1.15×, as the poll titles do. |
| S4 | S | `home_screen.dart:678`, `:755`, `:782-789`, `:726` | **At 2.0×, card text is cut on every phone:**<br>• the party card title ("Oppenheimer", h3 on one line)<br>• "9 going", "14 going" and "6 going", which become "9 go…"<br>• on 320, the live card's club "Action Heads" (146dp)<br>The resolution says the club is now on its own line "so it never gets cut"; that holds only up to 1.3×. Semantics are intact, and nothing overflows. | Give the club and party title `maxLines: 2` when the scale is above 1.3. Drop the redundant "N going" text when the scale is at least 1.6, since the avatar stack already says it. Add these labels to the matrix's truncation list. |
| S5 | S | `test/home_screen_test.dart:170-173`, `:209` | **The layout tests still can't see B1.**<br>• The 3×3 matrix runs outside the shell, with a 20dp top inset on 390×844 too (real devices have 47).<br>• It checks only control labels.<br>• The hero test stops at 1.3×. | Run the matrix inside the shell, with 47/34 insets on 390. Add the hero toolbar assertion from B1. Fold the S3 and S4 labels into the truncation check. |
| N1 | N | `home_screen.dart:455-465` | `_buttonWidth` hard-codes `ClButton`'s internals: font size 14/15, icon 18/20, padding and gap. If `ClButton` changes, the stacking and inline decisions go wrong without any error. | Expose a static `ClButton.intrinsicWidth(context, label, {size, hasIcon})` next to the code it mirrors. |
| N2 | N | `home_screen.dart:115-126` | The doc comment says the next section keeps "peeking above the fold". At 390×844 @2.0 the hero ends at 748 and the nav starts at about 743, so nothing peeks. On 320 and 375, the cap that keeps the peek is the cause of B1. | Decide which wins (B1 says legibility). Then update the comment. |
| N3 | N | `home_screen.dart:609`, `:819`, `:837`, `:865`, `:869` | Icon sizes 12, 14 and 16 are off the tokens.md scale (20/24/32/56). `const TextStyle(color: textMuted)` is merged into `caption` instead of using `copyWith`. | Use 20 inline, or add a small-icon token to tokens.md. Use `AppTextStyles.caption.copyWith(color: AppColors.textMuted)`. |
| N4 | N | `home_screen.dart:791-798` | The three party cards each expose a button labelled just "RSVP". The parent node carries the film, so this passes, but a buttons rotor lists "RSVP, RSVP, RSVP". | Add a `semanticLabel` to `ClButton` and pass `'RSVP, ${party.title}'`. |
| — | FYI, out of scope | `vote_summary_screen.dart:173-218`; `watch_party_list_screen.dart:136`, `:24` | Destination styling is for a later phase:<br>• The vote screen marks the leader **WINNER**, in gold, while the poll is open. Home fixed this.<br>• On the list, "Details" pushes `/watchParty` with no extra, so it opens "Arrival".<br>• One `_rsvp` state is shared by every party on the list. | Fix these in the destination redesign. |

## Resolution check

| Claimed fix | Status |
|---|---|
| 4b B1 / round 4 B3: hero CTA truncated | **Holds.** It stacks at 320 @1.3, 375 @2.0 and similar. "RSVP" and "Discuss" are never truncated. |
| 4b B2 / round 4 B1: hero text on the scrim and clear of the toolbar | **Partly.** It holds at 1.0× and 1.3× (panel ≥ 0.9). It fails at 2.0× on 320 and 375 (B1). |
| Round 4 B2: top scrim sized from the inset | **Holds.** The logo and bell sit inside the solid part at both insets. |
| Round 4 S1 / 4b B3: spinner gold | **Holds.** It is `AppColors.purple` on `surfaceRaised`, 4.0:1. The test's direct spinner assertion works. |
| Round 4 S2 / 4b B4: headers merge into cards | **Holds.** The dump shows the header nodes ("Active poll / Friday Film Club · closes in 2 days", "Live now") and the card nodes separately, and each card has exactly one button child. |
| Round 4 S4–S6 / 4b B7, S2: destinations | **Hold for film, club and party.** S2 above covers the poll's details. |
| Round 4 S7 / 4b S1, S7: states, scroll reset | **Hold.** The `ValueKey` is gone, `valueOrNull` keeps the tree during a refresh, and the empty states are reachable and tested. The one gap is retry feedback (S1). |
| Round 4 S8 / 4b S8–S10: tests | **Partly.** The destinations, states and semantics tests are real. The gold scan is vacuous (B2), and the layout and hero tests miss 2.0× and the toolbar (S5). |
| Round 4 N5 / 4b S3: ring | **Holds.** "41 minutes left" is read with no value, and the child text is excluded. |
| 4b S4: party count read twice | **Holds.** "Ada, Tunde +7 going" is read once, and "9 going" is excluded. |
| 4b S5: posters add noise | **Holds.** The tree has no image nodes. |
| Round 4 N6: hero title header | **Holds.** |
| Round 4 N7: club cut | **Holds to 1.3×**, not at 2.0× (S4). |
| Round 4 N8: nav targets; 2.0× nav overflow | **Holds.** Tabs are 54.8×50 on 320 (the side inset is dropped), 57.8×50 on 375 and 60.8×50 on 390. There is no exception at 2.0×. |
| Round 4 N1–N4 / 4b S6, N2, N3: tokens | **Hold.** `scrolledUnderElevation: 0`, `contentPadding`, an explicit `variant: primary`, and a `caption` rank digit in a circle that grows. No `Colors.*`, `Color(0x…)`, `GoogleFonts` or `Icons.*` in Home. |
| 4b N5: poll club; round 4 N9: delete `home/components` | **Hold.** |

## Shared components

- **`ClPressable` `container: true`.** Its callers are `ClCard`, `ClButton`, `ClChip` and the nav tabs and "+". No caller wraps it in a `Semantics` or `MergeSemantics` that relied on merging. `ClTextField`'s `MergeSemantics` contains a Material `IconButton`, not a `ClPressable`. The onboarding genre chips and community role chips still expose their own nodes. The full suite passes. No regression.
- **`ClSectionHeader`.** Only the header `Semantics` became a container, and "See all" stays a separate button. No regression.
- **`ClPosterImage(decorative)`.** It defaults to `false`, so the four other callers are unchanged.
- **`ClProgressRing(semanticValue)`.** Home is the only caller, so it can't regress anything. The default behaviour, which reads the percentage, is unchanged.
- **`ClBottomNavBar`.** The 48dp inset rule and the label clamp work at every size and scale tested.
- **Route wiring in `routes.dart`.** Each `extra` field is type-checked and falls back to the old demo, so a deep link or a missing `extra` can't crash.

## What works

- **The state model is right.**
  - One `FutureProvider` feeds the screen.
  - The skeleton keeps the app bar.
  - A failed refresh keeps the feed and shows a snackbar 15dp above the nav, inside the shell.
  - "Live now" and the hero are hidden when they're empty, instead of showing filler.
- **Every control passes what it names, and the tests check the payload, not just the path.**
- **The semantics tree is now clean.** Each section has a header node, a content node and a single button. The ring reads as a countdown, there are no poster stops, and the bell says "Notifications, 3 unread".
- **Layout below 2.0× is solid.**
  - No exceptions in any of the nine configurations.
  - Every `ClPressable` is at least 48dp.
  - The last card clears the nav by about 59dp everywhere.
  - The hero buttons stack exactly when they need to.
- **Reduced motion is respected:** stretch is off, the collapse mode is pin, and there are no transient callbacks after settling.
- **The gold budget holds in the code:** one content owner (the hero RSVP), plus the active tab and the logo.

---

## Resolution (implementer, 2026-11-25)

All findings are fixed. 125/125 tests pass; the analyzer has 0 errors and 0 warnings (15 infos, unchanged).

| ID | Fix | Test |
|---|---|---|
| B1 | `_heroHeight` takes the larger of the "peek" height and `toolbar + 16 + fade + measured text block` (`_Hero.blockHeight` measures badges, title, when line and buttons at the current scale). Legibility wins over the peek. | Hero test now runs 1.0/1.3/2.0× × 2 insets × 3 sizes, and asserts each hero line is below `inset + kToolbarHeight` as well as on the panel |
| B2 | The gold scan only exempts the `_FloatingNav` subtree, not all of `ClBottomNavBar`. | New negative control: a gold icon, text and border are flagged |
| S1 | `isLoading` is checked before `hasError`, so a retry in flight shows the skeleton. | Retry with a pending `Completer` shows the skeleton, not the error |
| S2 | `voteExtra` carries `closesInMinutes` and real film ids (TMDB); `Poll.closesIn` is a `Duration`. The vote screen uses both and omits the year when there is none. | Destination test asserts the club, option count and deadline |
| S3 | The Pinned badge moved to the discussion meta row (a `Wrap`), and titles get two lines above 1.15×. | Covered by the names check below |
| S4 | Above 1.3× the party title moves off the poster (title style, up to two lines), clubs and meta get two lines, and "N going" is dropped at ≥ 1.6× (the avatar stack still says it). | Names check |
| S5 | The layout matrix runs in the shell, with a 47dp inset on 390×844. It checks control labels and clubs/short titles/counts for truncation, **and every wrapping paragraph for words broken mid-word**. | — |
| N1 | `ClButton.intrinsicWidth` sits next to the code it mirrors; Home's copy is gone. | — |
| N2 | Comment rewritten: legibility wins over the peek. | — |
| N3 | Meta icons use 16, now in tokens.md ("16 (meta, beside `caption`/`bodySm` text)"). The muted caption uses `copyWith`. | — |
| N4 | `ClButton.semanticLabel`: party RSVPs read "RSVP, <film>" and the hero reads "RSVP to the <film> watch party". | Semantics test |

**Also found and fixed while verifying at 2.0× (not in this report):**
- The poll footer squeezed "24 of 31 members voted" to one character per line next to the button. It now stacks above a full-width button when the button would take more than half the width.
- Poll titles broke mid-word ("Oppen/heimer"). Above 1.6× the rows drop the thumbnail and right-hand percentage, and put "#rank · votes · %" on the votes line.
- The live card's title broke mid-word ("Missio/n"). In its narrow layout the title, club and button take the full card width.
- Avatar initials scaled with text and overflowed their fixed circle. `ClAvatar` initials no longer scale; the name is in semantics.

The broken-word check above is what catches this class of problem now.
