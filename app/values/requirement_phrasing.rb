# frozen_string_literal: true

module RequirementPhrasing
  Requirement = Data.define(:kind, :name) do
    def rank?  = kind == :rank
    def badge? = kind == :badge
    def lives? = kind == :lives
  end

  LIVES = Requirement.new(:lives, nil).freeze

  def seal_label_for(requirement)
    return if requirement.nil?
    return 'Niedostępne przy 0 życiach' if requirement.lives?

    requirement.rank? ? "Od rangi #{requirement.name}" : "Za odznakę #{requirement.name}"
  end

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
