# frozen_string_literal: true

class SessionsController < ApplicationController
  include LoggedUserRedirector
  include RedesignLayout

  skip_before_action :authenticate!, only: :new
  before_action :redirect_logged_user, only: :new
  before_action -> { @chrome = false }, only: :new

  def new; end

  def destroy
    reset_session
    redirect_to root_path
  end
end
