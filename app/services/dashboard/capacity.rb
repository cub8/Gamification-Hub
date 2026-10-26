# frozen_string_literal: true

module Dashboard::Capacity
  def free = [max_members - member_count, 0].max
  def fill_percent = (member_count * 100.0 / max_members).clamp(0, 100).round
  def full? = member_count >= max_members
end
