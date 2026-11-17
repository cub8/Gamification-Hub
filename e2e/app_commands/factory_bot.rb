# frozen_string_literal: true

# appFactories([["create", "user", "teacher", { email: "..." }]]) makes one FactoryBot call per entry.
Array.wrap(command_options).map do |factory_method, *args|
  CypressOnRails::SmartFactoryWrapper.public_send(factory_method, *args)
end
