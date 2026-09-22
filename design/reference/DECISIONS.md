# Gamification Hub – Card Table redesign: working notes for the wiring session

## Goal of the next session
Build ONE wired mockup app (single self-contained HTML) from these sources: hash router, persona switch
(teacher John Curtin / student Sebastian Alejandro / logged out), shared state across screens
(buy -> balance + teacher purchases + notifications; award in grading sheet -> student history + rank;
join with code + nickname -> student start page), light/dark, desktop/mobile frame, toolbar outside the app.
Build in parts (css + js modules) concatenated by a build script, verify with Playwright (Chromium is available).

## Sources in this zip
- ct/ : main mockup (styles.css = design system + tokens, app.js = data/icons/glyphs/views, index.html, build.py,
  fonts/*.woff2 subset Latin+Polish, rabbits.jpg). Fonts: Bricolage Grotesque, Literata (opsz pinned), JetBrains Mono (all OFL).
- t/ : later screens as templates. Build pattern used everywhere:
  base.css (= main mockup <style>, fonts inlined) + CSS blocks cut from earlier templates (text between '/*CSS*/' and '</style>')
  + JS slice of ct/app.js from 'const IC = {' to 'const LOGO' plus 'const CUR = {' to 'const CATS = [' (icons, glyphs, CUR, RANKS, BADGES, ITEMS)
  + rabbits.jpg as base64. Templates: form.html (story group wizard), item.html (item form), br.html (badge+rank forms),
  ag.html (grading sheets + templates), lists.html (teacher lists + code modal), student.html (student detail),
  rk.html (ranking/teachers/notifications), isg.html (invites/group settings/student start), auth.html (login/register),
  gh.html (group index/teacher home/student group settings/join nickname), sp.html (student pages/states), test.html (upload stress test).

## Settled decisions
- Style: "Card Table". No rounded ends anywhere; 45° cut corners (octagon, echoes logo). Entities are cards: item=orange, badge=teal, rank/currency=gold, sealed=grey.
- Borders on cut-corner surfaces: use a frame layer + inset background (never border/box-shadow; they break at corners).
- Uploads: fixed frames. Currency = gold rim + cream token (>=22px); price chips on cards show number only; optional "icon is already a coin" mode;
  pixelated rendering for small uploads (<=256px). Every image field: presets + upload + focal point (crop). Min upload ~400px for art.
- Forms: pages (not modals) for create/edit; modals/sheets for quick actions. Steps only in story group creation.
- Story group creation: Quick setup (packs neutral/fantasy/sci-fi, scaled by planned number of classes) or manual. Success screen must NOT show join code.
- Deletion: soft delete everywhere (hidden from shop/lists/pickers, KEPT in history, shown as "Usunięty z oferty"). Only deleting a story group deletes everything. No archiving.
- Naming: "Arkusze ocen" (grading sheets), "Szablon arkusza", actions "Utwórz arkusz", "Oceń". Not "Grupy aktywności".
- Template edits affect only sheets created afterwards. Column changes in a sheet affect only future awards; columns with awards can be hidden, not removed.
- Grading: 3 cell states (empty / marked now / awarded+locked), review dialog before irreversible award, focus on safe button.
- Currency corrections: only POSITIVE corrections raise total collected (rank). Negative lower only spendable balance; cannot go below 0.
- Discounts: student qualifies if they meet ANY condition (rank OR any listed badge). Amount = rank discount + SUM of held listed badge discounts.
- Item without requirements can never be sealed. "Można kupić przy 0 życiach" exception.
- Lives: taken for unjustified absence. Stepper shows heart + number (fixed width), never one heart per life in tables.
- Ranking: enabling requires confirmation; modes "Podium i własne miejsce" (DEFAULT for new groups) and "Pełny ranking" (confirm when switching to full).
  Students see nicknames only; teacher sees nickname + name. Ties share place. Per-sheet top-3 widget respects ranking visibility/mode.
- Nicknames: per group, required at join (step 2 of join), editable in "Ustawienia w grupie", unique per group (case-insensitive).
- Notifications: teachers only (purchases). Dropdown with Nowe/Wcześniej, mark all read.
- Supporting teachers: everything except deleting the group and managing the teacher list — adding and
  removing teachers is the owner's (they still read the list). Owner shown separately, cannot be removed.
- Add teacher: search-first (>=2 chars, diacritics-insensitive), max 8 results, per-row "Dodaj".
- Invites: 6-char codes without O,0,I,1,L. Limit and expiry each optional via explicit switches + summary sentence. Edit keeps code; limit >= uses.
  Code modal: dropdown of ACTIVE invites (newest default); inactive hidden. New invite is not auto-shown.
- Leaving a group: possible; REJOINING RESTORES old data (currency, badges, items). Leave dialog should say so.
- Auth: USOS login == USOS registration (UX labels differ). E-mail = magic link, 15 min, single use, consumed only after clicking the
  button on the landing page (anti-scanner). Resend cooldown 60 s. E-mail registration (school students): e-mail, first name, last name,
  invite code (finds organization + group), terms checkbox. Teachers: USOS or created by system admin. Pending QR join remembered
  (cookie/session) across login/registration.
- Account settings ("Ustawienia" in avatar menu): display user data only (name, e-mail, university, index, USOS ID) + theme + logout.
- Mobile: bottom tab bar; hidden in focused flows (forms/wizard). Card lists single-column on phones; shop keeps 2-col compact cards.
- Loading: skeletons with the same dimensions as content (no layout shift).

## Mockups that are OUT OF DATE (build per decisions above)
- Archive buttons (item, badge, grading sheet) -> delete (soft).
- "Grupy aktywności" labels -> "Arkusze ocen".
- Wizard success shows join code -> remove.
- student.html: negative correction lowers total -> must not.
- isg.html group settings text "Tylko właściciel zmienia te ustawienia" -> supporting teachers can too; only delete is owner-only.
- Main mockup: student sidebar lacks "Historia waluty" / "Ustawienia w grupie"; join modal lacks nickname step.
- gh.html leave dialog: must say rejoining restores data.

## Gaps to fill in the wired app
- "Więcej" sheet on mobile (remaining group sections).
- Account settings page (read-only user data).
- "Wszystkie zakupy w grupie" (dashboard purchases filtered to one group).
- Server error / offline state.

## Open (client)
- Terms of service + privacy policy documents (links are placeholders). Real icon set later (use current presets for now).

## Production stack (for the later Claude Code handoff)
Rails 8.1, Ruby 3.4.9, ViewComponent, Turbo, Stimulus. Recommendation: drop Bootstrap; Tailwind v4 (tailwindcss-rails, no Node)
with tokens in @theme + gh- prefixed component classes in @layer components (or plain CSS design system). New layout per migrated
section. Native <dialog> + Stimulus for modals/sheets. Polish plurals via rails-i18n; currency's 3 forms per group.
