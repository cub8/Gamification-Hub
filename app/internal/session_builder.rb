# frozen_string_literal: true

class SessionBuilder
  USOS_SEARCHED_FIELDS = %w[
    id
    first_name
    last_name
    email
    student_number
  ].freeze

  attr_reader :auth, :provider, :university_number,
              :usos_id, :full_name, :university_name,
              :email, :odc_uid

  def initialize(auth, provider)
    @auth = auth
    @provider = provider
  end

  def build
    case @provider
    when 'uam_usos'
      build_user_params_for_uam_usos
    when 'development'
      # do something later...
    end

    {
      usos_id:           @usos_id,
      email:             @email,
      full_name:         @full_name,
      university_number: @university_number,
      university_name:   @university_name,
    }
  end

  private

  def build_user_params_for_uam_usos
    user_data = extract_user_data_from_usos
    first_name = user_data['first_name']
    last_name = user_data['last_name']

    @usos_id = user_data['id']
    @university_number = user_data['student_number']
    @full_name =        "#{first_name} #{last_name}"
    @email =            user_data['email']
    @university_name =  'Uniwersytet im. Adama Mickiewicza'
  end

  def extract_user_data_from_usos
    token = @auth.credentials.token
    secret = @auth.credentials.secret
    usos_api_client = UsosApiClient.new(token, secret)
    usos_api_client.get_user_data(USOS_SEARCHED_FIELDS)
  end
end
