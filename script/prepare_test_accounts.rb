# frozen_string_literal: true

teachers_data = [
  # fill with actual data
].freeze

students_data = [
  # fill with actual data
].freeze

teachers_data.each do |teacher|
  next if User.exists?(email: teacher[:email])

  User.create!(
    email:             teacher[:email],
    full_name:         teacher[:full_name],
    university_number: teacher[:university_number],
    usos_id:           nil,
    university_name:   'Test University',
    role:              'teacher',
  )
end

students_data.each do |student|
  next if User.exists?(email: student[:email])

  User.create!(
    email:             student[:email],
    full_name:         student[:full_name],
    university_number: student[:university_number],
    usos_id:           nil,
    university_name:   'Test University',
    role:              'student',
  )
end
