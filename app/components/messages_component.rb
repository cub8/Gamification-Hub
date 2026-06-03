# frozen_string_literal: true

class MessagesComponent < ViewComponent::Base
  attr_reader :id, :flash, :notice, :alert

  def initialize(id:, flash:, notice: nil, alert: nil)
    @flash = flash
    @notice = notice
    @alert = alert
    @id = id
  end

  private

  def close_button
    helpers.button_tag '', { class: 'btn-close', data: { bs_dismiss: 'alert' }, 'aria-label' => 'Close' }
  end
end
