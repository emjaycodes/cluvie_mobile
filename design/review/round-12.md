# Design review, round 12: member profiles, profile editing, round-11 residuals

Scope: `ecd1c9a..7a6a724` on `feat/design-overhaul`. Commits: `87dfad7` (Home S3/N1), `2c0eff5` (notifications: mark all read, push settings, direct targets), `09ae80f` (round-11 report), `259f206` (member profiles and editing), `d5cb5d3` (make-admin codes), `14e0998` (Home S2, N2, N3, N5 redirect, N14), `7a6a724` (round-11 resolution).

Method: code reading of every changed file, the round-11 resolution checked against the code, and the screenshot set from `test/_shots/shots_test.dart` at 390×844 @3x (Home, room, profiles, notifications, members, party states; 2× text for the profile). The three profile routes are additionally exercised at 320×568 and 390×844 × 1.0/1.3/2.0 by `test/profile_test.dart` (broken-word and gold-budget checks). 585 of 585 tests pass; `flutter analyze --no-fatal-infos` reports no issues.

The independent reviewer lane was unavailable this round (model quota), so this is an orchestrator review. The automated layout/gold/broken-word checks carry the visual verification for every new route.

## Verdict

Ready to merge. Profiles, editing, follow, make-admin codes and the Home staleness fix are complete, contract-faithful and covered at both widths. There is one should-fix: opening your own `/users/:id` link lands on the tab profile in a root route with no visible way back. The rest are nits.

## Findings

| id | sev | file:line | finding | concrete fix |
|---|---|---|---|---|
| R12-S1 | S | `profile_screen.dart:150`; `profile_screen.dart:259-263` | **Your own profile link opens without a way back.** `_OtherProfile` returns `_MyProfile()` when `isMe`. `_MyProfile`'s `SliverAppBar` sets `automaticallyImplyLeading: false`, and the screen normally lives in the tab shell. A pushed `/users/<your-id>` (a shared link, a deep link) therefore renders with no tab bar and no back button — only the platform back gesture. | When `p.isMe` inside `_OtherProfile`, replace with `/profile` (`context.replace`), or render the tab profile with `showBackButton: true` when the router can pop. |
| R12-N1 | N | `notifications.dart:157-167` | `markAllRead` restores the old list only if the current list has no unread item. If a new notification arrives while the failed PATCH is in flight, the optimistic reads stay and the failure is invisible. | Restore the ids that were unread when the request started, or invalidate the list on failure. |
| R12-N2 | N | `profile.dart:225-229`; `profile_screen.dart:184-190` | A bio of only spaces is saved as-is and then renders as an empty-looking bio line (`bio.isNotEmpty` is true). | Trim the bio before sending; treat a blank result as `''`. |
| R12-N3 | N | `edit_profile_screen.dart:172-229` | No unsaved-changes guard: back (or the system gesture) discards a typed bio/avatar silently. The form is short, but a 160-character bio is easy to lose. | If `_dirty`, confirm on pop (or keep the form small enough to accept the risk — say which). |
| R12-N4 | N | `profile.dart:142` | `isMongoId` is imported from `features/movies/data/polls.dart` into the profile data layer. | Move the guard to `core/` and import it from both. |
| R12-N5 | N | `profile.dart:196-199` | Any 400 that isn't `CANNOT_FOLLOW_SELF` is treated as success ("already following"). Today that's the only 400 the contract defines; a future 400 (rate limit, bad target) would read as followed. | Match the "already following"/"not following" phrases, else `failed`, as the party refusals do. |
| R12-N6 | N | `cl_avatar.dart:37-40` | The avatar tints are raw `Color(0x…)`. Pre-existing, and the Phase-6 audit will flag it. | Move the five tints into `AppColors` (an avatar palette) so the audit is clean and the colours are documented. |

## Round-11 resolution check

Every claim in `round-11.md`'s Resolution section holds against the code: S1 (reconnecting keeps the room), S2 (build-time arm, past-deadline refetch, nullable label, suggest/discussion invalidations), S3 (time-split happening, hero = next), N1 (join generation), N2 (`NOT_PARTICIPANT`), N3 (roster/names/reactions; "Someone" neutral), N4 (`onSessionEnded`), N6 ("Starts …"; no future `timeAgo`), N7 (live host gets End), N8 (`purpleSolid`), N9 (`totalVotes`, film-comment label, hidden missing time), N10 (`socketEndpoint` + tests), N11 (navigate before clearing), N12 (party title hero), N13 (`h3` + shared disabled), N14 (`scrollUntilVisible`, `ConnectFailed` tests). N5 is correctly stated as partial: the legacy redirect is fixed, the room still gates only on `isOver()`.

## Design-system and accessibility checks

- **Gold budget:**

  | screen | gold |
  |---|---|
  | Your profile | none (Edit is secondary) |
  | Someone's profile | none (Follow/Following is secondary) |
  | Edit profile | the Save button only |
  | Home, party list/detail, room, notifications, settings, About | unchanged from round 11 |

- **Tokens:** no `Colors.*`, `Color(0x…)` (except the pre-existing avatar tints, R12-N6), `GoogleFonts.` or `Icons.` in the new screens. The edit form, profile headers and settings rows use `AppTextStyles`/`AppSpacing`/`AppColors`.
- **Word breaks and overflow:** `/profile`, `/users/:id` and `/profile/edit` pass at 320×568 and 390×844 × 1.0/1.3/2.0 with no broken words and no gold violations. Usernames use `FitWordsText`, so a 30-character name steps h2 → h3 → title. The stats grid still chooses its column count from measured label width.
- **States:** profile loading (skeleton, live region), not-found vs load error with Retry, following optimistic + rollback, `CANNOT_FOLLOW_SELF` quiet no-op; edit loading/error, field errors, `USERNAME_TAKEN` inline, `INVALID_PROFILE` banner, Save disabled until dirty and valid; notifications mark-all-read optimistic + restore, settings toggles optimistic + revert.
- **Semantics:** stats read "Followers: 2"; Follow reads "Follow ada_follows" / "Unfollow ada_follows"; the profile name is a header; skeletons are labelled and live. The neutral avatar is only used with a name ("Someone"), so it never announces an empty label.
- **Keyboard/membership:** the edit form dismisses on drag and pads for the bottom inset; the profile follows the backend rule (public, not member-gated).

## Backend gaps

- A party's actual start time (`startedAt`) is still missing, so Home and the room can only show the scheduled time (round-11 N6).
- Follow/unfollow's only defined 400 is `CANNOT_FOLLOW_SELF`; if the backend adds another 400, the app would read it as success (R12-N5).

## What works

- `/users/:id` shows the real public profile: avatar, name, joined month, bio, followers/following/suggestions/clubs, and a Follow button whose count moves before the server answers and rolls back with "Couldn't follow" on failure.
- Your own profile shows bio and avatar, and Edit opens `/profile/edit` above the tab shell; saving updates the header, the edit form validates username/bio/avatar to the backend's rules, and `USERNAME_TAKEN` is inline.
- Make-admin reads the server's code first (NOT_ADMIN, INVALID_TARGET, ALREADY_ADMIN, NOT_A_MEMBER, 404) and refetches only when something changed or the club vanished.
- Home no longer counts down on a closed poll and refetches a cached feed whose deadline already passed; the room names real people and shows "Someone" for the rest; the legacy party link opens the party page.
- Notifications open their populated film, club and party targets without a lookup, mark all read optimistically, and the settings screen saves each push/quiet-hours change at once with a revert on refusal.

## Summary

| severity | count |
|---|---|
| Blocking | 0 |
| Should-fix | 1 (R12-S1) |
| Nit | 6 (R12-N1 to R12-N6) |

**Verdict:** ready to merge. Fix before release:
- **R12-S1:** your own profile link must not strand the user without a back.

Then adopt the backend's `startedAt` when it lands.
