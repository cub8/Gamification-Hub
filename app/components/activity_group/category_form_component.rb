# frozen_string_literal: true

class ActivityGroup::CategoryFormComponent < ViewComponent::Base
  attr_accessor :f

  def initialize(f:)
    @f = f
  end
end
