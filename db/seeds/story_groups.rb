# frozen_string_literal: true

module Seeds
  class StoryGroups < Base
    DESCRIPTION = <<~DESC
      Galaktyka jest wielka, ale nasze uszy są większe!
      Dołącz do pionierów, którzy zamienili nory na stacje orbitalne.
      Walczymy o prestiż, przetrwanie i pełne brzuchy, zbierając Złote Marchewki w świecie, gdzie grawitacja to tylko sugestia.
      Pamiętaj: w kosmosie nikt nie usłyszy Twojego chrupania... chyba że zapomnisz wyłączyć interkom
    DESC

    def call
      log_start 'story group'
      build_story_group
      log_finish 'story group'
    end

    private

    def build_story_group
      return if StoryGroup.exists?(name: 'Kosmiczne króliki')

      owner = User.find_by!(email: 'tomasz.nowakowski@example.com')
      teachers = [
        User.find_by!(email: 'barbara.kowalczyk@example.com'),
        User.find_by!(email: 'andrzej.wozniak@example.com'),
      ]
      students = User.where(role: :student).first(5) + [User.where(role: :teacher).last!]

      story_group = FactoryBot.create(
        :story_group,
        owner:         owner,
        name:          'Kosmiczne króliki',
        description:   DESCRIPTION,
        currency_name: 'Złota Marchewka',
        default_lives: 3,
      )

      story_group.teachers << teachers
      story_group.students << students

      attach_images(story_group)
    end

    def attach_images(story_group)
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
    end
  end
end
