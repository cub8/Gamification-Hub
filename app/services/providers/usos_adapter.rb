# frozen_string_literal: true

module Providers
  class UsosAdapter < BaseAdapter
    USOS_SEARCHED_FIELDS = %w[
      id
      first_name
      last_name
      email
      student_number
    ].freeze

    private

    def build_params
      user_data = extract_user_data_from_usos
      first_name = user_data['first_name']
      last_name = user_data['last_name']

      @usos_id = user_data['id']
      @university_number = user_data['student_number']
      @full_name = "#{first_name} #{last_name}"
      @email = user_data['email']
      @university_name = 'Uniwersytet im. Adama Mickiewicza'
      @role = 'student'
    end

    def extract_user_data_from_usos
      token = @auth.credentials.token
      secret = @auth.credentials.secret
      usos_api_client = UsosApiClient.new(token, secret)
      usos_api_client.get_user_data(USOS_SEARCHED_FIELDS)
    end
  end
end
