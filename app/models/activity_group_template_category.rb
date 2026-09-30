# frozen_string_literal: true

class ActivityGroupTemplateCategory < ApplicationRecord
  include RewardCategory

  belongs_to :activity_group_template
end
