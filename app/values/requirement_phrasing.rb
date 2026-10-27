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
    return I18n.t('items.labels.seal_lives') if requirement.lives?

    key = requirement.rank? ? 'items.labels.seal_rank' : 'items.labels.seal_badge'
    I18n.t(key, name: requirement.name)
  end

  # [lead, name] pairs; the view sets the name in bold after the lead.
  def requirement_lines_for(requirements)
    requirements.map do |requirement|
      case requirement.kind
      when :rank  then [I18n.t('items.labels.requires_rank'),  requirement.name]
      when :badge then [I18n.t('items.labels.requires_badge'), requirement.name]
      else             [I18n.t('items.labels.requires_life'),  nil]
      end
    end
  end
end
