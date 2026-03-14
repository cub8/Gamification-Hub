# frozen_string_literal: true

# rubocop:disable Layout/LineLength

source 'https://rubygems.org'

gem 'kamal', '~> 2.10', require: false # Deploy this application anywhere as a Docker container [https://kamal-deploy.org]
gem 'pg', '~> 1.6' # Use postgresql as the database for Active Record
gem 'puma', '~> 7.2' # Use the Puma web server [https://github.com/puma/puma]
gem 'rails', '~> 8.1.2' # Base framework
gem 'thruster', '~> 0.1', require: false # Add HTTP asset caching/compression and X-Sendfile acceleration to Puma [https://github.com/basecamp/thruster/]

gem 'cssbundling-rails', '~> 1.4' # Bundle and process CSS [https://github.com/rails/cssbundling-rails]
gem 'image_processing', '~> 1.2' # Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
gem 'jsbundling-rails', '~> 1.3' # Bundle and transpile JavaScript [https://github.com/rails/jsbundling-rails]
gem 'propshaft', '~> 1.3' # The modern asset pipeline for Rails [https://github.com/rails/propshaft]
gem 'stimulus-rails', '~> 1.3' # Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem 'turbo-rails', '~> 2.0' # Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem "bcrypt", "~> 3.1.7"

gem 'solid_cable', '~> 3.0' # Adapter for ActionCable (broadcasting data on the frontend)
gem 'solid_cache', '~> 1.0' # Adapter for Rails.cache (caching stuff)
gem 'solid_queue', '~> 1.3' # Adapter ActiveJob (queues)

gem 'bootsnap', '~> 1.23', require: false # Reduces boot times through caching; required in config/boot.rb
gem 'tzinfo-data', '~> 1', platforms: %i[windows jruby] # Windows does not include zoneinfo files, so bundle the tzinfo-data gem

group :development, :test do
  gem 'brakeman', '~> 8.0', require: false # Static analysis for security vulnerabilities
  gem 'bundler-audit', '~> 0.9', require: false # Audits gems for known security defects
  gem 'debug', '~> 1.11', platforms: %i[mri windows] # Debugger
  gem 'factory_bot_rails', '~> 6.5' # For factories [https://github.com/thoughtbot/factory_bot_rails]
  gem 'rubocop', '~> 1.84' # Linter
  gem 'rubocop-espago', '~> 1.2', require: false # Linter rules from Espago
  gem 'ruby-lsp', '~> 0.26' # Ruby LSP
end

group :development do
  gem 'better_errors', '~> 1.1' # Better error console
  gem 'binding_of_caller', '~> 2.0' # For interactive console
  gem 'web-console', '~> 4.3' # Use console on exceptions pages [https://github.com/rails/web-console]
end

# rubocop:enable Layout/LineLength
