# frozen_string_literal: true

# A student buys an item by name through the real purchase service, which also notifies the teachers.
membership = StoryGroupStudent.find(command_options['membership_id'])
item = membership.story_group.items.find_by!(name: command_options['item'])

ItemPurchaseService.new(student: membership, item:).call
