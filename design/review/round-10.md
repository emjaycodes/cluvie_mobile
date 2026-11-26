# Design review, round 10: password reset, session end, watch parties, notifications, profile, club members

**Commits reviewed** (`feat/design-overhaul`, HEAD `a193c56`):
- `511c52a` feat(clubs): About lists members (`memberProfiles`); owner and admins can "Make admin"
- `ffc917c` feat(auth): password reset, `cluvie://reset-password` deep link, app-wide sign-out on 401, `ApiException.fromDio` passthrough, `AuthHeading` step-down
- `028d6ce` fix(auth): which 401s end the session
- `9fdddbd` feat(watch-party): list, detail, RSVP, host cancel, the live-room placeholder
- `35dc496` feat(notifications): `GET /notifications`, mark read, link mapping, clear all, unread bells
- `a193c56` feat(profile): `GET /users/me`, watchlist with remove and Undo, log out, other people's profiles

**Scope:**
- `lib/app.dart`, `core/api/api_client.dart`, `core/errors/api_exceptions.dart`, `core/repository/auth_repository.dart`, `core/router/routes.dart`
- `authentication/`: `reset_password_screen.dart`, `forgot_password_screen.dart`, `auth_backdrop.dart`, `auth_form_scaffold.dart`, `data/sign_out.dart`
- `AndroidManifest.xml` and `ios/Runner/Info.plist` (with `AppDelegate.swift`)
- `watch_party/` (data, list, detail, tile, room placeholder)
- `notifications/` (data, screen), plus `home_feed.dart` `unreadCountProvider` and `fit_text.dart` `breakableTokens`
- `user_profile/` (data, screen)
- `clubs/`: `community_info_screen.dart` `_Members`, `makeClubAdmin`, and `Community.memberProfiles`
- The tests that came with each commit

**Backend checked (read only, `cluvie-backend` on `master` at `5a05b62`):**
- `middleware/authMiddleware.js` and `utils/sessionCheck.js`:
  - No token or a bad token gets 401.
  - A revoked token gets 401 `code: SESSION_REVOKED`.
  - No other route in `routes/`, `middleware/` or `utils/` returns 401, so "401 means the session ended" holds.
- `routes/authRoutes.js`:
  - `forgot-password` always sends the same 200, or 400 if the email is empty. It looks the email up **case-sensitively**. The link is `${PASSWORD_RESET_URL || 'cluvie://reset-password'}?token=…`, sent as a **plain-text** email body (`utils/mailer.js`: console or Resend, `text` only).
  - `reset-password` returns 400 `INVALID_RESET_TOKEN`, or a 400 message for a short password. It sets `passwordChangedAt`. `/api/auth` sits behind `authLimiter`, and `forgot-password` also has `passwordResetLimiter` (429).
- `routes/watchpartyRoutes.js`, mounted at `/api/watchparties`:
  - The list populates `host`, `movie` and `community`, but **`participants` are raw ids**. It sorts by **`scheduledAt: 1`**, `limit` is at most 100, and nothing filters on date.
  - `GET /:id` populates everything. It returns 404 for a private party when you aren't a member, and **500 for a non-ObjectId id**.
  - `join`:
    - 404 when the party or its club is missing.
    - 400 "Cannot join watch party with status X".
    - 400 "Already a participant".
    - 403 when you aren't a member.
    - Its response populates only `participants` and `host`.
  - `leave` returns 400 "Host cannot leave…". `$pull` makes leaving a party you weren't in a 200. Its response populates `participants` only.
  - `PATCH /:id/update` is host-only (403). The catch blocks of join, leave and update return **400 with `err.message`**.
  - Nothing ever moves a party to `ended`. `status` changes only when the host PATCHes it.
  - The private-party filter uses `memberCommunityIds`, which is `owner` or `members.user` only. It doesn't use `joinedQuery`.
  - The creation notification's `relatedLink` is `/watchparty/:id`, and its message embeds an ISO timestamp.
- `routes/notificationRoutes.js`:
  - `GET /` returns `{notifications, total, …}` and honours `isRead`.
  - `PATCH /:id/read` returns 404 for a bad or foreign id.
  - `DELETE /clear`.
  - There's no mark-all-read and no preferences route. Error bodies use `error`, not `message`.
- `relatedLink` producers:
  - `movieRoutes`, `commentRoutes` and `discussionRoutes` send `/movies/:catalogId`.
  - `pollClose` sends `/polls/:id`.
  - `userRoutes` sends `/users/:followerId` (the follower, not you).
  - `watchpartyRoutes` sends `/watchparty/:id`.
- `GET /movies/:id` returns a bare movie (`tmdbId` may be missing). `GET /polls/:id` returns `{data}`, where `community` is a raw id.
- `routes/userRoutes.js` `GET /me` returns a bare user (`role`, `xp`, and populated arrays). There's no `GET /users/:id`.
- `routes/watchlistRoutes.js`:
  - `GET /` returns a bare array of populated movies.
  - `remove` takes any valid ObjectId and is a no-op 200 if the film isn't saved.
  - `add` returns 400 `ALREADY_IN_WATCHLIST`.
- `routes/communitiesRoutes.js` `POST /:id/make-admin {targetUserId}`:
  - 404 if the club is missing.
  - 403 if you aren't an admin.
  - **400 "Target user is not a member"**.
  - 400 "User is already an admin".
  - `GET /:id` adds `memberProfiles` (`utils/membership.js`).
- `utils/membership.js`: `isCommunityAdmin` also counts a member whose `role` is `admin`.

**Checks run:**
- `flutter analyze --no-fatal-infos`: **No issues found** (0 infos, 0 warnings, 0 errors).
- `flutter test $(ls test/*.dart)`: **509 of 509 pass**.
- I grepped every `lib/` file these commits touch for `Colors.`, `Color(0x`, `Icons.` and `GoogleFonts`. The only hits are `AppIcons.*`, which are fine.
- I read the go_router 14.8.1 sources (`parser.dart`, `router.dart` `_effectiveInitialLocation`) to trace both deep-link paths:
  - **Cold start:** `defaultRouteName` `cluvie://reset-password?token=t` has an empty path, so go_router rebuilds it as `/?token=t` and drops the host. `resetPasswordRedirect` catches the `/?token=` form.
  - **Warm start:** `pushRouteInformation` keeps the host. The redirect catches `host == reset-password`.
  - Both forms are tested (`password_reset_test.dart:172`).
  - On iOS, there's no `UIApplicationSceneManifest`, `FlutterAppDelegate` handles `openURL`, and deep linking is on by default (Flutter ≥ 3.27). The splash's `_route` checks `mounted`, so a link that arrives during the splash isn't overridden.
- I looked at all 16 renders in `shots10/`.

**Probes:** throwaway tests in `test/_review10/`, now deleted. Setup: `loadRealFonts()`, `ClPosterImage.debugDisableNetwork = true`, and `FakeApiClient`. They covered:
1. Watchlist Undo after switching tabs. Undo still POSTs `/watchlist/add` (1 call, no exception), so it isn't a bug.
2. A party scheduled 21 days ago that is still `status: scheduled`.
3. The host opening their own party while `currentUserIdProvider` is `null`.
4. A mark-read PATCH that fails after a refresh has landed.

## Verdict

**Ready to merge: 0 blocking findings.**

All six commits do what they say:
- Every screen is driven by the real API, with loading, empty, error and refresh states.
- The fake data is gone (Home's demo feed is out of scope).
- The live room and other people's profiles say plainly that they aren't available.
- The gold budget holds everywhere.
- The 401 rule is narrow and matches the backend.

There are six should-fix problems:
- **R10-S1:** the reset email's `cluvie://` link won't be tappable in most mail apps. Fix it before `PASSWORD_RESET` is turned on.
- **R10-S2:** stale "scheduled" parties still offer a gold RSVP.
- **R10-S3:** once there are more than 100 visible parties, the list loads the oldest ones.
- **R10-S4:** the R9-S3 pattern again: an RSVP that looks done while the refetch runs, or after it fails.
- **R10-S5:** a screen reader can't hear a party's status in the list.
- **R10-S6:** with an unknown user id, the host is offered "I'm going".

## Findings

Severity: **B** = blocking, **S** = should-fix, **N** = nit.

| id | sev | file:line | finding | concrete fix |
|---|---|---|---|---|
| R10-S1 | S | `AndroidManifest.xml:27-33`; `Info.plist:48-57`; `auth_form_scaffold.dart:36-43`; backend `authRoutes.js:103-110`, `utils/mailer.js` | **The reset link won't be tappable in practice.** The backend emails `cluvie://reset-password?token=…` in a **plain-text** body. Gmail (web and app) and Outlook don't linkify custom schemes in plain text, and Gmail strips non-http(s) `href`s from HTML too. A user who reads the email on their phone sees text they can't tap. The app side (intent filter, `CFBundleURLTypes`, redirect) is correct, but the route into it is closed. The flag comment also says the backend "has no email provider yet". Backend `5a05b62` (12:38, six minutes after `ffc917c`) added a Resend transport, so the only thing really missing is a working link. | • **Backend:** send an `https://` link. Either an App Link or Universal Link domain (`/.well-known/assetlinks.json` and `apple-app-site-association`), or a small https page that redirects to `cluvie://…` and shows the token as a fallback. Also send an HTML part.<br>• **App:** add the https host to the manifest (`autoVerify="true"`) and to Associated Domains. Teach `resetPasswordRedirect` the https path. Keep `cluvie://` as a fallback.<br>• Leave `kPasswordResetAvailable` off until this works end to end, and update its comment. |
| R10-S2 | S | `watch_party_detail_screen.dart:176-223`; `watch_party_list_screen.dart:25,96-103` | **A party long past its start still offers a gold "I'm going".** The backend never ends a party (only a host PATCH changes `status`). The list treats a party more than 4 h past its start as Past, but the detail screen uses `isOpen`, which is status only.<br>Probe, a party scheduled 21 days ago: the list shows "Past" ×1 and "Nothing planned right now.". Detail shows "I'm going" ×1 and "This party has ended." ×0. Tapping it would make the user "going" to a party three weeks ago. The host sees "Cancel party" too. | Put the 4 h rule on the model (`bool isOver(DateTime now)`, true when `!isOpen` or a scheduled party is more than 4 h past) and use it in the detail, the badge (show "Ended") and the list. Add a detail test for a stale scheduled party.<br>Backend ask: set `status: 'ended'` (or an `endTime`) server-side. |
| R10-S3 | S | `watch_parties.dart:113-121`; backend `watchpartyRoutes.js:169` | **With more than 100 visible parties, the list loads the oldest 100 and hides what's coming up.** The app asks for `limit: 100`. The server sorts `scheduledAt: 1` across **every public party from every club**, plus private ones in your clubs, with no date filter. Past parties never leave that set, so once there are more than 100, "Coming up" goes empty for everyone ("Nothing planned right now."), and it doesn't recover. | **Backend:** add `?from=<iso>` (or `upcoming=true`) and a "mine" filter (my clubs). Let the past be fetched separately, sorted descending.<br>**App until then:** at least pass `status=scheduled` for Coming up, and make a second call for the past. Or page until you reach `totalPages`. |
| R10-S4 | S | `watch_parties.dart:153-177`; `watch_party_detail_screen.dart:36-58` | **An RSVP looks done while the screen still offers the old action (the R9-S3 pattern again).** `_act` only *invalidates* the party. `_busy` clears at once, and `skipLoadingOnRefresh` and `skipError` keep the stale party.<br>• While the refetch runs, "I'm going" is enabled again under "You're going. See you there!". A second tap gets 400 "Already a participant", which is mapped to success, so a second success snackbar appears.<br>• If the refetch fails, the stale button stays with no "couldn't refresh".<br>The same applies to leave and cancel. | Do what R9-S3 did for clubs: await `ref.refresh(watchPartyProvider(id).future)` (keeping the auto-dispose provider alive), and keep `_busy` set until it settles. On a failed refetch, say "You're going. Couldn't refresh the party yet." Add a test where the refetch fails. |
| R10-S5 | S | `party_tile.dart:59-64,74-76` | **The list's semantics drop the party's state.** The tile's label is title, details, time and count. The badge (Live, Cancelled, Ended, Hosting or Going) sits inside `ExcludeSemantics`, so a screen reader user can't tell a cancelled party from an upcoming one, or tell that they're the host. | Add the badge text to `semanticLabel` (for example, "Cancelled. Noir night, …"). Return the label from `partyBadge` alongside the widget so the two can't drift. |
| R10-S6 | S | `watch_party_detail_screen.dart:161,181-223`; `party_tile.dart:33-37` | **When `me` isn't known, the host is offered "I'm going".** `isHost(null)` and `isGoing(null)` are false, so the gold RSVP shows.<br>Probe, host's own party with `currentUserIdProvider` → `null`: "I'm going" ×1, "Cancel party" ×0. Tapping it gets the server's 400 "Already a participant", which is treated as success: "You're going. See you there!". The same is true briefly while the id loads. This is the R9-S2 lesson: don't present a decision you can't make. | Watch `currentUserIdProvider` as an `AsyncValue`. While it loads, show a skeleton for the action. When it's `null`, show no RSVP and a short "Couldn't check your RSVP" with a retry. Add tests for a pending id and a null id. |
| R10-N1 | N | `comunity_provider.dart:216-229`; `community_info_screen.dart:150-171,186-196` | `makeClubAdmin` treats every 400 as done. If the member left after About loaded, the server answers 400 "Target user is not a member", and the screen says "**ola is now an admin.**" Also, "Make admin" is offered on a **Deleted account** row (visible in `15_about_members.png`), and the backend will promote that dead id. | Treat only "already an admin" as done (and ask the backend for codes, see the gaps below). For "not a member", say "They're no longer in the club" and refetch. Hide the action when `username == null`. |
| R10-N2 | N | `community_info_screen.dart:93`; `community.dart:117` | `canPromote` uses `Community.isAdmin` (owner or `admins`). The backend's `isCommunityAdmin` also counts a member with `role: 'admin'`, so a role-only admin isn't offered the action the server would allow. `memberProfiles` already carries the server's verdict. | Take my role from `memberProfiles.firstWhere((p) => p.id == me)?.role`. Fall back to `isAdmin` only when the profiles are missing. |
| R10-N3 | N | `community_info_screen.dart:243-262` | At 390 pt @1.0, "Make admin" falls onto its own line under the name (`318 − actionWidth − 56 < 140`). As a ghost button with no visual anchor, it reads as stray text (`15_about_members.png`). | Lower the inline threshold, or use `ClButtonSize.sm`, so it sits inline at 390 @1.0. Or give the stacked form the secondary variant. |
| R10-N4 | N | `watch_parties.dart:159-170`; `watch_party_detail_screen.dart:48` | `_act` decides refusals by substring (`'host'`, `'status'`), and maps **any other 400 to success**. The backend's catch blocks return 400 with `err.message` (for example, a validation error), and those would read "You're going". Also, a 403 from **cancel** ("Only host can update") becomes `notMember`, which shows "Only members of X can RSVP. Join the club first." and flips the screen to the join-club card. | Match only "Already a participant" as done, and treat any other 400 as `failed`. Add a `notHost` refusal for cancel. Backend ask: add codes (`ALREADY_PARTICIPANT`, `HOST_CANNOT_LEAVE`, `PARTY_CLOSED`, `NOT_HOST`). |
| R10-N5 | N | `notifications.dart:109-121` | Mark-read rollback writes over newer data. Probe: tap (optimistically read), then a refresh lands with the server's `isRead: true`, then the PATCH fails. The row goes back to New ×1. That's also the timeout case where the PATCH really landed. Each tap also fetches the unread count twice (the invalidate before and the one in `finally`). | Roll back only if the current item is still the optimistic copy (keep a pending-id set, and skip the rollback when `build` has run since). Drop the first `invalidate`. |
| R10-N6 | N | `profile.dart:84-94` | Two quick removes can bring back a film that's gone. Remove A, then B. If A then fails, its rollback restores its own `before`, which still contains B, though B was removed on the server. | Roll back by putting A back into the current list (`restore`-style insert at its index), not by restoring the whole snapshot. |
| R10-N7 | N | `app.dart:33-48`; `api_client.dart:66-70` | The session-ended handler is sound, but has some loose ends. It's untested; only `endsSession` has tests.<br>• `signedIn` is read from the header **at response time**. A request sent with an expired token that answers after the user has logged in again (connect and receive timeouts are 10 s each) signs the **new** session out, with "You were signed out".<br>• `clearUserState` runs before `goNamed(login)`, so mounted tabs refetch once without auth (harmless 401s).<br>• The `Future` is dropped, so an error from `logout()` is an unhandled async error. | Compare `DioException.requestOptions.headers['Authorization']` with the current header, and only end the session when they match. Navigate first, then invalidate. Add a widget test for `MyApp` that fires two concurrent 401s and checks for one logout, one snackbar, and that you land on Login. |
| R10-N8 | N | `routes.dart:41-47,265-266`; `reset_password_screen.dart:132-136`; `forgot_password_screen.dart:125` | • A cold-start reset link skips the splash, so a saved session isn't restored. "Remembered it? Log in" then asks someone who is still signed in to log in.<br>• The "It works for 30 minutes" and "work once, for 30 minutes" copy is hard-coded, but the server's TTL comes from `PASSWORD_RESET_TTL_MINUTES`.<br>• Forgot-password looks the email up case-sensitively, so `Ada@x.com` silently gets nothing (backend gap). | Make the secondary action on the reset form "Back" or "Cancel", going to `/splash` (which restores the session). Say "for a short time", or have the server return its TTL. The backend should normalise the email. |
| R10-N9 | N | `watch_party_list_screen.dart:107-111` | The empty state says "When someone in your clubs plans one", but the list shows public parties from **every** club. A party from a club you aren't in looks the same as your own until you open it. | Either filter to my clubs (needs the backend "mine" filter, R10-S3), or show the club's membership on the tile ("Not your club"). |
| R10-N10 | N | `notifications_screen.dart:49-51` | A film notification whose catalog film has no `tmdbId` says "Couldn't open this. It may have been removed.", though nothing was removed. | When the lookup succeeds without an id, say "Cluvie can't open this film yet", or make the row not tappable. |

## Design-system and accessibility checks

- **Gold budget:**

  | screen | gold |
  |---|---|
  | Party detail | "I'm going" only. The host gets danger, a goer gets secondary, ended or cancelled gets a warning banner. |
  | Party list | none. `ClBadge` defaults to purple, so "Hosting" isn't gold. |
  | Notifications | none |
  | Profile | none (Log out is danger; Admin is purple) |
  | Reset password | one per state |
  | Forgot password | "Send reset link" |
  | About | Join, for non-members only. "Make admin" is ghost. |

  The test matrices check this, and the 16 renders agree.
- **Word breaks:** handles wrap at `_ - . /` (`breakableTokens`), and `styleThatFits` splits on U+200B. `AuthHeading` steps down 34 → 28 → 22. Member names shrink and then ellipsize. The test matrices at 320 and 390 × 1.0, 1.3 and 2.0 pass. I found no breaks in the renders.
- **Touch targets:**
  - `ClIconButton` (watchlist remove, the bell, Clear all) and `ClButton` pad to `minTouch`.
  - Notification and party rows are full-row `ClPressable`.
  - `_Fact` rows on the party detail are about 64 pt tall.
- **Semantics:**
  - Headers on titles and sections. The loading skeletons are `liveRegion`. Notification rows read "Unread. title. message. time".
  - The party Club fact is a button labelled "Club: name". "Make admin" carries "Make ola an admin".
  - The party tiles are missing their state (R10-S5).
- **Membership:** the party detail keeps the three states. `unknown` still offers "I'm going", and a 403 then switches to the join-club card, so unknown isn't treated as "not a member". The weak spot is the *user id* being unknown (R10-S6).

## Backend gaps

1. **Reset email:** needs an https link (an App Link or Universal Link, or a redirect page) and an HTML part. It should also look the email up case-insensitively. (R10-S1, R10-N8)
2. **Watch party list:** needs a date filter (`from`/`upcoming`), a "my clubs" filter, and the past sorted descending. Today's `scheduledAt: 1` with `limit ≤ 100` returns the oldest. (R10-S3, R10-N9)
3. **Party lifecycle:** nothing ends a party, so a `scheduled` party stays scheduled forever. Set `ended` after `scheduledAt` plus the film's runtime, or store `endTime`. (R10-S2)
4. **Private-party visibility:** `memberCommunityIds` (`owner` or `members.user`) disagrees with `isCommunityMember` and `joinedQuery` for raw-id members. Use `joinedQuery`.
5. **Refusal codes:**
   - Watch parties: `ALREADY_PARTICIPANT`, `HOST_CANNOT_LEAVE`, `PARTY_CLOSED`, `NOT_HOST`.
   - `make-admin`: `ALREADY_ADMIN`, `NOT_A_MEMBER`.
   - `leave`: `OWNER_CANNOT_LEAVE` (still open from R9-N5).

   The app matches message substrings today. (R10-N1, R10-N4)
6. **Robustness:**
   - `GET /watchparties/:id` with a non-ObjectId returns 500. The app guards against it, but the API should return 404.
   - Join, leave and update catch-alls return 400 with raw `err.message`.
   - The join and leave responses populate different fields from `GET /:id`. The app refetches, so this doesn't matter today.
7. **Notifications:**
   - No mark-all-read.
   - No preferences route.
   - Error bodies use `error` where every other route uses `message`.
   - The watch-party message embeds a raw ISO time; send `scheduledAt` as a field instead of rewriting text.
   - FOLLOW links point at the follower's `/users/:id`, which nothing serves.
8. **Profiles and admin:** no `GET /users/:id` (public profile), no profile update or avatar, and no way to remove an admin.

## What works

- **The 401 rule is right.** I checked every 401 in the backend: they all come from `authMiddleware`. Exempting the four sessionless auth routes means a wrong password or a bad reset token never signs anyone out. `ApiException.fromDio` now passes an `ApiException` through, which fixes login errors that had lost their status.
- **The deep links are handled for both platform forms,** and the tests use the real `flutter/navigation` channel. The splash doesn't overwrite a link that arrives during it.
- **The screens are honest about what doesn't exist:**
  - The live room says it isn't open.
  - Other people's profiles say they aren't available and point to club About pages, which now list members.
  - Notifications have no fake mark-all-read or settings gear.
  - Profile has no Edit and no made-up levels.
- **Optimistic updates with a rollback and a message:** watchlist remove and Undo (Undo survives a tab switch, as probed), and mark-read.
- **Refresh failures keep the data and say so,** on all four new screens (party list, party detail, notifications, profile).
- **The tests are broad:** real routers, layout and gold matrices, error bodies shaped like the server's, and the 401 rule. What they miss is a stale scheduled party, a `null` user id, a failed refetch after an RSVP, and the server's list order. That's where R10-S2, R10-S3, R10-S4 and R10-S6 live.

## Summary

| severity | count |
|---|---|
| Blocking | 0 |
| Should-fix | 6 (R10-S1 to R10-S6) |
| Nit | 10 (R10-N1 to R10-N10) |

**Verdict:** ready to merge. Fix R10-S2, R10-S4 and R10-S6 (wrong RSVP offers) before release. Fix R10-S1 before turning on `PASSWORD_RESET`. R10-S3 needs the backend list filter.

## Resolution (2026-11-26)

Fixed in the commit after `dcb8536` (live rooms, which landed after this review was scoped). 540 of 540 tests pass; `flutter analyze` reports no issues.

| id | resolution |
|---|---|
| R10-S1 | App side: the `kPasswordResetAvailable` comment now says the blocker is the `cluvie://` link not being tappable in mail apps, not the email provider. The flag stays off. The https link (App Links / Universal Links or a redirect page) and an HTML part were sent to the backend as asks. |
| R10-S2 | `WatchParty.isOver(now)` treats a scheduled party more than 4 h (`kPartyStaleAfter`) past its start as over. Detail (no RSVP, "This party has ended."), the badge ("Ended"), the list and the live room all use it. Test: a party scheduled 21 days ago. |
| R10-S3 | The list pages through `totalPages` (up to 5 × 100) instead of stopping at the oldest 100. Asked the backend for `from`/"mine" filters and descending past. Test: an old party on page 1, an upcoming one on page 2. |
| R10-S4 | RSVP, cancel, start and end await the party's reload (kept alive with `listenManual`), and the button stays busy until it settles. A failed reload says "Couldn't refresh the party yet." Test: refetch fails after join. |
| R10-S5 | `partyStateLabel` feeds both the badge and the tile's semantics label ("Hosting, My party, …"). Test. |
| R10-S6 | While your id loads, the action is a skeleton; if it's unknown, "Couldn't check your RSVP" with retry. No RSVP is offered. Test. |
| R10-N1 | `makeClubAdmin` returns `PromoteResult`: "already an admin" is done, "not a member" says "X is no longer in the club" and refetches. Deleted accounts get no action. Test. |
| R10-N2 | Promote rights come from my own `memberProfiles` role (the server's verdict), falling back to `isAdmin`. Test with a role-only admin. |
| R10-N3 | "Make admin" is a small secondary button; the inline threshold accounts for the avatar and gaps, so it sits inline at 390 @1.0. |
| R10-N4 | Refusals match codes first, then exact phrases ("already a participant", "host cannot leave", "cannot join watch party with status"); any other 400 is a failure. A 403 on a host action is `notHost` ("Only the host can change this party."). Tests for both. |
| R10-N5 | Mark-read rolls back only if the item is still our optimistic copy; the count is fetched once per tap. Test with a refresh landing before the failed PATCH. |
| R10-N6 | A failed watchlist remove re-inserts only that film into the current list. Test with two removes, the first failing. |
| R10-N7 | A 401 ends the session only if the request carried the current token. `endSessionOnce` navigates to Log in first, then signs out and clears, at most once at a time, and swallows sign-out errors. Tests for concurrency and failure. |
| R10-N8 | The reset screen's "Log in" and "Back to log in" go through `/splash`, which restores a saved session. Link-lifetime copy no longer says "30 minutes". Case-insensitive email lookup was sent to the backend. |
| R10-N9 | The empty state says "When a club plans one". A "mine" filter was asked of the backend. |
| R10-N10 | When the lookup succeeds but there's nothing to open, the message is "Cluvie can't open this one yet." (warning), distinct from a failed lookup. |
