# Reference Sources

Images in `screens/` are third-party work kept **locally for internal reference only** (git-ignored, never shipped). Credits below. Collected 2026-11-24 via Firecrawl.

| File | Shot / Source | Designer | → Cluvie screen | What we take |
|---|---|---|---|---|
| `dark-cinematic-05.jpg` | [Movie Streaming App UI — Dark Cinematic Experience](https://dribbble.com/shots/27270377) | Ashar Waseem | Home hero, Movie details | Oversized tight display type over full-bleed poster; overline labels ("FEATURED SELECTION"); pill tag chips + rating; primary pill CTA paired with glass secondary; synopsis card with left accent rule |
| `community-02.png` | [Movie Streaming Community App UI](https://dribbble.com/shots/27030074) | Tanvir Shough | Bottom nav, Discover filters | Floating glass nav pill with circular active state; outlined filter chips (selected = solid); poster carousel with peeking neighbours |
| `social-filmly-03.png` | [Social Movie Mobile App — Filmly](https://dribbble.com/shots/26871134) | Artspire | Vote summary, Discussion | Ranked rows with rank badge on poster; score ring (result bars come from Nickelfox, not this shot); mood tag pills; "9 friends recommend" avatar stack; All/Friends segmented filter; reviews with reaction pills |
| `social-tracking-01.png` | [Cinema App UI — Movie Tracking & Social](https://dribbble.com/shots/27323916) | Master Creationz | Home feed, Profile | Personal greeting header with accent name; horizontal poster rows; friends' reviews with poster thumbnail on the right |
| `onboarding-cineflow-07.png` | [CineFlow — Cinematic Onboarding](https://dribbble.com/shots/27871387) | Hafil Vc | Onboarding, Welcome | Moody full-bleed photo with bottom text block; accent colour on the second line of headings; genre picker grid with checked state; Skip top-right |
| `social-vibe-06.png` | [VIBE — Cinematic Social Media App](https://dribbble.com/shots/27724658) | Erik Adam | Profile, Nav | Profile header: avatar + bio + 3-stat row + primary/secondary buttons; tabbed grid; raised centre "+" in nav |
| `streaming-reel-08.png` | [Reel — Cinematic Streaming App](https://dribbble.com/shots/27749914) | Violet Arther | General tone | Overall dark cinematic tone |
| `discovery-duovue-04.png` | [DuoVue — Movie Night Discovery Case Study](https://dribbble.com/shots/27314878) | Austyn McFadden | Suggest flow | Group decision-making for movie night (closest product analogue) |
| `rsvp-events-09.png` | [Events and Tickets App · iOS Dark Mode](https://dribbble.com/shots/27875336) | Andrew McKay | Watch party list + RSVP | **Going / Maybe / Can't segmented control with counts**; "Theo, Marco +9 are going" avatar stack; ticket-stub card with notches + dashed divider; "TONIGHT" badge; sticky bottom CTA bar; date strip. Note: its card CTAs are **white** and selected "Going" is pink, not yellow — we follow that (white card CTAs, gold reserved for one owner per screen) |
| `chat-irl-11.jpg` | [IRL App: Group Chat Stream and Create Menu](https://dribbble.com/shots/21977112) | Christopher Koziol | Club chat, Club detail | Club header + **Chat / Threads / Events / Polls tabs**; reaction pills under messages; date separators (no bubbles here — Cluvie's own/other bubble treatment is our addition); "+" sheet with Add poll / Create event — near 1:1 fit for Cluvie clubs |
| `chat-community-10.png` | [Community & Chat App UI](https://dribbble.com/shots/27225446) | Sk Raju Hossin | Club list | Community cards, member counts |
| `poll-voting-12.jpg` | [Poll Creation & Voting Mobile App UI](https://dribbble.com/shots/26421660) | Diksha Mahajan | Vote flow | Poll creation steps, option bars |
| `poll-nickelfox-13.png` | [Polling Mobile App](https://dribbble.com/shots/21745113) | Nickelfox | Vote flow | Result bars with percentages |
| `poll-dark-14.png` | [Manage Polls — Dark Theme UI](https://dribbble.com/shots/6780121) | Alexey Supp | — | **Dated (2019) — do not build on.** Kept only as a counter-example of loud multi-gradient cards |

## UX research
- [Letterboxd — A UX Case Study](https://davisdesigninteractive.medium.com/letterboxd-a-ux-case-study-e0034805d48b) (Design Interactive, UC Davis) — social interaction is the main motivation to watch new films; 91% of non-users watch with friends → prioritise friend presence (avatars, "X going") everywhere. Watch-party feature proposed.
- Further case studies indexed (not yet read): Behance "Improving New-User Flow in Letterboxd", growth.design Letterboxd breakdown, Robert Hanly, Yenny.Design.

## Packages / assets (to be pulled in Phase 2–3)
- `flutter_animate` 4.5.2 — https://pub.dev/packages/flutter_animate (BSD-3)
- `phosphor_icons` 3.0.1 — https://pub.dev/packages/phosphor_icons (MIT; fork compatible with Flutter 3.43+ final `IconData`). Original `phosphor_flutter` 2.1.0 is not compatible.
- ~~`lottie`~~ — dropped (Phase 3): LottieFiles downloads require login; celebrations/loaders are built natively with `flutter_animate` + a `ClConfetti` painter (themeable, no third-party asset licence, trivially disabled for reduced motion).
- Fonts (OFL): Sora — https://fonts.google.com/specimen/Sora · Plus Jakarta Sans — https://fonts.google.com/specimen/Plus+Jakarta+Sans
