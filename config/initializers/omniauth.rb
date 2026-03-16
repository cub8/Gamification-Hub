# frozen_string_literal: true

if Rails.application.credentials.usos_uam.blank?
  Rails.logger.warn(
    "=============================\n\n" \
    "No AUM credentials found!\n\n" \
    '=============================',
  )

  return
end

uam_usos_credentials = Rails.application.credentials.usos_uam!

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :oauth, {
    name:            :uam_usos,
    consumer_key:    uam_usos_credentials.consumer_key!,
    consumer_secret: uam_usos_credentials.consumer_secret!,
    client_options:  {
      site:               uam_usos_credentials.base_url!,
      request_token_path: '/services/oauth/request_token',
      authorize_path:     '/services/oauth/authorize',
      access_token_path:  '/services/oauth/access_token',
      redirect_uri:       uam_usos_credentials.callback_url!,
    },
    request_params:  {
      scopes: 'email|personal|cards|change_all_preferences|other_emails|studies|staff_perspective',
    },
  }
end
