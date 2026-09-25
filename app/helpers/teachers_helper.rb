# frozen_string_literal: true

# Polish for the "Nauczyciele" screen only. Anything a second screen needs
# belongs in ApplicationHelper instead — same rule as StudentsHelper.
module TeachersHelper
  # The mockup's lead names group deletion as the one owner-only thing, which
  # stopped being true when managing the list became owner-only too. A
  # supporting teacher reading the original sentence would take it as an
  # invitation to press a button that is not there.
  def teacher_list_lead(manage:)
    opening = 'Nauczyciele wspomagający pomagają prowadzić tę grupę.'

    return "#{opening} Grupę może usunąć tylko właściciel." if manage

    "#{opening} Dodawać i usuwać nauczycieli może tylko właściciel grupy."
  end

  # "09.09.2026". The mockup's "Dodano" column is a plain date, not a point in
  # a feed (gh_when) and not a deadline with an hour on it (gh_stamp).
  def teacher_added_on(time)
    time.to_date.strftime('%d.%m.%Y')
  end

  # The line the add dialog shows before anything is typed. It names the size
  # of the pool, because "no results" for an empty query would read as "there
  # is nobody", which is the opposite of the truth (30-rk.js `resHtml`).
  def teacher_pool_hint(size)
    # The verb moves with the number, so the whole clause is pluralised and not
    # just the noun: "jest 1 nauczyciel", "są 2 nauczyciele", "jest 5 nauczycieli".
    count = gh_plural(size,
                      "jest #{size} nauczyciel",
                      "są #{size} nauczyciele",
                      "jest #{size} nauczycieli",)

    "Wpisz co najmniej 2 znaki imienia, nazwiska albo e-maila. W Twojej uczelni #{count}."
  end

  # The sub-line under a candidate's name. The university is only worth
  # printing when the pool can span more than one — otherwise it is the same
  # word on every row.
  def teacher_candidate_subtitle(candidate, cross_university:)
    return candidate.email unless cross_university && candidate.person.university_name.present?

    "#{candidate.email}, #{candidate.person.university_name}"
  end
end
