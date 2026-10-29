# frozen_string_literal: true

# Screen-specific labels live in the screen's own helper, not in ApplicationHelper.
module StudentsHelper
  def student_list_lead(list)
    lead = [t('students.helpers.list_lead')]
    return safe_join(lead) if list.zero_lives.zero?

    safe_join(lead + [' ',
                      tag.b(t('students.helpers.zero_lives', count: list.zero_lives)),
                      ' ',
                      t('students.helpers.zero_lives_tail'),])
  end

  def student_list_subtitle(student)
    parts = []
    parts << t('students.helpers.nickname_quoted', nickname: student.nickname) if student.nickname.present?
    parts << student.email

    parts.join(' · ')
  end

  # "Pseudonim: Nova, s.alejandro@example.com, indeks s123456" — the detail
  # page's sub-line. The nickname is labelled rather than bare because here it is
  # a fact about the person, not the name they are going by on this screen. A
  # student who joined without an index number simply does not get that half.
  def student_sheet_subtitle(student)
    parts = []
    parts << t('students.helpers.nickname', nickname: student.nickname) if student.nickname.present?
    parts << student.email
    if student.university_number.present?
      parts << t('students.helpers.university_number', number: student.university_number)
    end

    parts.join(', ')
  end

  # "34 z 50 do rangi Nawigator", or nothing at the top rung and in a group with
  # no ranks at all.
  def student_rank_progress_line(sheet)
    return if sheet.next_rank.nil?

    t('students.helpers.rank_progress', total:    sheet.total,
                                        required: sheet.next_rank.required_currency_value,
                                        rank:     sheet.next_rank.name,)
  end

  # What "Usuń z grupy" costs, spelled out in numbers. Nothing is soft-deleted
  # here: the membership goes and takes the badges, the purchases and the whole
  # ledger with it, so the dialog has to say exactly that.
  def student_removal_losses(sheet)
    losses = []

    losses << t('students.helpers.losses.badges', count: sheet.badges.size) if sheet.badges.any?
    losses << t('students.helpers.losses.items', count: sheet.purchases.size) if sheet.purchases.any?

    entries = sheet.ledger.size
    losses << t('students.helpers.losses.ledger', count: entries) if entries.positive?

    losses
  end
end
