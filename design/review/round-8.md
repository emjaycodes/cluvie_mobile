# Design review, round 8: the round 7 fixes

**Commits reviewed:** `9f9715a` to `92a7e8b` on `feat/design-overhaul` (`git log adbf5a5..HEAD`):
- `9f9715a` fix(movies,discover): confirm suggestions and share one film catalog
- `e1d1166` fix(movies): keep the thread composer above the keyboard at large text
- `e41403c` fix(movies): keep data on failed refresh; honest vote labels and refusals
- `f203099` test(movies): unit and real-route tests; DST-safe poll end time
- `a34d382` fix(movies): show the author's name on a new post after a cold start
- `a6fa11b` fix(movies): the composer hint stays one line at large text
- `6eb5dd6`, `92a7e8b` design: round 7 resolution notes

**Scope:** `discover/data/tmdb.dart` (`catalogProvider`, `DiscoverFeed`), `discover_screen.dart`, `suggestion_screen.dart`, `suggest_sheet.dart`, `movies/data/film.dart`, `polls.dart`, `movie_details_screen.dart`, `vote_summary_screen.dart`, `discussion_thread_screen.dart`, `club_discussions_screen.dart`, `core/utils/relative_time.dart`, and the new and changed tests.

**Backend checked (read only):** `utils/movieCatalog.js` (`suggestToCommunity`: 409 `{success, message, code: 'DUPLICATE_SUGGESTION', data: movie}`), `routes/pollRoutes.js` (`vote`: 403 for non-members, after the `POLL_CLOSED` check), `routes/discussionRoutes.js` (`GET /:movieId` populates `userId` with `username`), `routes/communitiesRoutes.js` (`/:id/suggest`).

**Checks run:**
- `flutter analyze --no-fatal-infos`: 12 infos, 0 warnings, 0 errors. Same as the baseline, and none of the infos are in changed files.
- `flutter test`: **315 of 315 pass**. This confirms the implementer's count.
- I grepped the changed feature files for `Colors.`, `Color(0x`, `GoogleFonts` and `Icons.`. Every hit is `AppColors.*` or `AppIcons.*`. There are no raw colours, fonts or Material icons.

**Probes:** throwaway tests in `test/_review/`, now deleted. Setup: `loadRealFonts()`, `ClPosterImage.debugDisableNetwork = true`, and `FakeApiClient` returning the backend's shapes. They covered:
- The thread composer with a 1,899-character draft (so the counter row shows), keyboard up, at 320×568, 375×667 and 390×844, each at 1.0×, 1.3× and 2.0×.
- A semantics read of the composer field at 2.0×.
- Movie Detail opened, closed, and opened again after the catalog gained the film on the server.
- A 409 `DUPLICATE_SUGGESTION` from Movie Detail at 320 @2.0.
- A 403 vote.
- A Discover pull-to-refresh where only `/movies/trending` fails.
- A Discover "Suggested in clubs" section retry, counting requests.
- A Discover section error at 320 @2.0.
- A vote refused with `POLL_CLOSED` or `ALREADY_VOTED`, with the reload after it failing.
- Two quick posts after a cold start, with their quiet reloads held open and completed out of order.
- `dayAndTime` tests run with `TZ=Europe/London` and `TZ=America/New_York`.

## Verdict

**Ready to merge: 0 blocking findings.**

Both round 7 blockers are fixed and covered by tests:
- **B1:** a suggestion from Movie Detail is confirmed with a snackbar, and the preview updates.
- **B2:** the composer can't push Post under the keyboard at any size I tried, including with the counter row showing.

Every round 7 should-fix item the resolution claims is fixed in the code. S5 is mostly fixed: the icon colour isn't the token on-colour (R8-N5). S9, N1 and N3 remain deferred, as the resolution says. In this report, `R8-` marks a new round 8 finding, and plain IDs refer to round 7.

There are four new should-fix problems. None of them blocks the merge:
- **R8-S1:** the shared `catalogProvider` now lives for the whole session, so Movie Detail no longer sees films suggested elsewhere.
- **R8-S2:** a failed Discover refresh can replace a section that had loaded with an error card.
- **R8-S3:** the S2 change means a vote the server refused (closed, or already voted) can stay on screen as counted when the reload after it fails.
- **R8-S4:** the N6 quiet reload can let an older response hide the user's newest post.

R8-S3 is the one to fix before release. It's a two-line change.

## Findings

Severity: **B** = blocking, **S** = should-fix, **N** = nit.

| id | sev | file:line | finding | concrete fix |
|---|---|---|---|---|
| R8-S1 | S | `tmdb.dart:95`; `film.dart:125-126`; `movie_details_screen.dart:230` | **Movie Detail's discussion preview now goes stale for the whole session.** In round 7, `catalogFilmProvider` was autoDispose and fetched `/movies/list` on every visit. Now it reads `catalogProvider`, which is never disposed. Only three things refetch it: Discover pull-to-refresh, a retry from an error, and this device's own suggest sheet. Movie Detail has no pull-to-refresh.<br>Probe: I opened Movie Detail ("No club has suggested this film yet"), went back, added the film to the server catalog (another member suggesting it), and opened it again. `/movies/list` had been fetched **once**, and the screen still said "No club has suggested this film yet. Suggest it to start the discussion."<br>A plausible path: a club-mate suggests a film, the user opens it, is told nobody has, taps Suggest, and gets "Cinema Sundays already has Moonlight." The 409 handling copes with this, but the screen contradicted itself first.<br>Because the provider is never disposed, a failed `/movies/list` is cached too: every Movie Detail then opens on "Couldn't load the discussion" until someone taps retry. | Keep one shared fetch, but expire it:<br>• make `catalogProvider` autoDispose with `ref.keepAlive()` and a timer (for example 2–5 minutes), or<br>• refetch it when Movie Detail opens if the data is older than N seconds.<br>Add a test that opens Movie Detail, leaves, changes the catalog and reopens. |
| R8-S2 | S | `tmdb.dart:120-141`; `discover_screen.dart:239-256`, `:59-75` | **A failed Discover refresh can throw away a section that had loaded, without saying the refresh failed.** `discoverFeedProvider` only fails as a whole when both sources fail. When only one fails, the feed succeeds with `trendingFailed` (or `suggestedFailed`) set. The screen then swaps the loaded section for its error card, and `_refresh` doesn't throw, so the "Couldn't refresh. Showing earlier results." snackbar never shows.<br>Probe: I loaded Discover, then pulled to refresh with `/movies/trending` failing. Result: `Aftersun` ×0, "Couldn't load trending films" ×1, snackbar ×0. The same happens to "Suggested in clubs" when `/movies/list` fails on refresh.<br>This goes against the rule used on every other screen since round 6, and on Vote and Club discussions in this round: a failed refresh keeps the data. | In the provider, fall back to the earlier list when a source fails and one was cached:<br>`trending: results[0] ?? prev?.trending`<br>Set `trendingFailed` only when there's nothing to show. Have `_refresh` show the "Couldn't refresh" snackbar when a source failed but kept old data, for example via a `stale` flag on `DiscoverFeed`. Add a test for this: load, then refresh with one source failing. |
| R8-S3 | S | `vote_summary_screen.dart:113-118`, `:69-86` | **A refused vote can stay on screen as if it had counted.** For `alreadyVoted` and `closed`, `_vote` shows its snackbar and calls `_reload()`, but it never puts back `before`; the `notMember` and `failed` branches do. Before this round, `_reload()` cleared `_local` first, which removed the optimistic vote. Now `_local` is cleared only after a successful fetch, so when the follow-up `GET /polls/active` fails, the optimistic vote stays.<br>Probe: I voted, the POST returned 400 `POLL_CLOSED` (and separately `ALREADY_VOTED`), and the reload GET returned 503. In both cases the result was "Your vote" ×1, Vote buttons ×0, plus the "Couldn't refresh. Showing the earlier vote." snackbar, which replaced "This poll has closed". The server refused the vote, yet the row shows it counted, and the snackbar calls that state "the earlier vote", though it never existed. For `alreadyVoted`, the badge can sit on a different film from the one the user really voted for. | In the `alreadyVoted` and `closed` branches, run `setState(() => _local[poll.id] = before)` before `await _reload()`. Add a test for each refusal with the reload failing. |
| R8-S4 | S | `discussion_thread_screen.dart:110-114`; `discussions.dart:95-101` | **The quiet reload after posting can hide the user's newer post.** After a cold start, `user?.name` stays null, so every post triggers a `reload()` that isn't awaited. `reload()` ends with `state = fresh`, so whichever response arrives last wins, even if it was requested first.<br>Probe: I posted A, holding its reload GET open, then posted B. B's reload returned `[A, B]`, and then A's reload returned `[A]`. Result: "First post" ×1, "**Second post" ×0**. B stays hidden until the next refresh, though the server has it. This needs responses to arrive out of order, which happens on mobile networks. A post that vanishes invites the user to post it again. | Drop stale reloads: keep a request counter in `reload()` and ignore a response that isn't from the latest request. Or merge in any local posts the server list doesn't have, matched by id. Add a held-`Completer` test for two quick posts. |
| R8-N1 | N | `tmdb.dart:131-134`; `suggest_sheet.dart:84`, `:92` | Because `discoverFeedProvider` watches `catalogProvider`, anything that invalidates the catalog also refetches TMDB trending:<br>• the "Suggested in clubs" retry<br>• every successful or duplicate suggestion, from any screen, while the feed is alive<br>Probe: retrying the suggested section made 2 `/movies/trending` calls. This adds extra TMDB traffic, which is the source most likely to be rate-limited (429), and a trending failure caused this way then shows R8-S2's error card. | Give trending its own provider (`trendingProvider`) and have the feed watch both. Then a catalog invalidation leaves trending alone. |
| R8-N2 | N | `suggest_sheet.dart:249-265` | The 409 message is right ("Cinema Sundays already has Moonlight."), submit is disabled for that club, and the catalog is refetched. Probe at 320 @2.0: no exception, `/movies/list` fetched twice. Round 7's suggested "Open discussion" action wasn't added, though the 409 body carries `data: movie` with its `_id`. This is not required. | Optionally add an "Open discussion" text button that pops the sheet and pushes `/discussionThread` with `DiscussionThreadScreen.extraFor(movieId: data._id, …)`. |
| R8-N3 | N | `vote_summary_screen.dart:119-130` | The 403 path is right ("Join Cinema Sundays to vote", "Open club", no Retry, rolled back), and the probe confirms it. Two things remain:<br>• "Open club" uses `context.go`, which drops the back stack. From a deep link or from Home, back from the club no longer returns to the vote.<br>• Non-members still see three Vote buttons that can only be refused. That was round 7's "better still" option. | Use `context.push`. Hide the Vote buttons, or replace them with one "Join to vote" row, when the club isn't in `joinedCommunitiesProvider`. |
| R8-N4 | N | `test/movies_units_test.dart:84-90` | The DST test only proves anything when the suite runs in a timezone that has the EU transition. In UTC, where CI usually runs, the old local-midnight code also returns 1 day, so the test would pass against the bug it's meant to catch. The fix itself is correct: it passes under `TZ=Europe/London` and `TZ=America/New_York`. | Run this group under `TZ=Europe/London` in CI, or add a comment saying the test only bites in an EU timezone. |
| R8-N5 | N | `discussion_thread_screen.dart:466` | The send icon is `textPrimary` (`#F5F3FA`) on `purpleBadge`. tokens.md's on-colour for `purpleBadge` is white, and `AppColors.onPurpleBadge` exists and is used by the centre "+" (`cl_bottom_nav_bar.dart:249`). Round 7's fix asked for white. The contrast is about 5.6:1, so this is about token consistency only. | `color: canSend ? AppColors.onPurpleBadge : AppColors.textSecondary`. |

## Round 7 items

| id | status | evidence |
|---|---|---|
| B1 | **Fixed** | `movie_details_screen.dart:59-67` awaits the sheet and shows "Suggested <film> to <club>." `suggest_sheet.dart:84` invalidates `catalogProvider` through a container captured before the request, so it works even if the sheet has closed. The test at `movies_screens_test.dart:186` submits, then asserts the snackbar, a second `/movies/list` and the new preview copy. |
| B2 | **Fixed** | `discussion_thread_screen.dart:404-412`, `:427` caps the field at min(5 lines, 35% of the body), with `maxLines: null`. Probe with a 1,899-character draft, keyboard up, on all 9 size and scale combinations: no exception, Post above the keyboard (for example 264 vs. 308 at 320 @2.0), the counter row above the keyboard (300 vs. 308), and the list at least 99dp tall. The hint at 2.0× is "Write a post", which is also the field's spoken label. The 18 matrix tests at `:665-713` cover the empty and 5-line cases. |
| S1 | **Fixed** | `skipLoadingOnRefresh: false` at `discussion_thread_screen.dart:180` and `movie_details_screen.dart:240`, `:267`. Held-`Completer` tests are at `movies_screens_test.dart:221` and `:716`. Pull-to-refresh on the thread goes through `reload()`, which never enters loading, so the posts don't flash. |
| S2 | **Fixed**, with a new problem (R8-S3) | `vote_summary_screen.dart:69-86`, `:172-173` and `club_discussions_screen.dart:44-55`, `:72-73`. With `skipLoadingOnRefresh: hasValue` and `skipError: true`, a refresh with data keeps the data, and a retry from an error with no data shows the skeleton. I checked this against Riverpod 2.6's `when`: an error with a value plus `skipError` returns data. `_local` and `_order` are cleared only after a successful fetch. Tests are at `:419`, `:434`, `:782` and `:797`. That last change causes a new problem: see R8-S3. |
| S3 | **Fixed** | `vote_summary_screen.dart:364-369`: the label starts with the title, and the rank is gone. Tested by exact label at `:402`. |
| S4 | **Fixed** (see R8-N3) | `polls.dart:172` maps 403 to `notMember`, after the `code` checks. This matches the backend, which sends 403 only for non-members, after `POLL_CLOSED`. The UI is at `vote_summary_screen.dart:119-130`, tested at `:388`, and confirmed by probe. |
| S5 | **Mostly fixed** (see R8-N5) | `discussion_thread_screen.dart:460`: the fill is now `purpleBadge`, but the icon at `:466` is still `textPrimary`, not the token on-colour `onPurpleBadge` (white). The contrast is fine. |
| S6 | **Fixed** | `club_discussions_screen.dart:127`, `:146-159`: `FitWordsText`. The poster and "Open" step aside above 1.6×, and the screen is in the 3×3 matrix (`movies_screens_test.dart:875`). |
| S7 | **Fixed**, with a new problem (R8-S1) | The copy is "Suggested in clubs: Films clubs have put forward to watch", capped at 24 (`tmdb.dart:106`, `:131-133`) and tested. There is one shared `/movies/list`. The backend asks (`?limit=`, lookup by `tmdbId`) are still open. |
| S8 | **Fixed**, with a new problem (R8-S2) | Per-section `ClErrorState` with its own retry, and a skeleton while it retries (`discover_screen.dart:227-256`). Suggest shows "Couldn't load trending films" (`suggestion_screen.dart:243-257`). Tested. At 320 @2.0 there's no overflow, and the Try again target is 48dp. |
| S9 | **Deferred** (product decision) | Still `home_feed.dart:194` (`friday-film-club`), `home_screen.dart:547`, and `notifications_screen.dart:145-147`. |
| S10 | **Fixed** | Discover and Suggest fixtures use `{tmdbId, poster, releaseDate}` and Mongo docs. `movies_units_test.dart` covers `savedUserId`, the cold-start `currentUserIdProvider`, `timeLeft`, `dayAndTime`, `styleThatFits`, and the real router for the three routes. Retry on a vote is tapped, and the signed-out path is tested. The DST test is weak in UTC (R8-N4). |
| S11 | **Fixed** (see R8-N2) | `suggest_sheet.dart:91-103`, `:220`, `:249-265`. It matches the backend's 409 body. Tested in `suggest_screen_test.dart:186`, `:407`, and confirmed by probe at 320 @2.0. |
| N1 | **Deferred** | `kWatchlistAvailable = false` (`film.dart:12`). |
| N2 | **Fixed** | `relative_time.dart:47-61` uses UTC calendar dates, and `use24h` comes from `MediaQuery.alwaysUse24HourFormatOf` (`vote_summary_screen.dart:290`). `Poll.expiresAt` is converted with `toLocal()` (`polls.dart:126`), so the date parts are local. |
| N3 | **Deferred** | `community_detail_screen.dart:101` and `:220` still push with no `extra`. |
| N4 | **Fixed** | `mounted` guards on the Retry actions (`vote_summary_screen.dart:139-141`, `discussion_thread_screen.dart:123-125`). |
| N5 | **Fixed** | `resolvingMe` (`vote_summary_screen.dart:152-153`) keeps the rows busy until the id has resolved. An id that resolves to null counts as resolved, so the signed-out path still says "Sign in to vote". |
| N6 | **Fixed**, with a new problem (R8-S4) | `discussion_thread_screen.dart:110-114` reloads quietly when the name isn't known. The server populates `username`, which `DiscussionPost.fromJson` reads. Tested. |
| N7 | **Fixed** | `liveRegion: true` on the three loading labels. |

## Regressions elsewhere

- **The `discoverFeedProvider` record shape (`popular` → `suggested`, plus the `...Failed` flags).** Nothing in `lib/` or `test/` still reads `.popular`. There are two callers:
  - **Discover** handles both flags. Its top-level retry now invalidates `catalogProvider`, which rebuilds the feed, so both sources refetch.
  - **Suggest** uses only `trending` and `trendingFailed`. Its retry invalidates the feed and not the catalog, which is right.
  - A failed catalog never reaches Suggest, but every Suggest load now also fetches `/movies/list`, because the feed watches it. That's harmless.
- **`catalogFilmProvider`:** its contract is now "invalidate `catalogProvider`, not this". Both callers do that: the preview retry and the sheet. After a successful suggest, the preview briefly shows a skeleton while the catalog reloads, which is fine. See R8-S1 for the staleness.
- **`showSuggestSheet` result:** Movie Detail now uses it. `suggestion_screen.dart` reports the result as before. When the sheet is unmounted, it reports through `reportTo`, and the 409 copy reaches that path too.
- **`ClSnackbar`:** the API is unchanged. The new calls use the existing `type`, `actionLabel` and `onAction`. The snackbar action is purple per the token rules, which is unchanged.
- **`dayAndTime` signature:** `use24h` defaults to `true`, so existing callers keep the 24-hour output.
- **Analyzer and tests:** no new infos. 315 of 315 tests pass.

## What works

- **Both blockers are actually gone.** The composer keeps Post and the counter above the keyboard at every size and scale I tried, and leaves the list at least 99dp. The field scrolls inside its cap, and the large-text hint fits on one line.
- **Suggesting is honest end to end.** Success is confirmed and the preview updates. A duplicate is explained, not offered as a retry, and the catalog is refetched either way. Both work when the sheet has already closed, because the container is captured first.
- **The refresh pattern on Vote and Club discussions is right.** Data stays through a failed refresh, with a snackbar. A retry from an error shows the skeleton. The `RefreshIndicator` is no longer unmounted mid-pull, and the frozen row order resets only on fresh data.
- **Vote is clearer.** The spoken labels start with the title, and a 403 tells non-members to join instead of retrying (but see R8-S3 for the closed and already-voted refusals). Buttons wait for the user id, so there's no false "Sign in to vote".
- **The tests are much stronger.** They now include real response shapes, held-`Completer` retries, the composer keyboard matrix, real-route smoke tests, and unit tests for the utilities.
- **Design-system compliance holds.** Tokens and `Cl*` widgets only. The send fill is `purpleBadge` (the icon colour is R8-N5). The duplicate notice uses `textSecondary` on the sheet surface. Gold stays within budget, as the layout matrix's gold checks show.
