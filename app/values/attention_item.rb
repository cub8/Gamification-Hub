# frozen_string_literal: true

AttentionItem = Data.define(:icon, :tone, :title, :detail, :action_label, :action_path, :emphasis) do
  def initialize(icon:, title:, detail:, action_label:, action_path:, tone: nil, emphasis: nil)
    super
  end

  def emphasised? = !!emphasis
end
