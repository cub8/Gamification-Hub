# frozen_string_literal: true

class UserBuilder
  class InvalidAuthError < StandardError; end
  class InvalidParamsError < StandardError; end

  USOS_SEARCHED_FIELDS = %w[
    id
    first_name
    last_name
    email
    student_number
  ].freeze

  attr_reader :auth, :provider, :university_number,
              :usos_id, :full_name, :university_name,
              :email, :odc_uid, :role

  def initialize(auth, provider)
    @provider = provider
    @auth = auth

    raise InvalidAuthError if @auth.nil?
  end

  def build
    case @provider
    when 'uam_usos'
      build_user_params_for_uam_usos
    when 'development'
      build_user_params_for_development
    end

    user = search_for_user
    return create_user! unless user

    update_user_data(user) if user.first_login?
    user
  end

  private

  def build_user_params_for_uam_usos
    user_data = extract_user_data_from_usos
    first_name = user_data['first_name']
    last_name = user_data['last_name']

    @usos_id = user_data['id']
    @university_number = user_data['student_number']
    @full_name = "#{first_name} #{last_name}"
    @email = user_data['email']
    @university_name = 'Uniwersytet im. Adama Mickiewicza'
    @role = nil
  end

  def build_user_params_for_development
    @full_name = @auth[:full_name]
    @email = @auth[:email]
    @role = @auth[:role]
    @university_name = @auth[:university_name]
    @university_number = @auth[:university_number]
    @usos_id = nil

    raise InvalidParamsError if @full_name.nil? || @email.nil?
  end

  def extract_user_data_from_usos
    token = @auth.credentials.token
    secret = @auth.credentials.secret
    usos_api_client = UsosApiClient.new(token, secret)
    usos_api_client.get_user_data(USOS_SEARCHED_FIELDS)
  end

  def search_for_user
    users = User.where(email: @email)
    users = users.or(User.where(usos_id: @usos_id, university_name: @university_name)) if @usos_id

    users.first
  end

  def update_user_data(user)
    user.update!(user_params)
  end

  def create_user!
    User.create!(user_params)
  end

  def user_params
    {
      email:             @email,
      usos_id:           @usos_id,
      university_name:   @university_name,
      university_number: @university_number,
      full_name:         @full_name,
      first_login:       false,
      role:              @role,
    }
  end
end
