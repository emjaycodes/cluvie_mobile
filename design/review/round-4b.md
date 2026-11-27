# Design review, round 4: Home feed

**Scope:** `lib/features/home/presentation/home_screen.dart` and `test/home_screen_test.dart` at `0607cdf` (`feat/design-overhaul`), running in the `ClBottomNavBar` shell. Shared components are reviewed only for how Home uses them.

**Checks run:**
- `flutter analyze --no-fatal-infos`: 15 infos, all in other features. Nothing in Home or its test.
- `flutter test`: 85 of 85 passed.

**Measurements:** taken with throwaway probe tests, since deleted. They used real fonts (`loadRealFonts`), had network posters off, and set realistic status-bar insets: 20dp on 320×568 and 375×667, 47dp on 390×844 and 59dp on 430×932. Each size was run at 1.0×, 1.3× and 2.0× text, with and without the shell.

**Hero height:** the hero as rendered is `expandedHeight` plus the status bar. That gives 440dp on phones up to about 720dp tall, 537dp on 390×844 and 599dp on 430×932.

## Verdict

**Not ready to merge.** The structure is a big step up from the audit:
- The QA toggle is gone, the controls are real, and the poll is ranked with a purple leader.
- The single gold CTA follows the mood board, and the shell padding and reduced motion are handled properly.

The hero, though, is laid out for one phone at one text size, and the tests can't see that.

**Hero problems:**
- On a 320- or 375-wide phone at default text, the screen's only primary action reads "Watch par…".
- At 1.3× the tag row climbs well above the 0.55 scrim stop, so a `textPrimary` glass badge sits on raw poster.
- At 2.0× the badges are pushed off the top of the hero, and the title slides under the logo and bell.

**Other blockers:**
- **Gold budget:** the theme makes the pull-to-refresh spinner gold, which tokens.md v1.2 forbids by name.
- **Accessibility:** section headers merge into their cards' buttons. "Active poll" and "Live now" become one giant button carrying the header flag, with a second button nested inside.
- **Demo data:** the poll still contradicts itself (24 votes from 22 voters).
- **Wrong destination:** the *Oppenheimer* discussion card still opens the "Past Lives" thread, the exact §1.8 example.
- **Overflow:** the "Leading" badge overflows at 320 @2.0×.

None of these are hard to fix. Each needs a test that actually fails on it.

## Findings

Severity follows the brief. **Blocking** means a crash or overflow at a supported size, an accessibility failure, a contradiction of tokens.md, a dead or mislabelled control, or a regression.

| id | severity | file:line | finding | concrete fix |
|---|---|---|---|---|
| B1 | blocking | `home_screen.dart:248-266` | **The primary CTA is truncated.** "Watch party" is ellipsized (`didExceedMaxLines == true`) at 320×568 and 375×667 at **1.0×**, and on every phone at 1.3× and 2.0×. At 320 each `Expanded` button is 134dp wide. After 24+24 padding and the 20dp icon plus 8dp gap, only 58dp is left for the label (86dp at 375). "Discuss" truncates at 320 @1.3×, and at 2.0× on 320, 375 and 390. A truncated label on the screen's one gold action is a mislabelled control. | Below about 360dp of available width, or when the text scale is above 1.15, stack the two buttons vertically, both full width. Or make "Discuss" a 48dp `ClIconButton` with a tooltip, or use `ClButtonSize.sm`, which has 16dp padding. Add a layout test that asserts `RenderParagraph.didExceedMaxLines == false` for both labels at 320 @1.0× and 1.3×. |
| B2 | blocking | `home_screen.dart:39, 230-269` | **The hero text block ignores the scrim stop and the toolbar.** tokens.md says text must start where `scrimBottom` alpha is ≥ 0.85, i.e. ≥ 55% of the hero height. Measured badge-row top as a fraction of hero height: 320 @1.0 **0.51**, 320 @1.3 **0.36**, 375 @1.3 **0.44**, 390 @1.3 **0.54**. At 0.36–0.44 the alpha is 0.04–0.38, so the glass `DRAMA · 2023` badge (`textPrimary` on 8% white) sits on bare poster. On a light poster that is about 1.1–2.1:1. At **2.0×** the `Positioned(bottom:)` column has no top bound and grows upward without error: the badge top is at **−54** on 320/375, so it is clipped off the hero, and the title top is at 36, under the status bar and the logo/bell toolbar (bottom 76). On 390 @2.0 the badge top is at 43, behind the toolbar (bottom 103). The fixed `expandedHeight` clamp of 420–540 ignores text scale. | Tie the cover to the content: a `bg` panel at least 0.85 opaque behind the text block, with a fade above it, and grow `expandedHeight` with the measured block plus `padding.top + kToolbarHeight`, so the block never runs under the toolbar. Alternatively move the text block into the first sliver below a shorter poster. Capping the title's text scale is a possible design trade-off, but it is not required by any rule. Test: badge top ≥ the 0.85 line and ≥ `padding.top + kToolbarHeight` across the size × scale matrix. |
| B3 | blocking | `home_screen.dart:43-45` | **The RefreshIndicator is gold.** `RefreshIndicator` resolves `widget.color ?? colorScheme.primary`, and `primary` is `AppColors.gold`. The `progressIndicatorTheme.color` never applies. The probe measured `valueColor = #FFD27D`. tokens.md Rule 1 (v1.2) says the "refresh indicator … [is] purple". That makes Home's gold count: the hero CTA, the nav tab, the logo, the focus ring, **plus the spinner**, which is over budget. | Pass `color: AppColors.purpleText, backgroundColor: AppColors.surfaceRaised`. The same default affects every screen that doesn't pass a colour, so consider a `ClRefresh` wrapper. Extend the gold test to pull and inspect `RefreshProgressIndicator.valueColor`. |
| B4 | blocking | `home_screen.dart:202-210` (`_Section`), `:287-288`, `:443-444` | **Section headers merge into card buttons.** Nothing in `_Section` is a semantics container, so the poll card's `ClPressable` button merges upward. The probe's tree shows one node with `isButton, isHeader`, labelled "Active poll / A24 Lovers · closes in 2 days / [all three rows] / 24 votes · 22 of 31 members". A second button, "Cast your vote", sits inside it and goes to the same route. "Live now" does the same: header, meta and the ring's value "72%" become one button with "Join live" nested inside. Heading navigation lands on a button, and there are duplicate focus stops. **A probe showed that removing the card `onTap` alone makes it worse:** header and button then merge into a single "header + button" node. | Wrap the header and the child in `_Section` in `Semantics(container: true)`. In a probe that restored a separate header node and a separate card node. Then drop the card-level `onTap` from `_PollCard`, `_LiveCard` and `_PartyCard`, which each already have an explicit button, to remove the duplicate stop. Keep it on `_DiscussionCard`. Component follow-up: `container: true` in `ClPressable` and `ClSectionHeader`. Add a semantics test: "Active poll" has `isHeader` and no `isButton`, and the poll has exactly one tap action. |
| B5 | blocking | `home_screen.dart:305, 730-737` | **The poll footer contradicts itself.** The options sum to 8 + 11 + 5 = **24 votes**, but `voters: 22`, so the footer reads "24 votes · 22 of 31 members". On a single-pick poll that is impossible, and it is the exact class of problem in §1.8. | For a single-pick poll, `voters == totalVotes`. Derive the voter count from the votes (or set `voters: 24`), and add `assert(voters == totalVotes)` in `_Poll`. |
| B6 | blocking | `home_screen.dart:409` | **The "Leading" badge overflows.** At 320×568 @2.0×: "A RenderFlex overflowed by 33 pixels on the right", from the `ClBadge` `Row` (`cl_badge.dart:50`) inside the `Wrap` inside the `Expanded` column of `_PollRow`. A `Wrap` can't shrink a child that is wider than the run. | Wrap the badge in `FittedBox(fit: BoxFit.scaleDown)`, or at large scale show only the crown icon, with "leading" kept in semantics (it already is). Add 320 @2.0× to the layout test. |
| B7 | blocking | `home_screen.dart:594` (also `:157`) | **The discussion cards are mislabelled.** The *Oppenheimer* and *Mission: Impossible — Fallout* cards push `/discussionThread`, which renders a thread headed "Past Lives" (`disscusion_thread.dart:196`, hardcoded whatever the id). The audit names this case ("Home's *Oppenheimer* card opens Past Lives"). The hero's "Discuss" button, which is about Past Lives, does match. | Home can't fix the destination: the thread title is hardcoded and ignores `communityId`. So relabel what Home shows: one "Open discussions" entry, or Past Lives-only cards, until the thread takes a film or thread id. Follow-up (destination): pass an id through `/communities/:id/discussion` and render its title. Supporting evidence of the same no-id pattern, which rests on the destination's accepted demo data: "Join live" on *Mission: Impossible* opens a room showing *Arrival*, and the EEAAO card's "RSVP" opens a list without that party. |
| S1 | should-fix | `home_screen.dart:47` | **`ValueKey(_generation)` on the `CustomScrollView` rebuilds the whole scroll view on every refresh.** In the probe, a user who scrolled down 700dp while the refresh was pending was jumped back to **0**. It also resets the party list, drops accessibility focus, and replays every entrance and bar animation. | Key the sections (or `ClEntrance`) instead of the scroll view. |
| S2 | should-fix | `home_screen.dart:252-254, 566-572` | **CTA labels are vague.** "Watch party" (a noun) opens the generic list, not the Past Lives party; the mood board says "RSVP". The card "RSVP" doesn't RSVP; it opens the list. | Use "RSVP" or "Join watch party" with a party id once the list supports one. Until then, "See watch parties". |
| S3 | should-fix | `home_screen.dart:447-458` | **The live ring announces "41m remaining", "72%" and "41m left".** The value is elapsed progress, which contradicts the countdown, and "41m" may be read as "41 meters". | `semanticLabel: '41 minutes left'`, with the child text and the percentage value excluded. |
| S4 | should-fix | `home_screen.dart:556-564` | **The party card speaks its count twice.** "Ada, Tunde +7 going", then "9 going". The mood board shows the names. | Show the stack's caption, or exclude "9 going" from semantics. |
| S5 | should-fix | `home_screen.dart:229, 598` | **Poster images add noise.** "Past Lives poster" duplicates the title. The discussion and party posters add an `isImage` flag to the card button. | Add a `decorative` option to `ClPosterImage` that excludes semantics. |
| S6 | should-fix | `home_screen.dart:378-385` | **The rank digit is off-token and clips.** It uses an 11pt w800 style, which leaves part of the §1.8 "9–11pt" issue open. It clips inside the fixed 20×20 circle at 2.0× (about 30dp glyph in a 20dp box). | Use the 12pt `caption` token and a min-size circle that grows with the text. |
| S7 | should-fix | `home_screen.dart:85-98, 144-153, 725` | **The empty states can't be reached or tested.** `_demoPolls` and the others are non-empty `const`. The contract copy `'No active polls — suggest a film!'` is present, but no Home test renders it; `voting_card_test.dart:114` tests a local stub. "Start a thread" pushes an existing thread. "Live now" has no empty or hidden branch. | Inject the feed so tests can render the empty states and assert the contract copy on `HomeScreen`. Hide "Live now" when nothing is live. Fix the "Start a thread" label. |
| S8 | should-fix | `test/home_screen_test.dart:107-110` | **The tap tests for "Cast your vote", "Join live" and "RSVP" are tautological.** The parent card goes to the same route, so a disabled inner button still passes. | After B4, the inner button is the only target. Also assert `onTap != null`. Add tests for "See all", the live card and the party card. |
| S9 | should-fix | `test/home_screen_test.dart:72-81` | **The gold test can't fail on the real risks.** It only finds gold-gradient `DecoratedBox`es, so it misses the spinner (B3), gold text, borders and SVGs. After scrolling, `lessThanOrEqualTo(1)` passes with **zero**. | Scan all colours in the render tree (or the pixels) for gold, include a pulled refresh state, and assert exactly one content owner. |
| S10 | should-fix | `test/home_screen_test.dart:62-69, 86-93` | **The layout and ranking tests prove less than they claim.** The layout test only catches exceptions, so it can't see clipping (B2) or truncation (B1). It has no 2.0× case, which would have caught B6. The ranking test's `find.text('Oppenheimer').last` can resolve to the discussion or party card. | Add geometry and truncation assertions and a 2.0× matrix. Scope the ranking finders to the poll card. |
| N1 | nit | `home_screen.dart:409, 353` | The "Leading" pill is `purpleContainer` on a `purpleContainer` bar, so the pill's shape vanishes. | Use `purpleSolid`, or a lighter bar. |
| N2 | nit | `home_screen.dart:397, 419, 455` | Off-token sizes: 14, 15 and 16 overrides of `title`/`h3`. | Use the `label`/`title` tokens. |
| N3 | nit | `home_screen.dart:76` | The bottom padding duplicates `ClBottomNavBar.contentPadding`. The behaviour is correct: the last card clears the nav by 16dp at 1.0× and 2.0×. | Call the helper. |
| N4 | nit | `home_screen.dart:50-58` | The collapsed app bar is opaque `bg`, not the `surfaceGlass` that tokens.md lists for "app bar on scroll". | This is optional: fade glass in once collapsed. |
| N5 | nit | `home_screen.dart:725-737` | The "A24 Lovers" poll offers non-A24 films. | Swap the titles, or rename the club. |
| — | FYI, out of scope | `cl_bottom_nav_bar.dart:193` | At 2.0× text the nav tab `Column` overflows by 6px in the shell. | Route to the component owner. |

### Focus order

The traversal order (from the semantics dump) is logo, bell, hero (poster, badges, title, meta, "Watch party", "Discuss"), then the sections from top to bottom. That order is sensible. B4 adds a duplicate focus stop on the poll and live cards, and the poll and live headers become buttons.

### Audit §1.8 status

| Audit item | Status |
|---|---|
| QA toggle and hint | Fixed |
| Fake refresh and hardcoded content | Accepted (demo). There are still no loading or error states. |
| Demo vote id | Accepted |
| Discussions "View all" | Fixed (removed). The cards still open the wrong film (B7). |
| RSVP opens the live room | Partly fixed: it now opens the list (S2) |
| Join Live and the discussion card are dead | Fixed |
| A WINNER is shown during a tie | Fixed |
| Bell dot | Fixed, with a spoken count |
| RSVP visual size | Fixed: 40 visual, 48 hit |
| 9–11pt text | Mostly fixed. The rank digit is still 11pt (S6). |
| The poll header overflows | Fixed, but there is a new overflow at 2.0× (B6) |
| New self-contradiction | 24 votes from 22 voters (B5) |
| Must-keep navigation | All six paths present. `go('/suggest')` is only in the empty state, which can't be reached (S7). |
| Contract copy | Present, but not tested on Home (S7) |

### Reduced motion

| Item | Result |
|---|---|
| Stretch | Off |
| Collapse mode | Pinned (no parallax) |
| Entrances | Skipped |
| Vote bars and ring | Zero duration |
| Page transitions | Theme no-op builder |
| Probe | No transient callbacks after two frames |

## What works

- **Gold restraint, apart from B3:** the hero CTA is the only gold content. The leader, badges and "Join live" are purple, and the card CTAs are white (`inverse`).
- **Poll design follows the mock:** rows are ranked, share bars sit behind them, ties go to the earliest suggestion, and there is no premature WINNER. Each row has one concise semantics label.
- **The ticket-stub party card** is faithful to the mood board. Its 268dp height fits at every size and scale tested, including 2.0× and the horizontally scrolled cards.
- **The shell integration is correct:** padding comes from the shell's `MediaQuery` (116dp), so the last card clears the nav by 16dp. `edgeOffset` puts the spinner below the toolbar.
- **The collapsed app bar holds up at 2.0×.**
- **The bell** has a tooltip, a spoken unread count and a 48dp target.
- **Contrast of the static pairs is within spec:** `purpleText`/`purpleContainer` 5.5:1, white/`purpleBadge` 6.0:1, `textSecondary` over the share bars ≥ 6.1:1, and `textMuted` only on `surface`.
- **Reduced motion is handled for every mechanism listed in tokens.md.**
- **Real Cl\* components throughout,** empty states in the "illustration + message + one action" form, and a shared real-font test helper.

---

## Resolution (implementer, 2026-11-25)

**Context.** Two independent round-4 reviews of `0607cdf` were written in parallel:
- `round-4.md`, by another session, which also fixed its findings in `f4107b6`
- this one (`round-4b.md`)

**Covered by `f4107b6`:**
- B1, truncated hero CTA: it now stacks when the label wouldn't fit.
- B2, hero text and scrim: a content-tied solid panel and a top scrim sized from the real inset.
- B3: the refresh spinner is purple.

**Fixed here.** 102/102 tests pass; the analyzer has 0 errors and 0 warnings.

| ID | Fix | Test |
|---|---|---|
| B4 | Section heading and content are separate `Semantics(container: true)` nodes. The card-level tap was removed from the poll, live and party cards, which each have their own button, so there's one stop per action. Discussion cards keep the card tap; they have no inner button. | The heading is a header, not a button, and doesn't absorb the poll rows |
| B5 | Single-pick poll: the footer is computed as "`total` of `members` members voted"; the hardcoded voter count is gone. | "24 of 31 members voted" |
| B6 | "Leading" is wrapping inline text (crown icon plus purple label) instead of a fixed-width badge. | No overflow at 320×568 at 2.0× |
| B7 | `DiscussionThreadScreen` takes `title` and `posterUrl`, defaulting to the old demo. `/discussionThread` reads them from `extra`. Discussion cards and the hero's "Discuss" pass their film. | A card opens its own film; Discuss opens the pick |
