# frozen_string_literal: true

class TeacherInvitation < ApplicationRecord
  LINK_EXPIRES_IN = 7.days

  belongs_to :story_group
  belongs_to :invited_by, class_name: 'User'

  normalizes :email, with: ->(email) { email.strip.downcase }
  encrypts :email, deterministic: true

  validates :email, presence: true, length: { maximum: 255 },
                    format: { with: URI::MailTo::EMAIL_REGEXP, allow_blank: true }
  validates :email, uniqueness: { scope: :story_group_id }

  scope :newest_first, -> { order(created_at: :desc, id: :desc) }

  class << self
    def find_by_accept_token(token)
      find_signed(token, purpose: :accept)
    end
  end

  def create_invitee!
    User.create!(email: email, role: :teacher, organization: story_group.owner&.organization)
  end

  def accept_token
    signed_id(purpose: :accept, expires_in: LINK_EXPIRES_IN)
  end
end
