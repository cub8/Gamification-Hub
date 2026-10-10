# frozen_string_literal: true

module TeachersHelper
  def teacher_list_lead(manage:)
    opening = 'Nauczyciele wspomagający pomagają prowadzić tę grupę.'

    return "#{opening} Grupę może usunąć tylko właściciel." if manage

    "#{opening} Dodawać i usuwać nauczycieli może tylko właściciel grupy."
  end

  def teacher_added_on(time)
    time.to_date.strftime('%d.%m.%Y')
  end

  def teacher_pool_hint(size)
    count = gh_plural(size,
                      "jest #{size} nauczyciel",
                      "są #{size} nauczyciele",
                      "jest #{size} nauczycieli",)

    "Wpisz co najmniej 2 znaki imienia, nazwiska albo e-maila. W Twojej uczelni #{count}."
  end

  def teacher_candidate_subtitle(candidate, cross_university:)
    return candidate.email unless cross_university && candidate.person.university_name.present?

    "#{candidate.email}, #{candidate.person.university_name}"
  end
end
