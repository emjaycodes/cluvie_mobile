# Cluvie UX Audit: current screens (pre-overhaul)

Branch `feat/design-overhaul` · audited 2026-11-24 · input to the design overhaul. This is a record of **what exists today**. It does not propose a visual style; that lives in `design/tokens.md`.

**Scope:** every file under `lib/features/*/presentation/`, plus `lib/features/home/components/`, `lib/core/theme/widgets/`, and `lib/core/router/routes.dart`.

**Method notes**
- I read the code but did not run the app. Overflow findings at 320pt and 1.3× text are **predictions from layout code**: non-flexible `Row`s, fixed heights, and non-scrolling `Column`s. Confirm each one on a device or golden test.
- The style-debt count is the number of **occurrences** of `Colors.`, `Color(0x`, `TextStyle(`, `GoogleFonts.` and `Icons.`, with comment lines excluded (`grep -v '^\s*//' | grep -oE … | wc -l`). Format: **total (Colors / Color(0x / TextStyle / GoogleFonts / Icons)**. No screen uses `GoogleFonts.` directly; fonts come through `AppTextStyles`.
- The app is **dark-only**: `lib/app.dart:13` forces `ThemeMode.dark`. Several shared widgets still default to light colors (see §2).

---

## 0. Read this first: what the overhaul must not break

- **The tests are decoupled from `lib/`.** None of the four files in `test/` imports anything from `lib/`. `voting_card_test.dart`, `discussion_card_test.dart` and `discover_search_test.dart` declare their own copies of `VotingCard`, `DiscussionCard`, `DebouncedSearchField`, `RetryCard` and so on.
  - So **no widget key in `lib/` is bound by a test**. The only key in `lib/` is `ValueKey(m['title'])` at `profile_screen.dart:240`.
  - The test-local class names `VotingCard` and `DiscussionCard` collide with the unused classes in `lib/features/home/components/`.
- **Behaviour and copy contracts that the tests mirror.** Keep these, or change them together with the tests:
  - The 300 ms search debounce (Discover, Suggest).
  - `"Couldn't load Discover — tap to retry"` (Discover error).
  - `"No results for '<q>' — try another title"` (Discover, Suggest).
  - `'No active polls — suggest a film!'` (Home poll empty state).
  - `'Be the first to comment'` (Discussion empty state).
  - The `WINNER` badge, with winner = most votes and ties going to the earliest suggestion (Vote Summary, Home).
  - The `PINNED` badge, with pinned comments sorted first and the rest newest-first (Discussion).
  - A `RefreshIndicator` on the discussion list.
- **Providers in use:**
  - `authProvider` is a mocked `StateProvider` defined inside `splash_screen.dart:8`.
  - `authNotifierProvider` (login, signup).
  - `allCommunitiesProvider` (Community List).
  - `joinedCommunitiesProvider` (Create Community; the orphan Joined screen).
  - `movieNotifierProvider` (the orphan MovieListScreen).
  - Five screens construct `ApiClient()` directly: Discover, Suggest, Movie Detail, Vote Summary and Profile. It is a singleton factory, so this is harmless, but it is inconsistent with `apiClientProvider`.
- **API calls that screens make.** Keep these wired:
  - `GET /tmdb/trending`, `/tmdb/popular`, `/tmdb/search`
  - `POST /communities/:id/suggest`
  - `POST/DELETE /watchlist`, `GET /watchlist`
  - `POST /movies/:id/vote`
- **Navigation targets** are listed in each screen section. Route **names** in `RouteNames` and route **paths** are both used: some calls go by path string, others by name.

---

## 1. Screens

### Auth

#### 1.1 Splash: `authentication/presentation/splash_screen.dart`
- **Route:** `/splash`, the router's `initialLocation` (`routes.dart:45`). It is shown on every cold start.
- **Purpose:** an auth check. **Primary action:** none (automatic).
- **Problems**
  - `authProvider` is hard-mocked to `true` (`:8`), so it always goes to Home (`:30`). The router redirect is a no-op (`routes.dart:51-54`). Onboarding, Welcome and Login are **never reached on cold start**.
  - There is a fixed 2 s artificial delay (`:25`).
  - The screen is only a bare spinner, with no brand and no timeout or error path (`:38-42`).
- **Style debt:** 0. Uses no Cl* widgets; it bypasses `ClLoading`.
- **Must keep:** `authProvider` (`:8`), `goNamed(home|login)` (`:30`, `:32`).

#### 1.2 Onboarding: `onboarding_screen.dart`
- **Route:** `/` (named `onboardingRoot`) and `/onboarding-legacy`. **Reached:** nothing in the app navigates here now; only by URL.
- **Purpose:** a 3-page intro. **Primary action:** "Get Started" (last page only), which calls `pushNamed(signup)` (`:118`).
- **Problems**
  - "skip" is plain `Text`, not tappable, and lowercase (`:87-95`). It is a dead control.
  - Pages 1–2 have no Next button; swiping is the only way forward.
  - "Get Started" skips Welcome and *pushes* Signup, so Back returns to onboarding.
  - The dots indicator is rendered inside each page, so it scrolls with the page, and its `pageLength: 3` is hardcoded (`:111`).
  - **Overflow risk:** a non-scrolling `Column` holds a 300pt SVG and a 28pt headline between two `Spacer`s (`:80-121`). This will overflow on short phones at 1.3× text.
- **Style debt:** 3 (1/0/2/0/0). Uses `ClButton`.
- **Must keep:** `RouteNames.signup`, `DotsIndicatorWidget`.

#### 1.3 Welcome: `welcome_screen.dart`
- **Route:** `/welcome`. **Reached:** only from Profile → Log out (`profile_screen.dart:294`).
- **Purpose:** choose a sign-up method. **Primary action:** "Continue with Email", which calls `pushNamed('signup')` with a string literal (`:109`).
- **Problems**
  - "Continue with Apple" and "Continue with Google" are **dead CTAs** with `onPressed: () {}` (`:53`, `:66`).
  - The glass card has a fixed height of 380 (`:47`) and the Column does not scroll (`:25`). The contents are about 330pt at 1.0×, so this **will overflow at 1.3× text**.
  - `AuthButton` forces `minimumSize: Size(300, 50)` (`:164`). At 320pt wide, after screen and glass padding, less than 300pt is available, so there is a **horizontal overflow risk**.
  - "Log in" is a default `TextButton` under a separate `Text` (`:116-122`), unlike the inline row used on Login.
  - The logo SVG is drawn at an odd 50×100 (`:27-31`).
- **Style debt:** 12 (10/0/1/0/1). Uses no Cl* widgets; it bypasses `ClButton` with its own `AuthButton` (`:135-171`).
- **Must keep:** `RouteNames.login`, the `signup` route, and the shared `AuthGlassmorphicContainer` (imported from `login_screen.dart`).

#### 1.4 Login: `login_screen.dart`
- **Route:** `/login`. **Reached:** splash (if logged out), Welcome, Signup's link, and Forgot Password (both the link and the dialog).
- **Purpose:** sign in. **Primary action:** "Log in" (`:128-131`).
- **Problems**
  - **Validation is commented out** (`:27`), and so is the real login call (`:30`). Any input goes straight to Home (`:33`).
  - The error state **replaces the whole form** (`:47-66`), so the user loses what they typed. Its Retry calls `login("email", "password")` with string literals (`:58-60`). It uses a raw `ElevatedButton` and `Colors.red` (`:54-62`).
  - The loading state also replaces the whole screen (`:41-43`).
  - `Padding > Expanded` is a ParentData misuse (`:67-69`). It reports an "Incorrect use of ParentDataWidget" error in debug; release ignores it.
  - The fields use hints only, with no labels (`:87-104`).
  - There are no `autofillHints`, `textInputAction` or `onFieldSubmitted`, and no password visibility toggle (`:105`).
  - There is no app bar or back button even though the screen is *pushed* from Welcome, so iOS users only have edge-swipe.
  - The glass container defaults to a fixed 427.5×427.5 (`:252-253`). Height is the risk at 1.3×; width is clamped by the parent.
  - About 75 lines of dead commented code (`:154-228`).
- **Style debt:** 6 (5/0/1/0/0). Uses `ClButton` and `ClLoading`; bypasses `ClTextField` and `ClAppBar`.
- **Must keep:** `authNotifierProvider` (`.isLoading`, `.error`, `.login()`) and `RouteNames.forgotPassword|signup|home`. `AuthGlassmorphicContainer` is defined here and used by Welcome and Signup.

#### 1.5 Signup: `sigup_screen.dart` (filename typo)
- **Route:** `/signup`. **Reached:** Onboarding, Welcome, Login.
- **Purpose:** create an account. **Primary action:** "Create Account" (`:136-145`).
- **Problems**
  - **On success it navigates to `goNamed(RouteNames.movies)` (`:35`), but no route has that name, so it throws.** Signup can never complete.
  - While loading, the button is disabled by passing `() {}` and changing its label (`:138-145`) instead of using `ClButton.isLoading`.
  - The error state replaces the form (`:51-74`).
  - `Padding > Expanded` again (`:76-77`).
  - The glass card has a fixed height of 450 with a `Spacer` inside (`:91`, `:154`), so it will overflow at 1.3×.
  - Hints and labels are mixed: the name and email fields have hints, the password field has a label (`:96`, `:110`, `:124`).
  - There is no password visibility toggle or confirmation, and no autofill or `textInputAction`.
  - Copy typo in the link: `" have an account? Login"` (`:151`).
  - There is no back button (no app bar).
- **Style debt:** 2 (1/0/1/0/0). Uses `ClButton`. The `ClLoading` hit is inside a comment.
- **Must keep:** `authNotifierProvider.register(username, email, password)`, `RouteNames.login`.

#### 1.6 Forgot Password: `forgot_password_screen.dart`
- **Route:** `/forgotPassword`. **Reached:** Login.
- **Purpose:** request a reset link. **Primary action:** "Send Reset Link" (`:77-81`).
- **Problems**
  - The request is faked with a 2 s delay and no API call (`:29`).
  - `_loading` is never reset (`:27`). If the dialog is dismissed by tapping outside it, the button **stays in its spinner state forever**.
  - The "Login" link uses `pushNamed(login)` (`:90`), which stacks a duplicate Login on the back stack.
  - There is no app bar or back button (`:50-51`).
  - The heading uses `Theme.textTheme.headlineSmall` (`:61`) while the other auth screens use `AppTextStyles.heading1`. There is no glass card, unlike Login and Signup.
- **Style debt:** 0. Uses `ClButton` (with `isLoading` used correctly).
- **Must keep:** `RouteNames.login`.

#### 1.7 Email Verification: `email_verification_screen.dart`
- **The whole file is commented out** and the screen is unrouted. Delete it, or rebuild it if verification is in scope.

### Shell tabs (`ClBottomNavBar`, `routes.dart:181-250`)

#### 1.8 Home: `home/presentation/home_screen.dart`
- **Route:** `/home`, tab 0. **Reached:** splash, login, the bottom nav.
- **Purpose:** a feed of active polls, recent discussions and upcoming watch parties. **Primary action:** **unclear**. About 7 gold CTAs compete: "Vote now" and "Vote — tie needs your pick" (`:306-312`, ×2), two "View all" links, two RSVP buttons, and "Join Live".
- **Problems**
  - **QA-only UI ships to users:**
    - Tapping a section title toggles its empty state (`:65`, `:83`, `:193-194`).
    - The hint "Pull to refresh · Tap section titles to toggle empty states" is rendered on screen (`:169-172`). Its comment says "hidden in prod", but it is not hidden.
  - All content is hardcoded (`:71-167`). Pull-to-refresh is fake: a 700 ms delay followed by `setState` (`:22-25`).
  - There are **no loading or error states**.
  - The vote CTAs go to the hardcoded `/communities/demo/vote` (`:64`, `:309`).
  - Discussions "View all" opens a *single* thread at `/discussionThread` (`:82`), because no discussion list exists.
  - The "RSVP" and "Maybe" buttons open the **live room** at `/watchParty` (`:113`, `:121`), so the labels don't match the destination. "Maybe" also reads oddly as a button label (`:120`).
  - Dead or misleading affordances:
    - "Join Live" is a non-tappable `Container` (`:146-150`).
    - The discussion card shows "comment →" but neither the text nor the card has `onTap` (`:329-370`).
  - Demo data contradicts itself:
    - The second poll says "tie needs your pick" but already shows a WINNER (`:243-244`, `:311`).
    - The first poll has a "Past Lives (tie)" row (`:250`).
  - The bell's red dot is always on, whatever the unread count (`:42-46`).
  - **Visual size:** RSVP *looks* about 36pt tall (`:408`). Its hit area is padded to 48pt by Material's default `MaterialTapTargetSize.padded`, so this is a consistency issue, not a tap-target failure.
  - Text sizes of 9–11pt: WINNER (`:299`), PINNED (`:355`), replies (`:363`).
  - **Overflow:** the poll header has a fixed-width chip ("Cinema Sundays · ends in 18h"), then a `Spacer`, then a vote count (`:263-271`). This will overflow at 320pt and 1.3×.
  - The app bar uses a logo row with "CLUVIE", unlike every other tab, which uses a text title.
  - It reimplements its own private `_EmptyCard`, `_DiscussionCard` and `_WatchPartyCard`, and uses none of `home/components/`.
- **Style debt:** **95** (82/0/5/0/8), the highest in the app. Uses no Cl* widgets; it bypasses `ClCard`, `ClButton`, `ClEmptyState` and `ClChip`.
- **Must keep:**
  - Navigation: `push('/notifications')`, `push('/communities/:id/vote')`, `push('/discussionThread')`, `push('/watch-parties')`, `push('/watchParty')`, `go('/suggest')`.
  - Copy: `'No active polls — suggest a film!'` (test contract).

#### 1.9 Home components: `home/components/*`, `home/components/widgets/watch_card.dart`
- **`DiscussionCard`, `ReactionFooter`, `SectionTitle`, `UpcomingWatchCard`, `VotingCard` and `WeeklyWatchlist` are all unused.** Nothing in `lib/` references them. `MovieListScreen` declares its own `SectionTitle`.
- Problems, should any of them be revived:
  - `Image.network` with no placeholder or error widget (`discussion_card.dart:30`, `upcoming_watchcard.dart:22`, `watch_card.dart:74`).
  - Hardcoded content: "Arrival", "SAT, APR 13", "52%", "David just reacted…".
  - In `UpcomingWatchCard`, the text `Column` is not `Expanded`, so it overflows (`upcoming_watchcard.dart:30`).
  - `WeeklyWatchlist` pushes `/movieDetails` (`watch_card.dart:46`), and **no route has that path**. The legacy path is `/MovieDetails` and the real one is `/movie/:id`.
- **Style debt:** 26 across the files. Uses no Cl* widgets.
- **Recommendation:** delete them, or rebuild them as the real shared feed components that Home uses. Rename to avoid the test-name collision.

#### 1.10 Discover: `discover/presentation/discover_screen.dart`
- **Route:** `/discover` (and `/Discover`), tab 1.
- **Purpose:** browse trending and popular films and search TMDB. **Primary action:** search, then tap a poster to open `/movie/:id` (`:277`).
- **Problems**
  - When the request fails, it shows **hardcoded demo films labelled "Using cached data"** (`:84-94`, `:147-157`). That is not cache. It also shows the error card at the same time (`:158-172`), so there are two banners for one failure.
  - Search failures silently fall back to filtered demo data (`:104-106`). There is no "searching…" indicator; Suggest has one.
  - The demo films have no `id`, so tapping one pushes `/movie/0` (`:248-253`, `:277`).
  - The "Popular" grid has a hardcoded `childCount: 4` with `i % length` (`:219`). It repeats items when there are fewer than 4, truncates when there are more, and has no "see all".
  - The hint says "Search movies, clubs..." (`:136`), but only movies are searched.
  - The search needs at least 2 characters (`:54`) and nothing tells the user.
  - "Suggested Clubs" is hardcoded. The "Join Club" pill and the cards are **not tappable** (`:320-355`).
  - The loading shimmer replaces the whole screen, including the search field (`:121-122`).
  - Because tabs switch with `context.go`, the screen **reloads and loses the search on every tab switch** (see §3).
  - The bell has no unread dot, while Home's is always on.
- **Style debt:** 47 (37/0/2/0/8). Uses `ClEmptyState`. It bypasses `ClTextField`, `ClStatusBanner` (it reimplements the stale and error banners) and `ClCard`.
- **Must keep:**
  - The 300 ms debounce (`:52`) and the retry and empty copy (test contracts).
  - The `/tmdb/*` endpoints, `push('/movie/:id')`, `push('/notifications')`, `SuggestedClubsWidget` (public class).

#### 1.11 Suggest (tab): `suggest/presentation/suggestion_screen.dart` (class `SuggestMovieScreen`)
- **Route:** `/suggest` (and `/Suggest`), tab 2.
- **Purpose:** pick a film and suggest it to a club. **Primary action:** "Submit Suggestion" (`:268-277`). It sits **below the results grid and the club list**, so it is off-screen until the user scrolls.
- **Problems**
  - The club list is hardcoded (`:30-34`). The submit call always goes to `/communities/demo/suggest`, **whichever club is selected** (`:96`).
  - When the API returns nothing, or the call fails, demo films appear as if they were results for the query (`:76-78`). There is no error state.
  - `_yearFor` invents the year "2024" when it is missing (`:295`).
  - Results are silently capped at 6 (`:184`).
  - "Set default club for suggestions" is styled like a link but is plain `Text` (`:266`).
  - The error snackbar says "tap to retry" but has no action (`:106`). The "+10 XP" in the success message is fake (`:99`).
  - There is no pull-to-refresh, no `textInputAction.search`, and the keyboard does not dismiss on scroll.
  - The submit button is a raw `ElevatedButton` (`:270-276`), not `ClButton`.
- **Style debt:** 62 (50/0/2/0/10). Uses `ClEmptyState` and `ClSnackbar`; bypasses `ClButton`, `ClTextField` and `ClCard`.
- **Must keep:** the 300 ms debounce, the "No results for…" copy, `/tmdb/search`, and `POST /communities/:id/suggest` (payload `tmdbId`, `note`).

#### 1.12 Suggest (community deep link): `SuggestMovieDeepScreen` in `core/router/routes.dart:313-331`
- **Route:** `/communities/:id/suggest`. **Reached:** Community Detail, "Suggest a Movie" (`community_detail_screen.dart:93`) and "Suggest a Film" (`:157`).
- **Problems**
  - **It crashes.** It places `SuggestMovieScreen`, which is itself a `Scaffold`, directly inside an unbounded `Column` (`routes.dart:323-327`). That gives an infinite-height layout error, so **both suggest CTAs on Community Detail are broken**.
  - Its copy says "search TMDB above" (`:325`) while the search box is below. It shows the raw `communityId`.
  - It is a third suggest flow, next to the Suggest tab and Movie Detail's "Suggest to Club".
- **Style debt:** 0. Uses `ClEmptyState`.

#### 1.13 Communities list: `clubs/presentation/community_list_screen.dart`
- **Route:** `/communities` (and `/allCommunities`), tab 3, labelled **"Clubs"** in the nav but titled "Communities" (`:38`).
- **Purpose:** the user's clubs, plus join by invite or create. **Primary action:** tap a club to open `/communities/:id` (`:144`). The invite "Join" (`:79`), the "Create" FAB (`:43`) and the empty-state buttons all compete with it.
- **Problems**
  - The invite "Join" is fake: it only shows a snackbar (`:80-88`). It uses a raw `SnackBar`, not `ClSnackbar`.
  - **The role badge is wrong:** `isAdmin = community.admins.isNotEmpty` (`:140`), so every club that has any admin shows ADMIN.
  - `'Active 2h ago'` is hardcoded (`:142`), and the avatars are random picsum images (`:153`).
  - The empty state's `OutlinedButton` "Enter invite code above" is a no-op (`:128-132`): an instruction dressed up as a button.
  - The error copy says "tap to retry" *and* has a separate Retry button (`:112-114`).
  - The FAB covers the last row because the list has no bottom padding (`:135`).
  - The invite field has no `onSubmitted`, `textInputAction` or capitalization (`:64-76`).
  - The "Join" button looks about 40pt (`:79`), but its hit area is padded to 48pt. Badge text is 9pt (`:169`).
- **Style debt:** 50 (39/0/4/0/7). Uses `ClButton` and `ClEmptyState`; bypasses `ClTextField`, `ClCard`, `ClChip` and `ClSnackbar`.
- **Must keep:** `allCommunitiesProvider` (watch and refresh), `push('/createCommunity')`, `push('/communities/:id')`. This is the **only screen with real loading, error and empty states**; use it as the reference.

#### 1.14 Profile: `user_profile/presentation/profile_screen.dart`
- **Route:** `/profile`, tab 4. Also `/users/:id` (root navigator, no bottom nav).
- **Purpose:** identity, stats, watchlist, log out. **Primary action:** "Edit" for your own profile (`:96`), "Follow" for someone else's (`:102-112`).
- **Problems**
  - Your own profile is titled **"CLUVIE"** (`:91`).
  - Edit mode has no save, cancel or validation; "Done" only toggles (`:96`). The inline fields have no labels (`:136-153`). The avatar's edit badge is decorative (`:130-131`).
  - Follow graph: "View all" is a no-op (`:178`) and the avatars are not tappable.
  - Watchlist rows do not open Movie Detail. The ratings "Cluvie 4.8" and "TMDB 7.4" are hardcoded (`:272-274`).
  - There are two ways to remove an item (swipe and ×), and **no undo** (`:248`, `:278`).
  - The `Dismissible` key is the title (`:240`), so two identical titles will throw.
  - Copy is inconsistent: "12 XP to next badge" next to 1240/1500 (`:202-212`). "Recent Votes" uses 5-star ratings (`:318`), while voting everywhere else is pick-one.
  - The chevrons on vote cards lead nowhere (`:321`).
  - **Log out** calls `go('/welcome')` without clearing auth or asking for confirmation (`:294`). On relaunch, splash goes straight back to Home.
  - A failed watchlist load is silent and keeps the demo items (`:49-51`).
  - **Overflow:** the "Level 7 — Cinephile" `Spacer` "1240 / 1500 XP" row (`:199-205`) at 320pt and 1.3×.
- **Style debt:** **88** (69/0/5/0/14). Uses `ClButton`, `ClEmptyState` and `ClSnackbar`; bypasses `ClAvatar`, `ClTextField` and `ClCard`.
- **Must keep:** `GET /watchlist`, `DELETE /watchlist/:id`, `go('/discover')`, `go('/welcome')`, and the `userId` param (own profile vs. someone else's).

### Club sub-screens (root navigator, full-screen)

#### 1.15 Community Detail: `community_detail_screen.dart`
- **Route:** `/communities/:id`. **Reached:** Community List.
- **Purpose:** the club hub. **Primary action:** **competing**. "Suggest a Movie" and "Vote now" (`:86-104`) are duplicated by "Suggest a Film" (`:157`) and "Open Voting" (`:219-223`). Chat, the core social feature, is just an app-bar icon (`:42`).
- **Problems**
  - **The whole screen is hardcoded demo data** that ignores `communityId` (`:24-33`). Pull-to-refresh is fake (`:48`).
  - **It crashes:** `communityId.substring(0, 4)` throws for IDs shorter than 4 characters (`:80`).
  - Both suggest CTAs lead to the crashing deep screen (§1.12).
  - Three app-bar icons (info, chat, settings) truncate long club names (`:40-44`).
  - Members are shown by raw uid ("u1") (`:135`). The invite code is not copyable or shareable (`:77-82`).
  - The discussion previews have chevrons but no `onTap` (`:238-275`).
  - **Overflow:**
    - The header row has a members chip, a `Spacer` and an invite chip (`:65-84`).
    - The poll header `Text` is not flexible (`:203`).
    - The two side-by-side `ClButton`s use `heading2` text (`:90-103`), so "Suggest a Movie" wraps or clips at 320pt.
  - `ClChip` renders light-on-dark (`:137`), see §2.
  - There are no loading or error states.
- **Style debt:** 60 (50/0/2/0/8). Uses `ClButton`, `ClChip` and `ClEmptyState`; bypasses `ClCard` and `ClAvatar`.
- **Must keep:**
  - `push('/communityInfo', extra: Community)`, `push('/communityChat', extra: Community)`, `push('/communitySettings')`.
  - `push('/communities/:id/{suggest,vote,discussion}')`.

#### 1.16 Create Community: `create_community_screen.dart`
- **Route:** `/createCommunity`. **Reached:** the Community List FAB and its empty-state CTA.
- **Purpose:** create a club. **Primary action:** "Create Community" (`:121`).
- **Validation is good:** 3–40 characters with a live counter (`:86-92`).
- **Problems**
  - It shows the **raw exception** to the user: `'Error: $e'` (`:41`).
  - It writes to `joinedCommunitiesProvider` (`:35`) while the list reads `allCommunitiesProvider`, so the new club may not appear until the list is refreshed.
  - Cancel duplicates the back arrow (`:124-127`).
  - **Size mismatch:** `ClButton` is forced to 0.8× screen width while the Cancel button below it is full width (`:119-126`).
  - There is no `textInputAction.next` or autofocus. The field decoration is copy-pasted twice (`:73-85`, `:100-110`).
- **Style debt:** 34 (26/0/7/0/1). Uses `ClButton`; bypasses `ClTextField` and `ClSnackbar`.
- **Must keep:** `joinedCommunitiesProvider.notifier.createCommunity(name, desc)`, `context.pop()`.

#### 1.17 Community Chat: `community_chat_screen.dart`
- **Route:** `/communityChat`. It needs `extra: Community`; without it, you get `_MissingExtraScreen` (§1.27). **Reached:** the Community Detail chat icon.
- **Purpose:** club chat. **Primary action:** send a message (`:191-194`).
- **Problems**
  - **Unreadable text:** messages from others are `Colors.black87` on dark `surfaceContainerHighest` (`:315`, `:552`).
  - "Someone is typing..." appears when **you** type (`:134-144`, `:176`).
  - The initial messages are in the wrong order: older at the bottom of a `reverse: true` list (`:36-53`, `:148`).
  - Thread replies are appended to the **main** list, where they show at the top (`:119`). The open thread sheet doesn't update, because `replies` is a snapshot (`:97`, `:475`).
  - Tapping *any* bubble opens a thread (`:156`), which is easy to trigger by accident. Reactions are long-press only, with no hint (`:319`).
  - No-op controls: attach "+" (`:81`, `:167`), search (`:228`), and every item in the overflow menu (`:258-286`). "View Community Info" doesn't close the sheet first (`:252-255`). `isAdmin` is hardcoded to `true` (`:232`).
  - The `AppBar` sits in a `SizedBox(height: 90)` inside the body, not in `Scaffold.appBar` (`:212-214`). On notched iPhones the top inset is 47–59pt, so the bar will clip.
  - The title `Row` is not flexible (`:217-225`), and `community.name!` throws on null (`:222`).
  - The emoji picker's tap targets are bare 28pt `Text` (`:398-404`).
  - The input has no `textInputAction.send` or `onSubmitted` (`:172`).
  - There are no loading, empty or error states. The data is local-only (`:18`).
- **Style debt:** 28 (8/0/9/0/11). Uses no Cl* widgets; bypasses `ClAppBar`, `ClBottomSheet`, `ClAvatar` and `ClTextField`.
- **Must keep:** the `community` constructor arg, and `pushNamed(RouteNames.communityInfo, extra:)`.

#### 1.18 Community Info: `community_info_screen.dart`
- **Route:** `/communityInfo`, which needs `extra: Community`. **Reached:** Detail's info icon and the Chat overflow menu.
- **Purpose:** about the club. **Primary action:** none clear.
- **Problems**
  - `community.name!` and `description!` **throw on null** (`:28`, `:66`).
  - Hardcoded data: the category "HORROR" (`:58`), the "800" posts (`:83`), and the **same topic repeated 10 times** (`:109-116`).
  - All four action chips are no-ops at a fixed width of 174 (`:217-223`). The topic rows are no-ops too (`:246`).
  - The member check is commented out (`:96-99`), so **non-members see Moderation and Analytics**. `_JoinPrompt` is unused (`:179`).
  - It uses `Theme.textTheme` styles, unlike its sibling screens, and `Colors.grey` (`:142`, `:150`).
- **Style debt:** 17 (5/0/3/0/9). Uses no Cl* widgets.
- **Must keep:** the `community` constructor arg.

#### 1.19 Club Settings: `club_settings.dart`
- **Route:** `/communitySettings`. **It takes no club ID** (`routes.dart:170-174`). **Reached:** the Detail settings icon.
- **Purpose:** club admin and member settings. **Primary action:** none; nothing on the screen works.
- **Problems**
  - **Dead end:** there is no app bar or back button (`:9-11`).
  - **Every row is inert:** none of the `ListTile`s has an `onTap` (`:80-90`). "Leave Club" and "Report club" are plain `Text` (`:102-126`), and leaving has no confirmation.
  - The club name "Cinephiles Unite" is hardcoded (`:52`), while Detail shows "Cinema Sundays".
  - Only "Mute Notifications" has a chevron (`:31`), so the affordances are inconsistent.
  - **Overflow:** a non-scrolling `Column` with a `Spacer` holds 8 tiles plus the header (`:14-34`). That will overflow on a 568pt-tall phone and at 1.3×. The long trailing text squeezes the titles at 320pt (`:28`).
  - It sets its own background color (`:10`) and its own gold (`:49`, `:105`).
- **Style debt:** 18 (7/3/6/0/2). Uses no Cl* widgets.

#### 1.20 Joined Communities (orphan): `joined_community_screen.dart`
- **Unrouted;** nothing references `JoinedCommunitiesScreen`.
- If it is ever revived, these calls throw:
  - `pushNamed('communitySearch')` (`:31`): no such route.
  - `pushNamed('communityDetail')` with no `id` (`:178`).
- It has a black arrow on a dark background (`:177`) and a placeholder carousel (`:74-83`).
- **Style debt:** 16. **Recommendation:** delete it; Community List supersedes it.

### Movies, voting, discussion

#### 1.21 Movie Detail: `movies/presentation/movie_details_screen.dart`
- **Route:** `/movie/:id` (and legacy `/MovieDetails` with no id). **Reached:** only from Discover posters. Watchlist rows, vote rows, Suggest results and Home cards don't link here.
- **Purpose:** film info and actions. **Primary action:** "Suggest to Club" (`:139-144`). It competes with "Add to Watchlist", which appears **twice**: in the app bar (`:82`) and as a button (`:148-153`).
- **Problems**
  - **`movieId` is ignored.** Every film shows *Everything Everywhere All At Once* (`:89`, `:106`, `:160`). The "A24 · WINNER" badge (`:103`), the cast and the tags are hardcoded.
  - The numbers disagree: "12 votes" in the header vs. "42 votes" in the pill (`:108` vs. `:27`).
  - "Suggest to Club" posts to the demo club with **no club picker** (`:58-60`), unlike the Suggest tab.
  - The success snackbars show *before* the API responds (`:37`, `:58`). "tap to retry" has no action (`:65`).
  - Share is a no-op (`:83`). `_stale` is never set (`:29`).
  - The back button is a custom `context.pop()` (`:80`). On a deep link with no back stack this fails, so the user is stuck.
  - The pinned, collapsed app bar has no title, because the title lives only in the background.
  - There are no loading or error states.
  - **Overflow:**
    - The 3 rating pills sit in a non-wrapping `Row` (`:128-134`) that needs about 300pt. That likely overflows at 320pt **even at 1.0×**.
    - The side-by-side "Suggest to Club" / "Add to Watchlist" buttons (`:137-155`) will wrap.
    - The cast row has a fixed height of 86 (`:174`), so it will clip at 1.3×.
- **Style debt:** 63 (48/0/3/0/12). Uses `ClSnackbar`; bypasses `ClButton`, `ClChip` and `ClAvatar`.
- **Must keep:** the `movieId` param, `POST/DELETE /watchlist`, `POST /communities/:id/suggest`, `push('/discussionThread')`.

#### 1.22 Vote Summary: `vote_summary_screen.dart`
- **Route:** `/communities/:id/vote`. **Reached:** the Home vote CTAs (demo id), Community Detail, and a Notifications deep link (`demo-community`).
- **Purpose:** rank the suggestions and vote. **Primary action:** "Vote" on a row (`:207-213`).
- **Problems**
  - **The debug footer ships:** "Winner logic… Status… expiresAt…" (`:239`).
  - The suggestions are hardcoded (`:32-37`). The title shows the **raw id**, e.g. "Weekly Pick — demo" (`:128`).
  - The voting rule is unclear: you can vote for *every* row (`:55-73`) under a header that says "this week's pick".
  - "Close poll early" is an admin action, shown to everyone, **irreversible, with no confirmation** (`:133`). "Share" is a no-op (`:135`).
  - Pull-to-refresh just resets the countdown (`:117-120`), and the countdown never ticks.
  - The list re-sorts as soon as you vote (`:71`), so the row jumps out from under your finger.
  - The date is shown raw as `2026-11-24` (`:130`).
  - "Schedule Watch Party" opens the static live room (`:236`).
  - **Tap targets:** the Vote button is **34pt** tall (`:208`). WINNER is 9pt (`:192`).
  - **Overflow:** the `ClButton` pair with `heading2` text (`:132-136`) and "Schedule Watch Party" in a half-width button (`:236`), both at 320pt.
  - There are no loading or empty states. The test expects `'No active polls — suggest a film!'`.
- **Style debt:** 49 (44/0/3/0/2). Uses `ClButton` and `ClSnackbar`; bypasses `ClChip` and `ClStatusBanner`.
- **Must keep:** `POST /movies/:id/vote` with rollback, the winner and tie sort (test contract), `push('/discussionThread')`, `push('/watchParty')`.

#### 1.23 Discussion Thread: `disscusion_thread.dart` (filename typo)
- **Route:** `/discussionThread` and `/communities/:id/discussion`. **Reached:** Home, Movie Detail, Vote Summary, Notifications, Community Detail.
- **Purpose:** the comments on a film. **Primary action:** post a comment, via the send button (`:331-334`).
- **Problems**
  - **Demo copy ships:** infinite scroll keeps appending "Page N — infinite scroll demo. Real app paginates… GET /api/comments…" (`:113-123`, `:117`). It never ends.
  - The header is hardcoded to "Past Lives" (`:193-196`), whatever film you came from; Home's *Oppenheimer* card opens Past Lives. A raw `communityId` chip is shown (`:199`).
  - The bar labelled "Tap a reaction to toggle:" is **not interactive** (`:292-303`). The emoji icon in the input (`:309`) and the share icon (`:202`) are not buttons either.
  - **Tap targets:** the send button is about 36pt (`:333`), and the reaction chips are about 24pt (`:264`, `:277`).
  - The input bar has **no bottom `SafeArea`**, so it sits under the home indicator (`:305`).
  - Posting more than 2000 characters is silently ignored (`:157`). The hint reads like a dev note: "(1–2000 chars)" (`:319`).
  - Enter-to-post (`onSubmitted`) conflicts with the multiline input (`:316-327`).
  - Refresh doesn't fetch anything (`:130-137`). There is no initial loading or error state.
  - The class docs promise "threaded" comments, but there is no reply UI.
  - **Overflow:**
    - The app-bar title `Row` (`:190-201`).
    - The author `Row` (name, PINNED, `Spacer`, time) (`:242-250`) with long names at 1.3×.
  - It has its own colors: `0xFF1A122A` (`:227`, `:322`) and `0xFF0E0C1E` (`:307`).
- **Style debt:** 46 (34/3/4/0/5). Uses `ClEmptyState`; bypasses `ClChip`, `ClAvatar` and `ClTextField`.
- **Must keep:** the `communityId` param, the `'Be the first to comment'` and `PINNED` copy, the pinned-first sort, the `RefreshIndicator` (all test contracts), and the 2000-character limit.

#### 1.24 Discussion List: `discussion_list_screen.dart`
- **A `Placeholder()`** that is not routed. Every "View all discussions" goes to a single thread instead. This screen is needed (§3).

#### 1.25 Movie List (orphan): `movie_list_screen.dart`
- **Unrouted.**
- `pushNamed('movieDetails', extra: movie)` (`:204`, `:374`) throws, because the route needs `:id`.
- The error state is a bare `Text` with no Scaffold (`:73`). There are about 35 lines of commented-out code.
- **Style debt:** 22. **Recommendation:** delete it; Discover supersedes it.

#### 1.26 Movie Search: `movie_search_screen.dart`
- **Route:** `/search` (and `/MovieSearch`). **No in-app entry point**; only the orphan MovieListScreen linked here.
- **Problems**
  - It sends a request on **every keystroke** with no debounce (`:63-71`), and the query is not URL-encoded (`:26`).
  - Errors are only logged (`:39`). There is no empty state. The spinner replaces the list.
  - It uses default Material styling.
- **Security, outside UX scope:** a TMDB API key is hardcoded (`:24`). Flag it to engineering and rotate the key.
- **Recommendation:** delete it; Discover search supersedes it.

#### 1.27 Missing-extra fallback: `_MissingExtraScreen` in `routes.dart:300-310`
- This is what Chat and Info show when `state.extra` is missing: on any deep link, on app restore, or on a web refresh.
- It shows dev copy: **"CL\* — Missing navigation data. Go back and try again."** (`:308`).
- These routes should load by club ID instead of depending on `extra`.

### Watch parties

#### 1.28 Watch Party List: `watch_party/presentation/watch_party_list_screen.dart`
- **Route:** `/watch-parties`. **Reached:** Home, "See all" (`home_screen.dart:106`).
- **Purpose:** upcoming and past parties. **Primary action:** RSVP on each card (`:108-119`).
- **Problems**
  - **State bug:** a single `_rsvp` value is shared by every card (`:20`, `:114`). Choosing "Yes" on one card changes all of them. The RSVP is also local only.
  - "+" (create) is a no-op (`:44`). The past-party row has a chevron but no tap (`:129-148`).
  - "Details" (`:104`) and "View Live Party" (`:150`) both open the static live room. There is no event detail screen.
  - The dates are hardcoded and already in the past ("Sat, Sep 28") (`:24`). Refresh is fake (`:49`).
  - The `SegmentedButton` looks about 40pt tall and its icons make it tight at 320pt (`:108-119`). Its hit area is padded. The text color on the gold selected segment is left to the default (`:116-118`).
- **Style debt:** 37 (27/0/1/0/9). Uses `ClButton` and `ClEmptyState`; bypasses `ClCard`.
- **Must keep:** `push('/watchParty')`.

#### 1.29 Watch Party room: `watch_party_screen.dart`
- **Route:** `/watchParty`. **Reached:** Home RSVP, Watch Party List, Vote Summary, Notifications.
- **Purpose:** the live co-watching room. **Primary action:** none works.
- **Problems**
  - **Dead end:** there is no app bar, back button or leave control (`:8-24`).
  - **Every control is inert:** `ControlButton` is a `CircleAvatar` (`:201-205`), the control-bar icons (`:182-183`) are bare, and the emoji bar is static `Text` (`:141-150`).
  - "Arrival" and the timer "0:42:16 remaining" are static (`:36`, `:43`), whatever the party.
  - The avatars use `NetworkImage` with no error handling (`:117`). It sets its own background (`:9`) and uses `Colors.purpleAccent` (`:113`).
  - **Overflow:** the top-bar `Row` uses `spaceBetween` with non-flexible texts (`:33-46`).
- **Style debt:** 22 (10/1/5/0/6). Uses no Cl* widgets.

### Notifications

#### 1.30 Notifications: `notifications/presentation/notifications_screen.dart`
- **Route:** `/notifications` (root navigator) and `/notifications-shell` (in the shell). **Reached:** the bells on Home, Discover and Communities.
- **Purpose:** the activity inbox. **Primary action:** tap a notification to deep-link (`:142-151`).
- **What works:** unread styling, "Mark all read", tappable rows, an empty state.
- **Problems**
  - The items are demo data (`:20-43`). Refresh is fake (`:45-49`).
  - The settings gear opens **Profile** (`:75-78`), and there are no notification settings anywhere.
  - The poll deep link goes to the hardcoded `/communities/demo-community/vote` (`:145`).
  - It uses a raw `SnackBar` (`:57-59`), not `ClSnackbar`.
  - `ClAppBar` always shows a back button that calls `Navigator.pop`. On a cold deep link there is nothing to pop.
  - `/notifications-shell` highlights the **Home** tab (§3).
- **Style debt:** 21 (15/0/1/0/5). Uses `ClAppBar` (the only real screen that does) and `ClEmptyState`.
- **Must keep:** `push('/communities/:id/vote')`, `push('/discussionThread')`, `push('/watchParty')`.

---

## 2. Shared widgets: `lib/core/theme/widgets/`

**Most Cl\* widgets are used only by `lib/core/theme/test_page.dart`. Several have light-mode defaults in a dark-only app.** That explains why screens bypass them. **They must be fixed before the overhaul can standardize on them.**

| Widget | Used by screens | Problems |
|---|---|---|
| `ClButton` | 10 | <ul><li>Width is fixed at `0.8 × screen` (`cl_button.dart:34`), so it ignores its parent and looks narrower than full-width siblings.</li><li>Its `textStyle` is `heading2` (`:29`), which is too big for paired buttons.</li><li>The spinner is white on gold (`:45`).</li><li>There is no disabled state, since `onPressed` is required. Callers pass `() {}`.</li><li>`isSecondary` is a **white** fill (`:22`).</li><li>There is no icon support, so screens fall back to raw `ElevatedButton.icon`.</li></ul> |
| `ClEmptyState` | 9 | <ul><li>There is no CTA or subtitle slot, so screens wrap it in ad-hoc containers and buttons.</li><li>Uses `Colors.grey.shade400` (`:21`).</li></ul> |
| `ClSnackbar` | 4 | <ul><li>There is **no action** parameter (retry or undo), so the copy says "tap to retry" with nothing to tap.</li><li>The other 3 screens use raw `SnackBar`.</li></ul> |
| `ClAppBar` | 1 (Notifications) | <ul><li>Calls `Navigator.pop` (`:22`) instead of `context.pop`/`maybePop`.</li><li>Always shows a back button, even when it is the root.</li></ul> |
| `ClChip` | 1 (Detail) | <ul><li>Light background and border (`:24-31`).</li><li>Uses a `GestureDetector`, so there is no ripple, and the target is about 30pt.</li></ul> |
| `ClLoading` | 1 (Login) | Fine. |
| `ClCard` | 0 | Defaults to a **white** background (`:25`). |
| `ClTextField` | 0 | <ul><li>`grey.shade50` fill (`:47`).</li><li>Wraps a `TextField`, not a `TextFormField`, so it has no validator, error, suffix, `textInputAction` or autofill.</li></ul> |
| `ClAvatar` | 0 | <ul><li>A bogus `required String url` that is never used (`:10`).</li><li>Falls back to a **movie poster** URL (`:17`).</li></ul> |
| `ClBottomSheet` | 0 | **White** background (`:21`) and a fixed 50% height. |
| `ClTabBar` | 0 | The unselected color is `lightTextPrimary` (`:20`), which is dark on dark. |
| `showClDialog` | 0 | The confirm button is hidden by default (`showConfirm = false`, `:12`), and a `Container()` sits in `actions` (`:33`). |
| `ClStatusBanner` | 0 | The dismiss button is a no-op (`:76-78`). Discover reimplements this banner. |
| `ClBottomNavBar` | shell | See §3: `go()` with no per-tab state, a dead `/users/` mapping (`:27`), and the "Clubs" label. |

**Style debt in the widgets themselves:** 63 occurrences. **App-wide total:** about 890 across these 50 files. That is about 800 in screens; Home (95), Profile (88), Movie Detail (63), Suggest (62) and Community Detail (60) are the worst.

---

## 3. Navigation model issues

- **No per-tab state.** `ClBottomNavBar` switches tabs with `context.go` (`cl_bottom_nav_bar.dart:40`) under a plain `ShellRoute`. Each switch rebuilds the tab, so Discover refetches and search is lost. A `StatefulShellRoute` with an indexed stack is the fix.
- **Most of the app sits outside the shell:**
  - Community Detail, Chat, Info, Settings, Vote, Discussion, Movie Detail, Watch Parties and Notifications are all on the root navigator.
  - So the bottom nav disappears as soon as you tap into anything.
  - A second Notifications route inside the shell (`/notifications-shell`) highlights **Home** (`_getCurrentIndex` falls through to `0`, `:28`).
- **Root path confusion:** `/` is Onboarding and Home is `/home`. Splash ignores both onboarding and auth (`splash_screen.dart:8`, `routes.dart:51-54`).
- **Mixed navigation APIs:**
  - Push uses both path strings (`push('/watchParty')`) and names (`pushNamed('signup')`, sometimes as literals).
  - Pop uses both `Navigator.pop` (`ClAppBar`) and `context.pop`.
  - `go` is used where `push` was intended (Forgot Password dialog), and `push` where `go` was intended (Login and Signup cross-links stack duplicates).
- **Broken targets:**
  - `RouteNames.movies` (Signup), `/movieDetails` (`watch_card.dart:46`), `communitySearch`, and `communityDetail` with no id (Joined).
  - `SuggestMovieDeepScreen` crashes on layout.
  - Chat and Info depend on `extra`, so they fail on a deep link or restore.
- **Hardcoded demo IDs** in navigation and API calls: `/communities/demo/...` (`home_screen.dart:64`, `:309`; `suggestion_screen.dart:96`; `movie_details_screen.dart:60`) and `demo-community` (`notifications_screen.dart:145`).
- **Three suggest flows** with different UIs: the Suggest tab, `/communities/:id/suggest` (broken), and Movie Detail's "Suggest to Club" (no picker).
- **Watch-party routes are conflated:**
  - `/watchParty` is the *live room*, while `/watch-parties` is the *list*.
  - "RSVP", "Details" and "Schedule Watch Party" all open the live room.
  - There is no event-detail screen.
- **Missing screens that existing CTAs imply:**
  - A discussion list ("View all").
  - Watch-party event detail.
  - Club search (the Discover hint says "clubs").
  - Notification settings.
  - Followers / follow graph.
  - Editing club settings.
- **Dead ends:** Club Settings and the Watch Party room have no back or leave control. Login, Signup and Forgot Password are pushed screens with no app bar.
- **Labels:** the nav says **"Clubs"**, while screen titles and routes say "Communities". Legacy alias routes (`/Discover`, `/Suggest`, `/MovieDetails`, `/MovieSearch`, `/allCommunities`, `/onboarding-legacy`) clutter the table.

---

## 4. Inconsistencies between screens

- **App bars:**
  - Home has a custom logo row with "CLUVIE".
  - Most tabs and sub-screens use a left-aligned `Text(heading2, white)`.
  - Notifications uses a centered `ClAppBar`.
  - Profile is centered and titled "CLUVIE".
  - Movie Detail and Info use a `SliverAppBar`.
  - Chat puts an `AppBar` in a `SizedBox(90)`.
  - Auth screens, Club Settings and the Watch Party room have **none**.
- **Back buttons:** there are five styles.
  - The implicit default.
  - `BackButton(color: white)` (Discussion, Profile).
  - A custom `IconButton(arrow_back_rounded)` that calls `context.pop` (Movie Detail).
  - `ClAppBar`, which calls `Navigator.pop`.
  - None at all.
- **Bell icon:** Home always shows an unread dot. Discover and Communities never show one. The other screens have no bell.
- **Buttons:**
  - Primary CTAs are `ClButton` (0.8 × width, 16pt vertical padding, radius 12, `heading2` text) or raw `ElevatedButton`s with radius 8, 10, 12 or 14.
  - Heights range from 34pt (Vote) and about 36pt (RSVP, discussion send) to about 40pt (default `ElevatedButton`) and about 52pt (`ClButton`).
  - Secondary buttons are `ClButton(isSecondary)` with a **white** fill, `OutlinedButton` with a gold or white12 border, or `TextButton`.
- **Cards:**
  - Most use `darkSurface` with a `white10` border, but the radius varies: 12 (lists), 14 (club rows, poll), 16 (vote card, watch-party card).
  - Variants include gradient cards (`cinematicGradient`), `white @ 4%` cards (past parties, recent votes), custom `0xFF1A122A` (Discussion), and a `ClCard` that nobody uses.
- **Section headers:**
  - Links read "View all" (Home, Detail, Profile), "See all" (Home, watch parties), "Open thread →" (Movie Detail), and "Details" (Watch Parties).
  - Headings are `heading2` at 16, 18 or the default size, or `Theme.textTheme.titleMedium` (Info), or raw `TextStyle(22)` (Settings, Watch Party room).
- **Empty states:** `ClEmptyState`, Home's private `_EmptyCard`, a plain `Text` (Joined, Movie List), and `ClEmptyState` wrapped in custom containers with separate buttons.
- **Feedback:** `ClSnackbar` (Suggest, Movie Detail, Vote, Profile) vs. raw `SnackBar` (Community List, Create, Notifications). Error states are inline banners (Discover, Community List) or full-screen replacements (Login, Signup).
- **Copy for the same action:**
  - "Suggest a Movie", "Suggest a Film", "Suggest to Club" and "Submit Suggestion".
  - "Vote now", "Open Voting" and "Vote — tie needs your pick".
  - "Communities" vs. "Clubs".
  - "Log in", "Login" and "Log In".
- **Screen padding:** 16 (most), 20 (Profile), 24 (Settings, Watch Party room), `AppSpacing.clPadding` (auth, list, create), and 8 (Movie Search).
- **Badges:** WINNER, PINNED, ADMIN and MEMBER are each restyled per screen at 9–11pt.

---

## 5. State-handling gaps

Legend: ✓ present · ✗ missing · ~ fake or partial

| Screen | Loading | Empty | Error | Pull-to-refresh | Data |
|---|---|---|---|---|---|
| Splash | spinner | – | ✗ | – | mocked |
| Login | full-screen (hides form) | – | full-screen (hides form) | – | **no API call** |
| Signup | label only | – | full-screen | – | API, then crash |
| Forgot Password | ✓ button | – | ✗ | – | fake delay |
| Home | ✗ | ~ (QA toggle only) | ✗ | ~ | hardcoded |
| Discover | shimmer (hides search) | ✓ search | ~ (2 banners plus demo shown as "cached") | ✓ | API, demo fallback |
| Suggest tab | ✓ inline | ✓ search | ✗ (silent demo) | ✗ | API search, demo clubs |
| Community List | ✓ | ✓ | ✓ | ✓ | provider (**reference**) |
| Community Detail | ✗ | ~ (suggestions only) | ✗ | ~ | hardcoded |
| Create Community | ✓ button | – | raw exception | – | provider |
| Chat | ✗ | ✗ | ✗ | ✗ | local |
| Community Info | ✗ | ✗ | ✗ (null crash) | ✗ | `extra`, partly hardcoded |
| Club Settings | – | – | – | – | static |
| Movie Detail | ✗ | – | ~ (rollback snackbars only) | ✗ | hardcoded |
| Vote Summary | ✗ | ✗ (test expects copy) | ~ (rollback snackbar) | ~ | hardcoded, vote API |
| Discussion | ✗ (initial) / ✓ (more) | ✓ | ✗ | ~ | hardcoded |
| Watch Party List | ✗ | ✓ | ✗ | ~ | hardcoded |
| Watch Party room | ✗ | ✗ | ✗ | ✗ | static |
| Notifications | ~ (header spinner) | ✓ | ✗ | ~ | hardcoded |
| Profile | ~ (watchlist spinner) | ✓ watchlist | ✗ (silent) | ✓ watchlist only | API, demo fallback |

Patterns that cut across screens:
- **Optimistic success before the server confirms:** Movie Detail, Vote, Suggest and Profile show a success snackbar, then roll back if the call fails. That is acceptable, but the error snackbars promise "tap to retry" with no action, and removals have no undo.
- **Silent demo fallback hides real failures:** Discover, Suggest and Profile. In production the user cannot tell the difference between "no results", "offline" and "demo".
- **Errors replace the whole screen** on Login and Signup, so the user loses their form input.

---

## 6. Prioritized UX changes

### P0: must fix in the overhaul
1. **Fix crashes and blocked flows.** Screens: Signup, Community Detail, Suggest (deep link), Chat, Community Info.
   - Signup's success target `RouteNames.movies` does not exist (`sigup_screen.dart:35`).
   - `SuggestMovieDeepScreen` nests a Scaffold in a Column (`routes.dart:323-327`), which breaks both suggest CTAs on Detail.
   - `substring(0, 4)` crashes on short IDs (`community_detail_screen.dart:80`).
   - Force-unwraps: `community.name!` and `description!` (`community_chat_screen.dart:222`, `community_info_screen.dart:28`, `:66`).
2. **Remove QA and demo UI that ships to users.** Screens: Home, Vote Summary, Discussion, Chat, Info (fallback), Discover.
   - Home's empty-state toggle and hint (`home_screen.dart:65`, `:83`, `:169-172`).
   - The vote debug footer (`vote_summary_screen.dart:239`).
   - The pagination demo copy (`disscusion_thread.dart:117`).
   - The "CL\* —" fallback copy (`routes.dart:308`).
   - Demo films labelled "Using cached data" (`discover_screen.dart:84-94`, `:147-157`).
3. **Make the auth flow reachable and honest.** Screens: Splash, Onboarding, Welcome, Login, Signup, Profile (logout).
   - Splash is mocked to `true` and the redirect is a no-op, so Onboarding, Welcome and Login are never shown (`splash_screen.dart:8`, `routes.dart:51-54`).
   - Login validation and the API call are commented out (`login_screen.dart:27`, `:30`).
   - Logout doesn't clear the session (`profile_screen.dart:294`).
   - Without these fixes, the redesigned auth screens cannot be reached or tested.
4. **Remove dead ends and inert controls.** Every visible control must either work or be removed. Screens: Club Settings, Watch Party room, Login, Signup, Forgot Password, Welcome, Onboarding, Community List, Movie Detail, Vote Summary, Discussion, Chat, Info, Discover, Home.
   - Club Settings and the Watch Party room need an app bar, back and leave controls, and working rows (`club_settings.dart:9-34`, `watch_party_screen.dart:8-24`).
   - Login, Signup and Forgot Password need a back affordance.
   - Inert controls to fix or remove:
     - Apple/Google (`welcome_screen.dart:53`, `:66`), onboarding "skip" (`onboarding_screen.dart:87`).
     - "Enter invite code above" (`community_list_screen.dart:129`).
     - Share (Movie Detail `:83`, Vote `:135`, Discussion `:202`).
     - Discussion's reaction bar (`:292-303`).
     - Chat's attach, search and menu items.
     - Info's action chips.
     - Discover's "Join Club", Home's "Join Live", and "comment →".
5. **Fix the Cl\* widgets before standardizing on them.** Screens: all.
   - Light-mode defaults in a dark-only app: `ClCard`, `ClChip`, `ClTextField`, `ClBottomSheet`, `ClTabBar`, and `ClButton`'s secondary style.
   - `ClButton`: fixed 0.8× width, no disabled state, white spinner on gold.
   - `ClAppBar`'s `Navigator.pop` and always-on back button.
   - `ClAvatar`'s bogus param.
   - `ClSnackbar` needs an action slot; `ClEmptyState` needs a CTA slot.
6. **Unreadable chat text:** black87 on a dark surface (`community_chat_screen.dart:315`, `:552`). Screen: Chat.
7. **Tap targets under 44pt on primary actions:** Vote is 34pt, a tight `SizedBox` that overrides Material's padding (`vote_summary_screen.dart:208`). Discussion send is about 36pt (`disscusion_thread.dart:333`) and the reaction chips about 24pt (`disscusion_thread.dart:264`, `:277`); both are `GestureDetector`s with no padding. Screens: Vote Summary, Discussion.
8. **The RSVP state is shared across every watch-party card** (`watch_party_list_screen.dart:20`, `:114`), so the primary action shows wrong data. Screen: Watch Party List.

### P1
1. **Navigation model.** Screens: all tabs, Notifications, Chat, Info, Settings, Movie Detail.
   - Switch to `StatefulShellRoute` so each tab keeps its stack.
   - Pick one push/pop API.
   - Back that is safe on a deep link (`canPop` fallback).
   - Load Chat, Info and Settings by club ID, not `extra`. Pass the ID to Settings.
   - Drop `/notifications-shell`.
2. **One primary action per screen.** Screens: Home, Community Detail, Movie Detail, Suggest tab.
   - Home has about 7 gold CTAs.
   - Detail has duplicate suggest and vote pairs, and chat is hidden in an icon.
   - Movie Detail has a duplicate watchlist toggle.
   - On the Suggest tab, "Submit" sits below the fold.
3. **Unify the suggest flow and split the watch-party routes.** Screens: Suggest tab, the deep-link suggest, Movie Detail, Home, Watch Party List, Vote Summary.
   - Suggest should be one picker (film plus club) reused from all three entry points.
   - Add a watch-party event-detail screen so RSVP and Details don't open the live room.
4. **Add loading, error and empty states everywhere** using the Community List pattern. Screens: Home, Community Detail, Movie Detail, Vote Summary (`'No active polls…'`), Discussion, Watch Party List, Notifications, Chat.
   - Remove the silent demo fallbacks (Discover, Suggest, Profile).
   - Make every pull-to-refresh real.
   - Errors go inline, not as full-screen replacements (Login, Signup).
   - No raw exceptions (`create_community_screen.dart:41`).
   - Wire up retry and undo actions.
5. **Forms and keyboard.** Screens: Login, Signup, Forgot Password, Create Community, Community List (invite), Profile (edit), Discussion, Chat, Suggest.
   - Add labels, not only hints. Add `autofillHints`, `textInputAction` and next/submit.
   - Add password visibility toggles.
   - Give Profile's edit mode save, cancel and validation.
   - Reset the stuck Forgot Password spinner (`forgot_password_screen.dart:27`).
   - Bottom `SafeArea` on the Discussion input.
   - Resolve the send-vs-newline conflict.
6. **Overflow at 320pt and 1.3× text.** Verify each on a device. Screens:
   - Movie Detail: the rating pills (`:128-134`), the button pair, the cast row (`:174`).
   - Welcome, Login and Signup: the fixed glass heights (380, 427.5 and 450).
   - Onboarding: the non-scrolling Column.
   - Club Settings: the Column with a Spacer.
   - Community Detail: the header and poll rows (`:65-84`, `:203`).
   - Home: the poll header (`:263-271`).
   - Vote Summary: the button rows.
   - Discussion: the title and author rows.
   - Profile: the level row (`:199-205`).
   - Chat: the title and the fixed 90pt app bar.
   - Watch Party room: the top bar.
7. **Chat behaviour.** Screen: Chat.
   - The typing indicator triggers on your own typing.
   - Message order is inverted.
   - Thread replies leak into the main list, and the thread sheet goes stale.
   - Tapping a bubble opens a thread by accident; long-press reactions are undiscoverable.
8. **Data shown must match context.** Screens: Movie Detail, Discussion, Vote Summary, Community List, Community Detail, Notifications, Suggest, Home, Club Settings.
   - Movie Detail ignores `movieId`.
   - Discussion is hardcoded to "Past Lives" and shows a raw `communityId`.
   - Vote Summary shows a raw id in its title.
   - The wrong ADMIN badge (`community_list_screen.dart:140`).
   - Members shown as uids.
   - Hardcoded `/communities/demo` targets.
   - Settings shows a different club name.
9. **Remaining tap targets and small text:** `ClChip` (about 30pt, `GestureDetector`), the chat emoji picker (bare 28pt `Text`), and 9–11pt badges and captions. Screens: Community Detail, Chat, Home, Community List, Vote Summary, Discussion.
10. **`Padding > Expanded`** ParentData misuse, which reports an error in debug (`login_screen.dart:69`, `sigup_screen.dart:77`). Screens: Login, Signup.
11. **Copy and labels.** Screens: the nav bar, Community List, Home, Detail, Movie Detail, Suggest, Profile, Notifications, Signup.
    - "Clubs" vs. "Communities".
    - One verb each for suggest and vote.
    - "View all" vs. "See all".
    - Own profile titled "CLUVIE".
    - The Notifications gear opens Profile.
    - The signup link typo.
    - The fake "+10 XP" and inconsistent XP figures.
12. **Destructive actions need confirmation:** Close poll early (also hide it from non-admins), Leave club, Log out, and watchlist removal (add undo). Screens: Vote Summary, Club Settings, Profile.

### P2
1. **Delete orphan and dead files:** `JoinedCommunitiesScreen`, `MovieListScreen`, `DiscussionListScreen` (replace it with a real list in P1.3/P1.4), `MovieSearchScreen`, `email_verification_screen.dart`, `suggest_movie_screen.dart`, every `home/components/*`, and `_JoinPrompt`. Also remove the legacy alias routes and fix the filename typos (`sigup_`, `disscusion_`).
2. **Replace about 890 hardcoded style values with tokens,** worst first: Home 95, Profile 88, Movie Detail 63, Suggest 62, Community Detail 60, Community List 50, Vote 49, Discover 47, Discussion 46. Remove the per-screen background and gold overrides (`club_settings.dart:10`, `watch_party_screen.dart:9`, `disscusion_thread.dart:227`).
3. **Polish:**
   - Make the bell's unread dot data-driven (Home, Discover, Communities).
   - Make the vote list's re-sort animated or delayed (Vote Summary).
   - Format the poll date properly (Vote Summary).
   - Show an inline "2+ characters" search hint (Discover, Suggest).
   - Add "see all" to Discover's Popular grid instead of `childCount: 4`.
   - Add a Next button to onboarding.
   - Give the collapsed Movie Detail app bar a title.
   - Make the invite code copyable (Community Detail).
4. **Outside UX scope, but flag it now:** the hardcoded TMDB API key (`movie_search_screen.dart:24`) should be rotated, and calls should go through the backend proxy.
