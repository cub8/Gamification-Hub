# frozen_string_literal: true

# One row of the teacher's "Wymaga uwagi" list (mockup vHome(),
# js-expanded/30-gh.js:40-43).
#
# Read-only and query-free: TeacherOverview decides what deserves
# attention and writes the Polish sentence; this only carries it, so the view
# renders one shape of row no matter which of the three checks produced it.
#
#   icon    — Font Awesome class, e.g. "fa-heart"
#   tone    — nil, or "zero" for the red 0-lives pip
#   title   — the bold line
#   detail  — the small line under it, always explaining the consequence
#   action  — label + path; `emphasis` picks a real button over a link button,
#             which the mockup reserves for the one row that is a task ("Oceń")
AttentionItem = Struct.new(:icon, :tone, :title, :detail, :action_label, :action_path, :emphasis) do
  def emphasised? = !!emphasis
end
