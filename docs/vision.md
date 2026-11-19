# Vision, principles and roadmap

This document describes where Prefab Flutter is going and the principles
that guide decisions along the way. What the code does today is in the
[user guide](user_guide.md); the planned work is in the
[backlog milestones](../backlog/milestones).

## Vision

Describe your business domain once, as an annotated model, and get a secure,
responsive, intuitive business app. Code by hand only what makes your app
different.

## Mission

Prefab Flutter turns annotated Dart models into at least 80% of a business
application's frontend, built on proven Flutter practices. It integrates
seamlessly with [Prefab](https://github.com/stijnvanbael/prefab) backends and
works with most REST APIs. Any generated piece can be taken over as ordinary
Flutter code, so the remaining 20% is written like in any other Flutter app.

## Who it is for

A solo developer or small team building rich applications for small and
medium businesses, where time to a usable, production-quality app matters more
than a bespoke design for every screen.

**One-year goal:** the first client application runs in production on
Prefab Flutter and Prefab.

## Guiding principles

When a design decision is unclear, these decide it, roughly in this order.

1. **The model is the app.** Behaviour is declared on the model (what is
   listed, searchable, editable, who may do it), not wired up by hand. A new
   feature first asks: "what is the smallest annotation that expresses this?"
2. **Infer first, configure second.** Every annotation parameter has a
   sensible default derived from the code (names, types, nullability, JSON
   mapping). An entity with only `@View()` must produce a usable app.
3. **Disposable by default, promotable at any time.** Generated code is not
   edited and not committed. Any single generated artifact (a screen, a
   provider, an API client, a route) can be *promoted* into the codebase.
   From then on the generator stops producing that artifact, and everything
   else keeps working with the promoted version. This mirrors Prefab, which
   skips generating classes that already exist.
4. **Plain Flutter at the seams.** Generated code is idiomatic, readable
   Flutter, Riverpod and GoRouter code that a developer would write
   themselves. Hand-written screens, providers and routes plug in through
   the normal APIs. There is no proprietary runtime to learn and no framework
   to fight.
5. **Secure and robust by default.** Authentication, authorisation-aware
   UI, server-side validation errors on the right field, edit conflicts,
   network failures, and empty and loading states are handled out of the
   box.
6. **Production quality out of the box.** Responsive (phone, tablet,
   desktop, web), accessible, localisable and themeable. No hardcoded
   English strings and no phone-only layouts.
7. **Prefab-native, REST-general.** Prefab's REST conventions work with
   zero configuration. Every backend-specific assumption sits behind a
   replaceable adapter, so other REST backends are a configuration choice,
   not a fork.
8. **Built for parallel, agent-driven development.** Features are small,
   self-contained modules (annotation reading, code emitters, tests,
   documentation) that rarely touch the same files. Rules are enforced by
   tools and CI, not only by prose.

## Scope

**Broad on use cases, narrow on technology.**

- **Backends:** REST/JSON only, with Prefab as the reference backend and an
  adapter for everything else. Nearly all backends of small and medium
  business apps are REST/JSON. GraphQL, Firebase and Supabase are out of
  scope until a real project needs them.
- **Frontend stack:** opinionated on Riverpod, GoRouter and Material. One
  well-supported stack keeps a small team fast; principle 4 keeps
  hand-written code free to use other packages.

### What business apps typically need

| Use case | Examples | Capabilities it needs |
|---|---|---|
| Customer and relation management | CRM, contacts, suppliers | CRUD, search and filters, relations (company ↔ contacts), notes, attachments |
| Sales and invoicing | Quotes, orders, invoices | Money and VAT, editable detail lines, status workflows (draft → sent → paid), export |
| Inventory and products | Stock, catalogue, price lists | Images, barcode scanning, lookups, bulk edit |
| Planning and scheduling | Appointments, rosters, bookings | Calendar views, date and time ranges, availability |
| Field service | Technicians, inspections, deliveries | Offline use, photos, signatures, maps, mobile-first layout |
| Time and HR | Timesheets, leave requests, expenses | Approval actions, role-based visibility, receipt upload |
| Projects and tasks | Project follow-up, ticketing | Board views, assignees, comments, notifications |
| Management overview | Dashboards, KPIs | Dashboard home, aggregates, charts, CSV/Excel export |
| Customer portals | Self-service orders, documents | Authentication, multi-tenancy, a restricted read-mostly UI |

Almost every one needs: **login and roles**, **relations between entities**,
**domain actions beyond CRUD** (Prefab's named `@Update` operations),
**responsive web and mobile layouts**, **localisation**, **files**, and
**lists that scale** (filters, server paging).

## Reference applications

Two client apps are built in parallel and drive the priorities. Each
milestone is judged by whether it brings one of them closer to production.

| | Energy balancing | Self-study |
|---|---|---|
| The backend | Talks to home energy meters, batteries and car chargers, and balances energy | Generates summaries and quizzes from a curriculum |
| The frontend is for | Configuration (CRUD-heavy) and insight into what is happening (live data) | Guiding the learner through the material at their own pace (flow-heavy) |
| Generated (the 80%) | Device, site, tariff and schedule configuration; lists and filters | Curriculum and content administration; progress overview |
| Hand-written (the 20%) | Live energy-flow visualisation | Study sessions and quizzes; spaced repetition |
| Specific needs | Relations (device → site); quantities with units (kW, kWh, %); time-range schedules; domain actions (start/stop charging); live updates; time-series charts; read-only entities (measurements) | Rich text and markdown display; long-running backend jobs (generation status); domain actions (submit an answer); progress charts; file upload (curriculum); mobile-first card layouts |
| Shared needs | Login, per-household or per-learner data (tenancy), phone and web layouts | |

Both apps have a central hand-written screen. Hand-written screens must be
able to use the generated providers, API clients and widgets through a
stable, documented API, which is why escape hatches come early in the
roadmap.

## Roadmap

The milestones follow dependencies: the internals first, because they set
development speed; then the escape hatches every real app needs; then the
Prefab integration the reference apps run on. The milestone files in
[`backlog/milestones`](../backlog/milestones) hold the detailed scope; tasks
join a milestone through their `milestone:` field.

| Milestone | Goal |
|---|---|
| **M0: Foundation** | A feature is added by one agent in its own module, with few shared, conflict-prone files and cheap, reliable tests. |
| **M1: Escape hatches and promotion** | No app has to abandon generation because one screen or field is special; generated artifacts can be promoted one at a time. |
| **M2: Prefab and REST backends** | A Prefab backend works with zero configuration, other REST backends with configuration only; live updates and long-running jobs. |
| **M3: Business-app essentials** | Relations, authentication and roles, localisation, more field types, charts and dashboards, a responsive app shell. |
| **M4: Production readiness** | The first reference app goes to production; packages are published to pub.dev. |

After M4, real projects decide the order: offline sync, camera and barcode
scanning, signatures, maps, calendar and board views, export, status
workflows, step-by-step flows (if the self-study app shows a pattern worth
generating) and notifications.

## Decisions

| Decision | Choice |
|---|---|
| Promotion granularity | Per artifact (one screen, provider, client or route), not per entity |
| Publishing to pub.dev | Wait until one of the reference apps is close to production (M4) |
| Reference apps | Energy balancing and self-study, built in parallel |

Architecture decisions are recorded in `backlog/decisions/`; the first is
the generator architecture (PF-37).
