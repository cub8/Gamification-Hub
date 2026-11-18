# frozen_string_literal: true

# Gives a student one of their group's badges by name.
membership = StoryGroupStudent.find(command_options['membership_id'])
badge = membership.story_group.badges.find_by!(name: command_options['badge'])

FactoryBot.create(:students_badge, story_group_student: membership, badge:)
