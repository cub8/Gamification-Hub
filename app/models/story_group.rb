# frozen_string_literal: true

class StoryGroup < ApplicationRecord
  belongs_to :owner, class_name: 'User', foreign_key: 'owner_id'
  has_many :items, dependent: :destroy
  has_many :ranks, dependent: :destroy
  has_many :badges, dependent: :destroy
  has_many :student_memberships, class_name: 'StoryGroupStudent', foreign_key: 'story_group_id', dependent: :destroy
  has_many :teacher_memberships, class_name: 'StoryGroupTeacher', foreign_key: 'story_group_id', dependent: :destroy
  has_many :students, through: :student_memberships, source: :user
  has_many :teachers, through: :teacher_memberships, source: :user
  has_one_attached :icon
  has_one_attached :currency_icon
  has_many :items, dependent: :destroy
  has_many :activity_group_templates, dependent: :destroy
  has_many :activity_groups, dependent: :destroy

  validates :name, :currency_name, length: { maximum: 40 }
  validates :description, length: { maximum: 255 }
  validate :acceptable_icon
  validate :acceptable_currency_icon

  # Te akceptowalne pliki obrazów raczej do zmiany, na razie tak przykładowo
  def acceptable_icon
    return unless icon.attached?

    acceptable_types = ['image/gif', 'image/jpeg', 'image/png']
    return if acceptable_types.include?(icon.content_type)

    errors.add(:icon, 'must be a GIF, JPG or PNG image')
  end

  def acceptable_currency_icon
    return unless currency_icon.attached?

    acceptable_types = ['image/gif', 'image/jpeg', 'image/png']
    return if acceptable_types.include?(currency_icon.content_type)

    errors.add(:currency_icon, 'must be a GIF, JPG or PNG image')
  end
end
