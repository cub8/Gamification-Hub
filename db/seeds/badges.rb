# frozen_string_literal: true

module Seeds
  class Badges < Base
    BADGES = [
      {
        name:                 'Dzielny Królik',
        discount:             2,
        story_description:    'Królik nie uciekł z pola misji',
        didactic_description: 'Niezaliczona wejściówka, ale zdobyte co najmniej 4 marchewki ' \
                              'łącznie w innych kategoriach na danym laboratorium',
      },
      {
        name:                 'Zawsze na pokładzie',
        discount:             3,
        story_description:    'Rekrut nigdy nie opuścił statku',
        didactic_description: 'Co najmniej 26 marchewek za obecność',
      },
      {
        name:                 'Złota Marchewka',
        discount:             2,
        story_description:    'Idealna misja',
        didactic_description: 'Pierwszy raz wejściówka bez błędów',
      },
      {
        name:                 'Strateg Floty',
        discount:             3,
        story_description:    'Dowództwo zauważyło skuteczność',
        didactic_description: 'Co najmniej 3 wejściówki z rzędu ≥ średnia grupy',
      },
      {
        name:                 'Perfekcyjny Lot',
        discount:             5,
        story_description:    'Lot bez najmniejszej rysy',
        didactic_description: 'Co najmniej 3 wejściówki z rzędu bez błędów',
      },
      {
        name:                 'Mechanik Załogi',
        discount:             2,
        story_description:    'Królik naprawiał cudze statki',
        didactic_description: 'Zdobyte co najmniej 3 marchewki za pomoc innym',
      },
      {
        name:                 'Agent Chaosu',
        discount:             2,
        story_description:    'Rekrut zrobił coś „po króliczemu”',
        didactic_description: 'Zdobyte co najmniej 3 marchewki za ciekawą uwagę',
      },
      {
        name:                 'Królik Drużynowy',
        discount:             3,
        story_description:    'Królik uratował załogę',
        didactic_description: 'Wyjaśnienie jakiegoś trudnego zagadnienia/zadania całej grupie',
      },
    ].freeze

    def call
      log_start 'badges'
      story_group = StoryGroup.find_by!(name: 'Kosmiczne króliki')

      BADGES.each do |badge_data|
        next if Badge.exists?(story_group: story_group, name: badge_data[:name])

        FactoryBot.create(:badge, story_group: story_group, **badge_data)
      end

      log_finish 'badges'
    end
  end
end
