# frozen_string_literal: true

module Seeds
  class ActivityGroupTemplates < Base
    LABORATORIES_CATEGORIES = [
      {
        story_description:    'Rekrut stawił się na zbiórce floty króliczej i nie zgubił się w nadprzestrzeni.',
        didactic_description: 'Punktualny/a',
        reward:               2,
      },
      {
        story_description:    'Rekrut dotarł po starcie statku, ale doleciał.',
        didactic_description: 'Obecny/a',
        reward:               2,
      },
      {
        story_description:    'Misja zakończona sukcesem – statek wrócił do bazy.',
        didactic_description: 'Wejściówka zaliczona',
        reward:               1,
      },
      {
        story_description:    'Rekrut wykonał zadanie zgodnie z normami floty.',
        didactic_description: 'Wejściówka na poziomie co najmniej średniej grupy',
        reward:               1,
      },
      {
        story_description:    'Misja wykonana perfekcyjnie – bez strat i uszkodzeń statku.',
        didactic_description: 'Wejściówka na maxa',
        reward:               2,
      },
      {
        story_description:    'Rekrut zgłosił się do wykonania misji pomocniczej na statku.',
        didactic_description: 'Zgłoszenie się do zrobienia zadania',
        reward:               1,
      },
      {
        story_description:    'Rekrut samodzielnie naprawił zepsuty moduł statku — statek może lecieć dalej.',
        didactic_description: 'Samodzielnie i poprawnie zrobione zadanie',
        reward:               1,
      },
      {
        story_description:    'Rekrut uratował innego królika przed dryfowaniem w próżni.',
        didactic_description: 'Pomoc innym',
        reward:               1,
      },
      {
        story_description:    'Rekrut odkrył nieznane zjawisko kosmiczne.',
        didactic_description: 'Ciekawa uwaga',
        reward:               1,
      },
      {
        story_description:    'Rekrut udzielał się w naradzie załogi.',
        didactic_description: 'Udział w dyskusji',
        reward:               1,
      },
      {
        story_description:    'Rekrut przedstawił raport z obserwacji podczas misji.',
        didactic_description: 'Odpowiedź na pytanie wiedzy prowadzącego',
        reward:               1,
      },
    ].freeze

    SUMMARY_CATEGORIES = [
      {
        story_description:    'Rekrut nie opuścił ani jednej misji',
        didactic_description: 'Punktualny/a zawsze',
        reward:               3,
      },
      {
        story_description:    'Rekrut prawie zawsze był na posterunku',
        didactic_description: 'Obecny/a i prawie zawsze punktualny/a (1 spóźnienie)',
        reward:               2,
      },
      {
        story_description:    'Flota działała bez przerw',
        didactic_description: 'Wszystkie wejściówki zaliczone',
        reward:               2,
      },
      {
        story_description:    'Rekrut trzymał wysoki poziom misji',
        didactic_description: 'Wszystkie wejściówki >= średnia grupy',
        reward:               3,
      },
      {
        story_description:    'Co najmniej jedna misja wykonana idealnie',
        didactic_description: 'Co najmniej jedna wejściówka bez błędów',
        reward:               1,
      },
      {
        story_description:    'Miesiąc perfekcyjnych lotów',
        didactic_description: 'Wszystkie wejściówki bez błędów',
        reward:               4,
      },
    ].freeze

    def call
      log_start 'activity group templates'
      @story_group = StoryGroup.find_by!(name: 'Kosmiczne króliki')
      build_templates
      log_finish 'activity group templates'
    end

    private

    def build_templates
      templates_data.each do |data|
        next if ActivityGroupTemplate.exists?(story_group: @story_group, base_name: data[:base_name])

        FactoryBot.create(:activity_group_template, story_group: @story_group, **data)
      end
    end

    def templates_data
      [
        {
          base_name:  'Laboratoria',
          categories: LABORATORIES_CATEGORIES.map do |data|
            FactoryBot.build(:activity_group_template_category, **data)
          end,
        },
        {
          base_name:  'Podsumowanie',
          categories: SUMMARY_CATEGORIES.map do |data|
            FactoryBot.build(:activity_group_template_category, **data)
          end,
        },
      ]
    end
  end
end
