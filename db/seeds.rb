# frozen_string_literal: true

return unless Rails.env.development?

require_relative 'seeds/base'
Dir[Rails.root.join('db/seeds/*.rb')].each { |file| require file }

Seeds::Users.call
Seeds::StoryGroups.call
Seeds::Ranks.call
Seeds::Badges.call
Seeds::Items.call
Seeds::ActivityGroupTemplates.call
