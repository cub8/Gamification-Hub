# frozen_string_literal: true

class HomeController < ApplicationController
  include RedesignLayout

  # The landing screen after login. Two different screens behind one route,
  # mirroring StoryGroupsController#show: the view dispatches on the role, the
  # controller loads the matching dashboard.
  def index
    @dashboard =
      if current_user.teacher?
        TeacherStartDashboard.new(user: current_user, filter: params[:group]).load
      else
        StudentStartDashboard.new(user: current_user).load
      end
  end
end
