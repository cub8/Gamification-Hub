# frozen_string_literal: true

module Seeds
  class Users < Base
    STUDENTS = [
      { email: 'jan.nowak@example.com', full_name: 'Jan Nowak', university_number: 's123456' },
      { email: 'jacek.kowalski@example.com', full_name: 'Jacek Kowalski', university_number: 's123457' },
      { email: 'monika.szczepaniak@example.com', full_name: 'Monika Szczepaniak', university_number: 's123458' },
      { email: 'filip.jaskolka@example.com', full_name: 'Filip Jaskółka', university_number: 's123459' },
      { email: 'julia.kaznodzieja@example.com', full_name: 'Julia Kaznodzieja', university_number: 's123460' },
      { email: 'anna.wisniewska@example.com', full_name: 'Anna Wiśniewska', university_number: 's123461' },
      { email: 'piotr.zielinski@example.com', full_name: 'Piotr Zieliński', university_number: 's123462' },
      { email: 'katarzyna.wozniak@example.com', full_name: 'Katarzyna Woźniak', university_number: 's123463' },
      { email: 'marek.lewandowski@example.com', full_name: 'Marek Lewandowski', university_number: 's123464' },
      { email: 'magdalena.dabrowska@example.com', full_name: 'Magdalena Dąbrowska', university_number: 's123465' },
      { email: 'tomasz.mazur@example.com', full_name: 'Tomasz Mazur', university_number: 's123466' },
      {
        email:             'agnieszka.kwiatkowska@example.com',
        full_name:         'Agnieszka Kwiatkowska',
        university_number: 's123467',
      },
      { email: 'lukasz.krawczyk@example.com', full_name: 'Łukasz Krawczyk', university_number: 's123468' },
      { email: 'barbara.kaczmarek@example.com', full_name: 'Barbara Kaczmarek', university_number: 's123469' },
      { email: 'marcin.stepien@example.com', full_name: 'Marcin Stępień', university_number: 's123470' },
      { email: 'weronika.wojcik@example.com', full_name: 'Weronika Wójcik', university_number: 's123471' },
      { email: 'michal.pajak@example.com', full_name: 'Michał Pająk', university_number: 's123472' },
      { email: 'karolina.duda@example.com', full_name: 'Karolina Duda', university_number: 's123473' },
      { email: 'krzysztof.adamczyk@example.com', full_name: 'Krzysztof Adamczyk', university_number: 's123474' },
    ].freeze

    TEACHERS = [
      { email: 'tomasz.nowakowski@example.com', full_name: 'Tomasz Nowakowski', university_number: 't123456' },
      { email: 'barbara.kowalczyk@example.com', full_name: 'Barbara Kowalczyk', university_number: 't123457' },
      { email: 'andrzej.wozniak@example.com', full_name: 'Andrzej Woźniak', university_number: 't123458' },
      { email: 'elzbieta.mazur@example.com', full_name: 'Elżbieta Mazur', university_number: 't123459' },
      { email: 'mariusz.kaczmarek@example.com', full_name: 'Mariusz Kaczmarek', university_number: 't123460' },
    ].freeze

    ADMINS = [
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
    ].freeze

    def call
      build_students
      build_teachers
      build_admins
    end

    private

    def build_students
      log_start 'students'

      STUDENTS.each do |student_data|
        next if User.exists?(email: student_data[:email])

        FactoryBot.create(:user, :student, **student_data, usos_id: nil)
      end

      log_finish 'students'
    end

    def build_teachers
      log_start 'teachers'

      TEACHERS.each do |teacher_data|
        next if User.exists?(email: teacher_data[:email])

        FactoryBot.create(:user, :teacher, **teacher_data, usos_id: nil)
      end

      log_finish 'teachers'
    end

    def build_admins
      log_start 'admins'

      ADMINS.each do |admin_data|
        next if User.exists?(email: admin_data[:email])

        data = admin_data.dup
        trait = data.delete(:trait)
        FactoryBot.create(:user, trait, **data, usos_id: nil)
      end

      log_finish 'admins'
    end
  end
end
