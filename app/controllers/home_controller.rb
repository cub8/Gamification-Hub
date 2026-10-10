# frozen_string_literal: true

class HomeController < ApplicationController
  helper OrganizationsHelper

  # The landing screen after login. One screen per role behind one route,
  # mirroring StoryGroupsController#show: the view dispatches on the role, the
  # controller loads the matching dashboard.
  def index
    @dashboard =
      if current_user.global_admin?
        GlobalAdminStartDashboard.new.load
      elsif current_user.organization_admin?
        OrganizationAdminStartDashboard.new(user: current_user).load
      elsif current_user.teacher?
        TeacherStartDashboard.new(user: current_user, filter: params[:group]).load
      else
        StudentStartDashboard.new(user: current_user).load
      end
  end
end
