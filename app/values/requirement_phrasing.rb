# frozen_string_literal: true

module RequirementPhrasing
  # A requirement as a card needs it: what kind of thing it is and what it is
  # called. `name` is nil for :lives, which names no record.
  Requirement = Data.define(:kind, :name) do
    def rank?  = kind == :rank
    def badge? = kind == :badge
    def lives? = kind == :lives
  end

  # Having a life left is a condition of the PURCHASE, not a property of the
  # item, so only an offer ever carries it (PurchaseEligibilityService).
  LIVES = Requirement.new(:lives, nil).freeze

  # The plate stamped across the artwork. Only the first requirement fits
  # there, and the foot below lists the rest.
  def seal_label_for(requirement)
    return if requirement.nil?
    return 'Niedostępne przy 0 życiach' if requirement.lives?

    requirement.rank? ? "Od rangi #{requirement.name}" : "Za odznakę #{requirement.name}"
  end

  # [lead, name] pairs: the card prints the lead and bolds the name. A nil
  # name means the whole line is the lead and nothing is bolded.
  def requirement_lines_for(requirements)
    requirements.map do |requirement|
      case requirement.kind
      when :rank  then ['Wymaga rangi ',   requirement.name]
      when :badge then ['Wymaga odznaki ', requirement.name]
      else             ['Masz 0 żyć. Najpierw odzyskaj życie.', nil]
      end
    end
  end
end
