# Design review, round 11: live rooms, Home on `GET /feed`, round-10 fixes

**Commits reviewed** (`feat/design-overhaul`, HEAD `cc15665`):
- `dcb8536` feat(watch-party): live rooms over the backend socket (`socket_io_client` 3.1.6, `party_room.dart`, `watch_party_room_screen.dart`, `canEnterRoom`, "Enter live room", the `/watchParty` legacy redirect)
- `4ecfe86` fix(watch-party): greet every join so a reconnected user sees the room
- `a281df6` fix: resolve design review round 10 findings
- `cc15665` feat(home): Home runs on `GET /feed`; no demo data left

**Scope:**
- `watch_party/data/party_room.dart`, `presentation/watch_party_room_screen.dart`, `watch_party_screen.dart`; `canEnterRoom` and `_act` in `watch_parties.dart`; the detail screen's action block
- `core/api/api_client.dart` (`socketUrl`, the 401 token check), `core/repository/auth_repository.dart` (`savedToken`), `core/router/routes.dart` (`/watch-parties/:id/live`, `/watchParty`)
- `home/data/home_feed.dart`, `home/presentation/home_screen.dart`, and every `homeFeedProvider` invalidation (`sign_out.dart`, `comunity_provider.dart`, `polls.dart`, `watch_parties.dart`)
- Each round-10 fix in `a281df6` (app, clubs, notifications, profile, reset password, party list and tile)
- `~/.pub-cache/hosted/pub.dev/socket_io_client-3.1.6`: `socket.dart` (`emitWithAckAsync`, `onerror`, `CONNECT_ERROR` → `destroy()`, `dispose`) and `manager.dart` (`open`, `reconnect`, which emits `error` on every failed attempt)
- The tests that came with each commit

**Backend checked (read only, `cluvie-backend`).** The other session committed while I was reviewing. HEAD moved from `d34afca` to `b5143e3`, `7b0b404`, `982addf`, `d664514` and finally **`3c0c346`**. Everything below was re-read at `3c0c346`. The uncommitted changes left at the end (`package.json`, `server.js`, swagger removed in favour of OpenAPI) don't touch the routes in scope.
- `socket.js`:
  - The handshake checks the JWT plus `isTokenRevoked`. A failure is `next(new Error("unauthorized"))`, which reaches the client as a `CONNECT_ERROR` with `{message: "unauthorized"}`.
  - `watchparty:join` checks `canEnterParty` (a participant, or a club member; **any status, any time**). It acks `{ok: true, roster: [{userId, username}]}` (**roster since `982addf`**), or `{ok: false, error: forbidden|server_error}`. It also tells the room `presence {userId, username, action: "joined"}`.
  - `watchparty:leave` tells the room `left` **without** checking the user's other sockets. `disconnecting` does check them (`d34afca`).
  - `watchparty:presence` relays any action string, `joined` and `left` included.
  - New in `982addf`: `watchparty:reaction` (key validated, 10 per 2 s per socket) and `watchparty:message` (room chat, not stored).
  - The token is only checked at the handshake.
- `routes/watchpartyRoutes.js` (`7b0b404`):
  - Codes: `PARTY_CLOSED` (join once `isClosed`, i.e. ended/cancelled or 4 h past start), `ALREADY_PARTICIPANT`, `HOST_CANNOT_LEAVE`, **`NOT_PARTICIPANT` (leave, new)**, `NOT_HOST`, `NOT_A_MEMBER`.
  - Bad ids get 404. A private party returns 404 to non-members on join.
  - The list now takes `upcoming`, `past`, `mine`, `order`, `from` and `to`.
  - `PATCH update` emits `watchparty:updated` to the room and sets `endTime` on `ended`. Nothing records a start time.
  - `participant_joined`, `participant_left` and `deleted` go to the room.
- `utils/partyLifecycle.js` and `parties.scheduler.js`: every 15 min, `updateMany` ends scheduled **and live** parties 4 h past `scheduledAt`. It emits **no socket event**.
- `routes/feedRoutes.js` (unchanged since `2a332f3`):
  - Returns `{success, data: {communities, polls, suggestions, discussions, watchParties}}`.
  - Parties are `scheduled|live` with `scheduledAt ≥ now − 3 h`, sorted ascending, at most `limit`.
  - Polls are `open` and not expired, soonest-closing first. `totalVotes` is the sum of `voteCount`. An option's `movie` is null when its film is gone.
  - Discussions carry `movie.commentCount` (the film's count), `upvotes` and `createdAt`.
  - With no clubs, every list is empty.
- `routes/pollRoutes.js`: vote and close-early (`89ce1c4`). `middleware/authMiddleware.js` and `utils/sessionCheck.js`: the same 401 rule the app relies on (round 10).
- `routes/resetPageRoutes.js`: the https page meta-refreshes to `cluvie://reset-password?token=…` and shows an "Open Cluvie" button. The flag comment in `cc15665` describes it correctly.

**Checks run:**
- `flutter analyze`: **No issues found** (run with infos counted, unlike round 10's `--no-fatal-infos`).
- `flutter test $(ls test/*.dart)`: **547 of 547 pass**. The output has two flutter_test "drag() derived an Offset … would not hit test" warnings from `home_screen_test.dart:258` at 320×568 (see R11-N14).
- I grepped the 22 `lib/` files changed in `a193c56..cc15665` for `Colors.`, `Color(0x`, `GoogleFonts` and `TextStyle(`. Every hit is `AppColors.*` or `AppTextStyles.*`, except the reactions' raw `TextStyle(fontSize: 24)` (R11-N13).
- I looked at the new renders in `shots11/` (`17`–`22`: Home, the room as host and live, and the host's party page) and at `15_about_members.png` for R10-N1 and R10-N3. I didn't re-check `01`–`14` and `16`, which screens this round didn't change. Posters and emoji don't render in the harness, as expected.

**Probes:** throwaway tests in `test/_review11/`, now deleted. Real-socket probes ran the backend's own `socket.js` at `3c0c346` under node, with only `Watchparty`, `Community`, `User` and `sessionCheck` stubbed. They drove the app's real `SocketRoomLink`. The node script was `/private/tmp/claude-502/-Users-gate84limited-Documents-cluvie-cluvie-mobile/fb719920-f13b-4b82-ad70-776178741ebe/scratchpad/probe11/server.js`, a scratchpad file that isn't kept and isn't in either repo.

| # | probe | result |
|---|---|---|
| T1 | connect, join, react, `close()` | Join `ok`. The server sees `watchparty:join`, the presence ping, then `watchparty:leave`, then "client namespace disconnect". `close()` leaves cleanly, and `dispose` tears down the forceNew manager. |
| T2 | revoked token | `ConnectFailed(unauthorized: true)`. The `'$e'.contains('unauthorized')` check works on `{message: unauthorized}`. |
| T3 | server unreachable for 8 s, then back | 0.0 s `Connected`, 0.1 s `Disconnected`, **1.1 s `ConnectFailed(unauthorized: false)`**, 2.2 s and 5.3 s more of the same, **10.3 s `Connected`**. The rejoin is `ok`. The client keeps retrying after each `ConnectFailed`. |
| T4 | users A and B on two app links, a third user on a raw client killed with `-9`, then a second device of A that joins and `close()`s | A sees B `joined` and answers `here`. B sees A `here` and A's `joined`. B's `react:wow` reaches A and doesn't echo to B. The killed client gives A `left`. **When A's second device closes, B gets `Presence(A, left)` while A's first device is still in the room.** |
| P1 | room screen: `Disconnected`, then `ConnectFailed(false)` (the T3 sequence), then `Connected` | The reconnect banner goes. **"Couldn't join the room" ×1 and "React" ×0**, so the room is replaced. Then it comes back on its own ("In the room" ×1, joins = 2). |
| P2 | `HomeFeed.fromJson` shapes | Only a live party: pick = null, parties = 0. A scheduled party 2 h past its start plus one tomorrow: **hero = the 2 h-old one**, and tomorrow's goes under "More". Two live parties: live = the first, **the second appears nowhere**. A poll that closed an hour ago: **"closes in 1 minute"**. An option whose film was deleted: app total 3 against the server's `totalVotes` 10. |
| P3 | join #1 in flight, then drop, reconnect, join #2 `ok`, then join #1 times out | "In the room" ×1, then **"Couldn't join the room" ×1** although the socket is in the room. |
| P4 | Home party cards at 320×568 @1.0, 1.3 and 2.0, each card scrolled into view (4 cards with long titles and club names) | No exceptions and no mid-word breaks. Long names ellipsize by design. Layout holds. |

## Verdict

**Ready to merge: 0 blocking findings.** Fix R11-S1 to R11-S3 before release.

The live room works against the real server. I proved this end to end (T1–T4):
- The join ack and the forbidden refusal.
- Presence both ways.
- Reactions.
- `left` on a kill.
- Rejoin after an outage.
- A clean leave and dispose.
- Telling unauthorized apart from unreachable.

Home is fully on `/feed` with no invented content. The gold budget holds on every screen. The round-10 fixes hold, with two caveats.

There are three should-fix problems:
- **R11-S1:** any network blip over about 1 s replaces the room with an error screen.
- **R11-S2:** Home never refreshes on its own, and stale data then says false things ("closes in 1 minute" on a closed vote).
- **R11-S3:** because nothing but the host's button makes a party live, the party in progress shows as "Next watch party". "Live now" almost never appears, and when it does, the section below it says nothing is planned.

The backend also shipped a roster, a reaction event and chat during this review. The app doesn't use them yet (R11-N3).

## Findings

Severity: **B** = blocking, **S** = should-fix, **N** = nit. Every backend reference is committed at `3c0c346`.

| id | sev | file:line | finding | concrete fix |
|---|---|---|---|---|
| R11-S1 | S | `watch_party_room_screen.dart:95-100`; `party_room.dart:110`; socket_io_client `manager.dart:205` (the `error` on every failed attempt) and `socket.dart:371-376` (`onerror` → `connect_error` while not connected) | **A connection blip of more than about 1 s throws the user out of the room.** The client emits `connect_error` on *every failed reconnect attempt*, and it keeps retrying (T3: failures at 1.1, 2.2 and 5.3 s, then back at 10.3 s). The screen handles `RoomConnectFailed` while `reconnecting` as final: `_state = failed`. The banner, the people and the reactions are replaced by "Couldn't join the room. Check your connection and try again." (P1).<br>When the socket comes back, the room reappears by itself. So a user on a train sees the room flicker to a full error screen and back. Tapping Retry during the outage tears down a socket that was about to recover. | • While `reconnecting`, ignore `RoomConnectFailed(unauthorized: false)`. Keep the room and the "Reconnecting…" banner.<br>• Fail only when the *first* connect fails, or on the manager's `reconnect_failed`. Expose it as its own event, and/or cap with `setReconnectionAttempts`.<br>• Keep the room's content visible under the banner, with reactions disabled.<br>• Add a fake-link test: `Disconnected` → `ConnectFailed(false)` → `Connected`, asserting "Couldn't join" never shows. |
| R11-S2 | S | `home_feed.dart:130-148,309-313`; `home_screen.dart:170`; `suggest_sheet.dart:83`; `discussions.dart:111` | **Home only refetches when the user pulls, or after an RSVP, vote or club change, and stale data reads as fact.** `homeFeedProvider` isn't autoDispose, and nothing refreshes it on app resume or when the tab is re-selected. After a night in the background, Home shows yesterday's feed:<br>• The poll says **"closes in 1 minute"** for a vote that closed hours ago. `closesIn` clamps to zero, and the label floors to 1 minute (P2).<br>• The hero is a party that's over.<br>• A party that went live isn't shown.<br>• Suggesting a film (`/communities/:id/suggest`) and posting a discussion don't invalidate the feed, so "New in your clubs" and "Recent discussions" miss your own action. | • Refetch on `AppLifecycleState.resumed`, and when Home is re-selected if the feed is older than about 5 min. Keep the data and use the existing failed-refresh snackbar.<br>• Make `closesInLabel` nullable. Once `closesAt` has passed, show "Voting closed" (or drop the poll) instead of a countdown.<br>• Invalidate `homeFeedProvider` after a suggestion and after a discussion post. |
| R11-S3 | S | `home_feed.dart:50-60`; `home_screen.dart:187,191-206`; backend `feedRoutes.js:87-92` | **The party happening now is billed as "Next watch party", and "Live now" is the exception.** Only the host's "Start the party" sets `live`. A party nobody started stays `scheduled`, and the feed returns it for 3 h after its start. `fromJson` picks the first non-live party as the hero, so during every unstarted party Home's hero is the party in progress: "Next watch party · Today · 20:00", with a gold "RSVP". The actual next party is pushed into "More watch parties" (P2).<br>The rare live case reads wrong too:<br>• With only a live party, the next section says **"Watch parties: No watch parties planned yet."** directly under the Live card.<br>• With two live parties, the second is on Home nowhere (P2). | • Split by time as well as status. "Happening now" = `live`, or `scheduled` with `scheduledAt ≤ now` and not over (`kPartyStaleAfter`). Show every one of them in the Live section (a list, not `.first`), with the room CTA when `canEnterRoom`.<br>• The hero = the first party with `scheduledAt > now`.<br>• When something is on now, the empty copy should say "Nothing else planned yet."<br>• Add fixture tests for each of these. |
| R11-N1 | N | `watch_party_room_screen.dart:84-94` | **A stale join result can override a newer one.** `_on` awaits `link.join()` per `RoomConnected` with no guard. Sequence: join #1 is sent, the connection drops before its ack, the reconnect's join #2 succeeds, then join #1 hits its 8 s timeout and sets `failed`. "Couldn't join the room" then shows while the socket is in the room, and no further `RoomConnected` comes to fix it (P3). The window is a drop during the join round trip, which is narrow but real on mobile. | Tag each join with a generation (`final gen = ++_joinGen`), and apply the result only if `gen == _joinGen && link == _link`. `_retry` swaps links while an old join can still time out. |
| R11-N2 | N | `watch_parties.dart:218-225`; backend `watchpartyRoutes.js:295-296` | Leave now answers **400 `NOT_PARTICIPANT`** when you weren't going (it used to be a no-op 200). `_act` maps that to `failed`, which shows "Couldn't update the party. Try again." and doesn't refetch.<br>Example: you take back your RSVP on your phone, then tap the stale "Can't make it" on your tablet. You get the same error on every retry. | Treat `code == 'NOT_PARTICIPANT'` as done (null refusal, then reload), like `ALREADY_PARTICIPANT`. Add a test. |
| R11-N3 | N | `party_room.dart:73-77,111-115,124-141`; `watch_party_room_screen.dart:101-124,312`; backend `socket.js:96-129` (`982addf`) | **The backend now has what the room works around, and the app doesn't use it.**<br>• The join ack carries a `roster`, and `joined` carries `username`. The app still runs the `here` handshake. Since `4ecfe86`, every client answers every `joined`, so each join costs N−1 extra messages, and a client that repeats `joined` makes everyone reply each time.<br>• People who haven't RSVP'd show as **"A club member"**, with "AC" initials as if that were a name (`20_room_host.png`). The roster's `username` would name them.<br>• Reactions go out as `presence react:<key>`, which skips the server's key check and its 10-per-2 s limit. A client that uses the new `watchparty:reaction` event won't be shown by this one. | Seed `_here` from the ack's `roster`, and take names from `roster` and `joined.username`. Drop `here` (keep answering it for one release if older builds exist). Send and listen to `watchparty:reaction`. Render an unknown name as "Someone", with a neutral avatar and no initials. |
| R11-N4 | N | `watch_party_room_screen.dart:97-100,231-238` | **Unauthorized has no way out.** `ConnectFailed(unauthorized: true)` (T2) shows "Log in to join the room / Your session ended." with no button. The app isn't actually signed out: the socket refusal doesn't go through `endSessionOnce`, so every other tab keeps working until a REST call gets a 401. | Route it into the same session-ended path (`ApiClient.onSessionEnded` / `endSessionOnce`), or at least offer "Log in" (via `/splash`). |
| R11-N5 | N | `routes.dart:117-121`; `watch_party_room_screen.dart:59-78,273-296` | **The room doesn't apply `canEnterRoom` itself.** The legacy `/watchParty {id}` redirect, a pasted link, or a stale screen opens the room of a cancelled or ended party. The socket joins (the server allows any member at any status), and reactions are live under "This party was cancelled." | When `p.isOver()`, don't connect. Show the ended or cancelled state with "Back to the party". Redirect the legacy route to the party page (`/watch-parties/:id`), not straight into the room. |
| R11-N6 | N | `home_screen.dart:833`; `watch_party_room_screen.dart:267`; `relative_time.dart:16-24` | **"Started" times are really the scheduled time.**<br>• "4 going · started 30 minutes ago" and the room's "Started · Today · 13:35" come from `scheduledAt`.<br>• A host can start early (the room is open to them at any time). Then `timeAgoSpoken` of a future time gives **"started just now"** for the whole wait.<br>• A late start reads as earlier than it was. | Say "Scheduled for 13:35" until the backend records a start time (see the backend gaps). Never call `timeAgoSpoken` with a future time. |
| R11-N7 | N | `watch_party_detail_screen.dart:207-218` | **On a live party, the host's party page offers "Cancel party".** The room offers "End party" for the same state. Cancelling a running party marks it cancelled for everyone ("This party was cancelled."), when it really ended. | When `status == live`, show "End party" there (the same confirm as the room), or no destructive action. |
| R11-N8 | N | `home_screen.dart:825` | The Home Live card's badge is `ClBadgeTone.error` (red). The party list, detail and room use `purpleSolid` for Live, and tokens.md assigns LIVE-style pills to `purpleBadge` ("Purple carries identity"). | Use `ClBadgeTone.purpleSolid`. |
| R11-N9 | N | `home_feed.dart:135,282,285`; `home_screen.dart:1021` | **Real data, wrong meaning.**<br>• A discussion card's "5 comments" is the *film's* `commentCount`, not replies to that post.<br>• The poll total re-sums the parsed options. An option whose film was deleted (`movie: null`) drops out with its votes (P2: 3 shown, 10 on the server, which also sends `totalVotes`).<br>• A discussion without `createdAt` gets `DateTime.now()`, so it says "just now". | Label it as the film's ("5 comments on this film"), or drop it. Use the server's `totalVotes`. Hide the time when `createdAt` is missing. |
| R11-N10 | N | `api_client.dart:32-36` | `socketUrl` only strips a path ending exactly in `/api`. `…/api/` (a trailing slash), or a server behind a path prefix (`https://host/backend/api`), leaves a path. socket_io_client treats that path as the **namespace**, so the server answers "Invalid namespace" and the room shows "Couldn't join" forever. There's no unit test. | Trim a trailing `/`, and put any remaining prefix into `setPath('<prefix>/socket.io')` with namespace `/`. Allow a `SOCKET_URL` define. Unit-test `http://h:5000/api`, `…/api/` and `https://h/x/api`. |
| R11-N11 | N | `sign_out.dart:16-20`; `home_feed.dart:309-313` | Manual Log out (Profile) clears state *before* navigating. R10-N7's ordering fix only covers `endSessionOnce`. Now that the non-autoDispose `homeFeedProvider` is in `clearUserState`, the mounted Home tab refetches `/feed`, and `/users/me` with it, without a token. These are harmless 401s, because the header is null, but they're wasted requests. | Navigate first, as `endSessionOnce` does. In `homeFeedProvider`, return `const HomeFeed()` without a request when `me == null`. |
| R11-N12 | N | `home_feed.dart:85` | The hero names the *film*, not the party. "Noir night" (the party's title) never appears on Home's hero, while the party page leads with it. Two parties for the same film look identical. | Title = the party title, with the film and year as the supporting line (as on the party page). Or show both when they differ. |
| R11-N13 | N | `watch_party_room_screen.dart:333-343` | The reaction buttons use a raw `TextStyle(fontSize: 24)` and dim the emoji with `Opacity(0.4)` when you're not in the room. That goes against "tokens only" and against the disabled-state rule (fill `surfaceRaised` and muted content, not opacity). | Add a token emoji style (for example from `h2` metrics), and use `ClPressable`'s disabled treatment. |
| R11-N14 | N | `home_screen_test.dart:258`; `test/watch_party_test.dart:111-145` | **Test gaps.**<br>• The Home layout test's sideways drag misses at 320×568 (flutter_test warns), so later party cards aren't checked there. P4 checked them: they hold.<br>• `_FakeRoom` never emits `ConnectFailed` after `Disconnected`, and never delays a join, which is where R11-S1 and R11-N1 live.<br>• There are no tests for `SocketRoomLink` or `socketUrl`. | Scroll the card list with `scrollUntilVisible` on the horizontal `Scrollable`. Add the two fake sequences. Unit-test `socketUrl`. Optionally keep a node-backed protocol test in CI, as in T1–T4. |

## Design-system and accessibility checks

- **Gold budget** (read from the code, and agreeing with `17`–`22`):

  | screen | gold |
  |---|---|
  | Home | The hero CTA ("RSVP" / "View party"), or "Find a club" in the first-run state. Nothing when there's no hero. Card CTAs are `inverse`, the poll leader is purple, and Discuss is secondary. |
  | Party detail | "I'm going" or "Enter live room", never both. The host gets "Enter live room" plus a danger "Cancel party". |
  | Live room | "Start the party" (host, scheduled, not over). "End party" is danger, and the refusal and error states are secondary. The host's avatar ring is purple. |
  | Party list, notifications, profile, About | unchanged from round 10 (none, or one) |

- **Word breaks and overflow:**
  - The room matrix passes: the cases "room", "room (guest)" and "room (host, scheduled)", each at 320 and 390 × 1.0, 1.3 and 2.0.
  - The Home matrix passes, and P4 adds every party card at 320×568 up to 2.0×. Long names ellipsize; none break mid-word.
  - `FitWordsText` steps the room title down h2 → h3 → title, and the poster drops above 1.6×.
- **States:**
  - Home: skeleton, error with Retry, failed refresh that keeps the feed plus a snackbar, the first-run no-clubs card, and empty poll, party and discussion states with no gold.
  - Room: connecting, reconnecting, forbidden, failed, signed-out (no action, R11-N4), deleted, and party not found.
- **Semantics:**
  - Reactions are 52 pt `ClPressable`s labelled "Send popcorn" and so on.
  - The latest reaction and the "In the room (n)" header are live regions.
  - Each person in the room reads as their name, and the hero CTA says "RSVP to the X watch party".
  - An unnamed person reads "A club member" (R11-N3).
- **Membership:**
  - The party detail keeps the three states.
  - In the room, the server's `forbidden` maps to "Only club members can come in" with "Open club".
  - `canEnterRoom` needs `isGoing(me)`, so an unknown id offers no room.

## Round-10 resolution check

| id | status |
|---|---|
| R10-S1 | **Holds.** `kPasswordResetAvailable` is still off. The flag comment now names the real remaining blocker: email delivery. Its `PUBLIC_BASE_URL` is still right, because `authRoutes.js:102` uses `PUBLIC_BASE_URL || RENDER_EXTERNAL_URL`. The backend's https page (`resetPageRoutes.js`) bounces to `cluvie://` and has a tappable button. |
| R10-S2 | **Holds.** `isOver` drives the detail, badge, list and room. The backend now also auto-ends after 4 h, and `PARTY_CLOSED` agrees with `kPartyStaleAfter`. |
| R10-S3 | **Holds as a stopgap** (pages up to 5 × 100). The backend filters now exist (`upcoming`, `past`, `mine`, `order`); see the backend gaps. |
| R10-S4 | **Holds.** The button stays busy until the reload, with the "Couldn't refresh the party yet." variant. The room's host actions use the same path. |
| R10-S5 | **Holds.** `partyStateLabel` feeds both the badge and the semantics. |
| R10-S6 | **Holds.** A skeleton while the id loads, then "Couldn't check your RSVP" with Retry. |
| R10-N1 | **Holds** (`PromoteResult`; `15_about_members.png`: no action on the deleted account). The backend now sends `ALREADY_ADMIN` and `NOT_A_MEMBER`, which the app checks first. |
| R10-N2 | **Holds.** |
| R10-N3 | **Holds.** A small secondary button, inline at 390 @1.0 (`15_about_members.png`). |
| R10-N4 | **Holds.** Codes come first, and they match the committed backend codes. The new `NOT_PARTICIPANT` isn't handled (R11-N2). |
| R10-N5 | **Holds.** The rollback checks the optimistic item by `identical`, and the count is fetched once. |
| R10-N6 | **Holds.** Only the failed film is re-inserted, at its index. |
| R10-N7 | **Holds** for 401s (the token comparison, `endSessionOnce`). Manual Log out still clears before navigating (R11-N11). |
| R10-N8 | **Holds with a caveat.** "Log in" and "Back to log in" go to `/splash`, so someone still signed in lands on **Home** after tapping "Log in". Relabel to "Continue", or show "Log in" only when signed out. The doc comment at `reset_password_screen.dart:22` still says "for 30 minutes". |
| R10-N9 | **Holds** (the copy). The backend's `mine=true` now allows the real fix. |
| R10-N10 | **Holds.** |

## Backend gaps

All of these refer to `3c0c346`.
1. **An explicit `watchparty:leave` drops a user who is still in the room** (T4). `leave` emits `left` without the "another socket of the same user" check that `disconnecting` has. A second device, or a room screen pushed twice, makes everyone else lose the user. Apply the same check in `leave`.
2. **Presence relays any action.** Clients can send `joined` or `left` for themselves, and each fake `joined` makes every peer reply. Reserve `joined` and `left` for the server, now that the roster and `watchparty:reaction` exist.
3. **Auto-end is silent.** `endOverdueParties` uses `updateMany` and emits no `watchparty:updated`, so a live room never learns its party ended. Emit per party, or have clients refetch on a timer.
4. **No start time.** `endTime` exists, but nothing records when the host started. Set `startedAt` when `status → live`, and send it in `/feed` and `GET /:id`. (R11-N6)
5. **The feed's 3 h grace and the 4 h auto-end disagree.** A live party that started more than 3 h ago disappears from Home while it's still live. Include `live` parties whatever their `scheduledAt`, and use `autoEndMs()` for scheduled ones. (R11-S3)
6. **The socket token is checked only at the handshake.** A revoked session (password reset) keeps receiving room events until it disconnects. Re-check on join, or disconnect a user's sockets on revocation.
7. **The app has yet to adopt what's now shipped:**
   - List filters: `upcoming=true&mine=true`, and `past=true` (descending). These close R10-S3 and R10-N9.
   - `roster`, `username`, `watchparty:reaction` and `watchparty:message`. (R11-N3)
   - Notifications read-all and preferences (`d664514`).
8. **`NOT_PARTICIPANT` is a new 400 for a request that used to be idempotent.** The app needs R11-N2. Alternatively, keep leave idempotent (200) and include the code for information.

## What works

- **The room protocol is right against the real server** (T1–T4):
  - The JWT goes in `auth.token`.
  - The `watchparty:join` ack is parsed, and the forbidden refusal is mapped.
  - Presence arrives both ways. A late joiner learns who's there through `here`, and a killed client shows as left.
  - Reactions reach the others with no echo.
  - Unauthorized is told apart from unreachable.
  - The socket rejoins after an outage.
  - `close()` sends `leave` and tears down the forceNew manager, with no lingering listeners (`dispose` clears them).
  - The token source is right: login and signup both write the token to prefs and to the header (`auth_repository.dart:16-19`).
- **`canEnterRoom` is a clean rule:** going (hosts count), not over, and live, within 30 min of the start, or the host. It drives the only gold on the party page.
- **Home is honest:**
  - Every item is from `/feed`, by id.
  - Every control opens a real route (`/watch-parties/:id`, the room, `/communities/:id/vote`, `/discussionThread` by catalog id, `/movie/:tmdbId`, `/suggest`, `/communities`, `/notifications`).
  - The no-clubs state is one card instead of five empty sections.
  - Feed invalidations sit after RSVPs, host actions, votes, club create, join and leave, and sign-out. There are no provider cycles, and over-fetch is limited to one `/feed` per action.
  - The demo feed is gone.
- **The round-10 fixes are real and tested:** 547 tests, including tests for each R10 item.

## Summary

| severity | count |
|---|---|
| Blocking | 0 |
| Should-fix | 3 (R11-S1 to R11-S3) |
| Nit | 14 (R11-N1 to R11-N14) |

**Verdict:** ready to merge. Fix these before release:
- **R11-S1:** a reconnect shouldn't look like a failure.
- **R11-S2:** Home should refresh itself and never count down on a closed vote.
- **R11-S3:** the party in progress isn't "next".

Then adopt the backend's roster and reaction event (R11-N3) and its list filters, which removes the `here` workaround and the "A club member" placeholder.
