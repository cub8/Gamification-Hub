# Gamification Hub

Story Groups (class cohorts) where teachers award in-app currency, ranks and
badges; students spend currency in a per-group shop.

## Stack
Rails 8.1, Ruby 3.4.8, Turbo + Stimulus, jsbundling + cssbundling.
Bootstrap 5.3 (legacy layout) and planning to move to Tailwind (redesign layout) — see Redesign below.

## Commands
- `overmind start` - start project
- `bundle exec rails test` - run all tests
- `bundle exec rubocop` - run lint
- `bundle exec rubocop -A` - run without autofix. Run only on changed files

## Naming: code vs UI
The UI is Polish; code, comments, commits and branches are English.
Model names and UI labels deliberately differ — do not "fix" either to match:
- ActivityGroup → shown as "Arkusz ocen"
- ActivityGroupTemplate → "Szablon arkusza"
- StoryGroup → "Grupa"
design/reference/DECISIONS.md is authoritative for UI wording.

## Redesign in progress
design/ holds a finished static mockup of the new UI. Read design/HANDOFF.md
before UI work. design/reference/SCREENS.md maps each screen to the files
holding its markup and styles.

Two layouts run side by side:
- layout "application" — Bootstrap, current styles, everything not yet converted
- layout "redesign" — Tailwind, new styles, converted controllers only
Each layout links its own compiled bundle; they share no CSS.

Rules while converting:
- Convert one controller per session. Do not touch views on the other layout.
- Copy the mockup's markup, structure, Polish copy and ARIA attributes.
- Never copy its fake data (design/mockup-src/js/05-db.js), its hash router,
  its data-act click delegation, or its device-frame toolbar.
- Behaviour goes in Stimulus controllers, not inline handlers.
- Some mockup screens change behaviour, not just styling (soft delete instead
  of archiving, required nickname at join, negative corrections that lower only
  spendable balance). DECISIONS.md lists them. Flag these before implementing.

Already covered screens:
- chrome, notifications
- student and teacher dashboard
- story group index
- story group overview (Przegląd) - teacher and student perspectives
- ranks index, new, edit - teacher and student perspective
- badges index, new, edit - teacher and student perspective
- items index, new, edit - teacher perspective
- shop index, buy confirmation - student perspective
- students index, show (3 tabs), edit, remove confirmation - teacher perspective
- award badge, revoke badge, adjust currency - teacher perspective
- currency history, my items - student perspective
- invites index, show, new, edit
- new story group wizard + success screen - teacher perspective
- login screens

Every in-group screen now carries the group's cover as a blurred table
background (`.gh-tbg` + `.gh-ttint`), from one branch in the redesign layout.


