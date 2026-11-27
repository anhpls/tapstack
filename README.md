# Tapstack

### Every membership, stamp card and reward you have, in one stack.

You belong to a dozen rewards programs: a punch card from the boba shop, the bakery's app, a burrito chain's points, a paper card somewhere in your car. At the register you can't find the right one, so you skip it, and the free drink you earned quietly expires.

Tapstack fixes that from both sides of the counter.

- **For customers:** one app holds every membership and stamp card, so the right one is ready in a second at checkout.
- **For small shops:** a complete loyalty program with no app to build and no new hardware. Staff stamp from a phone or browser, and owners finally see who keeps coming back.

> **Status:** in active development, iPhone app first. Pre-launch: no shops are live yet.

---

## Why it's different

| Most rewards apps | Tapstack |
| --- | --- |
| One app per brand, one login per app | One stack for every program you belong to |
| Paper punch cards get lost, along with their stamps | Scan the paper card in, and the shop verifies it into real stamps |
| Small shops can't afford a custom app | Shops get the program, the counter tools and a dashboard without building anything |
| Stamps can be faked with a photo or a second tap | Staff-only stamping, cooldowns and live redemption codes |
| Owners see nothing beyond a stack of punched cards | Return rates, regulars, lapsed customers and which deals actually work |

## What's built

**The stack**
- Every card in one place, grouped into **category stacks** that fan open with one tap
- An **"Almost there"** section that surfaces cards one visit from a reward
- **Real Code128 barcodes** any store scanner reads, with smooth auto-brightness like a boarding pass
- Instant search, stamp history and a premium card finish

**Paper card rescue**
- Scan a paper stamp card with **VisionKit**, cleaned up with **Core Image** (auto-adjust and sharpening, plus retaking one side if it caught glare)
- The card keeps the shop's own artwork in the stack
- **Never carry the paper card again** <br>
  Once it's scanned, it lives in your stack. The stamps you already earned become official after the shop checks the card once, so nobody can fake stamps from a photo. Staff can confirm fewer stamps than claimed, never more.

**Stamping and rewards that can't be gamed**

- **Business mode** in the same app; one account, two modes, like Airbnb's host mode
- Multi-stamp visits with per visit limits, double stamp promos and a two minute cooldown
- **Customer started redemption:** the customer shows a 4-digit code and a ticking timer that a screenshot can't fake, and staff confirm it
- Extra stamps carry over, and two way corrections come with a double tap guard
- Every stamp is logged with who, when and why

**Accounts and security**

- Passwordless email code sign-in
- **Row Level Security on every table:** the database itself only shows each person their own data
- Every sensitive action (stamping, redeeming, transfers, corrections) runs through **security definer Postgres functions** that check the rules server-side, so a modified client can't bypass them
- Private image storage with per-user folders and signed URLs

## Engineering highlights

- **Server side rules, thin client.** Stamp limits, cooldowns, redemption windows and transfer caps live in Postgres functions, not in the app, so the same rules apply to iOS, the web dashboard and future integrations.
- **Security by default.** RLS is on for every table, stamps and rewards can only change through checked functions, and secrets never reach git.
- **Trust you can see.** The customer facing history shows only the net daily change from corrections, while owners get the full audit log.
- **Built to connect.** Linked memberships are designed around platforms, not individual brands (the "Plaid of loyalty" approach); one integration, such as Square Loyalty, unlocks thousands of shops at once.

## Tech stack

| Layer | Tech |
| --- | --- |
| iOS app | SwiftUI (iOS 17+), Observation, VisionKit, Core Image, PhotosPicker |
| Backend | Supabase (Postgres, Row Level Security, security definer functions, Storage, Auth) |
| Business dashboard | Next.js, Tailwind CSS, `@supabase/ssr` (in progress) |

## What's next

- **Business dashboard** on the web so shops can access tools from any tablet or laptop
- **Linked memberships** for chains like 85°C and CAVA, then live balances through Square Loyalty
- **Deals in every card**, including AI drafted deals that owners approve with one tap
- **Tap to join** with an NFC sticker, no download needed
- **Growth tools** for owners that show who keeps coming back and win back regulars who stopped
- A full **UI/UX redesign** before the first shop pilot

See the [feature catalog](docs/roadmap/FEATURES.md) for all 116 planned features.

## Product planning

- **[Feature catalog](docs/roadmap/FEATURES.md):** every feature, its status and why it matters
- **[Roadmap](docs/roadmap/Tapstack.Roadmap.public.pdf):** the path from zero shops to a paid launch with phases
- **[For customers](docs/pitch/Tapstack.For%20Customers.pdf)** and **[for business owners](docs/pitch/Tapstack.For%20Business%20Owners.pdf):** the one page pitches
- **[Changelog](#changelog):** every update so far
- **[Review package](docs/pitch/Tapstack%20%E2%80%94%20Review%20Package.pdf):** the full product overview

## Current Repo layout

```
ios/                  SwiftUI app
  App/                  entry point and root navigation
  Models/               card model and the observable card store
  Design/               theme, card styles, shared components
  Features/             Auth, Home, Cards, Rewards, AddCard, Business
supabase/migrations/  schema, RLS policies and functions, applied in order
web/                  business dashboard (Next.js)
docs/                 roadmap, feature catalog and pitches
```

## Changelog

### 2026-11-27
- Paper card verification at the counter
- Test shops for solo testing
- Top banner for stamping results
- iOS project reorganized into feature folders
- README, feature catalog, public roadmap and pitches

### 2026-11-25
- Card stack, category stacks and search
- Supabase backend with Row Level Security
- Business mode with stamping limits, promos and corrections
- Live redemption codes
- Paper card scanning with photo cleanup
- Edit, hide and delete cards; premium card style

### 2026-11-20
- Project setup (iOS app and web dashboard)
