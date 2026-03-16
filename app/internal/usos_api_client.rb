# frozen_string_literal: true

class UsosApiClient
  attr_reader :access_token

  def initialize(token, secret)
    usos_uam_credentials = Rails.application.credentials.usos_uam!

    consumer = OAuth::Consumer.new(
      usos_uam_credentials.consumer_key!,
      usos_uam_credentials.consumer_secret!,
      site: usos_uam_credentials.base_url!,
    )

    @access_token = OAuth::AccessToken.new(consumer, token, secret)
  end

  def get_user_data(fields)
    base_path = '/services/users/user?fields='
    fields_string = fields.join('|')
    full_path = "#{base_path}#{fields_string}"
    response = @access_token.get(full_path)

    JSON.parse(response.body)
  end
end
