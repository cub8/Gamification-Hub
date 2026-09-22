# frozen_string_literal: true

require 'test_helper'

class TeacherPoolTest < ActiveSupport::TestCase
  setup do
    @owner       = FactoryBot.create(:user, role: :teacher, full_name: 'Zofia Zawadzka')
    @story_group = FactoryBot.create(:story_group, owner: @owner)
  end

  def pool(viewer: @owner) = TeacherPool.new(story_group: @story_group, viewer: viewer)

  def teacher(name, role: :teacher, university: 'Example university')
    FactoryBot.create(:user, role: role, full_name: name, university_name: university)
  end

  def names(candidates) = candidates.map(&:name)

  test 'students are never candidates, admins always are' do
    teacher('Adam Adamczyk')
    teacher('Bogdan Borek', role: :organization_admin)
    FactoryBot.create(:user, role: :student, full_name: 'Celina Cis')

    assert_equal ['Adam Adamczyk', 'Bogdan Borek', 'Zofia Zawadzka'], names(pool.candidates)
  end

  test 'another university is out of reach unless the viewer is a global admin' do
    teacher('Adam Adamczyk', university: 'Somewhere else')

    assert_not_includes names(pool.candidates), 'Adam Adamczyk'

    admin = teacher('Global Gustaw', role: :global_admin, university: 'Somewhere else')
    assert_includes names(pool(viewer: admin).candidates), 'Adam Adamczyk'
  end

  # Only then is the university worth printing beside an e-mail.
  test 'only a global admin sees a pool that can span universities' do
    assert_not pool.cross_university?
    assert pool(viewer: teacher('Global Gustaw', role: :global_admin)).cross_university?
  end

  test 'the owner and the people already in are flagged, not filtered out' do
    inside = teacher('Adam Adamczyk')
    FactoryBot.create(:story_group_teacher, user: inside, story_group: @story_group)
    teacher('Bogdan Borek')

    taken = pool.candidates.select(&:in_group?).map(&:name)

    assert_equal ['Adam Adamczyk', 'Zofia Zawadzka'], taken
    assert_not pool.candidates.find { |c| c.name == 'Bogdan Borek' }
                              .in_group?
  end

  test 'candidates sort by folded name' do
    teacher('Łukasz Lis')
    teacher('Marta Mazur')
    teacher('Adam Adamczyk')

    assert_equal ['Adam Adamczyk', 'Łukasz Lis', 'Marta Mazur', 'Zofia Zawadzka'], names(pool.candidates)
  end

  # What the Stimulus controller matches against: name and e-mail in one
  # folded string, so a query spanning the two finds nothing.
  test 'the search key folds diacritics and covers name and e-mail' do
    person = teacher('Łukasz Wiśniewski')
    person.update!(email: 'L.Wisniewski@Example.COM')

    key = pool.candidates.find { |c| c.person == person }
                         .search_key

    assert_equal 'lukasz wisniewski l.wisniewski@example.com', key
  end

  test 'a university with nobody else in it has an empty pool' do
    @story_group.teacher_memberships.destroy_all
    @owner.update!(university_name: 'Lonely university')

    assert_equal 1, pool.size # the owner themselves, flagged as already in
    assert pool.candidates.all?(&:in_group?)
    assert_not pool.addable?
  end
end
