# Design review, round 6: Discover, Suggest and film search

**Commit reviewed:** `90a921d` on `feat/design-overhaul` ("feat(discover,suggest): redesign Discover, Suggest and film search").

**Scope:**
- `discover_screen.dart`, `movie_poster_tile.dart` and `discover/data/tmdb.dart`.
- `suggestion_screen.dart` and the new `suggest_sheet.dart`.
- The new `ClSearchField`.
- The `routes.dart` changes: the `/search` and `/MovieSearch` redirects, `/communities/:id/suggest`, and the deletion of `SuggestMovieDeepScreen` and `movie_search_screen.dart`.
- `unreadCountProvider` in `home_feed.dart`.
- The new tests and helpers: `discover_screen_test.dart`, `suggest_screen_test.dart`, `helpers/fakes.dart` and `helpers/design_checks.dart`, plus the Home test refactor.

**Checks run:**
- `flutter analyze --no-fatal-infos`: 15 infos, 0 warnings, 0 errors. This matches the baseline, and none of the infos are in the changed files.
- `flutter test`: 165 of 165 pass.
- Grep of the redesigned files for `Colors.`, `Color(0x`, `GoogleFonts` and `Icons.`: none.

**Measurements:** taken with a throwaway probe in `test/_probe/`, since deleted. Setup:
- Real fonts, `ClPosterImage.debugDisableNetwork = true` and the fakes from `test/helpers/fakes.dart`.
- Both screens mounted under `ClBottomNavBar` through a `ShellRoute`. The club deep link was on the root navigator, outside the shell.
- Insets of 20/34 on 320×568 and 375×667, and 47/34 on 390×844.
- Text at 1.0×, 1.3× and 2.0×.

For each of the 9 configurations the probe recorded:
- Exceptions while scrolling Discover from top to bottom.
- `didExceedMaxLines` on every paragraph.
- Every enabled `ClPressable` smaller than 48dp.
- Clearance between the last card and the nav.
- Whether the sheet's note field and caret stay above a simulated keyboard (260dp on the small phones, 300dp on 390), set through both `view.viewInsets` and `MediaQuery`.

It also ran:
- a semantics dump of Discover and of the sheet after a failed submit
- the feed error, no results and search error states at 2.0× on all three sizes
- a search in flight, and a search retry with the request held open
- a one-letter query, and the trending error on Suggest
- a tab switch with a search active
- a double tap and a barrier dismiss while a submit was pending
- a deep link to a club the user hasn't joined
- a reduced-motion run
- an unrestricted gold scan of the sheet

## Verdict

**Not ready to merge: 3 blocking findings.**

Most of the redesign holds:
- **The P0 problems are fixed.** The deep link crash, the demo films labelled "cached", the inert "Join Club", the hardcoded `demo` club and the fake XP are all gone.
- **Every audit contract is kept.** That covers the 300 ms debounce, both copy strings, the `/tmdb/*` endpoints, `POST /communities/:id/suggest` with `{tmdbId, note}`, `push('/movie/:id')` and the public `SuggestedClubsWidget`.
- **Layout is sound.** Nothing overflowed and nothing threw in any of the 9 configurations. Every enabled control is at least 48dp. The only gold is the sheet's submit button and the active tab.

Three problems remain:
1. **After a failed submit, the button says "Try again" but is announced as "Suggest Aftersun to Night Owls".** This is a label-in-name failure.
2. **`ClSearchField` overrides the input tokens.** Its resting border is the 8% decorative `border` instead of `borderInput`, and its focus state is a purple border instead of the 2px `focusRing`.
3. **Discover's bell now shows Home's demo unread count to every user.** It shows "3 unread" whatever the user's real notifications are.

## Findings

Severity: **B** = blocking, **S** = should-fix, **N** = nit.

| id | sev | file:line | finding | concrete fix |
|---|---|---|---|---|
| B1 | **B** | `suggest_sheet.dart:190-197` | **The submit button's spoken label contradicts its visible label after a failure.** The probe's semantics dump after a failed POST shows the visible text "Try again" while the node reads `label: "Suggest Aftersun to Night Owls"`. `semanticLabel` is set whenever a club is picked, and it overrides the visible text (`excludeChildSemantics`).<br>This fails WCAG 2.5.3 (label in name). A Voice Control or Voice Access user who says "tap Try again" gets no match. A screen-reader user hears no sign that the first attempt failed; only the separate live region says so.<br>When a club is picked and nothing has failed, the spoken label does start with "Suggest", so that state passes. | Build the spoken label from the visible text: `_failed ? 'Try again: suggest ${title} to $clubName' : 'Suggest ${title} to $clubName'`. Add a test that reads `t.getSemantics(submit).label` in both states and asserts it starts with the visible label. |
| B2 | **B** | `cl_search_field.dart:86-97` | **`ClSearchField` overrides the theme's input tokens.**<br>• At rest the border is `AppColors.border` (white @ 8%, decorative only). The `surfaceRaised` fill against `bg` is about 1.15:1. tokens.md defines `borderInput` (3.05:1 on raised) for exactly this, to meet WCAG 1.4.11, and the theme and `ClTextField` both use it.<br>• On focus the border is `purpleText` at 1.5px. The tokens States table says focus is the 2px `focusRing` "for all focusable controls". The theme's `focusedBorder` already does that, and the search field opts out of it.<br>Both Discover and Suggest use this field, so it is the main input on two tabs. | Remove the `border`, `enabledBorder` and `focusedBorder` overrides and inherit the theme. Keep only the pill radius: `borderSide: BorderSide(color: AppColors.borderInput)` at rest and `BorderSide(color: AppColors.focusRing, width: 2)` on focus. A gold focus ring is allowed by the budget. |
| B3 | **B** | `discover_screen.dart:79`, `:100-107`; `home_feed.dart:157-159`; `test/discover_screen_test.dart:165-168` | **Discover shows a demo unread count to every user.** `homeFeedProvider` returns `demoHomeFeed` (`TODO(api)`), and `unreadCountProvider` reads `unread: 3` from it. So Discover's bell reads "Notifications, 3 unread" with a badge for every user, whatever their real notifications are.<br>Audit P0 #2 listed Discover as a screen whose demo UI must go, and this commit takes out the demo films only to bring in a demo count. The test `the bell shows the same unread count as Home` asserts the fake "3".<br>Home's own demo feed was in place before this commit and is not new here. | Until notifications have a real source, have `unreadCountProvider` return 0, or hide the badge on Discover. Then the bell is honest: "Notifications", with no dot. Change the test to assert that the badge follows the provider, by overriding it with 2 and then 0, instead of asserting the demo value. |
| S1 | S | `suggest_sheet.dart:60-78`; `cl_bottom_sheet.dart:55-64` | **The sheet can be dismissed while a submit is in flight, and the result is then lost.**<br>• Probe: with the POST held open, a tap on the scrim closes the sheet. The POST then succeeds and nothing is shown: there's no snackbar, because the sheet's `pop(club)` never runs, so `_suggest` got `null`.<br>• If the POST had failed instead, the error would also go unseen.<br>A double tap is handled correctly: only one POST is sent. | While `_submitting`, block dismissal. Wrap the sheet body in `PopScope(canPop: !_submitting)`, and pass `isDismissible` and `enableDrag` through `showClSheet`. Or move the POST to the caller, so the screen reports the outcome either way. |
| S2 | S | `suggestion_screen.dart:82-90`, `:123-127`; `suggest_sheet.dart:52-58` | **A deep link to a club the user hasn't joined drops the club without a word.**<br>• Probe: `/communities/zz/suggest` opens with the generic copy "Pick a film, then choose the club…", and the sheet says "Pick a club".<br>• The user can then suggest to a *different* club without noticing.<br>• The same happens when `joinedCommunitiesProvider` fails.<br>• After a successful deep-link suggestion, the screen stays on Suggest with the search cleared, rather than going back to the club the user came from. | When `communityId` isn't among the joined clubs, show "Join <club> to suggest films", with a button that opens the club, instead of a picker for other clubs. Get the name from `allCommunitiesProvider` or a club lookup. On success from the deep link, `pop()` back to the club and show the snackbar there. |
| S3 | S | `suggest_sheet.dart:142-158`, `:241-246` | **The club picker doesn't read as a single choice.** In the dump, each row is a `button` with `isSelected` on the picked one, and nothing else. There's no `inMutuallyExclusiveGroup` and no checked state, so TalkBack doesn't announce "radio button, 1 of 3, not checked". The group label is a bare "Clubs". The code comment calls them "radio-style" rows. | Give each row `Semantics(inMutuallyExclusiveGroup: true, checked: selected)`, through a `ClPressable` option or a wrapper. Label the group "Suggest to" or "Choose a club". |
| S4 | S | `discover_screen.dart:167-170`; `suggestion_screen.dart:183-187`; `suggest_sheet.dart:109-116` | **"Try again" on a search error or a clubs error gives no feedback.** This is the same mechanism as round 5 S1.<br>• `ref.invalidate` keeps the error in the reload state, and `.when()` skips loading on refresh by default.<br>• Probe, with the retry held open: the error card stays, and no skeleton appears. The only change is the 18dp spinner in the search field, which isn't there at all in the sheet's clubs-error case.<br>The browse error paths are fine: `!feed.isLoading` sends them to the skeleton. | Use `when(skipLoadingOnRefresh: false, …)`, or check `isLoading` before `hasError`, for search results and the sheet's club list. Add a test that holds the retry with a `Completer` and expects the skeleton. |
| S5 | S | `discover_screen.dart:59-71`; `suggestion_screen.dart:68-80` | **A failed pull-to-refresh is silent.** If the feed is cached and the refresh fails, `valueOrNull` keeps the old films and the `catch (_) {}` swallows the error. The spinner just stops. Home shows a snackbar in the same case (round 5). | When the refresh fails and data is cached, call `ClSnackbar.show(type: error, message: "Couldn't refresh. Showing earlier results.")`. |
| S6 | S | `suggestion_screen.dart:136`; `cl_search_field.dart:81` | **The placeholder is cut off.** The field has no visible label, so its hint is the only visible name, and "Search films to suggest" is ellipsized at 320 @1.3 and at 2.0× on all three sizes. The spoken label is complete. Discover's shorter "Search films" fits everywhere. | Use "Search films" on Suggest too, since the header and subtitle already say "suggest". Or set `hintMaxLines: 2` and let the pill grow. |
| S7 | S | `test/suggest_screen_test.dart:140-158`, `:224-243`, `:200-212`; `test/discover_screen_test.dart:261-279` | **The new tests can't catch several of the problems they claim to guard.**<br>• **Spoken labels:** the retry test finds "Try again" by its visible text, so B1 passes.<br>• **Keyboard:** no test sets `viewInsets`.<br>• **Truncation:** the sheet's `expectNotTruncated` list holds only short names, so it can't fail at any of these sizes. The probe found long club names and the placeholder cut (S6).<br>• **States:** the Discover matrix runs only the browse state. The feed error, search error, no results and hint states are never laid out at 2.0×.<br>• **Deep link:** the test builds its own route tree, not `routes.dart`, so a wrong `parentNavigatorKey` on the real route would pass.<br>• **Gold scan:** it can't see gold inside illustration SVGs. That is allowed by tokens.md's Illustration rule, but the scan should say so.<br>• **Search field:** nothing checks its border tokens (B2). | Assert spoken labels with `getSemantics`. Add a keyboard test that sets `t.view.viewInsets` and asserts the caret rect is above `height - inset`. Include a long club name and long film titles in the fixtures. Run the state cards through the matrix. Add one smoke test that resolves `/communities/x/suggest` through the app's `router` and checks it sits on the root navigator. |
| N1 | N | `discover/data/tmdb.dart:97` | `movieSearchProvider` is `autoDispose`, so returning to Discover with a search active refetches it. The probe counted 2 calls to `/tmdb/search`. Browse isn't refetched, and the text and results come back, so the audit item holds. | `ref.keepAlive()` the provider for the current `discoverQueryProvider` value, or cache it for a short time. |
| N2 | N | `movie_poster_tile.dart:74`; `suggest_sheet.dart:263` | Long titles are cut to 2 lines, which is by design, and the spoken labels are complete. Examples: "Portrait of a Lady on Fire" in the 132dp trending row at 2.0×, and "Everything Everywhere All at Once" in the 3-column grid at 390. Long club names are also cut in the sheet at every size; the selected club is the one the user is committing to. | Allow the club name in the sheet 3 lines above 1.3×. The posters are fine. |
| N3 | N | `discover_screen.dart:139`; `suggestion_screen.dart:156` | The last card ends 16dp above the floating nav on every size, against about 59dp on Home. It's clear, but tight against a glass bar. | Use `ClBottomNavBar.contentPadding(context) + AppSpacing.xl` to match Home. |
| N4 | N | `suggest_sheet.dart:273`; `movie_poster_tile.dart:58` | The 22dp radio ring and the 28dp check badge are off the 16/20/24 icon scale. | Use 20 and 24. |
| N5 | N | `lib/core/api/tmdb_api.dart` | The old TMDB layer has no callers now that `tmdb.dart` replaces it. | Delete it. |
| — | FYI, out of scope | `movie_details_screen.dart:60`; git history | • Movie Detail still posts to `/communities/demo/suggest`. `showSuggestSheet` is built to be reused, so that phase should call it.<br>• `movie_search_screen.dart` is deleted, but its hardcoded TMDB key is still in git history. The audit (1.26) asks for the key to be **rotated**. | Use the sheet from Movie Detail. Rotate the TMDB key. |

## Audit coverage

| Audit item | Status |
|---|---|
| 1.10: demo films "Using cached data", and two banners | **Fixed.** There is one tap-to-retry card with the contract copy and no demo films. Tested. |
| 1.10: silent search fallback; no "searching" state | **Fixed.** There's a spinner in the field and a skeleton grid, and an error card with retry. The retry gives no feedback (S4). |
| 1.10: demo films push `/movie/0` | **Fixed.** Films with no id are inert and are not buttons. Tested. |
| 1.10: Popular capped at 4 and repeating | **Fixed.** The full grid is shown; all 7 render. |
| 1.10: hint says "clubs"; 2-character minimum not explained | **Fixed.** The hint is "Search films", and a live-region hint says "Keep typing: search starts at 2 letters." |
| 1.10: Suggested Clubs hardcoded, "Join Club" inert | **Fixed.** Real clubs the user isn't in are shown, and each card opens the club. They are hidden while loading or on error. `SuggestedClubsWidget` is still public. |
| 1.10: the shimmer hides search | **Fixed.** Tested. |
| 1.10 / §3: search lost on tab switch | **Fixed for Discover.** The text and results come back and browse isn't refetched; the search itself is refetched (N1). |
| 1.10: bell dot | **Made consistent, but with fake data (B3).** |
| 1.11: hardcoded clubs; POST to `demo` | **Fixed.** The user's real joined clubs are listed, and the POST goes to `/communities/<picked>/suggest` with `{tmdbId, note}`. Tested. |
| 1.11: demo results; no error state; invented year; 6-result cap | **Fixed.** |
| 1.11: inert "default club" link; snackbar promising a retry it doesn't have; fake XP | **Fixed.** The link is removed, and the error is now inline with a real retry. B1 is about that retry button's label. |
| 1.11: CTA below the fold; raw `ElevatedButton`; no refresh, search action or keyboard dismiss | **Fixed.** A sheet holds the `ClButton`, and there's a `RefreshIndicator`, `TextInputAction.search` and dismiss-on-drag. |
| 1.12 / P0 #1: deep link crashes | **Fixed.** It opens on the root navigator with no exception, a back button and no nav bar. Bottom padding is the safe inset plus 16. The club is preselected **if the user has joined it** (S2). |
| 1.12: "search TMDB above" copy; raw id shown | **Fixed.** |
| 1.26: `/search`, undebounced, API key | **Fixed.** The screen is deleted, and `/search` and `/MovieSearch` redirect to `/discover`. Rotate the key (FYI). |
| §3: three suggest flows | **Two remain.** Tab and deep link share one screen and sheet; Movie Detail is still separate (FYI). |
| §0 contracts | **All hold:** the 300 ms debounce (`kSearchDebounce`, tested at 250 and 310 ms), both copy strings, the `/tmdb/*` endpoints through `apiClientProvider`, the suggest POST and its payload, `push('/movie/:id')`, `push('/notifications')` and `SuggestedClubsWidget`. |

## Regressions elsewhere

- **`home_feed.dart`.** It only adds `unreadCountProvider`. Home still reads `feed.unread` directly, so it's unaffected. The problem is the Discover consumer (B3).
- **Home tests.** The gold scan, broken-word check and `isGold` moved to `test/helpers/design_checks.dart` unchanged. The `_FloatingNav`-only exemption is kept, and Home's negative-control test still exercises the shared scan. All Home tests pass.
- **Routes.** `SuggestMovieDeepScreen` and `MovieSearchScreen` have no remaining references. Both of Community Detail's CTAs push `/communities/$id/suggest`, which now resolves.

## What works

- **Every state now exists, and each is honest.** For Discover:
  - A skeleton that leaves the search field usable.
  - One retry card using the contract copy.
  - Search in flight, search error, no results with the contract copy, and the one-letter hint.
  - "Clubs to join" hidden on error.

  For Suggest:
  - A trending error with retry, and an empty trending state.
  - In the sheet: clubs loading, clubs error, no clubs (with "Find a club", which goes to `/communities`), and an inline submit error with a working retry.
- **There is no fake content in the films or clubs.** The year is left out when unknown, and films with no id are inert.
- **Layout is robust across the matrix.** There are no exceptions or broken words at any of the nine size and scale combinations. The grid drops to 2 columns on small phones and at large text, and each cell's height is measured from the text scale. The retry card, no-results card and error card all fit at 320 @2.0.
- **The keyboard works.** The sheet pads its content by `viewInsets` and scrolls. With a keyboard up, the note field's caret stays visible at every size and scale. At 320 @2.0 the caret is at 253–297 with the keyboard top at 308, so only the field's lower lines go under the keyboard.
- **Touch targets:** no enabled `ClPressable` is under 48dp at any size or scale, and the clear button is 48×48.
- **The gold budget holds.** Discover has no gold. Suggest has none on the screen, and in the sheet the only gold is the submit button. An unrestricted scan of the sheet before a club is picked finds no gold at all. Selection is purple, as are the radio check, the poster selection ring and both refresh indicators.
- **Semantics are mostly clean.** Each poster is a single button reading "Title, year", and the posters themselves are decorative. The search field is named by its hint, the sheet title and "Suggest to" are headers, and the club rows read "Name, N members". The submit label is right in every state except a failure (B1).
- **Reduced motion is respected.** The sheet opens with `AnimationStyle.noAnimation` and is fully shown after one frame. Skeletons are static, and the press scale uses zeroed durations.
- **The data layer is clean.** All TMDB traffic goes through `apiClientProvider`. Search results are keyed by query, so a slow old response can't overwrite a newer one. The feed isn't auto-disposed, so switching tabs doesn't refetch it.

---

## Resolution (implementer, 2026-11-25)

All findings are fixed. 184/184 tests pass; the analyzer has 0 errors and 0 warnings (15 infos, unchanged).

| ID | Fix | Test |
|---|---|---|
| B1 | The spoken label starts with the visible text: "Suggest <film> to <club>" normally, "Try again: suggest <film> to <club>" after a failure. | Both labels are asserted via `bySemanticsLabel`; the old label must be gone after a failure |
| B2 | `ClSearchField` uses `borderInput` at rest and the 2px `focusRing` when focused, on the pill radius. | The decoration's border tokens are asserted |
| B3 | `unreadCountProvider` returns 0 until notifications have an endpoint, so no bell shows a made-up count. Home's bell reads it too, so the bells agree. | Badge follows the provider (2 → "2 unread", 0 → no badge); Home tests override it |
| S1 | `PopScope(canPop: !_submitting)` blocks dismissal mid-send. If the sheet is gone anyway, the outcome is reported via the opener's context (`reportTo`). | Scrim tap mid-send leaves the sheet open; the result is shown on completion |
| S2 | A deep link to a club the user isn't in shows "You're not in <club> yet…" with "Open club", not a picker for other clubs. A successful deep-link suggestion pops back to the club and shows the snackbar there. | Both covered |
| S3 | `ClPressable` gains `checked` and `inMutuallyExclusiveGroup`; club rows use them. The group label is "Choose a club". | Radio flags asserted |
| S4 | Search results and the sheet's club list show the skeleton while a retry after an error is in flight. A failed refresh keeps earlier results (`skipError`). | Retry with a held `Completer`, for both search and clubs |
| S5 | A failed pull-to-refresh with results on screen shows "Couldn't refresh. Showing earlier results." on both screens. | Discover test |
| S6 | The Suggest hint is "Search films" (the header already says "suggest"). | The hint is checked for truncation while the field is empty, across the matrix |
| S7 | Added: spoken-label, keyboard (insets at 3 sizes; the note field scrolls above the keyboard), long club name fixture, hint / no-results / search-error / feed-error states across the 3×3 matrix, and a check that the app's real `/communities/:id/suggest` route isn't under the shell. | — |
| N1 | Search results are kept alive for 5 minutes. | — |
| N2 | Club names in the sheet are never truncated. Above 1.6× the decorative avatar steps aside so long words don't break. | Long-name fixture in the matrix |
| N3 | Bottom clearance is `contentPadding + xl`, matching Home. | — |
| N4 | The radio ring is 20 and the check badge 24. | — |
| N5 | `lib/core/api/tmdb_api.dart` deleted (no callers). | — |

**Still open, and outside this group:**
- Movie Detail should call `showSuggestSheet` (group 4).
- The TMDB key in git history must be rotated by whoever owns it.
