# frozen_string_literal: true

class SessionsController < ApplicationController
  include LoggedUserRedirector

  skip_before_action :authenticate!, only: :new
  before_action :redirect_logged_user, only: :new

  def new; end

  def destroy
    reset_session
    redirect_to root_path
  end
end
