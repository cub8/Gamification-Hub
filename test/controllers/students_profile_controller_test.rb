require "test_helper"

class StudentsProfileControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get students_profile_index_url
    assert_response :success
  end
end
