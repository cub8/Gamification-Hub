# frozen_string_literal: true

# Who runs one group: the owner and every supporting teacher, as one list.
#
# The owner has no StoryGroupTeacher row — ownership is `story_groups.owner_id`
# — so the mockup's single table is assembled here rather than in the view
# (30-rk.js `vTeachers`). A row carries its membership only when there is one,
# and that is exactly what decides whether "Usuń" is offered: the owner is
# shown separately and can never be removed (DECISIONS.md:40).
#
# A service rather than a value: it does the loading. Same split as
# StudentList.
class TeacherList
  Row = Struct.new(:person, :membership, :added_at) do
    def owner? = membership.nil?

    # The owner row has no id of its own, so nothing that needs one — a
    # removal link, a dialog URL — may be built for it.
    def removable? = !owner?
  end

  def initialize(story_group:, memberships: nil)
    @story_group = story_group
    @memberships = memberships
  end

  attr_reader :story_group

  # The owner first, always: they are the answer to "who is responsible for
  # this group", and a list sorted purely by name would bury them.
  def rows
    @rows ||= [owner_row] + supporting_rows
  end

  def any? = rows.any?
  def size = rows.size

  private

  def owner_row
    Row.new(story_group.owner, nil, story_group.created_at)
  end

  def supporting_rows
    loaded_memberships.map { |membership| Row.new(membership.user, membership, membership.created_at) }
                      .sort_by { |row| sort_key(row.person) }
  end

  # Defaults to the group's own memberships; the controller hands in the
  # policy-scoped relation instead.
  def loaded_memberships
    @loaded_memberships ||= (@memberships || story_group.teacher_memberships).with_user.to_a
  end

  # By display name, so the order matches what the teacher is reading. Case
  # and diacritics folded, because "Łukasz" sorting after "Zofia" reads as a
  # bug to everyone but a byte comparator. Same key as StudentList.
  def sort_key(person)
    name = person.full_name.to_s
    [ActiveSupport::Inflector.transliterate(name).downcase, name, person.id]
  end
end
