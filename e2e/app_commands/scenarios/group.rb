# frozen_string_literal: true

# A teacher's group filled from the quick-start pack (5 ranks, 6 badges, 7 items, a grade sheet template
# with 8 categories) and three students:
#   Jan Nowak "Kometa"   50 collected, 3 lives (rank Adept)
#   Ola Zielińska "Feniks" 10 collected, 1 life  (rank Nowicjusz)
#   Piotr Wiśniewski     nothing yet, 0 lives
teacher = FactoryBot.create(:user, :teacher, full_name: 'Anna Kowalska', email: 'anna.kowalska@example.com')
group = FactoryBot.create(:story_group, owner: teacher, name: 'Klasa 3B', currency_name: 'Złote monety')
StarterPackBuilder.new(story_group: group, pack: 'neutral', classes: 12).call

enrol = ->(full_name, email, **membership) do
  user = FactoryBot.create(:user, :student, full_name:, email:)
  FactoryBot.create(:story_group_student, story_group: group, user:, **membership)
end

membership = enrol.call('Jan Nowak', 'jan.nowak@example.com',
                        nickname: 'Kometa', lives: 3, current_currency: 50, total_currency: 50,)
others = [
  enrol.call('Ola Zielińska', 'ola.zielinska@example.com',
             nickname: 'Feniks', lives: 1, current_currency: 10, total_currency: 10,),
  enrol.call('Piotr Wiśniewski', 'piotr.wisniewski@example.com', lives: 0, current_currency: 0, total_currency: 0),
]

{ teacher:, group:, student: membership.user, membership:, others: others.map(&:user) }
