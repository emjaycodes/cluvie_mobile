# Design review, round 7: Movie Detail, Vote, Discussion, and the Discover data fix

**Commits reviewed:** `87beb5c`, `5bbc63b` and `adbf5a5` on `feat/design-overhaul`:
- "fix(discover): use the backend's real film endpoints and envelope"
- "feat(movies): redesign Movie Detail, Vote and Discussion on the real API"
- "fix(movies): back works on deep links; thread bar names the screen"

**Scope:**
- `discover/data/tmdb.dart` and the Discover "Popular in clubs" header.
- `movie_details_screen.dart`, `vote_summary_screen.dart`, `discussion_thread_screen.dart` and `club_discussions_screen.dart`.
- `movies/data/film.dart`, `polls.dart` and `discussions.dart`.
- `current_user.dart` and `AuthRepository.savedUserId`.
- `core/utils/fit_text.dart` and `relative_time.dart`.
- `ClAppBar` / `ClBackButton` `fallbackRoute`.
- `routes.dart`.
- `test/movies_screens_test.dart` and `test/discover_screen_test.dart`.

**Backend checked (read only):** the `server.js` mounts, plus:
- routes: `tmdbRoutes`, `movieRoutes`, `pollRoutes`, `discussionRoutes`, `communitiesRoutes`, `watchlistRoutes`
- helpers: `utils/tmdbHelper.js`, `utils/movieCatalog.js`, `utils/movieCounters.js`
- models: `Movie`, `Poll`, `Discussion`

**Checks run:**
- `flutter analyze --no-fatal-infos`: 12 infos, 0 warnings, 0 errors. This matches the baseline, and none of the infos are in the changed files.
- `flutter test`: 244 of 244 pass.
- I grepped the changed feature files for `Colors.`, `Color(0x`, `GoogleFonts` and `Icons.` and found none.

**Probes:** I ran a throwaway probe in `test/_review/` and have since deleted it. Setup:
- Real fonts.
- `ClPosterImage.debugDisableNetwork = true`.
- `FakeApiClient` returning the backend's real shapes.

It covered:
- A full suggest round trip from Movie Detail.
- Retry with the request held open on a `Completer`, for the thread and for the Movie Detail discussion preview.
- A failed pull-to-refresh on Vote and on Club discussions.
- A 403 vote.
- A semantics read of the Vote rows before and after a vote.
- Club discussions at 2.0× on 320 and 390 wide, with long titles.
- The thread composer with the keyboard up, on 6 combinations of size, scale and keyboard height, with drafts of 2 to 5 lines.
- A semantics dump of Movie Detail.
- Tapping a snackbar's Retry after leaving the screen.

## Verdict

**Not ready to merge: 2 blocking findings.**

Most of this round is solid:
- **The P0 and P1 problems these screens had are gone.** That covers:
  - the hardcoded film, badge, cast and vote counts
  - Vote's debug footer and the admin-only "Close poll early"
  - the infinite-scroll demo copy
  - the inert reaction bar, Share and emoji controls
  - the 34pt Vote and 36pt send targets
  - the missing bottom `SafeArea`
  - the `Placeholder` discussion list
- **The endpoints are right.** The data layer now talks to routes that exist, with the right envelopes and id kinds:
  - TMDB ids for `/tmdb/:id` and `/movie/:id`
  - catalog Mongo ids for `/discussions/:movieId`
  - option ids for `/polls/:id/vote`
- **Back works on deep links.**

Two problems block the merge:
1. **Suggesting from Movie Detail succeeds silently.** The sheet closes with no confirmation, and the screen still says "No club has suggested this film yet."
2. **At 320pt and 2.0× text, a 4–5 line draft pushes the composer past the keyboard.** The Post button ends up under the keyboard, the post list collapses to 0dp, and the layout overflows.

## Findings

Severity: **B** = blocking, **S** = should-fix, **N** = nit.

| id | sev | file:line | finding | concrete fix |
|---|---|---|---|---|
| B1 | **B** | `movie_details_screen.dart:114`, `:217`, `:233-239`; `suggest_sheet.dart:74-76` | **Suggesting from Movie Detail gives no confirmation, and the screen then contradicts itself.**<br>• `onPressed: () => showSuggestSheet(context, film.toTmdbMovie())` ignores the returned club.<br>• On success, the sheet only `pop(club)`s. It shows a snackbar itself only when it is unmounted, because the caller is expected to report the result (as `suggestion_screen.dart:61-63` does).<br>Probe: the POST to `/communities/<club>/suggest` succeeds and the sheet closes, but **no snackbar** appears. `/movies/list` was fetched once and not again, so the discussion section still reads "No club has suggested this film yet. Suggest it to start the discussion.", directly under the button the user just used.<br>This is the primary action on the screen, and a user who gets no response from it will likely suggest again. The repeat then fails with a 409 that the sheet shows as a retryable error (S11). | `final club = await showSuggestSheet(...)`. When `club != null && context.mounted`:<br>• `ClSnackbar.show(context, message: 'Suggested ${film.title} to ${club.name}.', type: success)`<br>• `ref.invalidate(catalogFilmProvider(film.tmdbId))`, so the preview switches to "Start the discussion".<br>Extend the test "one suggest action…" to submit and assert both the snackbar and the refetch. |
| B2 | **B** | `discussion_thread_screen.dart:230-239`, `:402-403` | **The composer can grow past the keyboard and cover the screen.** The composer is a fixed sibling of `Expanded(list)` with `maxLines: 5`. At 2.0× a line is about 44dp, so five lines plus padding are taller than the space left above a keyboard on a small phone.<br>Probe at 320×568 @2.0 with a 260dp keyboard:<br>• **5 lines:** "RenderFlex overflowed by 32 pixels". The list is **0dp** tall, and the Post button's bottom edge is at **332** while the keyboard's top is at **308**, so the button is under the keyboard.<br>• **3 lines:** it fits, but the list is 56dp.<br>• **375×667 @2.0, 5 lines:** the list is 27dp.<br>With the list at 0dp, the drag-to-dismiss on the list (`keyboardDismissBehavior.onDrag`) has nothing to drag, so on iOS the user can't post or dismiss the keyboard without deleting text.<br>Audit 1.23 asked for the input to clear the home indicator and the keyboard. The test does that only at 390 @1.0 with one line. | Cap the composer's height, not its line count: wrap the `TextField` in `ConstrainedBox(maxHeight: min(5 lines, 0.35 × (height − viewInsets.bottom − toolbar)))`, so it scrolls inside. Or set `maxLines` from the text scale (5 at ≤1.3×, 3 above). Add the 320 @2.0 keyboard case, with a 5-line draft, to the matrix. Assert no exception, the Post button above the keyboard's top, and the list at least 1 row tall. |
| S1 | S | `discussion_thread_screen.dart:167-168`, `:188`; `movie_details_screen.dart:225-231`, `:251-257` | **"Try again" after a load error gives no feedback.** This is round 6's S4 again, in new code.<br>• The thread uses `when(skipLoadingOnRefresh: true)`. The Movie Detail preview uses the default, which is also `true`.<br>• `ref.invalidate` after an error is a refresh, so the error card stays put while the request is in flight.<br>Probe, with the retry held on a `Completer`: the thread shows the error card and 0 skeletons, and so does the Movie Detail discussion preview. The screen-level Movie Detail, Vote and Club discussions states use `skipLoadingOnRefresh: false` and are fine. | Use `skipLoadingOnRefresh: false` in both places. Pull-to-refresh on the thread goes through `reload()`, which never sets a loading state, so the posts won't flash. Add a held-retry test for each. |
| S2 | S | `vote_summary_screen.dart:66-75`, `:141`; `club_discussions_screen.dart:43-50`, `:66` | **A failed pull-to-refresh throws away the data on screen.** Both screens `invalidate` and render with `skipLoadingOnRefresh: false`, and `.when` gives the error priority.<br>Probe: after loading successfully, a failed refresh replaces the poll with "Couldn't load the vote", and the film list with "Couldn't load discussions". The thread does this correctly ("Couldn't refresh. Showing earlier posts."), and so do Discover and Suggest since round 6. Vote also clears `_local` and `_order` before the fetch.<br>`skipLoadingOnRefresh: false` also unmounts the `RefreshIndicator` mid-pull and puts the full skeleton in its place. | Separate retry-from-error from refresh-with-data. Refresh: `await ref.refresh(provider.future)` inside a try block. On failure with a value cached, keep the value via `skipError: true` and show the "Couldn't refresh. Showing earlier …" snackbar. Keep `skipLoadingOnRefresh: false` only while there is no value. |
| S3 | S | `vote_summary_screen.dart:270`, `:331-337` | **Each Vote row's spoken label starts with a rank that isn't shown, and after a vote that rank contradicts the order on screen.** The label is `'Number $rank, <title>, …'`, which is not label-in-name: the row shows the title first, and no rank is visible anywhere.<br>`rank` comes from the live `poll.ranked`, while the rows stay in their frozen order. Probe: after voting Past Lives into a tie it wins, the **first** row reads "Number 2, Oppenheimer, 5 votes", and the **second** reads "Number 1, Past Lives, …, Leading, your vote". | Start the label with the visible title: `'<title>, 5 votes, Leading, your vote. Open film details'`. Drop the rank, or show it on screen and take it from the frozen row order. Assert the label with `getSemantics` before and after a vote. |
| S4 | S | `polls.dart:160-172`; `vote_summary_screen.dart:108-116` | **A non-member's vote fails with a Retry that can never succeed.** `GET /polls/active` needs no auth or membership, so anyone who opens a club's Vote screen sees the Vote buttons. `POST /polls/:id/vote` then answers 403 ("You must be a member of this community to vote"), which `castVote` reports as `failed`.<br>Probe: the snackbar reads "Couldn't count your vote. Try again." and has a Retry button. A 400 "Invalid option" is handled the same way. | Add `VoteRefusal.notMember` for 403. Say "Join <club> to vote" and offer "Open club" (go to `/communities/:id`) instead of Retry. Better still, hide the Vote buttons for non-members, using `joinedCommunitiesProvider`. |
| S5 | S | `discussion_thread_screen.dart:425`, `:431` | **The send button puts a `textPrimary` icon on the `purple` fill.** tokens.md's on-colour table gives `purple #7C5CFF` no on-colour ("**none — no text allowed**"; "never white text on it"). Solid purple fills that carry content use `purpleBadge` with white, as the centre "+" does. | `backgroundColor: AppColors.purpleBadge` with a white icon. Keep `surfaceRaised` with `textSecondary` for the disabled state. |
| S6 | S | `club_discussions_screen.dart:138` | **Club discussions breaks long words mid-word at large text.** The row title is a plain `Text(film.title, style: title)`. This commit added `FitWordsText` for exactly this case and used it on the other three screens, but not here.<br>Probe at 2.0×: "Assassination" breaks mid-word at 320 **and** at 390. The screen isn't in the layout matrix. | Use `FitWordsText(film.title, styles: [title, label, bodySm])`. Hide the 48dp poster above 1.6×, as the other screens do. Add Club discussions to the 3×3 matrix with the long-title fixture. |
| S7 | S | `tmdb.dart:83-86`; `discover_screen.dart:235`; `film.dart:123-137` | **"Popular in clubs: The films clubs have voted for most" isn't true.** `/movies/list` is `Movie.find().sort({votes: -1})` with no limit.<br>• `Movie.votes` changes only through `POST /movies/:id/vote` (`movieCounters.addVote`), which nothing in the app calls now that votes go through polls. Every film stays at 0 votes, so the order is effectively insertion order.<br>• It returns the whole global catalog: every film any club has suggested, with no cap. The grid will grow without bound, and `catalogFilmProvider` downloads the full list just to find one id on every Movie Detail. | Change the copy to "Suggested in clubs", or rank from poll results once the backend can. Ask the backend for `?limit=` and a lookup by `tmdbId` (`GET /movies/tmdb/:tmdbId`). Until then, cap the grid client-side (for example 24 films), and share one cached `/movies/list` between Discover and Movie Detail instead of fetching it per film. |
| S8 | S | `tmdb.dart:100-109` | **When one Discover source fails, it disappears without a word.** If `/movies/trending` fails (TMDB 429, 502 or 503, or no API key), Discover shows only "Popular in clubs". There is no notice and no retry, apart from a pull-to-refresh nobody knows to try. The audit rejected this kind of silent fallback on this screen (1.10). | Return per-source errors, for example `({trending, popular, trendingFailed})`. Where a section failed, show a compact `ClErrorState` ("Couldn't load trending films", Try again). |
| S9 | S | `home_feed.dart:46`, `:92-99`, `:148`; `home_screen.dart:209`, `:484`, `:547`, `:961`; `notifications_screen.dart:145-147` | **Every film CTA on Home now leads to an empty state.** The Vote route no longer reads `options` from `extra`, and the thread needs `movieId`. Home's demo feed still sends `{title, posterUrl}` and the club id `friday-film-club`. So:<br>• Home's live-looking poll card, "Vote now", opens "No vote running — No active polls".<br>• Every "Discuss" opens "This discussion isn't open yet".<br>• Notifications' `demo-community` links do the same.<br>The destinations are now honest. The cause is Home's demo data (`TODO(api)`), but these commits turned a consistent demo into a contradiction the user can see. | Until Home has real data, hide Home's poll card and Discuss CTAs, or point them at the user's first joined club's real `/vote` and `/discussion`. Track this with the Home data task. |
| S10 | S | `test/movies_screens_test.dart:175-183`, `:288-297`, `:482-487`, `:517-539`; `test/discover_screen_test.dart:20-35` | **The tests miss both blocking findings and several shape contracts.**<br>• "one suggest action…" stops when the sheet opens, so B1 passes.<br>• The keyboard test covers only 390 @1.0 with a 1-line draft, so B2 passes.<br>• Retry is never tested with the request held (S1), and pull-to-refresh failure isn't tested on Vote or Club discussions (S2).<br>• Vote labels are found by substring and never checked to start with the visible text (S3). 403 isn't tested (S4).<br>• Club discussions has no layout or error test (S6).<br>• "a failed vote is rolled back, with retry" asserts that Retry exists but never taps it.<br>• Discover's fixtures use TMDB's item shape (`id`, `poster_path`, `release_date`) for `/movies/trending` and `/movies/list`. The real items are `{tmdbId, poster, releaseDate}` and Mongo docs `{_id, tmdbId, posterPath}`. If `TmdbMovie.fromJson`'s `tmdbId` fallback were removed, every trending film would become inert and the suite would still pass. The commit message says the fakes use "the backend's response shapes", but only the envelopes do.<br>• `currentUserIdProvider` is always overridden, so `savedUserId` and the "Sign in to vote" path are never run. `timeLeft`, `dayAndTime` and `styleThatFits` have no unit tests.<br>• The harness builds its own routes, so the real `routes.dart` entries (`/MovieDetails`, `/communities/:id/discussion`) are untested. | Add tests for each gap above. Use the real item shapes in the Discover and Suggest fixtures. Add unit tests for `savedUserId` (valid JWT, malformed token, no `id`), `timeLeft`, `dayAndTime` (including a DST boundary; see N2) and `styleThatFits`. Add one smoke test through the app's `router` for `/movie/:id`, `/communities/:id/vote` and `/communities/:id/discussion`. |
| S11 | S | `suggest_sheet.dart:79-87` (reached newly from `movie_details_screen.dart:114`) | **A duplicate suggestion shows as a retryable failure.** The backend returns `409 DUPLICATE_SUGGESTION` when the club already has the film. The sheet shows "Try again", which will always fail. From Movie Detail this is likely: the film may already be in the catalog, and B1 invites a second tap. | Map 409 `DUPLICATE_SUGGESTION` to "<club> already has <film>", with "Open discussion" or "Close". |
| N1 | N | `film.dart:6-12`; `movie_details_screen.dart:116-124` | Hiding the watchlist is defensible: the old `POST /watchlist` and `DELETE /watchlist/:id` never existed, and the real routes are `/watchlist/add` and `/watchlist/remove` with a Mongo id. But the comment's reason is incomplete. For any film a club has suggested, `catalogFilmProvider` already has the Mongo id. | Show the toggle when `catalogFilmProvider` returns an entry, using `{movieId: entry.id}`, or update the comment. |
| N2 | N | `relative_time.dart:47-51` | `dayAndTime` compares local midnights with `difference().inDays`. Across a DST change that difference is 23h, so `inDays` is 0 and a poll ending tomorrow reads "today at 20:00". `DateFormat.Hm()` is also always 24-hour, whatever the locale. | Compare `DateTime.utc(y, m, d)` values. Use `DateFormat.jm()`, or the platform's 24-hour setting. |
| N3 | N | `community_detail_screen.dart:101`, `:220` | Community Detail pushes `/communities/$id/vote` with no `extra`, so the title is the generic "Club vote". The raw id from audit 1.22 is gone, but the club's name is known. | Pass `extra: {'club': name}`, or have Vote read the name from the club provider. |
| N4 | N | `vote_summary_screen.dart:114-115`; `discussion_thread_screen.dart:114-115` | The error snackbar's Retry outlives the screen. In the probe, tapping it after leaving did nothing: no request and no error. It's a dead control for up to 3s. | Hide the current snackbar in `dispose`, or make the action a no-op with `if (!mounted) return` and say nothing. |
| N5 | N | `vote_summary_screen.dart:86-90`, `:123` | While `currentUserIdProvider` is still loading, `me` is null. A fast tap then says "Sign in to vote", and users who have already voted briefly see Vote buttons. | Treat `isLoading` as busy: disable the buttons until the provider has resolved. |
| N6 | N | `discussion_thread_screen.dart:100-104` | After a cold start `authNotifierProvider.user` is null, so the user's own new post shows as "Cluvie member" until a refresh. | Take the name from a current-user profile provider, or reload after posting. |
| N7 | N | `movie_details_screen.dart:330`; `vote_summary_screen.dart:142`; `club_discussions_screen.dart:67` | The "Loading…" labels aren't live regions, so the switch to content isn't announced. The suggest sheet's loading state is a live region. | Add `liveRegion: true`. |

## Audit coverage

| Audit item | Status |
|---|---|
| 1.21: `movieId` ignored; hardcoded film, badge, cast and tags | **Fixed.** Everything comes from `/tmdb/:id`, and missing fields are left out. Tested. |
| 1.21: "12 votes" vs. "42 votes" | **Fixed.** No vote counts are shown on Movie Detail. |
| 1.21: suggest posts to `demo` with no picker | **Fixed.** Movie Detail uses the shared sheet, which posts to the picked club. But a success gets no feedback and the screen goes stale (**B1**), and a duplicate shows as a retryable error (S11). |
| 1.21: snackbars before the API responds; "tap to retry" with no action | **Fixed** for errors. Success now shows nothing at all (B1). |
| 1.21: Share no-op; `_stale` never set | **Fixed.** Both are removed. |
| 1.21: custom `pop()` traps deep links | **Fixed.** `fallbackRoute: '/discover'`. Tested. |
| 1.21: the collapsed bar has no title | **Fixed.** The title fades in at 85% collapse. It is excluded from semantics while hidden, and the duration respects reduced motion. |
| 1.21: no loading or error states | **Fixed.** Skeleton, retry (which shows the skeleton while retrying) and not-found states. |
| 1.21: overflowing pills, button pair and cast row | **Fixed.** The pills `Wrap`, there's one button, and the cast is removed. The matrix passes at all 9 sizes. |
| 1.21 must keep: `movieId`, `push('/discussionThread')`, `POST /communities/:id/suggest` | **Kept.** |
| 1.21 must keep: `POST/DELETE /watchlist` | **Dropped, with reason.** Those endpoints never existed. The toggle could return for catalog films (N1). |
| 1.22: debug footer, hardcoded suggestions, raw id in title | **Fixed.** The title is generic when no name is passed (N3). |
| 1.22: unclear voting rule | **Fixed.** "You get one vote, and it's final.", "You've voted. Votes are final." and a multiple-choice variant, as a live region. |
| 1.22: "Close poll early" for everyone; Share; static watch-party link | **Fixed.** All removed. There is no close endpoint. |
| 1.22: refresh only resets the countdown; the countdown never ticks | **Fixed.** Refresh refetches and the countdown ticks every 30s. A failed refresh loses the data (**S2**). |
| 1.22: rows jump on vote | **Fixed.** The order is frozen until the next refresh. Tested. The spoken rank contradicts the frozen order (S3). |
| 1.22: raw date | **Fixed:** "Ends tomorrow at 20:00". There's a DST edge case (N2). |
| 1.22: 34pt Vote; 9pt WINNER | **Fixed.** The Vote button is a 48dp `ClButton` (secondary), and the leader badge is a `ClBadge` at caption size. |
| 1.22: no loading or empty states; `'No active polls — suggest a film!'` | **Fixed.** The contract copy is kept and tested. |
| 1.22 must keep: `POST /movies/:id/vote` with rollback | **Replaced** by `POST /polls/:id/vote` with an optimistic update and rollback, which is the backend's real club vote. Side effect: `Movie.votes` no longer moves, so S7. |
| 1.22 must keep: winner and tie sort | **Kept**, matching the server's `summarize`. Tested. |
| 1.22 must keep: `push('/discussionThread')` | **Kept**, as "Discuss <leader>". |
| 1.22 must keep: `push('/watchParty')` | **Dropped**, because it opened the static room (P1.3). Acceptable until the event-detail screen exists. |
| 1.23: infinite-scroll demo copy; "Past Lives" header; raw `communityId` chip | **Fixed.** Tested. |
| 1.23: inert reaction bar, emoji and share | **Fixed.** All removed. Like maps to the one-way upvote and is disabled once used. |
| 1.23: 36pt send; 24pt chips | **Fixed.** Send and like are at least 48dp. Tested. The send fill is off-token (S5). |
| 1.23: no bottom `SafeArea` | **Fixed** at normal sizes. At 320 @2.0 with the keyboard up, a 4–5 line draft pushes Post under the keyboard (**B2**). |
| 1.23: 2000 characters silently ignored; dev-note hint | **Fixed.** A formatter caps input, and a counter appears from 1800 characters as a live region. |
| 1.23: Enter conflicts with multiline | **Fixed.** Enter adds a newline and posting is by button. Tested. |
| 1.23: refresh fetches nothing; no loading or error states | **Fixed.** A failed refresh keeps the posts. Retrying after an error gives no feedback (S1). |
| 1.23: title and author row overflow; own colours | **Fixed.** The author row is a `Wrap` and the avatar steps aside above 1.6×. Tokens only. |
| 1.23 must keep: `'Be the first to comment'`, `PINNED`, pinned-first then newest, `RefreshIndicator`, 2000 limit | **All kept.** The client re-sorts, because the server sorts by upvotes as its second key. Tested. |
| 1.23 must keep: `communityId` param | **Replaced.** Discussions are keyed by the film's catalog id, as on the backend. `/communities/:id/discussion` now lists the club's films. |
| 1.24: Discussion List is a `Placeholder` | **Fixed** by `ClubDiscussionsScreen`. Long titles break mid-word (S6). |
| 1.25 / P2.1: orphan `MovieListScreen`; `suggest_movie_screen.dart`; `disscusion_` typo | **Fixed.** Deleted or renamed. |
| P0 #2 / #4: demo UI and inert controls on Vote and Discussion | **Fixed.** |
| P0 #7: tap targets on Vote and Discussion | **Fixed.** |
| P1.1: back is safe on deep links | **Fixed** for these four screens. |
| P1.2: one primary action on Movie Detail | **Fixed.** The suggest button is the only gold. |
| P1.3: one suggest flow | **Fixed.** All three entry points use `showSuggestSheet`, but the Movie Detail caller drops the result (B1). |
| P1.4: states everywhere | **Mostly.** See S1 and S2. |
| P1.8: data matches context | **Fixed on these screens.** Home feeds them demo context (S9). |
| §0: `/tmdb/*` calls | **Corrected.** `/tmdb/trending` and `/tmdb/popular` don't exist on the backend. Discover now uses `/movies/trending` (TMDB's weekly list) and `/movies/list`. `/tmdb/search` now reads the `{success, data}` envelope, which it didn't before. |

## Regressions elsewhere

- **`ClAppBar` and `ClBackButton`.** `fallbackRoute` is opt-in. Existing callers (Suggest's deep-link back, every other `ClAppBar`) keep their behaviour, because without it the leading button still needs `canPop`. Note that `canPop` is read at build time, as before.
- **`parseMovies` and `discoverFeedProvider`.** The new `keys` parameter defaults to `['data', 'results']`, so the Suggest screen, the only other caller, is unaffected. Its test fakes moved to the new envelope and paths. A trending failure on Suggest now has the same silent partial-failure behaviour as S8.
- **Routes.** `/communities/:id/vote` drops the `options` and `closesInMinutes` extras. `/discussionThread` now needs `movieId` in `extra`. This turns Home's and Notifications' demo CTAs into empty states (S9). `/MovieDetails` (no id) shows "not found" with a way back to Discover, which is the right outcome for a link with no id.
- **`currentUserIdProvider`.** It isn't autoDisposed and depends only on the login user id. After a cold-start session (id from the token), signing out doesn't recompute it until the next login, so it briefly holds the old id. Nothing reads it while signed out, so there's no visible effect.

## What works

- **The client matches the backend.** Every request goes to a mounted route, with the right id kind:
  - `Poll.fromJson` reads the populated `options.movie` (`title posterPath tmdbId`).
  - `castVote` maps `ALREADY_VOTED` and `POLL_CLOSED` by `code`.
  - The upvote's untyped 400 "Already upvoted" is treated as success.
  - `POST /discussions` reads `{discussion}` and falls back to a local post.
  - `/communities/:id/movies` and `/movies/list` are read as `{success, data}` and as a bare array respectively, and both are tolerated.
  - Non-Mongo ids (demo links) don't send a request at all.
- **The data is honest.** There are no invented years, ratings or posters:
  - The rating is hidden when TMDB has no votes.
  - "TMDB has no synopsis for this film yet." is shown when there's no synopsis.
  - Films are attributed to TMDB.
- **Voting behaves properly.** It is optimistic with rollback, the buttons lock while a vote is in flight, single-choice votes hide the buttons at once, and "already voted" reloads and explains itself. Rows don't jump, the countdown ticks and the timer is cancelled in `dispose`. Gold appears only on the first poll's leader badge.
- **The thread composer keeps the user's work.** The draft survives a failed post and the controller and focus node are disposed. The 2000-character cap has a visible counter, and the Post button shows a spinner while sending and can't be double-sent.
- **Layout holds in the existing matrix.** Movie Detail, Vote and Thread have no exceptions or broken words at 320, 375 and 390 wide, at 1.0×, 1.3× and 2.0×. `FitWordsText` steps a long title down a size rather than breaking it.
- **Semantics are mostly right.**
  - The film title, "Story" and "Discussion" are headers.
  - The rating reads "Rated 7.4 out of 10 on TMDB".
  - "Vote for <film>" and "<film>, N posts. Open film details" both start with the visible text.
  - The collapsed title is hidden from semantics until it's visible.
  - Error states are live regions.
- **Design-system compliance:** tokens and `Cl*` widgets only. Every `ClButton` sets its variant explicitly. Refresh indicators are purple and `textMuted` appears only on `bg`.

## Resolution (implementer, 2026-11-26)

All findings except S9, N1 and N3 are fixed (`9f9715a`, `e1d1166`, `e41403c`, `f203099`, `a34d382`, `a6fa11b`). 315/315 tests pass; the analyzer has 0 errors and 0 warnings (12 infos, unchanged, none in changed files).

| ID | Fix | Test |
|---|---|---|
| B1 | Movie Detail awaits `showSuggestSheet` and shows "Suggested <film> to <club>." The sheet invalidates the shared `catalogProvider` on success, so the discussion preview switches from "No club has suggested…" to the discussion. | Submits through the sheet; asserts the snackbar, a second `/movies/list` fetch and the new preview copy |
| B2 | The draft field's height is capped at min(5 lines, 35% of the body height from a `LayoutBuilder`) with `maxLines: null`, so it scrolls inside. (`MediaQuery` inside the Scaffold body has the keyboard inset removed, so the body height is measured directly.) | 3 sizes × 3 scales, keyboard up, 5-line draft: no exception, Post and field above the keyboard, list ≥ 48dp. It failed at 320 before the fix. Also an empty-draft case: the hint sits outside the field's scroll view, so above 1.2× it is the one-line "Write a post" (`a6fa11b`) |
| S1 | `skipLoadingOnRefresh: false` on the thread and on both Movie Detail preview states; the preview retry invalidates `catalogProvider`. | Held-`Completer` retry tests for the thread and the preview |
| S2 | Vote and Club discussions use `skipLoadingOnRefresh: hasValue` with `skipError: true`. A failed refresh with data keeps it and shows "Couldn't refresh. Showing the earlier vote." / "…earlier discussions." Vote clears `_local` and `_order` only after fresh data arrives. | Failed pull-to-refresh and held retry, on both screens |
| S3 | Row labels start with the title and drop the rank: "Past Lives, 4 votes, your vote. Open film details". | Exact labels via `getSemantics`, before and after a vote |
| S4 | `VoteRefusal.notMember` for 403: "Join <club> to vote" with "Open club", rolled back, no Retry. | 403 test, including the Open club navigation |
| S5 | The send fill is `purpleBadge`. | — |
| S6 | `FitWordsText` for the title; the poster and the "Open" hint step aside above 1.6×. Club discussions is in the 3×3 layout matrix with the long title. | Matrix |
| S7 | One kept-alive `catalogProvider` (`/movies/list`) serves Discover and `catalogFilmProvider`. The section is "Suggested in clubs: Films clubs have put forward to watch", capped at `kSuggestedInClubsLimit` (24). The backend `?limit=` and `GET /movies/tmdb/:tmdbId` asks remain for the backend. | Cap test |
| S8 | `DiscoverFeed` carries `trendingFailed` / `suggestedFailed`. A failed section shows its own compact error with retry, and a skeleton while retrying. Suggest shows "Couldn't load trending films" instead of the empty state. | Section-failure and held section-retry tests |
| S10 | Discover and Suggest fixtures use the real shapes (`{tmdbId, poster, releaseDate}`, Mongo docs). New `test/movies_units_test.dart`: `savedUserId`, the cold-start `currentUserIdProvider`, `timeLeft`, `dayAndTime`, `styleThatFits`, and the real router for `/movie/:id`, `/communities/:id/vote` and `/communities/:id/discussion`. Also: Retry on a failed vote is tapped, and the signed-out "Sign in to vote" path is tested. | — |
| S11 | A 409 `DUPLICATE_SUGGESTION` says "<club> already has <film>." (plus "Pick another club…" when there are others), disables submit for that club, and refreshes the catalog. | 409 test, then a successful suggest to another club |
| N2 | `dayAndTime` compares UTC calendar dates, and the Vote screen passes `MediaQuery.alwaysUse24HourFormatOf`. | Includes the EU spring-forward and fall-back nights |
| N4 | Retry actions are guarded with `if (mounted)`. | — |
| N5 | Voting is busy until `currentUserIdProvider` resolves. | — |
| N6 | After posting with no known user name, the thread reloads quietly. | The post test's fake now stores posts; asserts the author's name |
| N7 | Loading labels on Movie Detail, Vote and Club discussions are live regions. | — |

**Still open:**
- **S9 (needs a product decision):** Home's demo feed still sends Vote and Discuss CTAs to empty states. The options are to hide those CTAs while Home is demo data, or to wire Home to the real API.
- **N1:** the watchlist toggle for catalog films (`/watchlist/add {movieId}`) is a feature addition, deferred.
- **N3:** Community Detail is still the demo screen. Pass the club name when it is rebuilt in group 5.
