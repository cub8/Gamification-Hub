# frozen_string_literal: true

class HomeController < ApplicationController
  helper OrganizationsHelper

  def index
    @dashboard = Dashboard.for(current_user, params: params)
  end
end
