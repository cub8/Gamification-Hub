# frozen_string_literal: true

# The "Grupy" screen (mockup `#/s/groups` and `#/t/groups` — one view, two
# personas).
#
# Turns the Pundit scope into cards and filter tabs: what your role in each
# group is, how many students it has, and the one extra fact the mockup prints
# next to that count, which differs per role.
class StoryGroupsListing
  # gh_plural only formats a number; it touches no view context. Including the
  # helper keeps the Polish plural rule in one place instead of giving the view
  # a `case` on role just to assemble a string the service already knows.
  include RedesignHelper

  # Role -> the tag printed on the card. Owner-first: owning implies teaching,
  # so a group you own is never "Wspierasz".
  ROLE_LABELS = { own: 'Prowadzisz', sup: 'Wspierasz', lrn: 'Uczysz się' }.freeze

  # Filter param -> [tab label, role it selects]. `nil` is "everything" and is
  # always present. The param values are the ones the Bootstrap screen already
  # used, so links and bookmarks into this screen keep working.
  TABS = {
    nil       => ['Wszystkie', nil],
    'mine'    => ['Moje',      :own],
    'teacher' => ['Nauczam',   :sup],
    'student' => ['Uczę się',  :lrn],
  }.freeze

  Group = Struct.new(:story_group, :role, :students_count, :meta) do
    def role_label = ROLE_LABELS[role]
  end

  # `total`, not `count`: a Struct member named `count` shadows Struct#count.
  Tab = Struct.new(:key, :label, :total)

  attr_reader :groups, :tabs, :filter

  # `scope` is the Pundit scope — authorization stays in the controller.
  def initialize(scope:, user:, filter: nil)
    @scope = scope
    @user = user
    # An unknown ?filter= falls back to everything rather than to an empty
    # screen, which is what a stale or hand-edited URL deserves.
    @filter = filter if TABS.key?(filter)
  end

  def load
    @tabs   = build_tabs
    @groups = all_groups.select { |group| matches_filter?(group) }
    self
  end

  private

  def matches_filter?(group)
    role = TABS[filter].last

    role.nil? || group.role == role
  end

  # Every group, in every tab: the tab counts describe the whole list, so they
  # must not be recomputed per filter.
  def all_groups
    @all_groups ||= begin
      summaries = records.map do |story_group|
        role = role_for(story_group)

        Group.new(
          story_group:    story_group,
          role:           role,
          students_count: student_counts.fetch(story_group.id, 0),
          meta:           meta_for(story_group, role),
        )
      end

      summaries.sort_by { |group| group.story_group.name.to_s.downcase }
    end
  end

  def records
    @records ||= @scope.with_attached_icon.to_a
  end

  def role_for(story_group)
    return :own if story_group.owner_id == @user.id
    return :sup if teacher_group_ids.include?(story_group.id)

    :lrn
  end

  # The mockup's second meta item (30-gh.js:17): what matters about a group
  # depends entirely on what you are in it.
  def meta_for(story_group, role)
    case role
    when :own then owner_meta(story_group)
    when :sup then "Właściciel: #{story_group.owner.full_name}"
    else           student_meta(story_group)
    end
  end

  def owner_meta(story_group)
    count = purchase_counts.fetch(story_group.id, 0)
    return 'Brak nowych zakupów' if count.zero?

    "#{count} #{gh_plural(count, 'nowy zakup', 'nowe zakupy', 'nowych zakupów')}"
  end

  def student_meta(story_group)
    balance = memberships[story_group.id]&.current_currency.to_i

    "Masz #{balance} #{story_group.currency_name}"
  end

  def teacher_group_ids
    @teacher_group_ids ||= @user.teacher_story_groups.ids
  end

  def memberships
    @memberships ||= @user.student_memberships.index_by(&:story_group_id)
  end

  def student_counts
    @student_counts ||= StoryGroupStudent.where(story_group_id: records.map(&:id))
                                         .group(:story_group_id)
                                         .count
  end

  def owned_ids
    @owned_ids ||= records.select { |story_group| story_group.owner_id == @user.id }
                          .map(&:id)
  end

  def purchase_counts
    return {} if owned_ids.empty?

    @purchase_counts ||= CurrencyTransaction.purchase
                                            .joins(:student)
                                            .where(story_group_students: { story_group_id: owned_ids })
                                            .where(created_at: recent_window)
                                            .group('story_group_students.story_group_id')
                                            .count
  end

  # "New" is the window the teacher start screen already calls recent — today
  # and yesterday. Derived from that constant so the two cannot drift.
  def recent_window
    (Date.current - (TeacherStartDashboard::RECENT_DAYS.size - 1)).beginning_of_day..
  end

  # A tab is worth showing only when it narrows the list: never at zero, and
  # never when it selects everything (a lone "Wszystkie" filters nothing, and a
  # "Moje" identical to "Wszystkie" is noise). The strip then renders only when
  # more than one tab survives — which is why a student, who can only ever be
  # `lrn`, sees no strip at all.
  def build_tabs
    total   = all_groups.size
    by_role = all_groups.group_by(&:role)

    TABS.filter_map do |key, (label, role)|
      count = role.nil? ? total : by_role.fetch(role, []).size
      next if role && !count.between?(1, total - 1)

      Tab.new(key: key, label: label, total: count)
    end
  end
end
