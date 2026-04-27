# frozen_string_literal: true

module Seeds
  class Ranks < Base
    RANKS = [
      { name: 'Rekrut', required_currency_value: 0, discount: 0 },
      { name: 'Kosmiczny Królik', required_currency_value: 40, discount: 3 },
      { name: 'Pilot Marcheton-7', required_currency_value: 80, discount: 5 },
      { name: 'Strateg Imperium', required_currency_value: 130, discount: 10 },
      { name: 'Mistrz Marchewki', required_currency_value: 190, discount: 20 },
    ].freeze

    def call
      log_start 'ranks'
      story_group = StoryGroup.find_by!(name: 'Kosmiczne króliki')

      RANKS.each do |rank_data|
        next if Rank.exists?(story_group: story_group, name: rank_data[:name])

        FactoryBot.create(:rank, story_group: story_group, **rank_data)
      end

      log_finish 'ranks'
    end
  end
end
