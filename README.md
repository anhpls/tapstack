# Tapstack

**One app for every loyalty card you own.** Tapstack is a hub for rewards: shop stamp cards, chain memberships and the paper punch cards in your wallet all live in one stack, ready at the register. For small shops that will never build their own app, Tapstack *is* their loyalty program: staff stamp from a phone or browser, and owners get a dashboard that shows who keeps coming back.

> Status: in active development, iPhone app first. Not yet live with shops.

## What works today

- **The stack:** every card in one place, grouped into category stacks, with an "Almost there" section and search
- **Real barcodes:** Code128 member codes any store scanner can read, with smooth auto-brightness
- **Paper card rescue:** scan a paper stamp card (VisionKit plus auto-enhance), then have the shop verify it so the stamps become real
- **Staff stamping:** Business mode with multi-stamp visits, per-visit limits, promos, a cooldown, and two-way corrections with a double-tap guard
- **Fraud-resistant redemption:** the customer shows a live 4-digit code and timer that a screenshot can't fake; staff confirm
- **Passwordless sign-in:** email codes, with Row Level Security on every table and all sensitive actions behind protected database functions

## Tech stack

| Layer | Tech |
| --- | --- |
| iOS app | SwiftUI (iOS 17+), Observation, VisionKit, CoreImage |
| Backend | Supabase: Postgres, Row Level Security, security-definer functions, Storage, Auth |
| Business dashboard | Next.js, Tailwind, `@supabase/ssr` (in progress) |

## Repo layout

```
ios/                 SwiftUI app (App, Models, Design, Features/…)
supabase/migrations  Database schema, policies and functions, in order
web/                 Business dashboard (Next.js)
docs/                Product planning: roadmap, feature catalog, pitches
```

## Product planning

Tapstack is planned like a product, not only built like a project:

- [Feature catalog](docs/roadmap/FEATURES.md): all 115 planned features, each with its status and why it exists
- [Roadmap](docs/roadmap/Tapstack.Roadmap.public.pdf): phases from zero shops to a paid launch, each ending with a go/no-go check
- [For customers](docs/pitch/Tapstack.For%20Customers.pdf) and [for business owners](docs/pitch/Tapstack.For%20Business%20Owners.pdf): the one-page pitches
- [Review package](docs/pitch/Tapstack%20%E2%80%94%20Review%20Package.pdf): the full product overview
