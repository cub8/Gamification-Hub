# frozen_string_literal: true

module Seeds
  class Items < Base
    def call
      log_start 'items'
      @story_group = StoryGroup.find_by!(name: 'Kosmiczne króliki')
      build_items
      log_finish 'items'
    end

    private

    def build_items
      items_data.each do |data|
        next if Item.exists?(story_group: @story_group, name: data[:name])

        FactoryBot.create(:item, story_group: @story_group, **data)
      end
    end

    def items_data
      [
        {
          name:                  '0.5% oceny',
          story_description:     'Najwyższa Rada Królików przyznaje specjalną nagrodę za szczególne zasługi',
          didactic_description:  'Podniesienie oceny POZYTYWNEJ o pół stopnia',
          min_rank_for_discount: Rank.find_by!(name: 'Mistrz Marchewki'),
          unlock_rank:           Rank.find_by!(name: 'Strateg Imperium'),
          unlock_badges:         [Badge.find_by!(name: 'Zawsze na pokładzie')],
          price:                 80,
        },
        {
          name:                  '+3% do oceny',
          story_description:     'Wielka Marchewka dodaje królikowi punktów mocy',
          didactic_description:  '+3 punkty procentowe do ogólnego wyniku studenta/studentki',
          price:                 80,
          unlock_rank:           Rank.find_by!(name: 'Pilot Marcheton-7'),
          min_rank_for_discount: Rank.find_by!(name: 'Strateg Imperium'),
        },
        {
          name:                 'Zaliczenie wejściówki',
          story_description:    'Statek wrócił z misji uszkodzony, ale wrócił',
          didactic_description: 'Zaliczenie słabo napisanej wejściówki na 50%',
          price:                35,
        },
        {
          name:                 '+10% do wejściówki',
          story_description:    'Wsparcie dowództwa królików',
          didactic_description: '+10 punktów procentowych do wejściówki (do maksymalnie 100% w wyniku)',
          price:                33,
        },
        {
          name:                 '+5% do wejściówki',
          story_description:    'Flota dosyła dodatkowe zapasy',
          didactic_description: '+5 punktów procentowych do wejściówki (do maksymalnie 100% w wyniku)',
          price:                30,
        },
        {
          name:                 '+5 minut do wejściówki',
          story_description:    'Spowolnienie czasu w nadprzestrzeni',
          didactic_description: 'Dodatkowe 5 minut na wejściówce',
          price:                15,
        },
        {
          name:                 'Konsultacja',
          story_description:    'Konsultacja z Mistrzem Królików',
          didactic_description: 'Możliwość zadania pytania (nie wprost o prawidłową odpowiedź) ' \
                                'prowadzącego podczas wejściówki',
          price:                15,
        },
        {
          name:                 'Poprawa wejściówki',
          story_description:    'Awaryjny powrót statku do bazy',
          didactic_description: 'Możliwość ponownego napisania (poprawy) wejściówki',
          price:                15,
        },
        {
          name:                 'Bezpieczna poprawa',
          story_description:    'Statek trafia do hangaru ochronnego',
          didactic_description: 'Możliwość ponownego napisania (poprawy) wejściówki z zamrożeniem ' \
                                'obecnego wyniku (czyli nie można pogorszyć wyniku)',
          price:                20,
        },
        {
          name:                  'Poprawa trzech wejściówek',
          story_description:     'W statku trzeba naprawić kilka modułów',
          didactic_description:  'Możliwość ponownego napisania (poprawy) trzech wybranych wejściówek',
          price:                 40,
          unlock_rank:           Rank.find_by!(name: 'Kosmiczny Królik'),
          min_rank_for_discount: Rank.find_by!(name: 'Pilot Marcheton-7'),
        },
        {
          name:                  'Bezpieczna poprawa trzech wejściówek',
          story_description:     'W statku trzeba naprawić kilka modułów i na ten czas królik ' \
                                 'otrzymuje statek zastępczy',
          didactic_description:  'Możliwość ponownego napisania (poprawy) trzech wybranych z ' \
                                 'zamrożeniem obecnego wyniku (czyli nie można pogorszyć wyniku)',
          price:                 50,
          unlock_rank:           Rank.find_by!(name: 'Kosmiczny Królik'),
          min_rank_for_discount: Rank.find_by!(name: 'Pilot Marcheton-7'),
        },
        {
          name:                  'Spóźnienie',
          story_description:     'Teleporter działał z opóźnieniem',
          didactic_description:  'Jedno spóźnienie bez straty marchewek za punktualność',
          price:                 5,
          unlock_rank:           Rank.find_by!(name: 'Kosmiczny Królik'),
          min_rank_for_discount: Rank.find_by!(name: 'Pilot Marcheton-7'),
        },
        {
          name:                  'Usprawiedliwienie',
          story_description:     'Misja zdalna dla floty',
          didactic_description:  'Jedna usprawiedliwiona nieobecność bez straty marchewek za obecność i punktualność',
          price:                 10,
          unlock_rank:           Rank.find_by!(name: 'Kosmiczny Królik'),
          min_rank_for_discount: Rank.find_by!(name: 'Pilot Marcheton-7'),
        },
        {
          name:                  '1up',
          story_description:     'Reanimacja królika',
          didactic_description:  'Odzzyskanie jednego życia w ramach grywalizacji - kontynuacja gry',
          price:                 50,
          min_rank_for_discount: Rank.find_by!(name: 'Mistrz Marchewki'),
          can_buy_at_0_lives:    true,
        },
      ]
    end
  end
end
