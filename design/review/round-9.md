# Design review, round 9: the Clubs screen group

**Commit reviewed:** `d934e6c` feat(clubs): redesign Clubs, Club detail, About, Membership and Create on the real API (`feat/design-overhaul`).

**Scope:**
- `clubs/presentation/`: `community_list_screen.dart`, `community_detail_screen.dart`, `community_info_screen.dart`, `club_settings.dart`, `create_community_screen.dart`, `club_scaffold.dart`, `widgets/club_tile.dart`
- `clubs/data/comunity_provider.dart`, `core/models/community.dart`, `core/repository/comunity_repository.dart`
- `core/router/routes.dart`: the club routes, `/communityChat`, `/communityInfo`, `/communitySettings`
- `vote_summary_screen.dart`: the non-member change only
- `test/clubs_data_test.dart`, `test/clubs_screens_test.dart`

I did not review the internals of `community_chat_screen.dart`. I only checked that nothing reaches it.

**Backend checked (read only):**
- `routes/communitiesRoutes.js`:
  - `POST /` needs both `name` and `description` (Mongoose `required`). A missing one returns 500, not 400.
  - `join`: 404 if the club doesn't exist, 400 "already a member".
  - `leave`: 404, 400 "not a member", 400 "Owner cannot leave".
  - `GET /:id` returns `{success, data}`. A non-ObjectId id returns 500.
  - **`GET /joined` filters on `'members.user': userId` only.**
- `models/Community.js`
- `utils/membership.js`: a member is the `owner`, a `{user}` subdocument, or a raw id. An admin is the owner, anyone in `admins`, or a member with role `admin`.
- `utils/movieCatalog.js`: suggesting returns 403 for non-members, using `isCommunityMember`.
- `routes/pollRoutes.js`: voting returns 403 for non-members, after the `POLL_CLOSED` check.

**Checks run:**
- `flutter analyze --no-fatal-infos`: 10 infos, 0 warnings, 0 errors. All 10 are in files outside this change (`notifications_screen.dart`, `profile_screen.dart`, `watch_party_list_screen.dart`).
- `flutter test`: **389 of 389 pass**.
- I grepped every `lib/` file in the commit for `Colors.`, `Color(0x`, `Icons.` and `GoogleFonts`. There were no hits.

**Probes:** throwaway tests in `test/_review/`, now deleted. Setup: `loadRealFonts()`, `ClPosterImage.debugDisableNetwork = true`, and a `FakeApiClient` backend that follows the server's rules: `/joined` filters on `members.user`, join returns 400 when you're already a member, and leave returns 400 for the owner or a non-member. They covered:
- A legacy club where I'm a raw-id member, and one where I'm only the `owner`. I looked at the Clubs tab, Join, Club detail, Vote and Join-from-Vote.
- `currentUserIdProvider` never resolving, and resolving to `null`, on Membership and Detail. I ran each with `/joined` listing the club, and with `/joined` failing.
- A join that succeeds when the refetch after it fails (Detail), and a join whose refetch is held open and then fails (Clubs tab), tapping Join again in between.
- A Detail pull-to-refresh where the club loads but `/polls/active` fails.
- Create while `/joined` is in error, then back. A double tap on Create.
- Deep links: a valid-format unknown id, `x/about`, an unknown id plus `/settings`, and `/communities/null`.
- Odd backend data: a numeric `name`, `null` and int members, `{user: null}`, a populated `owner`, `admins: null`, a string `movie_suggestions`, a garbage `createdAt`, a non-map list entry, and `communities: null`.
- The Vote Join card with a long club name, the Clubs tab error state, and the no-match state, each at 320×568 @1.3 and @2.0.

## Verdict

**Ready to merge: 0 blocking findings.**

The redesign does what the audit asked:
- The demo data, crashes, fake invite field, wrong ADMIN badge and inert rows are gone.
- Every screen is keyed by club id, with real loading, not-found and error states.
- Leaving asks for confirmation, and the layout matrix passes.

There are four should-fix problems:
- **R9-S1:** Vote, the Clubs tab and the suggest sheet decide membership from `/joined`, which misses the owner-only and raw-id members that `utils/membership.js` counts. Club detail uses the club document. For those users the screens contradict each other, and Join can't fix it. I checked the backend's history, and no code path writes those shapes today, so this is a fragility rather than a live block.
- **R9-S2:** Membership shows a role it doesn't know.
- **R9-S3:** a join can look like it failed when only the refetch did, and Join can be tapped again in that window.
- **R9-S4:** Detail's refresh stays silent when the vote or films fail.

R9-S3 is the one to fix before release.

## Findings

Severity: **B** = blocking, **S** = should-fix, **N** = nit.

| id | sev | file:line | finding | concrete fix |
|---|---|---|---|---|
| R9-S1 | S | `vote_summary_screen.dart:177`; `comunity_provider.dart:67-73`; `community_list_screen.dart:103-108`; `suggest_sheet.dart:126-135`; backend `communitiesRoutes.js:107-109` | **Members in older document shapes are treated as non-members, and Join can't fix it.** Today's create and join, and `scripts/seed.js`, all write `{user, role}` and put the owner in `members`. I found no code in the backend's history that wrote the other shapes. The first schema (`28c3954`) had raw-id `members`, but its create didn't add the creator, and its join (`Community.members.push`) always returned 500 until `302cb43`. So this only affects documents edited by hand or imported. That's why it's should-fix and not blocking. But `membership.js` and `Community.fromJson` both support those shapes on purpose, and the app gives them contradictory answers.<br> The backend's `GET /communities/joined` matches only `{user}` subdocuments. `isCommunityMember`, which vote and suggest enforce, also counts the `owner` and raw-id `members`. (`clubs_data_test.dart:48` tests those shapes.) But three places take membership from `/joined`: Vote (`clubMembershipProvider`), the Clubs tab (`mineIds`) and the suggest sheet. Detail uses the club document (`membershipIn`), so the screens disagree.<br>Probe, with a backend-faithful `/joined` and me as a raw-id member of "Raw Member Club":<br>• **Clubs tab:** "You're not in a club yet". The club is under "Find a club" with Join. Tapping Join gets a 400, which `joinClub` treats as success: "You joined Raw Member Club." The Join button is still there, so it loops. The owner-only club is also listed under Find a club with Join; joining it would get the same 400.<br>• **Detail:** "You're a member", Suggest a film.<br>• **Vote:** the "Join Club to vote" card, "Only club members can vote.", and **0 Vote buttons**, though the server would accept this user's vote. Join gives a 400, then "You joined Club. Cast your vote.", and the card stays. There's no way to vote.<br>• **Suggest** from Detail: the sheet says "You're not in this club yet. Join it…". "Open club" goes back to a Detail that says "You're a member".<br>The tests can't see this because `_Backend.joined` in `clubs_screens_test.dart:63` is a set that's updated by hand, not the server's query. | • **App:** decide membership from the club itself everywhere. Vote should watch `communityProvider(id)` and use `membershipIn`, falling back to `/joined` only while the club loads. The Clubs tab should treat `c.isMember(me)` from `/all` as "yours", as well as `mineIds`. The suggest sheet's `_notMember` check should do the same.<br>• **Backend ask:** make `/joined` use the same rule as `isCommunityMember`: `$or: [{owner: id}, {'members.user': id}, {members: id}]`.<br>• **Tests:** make the fake's `/joined` filter the way the server does, and add a raw-id fixture and an owner-only fixture across the Clubs tab, Detail, Vote and Suggest. |
| R9-S2 | S | `club_settings.dart:73-76`, `:96-126`; `comunity_provider.dart:77-83` | **Membership claims a role it doesn't know.** `role` and `owner` come from `me`. When the user id is still loading, or resolved to `null`, `owner` is false and the role defaults to "Member". `membershipIn` then falls back to `/joined`.<br>Probe, me pending, and me `null`, on a club I own that's listed in `/joined`: "Your role: Member", no "you can't leave" copy, and **Leave enabled for the owner**. Tapping Leave gets the server's refusal, which is handled, but the doc comment's "owners are told up front" doesn't hold.<br>Probe, me pending or `null` with `/joined` failing: membership is `unknown`, but the `else` branch still renders "Your role: Member", with no Leave button and no explanation. | • Show the role card and Leave only when `me` is known and `membership == member`.<br>• While `me` is loading, show the skeleton. When membership is `unknown`, show a `ClErrorState` with a retry that invalidates `joinedCommunitiesProvider` and `currentUserIdProvider`.<br>• Add tests with a pending id and a null id. |
| R9-S3 | S | `community_detail_screen.dart:64-78`; `community_list_screen.dart:66-72`; `comunity_provider.dart:97-116` | **A successful join can look like a failure, and the button can be tapped again while the refetch runs.** `joinClub` returns once the POST succeeds, then only *invalidates*. The screens clear `_joining` straight away, while `skipLoadingOnRefresh` and `skipError` keep the old "not a member" data.<br>Probe on Detail, POST 200 then `GET /communities/:id` 503: "Welcome to Noir." **and** the Join club button, still there and enabled, with no "couldn't refresh". A second tap sent a second POST and showed "Welcome" again.<br>Probe on the Clubs tab, with the `/joined` refetch held: the Join button is back and enabled mid-refetch, and a second tap sent a second POST (2 in total). The server answers 400 and nothing breaks, but the user is told they joined while the screen offers Join. | • Have `joinClub`/`leaveClub` await the refetch (`ref.refresh(communityProvider(id).future)` plus `joinedCommunitiesProvider.future`), and keep `_joining` set until it settles.<br>• Or, simpler: on success, mark the id as joined locally (a `Set` in the provider, or an optimistic `AsyncData` on `joinedCommunitiesProvider`) and show Suggest straight away. If the refetch fails, keep the optimistic state and show "Joined. Couldn't refresh the club."<br>• Add a test where the refetch fails after a successful join. |
| R9-S4 | S | `community_detail_screen.dart:45-62` | **A failed refresh of the vote or the films is silent.** `_refresh` shows "Couldn't refresh" only when the club itself fails. The poll and films errors are swallowed (`onError: (_) {}`), and because `skipError: hasValue` keeps the old data, nothing on screen changes.<br>Probe, with the club OK and `/polls/active` 503 on pull-to-refresh: the old poll stays (×1), the error card ×0, and the snackbar ×0. This is the same bug as R8-S2 on Discover, and it breaks the round-6 convention: keep the data, **and say the refresh failed**. | Collect the three results. If any section that had data failed, show one "Couldn't refresh. Showing earlier details." snackbar. Add a test with the club OK and polls failing on refresh. |
| R9-N1 | N | `community_detail_screen.dart:205` | When membership is `unknown` (the user id isn't known and `/joined` failed), Detail shows no action and no explanation. Probe: Join ×0, Suggest ×0, no copy. The user can't tell why there's nothing to do. | Show a compact `ClErrorState` there: "Couldn't check your membership", with a retry. |
| R9-N2 | N | `community_info_screen.dart:35-39`; `comunity_provider.dart:107-109` | Two refusals get the wrong copy:<br>• About's `_join` shows "Couldn't join. Check your connection…" for every refusal, including `notFound`. Detail and the Clubs tab say "no longer exists".<br>• `joinClub` and `leaveClub` map 401 and 403 to `failed`, so an expired session reads as a connection problem. | Use the same switch as Detail in About. Add an `unauthorised` refusal, or let the global 401 handler run. |
| R9-N3 | N | `create_community_screen.dart:68` | "$name is ready. **Invite your friends to join.**" There's no invite code, share link or invite flow, and the commit removed the fake invite field for that reason. The copy points at a control that doesn't exist. | "$name is ready. Friends can find it under Clubs." Or add a Share action with a deep link to `/communities/:id`. |
| R9-N4 | N | `comunity_provider.dart:53-58` | `createCommunity` only puts the new club into `joinedCommunitiesProvider` when the list already has a value. It doesn't invalidate the list when it doesn't. Probe, creating while "Your clubs" is in error: back on the Clubs tab, the error card is still there, and the new club appears under "Find a club" (without Join, since membership is unknown). | When `state.valueOrNull == null`, call `ref.invalidate(joinedCommunitiesProvider)`. |
| R9-N5 | N | `comunity_provider.dart:125-127` | "Owner can't leave" is detected by `message.contains('owner')` on a 400. It works with today's copy, but breaks silently if the message is reworded or translated. | Ask the backend for `code: 'OWNER_CANNOT_LEAVE'` (polls already use `code`), and check the code first. |
| R9-N6 | N | `vote_summary_screen.dart:224-230`; `club_discussions_screen.dart:95-99` | The Vote and Discussions empty states offer "Suggest a film" to non-members too. They pick a film and only then learn they must join, in the sheet's `_notMember`. The copy is honest, but it's a detour. (Vote's message is also still the old "No active polls — suggest a film!".) | Use the membership you already have: for non-members, use "Join club" instead, or hide the action. |
| R9-N7 | N | `club_settings.dart:94`; `suggest_sheet.dart:198` | "Open club" uses `context.go`, which drops the back stack (the same issue as R8-N3 on Vote). From Membership, back from the club no longer returns where the user came from. | `context.push` (or `pushReplacement` from Membership). |
| R9-N8 | N | `community_detail_screen.dart:252-255` | The owner sees "You're a member". Their role (Owner or Admin) shows on the Clubs tab and in Membership, but not on the club's own page. | Show "You run this club" or an Owner badge for `isOwner(me)`. Use the purple tone, as the list does. |

## Audit items (ux-audit §1.13–1.20 and the P0 list)

| audit item | status | evidence |
|---|---|---|
| P0.1: `substring(0, 4)` crash on short ids (§1.15) | **Fixed** | No substring. A non-Mongo id returns `ClubNotFound` without a request (`comunity_provider.dart:24`). Probe: `/communities/null`, `x/about` and an unknown id plus `/settings` all show "This club doesn't exist", with no exception. |
| P0.1: `name!` and `description!` force-unwraps on Info (§1.18) | **Fixed** | `displayName` never throws. The description falls back to "This club has no description yet." Probe with `name: 42` and `description: null`: "Untitled club", no exception. |
| P0.2: "CL\* —" fallback copy (`routes.dart`) | **Fixed** | `_MissingExtraScreen` now says "Couldn't open this page", with `ClAppBar` and a fallback route. |
| P0.4: "Enter invite code above" and the fake invite Join (§1.13) | **Fixed** | Both are gone, and there's no code field (tested at `clubs_screens_test.dart:217`). See R9-N3 for the leftover copy. |
| P0.4: Club Settings is a dead end with inert rows (§1.19) | **Fixed** | `ClAppBar` with a fallback. The only row left is the role, plus a real Leave with `showClDialog` confirmation (the dialog pops before `onConfirm`, so there's no double submit). The owner gets a disabled button and an explanation, but see R9-S2. |
| P0.4: Info's action chips and topic rows are no-ops (§1.18) | **Fixed** | They're removed. About shows only backend facts (members, admins, films, founded). Moderation and Analytics are gone, and `_JoinPrompt` is deleted. |
| P0.4: Chat's no-op controls (§1.17) | **Fixed** by gating | Nothing in `lib/` pushes `/communityChat`, or the legacy `/communityInfo` and `/communitySettings`. The only reference is inside the chat screen itself. A deep link to `/communityChat` shows `_ChatUnavailableScreen` while `kClubChatAvailable` is false. |
| P0.6: unreadable chat text | **Deferred** | Chat is behind the flag (out of scope). |
| §1.13: ADMIN badge on every club | **Fixed** | `roleOf` uses `isOwner(me)` and `isAdmin(me)`, which mirror `membership.js`. Tested. |
| §1.13: "Active 2h ago", picsum avatars, raw `SnackBar`, error copy, FAB covering rows, 9pt badges | **Fixed** | Stats come from data, with a `ClAvatar` monogram, `ClSnackbar` and `ClErrorState`. There's no FAB (Create is an app-bar icon). The bottom padding is `xxl + paddingOf.bottom`. The badge is `ClBadge`. |
| §1.15: hardcoded demo data, fake refresh, duplicate CTAs, three app-bar icons, raw uids, chevrons with no tap, no loading or error | **Fixed** | Detail is driven by `GET /communities/:id`, `/polls/active` and `/communities/:id/movies`, each with its own skeleton, error and retry. There's one primary CTA (Join or Suggest) and one overflow menu. Members are counts. Every film tile opens its thread. See R9-S4 for refresh. |
| §1.15: overflows at 320 | **Fixed** | The layout matrix (7 screens, 320/390 × 1.0/1.3/2.0) passes. My probes at 320 @1.3 and @2.0 (the Vote Join card, Clubs tab error and no-match states) found no exceptions and no broken words. |
| §1.16: raw exception, wrong provider, Cancel, 0.8× width, no `textInputAction` | **Fixed** | A generic `ClStatusBanner`. `createCommunity` updates the joined list and invalidates the all-clubs list (but see R9-N4). There's no Cancel. Name uses `next`, which moves focus to the description. A double tap makes 1 POST (probe). The description is required, which matches the Mongoose `required`. |
| §1.18: `Theme.textTheme`, `Colors.grey` | **Fixed** | Tokens and `Cl*` widgets only (grep is clean). |
| §1.19: hardcoded "Cinephiles Unite", no club id, non-scrolling Column, own background and gold | **Fixed** | `/communities/:id/settings` uses `ClubScaffold` with a `ListView`. Gold: none. |
| §1.20: orphan `JoinedCommunitiesScreen` | **Fixed** | Deleted, along with `CommunityState`. |
| P1.1: load Info and Settings by id, not `extra` | **Fixed** | `/communities/:id/about` and `/settings` exist. The legacy routes map `extra.id` onto them. |
| Round 7 N3 / R8-N3: Vote gets the club name, and non-members don't see Vote buttons | **Fixed** (see R9-S1) | `{'club': name}` is passed (tested). The `_JoinToVote` card is purple, so the gold leader badge keeps the budget. Its membership source is wrong for legacy members. |

## Design-system and accessibility checks

- **Gold budget:**
  - Detail: the Join or Suggest primary. Vote uses `inverse`.
  - Clubs tab: only the empty-state "Create a club".
  - About: Join, for non-members only.
  - Membership: none (danger).
  - Create: "Create club".
  - Vote: the Join card is `purple`, so it doesn't compete with the gold leader badge.
  - The matrix's `goldViolations` passes everywhere.
- **Controls:** the refresh indicators are `AppColors.purple`, the `ClAvatar` ring is purple, and the role badges use the purple tone.
- **`textMuted`:** used only on the forward chevron in the sheet's menu rows, which sit on the sheet's flat surface. That's allowed.
- **Touch targets:**
  - `_MenuRow` is `minTouch + 8`. Join and Create use `ClButton`, and the icon buttons use `ClIconButton`.
  - The ClubTile Join button sits beside the text, or below it above 1.6× or when the row is narrow.
- **Semantics:**
  - Headers on the screen title, the section titles and the club name.
  - The tiles are one button labelled "name. stats. role". The Join button's label is "Join <club>".
  - The fact cards read as "Members: 3".
  - The loading skeletons are `liveRegion`.
- **Shell padding:** the Clubs tab pads `xxl + MediaQuery.paddingOf(context).bottom`, as Discover does.
- **Data robustness:** `Community.fromJson` survived every odd shape in the odd-backend-data probe without an exception. `_list` drops non-map entries, and `communities: null` gives an empty list.

## What works

- **The audit's P0s for this group are gone.** That covers the crashes, the demo data, the fake controls, the dead-end settings and the wrong ADMIN badge. Every route is keyed by id and says "doesn't exist" for bad links, without a wasted request.
- **The membership model is careful where it's used.** `unknown` is a real state, so nobody gets a Join button while `/joined` is loading or has failed, and Vote keeps its buttons when membership is unknown. R9-S1 is about the *source* of the membership answer, not this design.
- **Honest copy.** The screens don't offer moderation, rename or delete, because the backend has none, and Membership says so in its doc. Chat says it isn't open yet rather than showing a local mock.
- **Per-section states on Detail,** with a failed refresh keeping the data (it just needs to say so: R9-S4).
- **Layout.** The tile, header and fact grid change layout at large text instead of breaking words, and the 42-case matrix passes.
- **The tests are broad:** data shapes, the real router, join and leave, create, Vote for non-members, and the layout and gold matrix. What they miss is a server-faithful `/joined` and refetch failures, which is where R9-S1 and R9-S3 live.

## Summary

| severity | count |
|---|---|
| Blocking | 0 |
| Should-fix | 4 (R9-S1 to R9-S4) |
| Nit | 8 (R9-N1 to R9-N8) |

**Verdict:** ready to merge. A strong redesign that fixes every audit P0 for the group. Fix R9-S3 (a join that looks failed or can be repeated) before release, and fix R9-S1 together with its backend `/joined` ask.

## Resolution (2026-11-26)

| ID | Resolution | Test |
|---|---|---|
| R9-S1 | `clubMembershipProvider(id)` now decides from the club itself (`Community.isMember`, the backend's rule), then `/joined`, then the all-clubs list if it's already loaded (never fetched just for this). Vote, Detail, About, Membership, Club discussions and the suggest sheet all use it. The Clubs tab counts a club as yours by `isMyClub` (overrides, `/joined`, or the club's own members). Backend ask still open: make `/joined` use `isCommunityMember`'s rule. | `clubs_data_test` "owner-only and raw-id members count"; `clubs_screens_test` "R9-S1" (server-faithful `/joined`) |
| R9-S2 | Membership shows a skeleton while the user id loads. When the id is null or membership is unknown, it shows "Couldn't check your membership" with retry, and no role card or Leave. | "R9-S2" |
| R9-S3 | `joinClub`/`leaveClub` return `(ClubActionDone?, ClubActionRefusal?)`, record the change in `clubMembershipOverridesProvider` (wins over stale data) and **await** the refetch (keeping the auto-dispose club provider alive while waiting). Buttons stay busy until then and ignore re-entry. A failed refetch says "You joined X. Couldn't refresh the club yet." Shared `showJoinResult` (`join_feedback.dart`). | "a join whose refetch fails…" (data and screen) |
| R9-S4 | Detail's refresh collects all three results; any section that had data and failed shows one "Couldn't refresh. Showing earlier details." | "R9-S4" |
| R9-N1 | Detail shows "Couldn't check your membership" with retry when membership is unknown because a source failed; nothing while it loads. | — |
| R9-N2 | About uses `showJoinResult` (not-found copy). New `ClubActionRefusal.unauthorised` for 401/403 with session copy. | data test (401) |
| R9-N3 | "$name is ready. Friends can find it under Clubs." | — |
| R9-N4 | `createCommunity` invalidates the joined list when it had no value, and records the new club in the overrides. | — |
| R9-N5 | `leaveClub` checks `code: 'OWNER_CANNOT_LEAVE'` first, then the message. Backend ask: send that code. | data test |
| R9-N6 | Vote's empty state: non-members get "Join club"; members get the new copy. Club discussions' empty state: non-members get "Open club". | movies test (copy) |
| R9-N7 | Membership's "Open club" uses `pushReplacement`; the suggest sheet's uses `push`. | — |
| R9-N8 | Detail shows "You run this club" / "You're an admin" (purple) instead of "You're a member". | "R9-N8" |

Also: demo (non-Mongo) ids are membership `unknown`, so no Join is offered for a club that can't exist. The suggest sheet still says "not in this club" for them. Tests: 397/397. Analyzer: 0 errors, 0 warnings.
