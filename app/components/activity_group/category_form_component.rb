# frozen_string_literal: true

class ActivityGroup::CategoryFormComponent < ViewComponent::Base
  attr_accessor :f

  def initialize(f:, partial_save: false)
    @f = f
    @partial_save = partial_save
  end
end
