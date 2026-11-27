# UX Patterns to Adopt

Distilled from the references in `sources.md`. Each pattern names the Cluvie screen it lands on.

## Social presence everywhere
Friends are the reason people watch (Letterboxd study). Every film/party/poll card shows **who** (avatar stack + "Ada, Tunde +6"), not just a count.
→ Home cards, watch party list, vote rows, discover results.

## One primary action per card
Kiosk: each event card has exactly one pill CTA (RSVP). Cluvie cards today mix several inline buttons.
→ Poll card: "Vote". Discussion card: tap whole card. Watch party: "RSVP" / "Going ✓".

## Three-state RSVP with counts
Going / Maybe / Can't as a segmented control showing live counts; selected = gold fill.
→ `watch_party_screen` RSVP sheet.

## Ranked poll rows
Rank badge on poster corner, animated progress bar behind the row, % + vote count right-aligned, gold crown on leader. Tap = vote (haptic + bar animates). Once voted, your pick shows a check.
→ `vote_summary_screen`, Home "Active Polls".

## Club as a hub with tabs
Club header (banner, name, members avatar stack, Join/Joined) → tabs: **Chat · Discussions · Polls · Parties**. Composer "+" opens a sheet: Suggest film, Start poll, Plan watch party.
→ `community_detail_screen`, `community_chat_screen`.

## Chat
Grouped consecutive messages, own messages gold-tinted bubble on right, others `surfaceRaised` left with name colour. Reaction pills below bubble. Date separators. Glass composer pinned above keyboard.

## Poster-first hero
Full-bleed poster, scrim, overline (genre · year), display title, meta chips, primary + glass secondary CTA. Collapses into app bar on scroll.
→ Movie details, Home featured.

## Onboarding that personalises
Slide 1 mood image + value prop → slide 2 genre grid (multi-select) → slide 3 "join or create a club". Skip always visible. Accent on second line of heading.

## Floating glass nav with centre action
5 slots; centre "+" (Suggest) raised gold circle. Active tab = filled icon + gold pill + label; inactive = regular icon, no label. Content gets bottom padding = nav height + 16.

## States are designed, not afterthoughts
Every list: skeleton (shape-matched) → content (staggered in) → empty (illustration + one CTA) → error (retry). Pull-to-refresh on all feeds.

## Anti-patterns to remove
- Multi-gradient loud cards (poll-dark-14).
- Hard-coded design-QA toggles shipping in prod (Home section-title tap).
- Buttons sized to `0.8 × screen width`.
- Text below 4.5:1 contrast.
