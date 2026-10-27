# frozen_string_literal: true

module TeachersHelper
  def teacher_list_lead(manage:)
    tail = manage ? t('teachers.helpers.lead_manage') : t('teachers.helpers.lead_read_only')

    "#{t('teachers.helpers.lead')} #{tail}"
  end

  def teacher_added_on(time)
    l(time.to_date, format: :default)
  end

  def teacher_pool_hint(size)
    t('teachers.helpers.pool_hint', count: size)
  end

  def teacher_candidate_subtitle(candidate, cross_university:)
    return candidate.email unless cross_university && candidate.person.university_name.present?

    t('teachers.helpers.candidate', email: candidate.email, university: candidate.person.university_name)
  end
end
