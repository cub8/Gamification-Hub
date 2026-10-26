# frozen_string_literal: true

module Dashboard::Capacity
  def unlimited? = max_members.nil?
  def free = unlimited? ? nil : [max_members - member_count, 0].max
  def fill_percent = unlimited? ? 0 : (member_count * 100.0 / max_members).clamp(0, 100).round
  def full? = !unlimited? && member_count >= max_members
end
