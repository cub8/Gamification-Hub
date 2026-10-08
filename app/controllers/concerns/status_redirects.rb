# frozen_string_literal: true

module StatusRedirects
  protected

  def record_not_found
    redirect_to root_path, alert: 'Nie znaleziono.'
  end

  def not_authorized
    redirect_to root_path, alert: 'Nie znaleziono.'
  end
end
