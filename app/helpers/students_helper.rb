# frozen_string_literal: true

# Screen-specific labels live in the screen's own helper, not in RedesignHelper.
module StudentsHelper
  # The list's own sentence. The second half only appears when somebody is
  # actually at zero — a line about a state nobody is in is noise.
  #
  # The mockup writes "N studentów ma 0 żyć" with a plural table that has no
  # 2-4 form (30-lists.js:45); gh_plural has one, so this says "2 studentów ma"
  # where the mockup would have said the same thing by accident.
  def student_list_lead(list)
    lead = ['Życie odbierasz za nieusprawiedliwioną nieobecność.']
    return safe_join(lead) if list.zero_lives.zero?

    zero = list.zero_lives

    safe_join(lead + [' ',
                      tag.b("#{zero} #{gh_plural(zero, 'student ma', 'studentów ma', 'studentów ma')} 0 żyć"),
                      ' i kupi tylko przedmioty dostępne przy 0 życiach.',])
  end

  # The smaller line under a name in the list.
  #
  # The mockup shows the e-mail alone (30-lists.js:40). The bold line above is
  # the real name, so this carries the NICKNAME when there is one — DECISIONS.md
  # says the teacher sees nickname and name both, and the ranking is the only
  # screen where the nickname outranks the name. Without one there is nothing to
  # add and the e-mail stands alone.
  def student_list_subtitle(student)
    parts = []
    parts << "„#{student.nickname}”" if student.nickname.present?
    parts << student.email

    parts.join(' · ')
  end

  # "Pseudonim: Nova, s.alejandro@example.com, indeks s123456" — the detail
  # page's sub-line. The nickname is labelled rather than bare because here it is
  # a fact about the person, not the name they are going by on this screen. A
  # student who joined without an index number simply does not get that half.
  def student_sheet_subtitle(student)
    parts = []
    parts << "Pseudonim: #{student.nickname}" if student.nickname.present?
    parts << student.email
    parts << "indeks #{student.university_number}" if student.university_number.present?

    parts.join(', ')
  end

  # "34 z 50 do rangi Nawigator", or nothing at the top rung and in a group with
  # no ranks at all.
  def student_rank_progress_line(sheet)
    return if sheet.next_rank.nil?

    "#{sheet.total} z #{sheet.next_rank.required_currency_value} do rangi #{sheet.next_rank.name}"
  end

  # What "Usuń z grupy" costs, spelled out in numbers. Nothing is soft-deleted
  # here: the membership goes and takes the badges, the purchases and the whole
  # ledger with it, so the dialog has to say exactly that.
  def student_removal_losses(sheet)
    losses = []

    if sheet.badges.any?
      count = sheet.badges.size
      losses << "#{count} #{gh_plural(count, 'odznakę', 'odznaki', 'odznak')}"
    end

    if sheet.purchases.any?
      count = sheet.purchases.size
      losses << "#{count} #{gh_plural(count, 'przedmiot', 'przedmioty', 'przedmiotów')}"
    end

    entries = sheet.ledger.size
    losses << "całą historię waluty (#{entries} #{gh_plural(entries, 'wpis', 'wpisy', 'wpisów')})" if entries.positive?

    losses
  end

  # The user picker on the Bootstrap "Dodaj studenta" screen, which is not part
  # of the redesign yet. Left alone deliberately.
  def student_map(students)
    students.map do |u|
      {
        value:             u.id,
        text:              u.email,
        name:              u.full_name,
        email:             u.email,
        university_number: u.university_number,
      }
    end
  end
end
