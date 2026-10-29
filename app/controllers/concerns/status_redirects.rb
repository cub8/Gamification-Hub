# frozen_string_literal: true

module StatusRedirects
  protected

  def record_not_found
    redirect_to root_path, alert: t('application.flash.not_found')
  end

  def not_authorized
    redirect_to root_path, alert: t('application.flash.not_found')
  end
end
