# frozen_string_literal: true

require 'test_helper'

class StudentListTest < ActiveSupport::TestCase
  setup do
    @owner       = FactoryBot.create(:user, role: :teacher)
    @story_group = FactoryBot.create(:story_group, owner: @owner, currency_name: 'marchewki')
  end

  def student(name:, nickname: nil, total: 0, lives: 3)
    user = FactoryBot.create(:user, role: :student, full_name: "#{name} Testowy")

    FactoryBot.create(:story_group_student, user: user, story_group: @story_group,
                                            nickname: nickname, lives: lives,
                                            current_currency: total, total_currency: total,)
  end

  def rank(name:, threshold:, discount: 0)
    FactoryBot.create(:rank, story_group: @story_group, name: name,
                             required_currency_value: threshold, discount: discount,)
  end

  def list = StudentList.new(story_group: @story_group)

  # The real name, because that is what the list prints and sorts by — the
  # nickname only reaches the sub-line.
  def full_names = list.rows.map { |row| row.student.full_name }

  def given_names = full_names.map { |name| name.split.first }

  def rank_names = list.rows.map { |row| row.rank&.name }

  test 'is empty in a group nobody has joined' do
    assert_not list.any?
    assert_equal 0, list.size
    assert_equal 0, list.zero_lives
  end

  test 'reads by display name, folding case and diacritics' do
    student(name: 'Zofia')
    student(name: 'Łukasz')
    student(name: 'Anna')

    assert_equal %w[Anna Łukasz Zofia], given_names
  end

  test 'sorts by the real name even when there is a nickname, because that is what is shown' do
    student(name: 'Anna', nickname: 'Zorro')
    student(name: 'Zofia', nickname: 'Albatros')

    assert_equal %w[Anna Zofia], given_names
  end

  test 'gives each student the highest rung they have reached' do
    rank(name: 'Rekrut', threshold: 0)
    rank(name: 'Kapitan', threshold: 50)
    rank(name: 'Admirał', threshold: 200)

    student(name: 'Anna', total: 0)
    student(name: 'Basia', total: 60)
    student(name: 'Celina', total: 500)

    assert_equal %w[Rekrut Kapitan Admirał], rank_names
  end

  test 'leaves the rank nil in a group with no ladder' do
    student(name: 'Anna', total: 100)

    assert_nil list.rows.first.rank
  end

  test 'counts badges per student' do
    anna  = student(name: 'Anna')
    basia = student(name: 'Basia')

    2.times do |i|
      badge = FactoryBot.create(:badge, story_group: @story_group, name: "Odznaka #{i}")
      FactoryBot.create(:students_badge, story_group_student: anna, badge: badge)
    end

    assert_equal [2, 0], list.rows.map(&:badge_count)
    assert_equal basia.id, list.rows.last.student.id
  end

  test 'counts who is out of lives' do
    student(name: 'Anna', lives: 0)
    student(name: 'Basia', lives: 2)
    student(name: 'Celina', lives: 0)

    assert_equal 2, list.zero_lives
    assert_equal [true, false, true], list.rows.map(&:zero_lives?)
  end

  test 'resolves every row without a query per student' do
    rank(name: 'Rekrut', threshold: 0)
    rank(name: 'Kapitan', threshold: 50)
    badge = FactoryBot.create(:badge, story_group: @story_group, name: 'Nawigator')

    8.times do |i|
      member = student(name: "Student#{i}", total: i * 20)
      FactoryBot.create(:students_badge, story_group_student: member, badge: badge)
    end

    subject = list
    queries = count_queries { subject.rows.each { |row| [row.rank&.name, row.badge_count] } }

    assert_operator queries, :<=, 4, "expected a fixed number of queries, ran #{queries}"
  end

  def count_queries(&)
    count = 0
    counter = ->(_name, _start, _finish, _id, payload) { count += 1 unless payload[:name] == 'SCHEMA' }

    ActiveSupport::Notifications.subscribed(counter, 'sql.active_record', &)
    count
  end
end
