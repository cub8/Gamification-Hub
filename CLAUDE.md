# Gamification Hub

Story Groups (class cohorts) where teachers award in-app currency, ranks and
badges; students spend currency in a per-group shop.

## Stack
Rails 8.1, Ruby 3.4.8, Turbo + Stimulus, jsbundling + cssbundling.
Tailwind 4. One layout, "application" — no Bootstrap.

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

## Frontend layout
Styles: `app/assets/stylesheets/application.css` is the Tailwind entry point;
system partials sit beside it, screen-specific rules under `components/`.
Scripts: `app/javascript/application.ts` is the esbuild entry point; Stimulus
controllers live in `app/javascript/controllers/` and self-register in
`controllers/index.ts`.

Every in-group screen carries the group's cover as a blurred table background
(`.gh-group-cover-bg` + `.gh-group-cover-tint`), from one branch in `layouts/application.html.haml`.

