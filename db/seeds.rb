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

build_students
build_teachers
build_admins
build_story_group
build_ranks
build_badges

# rubocop:enable Style/TopLevelMethodDefinition
