# frozen_string_literal: true

module SoftDeletable
  extend ActiveSupport::Concern

  included do
    scope :kept,    -> { where(deleted_at: nil) }
    scope :deleted, -> { where.not(deleted_at: nil) }
  end

  def deleted? = deleted_at.present?

  def soft_delete!
    update_column(:deleted_at, Time.current)
  end
end
