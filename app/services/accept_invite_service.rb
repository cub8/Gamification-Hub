# frozen_string_literal: true

class AcceptInviteService
  def initialize(user:, invite:)
    @current_user = user
    @invite = invite
    @story_group = @invite.story_group
  end

  def call
    result = { success: false }

    @invite.with_lock do
      ActiveRecord::Base.transaction do
        if @invite.usable?
          @invite.use!
          @story_group.student_memberships.build(user: @current_user).save!

          result[:success] = true
        end
      end
    end
    result
  end
end
