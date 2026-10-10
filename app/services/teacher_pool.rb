# frozen_string_literal: true

class TeacherPool
  ROLES = %i[teacher organization_admin global_admin].freeze

  Candidate = Data.define(:person, :in_group, :search_key) do
    def in_group? = in_group
    def name = person.full_name.to_s
    def email = person.email.to_s
  end

  attr_reader :story_group, :viewer

  def initialize(story_group:, viewer:)
    @story_group = story_group
    @viewer = viewer
  end

  def candidates
    @candidates ||= people.map { |person| candidate_for(person) }
                          .sort_by { |candidate| sort_key(candidate.person) }
  end

  def any? = candidates.any?
  def size = candidates.size
  def addable? = candidates.any? { |candidate| !candidate.in_group? }
  def cross_university? = viewer.global_admin?

  private

  def candidate_for(person)
    key = fold("#{person.full_name} #{person.email}")

    Candidate.new(person, taken_ids.include?(person.id), key)
  end

  def fold(text)
    text.to_s
        .unicode_normalize(:nfd)
        .gsub(/\p{Mn}/, '')
        .tr('łŁ', 'lL')
        .downcase
  end

  def people
    @people ||= scope.to_a
  end

  def scope
    return User.where(role: ROLES) if cross_university?

    User.where(role: ROLES, university_name: viewer.university_name)
  end

  def taken_ids
    @taken_ids ||= story_group.teacher_memberships.pluck(:user_id).push(story_group.owner_id).compact.to_set
  end

  def sort_key(person)
    name = person.full_name.to_s
    [ActiveSupport::Inflector.transliterate(name).downcase, name, person.id]
  end
end
