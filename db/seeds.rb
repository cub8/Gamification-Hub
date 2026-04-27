# frozen_string_literal: true

# rubocop:disable Style/TopLevelMethodDefinition

return unless Rails.env.development?

def build_students
  puts 'Building students'

  students = [
    { email: 'jan.nowak@example.com', full_name: 'Jan Nowak', university_number: 's123456' },
    { email: 'jacek.kowalski@example.com', full_name: 'Jacek Kowalski', university_number: 's123457' },
    { email: 'monika.szczepaniak@example.com', full_name: 'Monika Szczepaniak', university_number: 's123458' },
    { email: 'filip.jaskolka@example.com', full_name: 'Filip Jaskółka', university_number: 's123459' },
    { email: 'julia.kaznodzieja@example.com', full_name: 'Julia Kaznodzieja', university_number: 's123460' },
    { email: 'anna.wisniewska@example.com', full_name: 'Anna Wiśniewska', university_number: 's123461' },
    { email: 'piotr.zielinski@example.com', full_name: 'Piotr Zieliński', university_number: 's123462' },
    { email: 'katarzyna.wozniak@example.com', full_name: 'Katarzyna Woźniak', university_number: 's123463' },
    { email: 'marek.lewandowski@example.com', full_name: 'Marek Lewandowski', university_number: 's123464' },
  ]

  students.each do |student_data|
    next if User.exists?(email: student_data[:email])

    FactoryBot.create(
      :user,
      :student,
      **student_data,
      usos_id: nil,
    )
  end

  puts ' - Finished building students'
end

def build_teachers
  puts 'Building teachers'

  teachers = [
    { email: 'tomasz.nowakowski@example.com', full_name: 'Tomasz Nowakowski', university_number: 't123456' },
    { email: 'barbara.kowalczyk@example.com', full_name: 'Barbara Kowalczyk', university_number: 't123457' },
    { email: 'andrzej.wozniak@example.com', full_name: 'Andrzej Woźniak', university_number: 't123458' },
    { email: 'elzbieta.mazur@example.com', full_name: 'Elżbieta Mazur', university_number: 't123459' },
    { email: 'mariusz.kaczmarek@example.com', full_name: 'Mariusz Kaczmarek', university_number: 't123460' },
  ]

  teachers.each do |teacher_data|
    next if User.exists?(email: teacher_data[:email])

    FactoryBot.create(
      :user,
      :teacher,
      **teacher_data,
      usos_id: nil,
    )
  end

  puts ' - Finished building teachers'
end

def build_admins
  puts 'Building admins'

  admins = [
    {
      email:             'pawel.wisniewski@example.com',
      full_name:         'Paweł Wiśniewski',
      university_number: 'a123456',
      trait:             :organization_admin,
    },
    {
      email:             'malgorzata.lewandowska@example.com',
      full_name:         'Małgorzata Lewandowska',
      university_number: 'a123457',
      trait:             :global_admin,
    },
  ]

  admins.each do |admin_data|
    next if User.exists?(email: admin_data[:email])

    trait = admin_data.delete(:trait)
    FactoryBot.create(
      :user,
      trait,
      **admin_data,
      usos_id: nil,
    )
  end

  puts ' - Finished building admins'
end

def build_story_group
  puts 'Building story group'

  owner = User.find_by(email: 'tomasz.nowakowski@example.com')
  teachers = [
    User.find_by(email: 'barbara.kowalczyk@example.com'),
    User.find_by(email: 'andrzej.wozniak@example.com'),
  ]
  students = User.where(role: :student).first(5) + [User.where(role: :teacher).last!]
  description = <<~DESC
    Galaktyka jest wielka, ale nasze uszy są większe!
    Dołącz do pionierów, którzy zamienili nory na stacje orbitalne.
    Walczymy o prestiż, przetrwanie i pełne brzuchy, zbierając Złote Marchewki w świecie, gdzie grawitacja to tylko sugestia.
    Pamiętaj: w kosmosie nikt nie usłyszy Twojego chrupania... chyba że zapomnisz wyłączyć interkom
  DESC

  story_group = FactoryBot.create(
    :story_group,
    owner:         owner,
    name:          'Kosmiczne króliki',
    description:   description,
    currency_name: 'Złota Marchewka',
    default_lives: 3,
  )

  story_group.teachers << teachers
  story_group.students << students

  icon_path = Rails.root.join('db', 'seeds', 'images', 'space-bunnies.jpg')
  currency_icon_path = Rails.root.join('db', 'seeds', 'images', 'golden_carrot.png')

  story_group.icon.attach(
    io:           File.open(icon_path),
    filename:     'space-bunnies.jpg',
    content_type: 'image/jpeg',
  )

  story_group.currency_icon.attach(
    io:           File.open(currency_icon_path),
    filename:     'golden_carrot.png',
    content_type: 'image/png',
  )

  puts '- Finished building story group'

  story_group
end

def build_ranks
  story_group = StoryGroup.find_by!(name: 'Kosmiczne króliki')

  FactoryBot.create(
    :rank,
    story_group:             story_group,
    name:                    'Rekrut',
    required_currency_value: 0,
    discount:                0,
  )

  FactoryBot.create(
    :rank,
    story_group:             story_group,
    name:                    'Kosmiczny Królik',
    required_currency_value: 40,
    discount:                3,
  )

  FactoryBot.create(
    :rank,
    story_group:             story_group,
    name:                    'Pilot Marcheton-7',
    required_currency_value: 80,
    discount:                5,
  )

  FactoryBot.create(
    :rank,
    story_group:             story_group,
    name:                    'Strateg Imperium',
    required_currency_value: 130,
    discount:                10,
  )

  FactoryBot.create(
    :rank,
    story_group:             story_group,
    name:                    'Mistrz Marchewki',
    required_currency_value: 190,
    discount:                20,
  )
end

def build_badges
  story_group = StoryGroup.find_by!(name: 'Kosmiczne króliki')

  FactoryBot.create(
    :badge,
    story_group:          story_group,
    name:                 'Dzielny Królik',
    discount:             2,
    story_description:    'Królik nie uciekł z pola misji',
    didactic_description: 'Niezaliczona wejściówka, ale zdobyte co najmniej 4 marchewki łącznie w innych kategoriach na danym laboratorium',
  )

  FactoryBot.create(
    :badge,
    story_group:          story_group,
    name:                 'Zawsze na pokładzie',
    discount:             3,
    story_description:    'Rekrut nigdy nie opuścił statku',
    didactic_description: 'Co najmniej 26 marchewek za obecność',
  )

  FactoryBot.create(
    :badge,
    story_group:          story_group,
    name:                 'Złota Marchewka',
    discount:             2,
    story_description:    'Idealna misja',
    didactic_description: 'Pierwszy raz wejściówka bez błędów',
  )

  FactoryBot.create(
    :badge,
    story_group:          story_group,
    name:                 'Strateg Floty',
    discount:             3,
    story_description:    'Dowództwo zauważyło skuteczność',
    didactic_description: 'Co najmniej 3 wejściówki z rzędu ≥ średnia grupy',
  )

  FactoryBot.create(
    :badge,
    story_group:          story_group,
    name:                 'Perfekcyjny Lot',
    discount:             5,
    story_description:    'Lot bez najmniejszej rysy',
    didactic_description: 'Co najmniej 3 wejściówki z rzędu bez błędów',
  )

  FactoryBot.create(
    :badge,
    story_group:          story_group,
    name:                 'Mechanik Załogi',
    discount:             2,
    story_description:    'Królik naprawiał cudze statki',
    didactic_description: 'Zdobyte co najmniej 3 marchewki za pomoc innym',
  )

  FactoryBot.create(
    :badge,
    story_group:          story_group,
    name:                 'Agent Chaosu',
    discount:             2,
    story_description:    'Rekrut zrobił coś „po króliczemu”',
    didactic_description: 'Zdobyte co najmniej 3 marchewki za ciekawą uwagę',
  )

  FactoryBot.create(
    :badge,
    story_group:          story_group,
    name:                 'Królik Drużynowy',
    discount:             3,
    story_description:    'Królik uratował załogę',
    didactic_description: 'Wyjaśnienie jakiegoś trudnego zagadnienia/zadania całej grupie',
  )
end

def build_items
  story_group = StoryGroup.find_by!(name: 'Kosmiczne króliki')
  pilot_marcheton = Rank.find_by!(name: 'Pilot Marcheton-7')
  strateg_imperium = Rank.find_by!(name: 'Strateg Imperium')
  kosmiczny_krolik = Rank.find_by!(name: 'Kosmiczny Królik')
  mistrz_marchewki = Rank.find_by!(name: 'Mistrz Marchewki')

  FactoryBot.create(
    :item,
    story_group:           story_group,
    name:                  '0.5% oceny',
    story_description:     'Najwyższa Rada Królików przyznaje specjalną nagrodę za szczególne zasługi',
    didactic_description:  'Podniesienie oceny POZYTYWNEJ o pół stopnia',
    min_rank_for_discount: mistrz_marchewki,
    unlock_rank:           strateg_imperium,
    unlock_badges:         [Badge.find_by!(name: 'Zawsze na pokładzie')],
    price:                 80,
  )

  FactoryBot.create(
    :item,
    story_group:           story_group,
    name:                  '+3% do oceny',
    story_description:     'Wielka Marchewka dodaje królikowi punktów mocy',
    didactic_description:  '+3 punkty procentowe do ogólnego wyniku studenta/studentki',
    price:                 80,
    unlock_rank:           pilot_marcheton,
    min_rank_for_discount: strateg_imperium,
  )

  FactoryBot.create(
    :item,
    story_group:          story_group,
    name:                 'Zaliczenie wejściówki',
    story_description:    'Statek wrócił z misji uszkodzony, ale wrócił',
    didactic_description: 'Zaliczenie słabo napisanej wejściówki na 50%',
    price:                35,
  )

  FactoryBot.create(
    :item,
    story_group:          story_group,
    name:                 '+10% do wejściówki',
    story_description:    'Wsparcie dowództwa królików',
    didactic_description: '+10 punktów procentowych do wejściówki (do maksymalnie 100% w wyniku)',
    price:                33,
  )

  FactoryBot.create(
    :item,
    story_group:          story_group,
    name:                 '+5% do wejściówki',
    story_description:    'Flota dosyła dodatkowe zapasy',
    didactic_description: '+5 punktów procentowych do wejściówki (do maksymalnie 100% w wyniku)',
    price:                30,
  )

  FactoryBot.create(
    :item,
    story_group:          story_group,
    name:                 '+5 minut do wejściówki',
    story_description:    'Spowolnienie czasu w nadprzestrzeni',
    didactic_description: 'Dodatkowe 5 minut na wejściówce',
    price:                15,
  )

  FactoryBot.create(
    :item,
    story_group:          story_group,
    name:                 'Konsultacja',
    story_description:    'Konsultacja z Mistrzem Królików',
    didactic_description: 'Możliwość zadania pytania (nie wprost o prawidłową odpowiedź) prowadzącego podczas wejściówki',
    price:                15,
  )

  FactoryBot.create(
    :item,
    story_group:          story_group,
    name:                 'Poprawa wejściówki',
    story_description:    'Awaryjny powrót statku do bazy',
    didactic_description: 'Możliwość ponownego napisania (poprawy) wejściówki',
    price:                15,
  )

  FactoryBot.create(
    :item,
    story_group:          story_group,
    name:                 'Bezpieczna poprawa',
    story_description:    'Statek trafia do hangaru ochronnego',
    didactic_description: 'Możliwość ponownego napisania (poprawy) wejściówki z zamrożeniem obecnego wyniku (czyli nie można pogorszyć wyniku)',
    price:                20,
  )

  FactoryBot.create(
    :item,
    story_group:           story_group,
    name:                  'Poprawa trzech wejściówek',
    story_description:     'W statku trzeba naprawić kilka modułów',
    didactic_description:  'Możliwość ponownego napisania (poprawy) trzech wybranych wejściówek',
    price:                 40,
    unlock_rank:           kosmiczny_krolik,
    min_rank_for_discount: pilot_marcheton,
  )

  FactoryBot.create(
    :item,
    story_group:           story_group,
    name:                  'Bezpieczna poprawa trzech wejściówek',
    story_description:     'W statku trzeba naprawić kilka modułów i na ten czas królik otrzymuje statek zastępczy',
    didactic_description:  'Możliwość ponownego napisania (poprawy) trzech wybranych z zamrożeniem obecnego wyniku (czyli nie można pogorszyć wyniku)',
    price:                 50,
    unlock_rank:           kosmiczny_krolik,
    min_rank_for_discount: pilot_marcheton,
  )

  FactoryBot.create(
    :item,
    story_group:           story_group,
    name:                  'Spóźnienie',
    story_description:     'Teleporter działał z opóźnieniem',
    didactic_description:  'Jedno spóźnienie bez straty marchewek za punktualność',
    price:                 5,
    unlock_rank:           kosmiczny_krolik,
    min_rank_for_discount: pilot_marcheton,
  )

  FactoryBot.create(
    :item,
    story_group:           story_group,
    name:                  'Usprawiedliwienie',
    story_description:     'Misja zdalna dla floty',
    didactic_description:  'Jedna usprawiedliwiona nieobecność bez straty marchewek za obecność i punktualność',
    price:                 10,
    unlock_rank:           kosmiczny_krolik,
    min_rank_for_discount: pilot_marcheton,
  )

  FactoryBot.create(
    :item,
    story_group:           story_group,
    name:                  '1up',
    story_description:     'Reanimacja królika',
    didactic_description:  'Odzzyskanie jednego życia w ramach grywalizacji - kontynuacja gry',
    price:                 50,
    min_rank_for_discount: mistrz_marchewki,
    can_buy_at_0_lives:    true,
  )
end

def build_activity_group_templates
  story_group = StoryGroup.find_by!(name: 'Kosmiczne króliki')

  FactoryBot.create(
    :activity_group_template,
    story_group: story_group,
    base_name:   'Laboratoria',
    categories:  [
      FactoryBot.build(
        :activity_group_template_category,
        story_description:    'Rekrut stawił się na zbiórce floty króliczej i nie zgubił się w nadprzestrzeni.',
        didactic_description: 'Punktualny/a',
        reward:               2,
      ),
      FactoryBot.build(
        :activity_group_template_category,
        story_description:    'Rekrut dotarł po starcie statku, ale doleciał.',
        didactic_description: 'Obecny/a',
        reward:               2,
      ),
      FactoryBot.build(
        :activity_group_template_category,
        story_description:    'Misja zakończona sukcesem – statek wrócił do bazy.',
        didactic_description: 'Wejściówka zaliczona',
        reward:               1,
      ),
      FactoryBot.build(
        :activity_group_template_category,
        story_description:    'Rekrut wykonał zadanie zgodnie z normami floty.',
        didactic_description: 'Wejściówka na poziomie co najmniej średniej grupy',
        reward:               1,
      ),
      FactoryBot.build(
        :activity_group_template_category,
        story_description:    'Misja wykonana perfekcyjnie – bez strat i uszkodzeń statku.',
        didactic_description: 'Wejściówka na maxa',
        reward:               2,
      ),
      FactoryBot.build(
        :activity_group_template_category,
        story_description:    'Rekrut zgłosił się do wykonania misji pomocniczej na statku.',
        didactic_description: 'Zgłoszenie się do zrobienia zadania',
        reward:               1,
      ),
      FactoryBot.build(
        :activity_group_template_category,
        story_description:    'Rekrut samodzielnie naprawił zepsuty moduł statku — statek może lecieć dalej.',
        didactic_description: 'Samodzielnie i poprawnie zrobione zadanie',
        reward:               1,
      ),
      FactoryBot.build(
        :activity_group_template_category,
        story_description:    'Rekrut uratował innego królika przed dryfowaniem w próżni.',
        didactic_description: 'Pomoc innym',
        reward:               1,
      ),
      FactoryBot.build(
        :activity_group_template_category,
        story_description:    'Rekrut odkrył nieznane zjawisko kosmiczne.',
        didactic_description: 'Ciekawa uwaga',
        reward:               1,
      ),
      FactoryBot.build(
        :activity_group_template_category,
        story_description:    'Rekrut udzielał się w naradzie załogi.',
        didactic_description: 'Udział w dyskusji',
        reward:               1,
      ),
      FactoryBot.build(
        :activity_group_template_category,
        story_description:    'Rekrut przedstawił raport z obserwacji podczas misji.',
        didactic_description: 'Odpowiedź na pytanie wiedzy prowadzącego',
        reward:               1,
      ),
    ],
  )

  FactoryBot.create(
    :activity_group_template,
    story_group: story_group,
    base_name:   'Podsumowanie',
    categories:  [
      FactoryBot.build(
        :activity_group_template_category,
        story_description:    'Rekrut nie opuścił ani jednej misji',
        didactic_description: 'Punktualny/a zawsze',
        reward:               3,
      ),
      FactoryBot.build(
        :activity_group_template_category,
        story_description:    'Rekrut prawie zawsze był na posterunku',
        didactic_description: 'Obecny/a i prawie zawsze punktualny/a (1 spóźnienie)',
        reward:               2,
      ),
      FactoryBot.build(
        :activity_group_template_category,
        story_description:    'Flota działała bez przerw',
        didactic_description: 'Wszystkie wejściówki zaliczone',
        reward:               2,
      ),
      FactoryBot.build(
        :activity_group_template_category,
        story_description:    'Rekrut trzymał wysoki poziom misji',
        didactic_description: 'Wszystkie wejściówki >= średnia grupy',
        reward:               3,
      ),
      FactoryBot.build(
        :activity_group_template_category,
        story_description:    'Co najmniej jedna misja wykonana idealnie',
        didactic_description: 'Co najmniej jedna wejściówka bez błędów',
        reward:               1,
      ),
      FactoryBot.build(
        :activity_group_template_category,
        story_description:    'Miesiąc perfekcyjnych lotów',
        didactic_description: 'Wszystkie wejściówki bez błędów',
        reward:               4,
      ),
    ],
  )
end

build_students
build_teachers
build_admins
build_story_group
build_ranks
build_badges
build_items
build_activity_group_templates

# rubocop:enable Style/TopLevelMethodDefinition
