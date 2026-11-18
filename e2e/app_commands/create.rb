# frozen_string_literal: true

# rails.create("user", "teacher", { email: "..." }) in the specs: FactoryBot.create(:user, :teacher, email: "...").
factory, *traits = command_options
attributes = traits.last.is_a?(Hash) ? traits.pop : {}

FactoryBot.create(factory.to_sym, *traits.map(&:to_sym), **attributes.symbolize_keys)
