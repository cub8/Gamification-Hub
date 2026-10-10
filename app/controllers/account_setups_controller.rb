# frozen_string_literal: true

class AccountSetupsController < ApplicationController
  layout 'public'

  skip_before_action :require_account_setup!
  before_action :redirect_configured_user

  def edit; end

  def update
    @current_user.assign_attributes(account_setup_params)
    @current_user.first_login = false

    if @current_user.save(context: :account_setup)
      redirect_to home_path, notice: 'Pomyślnie skonfigurowano konto.'
    else
      @current_user.first_login = true
      render :edit, status: :unprocessable_content
    end
  end

  private

  def redirect_configured_user
    redirect_to home_path unless @current_user.needs_account_setup?
  end

  def account_setup_params
    params.expect(
      user: %i[
        full_name
      ],
    )
  end
end
