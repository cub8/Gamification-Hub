# frozen_string_literal: true

class RootController < ApplicationController
  skip_before_action :authenticate!

  def index
    return redirect_to home_path if session[:user]

    redirect_to login_path
  end
end
