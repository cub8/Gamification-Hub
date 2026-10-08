# frozen_string_literal: true

module Sidebar
  included do
    before_action :set_sidebar_state
  end

  protected

  def set_sidebar_state
    @sidebar_collapsed = cookies[:sidebar_collapsed] == 'true'
  end
end
