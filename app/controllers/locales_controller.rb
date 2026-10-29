# frozen_string_literal: true

class LocalesController < ApplicationController
  skip_before_action :authenticate!

  def update
    locale = params[:locale].to_s
    cookies.permanent[Localization::LOCALE_COOKIE] = locale if available_locale?(locale)

    redirect_back_or_to root_path, status: :see_other
  end
end
