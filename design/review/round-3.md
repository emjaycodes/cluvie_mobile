# Design review, round 3: authentication flow

Commit reviewed: `5221521` on `feat/design-overhaul`, plus the later move of `_TicketDivider` into `ClTicketDivider`, which behaves the same. Scope: splash, onboarding, welcome, login, signup, forgot password, `auth_backdrop.dart`, `auth_form_scaffold.dart`, `launch_state.dart`, `auth_provider.dart`, `AuthRepository.restoreSession`, the profile logout change, and `test/auth_flow_test.dart`.

## Verdict

**Not ready to merge: 4 blocking findings.**

The redesign closes the big gaps from the audit:
- The first-run gate is real.
- Login calls the API, with validation.
- The signup crash is gone.
- The dead Apple and Google buttons are hidden.
- The switch links replace the screen instead of stacking.
- Reduced motion is handled on every new animation.

Four problems remain:
1. Onboarding page 3 overflows on small phones. With the real bundled fonts it overflows at 1.0× on 320 pt wide phones, and at 1.3× on the 375×667 iPhone SE.
2. On short screens and at 1.3×, the Welcome heading sits on the un-scrimmed poster wall. This breaks both the contrast rules and the scrim rule in tokens.md.
3. Logout bypasses the auth provider and leaves the previous user's cached data in memory.
4. Forgot password tells the user an email is on its way when no request is ever sent.

Below those, there is a group of session and error-handling issues:
- A token is saved before the response is parsed.
- Non-network failures are reported as "check your connection".
- The router guard is still a no-op.
- A stale error banner flashes and is announced on the next screen.

The tests cover the launch gate well but leave every success, failure and navigation path through the screens untested.

**Tool runs**
- `flutter analyze --no-fatal-infos`: 15 infos, 0 warnings, 0 errors. None of them are in the auth files. The 3 in `profile_screen.dart` (`_following`, `_xp`, `_VoteCard`) are not from the logout change.
- `flutter test`: 61 of 61 tests pass.

**How the layout was checked.** The layout claims come from a scratch widget test, kept outside the repo. It loads the real Sora and Plus Jakarta Sans fonts (the default test font is much wider and gives false results) and renders at 320×568, 375×667 and 390×844, at 1.0× and 1.3× text, with reduced motion on.

## Findings

Severity: **B** = blocking, **S** = should-fix, **N** = nit.

| id | sev | file:line | finding | concrete fix |
|---|---|---|---|---|
| B1 | **B** | `onboarding_screen.dart:325-385` (`_PartyPreview`), inside `_OnboardingPage` `:154-169` | **Page 3 overflows vertically.** Measured with the real fonts: 69 px at 320×568 1.0×, 174 px at 320×568 1.3×, and 23 px at 375×667 1.3× (iPhone SE 2/3 with larger text). Pages 1 and 2 are fine. The card has a fixed 150 pt image area plus three rows, and it sits in an `Expanded` with a non-scrolling heading below it. In debug you see the yellow overflow stripes. In release the card is clipped and the heading collides with it, which is an accessibility failure at 1.3×. | Let the visual shrink to fit: wrap `visual` in `FittedBox(fit: BoxFit.scaleDown)` inside the `Expanded`, or make the poster height in `_PartyPreview` a `LayoutBuilder` fraction (as `_PosterFan` already does). Also make each page body scrollable (`CustomScrollView` + `SliverFillRemaining(hasScrollBody: false)`) so the heading itself can never overflow. Add a 320×568 @1.3× golden or overflow test for all three pages. |
| B2 | **B** | `welcome_screen.dart:26-47` (layout) and `:130-141` (wall mask) | **Heading text on the poster wall.** The wall is drawn at 55% opacity and fully opaque down to 32% of the screen height, then fades out by 56%. Measured heading top: 36% at 320×568 1.0×, **17%** at 320×568 1.3×, and 37% at 375×667 1.3×. At 1.3× on 320 pt, line 1 (`textPrimary`) sits over the full wall. Worst case (a white poster) that is about 2.9:1, which fails even the 3:1 large-text minimum. Line 2 (`purpleText`) and the start of the body are worse. tokens.md (`scrimBottom`) requires poster text to start where the cover is at least 0.85. Here the cover is about 0.45–0.55. | Tie the mask to the content, not the screen. Measure the heading's top (a `GlobalKey` or `CustomMultiChildLayout`) and end the fade (alpha 0) at least 24 pt above it. A simpler alternative: put a `bg` panel behind the heading block that is at least 85% opaque, or hide/shorten the wall when `c.maxHeight < 640 \|\| textScaler > 1.15`. Then check worst-case contrast at 320×568 @1.3×. |
| B3 | **B** | `profile_screen.dart:295-299` | **Logout leaves session state behind.** It calls `AuthRepository().logout()` directly. `authNotifierProvider` still holds the old `AuthState.success(user)`. Global, non-`autoDispose` providers keep the previous user's data, for example `joinedCommunitiesProvider` (`comunity_provider.dart:7`). If someone else logs in without killing the app, they see the first user's clubs. There is also no confirmation step (audit 1.14). | Make the profile screen a `ConsumerStatefulWidget`. Call `ref.read(authNotifierProvider.notifier).logout()` and then invalidate the user-scoped providers (`joinedCommunitiesProvider`, `allCommunitiesProvider`, and any watchlist or profile providers), or rebuild the `ProviderScope` with a session key. Add a `ClDialog` confirmation, then call `go(welcome)`. |
| B4 | **B** | `forgot_password_screen.dart:35-41`, `:46-78` | **Fake success.** No reset endpoint exists, yet the screen shows "Check your inbox… you'll get a link in a few minutes" (live-region announced). This is a control that does nothing while claiming it worked, which is the case audit P0-3 ("honest") and P0-4 ("every visible control must either work or be removed") rule out. A user who is locked out waits for an email that never arrives. | Until the endpoint exists, either hide the "Forgot password?" link (`login_screen.dart:94-101`) behind a flag, as was done for social login, or replace the success state with honest copy and a contact or support action. When the API lands, wire it up with real error states. |
| S1 | S | `auth_repository.dart:46-51`, `:68-73` | The token is saved **before** `UserModel.fromJson` runs. If the user JSON is missing or malformed, login reports failure but the token is already stored. The next cold start then goes straight to Home through `restoreSession`. A null `token` also throws a `TypeError` here. | Parse first, then save. Check `token is String && token.isNotEmpty` before calling `_saveToken`. On any failure after saving, call `_clearToken()`. |
| S2 | S | `api_exceptions.dart:32` and `auth_provider.dart:83-86` | `ApiException.fromDio` turns every non-Dio error (a parse bug, a `TypeError`) into `statusCode: null`. `friendlyAuthError` then tells the user "Can't reach Cluvie… check your connection". That hides real contract bugs and sends users to troubleshoot their Wi-Fi. A Dio `badCertificate` error or a cancelled request lands in the same bucket. | Add a `kind` to `ApiException` (network, timeout, http, parse) based on `DioExceptionType`. Show the connection message only for `connectionError`, `connectionTimeout`, `receiveTimeout` and `sendTimeout`. Show the generic message for parse errors and log them loudly. |
| S3 | S | `auth_provider.dart:87-98` | The status mapping is too broad and too narrow at once. On login, `400` is shown as "email and password don't match", but a 400 is usually malformed input. `422` (validation) and `429` (rate limited) fall through to "Something went wrong", and a 429 needs a "wait and try again" message. On signup, `400` gives "check your name, email and password" without saying which one, even though the server body probably names the field. | Map 401/404 to the credentials message, and 400/422 to a field message parsed from `responseBody` when one is present. Add a 429 case: "Too many attempts. Wait a minute and try again." Add tests for each case. |
| S4 | S | `routes.dart:46-55` | The router `redirect` is still a no-op, with stale TODO comments, and the header comment says "Home -> /" even though `/` is onboarding. Logged-out users can reach shell routes through `go('/home')`, a restored URL, or any future deep link. Logged-in users can reach `/welcome` and `/login` the same way. Nothing in the manifest exposes deep links today, so this is not blocking. | Back the redirect with a `ValueNotifier<bool> sessionListenable` set by `restoreSession`, login and logout, and pass it as `refreshListenable`. Send logged-out users on non-auth routes to `/welcome`, and logged-in users on auth routes to `/home`. Fix the comments. |
| S5 | S | `auth_repository.dart:32-37`, `launch_state.dart:19` | A returning user's session is "a token exists". There is no expiry check and no 401 handling (`api_client.dart` has no auth interceptor, and `setupDioLogging` is never called). A revoked or expired token lands the user on Home with every request failing, and the only way out is Profile → Log out. | Add a Dio `onError` interceptor: on a 401 from a non-auth path, clear the token, update the session notifier, and redirect to Welcome with a "Your session expired, log in again" banner. Optionally call `/auth/profile` in the background after splash. |
| S6 | S | `login_screen.dart:31-33`, `:61-64`; `sigup_screen.dart:30-32`, `:64-67` | A stale error is cleared in a post-frame callback, so the first frame of the new screen still shows the previous screen's banner. `ClStatusBanner` is a `liveRegion`, so TalkBack/VoiceOver may announce the old error. The banner also stays up after the user edits the fields. | Clear the error **before** navigating (in the switch-link and back handlers). Better: make the error per-screen (`authNotifierProvider.autoDispose`, or keep the error in local state). Clear the banner in `onChanged` of either field. |
| S7 | S | `login_screen.dart:43-46`, `:89`; `sigup_screen.dart:43-48`, `:104` | `_submit` has no in-flight guard. `ClButton` ignores taps while loading, but the keyboard's Done (`onSubmitted`) still fires `_submit`, which sends a second login or register request. A double register can produce a misleading 409 "already exists" after the account was in fact just created. | Add `if (ref.read(authNotifierProvider).isLoading) return;` at the top of `_submit`. |
| S8 | S | `forgot_password_screen.dart:71` | "Back to log in" calls `goNamed(login)`, which replaces the whole stack. Login becomes the root: `ClAppBar` shows no back button, Welcome can't be reached, and Android Back exits the app. The "Remembered it?" link on the same screen does this correctly (`:110`). | Use the same logic as `:110`: `context.canPop() ? context.pop() : context.goNamed(RouteNames.login)`. |
| S9 | S | `splash_screen.dart:33-47` | There is no error path. If `SharedPreferences.getInstance()` or `restoreSession()` throws (corrupt prefs, a platform channel failure), the `Future.wait` rejects and the splash stays up forever. This is the "no timeout or error path" problem from audit 1.1, still open. | Wrap the call in `try/catch` and fall back to `LaunchDestination.onboarding` (or welcome) on error. Add `.timeout(5s)`. Add a test with a `LaunchState` whose `resolve()` throws. |
| S10 | S | `auth_backdrop.dart:42-52` | A second **gold** radial glow (`Color(0x1FFFD27D)`, hardcoded) sits on every auth screen, so splash, onboarding, welcome, login, signup and forgot all carry an extra gold element outside rule 1 (a)–(d). tokens.md defines ambient glow as purple (`brandGlow`, `glowPurple`). It is faint (about 6% alpha), so it is not counted as blocking, but it is an untokenised gold value. | Remove it, or use a `purpleText`/`purple` tint from `AppColors`. If warm light is wanted, add it to tokens.md as a named token with a budget exemption first. |
| S11 | S | `auth_backdrop.dart:99`, `:105` | `AuthHeading` uses an off-scale size: `display` overridden to 34/40, and body overridden to 16 pt (the `body` token is 15/22). Neither value is in the type scale. | Use `display` (40/44) or `h1` (28/34) unchanged. If 34 is the intended size, add a `displaySm` token to tokens.md and `AppTextStyles`. Use `AppTextStyles.body` as it is. |
| S12 | S | `onboarding_screen.dart:175-203` | The page indicator has a good static label ("Page 2 of 3"), but page changes are not announced, and the `PageView` does not expose its scroll semantics in a useful way ("Next" is the only accessible route). | In `onPageChanged`, call `SemanticsService.announce('Page ${i + 1} of 3', TextDirection.ltr)`, or wrap the dots in `Semantics(liveRegion: true)`. |
| S13 | S | `forgot_password_screen.dart:60` | "Check your inbox" is a visual heading but has no `Semantics(header: true)`. Every other auth heading goes through `AuthHeading`, which sets it. | Wrap it in `Semantics(header: true)`, or use `AuthHeading(center: true)`. |
| S14 | S | `sigup_screen.dart:73-80` | The field is labelled **Name**, with the hint "Ada Obi" (contains a space), but its value is sent as `username` (`auth_repository.dart:63`). If the backend expects a handle (unique, no spaces), real names fail with a vague 400 "Some details look off". | Check the API contract. Either label the field "Username", with helper text giving the allowed characters and matching client-side validation, or send `name` and derive the username on the server. |
| S15 | S | `test/auth_flow_test.dart` | Important paths are untested: login success (→ home, `onboarding_seen` set, token saved); login failure (banner shown, typed input kept); signup success and failure; onboarding Skip and Get started (prefs written, → welcome, genres saved); welcome → signup/login push and switch-link replacement (back-stack depth); forgot → back; logout clearing the token and the next `resolve()` returning welcome; the stale-error clear; layout at 320×568 @1.3× (would have caught B1); reduced motion (no pending `Animate` timers). The repository and notifier are not injectable (`AuthNotifier` news up `AuthRepository()`, which news up the `ApiClient` singleton), so none of the network paths can be tested. | Inject `AuthRepository` through a provider (`authRepositoryProvider`) and `ApiClient` through `apiClientProvider`. Add fake-repo widget tests for the paths above. Add an overflow test that pumps every auth screen at 320×568 and 1.3× with the bundled fonts loaded through `FontLoader`. |
| N1 | N | `splash_screen.dart:1` | `// ignore_for_file: use_build_context_synchronously` isn't needed: `mounted` is checked. The blanket ignore will hide future mistakes. | Remove it. |
| N2 | N | `splash_screen.dart:37` | The 1.1 s minimum hold also applies under reduced motion, where there is nothing to watch. | Use `motion.reduced ? Duration.zero : 1100ms`. |
| N3 | N | `onboarding_screen.dart:36-40`, `:73` | Tapping Skip or Get started twice runs `_finish` twice (two prefs writes, two `goNamed` calls). It's harmless, but sloppy. | Add a `_finishing` flag. |
| N4 | N | `onboarding_screen.dart:68-75` | Skip is hidden on the last page. The approved mood board note says "Skip always visible". "Get started" covers the action, so this is a nit. | Keep Skip visible, or note the deviation in the mood board. |
| N5 | N | `onboarding_screen.dart:244-246` | `_PosterFan` asks for `h + 40`. When `maxHeight` is under about 286 (short phones, 1.3×) the box is clamped, and the "7 of 9 votes" chip overlaps the poster. | Compute `h = min((c.maxHeight - 40) , 340)`. |
| N6 | N | `onboarding_screen.dart:262`, `:266`, `:353`, `:362` | Hardcoded values: `fontSize: 13`, and padding values of 14, 10 and 6 that are off the 4-pt scale. | Use `AppTextStyles.bodySm` and `AppSpacing` values. |
| N7 | N | `onboarding_screen.dart:294-301` | `PageView` disposes page 2 when you leave it, so the chip entrance stagger replays every time you come back. | Set `allowImplicitScrolling: true` on the `PageView`, or play the entrance only once. |
| N8 | N | `routes.dart:62-72` | The gate navigates to `onboarding` at `/onboarding-legacy`, and a second copy of the screen is mounted at `/`. | Give onboarding one route (`/onboarding`) and drop `onboardingRoot` once nothing links to `/`. |
| N9 | N | `auth_provider.dart:46`, `auth_repository.dart:50`, `:69` | Leftover debug logs: `"usreeeeeeeee $user"`, and the full response including the token. They are debug-only through `BuildConfig`, but they put the bearer token in device logs during QA. | Remove them, or redact the token. |
| N10 | N | `auth_form_scaffold.dart:44-46` | A 6-character minimum, applied on login as well. If the server rule ever changes, login will block valid existing passwords on the client. | On login, check only that the password is non-empty. Keep the length rule on signup. |

## Gold budget per screen

| Screen | Gold elements | Within rule 1? |
|---|---|---|
| Splash | logo (c) + backdrop gold glow | Glow is extra (S10) |
| Onboarding | logo (c) + Next / Get started CTA (a) + glow | Glow is extra |
| Welcome | logo (c) + "Continue with email" (a) + glow | Glow is extra |
| Login / Signup | CTA (a) + focus ring (d) + glow | Glow is extra |
| Forgot (form and sent states) | CTA (a) + glow | Glow is extra |

Purple carries identity on every screen: heading line 2, the dots, selected chips, the crown, the Tonight badge and the links.

## Contrast spot checks

Every pair below passes, except the Welcome wall (B2).

| Pair | Ratio | Result |
|---|---|---|
| `textSecondary` body on `bg` | 8.1 | Pass |
| `purpleText` heading line 2 on `bg` | about 7 | Pass |
| `bodySm` switch prompt on `bg` | 8.1 | Pass |
| Banner `label` on `surfaceRaised` | 15.7 | Pass |
| "Oppenheimer" `h2` on the scrimmed poster (starts below 68%, where the scrim is at least 0.85) | — | Pass |
| Vote chip label on `surfaceRaised` | — | Pass |

## What works

- **The first-run gate is real and simple.** `LaunchState` is small, readable and tested for all three destinations, and splash routing has widget tests for each branch.
- **The dead ends from audit P0-3 and P0-4 are gone:**
  - Login, Signup and Forgot all have a back affordance (`ClAppBar` shows it only when the route can pop).
  - Skip works.
  - Pages 1 and 2 have a Next button.
  - Social buttons are hidden behind `kSocialAuthEnabled`.
  - The signup crash (`RouteNames.movies`) is fixed.
- **Navigation choices are mostly right:**
  - Welcome *pushes* login/signup, so Back returns to Welcome.
  - The login↔signup links *replace*, so they don't stack.
  - "Remembered it?" pops when it can.
  - Auth completion uses `go`, so Back can't return to the forms.
- **`mounted` checks** come after every `await`. `context.mounted` is used in the logout closure.
- **The forms are good:**
  - Labelled `ClTextField`s with hints.
  - `AutofillGroup` with the correct hints (`newPassword` on signup).
  - `TextInput.finishAutofillContext()` on success.
  - `next`/`done`/`send` keyboard actions.
  - A password visibility toggle.
  - Typed input is kept on error; the inline banner replaces the old full-screen error swap.
- **Error copy** is plain language. It never leaks exception text, and a test enforces that.
- **Reduced motion** is handled on every new animation:
  - Splash reveal: skipped.
  - `ClEntrance`: returns the child as is.
  - Parallax: off.
  - Page change: `jumpToPage`.
  - Dots and the Skip fade: zero duration.
  - Route transitions: the theme's `ReducedMotionPageTransitionsBuilder`.
- **Semantics are good:**
  - Headings are announced as headers with the two lines joined.
  - Illustrations are single labelled images (`excludeSemantics`).
  - The decorative wall and backdrop are excluded.
  - The page dots have a label.
  - The sent state on Forgot is a live region.
  - The preview RSVP button is non-interactive (`IgnorePointer`).
- **Touch targets:** every `TextButton` (Skip, Forgot, the switch links) gets the 48 dp minimum from the theme.
- **Login, Signup and Forgot scroll safely:** they use a `ListView` with keyboard dismiss on drag, so 1.3× and small phones are fine there. Welcome's `IntrinsicHeight` + `Spacer` scroll pattern did not overflow in any measured configuration.
- **Logout now clears the stored token**, so the next launch correctly lands on Welcome (see B3 for what it still leaves behind).

---

## Resolution (implementer, 2026-11-25)
All 4 blocking findings fixed. 73/73 tests pass. The analyzer has 0 errors and 0 warnings.

| ID | Resolution | Test |
|---|---|---|
| B1 | Onboarding pages split 3/5 visual and 2/5 heading. The visual scales down to fit (the party preview uses a `FittedBox`), and the heading scrolls if cramped. | `auth_layout_test`: no overflow on all 3 pages at 320×568, 375×667 and 390×844, at 1.0× and 1.3× |
| B2 | Welcome copy sits on a solid 96% bg panel after a fixed 56dp fade, so it never sits on the poster wall at any text scale. A top scrim is added behind the logo. | `auth_layout_test`: the heading top is at or below the solid panel top, at every size and scale |
| B3 | A new `signOut()` (`data/sign_out.dart`) calls the notifier's `logout()`, invalidates the communities, movies and comments providers, then goes to welcome. Profile is now a `ConsumerStatefulWidget` with a destructive confirm dialog. | — |
| B4 | `kPasswordResetAvailable = false` hides "Forgot password?". The screen, if deep-linked, says plainly that reset isn't available yet. No fake "check your inbox". | — |

Should-fix items also done:
- **S1:** the user is parsed before the token is saved.
- **S2:** only real network failures say "check your connection".
- **S6:** the error banner appears only after this screen's own submit, so there's no stale flash and no post-frame `clearError`.
- **S7:** repeat submits are ignored while a request is in flight.
- **S8:** "Back to log in" pops instead of resetting the stack.
- **S9:** splash times out after 5s and falls back to welcome on error.
- **S10:** the gold glow was removed from `AuthBackdrop`.

Deferred, for the router and auth hardening pass:
- **S4:** the router `redirect` still does nothing.
- **S5:** expired tokens (401) aren't handled.
- **S15:** the full navigation paths aren't tested; it needs an injectable repository.
- The remaining nits.
