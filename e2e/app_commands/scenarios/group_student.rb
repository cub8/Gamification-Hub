# frozen_string_literal: true

# One more student in the given group: Ewa Mazur, with the group's starting lives and no currency unless given.
group = StoryGroup.find(command_options['group_id'])
student = FactoryBot.create(:user, :student, full_name: 'Ewa Mazur', email: 'ewa.mazur@example.com')
lives = command_options.fetch('lives', group.default_lives)
currency = command_options.fetch('currency', 0)
membership = FactoryBot.create(:story_group_student, story_group: group, user: student,
                                                     lives:, current_currency: currency, total_currency: currency,)

{ student:, membership: }
