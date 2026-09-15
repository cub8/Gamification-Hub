# UI Redesign Audit

Audit of the Gamification Hub Rails app against the "Card Table" static mockup in
`design/`. **No code was changed to produce this document.**

Sources read directly: `design/HANDOFF.md`, `design/reference/DECISIONS.md`,
`design/reference/SCREENS.md`, and the app's own controllers, views, partials,
helpers and JavaScript.

**Status:** the open decisions in section 6.1 have been settled — see that
section for the outcomes (HAML, Tailwind, one layout, `gh-` namespacing) and
section 9 for which uncertainties they closed.

Repo shape at audit time (branch `feature/rework-views`): 28 controllers,
73 views, 21 partials, 13 Stimulus controllers, 16 helpers. The mockup defines
46 screens — 9 auth (`#/out/`), 14 student (`#/s/`), 23 teacher (`#/t/`).

**Contents**

1. [What the mockup is, in one page](#1-what-the-mockup-is-in-one-page)
2. [Current app inventory](#2-current-app-inventory)
3. [Screen mapping: auth](#3-screen-mapping-auth)
4. [Screen mapping: student](#4-screen-mapping-student)
5. [Screen mapping: teacher](#5-screen-mapping-teacher)
6. [Shared work that must land first](#6-shared-work-that-must-land-first)
7. [The five riskiest items](#7-the-five-riskiest-items)
8. [Recommended conversion order and effort](#8-recommended-conversion-order-and-effort)
9. [Low confidence](#9-low-confidence)

---

## 1. What the mockup is, in one page

The mockup is a single self-contained HTML prototype with a hash router, a
persona switch and fake seed data. It is a **specification of appearance and
behaviour only**. Per `HANDOFF.md`, the following must never be carried into the
app: the hash router and persona switch, `DB` in `05-db.js`, the inline
`data-act` click delegation, the device-frame toolbar, and `window.mock`.

What *is* normative and should be copied literally: the Polish UI copy (error
messages, empty states, destructive-action dialogs), the ARIA attributes, and
the breakpoints (1199 / 1080 / 720 — the mockup expresses them as
`@container app`; plain media queries are fine in the app as long as the
numbers match).

### The design system in four points

| Primitive | What it is | Why it matters for conversion |
| --- | --- | --- |
| **One shape** | Every surface is the same 45° cut-corner octagon via `clip-path: polygon(...)` driven by a `--c` variable. **No `border-radius` anywhere.** | Bootstrap applies `border-radius` to nearly every component. This is a system-wide collision, not a per-screen one. |
| **Physical button edge** | `::before` with a two-stop linear gradient (edge colour for the bottom 3px, fill above); `:active` shifts down 2px. | This is the whole "card table" feel. It cannot be expressed as Tailwind utilities; it belongs in `@layer components`. |
| **Semantic colour roles** | `--item` (orange), `--badge` (teal), `--rank` (gold), `--lock`, `--heart`, `--earn`, `--spend`, each with an `-edge` variant. Light/dark are two token sets on `[data-theme]`. | Roles, not palette names. Theming is `[data-theme]` attribute-driven, **not** Tailwind's `dark:` variant. |
| **Three fonts** | Bricolage Grotesque (UI), Literata (flavour/story text), JetBrains Mono (codes). | Self-hosted woff2 subsets (Latin + Polish) already exist in the bundle. |

Borders on cut-corner surfaces must use a frame layer plus inset background —
`border` and `box-shadow` break at the clipped corners. Any conversion that
reaches for a border has gone wrong.

### Deliberate behaviour changes recorded in DECISIONS.md

These are **not** styling changes. Each one implies controller, model, route or
migration work, and each is flagged against the affected screens in sections 3–5.

| # | Decision | Implication |
| --- | --- | --- |
| D1 | **Soft delete everywhere**, no archiving. Deleted entities are hidden from shop/lists/pickers but kept in history and shown as "Usunięty z oferty". Only deleting a story group cascades. | Replaces the current archive concept. Needs `deleted_at` + scopes on items/badges/ranks/sheets, and every list/picker query revisited. |
| D2 | **"Arkusze ocen"**, not "Grupy aktywności". Also "Szablon arkusza", actions "Utwórz arkusz" / "Oceń". | UI copy only — the models stay `ActivityGroup` / `ActivityGroupTemplate` per `CLAUDE.md`. Do not rename code. |
| D3 | **Nickname required at join** (step 2 of join), per group, editable in "Ustawienia w grupie", unique per group case-insensitively. | New required field + uniqueness validation + a step in the join flow. Students see only nicknames in ranking; teachers see nickname + name. |
| D4 | **Negative currency corrections lower only the spendable balance**, never total collected (which drives rank); cannot go below 0. Only positive corrections raise the total. | Two separate quantities must exist. If the app currently derives balance from a single sum, this is a model change. |
| D5 | Template edits affect only sheets created afterwards; columns with awards can be hidden, not removed. | Versioning/soft-hide semantics on sheet columns. |
| D6 | Discounts: student qualifies on **ANY** condition (rank OR any listed badge); amount = rank discount + **sum** of held listed badge discounts. | Pricing rule; verify against current implementation. |
| D7 | Ranking: enabling requires confirmation; modes "Podium i własne miejsce" (default for new groups) and "Pełny ranking" (confirm when switching to full). Ties share place. | Per-group setting + confirmation dialogs. |
| D8 | Leaving a group is possible and **rejoining restores old data** (currency, badges, items). The leave dialog must say so. | Soft membership, not destroy. |
| D9 | Invites: 6-char codes excluding O, 0, I, 1, L. Limit and expiry each optional via explicit switches. Edit keeps the code; limit must be ≥ uses. | Code generator alphabet + validation. |
| D10 | Supporting teachers may do everything except delete the group. Owner shown separately, cannot be removed. | Authorisation change; contradicts mockup text "Tylko właściciel zmienia te ustawienia", which is out of date. |
| D11 | Wizard success screen must **not** show the join code. | Remove from the success step. |
| D12 | Account settings are **read-only** user data (name, e-mail, university, index, USOS ID) plus theme and logout. | Not an edit form. |

`DECISIONS.md` also lists parts of the mockup that are themselves out of date —
archive buttons, "Grupy aktywności" labels, the wizard showing the join code, the
student-detail negative correction, the group-settings owner-only text, the
missing student sidebar entries, and the join modal lacking the nickname step.
**Build to the decisions, not to those mockup screens.**

### Gaps the mockup itself declares

"Więcej" mobile sheet, account settings page, "Wszystkie zakupy w grupie", and a
server-error/offline state were invented during the mockup and may have no
counterpart in the app — they are expected to land in bucket C.

---

## 2. Current app inventory

### 2.0 Four facts that change the plan

These contradict or extend the assumptions in `HANDOFF.md` and `CLAUDE.md`, so
they come first:

1. **Views are HAML, not ERB.** All 73 views, 21 partials and 6 ViewComponent
   templates are `.html.haml`. `HANDOFF.md` talks about
   `app/views/layouts/redesign.html.erb` and the mockup's markup is raw HTML
   strings — every screen conversion includes an HTML→HAML translation step.
   That is a real, repeated cost, and it is the single most underestimated line
   in the existing plan. (Alternative: allow `.html.erb` for redesigned views and
   run the two template languages side by side, which is legal in Rails and
   removes the translation step entirely.)
2. **The `redesign` layout does not exist yet, and neither does Tailwind.**
   `CLAUDE.md` describes "two layouts run side by side" — that is the *target*,
   not the current state. Today there are only `application`, `public` and the
   two mailer layouts. `grep` for "tailwind" across `package.json`, `Gemfile`
   and `config/` returns nothing. Step 1 and 2 of the HANDOFF migration plan are
   both still unstarted.
3. **ViewComponent is already installed (v4.9) and in use** (`app/components`,
   6 components), and the chrome is already componentised. The HANDOFF's "ViewComponents to name them" step has an existing
   home and existing conventions to follow — this is the good news in the audit.
4. **CSS is SCSS via Dart Sass, with Bootstrap imported from source**
   (`@import 'bootstrap/scss/bootstrap'`), not a prebuilt CSS file. Two bundles
   are compiled: `application.css` and `public.css`. Adding a third, Tailwind
   bundle for the redesign layout fits the existing `build:css` script shape.

### 2.1 Controllers and the actions that render HTML

28 controller files (25 concrete controllers + `ApplicationController` +
3 concerns). Layout column: blank = `application` (the default).

| Controller | HTML actions | Layout | Notes |
| --- | --- | --- | --- |
| `RootController` | — (redirect only) | — | `/` → `home` or `login` |
| `HomeController` | `index` | application | dashboard |
| `SessionsController` | `new` | **public** | login screen |
| `Auth::PasswordlessController` | `new` | **public** | magic-link request; `verify`/`create` redirect |
| `Auth::UsosController` | — (redirect only) | — | OAuth callback — **has no views at all**; failures are redirect + flash |
| `JoinController` | `show`, `new` | application | `create` re-renders `new` on failure |
| `StoryGroupsController` | `index`, `show`, `new`, `edit` | application | `show` branches student/teacher |
| `StudentsController` | `index`, `show`, `new`, `edit` | application | `update_lives` re-renders `index` |
| `StudentsProfileController` | `index` | application | student's own profile |
| `StudentsItemsController` | `index`, `show` | application | |
| `StudentsBadgesController` | `new` | application | modal |
| `CurrencyAdjustmentsController` | `new` | application | modal |
| `CurrencyTransactionsController` | `index` | application | currency history |
| `ItemsController` | `index`, `new`, `edit` | application | no `show` |
| `BadgesController` | `index`, `show`, `new`, `edit` | application | |
| `RanksController` | `index`, `show`, `new`, `edit` | application | |
| `ShopController` | `index`, `show` | application | `show` is the buy modal |
| `RankingController` | `show` | application | `change_status` redirects |
| `StoryGroupInvitesController` | `index`, `show`, `new`, `edit` | application | |
| `TeachersController` | `index`, `new` | application | |
| `ActivityGroupsController` | `index`, `edit` | application | `create_bulk`, `destroy` redirect |
| `ActivityGroupTemplatesController` | `index`, `new`, `edit` | application | **`show` renders JSON**, not HTML |
| `StudentsActivityGroupCategoriesController` | `edit` | application | the grading screen |
| `NotificationsController` | `index` | application | `mark_as_read` → turbo_stream |

Non-HTML actions worth noting: `ActivityGroupTemplates#show` (JSON, consumed by
the template picker), `Notifications#mark_as_read` (turbo_stream removing
`#notification-dot`), and `ApplicationController#redirect_outside_turbo_frame`
(a custom `turbo_stream.action(:redirect, …)` used to break out of the modal
frame — the redesign's dialog replacement must preserve this).

### 2.2 Layouts

| Layout | Bundle | Chrome |
| --- | --- | --- |
| `application.html.haml` | `application.css` | `Shared::HeaderComponent`, two `Shared::MainSidebarComponent` renders (full + collapsed, toggled by the `desktop-sidebar` Stimulus controller via `d-none`), `MessagesComponent`, `#app-content`, and a bare `turbo_frame_tag 'modal'` |
| `public.html.haml` | `public.css` | centred `.public-panel`, logo, an inline `.alert-success` with a Bootstrap `btn-close`, no nav |
| `mailer.html.haml` / `mailer.text.haml` | — | out of redesign scope |

Both HTML layouts hardcode Bootstrap utilities on `<body>`
(`vh-100 d-flex flex-column overflow-hidden`) and both pull the Google Fonts
Lato stylesheet via `@import url(...)` in SCSS. The mockup replaces Lato with
Bricolage Grotesque / Literata / JetBrains Mono, self-hosted.

**There is no mobile navigation of any kind** — no bottom tab bar, no
off-canvas, no "Więcej" sheet. The sidebar is desktop-only with a
collapse toggle. The mockup's mobile tab bar and "Więcej" sheet are net-new.

### 2.3 Global chrome and shared UI

| Concern | Implementation | Redesign impact |
| --- | --- | --- |
| Header | `Shared::HeaderComponent` + `_header.scss` | Full rebuild; hosts the notification dropdown and user dropdown |
| Sidebar | `Shared::MainSidebarComponent` + `Shared::SidebarButtonComponent` + `_sidebar.scss` | Full rebuild. **Nav labels live in Ruby**, not views — `primary_buttons` / `story_group_buttons` return hashes with `text:`/`icon:`/`path:`. The "Grupy aktywności" → "Arkusze ocen" rename (D2) is a one-line change here. |
| Flash | `MessagesComponent` | Bootstrap `.alert` + `btn-close` with `data-bs-dismiss` |
| Modals | **Two separate mechanisms** (see 2.5) | The main structural risk |
| Pagination | **None found** — no kaminari, no pagy, no custom paginator | Lists render full collections. If any list is expected to grow, pagination is net-new work the mockup does not specify. |
| Form builder | **None** — plain `form_with` + hand-written Bootstrap classes | No abstraction layer to swap. **17 files hand-type `form-control` / `form-select` / `btn` on every field.** This is the highest-volume manual work in the whole conversion; a redesign FormBuilder or field component would pay for itself across the mockup's 5 form screens. Nested category fields use the `rondo_form` gem. |
| Icons | Font Awesome 7 **and** Bootstrap Icons, both bundled | The mockup has its own icon set ("real icon set later" is still open per DECISIONS) |
| Authorization | Pundit (`authorize` calls + `story_group_*_authorization` concerns) | Unaffected by styling, but D10 (supporting teachers) is a policy change |

### 2.4 Helpers

16 helper files, but **9 are completely empty** (`badges_helper`, `home_helper`,
`ranks_helper`, `root_helper`, `sessions_helper`, `story_groups_helper`,
`students_badges_helper`, `students_profile_helper`, plus `application_helper`
holds only a string builder). Helpers are *not* a significant Bootstrap-coupling
hotspot here. The three that emit markup:

| Helper | Method | Concern |
| --- | --- | --- |
| `CurrencyTransactionsHelper` | `transaction_kind_badge` | `content_tag(:span, …, class: "badge bg-primary\|bg-info\|bg-secondary")` — **the only hardcoded Bootstrap colour classes in a helper.** Maps directly onto the mockup's semantic roles (`--earn` / `--spend` / gold), so this is a clean rewrite. |
| `StudentsItemsHelper` | `go_back_from_show_link`, `close_show_link` | Both emit `class: 'btn btn-secondary'` and both encode modal-vs-page navigation logic in `data: { turbo_frame: … }`. Coupled to the turbo-frame modal pattern, so they change when modals change. |
| `StoryGroupInvitesHelper` | `invite_qr_code` | Generates a base64 PNG QR via RQRCode. Framework-neutral — keep as is. |

Pure data helpers with no markup: `student_map`, `teacher_map` (TomSelect
option payloads), `invite_uses_label`, `exp_time_label`, `discount_label`,
`user_in_group`, `transaction_description`.

### 2.5 Partials and components

21 partials, all HAML. There is no `app/views/shared/` directory and there are
no mailer partials. Fan-in is strikingly low: **18 of the 21 are single-use**
form bodies or role-branch bodies. The shared-component role is played by
ViewComponents instead, which is the better outcome for the redesign — any
"build the shared components first" plan must target `app/components/`, not the
partials.

**Partials with 3+ render sites — there is exactly one:**

- `notifications/_notification` — rendered at `notifications/index:10` (unread
  collection), `notifications/index:15` (read collection), **and from
  `app/models/notification.rb` via `broadcast_prepend_to` / `broadcast_update_to`**,
  which live-push it into the header dropdown (`turbo_stream_from` in
  `HeaderComponent`). Restyling this partial therefore touches a **model**, not
  just views — the broadcast renders the same partial server-side.

Components, by contrast, do have real fan-in: `MessagesComponent` 4 sites,
`ActivityGroup::CategoryFormComponent` 4 sites, `Shared::SidebarButtonComponent`
3 sites.

| Partial | Rendered by | Notes |
| --- | --- | --- |
| `items/_form` | `items/new`, `items/edit` | 2 |
| `badges/_form` | `badges/new`, `badges/edit` | 2 |
| `ranks/_form` | `ranks/new`, `ranks/edit` | 2 |
| `story_groups/_form` | `story_groups/new`, `story_groups/edit` | 2, takes `cancel_path` + `submit_label` |
| `story_group_invites/_form` | `invites/new`, `invites/edit` | 2, takes `url` |
| `activity_groups/_form` | `activity_groups/edit` | 1 |
| `activity_group_templates/_form` | `templates/new`, `templates/edit` | 2 |
| `activity_groups/_category_form` | via `ActivityGroup::CategoryFormComponent` | wrapper |
| `activity_group_templates/_category_form` | via same component | wrapper |
| `activity_groups/_name_modal` | `activity_groups/index` | Bootstrap modal |
| `activity_groups/_bulk_create_modal` | `activity_groups/index` | Bootstrap modal |
| `activity_groups/_confirm_delete_modal` | `activity_groups/index` (×2 call sites) | Bootstrap modal |
| `story_groups/_student_show` | `story_groups/show` | role branch |
| `story_groups/_teacher_show` | `story_groups/show` | role branch |
| `shop/_item` | `shop/index` (×2: eligible + locked) | collection render, `locked:` local |
| `notifications/_notification` | `notifications/index` (×2: unread + read) | collection render |
| `students/_badges` | `students/show` | |
| `students_items/_index` | `students_items/index` (×2 branches) | |
| `badges/_badge` | — | **no render site found** |
| `ranks/_rank` | — | **no render site found** |
| `story_groups/_story_group` | — | **no render site found** |

**Three partials are dead** — `badges/_badge`, `ranks/_rank` and
`story_groups/_story_group` have zero render sites after checking collection
renders, model broadcasts, `link_to_add_association` and JS. All three are Rails
scaffold residue (unstyled `%p %strong` dumps; `_story_group` still carries
English labels). **Delete them rather than convert them.**

Two render sites that a plain `grep render` misses, and which must not be
overlooked when converting: both `_category_form` partials are reached via
`link_to_add_association … partial:` from their respective `_form` (the
`rondo_form` nested-form gem), and `_notification` via the model broadcast above.

**Duplicate pairs worth consolidating during conversion:**
`activity_groups/_form` ↔ `activity_group_templates/_form`, and their two
`_category_form` adapters — near-identical structures maintained twice.

**Heaviest Bootstrap class coupling** (raw marker counts):
`story_groups/_teacher_show` 44, `story_groups/_student_show` 42,
`shop/_item` 17. Those three are the densest per-file rewrites among partials.

**Natural component primitives suggested by the duplication:**
`EntityCard` — `shop/_item` and `students_items/_index` repeat the same
`.dark-card.flex-row` skeleton verbatim, and it maps straight onto the mockup's
item/badge/rank/sealed colour roles; `ConfirmDialog` — `_confirm_delete_modal`
is already fully parameterised and is exactly the soft-delete (D1) surface;
a `Modal`/`Sheet` shell — the three `activity_groups` modals repeat one
skeleton; and `PriceChip`. Second tier: `FormPage` (all six `_form` partials
share one structure), `ImageField`, `EmptyState`.

**Stale copy found in partials:** `_name_modal` says "Nowa grupa aktywności"
(D2 renames this to "Arkusze ocen" / "Utwórz arkusz"), and
`story_groups/_form` is passed **English** `submit_label` values ("Create" /
"Save") from its two call sites — a UI-language bug independent of the redesign.
`students/_badges` renders a `%table` where the mockup wants badge cards: an
information-architecture change, not a restyle.

ViewComponents (6): `Shared::HeaderComponent`, `Shared::MainSidebarComponent`,
`Shared::SidebarButtonComponent`, `Shared::UserDropdownComponent`,
`MessagesComponent`, `ActivityGroup::CategoryFormComponent`. The first four plus
`MessagesComponent` are exactly the chrome the mockup redraws.

### 2.6 JavaScript

**12** Stimulus controllers, written in **TypeScript**, bundled by esbuild with
`@controllers` / `@utils` path aliases. (The 14 files in
`app/javascript/controllers/` include `application.ts` and `index.ts`, which are
infrastructure, not controllers — the "13 controllers" figure in the brief is
off by one.) There is no auto-registration: each file self-registers and
`controllers/index.ts` imports all 12, so adding a redesign controller means
editing that index.

| Controller | Purpose | Bootstrap-dependent? |
| --- | --- | --- |
| `desktop-sidebar` | toggles full/collapsed sidebar by adding `d-none` | Yes — uses the `d-none` utility class |
| `notifications` | fetches/marks notifications, drives the header dropdown | Yes — lives inside a `data-bs-toggle="dropdown"` |
| `collapse-memory` | remembers open/closed state of collapsible sections | Yes — wraps Bootstrap Collapse |
| `table-search` | client-side row filter | No |
| `column-select` | column picker in grading | No |
| `badge-selector` | badge picking UI | No |
| `nested-rondo` | nested dynamic form fields | No |
| `sortable-form` | drag-reorder via SortableJS | No |
| `file-upload` | file input preview (5 view usages) | No |
| `flatpickr` | date picker via stimulus-flatpickr | No |
| `tom-select-basic` | select enhancement (4 usages) | No — but ships Bootstrap 5 theme CSS |
| `tom-select-user` | user search select (2 usages) | Same |
| `application` / `index` | Stimulus bootstrapping | — |

**Bootstrap JS — the replacement list.** Bootstrap's JS is imported wholesale
(`import "bootstrap"` in `application.ts`) plus an explicit
`import { Tooltip } from "bootstrap"` in `utils/bootstrap_setup.ts`. Actual
behavioural usage is modest and concentrated:

> **Grep warning:** `rg 'data-bs-'` returns only **one** hit and is badly
> misleading. The views are HAML, so the attributes are written
> `data: { bs_toggle: …, bs_target: …, bs_dismiss: … }`. Search for `bs_` , not
> `data-bs-`.

| Component | Occurrences | Where | Replacement |
| --- | --- | --- | --- |
| Dropdown | 6 | header (bell + avatar), `story_groups/_teacher_show`, `students/index`, `activity_groups/index` ×2 | Stimulus + popover or `<details>`. Two need `auto_close: 'outside'` and two need Popper `strategy: 'fixed'` — and the `notifications` controller listens for the dropdown's **show event**, so either keep that event contract or rewrite it alongside. |
| Modal | 4 triggers / 3 dialogs | `activity_groups/index` and its three `_*_modal` partials only | native `<dialog>` + Stimulus — confined to one screen |
| Collapse | 2 | `activity_groups/index`, `activity_group/category_form_component` | rewrite together with `collapse-memory`, which wraps it |
| Alert dismiss | 3 | `MessagesComponent`, `layouts/public` | trivial Stimulus |
| Tooltip | 1 (applies to every collapsed sidebar button) | `SidebarButtonComponent#tooltip_attributes`; `bootstrap_setup.ts` scans `[data-bs-toggle="tooltip"]` once at load | Stimulus or CSS. **Note it is already broken after Turbo navigation** — the scan never re-runs — so this is a bug fix, not just a port. |

No offcanvas, tabs, toasts, carousel, scrollspy or popovers. `@popperjs/core` is
a dependency only because Bootstrap's dropdowns and tooltips need it — both go
away together, and Popper can be dropped or re-adopted deliberately.

#### The modal pattern is the single biggest structural finding

**27 views open a `turbo_frame_tag 'modal'` and 27 wrap their content in a
custom `.modal-overlay`** (plus the layout's frame host). Nearly every create,
edit, show and quick-action screen in the app is a modal: students, items,
badges, ranks, invites, teachers, story groups, sheet templates, currency
adjustments, currency history, student items, shop buy, join.

`DECISIONS.md` states: *"Forms: pages (not modals) for create/edit; modals/sheets
for quick actions."* So the redesign does not merely restyle these — it
**moves most of them out of the modal frame and onto full pages**, which is
controller, routing and navigation work that no amount of grepping for Bootstrap
classes would reveal. This affects far more screens than the Bootstrap-JS list
above and is the main reason the "markup only" bucket in sections 3–5 is small.

**Two modal mechanisms coexist**, and this matters more than the class names:

- **Turbo-frame modals** — the layout ends with `turbo_frame_tag 'modal'`; 27
  views open one and 14 files link into it with `data: { turbo_frame: 'modal' }`.
  These are server-rendered; escaping them uses the custom
  `redirect_outside_turbo_frame` turbo_stream action.
- **Bootstrap modals** — the three `activity_groups` partials, client-side.

The redesign has to land native `<dialog>` for both, and the turbo-frame variant
is the harder one because the dialog element must open in response to frame
content arriving.

Third-party UI dependencies that survive or need decisions: SortableJS (keep),
flatpickr (keep; needs restyling — it ships its own CSS), TomSelect (keep;
**currently themed `tom-select.bootstrap5`, so its theme import must be
replaced**), Font Awesome + Bootstrap Icons (both replaced by the mockup's icon
set, still open per DECISIONS), Lato via Google Fonts CDN (replaced by three
self-hosted faces).

No inline `<script>` tags, no jQuery, no chart library — all behaviour already
lives in bundled TypeScript, which is a good starting position.

**Bundle sizes today:** `application.js` ~798 KB; `application.css` ~1.7 MB and
`public.css` ~1.2 MB, both of which `@import` the whole of Bootstrap from source.
Dropping Bootstrap is a large CSS win.

**Stack contradiction to resolve before starting:** `HANDOFF.md` assumes ERB and
a Node-based Tailwind; `DECISIONS.md` recommends Tailwind v4 via
`tailwindcss-rails` with **no Node**. The repo already has Node and esbuild, and
the views are HAML. Someone has to pick — see section 6.

### 2.7 Route map

Everything group-scoped nests under `resources :story_groups`:

```
/story_groups                                    index, new, edit, show
  /ranking                        (+ POST change_status)
  /items                          except show
  /activity_group_templates       full CRUD
  /activity_groups                except show, new  (+ POST create_bulk)
    /students_activity_group_categories   edit, update   ← the grading screen
  /ranks, /badges                 full CRUD
  /teachers                       new index create destroy
  /students                       full CRUD (+ POST update_lives)
    /currency_adjustment          new create
    /badges  (students_badges)    new create destroy
    /currency_transactions        index
    /items   (students_items)     index show
  /shop                           index show (+ POST buy)
  /profile (students_profile)     index
  /invites (story_group_invites)  full CRUD
/join/:code                       show new (+ POST create)
/notifications                    index (+ POST mark_as_read)
/auth/:provider/callback, /auth/passwordless(/verify)
/login, /logout, /home, /  (root)
```

Note there is **no route for a wizard** (group creation is a single
`story_groups/new` form), **no account-settings route**, **no group-level
purchases route**, and **no error-page route**.

### 2.8 DECISIONS.md items checked against the code

| # | Decision | Current state |
| --- | --- | --- |
| D1 | Soft delete everywhere | **Not implemented.** No `deleted_at` column on any table, no `discard`/`acts_as_paranoid` gem, and no "archive" concept either — every `destroy` is a hard delete. This is a migration + scope change across items, badges, ranks, sheets and memberships. |
| D2 | "Arkusze ocen" | Not applied. Sidebar still says "Grupy aktywności" (`main_sidebar_component.rb`). |
| D3 | Nickname required at join | **Not implemented.** No `nickname` column anywhere; the join flow is a single step. |
| D4 | Negative corrections don't lower total | **Already correct.** `story_group_students` has separate `current_currency` and `total_currency` columns, and `CurrencyAdjusterService` increments `total_currency` only `if amount.positive?`. However **the "cannot go below 0" clamp is missing** — `increment!(:current_currency, amount)` is unguarded, so a large negative correction drives the spendable balance negative. That is a live bug against D4, independent of the redesign. |
| D6 | Discount = rank OR any badge, amounts summed | `DiscountCalculatorService` exists and computes `meets_rank` against `total_currency`; needs a read against the D6 wording (not verified in depth). |
| D7 | Ranking modes | Only a boolean `ranking_enabled` + `change_status`. The two modes ("Podium i własne miejsce" / "Pełny ranking") do not exist. |
| D8 | Leaving restores data on rejoin | No leave action exists at all; membership `has_many … dependent: :destroy` would hard-delete on removal. |
| D9 | Invite codes excluding O/0/I/1/L | Not verified — see Low confidence. |
| D12 | Account settings read-only | No account screen exists. |


---

## 3. Screen mapping: auth (9 mockup screens)

**Buckets: A = 2, B = 3, C = 7.**

This is the emptiest part of the app relative to the mockup. `HANDOFF.md` frames
auth as the cheap warm-up tier ("9 auth screens are one pattern… proves tokens
and buttons"). That is **half right**: the nine screens genuinely share one
shell, and the two that exist are cheap — but the other seven are *new features*,
several security-relevant, not restyling. Auth is still the right place to start
for the design system; it is the wrong place to expect a small total.

### Bucket A — exists here and in the mockup

| Mockup | Ours | View | Effort | Driver |
| --- | --- | --- | --- | --- |
| `#/out/login` | `SessionsController#new` (layout `public`) | `sessions/new.html.haml` | **M** | markup + route |
| `#/out/login-mail` | `Auth::PasswordlessController#new` (layout `public`) | `auth/passwordless/new.html.haml` | **M** | markup + controller/Stimulus |

**`#/out/login` — M.** The markup is small (two buttons, an "albo" divider, a
footer link), but this is the screen that must first stand up the whole redesign
shell — public layout, tokens, the octagon panel surface, the button edge, the
brand block, the footer theme toggle. IA differences beyond styling: the mockup
adds a `.who` audience descriptor under each method ("Studenci i nauczyciele
uczelni" / "Uczniowie szkół i osoby dodane przez administratora"), which is
D-rule "USOS login == USOS registration" made visible; the heading becomes
"Zaloguj się" + a lead paragraph instead of "Witaj w Gamification Hub!"; and the
provider path is currently hardcoded as `'/auth/uam_usos'` in the view.

**`#/out/login-mail` — M.** One email field and a submit would be S alone. It is
M because the mockup's submit **navigates to a dedicated `inbox` screen** rather
than our `redirect_to new_auth_passwordless_path` + flash, so the controller's
`create` response changes; and because the mockup moves the back-navigation to a
top "Inne sposoby logowania" link instead of our bottom "Cofnij" button.

### Bucket B — exists here, no mockup screen

| Ours | Note |
| --- | --- |
| `passwordless_mailer/token_email` (`.html` + `.text`) | The magic-link e-mail. The mockup never shows an e-mail. Currently near-unstyled. Restyling is worthwhile but out of mockup scope — and mailer HTML cannot rely on `clip-path`/token CSS across mail clients, so it needs its own simplified treatment. |
| `SessionsController#destroy` (`/logout`) | Redirect only; appears in the mockup as an avatar-menu item, not a screen. |
| `BypassLoginService` dev login bypass | Not in the mockup — see the flag below. |

`layouts/public.html.haml` is bucket B in spirit: the mockup's auth shell
replaces it wholesale rather than mapping onto it.

### Bucket C — mockup screen with no counterpart here (7)

| Mockup | Screen | Effort | What must be built |
| --- | --- | --- | --- |
| `#/out/inbox` | Sprawdź skrzynkę | **M** | Route + action + view. The submitted e-mail must survive to the screen (session or signed param). Resend posting back to `passwordless#create`, a 60 s cooldown (server throttle **and** a Stimulus countdown), and a "Zmień adres e-mail" link. |
| `#/out/link` | Magic-link landing | **L** | **Security-relevant — see B1.** Split `verify` into a side-effect-free GET that renders, plus a POST that consumes. Dual copy variant (login vs finish-registration). |
| `#/out/link-expired` | Link wygasł | **S** | Route + view + the failure branch of `verify` rendering it instead of a flash redirect. Static copy, two buttons. |
| `#/out/register` | Rejestracja | **M** | Route + controller + view mirroring `login`. **No registration controller exists at all.** |
| `#/out/register-mail` | Rejestracja e-mailem | **L** | Largest auth item. Form: invite code, first name, last name, e-mail, terms checkbox. The code field has a **live preview** resolving the code to a group + organisation with a thumbnail — an async validation endpoint plus Stimulus, not markup. Creating a user *from* an invite does not exist: `AcceptInviteService` requires an already-authenticated `user`. |
| `#/out/usos` | Przekierowanie do USOS | **S** | Route + view. Pure interstitial (spinner, copy, manual-open fallback). Only meaningful if the redirect is routed through the app. |
| `#/out/usos-error` | Błąd USOS | **M** | Route + view with two variants — user cancelled/refused consent vs USOS unavailable. Today `InvalidProviderError` and `Providers::InvalidAuthError` both collapse to `redirect_to root_path` with one generic flash, so the error taxonomy must widen. |

### Behaviour changes — not styling

| # | Change | Current state | Impact |
| --- | --- | --- | --- |
| B1 | **Anti-scanner landing page**: token consumed only on an explicit button press | `passwordless#verify` (GET) consumes the token and logs in in one request | Controller split; the GET must become side-effect-free. The current design lets a mail scanner's link prefetch burn the token — this is a real bug the redesign fixes. |
| B2 | **Token TTL 15 minutes** (DECISIONS + mockup copy "Link działa przez 15 minut") | **`LoginToken#generate_token!` sets `expires_at = 5.minutes.from_now`** | **Direct contradiction — verified in code.** Either the model goes to 15 minutes or the mockup copy changes. A decision, not an assumption. |
| B3 | **60 s resend cooldown** | Nothing — `create` can be POSTed repeatedly, each call destroying the old token and mailing a new one | Needs a server-side throttle *and* the Stimulus countdown. Without the server half the timer is decoration. |
| B4 | **E-mail registration for school students** | No registration path exists; users come from `SessionUserBuilder` (USOS) or an admin | New controller, view, and a create-user-from-invite service. Note `User` already declares `validates_presence_of :email, :full_name, on: :account_setup` — an existing validation context no current flow uses, which looks intended for exactly this. |
| B5 | **Terms + privacy acceptance** | No documents, no acceptance column | DECISIONS lists the documents as **open (client)**; links are placeholders. Persisting acceptance (timestamp/version) is a migration. Blocked on client content. |
| B6 | **Pending QR join remembered across login/registration** | Not implemented — `JoinController#create` calls `AcceptInviteService.new(user: @current_user, …)`, so joining requires being logged in; nothing stashes a code for an anonymous visitor | Session/cookie stash, a banner on all four form screens, and consumption in **three** places: magic-link confirm, registration, and USOS return. |
| B7 | **USOS error taxonomy** | Two rescues, both → one generic flash | Widen handling; two copy variants. |
| B8 | **Theme toggle on auth screens** | No theming mechanism anywhere in the app | `[data-theme]` token sets + cookie persistence. **System-level work auth is merely the first consumer of** — it belongs in the shared-primitives stage (section 6), not in an auth screen estimate. |
| B9 | Dead link: `link_to 'Zarejestruj się', ''` in `sessions/new` | Renders an anchor to the current page | A live bug today; fixed once a register route exists. |

### ⚠️ Found during the audit, unrelated to the redesign

`BypassLoginService` (called from `Auth::PasswordlessController#create`) logs a
user straight in, skipping the magic link, when the SHA256 of their e-mail
matches one of **14 hardcoded hashes**. I verified it: **it is not environment-
gated in any way** — no `Rails.env` check in the service or at the call site — and
the recent commit *"Add production seeds. Add more accounts to login bypass"*
indicates it is live in production. The file comments itself as "Temporary
service existing for testing purposes".

**Resolved: this is intentional and accepted.** It exists so the client can test
against production, and is to be left as is. Recorded here only so the next
reader does not re-raise it.

### Cross-cutting

**One shared auth shell covers all nine screens.** The mockup wraps every auth
view in: background tint/pattern layers, `<main class="main">`, an `.auth`
column, a `.brand` block, an optional pending-join banner on the four form
screens, a `<section class="panel acard">` body, and a `.foot` with the theme
toggle and help link. Build that shell once as the redesign public layout and
the nine screens really do become composition — HANDOFF's promise holds for
markup, just not for behaviour.

`28-auth.css` is **24 lines / 16 selectors**; nearly everything else comes from
`00-base.css`, which confirms the system-first ordering. Three of its selectors
are reusable primitives later screens will want: `.stack` (vertical button
group), `.chk` (checkbox row), `.big-ic` (status glyph for empty/error states),
plus `.loader` — the skeleton primitive DECISIONS calls for.

Two screens are **one view with two copy variants** (`link`: login vs register;
`usos-error`: cancelled vs down). Model them as one view with a variant local,
not four views.

**No organization model exists.** `grep` finds only an `organization_admin` role
value on `User`; there is no school/organization table. The register-mail copy
promises the invite code "od razu dodaje Cię do właściwej szkoły i grupy", which
implies one. Either the copy overstates what the code does (it maps to a story
group only), or an organization concept must be introduced.


---

## 4. Screen mapping: student (14 mockup screens)

**Buckets: A = 8, B = 3, C = 6.** (Totals exceed 14 because two mockup screens
map onto one shared action, and two are dev/skeleton screens rather than routes.)

> Mapped by the orchestrator directly. The delegated student fork died on a
> session rate limit before writing its file, so this section is based on my own
> reading of the views and controllers rather than on that fork's output.

### Bucket A — exists here and in the mockup

| Mockup | Ours | View | Effort | Driver |
| --- | --- | --- | --- | --- |
| `#/s/groups` Moje grupy | `StoryGroupsController#index` | `story_groups/index.html.haml` | **M** | markup only |
| `#/s/home` Grupa: przegląd | `StoryGroupsController#show` | `story_groups/_student_show.html.haml` | **L** | markup + IA |
| `#/s/shop` Sklep | `ShopController#index` | `shop/index.html.haml` + `shop/_item` | **M** | markup + Stimulus |
| (shop buy dialog) | `ShopController#show` / `#buy` | `shop/show.html.haml` | **M** | markup + modal mechanism |
| `#/s/my-items` Moje przedmioty | `StudentsItemsController#index` / `#show` | `students_items/index` + `_index` + `show` | **M** | markup + modal mechanism |
| `#/s/ranks` Rangi | `RanksController#index` / `#show` | `ranks/index`, `ranks/show` | **S** | markup only |
| `#/s/badges` Odznaki | `BadgesController#index` / `#show` | `badges/index`, `badges/show` | **S** | markup only |
| `#/s/history` Historia waluty | `CurrencyTransactionsController#index` | `currency_transactions/index.html.haml` | **M** | markup + soft-delete display |
| `#/s/ranking` Ranking | `RankingController#show` | `ranking/show.html.haml` | **L** | markup + model/controller |

**`#/s/groups` — M.** A card grid already exists, with filter tabs
(Wszystkie / Moje / Uczę się / Nauczam) built as a Bootstrap `.nav`. Straight
restyle to the octagon card, plus the floating "Utwórz grupę" FAB. Markup only.

**`#/s/home` — L, and the driver is IA, not CSS.** `_student_show` (85 lines)
already carries everything the mockup wants — rank, lives, both currency
figures, badges, items — but as one long scrolling column of Bootstrap panels.
The mockup restructures this into the group landing page with section
navigation, and DECISIONS records that **the student sidebar is missing
"Historia waluty" and "Ustawienia w grupie"** — so this screen's conversion is
coupled to the sidebar/nav work, not self-contained. It is also the second
most Bootstrap-dense partial in the app (42 class markers).

**`#/s/shop` — M.** `shop/index` already splits eligible vs locked items with a
"Zablokowane" divider, which matches the mockup's sealed concept. The work is
the item card (orange `--item` role, price chip, sealed treatment) and the
mobile rule that **shop keeps 2-column compact cards** while other card lists go
single-column. `shop/_item` is the third-densest Bootstrap partial (17 markers)
and shares its skeleton with `students_items/_index` — build one `EntityCard`.

**Shop buy dialog — M.** Currently `shop/show` rendered into the layout's
`turbo_frame_tag 'modal'` with a `.modal-overlay`. This is a *quick action*, so
DECISIONS keeps it a dialog — but it must become a native `<dialog>` opened by
frame content arriving. That mechanism is shared with every other modal
(section 6) and should not be re-solved here.

**`#/s/my-items` — M.** Same `EntityCard` as shop. Note `students_items/index`
already branches on `turbo_frame_request_id == 'modal'` to render either a modal
or a full page — a pattern worth preserving, and a hint that the page/modal
split the redesign wants is partially anticipated.

**`#/s/ranks` / `#/s/badges` — S each.** Read-only lists with a detail modal;
the detail is a quick action so it stays a dialog. These are the cheapest real
screens in the app and are the right first test of the card primitives after
auth. Note both actions are **shared with the teacher role** (same controller,
`authorize_story_group_read!`), so converting them flips the screen for both
personas at once — see the risk in section 7.

**`#/s/history` — M.** A transaction list exists. The redesign adds the `--earn`
/ `--spend` semantic colouring (today `transaction_kind_badge` hardcodes
`bg-primary` / `bg-info` / `bg-secondary`) and must render soft-deleted items as
**"Usunięty z oferty"** rather than dropping them — which depends on D1 landing
first.

**`#/s/ranking` — L, behaviour change.** Today ranking is a single boolean
(`story_group.ranking_enabled`) and `ranking/show` lists every student ordered by
`total_currency`, showing **full names**. DECISIONS requires: two modes
("Podium i własne miejsce" as the default for new groups, "Pełny ranking"),
**students see nicknames only**, ties share place, and enabling or switching to
full ranking each require confirmation. That is a migration (mode column +
nickname), a query change (tie handling), and two confirm dialogs — none of it
visible in the markup.

### Bucket B — exists here, no mockup screen

| Ours | Note |
| --- | --- |
| `StudentsProfileController#index` (`/profile`) | "Mój profil" — 21 lines of bare `%h1`/`%h3` with plain links, no styling at all. The mockup has no counterpart because its content is split between the group overview and account settings. **Recommend deleting rather than converting**; confirm nothing links to it. |
| `JoinController#show` (`/join/:code`) | The QR/code landing for an invite. The mockup's join flow is a modal with a nickname step, not a standalone screen, so there is no SCREENS.md row — but the screen must survive because QR codes point at it. |
| `JoinController#new` + `#create` | The "enter a code" form, currently a modal. Must gain the **required nickname step** (D3). |

### Bucket C — mockup screen with no counterpart here

| Mockup | Screen | Effort | What must be built |
| --- | --- | --- | --- |
| `#/s/start` | Start studenta | **L** | A real student landing page. `HomeController#index` exists but renders only "Witaj, {name}" plus a read-only profile card — it is a stub, not a dashboard. Needs a query layer (the student's groups, recent currency, pending items) and a view. `StoryGroupStudentDashboard` exists but is scoped to one group and used by `story_groups#show`. |
| `#/s/group-settings` | Ustawienia w grupie | **L** | Route + controller + view. Contents per DECISIONS: **edit nickname** (new column, unique per group case-insensitive) and **leave the group**, with a dialog stating that rejoining restores currency, badges and items. Leaving does not exist at all today, and memberships are `dependent: :destroy`, so "rejoining restores data" is **impossible without making membership soft** — this is the deepest model change in the student slice. |
| `#/s/account` | Ustawienia konta | **S–M** | Route + controller + view — but **the content already exists**: `home/index` renders exactly the read-only fields D12 asks for (e-mail, university, index number, USOS ID). This is largely a move plus the theme toggle and logout. Cheap, and it frees `home#index` to become the real dashboard. |
| `#/s/error` | Błąd serwera / offline | **S** | A styled 500/offline page. Rails' default `public/500.html` is static and outside the asset pipeline, so it cannot use the token CSS unless inlined. |
| `#/s/loading` | Ładowanie (szkielety) | **S** | Not a route — a **skeleton component set**. DECISIONS requires skeletons with identical dimensions to the content (no layout shift). Build as part of the primitives (section 6), not as a screen. |
| `#/s/states` | Galeria stanów (dev) | **skip** | A development gallery of empty/error/loading states. No route needed. Optionally reproduce as a Lookbook/preview page if ViewComponent previews are adopted. |

### Behaviour changes landing on the student slice

| Change | Screens affected | Note |
| --- | --- | --- |
| **Nicknames (D3)** | join, group-settings, ranking, teacher student list | No `nickname` column exists. Required at join, unique per group case-insensitively, students see only nicknames in ranking, teacher sees nickname + name. Migration + validation + backfill for existing memberships. |
| **Soft delete (D1)** | history, my-items, shop | Deleted items must still appear in history as "Usunięty z oferty". No `deleted_at` exists anywhere. |
| **Leave / rejoin restores data (D8)** | group-settings | Requires soft membership; today's `dependent: :destroy` makes it impossible. |
| **Ranking modes (D7)** | ranking | Two modes + confirmations + shared places for ties. |
| **Read-only account (D12)** | account | Display only — not an edit form. |
| **Lives as heart + number** | group overview | Already rendered as an icon + number, not one heart per life — compliant today. |
| **Mobile tab bar + "Więcej" sheet** | all | Net-new; no mobile navigation exists. Shared work, section 6. |


---

## 5. Screen mapping: teacher (23 mockup screens)

**Buckets: A = 15, B = 4, C = 6.**

> Mapped by the orchestrator directly — both delegated teacher forks died on a
> session rate limit before writing their files.

### Bucket A — exists here and in the mockup

| Mockup | Ours | View | Effort | Driver |
| --- | --- | --- | --- | --- |
| `#/t/groups` Wszystkie grupy | `StoryGroupsController#index` | `story_groups/index` | **M** | markup only (shared with `#/s/groups`) |
| `#/t/home` Grupa: przegląd | `StoryGroupsController#show` | `story_groups/_teacher_show` | **L** | markup + IA |
| `#/t/students` Studenci | `StudentsController#index` | `students/index` | **L** | markup + Stimulus + IA |
| `#/t/student` Student: szczegóły | `StudentsController#show` | `students/show` | **L** | markup + modal→page + behaviour |
| `#/t/sheets` Arkusze ocen | `ActivityGroupsController#index` | `activity_groups/index` | **L** | markup + Bootstrap JS + naming + soft delete |
| `#/t/sheet-template-new` Nowy szablon | `ActivityGroupTemplatesController#new` | `activity_group_templates/new` + `_form` | **M** | markup + modal→page |
| `#/t/sheet-template-edit` Edycja szablonu | `ActivityGroupTemplatesController#edit` | `activity_group_templates/edit` + `_form` | **L** | markup + versioning behaviour |
| `#/t/sheet-settings` Ustawienia arkusza | `ActivityGroupsController#edit` | `activity_groups/edit` + `_form` | **M** | markup + hidden-not-removed columns |
| `#/t/grade` Ocenianie | `StudentsActivityGroupCategoriesController#edit` | `students_activity_group_categories/edit` | **L** | markup + behaviour + Stimulus |
| `#/t/items` Przedmioty | `ItemsController#index` | `items/index` | **M** | markup + soft delete |
| `#/t/item-new` Nowy przedmiot | `ItemsController#new` | `items/new` + `_form` | **L** | markup + modal→page + uploads |
| `#/t/item-edit` Edycja przedmiotu | `ItemsController#edit` | `items/edit` + `_form` | **L** | same form, same drivers |
| `#/t/ranks` Rangi | `RanksController#index` | `ranks/index` | **S** | markup only |
| `#/t/badges` Odznaki | `BadgesController#index` | `badges/index` | **S** | markup only |
| `#/t/invites` Zaproszenia | `StoryGroupInvitesController#index` | `story_group_invites/index` | **M** | markup + invite rules |
| `#/t/teachers` Nauczyciele | `TeachersController#index` | `teachers/index` | **M** | markup + IA + permissions |
| `#/t/ranking` Ranking | `RankingController#show` | `ranking/show` | **L** | shared with `#/s/ranking` |
| `#/t/group-settings` Ustawienia grupy | `StoryGroupsController#edit` | `story_groups/edit` + `_form` | **M** | markup + modal→page + permissions |

**`#/t/home` — L.** `_teacher_show` is the **single most Bootstrap-dense file in
the app** (103 lines, 44 class markers) and includes a Bootstrap dropdown. It is
fed by `StoryGroupTeacherDashboard` (recent transactions, recent sheets, per-sheet
top-3 rankings). The per-sheet top-3 widget must start **respecting ranking
visibility and mode** (D7) — today it renders unconditionally.

**`#/t/students` — L.** A dense table: lives stepper, four per-row action
buttons, a Bootstrap dropdown, `stretched-link` cells opening a modal, and an
inline validation-error row injected after the failing student. The redesign
needs the **heart + number stepper at fixed width** (D7 note: never one heart
per life in tables), nickname + name display (D3), and the row actions
reorganised. The `stretched-link` + `position-relative z-2` stacking trick will
not survive a `clip-path` surface unchanged.

**`#/t/student` — L.** Currently a modal (`students/show`, 59 lines) hosting
badges (as a `%table`, where the mockup wants **cards** — an IA change), currency
figures, and links to adjustments and history. DECISIONS also fixes the
out-of-date mockup here: **a negative correction must not lower the total.**

**`#/t/sheets` — L, and it is the Bootstrap-JS epicentre.** `activity_groups/index`
(80 lines) is the only screen using Bootstrap **modals** (all three modal
partials), and it also uses **collapse** (wrapped by the `collapse-memory`
Stimulus controller, with cookie persistence) and **two dropdowns with
`strategy: 'fixed'`**. Converting it means replacing three Bootstrap components
at once. It also carries the stale **"Grupy Aktywności"** title and heading
(D2 → "Arkusze ocen"), and its two delete paths are **hard deletes** that D1
turns into soft deletes.

**`#/t/sheet-template-edit` — L.** D5: template edits must affect **only sheets
created afterwards**. Today `ActivityGroupTemplate` edits have no versioning
concept, so this is a model change, not a form restyle.

**`#/t/sheet-settings` — M.** D5's other half: columns that already have awards
can be **hidden, not removed**. Today `_form` + `rondo_form` nested fields allow
outright removal. Needs a `hidden` flag and a guard.

**`#/t/grade` — L, the hardest screen in the app.** Current state: a sticky-column
table (`.sticky-col` + `.table-scroll-area` already exist — genuinely useful
groundwork), a `table-search` Stimulus filter, a `column-select` tick-whole-column
control, and checkboxes that are `disabled` once completed. That is **two** cell
states (empty, awarded+locked). DECISIONS requires **three** — empty, *marked
now*, awarded+locked — plus a **review dialog before the irreversible award**
with focus on the safe button, and a per-sheet top-3 widget respecting ranking
mode. So: a new intermediate state in markup and JS, a confirm-and-diff dialog
listing what is about to be awarded, and the award itself remaining irreversible.

**`#/t/items` / `#/t/item-new` / `#/t/item-edit` — M / L / L.** `items/_form` is
the largest form in the app (82 lines) with **four** TomSelect instances and
file upload. The redesign adds the mockup's upload treatment (fixed frames,
presets + upload + **focal point crop**, min ~400px for art, pixelated ≤256px)
and the currency-icon rules (gold rim + cream token ≥22px, price chips showing
number only). Focal-point cropping does not exist today and is a genuine feature.
D6's discount rule (qualify on ANY condition; amount = rank discount + **sum** of
held badge discounts) needs checking against `DiscountCalculatorService`.

**`#/t/ranks` / `#/t/badges` — S each.** Same lists as the student side, same
cheapness — and the same shared-action caveat.

**`#/t/invites` — M.** `invites/index` (44 lines) plus a `show` modal displaying
the QR (`invite_qr_code`, framework-neutral, keep as is) and a flatpickr expiry
field. D9 adds: a 6-char alphabet **excluding O, 0, I, 1, L**; limit and expiry
each toggled by an **explicit switch** with a summary sentence; edit keeps the
code; limit must be ≥ uses; and the code modal becomes a **dropdown of active
invites** (newest default, inactive hidden, a new invite not auto-shown).

**`#/t/teachers` — M.** Today a plain table with a delete button per row. D10
requires the **owner shown separately and not removable**, supporting teachers
able to do everything except delete the group (a Pundit policy change), and
**search-first adding** (≥2 chars, diacritics-insensitive, max 8 results, per-row
"Dodaj"). `tom_select_user` exists but is a select widget, not the search-first
result list the mockup specifies.

**`#/t/group-settings` — M.** `story_groups/edit` + `_form` (70 lines). Two
corrections land here: the mockup's "Tylko właściciel zmienia te ustawienia"
text is **out of date** (D10 — supporting teachers can too; only delete is
owner-only), and `_form` is currently passed **English** `submit_label` values
("Create" / "Save") from its call sites, which is a live UI-language bug.

### Bucket B — exists here, no mockup screen

| Ours | Note |
| --- | --- |
| `NotificationsController#index` | A full-page notification list. The mockup only ever shows notifications as a header **dropdown** (Nowe / Wcześniej, mark all read). Decide whether the full page survives as a mobile fallback or is dropped. |
| `ActivityGroupTemplatesController#show` | Renders **JSON**, not HTML — the template picker's data source. Not a screen; must keep working. |
| `ActivityGroupsController#create_bulk` | "Stwórz wiele grup" bulk creation, driven by `_bulk_create_modal`. No mockup screen covers bulk creation — **confirm it is still wanted** before dropping the Bootstrap modal it lives in. |
| `StudentsController#new` / `#edit`, `StudentsBadgesController#new`, `CurrencyAdjustmentsController#new` | Quick-action modals with no dedicated mockup row; they appear inside the student detail flow. |

### Bucket C — mockup screen with no counterpart here

| Mockup | Screen | Effort | What must be built |
| --- | --- | --- | --- |
| `#/t/dash` | Start nauczyciela | **L** | A real teacher dashboard. `home#index` is a stub ("Witaj" + read-only profile card). Needs cross-group queries (recent purchases, notifications, groups taught) and a view. |
| `#/t/new-group` | Nowa grupa (kreator) | **XL** | The biggest single bucket-C item. Today group creation is **one form** in a modal (`story_groups/new` + `_form`). The mockup is a multi-step wizard with **Quick setup** — content packs (neutral / fantasy / sci-fi) *scaled by the planned number of classes* — or manual. Needs multi-step routing/state, the seed-pack content itself (ranks, badges, items per theme, which is a content authoring task, not just code), and a success screen that **must not show the join code** (D11). |
| `#/t/purchases` | Wszystkie zakupy w grupie | **M** | Route + controller + view. A group-filtered purchase list. The data exists (`CurrencyTransaction` with `kind: :purchase`); `StoryGroupTeacherDashboard` already queries recent transactions, so this is largely a full, filterable version of that. |
| `#/t/account` | Ustawienia konta | **S–M** | Same screen as `#/s/account` — build once. Content already exists in `home/index`. |
| `#/t/uploads` | Test uploadów (dev) | **skip** | A development stress-test page for the upload frames. Not a product route. Useful to reproduce while building the upload primitives, then discard. |
| (implied) mobile "Więcej" sheet | — | **M** | Listed in DECISIONS as a gap. No mobile nav exists at all. Shared work — section 6. |

### The single most expensive teacher screen

**`#/t/grade` (Ocenianie)** — it is the only screen combining an irreversible
action, a new intermediate UI state, a review dialog, sticky columns with
horizontal scroll, and a ranking-aware widget. `HANDOFF.md` independently reaches
the same conclusion and puts it last in the suggested order. The runner-up is
`#/t/new-group`, which is larger in raw work but carries far less risk because
nothing depends on it and it has no existing behaviour to preserve.


---

## 6. Shared work that must land before any screen converts

`HANDOFF.md` is right that the system comes first. This is that list, ordered,
with what the audit adds to it.

### 6.1 Decisions — settled

These were open when the audit was written. They have since been decided by the
project owner and are recorded here so the rest of the document reads correctly.

| # | Decision | Outcome |
| --- | --- | --- |
| **D-a** | Template language for redesigned views | **HAML.** The project standardises on `.html.haml`; no mixed-templating exception. Every screen conversion therefore includes an HTML→HAML translation step from the mockup's raw markup — a real per-screen cost, accepted deliberately. |
| **D-b** | Tailwind delivery | **Tailwind is being added to the project** as step 1 of the migration, with a new layout and new JS/CSS entry points kept separate from the existing ones. |
| **D-c** | How much Tailwind | **Tailwind for layout, spacing and colour utilities; hand-written CSS for the primitives.** Measured against the mockup's own CSS: of 1004 rule blocks, roughly 85% are ordinary layout/colour/spacing that utilities express directly, and roughly 15% (22 `clip-path`, 85 `::before`/`::after`, 12 gradients, 15 `@container`, 9 `@keyframes`, 78 `--c` corner declarations) need real CSS in `@layer components`. |
| **D-d** | Layout structure | **The `public` / `application` layout split is dropped.** One redesign layout, with the header/sidebar chrome suppressed on auth screens. |
| **D-e** | Naming and namespacing | **Everything the redesign introduces is namespaced.** See below — this replaces the mockup's generic `.app` / `data-theme` / bare token names. |

#### D-e: namespacing rules

The mockup uses `.app` as the token scope, `data-theme` as the theme switch, and
bare custom-property names (`--card`, `--line`, `--ink`, `--focus`). All three
are collision-prone while Bootstrap is still loaded, and generic enough to be
confused with other frameworks' conventions later. Bootstrap itself namespaces to
`data-bs-theme` for exactly this reason. The redesign adopts:

| Mockup | Use instead | Why |
| --- | --- | --- |
| `data-theme="dark"` | **`data-gh-theme="dark"`** | A bare `data-theme` is also used by other CSS frameworks; namespacing removes any chance of two systems reading the same attribute during the migration. |
| `.app` as token scope | **`:root`** (tokens), `.gh-app` only if a scope is genuinely needed | Custom properties do not collide destructively — defining `--gh-card` on `:root` restyles nothing in Bootstrap. Only *class names* collide, so the wrapper is not needed for safety. |
| `--card`, `--item`, `--ink`, … | **`--gh-card`, `--gh-item`, `--gh-ink`, …** | 36 tokens per theme, many with very generic names. Prefixing makes every reference self-identifying. |
| `.btn`, `.card`, `.badge`, `.nav` | **`.gh-btn`, `.gh-card`, …** | These collide with Bootstrap head-on. This is the concrete form of the risk in section 7. |

**Light/dark stays attribute-driven and must NOT become Tailwind's `dark:`
variant.** The design system redefines semantic roles per theme (`--gh-item` is
`#FF7A1A` light, `#FF8A33` dark). Expressing that with `dark:` would mean writing
`bg-item dark:bg-item-dark` at all 828 `var()` call sites. The idiomatic Tailwind
v4 approach is the opposite and is what the mockup already implies: map the theme
onto custom properties once, and let the utilities resolve through them —

```css
@theme { --color-item: var(--gh-item); }          /* bg-item, text-item, … */
:root                      { --gh-item: #FF7A1A; }
:root[data-gh-theme="dark"] { --gh-item: #FF8A33; }
@custom-variant dark (&:where([data-gh-theme="dark"], [data-gh-theme="dark"] *));
```

`bg-item` is then correct in both themes with no variant prefix anywhere, and
`dark:` remains available for the rare case that needs it.

### 6.2 The shared build, in dependency order

1. **Token layer.** `tokens/tokens.css` light/dark sets on `[data-theme]`, the
   semantic roles (`--item`, `--badge`, `--rank`, `--lock`, `--heart`, `--earn`,
   `--spend`, each with `-edge`), the `--c` corner sizes, and the three
   self-hosted font faces replacing the Lato Google-Fonts `@import`.
2. **Theme switching.** No theming mechanism exists anywhere in the app today.
   `[data-theme]` on the root plus cookie persistence, set server-side to avoid
   a flash of the wrong theme. Auth screens and account settings both consume it,
   so it cannot be deferred to "later".
3. **The third CSS bundle + the `redesign` layout.** A new entry point beside
   `application.scss` / `public.scss`, and `app/views/layouts/redesign.*`. If
   Tailwind is used alongside Bootstrap, `corePlugins.preflight = false` and scope
   the mockup's own reset inside `.app`, exactly as `HANDOFF.md` warns.
4. **Primitives** (`@layer components` or plain CSS): the octagon `clip-path`
   surface, the button edge treatment, panels, cards, cost chips, avatars, and
   the **frame-layer border technique** (never `border`/`box-shadow` on a clipped
   corner). Plus `.stack`, `.chk`, `.big-ic` and `.loader` lifted from
   `28-auth.css`, which later screens reuse.
5. **ViewComponents.** `Button`, `Panel`, `Card`/`EntityCard`, `CostChip`,
   `Avatar`, `EmptyState`, `Skeleton`. `EntityCard` is justified immediately by
   `shop/_item` and `students_items/_index` sharing one skeleton verbatim.
   ViewComponent is already installed and the chrome is already componentised,
   so this follows existing conventions rather than introducing a pattern.
6. **The dialog mechanism — the biggest shared item.** Native `<dialog>` +
   Stimulus, covering **both** modal systems: the three Bootstrap modals on
   `activity_groups/index`, and the **27 views that render into the layout's
   `turbo_frame_tag 'modal'`**. The turbo-frame variant is the hard one: the
   dialog must open in response to frame content arriving, and
   `redirect_outside_turbo_frame` must keep working. **Every screen that is
   currently a modal is blocked on this**, which is most of the app.
7. **The modal→page migration policy.** DECISIONS says create/edit are **pages**,
   modals only for quick actions. Decide per screen which becomes a page, and
   note that this changes routes and back-navigation (`students_items_helper`'s
   two link builders encode that logic today and will need rewriting).
8. **Application chrome.** Header, desktop sidebar, and the **net-new mobile tab
   bar and "Więcej" sheet**. Sidebar nav labels live in Ruby
   (`MainSidebarComponent#story_group_buttons`), so the mobile nav can reuse that
   data — and the D2 rename ("Grupy aktywności" → "Arkusze ocen") is a one-line
   change there. Add the two missing student entries (Historia waluty, Ustawienia
   w grupie) at the same time.
9. **Bootstrap JS replacements.** Dropdown (6 uses, two needing `auto_close:
   outside`, two needing fixed positioning), collapse (2, wrapped by
   `collapse-memory`), alert dismiss (3), tooltip (1, and **already broken after
   Turbo navigation** — its init scan never re-runs). Keep the `notifications`
   controller's dropdown-show event contract or rewrite it in the same pass.
10. **Form field components.** No form builder exists and **17 files hand-type
    `form-control` / `form-select` / `btn`**. A redesign FormBuilder or a
    `Field` component is the single highest-leverage piece of shared work after
    the dialog, because it is the difference between five form screens being M
    and being L. The upload field (fixed frames, presets, **focal-point crop**,
    pixelated ≤256px) belongs here too.
11. **Third-party restyling.** TomSelect currently imports the
    `tom-select.bootstrap5` theme — that import must be replaced. flatpickr ships
    its own CSS and needs a token-aware skin. Font Awesome + Bootstrap Icons are
    both bundled and both replaced by the mockup's icon set, which `DECISIONS.md`
    still lists as **open on the client**.

### 6.3 Model and migration work the redesign depends on

Not UI, but several screens cannot be finished without it:

| Change | Blocks |
| --- | --- |
| **Soft delete** (`deleted_at` + scopes on items, badges, ranks, sheets, memberships) | items, badges, ranks, sheets, shop, history, student detail |
| **Nicknames** (column, per-group case-insensitive uniqueness, backfill, required at join) | join, student group settings, ranking, teacher student list |
| **Ranking modes** (mode column, tie handling, confirmations) | both ranking screens, the per-sheet top-3 widget |
| **Soft membership** (leave without destroying; rejoin restores) | student group settings |
| **Template versioning + hideable columns** (D5) | sheet template edit, sheet settings |
| **Currency clamp** — `CurrencyAdjusterService` increments `current_currency` unguarded, so a negative correction can drive the spendable balance **below zero**, which D4 forbids | student detail, history. **Deferred by decision**: to be picked up when test coverage is written, not as part of the redesign. |

---

## 7. The five riskiest items

**1. The turbo-frame dialog mechanism (27 views depend on it).**
Nearly every create, edit, show and quick action in this app is rendered into one
shared `turbo_frame_tag 'modal'` with a custom `.modal-overlay`. Replacing that
with native `<dialog>` touches more screens than any other single change, and
DECISIONS simultaneously moves most of those views *out* of modals onto pages.
Getting the mechanism wrong, or changing it midway, means reworking every screen
converted before the change.

**Context added after the audit:** the project owner's position is that the
existing turbo-frame usage was itself a mistake and is a motivation for the
redesign, and that new views take priority over preserving old behaviour. That
lowers the compatibility risk considerably — there is no requirement to keep the
old modal semantics working — but it does not lower the *sequencing* risk. The
replacement pattern still has to exist before the first view is converted, or it
gets retrofitted across everything built in the meantime.

**Mitigation:** settle the `<dialog>` + Stimulus pattern and the
page-vs-dialog list as part of the new-layout step, not during screen
conversion; prove it on one cheap quick action (badge or rank detail) first.

**2. The grading screen (`#/t/grade`).**
The only screen combining an irreversible action, a brand-new intermediate cell
state, a review dialog that must summarise exactly what is about to be awarded,
sticky columns with horizontal scroll, and a ranking-mode-aware widget. A bug
here costs real student currency and cannot be undone. `HANDOFF.md` independently
puts it last; this audit agrees. **Mitigation:** last, with tests around the
award path written before the restyle.

**3. Screens shared between roles.**
`ranks#index`, `badges#index`, `ranking#show` and `story_groups#index`/`#show`
each serve both personas from one action — `story_groups#show` picks
`_student_show` or `_teacher_show` inside a single action. The mockup treats
these as **separate screens under `#/s/` and `#/t/`**, so "convert one controller
per session" (CLAUDE.md) does not cleanly hold: converting one flips the screen
for both roles at once, and a half-converted `story_groups#show` would mean one
role on Bootstrap and the other on Tailwind **inside the same action**.
**Mitigation:** treat each shared action as one unit of work covering both role
variants, and schedule it accordingly.

**4. Auth is not the cheap warm-up it looks like.**
Only 2 of 9 auth screens exist. The other 7 are features: a registration flow
that has no controller, a create-user-from-invite path that contradicts
`AcceptInviteService`'s "user must already exist" assumption, a 60 s server-side
throttle, and the anti-scanner landing page that requires splitting a GET that
currently consumes the token. Starting with auth is still correct for proving the
design system — but budgeting it as "one pattern, nine screens" will be wrong by
a large multiple. **Mitigation:** convert `login` and `login-mail` first to prove
tokens and buttons, then explicitly schedule the registration work as a feature
project, not as redesign.

**5. Bootstrap and the design system fighting over the same class names.**
`HANDOFF.md` reports losing an afternoon to exactly this while building the
mockup, and the conditions here are worse: Bootstrap is imported **from SCSS
source** into both bundles, `.badge` / `.btn` / `.card` / `.nav` all collide, the
design system forbids `border-radius` while Bootstrap applies it nearly
everywhere, and `clip-path` surfaces break Bootstrap's `border` and `box-shadow`
idioms outright. `transaction_kind_badge` emitting `badge bg-primary` from a
helper is a concrete instance already in the codebase. **Mitigation:** scope the
new system under `.app`, keep preflight off while both exist, and prefix the new
component classes (`gh-`) so a collision is impossible rather than merely
unlikely.

*Runner-up worth naming:* **the group-creation wizard's content packs.** The
neutral / fantasy / sci-fi seed packs, scaled by class count, are a content
authoring job (ranks, badges, items, copy, art) disguised as a UI task, and
nothing in `design/` supplies that content.

---

## 8. Recommended conversion order and effort

The order below follows `HANDOFF.md`'s instinct — cheap and self-contained first
— with two changes this audit forces: the dialog mechanism is promoted into the
foundation because 27 views depend on it, and the shared-role screens are
scheduled as single units.

Effort bands are **engineer-days for one engineer already familiar with the
codebase**, assuming decisions D-a/D-b/D-c are settled first. They cover markup,
styles, components and the behaviour changes named per screen, but **exclude**
the bucket-C feature work called out separately.

| # | Stage | Contents | Effort |
| --- | --- | --- | --- |
| 0 | ~~Decisions~~ | **Settled — see 6.1.** HAML; Tailwind added as step 1; utilities + hand-written primitives; one layout; `gh-` namespacing | done |
| 1 | **Design system** | tokens, fonts, theme switching + persistence, third bundle, `redesign` layout, primitives, first ViewComponents | 5–8 d |
| 2 | **Dialog mechanism** | native `<dialog>` + Stimulus for both modal systems, proven on one quick action; page-vs-dialog decision list | 3–5 d |
| 3 | **Auth (the 2 that exist)** | `login`, `login-mail` + the shared auth shell | 2–3 d |
| 4 | **Chrome** | header, sidebar, **mobile tab bar + "Więcej" sheet**, notifications dropdown, D2 rename, missing student nav entries | 5–8 d |
| 5 | **Bootstrap JS removal** | dropdown, collapse, alert, tooltip replacements | 2–3 d |
| 6 | **Cheap read-only lists** | ranks, badges (both roles at once), account settings screen | 3–4 d |
| 7 | **Student screens** | groups, group overview, shop + buy dialog, my items, history | 6–9 d |
| 8 | **Form field components** | FormBuilder/`Field`, upload field with focal-point crop | 4–6 d |
| 9 | **Teacher lists** | students, items, invites, teachers, group settings | 7–10 d |
| 10 | **Forms** | item, badge, rank, group settings, sheet template — all share one layout | 5–7 d |
| 11 | **Sheets** | sheets index (3 Bootstrap components at once), sheet settings, template edit | 5–7 d |
| 12 | **Ranking** | both roles + modes + confirmations | 3–4 d |
| 13 | **Grading sheet** | 3 cell states, review dialog, top-3 widget | 5–8 d |
| 14 | **Bootstrap removal** | delete Bootstrap + Popper + icon sets, preflight back on, bundle cleanup | 1–2 d |

**Redesign subtotal: roughly 57–85 engineer-days (≈ 11–17 weeks solo).**

Tracked separately, because these are features rather than restyling:

| Feature work | Effort |
| --- | --- |
| Model/migration prerequisites (soft delete, nicknames, ranking modes, soft membership, template versioning, currency clamp) | 8–12 d |
| Registration flow (`register`, `register-mail`, invite-code preview endpoint, create-user-from-invite, terms) | 6–9 d |
| Magic-link landing + inbox + expired + resend throttle | 4–6 d |
| USOS interstitial + error taxonomy | 2–3 d |
| Teacher dashboard + student start page (real content) | 4–6 d |
| Group creation wizard + content packs (**content authoring not included**) | 8–12 d |
| Group purchases screen | 2–3 d |
| Error/offline page, skeleton set | 2–3 d |

**Feature subtotal: roughly 36–54 engineer-days.**

**Total: ~93–139 engineer-days.** The spread is wide because it is dominated by
the three unsettled decisions in 6.1 and by how much of the bucket-C feature work
is actually in scope for this round. If the goal is "the app looks like the
mockup" rather than "the app does everything the mockup implies", stages 0–14
alone are the answer and the feature list can be scheduled independently.

A sensible first milestone is **stages 0–3** (~11–17 days): it proves the tokens,
the buttons, the dialog mechanism and the layout split on real screens, and it is
the point at which the rest of the estimate stops being a guess.

---

## 9. Low confidence

Things this audit could not determine from the code, or where it is guessing.
None of these were filled in silently.

**Not verified**

- **Mockup CSS and JS were not read in depth.** Sections 1 and 6 describe the
  design system from `HANDOFF.md`'s and `DECISIONS.md`'s own descriptions of it.
  I did not open `00-base.css`, `tokens.css` or the `js-expanded/` view modules
  myself, except via the auth fork's reading of `28-auth.css`. **Per-screen
  markup deltas in sections 4 and 5 are therefore inferred from our side plus the
  documented decisions, not from a line-by-line diff against the mockup.** The
  bucket assignments (does a counterpart exist) are solid; the fine-grained IA
  claims for individual mockup screens are the weakest part of this document.
- **D6 (discounts)** — `DiscountCalculatorService` exists and computes a rank
  condition against `total_currency`, but I did not verify whether it implements
  "qualify on ANY condition, amount = rank discount + sum of held badge
  discounts". Flagged as needing a read, not reported as compliant or broken.
- **D9 (invite code alphabet)** — I did not read the code generator, so whether
  O/0/I/1/L are already excluded is unknown.
- **Effort bands are judgement, not measurement.** They assume one engineer
  familiar with the codebase and no review latency. They are anchored on file
  sizes, Bootstrap-marker density, and how much non-markup work each screen
  carries — treat them as relative weights first and absolute numbers second.
- I did not run the test suite, RuboCop, or the app. Nothing here is verified
  against runtime behaviour.

**Genuinely ambiguous**

- **Whether `students_profile#index` is reachable.** It has a route and a view,
  but I did not find what links to it. I recommend deleting it; confirm first.
- **The three dead partials** (`badges/_badge`, `ranks/_rank`,
  `story_groups/_story_group`) — no render site was found after checking
  collection renders, model broadcasts, `link_to_add_association` and JS. High
  confidence they are scaffold residue, but "grep found nothing" is not proof.
- **Whether bulk sheet creation (`create_bulk`) survives.** No mockup screen
  covers it. It may be a deliberate omission or an oversight in the mockup.
- **Whether the full-page notifications list survives**, given the mockup only
  shows notifications as a header dropdown.
- **No organization/school model exists** — only an `organization_admin` role
  value. The register-mail copy promises the invite code adds you to the right
  *school* and group. Either the copy overstates it or a model is missing.
- ~~Token TTL: 5 minutes in code vs 15 in DECISIONS.~~ **Resolved: 5 minutes
  stands.** The mockup copy ("Link działa przez 15 minut") is what changes.
- **The wizard's content packs have no source.** Nothing in `design/` supplies
  the neutral/fantasy/sci-fi ranks, badges, items, copy or art.

**Process caveat**

Stage 1 (inventory) and the auth mapping were produced by subagents and then
spot-checked by me against the code; I verified every claim I reproduced as a
hard fact (HAML, layouts, Tailwind's absence, the Bootstrap-JS counts, the
27-view modal pattern, the currency columns, the token TTL, the login bypass).
**The student and teacher mappings in sections 4 and 5 were written by me
directly**, because those three subagents hit a session rate limit before
writing their files — so those two sections had no second reader.

