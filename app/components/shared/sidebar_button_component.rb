# frozen_string_literal: true

class Shared::SidebarButtonComponent < ViewComponent::Base
  attr_reader :current_path, :href, :text, :icon, :button_class, :role, :collapsed, :data

  def initialize(text, href, current_path:, icon:, role: nil, collapsed: false, data: {})
    @current_path = current_path
    @href = href
    @text = text
    @icon = icon
    @role = role
    @collapsed = collapsed
    @data = data
    @button_class = establish_button_class
  end

  private

  def tag_type
    href.present? ? :a : :button
  end

  def establish_button_class
    classes = []
    classes << (@current_path == @href ? 'btn-primary' : 'sidebar-idle-btn')
    classes << 'text-center' if collapsed
    classes.join(' ')
  end

  def tooltip_attributes
    return {} unless collapsed

    {
      data: {
        bs_toggle:    'tooltip',
        bs_placement: 'right',
        bs_title:     @text,
      },
    }
  end

  def merged_data_attributes
    tooltip_attributes.fetch(:data, {}).merge(data)
  end
end
