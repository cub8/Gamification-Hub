# frozen_string_literal: true

class User < ApplicationRecord
  enum :role, {
    student:            1,
    teacher:            2,
    organization_admin: 3,
    global_admin:       4,
  }

  INVITABLE_ROLES = %w[student teacher].freeze

  has_many :student_memberships, class_name: 'StoryGroupStudent', foreign_key: 'user_id', dependent: :destroy
  has_many :teacher_memberships, class_name: 'StoryGroupTeacher', foreign_key: 'user_id', dependent: :destroy
  has_many :owner_story_groups, class_name: 'StoryGroup', foreign_key: 'owner_id', dependent: :destroy
  has_many :student_story_groups, through: :student_memberships, source: :story_group
  has_many :teacher_story_groups, through: :teacher_memberships, source: :story_group
  has_many :notifications, dependent: :destroy
  # Currency history outlives whoever granted it.
  has_many :granted_currency_transactions, class_name: 'CurrencyTransaction', foreign_key: 'granted_by_user_id',
                                           dependent: :nullify, inverse_of: :granted_by_user
  has_one :login_token, dependent: :destroy

  belongs_to :organization, optional: true

  normalizes :email, with: ->(email) { email.strip.downcase }

  validates :email, length: { maximum: 255 }, uniqueness: true, allow_nil: true
  validates :usos_id, uniqueness: { scope: :university_name }, allow_nil: true
  validates :university_number, length: { maximum: 20 }
  validates :full_name, length: { maximum: 80 }
  validates :university_name, length: { maximum: 100 }
  validates_presence_of :email, :full_name, on: :account_setup
  validates_presence_of :email, on: :admin_invitation
  validates_presence_of :email, :full_name, on: :user_invitation
  validates :role, inclusion: { in: INVITABLE_ROLES }, on: :user_invitation
  validate :organization_has_free_slot, if: :will_save_change_to_organization_id?

  encrypts :email, deterministic: true
  encrypts :university_number, deterministic: true
  encrypts :full_name, deterministic: true

  def all_story_groups
    (owner_story_groups + student_story_groups + teacher_story_groups).uniq
  end

  def administers?(story_group)
    organization_admin? && organization_id.present? &&
      story_group.owner&.organization_id == organization_id
  end

  def needs_account_setup?
    organization_admin? && first_login?
  end

  def create_login_token!(expires_in: LoginToken::EXPIRES_IN)
    consume_login_token!
    LoginToken.create!(user: self, expires_at: expires_in.from_now)
  end

  def consume_login_token!
    login_token&.destroy!
  end

  private

  def organization_has_free_slot
    errors.add(:organization, :member_limit) if organization&.full?
  end
end
