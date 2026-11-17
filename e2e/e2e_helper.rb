# frozen_string_literal: true

# Loaded once, before the first app command runs.
require 'cypress_on_rails/smart_factory_wrapper'

CypressOnRails::SmartFactoryWrapper.configure(
  always_reload: false,
  factory:       FactoryBot,
  files:         Rails.root.glob('test/factories/**/*.rb'),
)
