# frozen_string_literal: true

# Mounts /__e2e__/command, through which Playwright runs e2e/app_commands (factories, cleanup).
# Those commands change the database at will, so the endpoint exists only on the e2e test server.
if defined?(CypressOnRails)
  CypressOnRails.configure do |c|
    c.api_prefix = ''
    c.install_folder = Rails.root.join('e2e').to_s
    c.use_middleware = Rails.env.test? && ENV['CYPRESS'].present?
    c.logger = Rails.logger
  end
end
