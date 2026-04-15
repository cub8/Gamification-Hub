# frozen_string_literal: true

# rubocop:disable Style/TopLevelMethodDefinition

# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

return unless Rails.env.development?

def build_students
  print('Building students')

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

  puts(' - Finished building students')
end

def build_teachers
  print('Building teachers')

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

  puts(' - Finished building teachers')
end

def build_admins
  print('Building admins')

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

  puts(' - Finished building admins')
end

build_students
build_teachers
build_admins

# rubocop:enable Style/TopLevelMethodDefinition
