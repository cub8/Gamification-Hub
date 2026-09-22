# frozen_string_literal: true

# A group's front page, as one of its students reads it. Mockup: #/s/home,
# viewHome(), js-expanded/30-main.js:99-131.
#
# Five questions, all of them queries: what do I have, what rank am I, which
# badges are still out there, what did I buy, what just happened. Resolved
# once here, so the view is a rendering and nothing else.
#
# Replaces StoryGroupStudentDashboard. The badges and the shop are NOT
# re-derived: BadgeShelf and Shop already answer those, and a second
# implementation is how an overview ends up disagreeing with the screen it
# links to.
class StudentOverview
  # The fan holds this many cards.
  #
  # Three, because that is what the column can hold. The hand sits in a
  # `span 7` track — about 510px of usable width on a 1400px screen — and one
  # 196px card plus 110px of each card behind it means three cards are 416px
  # and five are 636px, before the "go to shop" slot. The mockup's own fan is
  # three for the same reason; its fake student owns three items.
  #
  # The zone counter still reports everything the student owns, and
  # "Moje przedmioty" is one click away with the full set.
  HAND = 3

  # How many ledger rows the overview shows before handing over to the
  # history screen. The mockup's six.
  LEDGER = 6

  def initialize(student:)
    @student = student
  end

  attr_reader :student, :entries

  def load
    @items      = load_items
    @entries    = ledger.entries.first(LEDGER)
    self
  end

  def story_group = @story_group ||= student.story_group

  def balance = student.current_currency.to_i

  def total = student.total_currency.to_i

  def lives = student.lives.to_i

  def rank      = student.rank
  def next_rank = student.next_rank

  # How far up the current rung the student is, as the bar sees it. Measured
  # from the rung they hold, not from zero, or a student at 90/100 with the
  # previous rung at 80 would read as nearly finished the moment they
  # arrived.
  def rank_progress
    return if next_rank.nil?

    floor  = rank&.required_currency_value.to_i
    target = next_rank.required_currency_value.to_i

    [total - floor, target - floor]
  end

  def missing_to_next_rank
    return if next_rank.nil?

    next_rank.required_currency_value.to_i - total
  end

  def badges = @badges ||= BadgeShelf.new(story_group: story_group, membership: student)

  # The newest few, for the fan; `items_count` is every one of them, because
  # the zone's counter names what the student owns, not what is on screen.
  attr_reader :items

  def items_count = @items_count ||= student.students_items.count

  def affordable = shop.affordable

  def ledger = @ledger ||= CurrencyLedger.new(student: student)

  # The student's place in the group, or nil when the ranking is not theirs
  # to see. Standard competition ranking: ties share a place, so two students
  # on 40 are both 2. and the next one is 4. (DECISIONS.md:36).
  def ranking_place
    return @ranking_place if defined?(@ranking_place)

    @ranking_place = if StoryGroupPolicy.new(student.user, story_group).see_ranking_standings?
                       totals = story_group.student_memberships.pluck(:total_currency).map(&:to_i)
                       totals.sort.reverse.index(total) + 1
                     end
  end

  private

  def load_items
    student.students_items
           .includes(item: { icon_attachment: :blob })
           .order(created_at: :desc)
           .limit(HAND)
           .to_a
  end

  def shop = @shop ||= Shop.new(story_group: story_group, student: student)
end
