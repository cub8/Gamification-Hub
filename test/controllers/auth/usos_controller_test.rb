# frozen_string_literal: true

require 'test_helper'

class Auth::UsosControllerTest < ActionDispatch::IntegrationTest
  test 'failed USOS login redirects to login with an alert instead of 404' do
    get auth_failure_path(message: 'invalid_credentials', strategy: 'uam_usos')

    assert_redirected_to login_path
    assert_equal I18n.t('auth.flash.usos_failure'), flash[:alert]
  end

  # Runs the real OmniAuth middleware and OAuth strategy; only the calls that would reach USOS are stubbed.
  test 'signs a student in through the whole USOS flow' do
    consumer = OAuth::Consumer.new('key', 'secret', site: 'https://usos.example', authorize_path: '/authorize')
    oauth_callback = nil
    OAuth::Consumer.any_instance.stubs(:get_request_token)
                   .with { |params| oauth_callback = params[:oauth_callback] }
                   .returns(OAuth::RequestToken.new(consumer, 'request-token', 'request-secret'))
    OAuth::RequestToken.any_instance.stubs(:get_access_token)
                       .returns(OAuth::AccessToken.new(consumer, 'access-token', 'access-secret'))
    UsosApiClient.any_instance.stubs(:get_user_data).returns(
      'id' => '424242', 'first_name' => 'Ewa', 'last_name' => 'Mazur',
      'email' => 'ewa.mazur@st.amu.edu.pl', 'student_number' => '123123',
    )

    post '/auth/uam_usos'

    assert_equal 'http://www.example.com/auth/uam_usos/callback', oauth_callback
    assert_match %r{\Ahttps://usos\.example/authorize\?.*oauth_token=request-token}, response.location

    get '/auth/uam_usos/callback', params: { oauth_token: 'request-token', oauth_verifier: 'verifier' }

    assert_redirected_to home_path
    user = User.find_by!(usos_id: '424242')
    assert_equal ['Ewa Mazur', 'ewa.mazur@st.amu.edu.pl', 'student'], [user.full_name, user.email, user.role]
    follow_redirect!
    assert_response :success
  end
end
