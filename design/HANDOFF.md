# Card Table redesign — handing this to Claude Code

This bundle is the design source of truth for restyling the Rails app. It is a
static mockup: no backend, no persistence, fake data. Its job is to answer
"what should this screen look like and how should it behave", nothing else.

## What's in here

| Path | What it is | Give it to Claude Code? |
| --- | --- | --- |
| `mockup/gamification-hub-mockup.html` | The built, clickable mockup. ~1.2 MB, mostly base64 fonts. | **No.** Open it in a browser. Never paste it into context. |
| `mockup-src/css/00-base.css` | The design system: tokens, shape, buttons, cards, panels, chrome, layout. Fonts stripped, ~41 KB. | **Yes** — this is the most important file. |
| `mockup-src/css/2*.css` | Per-area CSS blocks (forms, lists, ranking, auth…). 1–10 KB each. | Yes, the one for the screen being built. |
| `mockup-src/css/90-core.css` | Styles for screens added during wiring (account, purchases, error, sheet). | Yes, when relevant. |
| `mockup-src/js-expanded/` | Each area's markup + behaviour as one readable file. **Read these for markup** — they contain the actual HTML strings. | Yes, the one for the screen being built. |
| `mockup-src/js/` + `build.py` + `tools/` | How the mockup itself is assembled. | Only if you want to keep editing the mockup. |
| `tokens/tokens.css` | Just the light/dark custom properties. | Yes, at the start. |
| `reference/DECISIONS.md` | Product and naming decisions the mockup encodes (soft delete, "Arkusze ocen", nickname rules, negative corrections…). | **Yes** — read once, keep in the repo. |
| `reference/SCREENS.md` | All 46 routes mapped to their source files. | Yes, as an index. |

## The one thing to get right first

Do **not** start by converting screens. Start by converting the *system*, because
every screen is built from the same handful of primitives:

- **One shape.** Every surface is the same cut-corner octagon, done with
  `clip-path: polygon(...)` driven by a `--c` variable. No border-radius anywhere
  in the entire mockup. In `00-base.css` this is a single rule listing every
  element that gets the shape.
- **Buttons have a physical bottom edge** — a `::before` with a two-stop linear
  gradient (`edge` colour for the bottom 3px, fill above), and `:active` shifts
  down 2px. That's the whole "card table" feel.
- **Semantic colour roles**, not palette names: `--item` (orange, purchasable),
  `--badge` (teal), `--rank` (gold), `--lock`, `--heart`, `--earn`, `--spend`.
  Each has an `-edge` variant. Light and dark are two token sets on
  `[data-theme]`.
- **Three fonts**: Bricolage Grotesque (UI), Literata (flavour text/story),
  JetBrains Mono (codes).

Get these into Tailwind as theme extensions plus a small set of components, and
the screens become mostly composition.

## Bootstrap → Tailwind, without a big bang

The mockup is framework-agnostic CSS, so it doesn't force the decision — but it
will fight Bootstrap, since both want to own `.btn`, `.card`, `.badge`, `.nav`.
That collision is real: while merging twelve template stylesheets I lost an
afternoon to exactly this class of bug (a stray `.sec` rule from one page
restyling every secondary button in the app).

A safe order:

1. **New layout, old CSS still loaded.** Add `app/views/layouts/redesign.html.erb`.
   Opt a controller in with `layout "redesign"`. Keep Bootstrap loaded for
   everything else.
2. **Add Tailwind alongside, preflight off**, scoped to the new layout's root
   (`.app`). Tailwind's preflight resets things Bootstrap depends on, so leave
   `corePlugins.preflight = false` while both exist, and put the mockup's own
   reset inside `.app`.
3. **Migrate screen by screen.** Each converted controller switches to the new
   layout. Bootstrap stays until the last one flips, then you delete it and turn
   preflight back on.
4. **Only then** consider whether Tailwind utilities or plain CSS suit this design
   better. Honestly: much of `00-base.css` (the clip-path shape, the gradient
   edges, the card faces) is awkward as utility classes. A realistic split is
   Tailwind for layout and spacing, a `@layer components` file lifted almost
   verbatim from `00-base.css` for the primitives, ViewComponents to name them.

## Suggested screen order

Cheap and self-contained first, so the system gets exercised before anything hard:

1. Auth screens (`#/out/login` and friends) — no chrome, few components, proves tokens and buttons.
2. Application chrome — header, sidebar, mobile tab bar, "Więcej" sheet. Everything else sits inside it.
3. Student read-only screens — group overview, my items, ranks, badges, currency history.
4. Teacher lists — students, items, ranks, badges, invites, teachers.
5. Forms — item, badge, rank, group settings, sheet template. All share one form/preview layout.
6. Shop and the buy dialog.
7. Grading sheet — leave for last. Sticky columns, horizontal scroll, an irreversible action and a scrollable review dialog.
8. Group creation wizard.

## Prompting Claude Code

**Set up `CLAUDE.md` in the repo root first.** Something like:

> This app is being restyled to the "Card Table" design. The design source is in
> `design/` — read `design/reference/DECISIONS.md` and `design/tokens/tokens.css`
> before any UI work, and `design/mockup-src/css/00-base.css` for the primitives.
> Screens live in `design/reference/SCREENS.md`; each row names the file holding
> that screen's markup. The mockup is a static prototype: copy its markup,
> structure and copy (Polish UI text), never its fake data or its hash router.
> New screens use `layout "redesign"` and Tailwind; untouched controllers keep
> Bootstrap. Never change a Bootstrap-era view while converting a different screen.

**Then a system-extraction session, before any screen:**

> Read `design/tokens/tokens.css` and `design/mockup-src/css/00-base.css`.
> Produce: (1) a Tailwind theme extension for the colour roles, fonts and the
> `--c` corner sizes, with light/dark as `[data-theme]` token sets, not
> Tailwind's `dark:` variant; (2) a `@layer components` stylesheet for the
> primitives that don't express well as utilities — the octagon clip-path, the
> button edge treatment, panels, cards, cost chips, avatars; (3) ViewComponents
> for Button, Panel, Card, CostChip, Avatar with the variants the mockup uses.
> Show me the plan before writing files.

**Then one screen at a time:**

> Convert the students list. The design is `#/t/students` in the mockup — markup
> in `design/mockup-src/js-expanded/30-lists.js` (function `vStudents`), styles in
> `design/mockup-src/css/24-lists.css`. Our current implementation is
> `app/views/students/index.html.erb` with `StudentsController#index`. Keep our
> existing data, routes and Turbo behaviour; change only markup and styles. Switch
> this controller to `layout "redesign"`. Use the components from the previous
> step; tell me if you need a new one rather than inventing one-off CSS. The lives
> stepper and search should use Stimulus, not the mockup's inline handlers.

Notes on what makes those prompts work: they point at *one* screen's files rather
than the whole bundle, they say explicitly what to keep (data, routes, Turbo) and
what to replace (markup, styles), and they ask for the plan first on the one task
where a wrong turn is expensive.

## Things the mockup does that your app should not copy

- **The hash router and persona switch.** Rails routes and real sessions replace them.
- **`DB` in `05-db.js`.** Fake seed data. Your models replace it.
- **Inline `data-act` click delegation.** The mockup dispatches every click through one listener. Use Stimulus controllers.
- **The toolbar and device frame.** Prototype scaffolding, outside the app entirely.
- **`window.mock`.** Debug hook.

What *is* worth copying literally: the Polish UI copy (it was written carefully —
error messages, empty states, the dialogs explaining what a destructive action
actually destroys), the ARIA attributes, and the container-query breakpoints.
`00-base.css` uses `@container app` rather than media queries because the mockup
renders in a scaled frame; in the real app plain media queries are fine, but keep
the same breakpoints (1199 / 1080 / 720).

## Estimating the work

46 screens, but they collapse into far fewer patterns: 9 auth screens are one
pattern, 5 form screens are one pattern, 4 list screens are one pattern. The real
work is the system extraction, the chrome, and the grading sheet. Ask Claude Code
to produce the estimate itself after reading `SCREENS.md` and your
`app/views` — it can map mockup screens to your existing controllers and tell you
which ones have no counterpart yet (the account settings page, "Wszystkie zakupy
w grupie" and the error state were invented during this mockup and may not exist
in your app at all).
