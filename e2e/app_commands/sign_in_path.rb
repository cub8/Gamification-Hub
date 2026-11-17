# frozen_string_literal: true

# A one-time sign-in path for the given user, so tests that are not about signing in can skip the login form.
token = User.find(command_options['user_id']).create_login_token!

Rails.application.routes.url_helpers.auth_passwordless_verify_path(token: token.raw_token)
