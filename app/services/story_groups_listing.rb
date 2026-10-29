# frozen_string_literal: true

class StoryGroupsListing
  TABS = {
    nil       => nil,
    'mine'    => :own,
    'teacher' => :sup,
    'student' => :lrn,
  }.freeze

  Group = Data.define(:story_group, :role, :students_count, :meta) do
    def role_label = I18n.t("story_groups.listing.roles.#{role}")
  end

  Tab = Data.define(:key, :label, :total)

  attr_reader :groups, :tabs, :filter

  def initialize(scope:, user:, filter: nil)
    @scope = scope
    @user = user
    @filter = filter if TABS.key?(filter)
  end

  def load
    @tabs   = build_tabs
    @groups = all_groups.select { |group| matches_filter?(group) }
    self
  end

  private

  def matches_filter?(group)
    role = TABS[filter]

    role.nil? || group.role == role
  end

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

  def meta_for(story_group, role)
    case role
    when :own then owner_meta(story_group)
    when :sup then I18n.t('story_groups.listing.owner', name: story_group.owner.full_name)
    else           student_meta(story_group)
    end
  end

  def owner_meta(story_group)
    count = purchase_counts.fetch(story_group.id, 0)
    return I18n.t('story_groups.listing.no_purchases') if count.zero?

    I18n.t('story_groups.listing.purchases', count: count)
  end

  def student_meta(story_group)
    balance = memberships[story_group.id]&.current_currency.to_i

    I18n.t('story_groups.listing.balance', balance: balance, currency: story_group.currency_name)
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

  def recent_window
    (Date.current - (Dashboard::Teacher::RECENT_DAYS.size - 1)).beginning_of_day..
  end

  def build_tabs
    total   = all_groups.size
    by_role = all_groups.group_by(&:role)

    TABS.filter_map do |key, role|
      count = role.nil? ? total : by_role.fetch(role, []).size
      next if role && !count.between?(1, total - 1)

      Tab.new(key: key, label: I18n.t("story_groups.listing.tabs.#{key || 'all'}"), total: count)
    end
  end
end
