# frozen_string_literal: true

class ActivityGroup < ApplicationRecord
  include SoftDeletable

  belongs_to :story_group
  belongs_to :activity_group_template

  has_many :activity_group_categories, -> { order(:position) }, dependent: :destroy

  accepts_nested_attributes_for :activity_group_categories, allow_destroy: true

  validates :name, presence: { message: 'Podaj nazwę arkusza.' }, length: { maximum: 100 }
  validate :at_least_one_visible_category, on: :settings

  scope :newest_first, -> { order(created_at: :desc, id: :desc) }

  def columns_modified? = columns_modified_at.present?

  def visible_categories = activity_group_categories.reject(&:hidden?)

  def max_reward = visible_categories.sum { |category| category.reward.to_i }

  class << self
    def next_name_for_template(template)
      next_names_for_template(template, 1).first
    end

    def next_names_for_template(template, count)
      first = next_number_for_base(template)

      Array.new(count) { |offset| "#{template.base_name} #{first + offset}" }
    end

    def next_number_for_base(template)
      matching = template.activity_groups
                         .where('name ~* ?', "^#{Regexp.escape(template.base_name)} [0-9]+$")
                         .order(:id)

      last = matching.last
      return template.activity_groups.count + 1 unless last

      Integer(last.name.to_s.split(' ').last) + 1
    rescue ArgumentError, TypeError
      template.activity_groups.count + 1
    end
  end

  private

  def at_least_one_visible_category
    return if activity_group_categories.any? { |category| !category.marked_for_destruction? && !category.hidden? }

    errors.add(:base, 'Dodaj co najmniej jedną widoczną kategorię.')
  end
end
