# frozen_string_literal: true

class TeacherPool
  # Who may hold a group at all. Admins are teachers with more rights, not a
  # separate kind of person, so they belong in the pool.
  ROLES = %i[teacher organization_admin global_admin].freeze

  # `search_key` is name and e-mail in one folded string: the mockup matches
  # against both at once (`norm(t.name + ' ' + t.email)`), so a query
  # spanning the two finds nothing, exactly as it does there.
  Candidate = Data.define(:person, :in_group, :search_key) do
    def in_group? = in_group

    def name = person.full_name.to_s

    def email = person.email.to_s
  end

  def initialize(story_group:, viewer:)
    @story_group = story_group
    @viewer = viewer
  end

  attr_reader :story_group, :viewer

  def candidates
    @candidates ||= people.map { |person| candidate_for(person) }
                          .sort_by { |candidate| sort_key(candidate.person) }
  end

  def any? = candidates.any?
  def size = candidates.size

  # Whether the dialog has anything to offer. The pool always holds at least
  # the owner, so `any?` is never the question — "is there somebody not in
  # the group yet" is.
  def addable? = candidates.any? { |candidate| !candidate.in_group? }

  # Whether the pool can span more than one university. Only then is the
  # university worth printing beside an e-mail — for everyone else it is the
  # same word on every row.
  def cross_university? = viewer.global_admin?

  private

  def candidate_for(person)
    key = fold("#{person.full_name} #{person.email}")

    Candidate.new(person, taken_ids.include?(person.id), key)
  end

  # Diacritics folded, so "lukasz" finds "Łukasz". `ł` has no combining
  # decomposition, so NFD alone leaves it behind and it needs naming.
  # Mirrors the mockup's norm() and the fold() in the Stimulus controllers.
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

  # Already in, in either capacity. They stay in the list wearing "Już w
  # grupie" rather than vanishing from it: a teacher searching for somebody
  # wants to be told they are already here, not shown an empty result.
  def taken_ids
    @taken_ids ||= story_group.teacher_memberships.pluck(:user_id).push(story_group.owner_id).compact.to_set
  end

  # Same key as TeacherList, so the dialog and the list agree on the order.
  def sort_key(person)
    name = person.full_name.to_s
    [ActiveSupport::Inflector.transliterate(name).downcase, name, person.id]
  end
end
