# frozen_string_literal: true

# One grading sheet — UI "Arkusz ocen". Its columns are copied from a template
# at creation time and belong to it from then on, which is what makes
# DECISIONS.md:30 ("template edits affect only sheets created afterwards")
# true without any versioning: there is nothing left to version.
class ActivityGroup < ApplicationRecord
  belongs_to :story_group
  belongs_to :activity_group_template

  has_many :activity_group_categories, -> { order(:position) }, dependent: :destroy

  accepts_nested_attributes_for :activity_group_categories, allow_destroy: true

  validates :name, presence: { message: 'Podaj nazwę arkusza.' }, length: { maximum: 100 }
  # Only on the settings form. Elsewhere a sheet is built by copying a
  # template's columns, and the copy happens around the save — holding every
  # programmatic path to this rule would say a sheet may never exist without
  # columns, which is not what the rule is for.
  validate :at_least_one_visible_category, on: :settings

  # Soft delete (DECISIONS.md:54). NOT a default_scope: Redesign::CurrencyLedger
  # has to go on naming the column a deleted sheet's award came from, because
  # the student keeps the currency and keeps the history entry.
  scope :kept,    -> { where(deleted_at: nil) }
  scope :deleted, -> { where.not(deleted_at: nil) }

  scope :newest_first, -> { order(created_at: :desc, id: :desc) }

  def deleted? = deleted_at.present?

  # Skips validations for the same reason Badge#soft_delete! does: a sheet
  # written before a rule existed must still be deletable.
  def soft_delete!
    update_column(:deleted_at, Time.current)
  end

  def columns_modified? = columns_modified_at.present?

  def visible_categories = activity_group_categories.reject(&:hidden?)

  # The ceiling shown as "do N marchewek na studenta za arkusz".
  def max_reward = visible_categories.sum { |category| category.reward.to_i }

  class << self
    def next_name_for_template(template)
      next_names_for_template(template, 1).first
    end

    # The names the next `count` sheets from this template will get. One source
    # for the dialog's live chip list and for ActivityGroupBuilder#build_many,
    # so the preview cannot disagree with what is actually created.
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

  # A sheet whose every column is hidden or deleted has no grading table left
  # to open, so the form refuses it rather than leaving a dead "Oceń" button on
  # the index.
  def at_least_one_visible_category
    return if activity_group_categories.any? { |category| !category.marked_for_destruction? && !category.hidden? }

    errors.add(:base, 'Dodaj co najmniej jedną widoczną kategorię.')
  end
end
