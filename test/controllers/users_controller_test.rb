require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get users_new_url
    assert_response :success
  end

  test "should return error if passwords don't match" do
    post users_url, params: {
      name: "bobby",
      email: "camp_a@express-tops.net",
      password: "password_one",
      password_confirm: "password_two"
    }
    assert_equal flash[:error_msg], "Sorry, your passwords do not match"
  end

  test "should return success if passwords are valid" do
    post users_url, params: {
      name: "bobby",
      email: "camp_a@express-tops.net",
      password: "password_three",
      password_confirm: "password_three"
    }
    assert_not flash[:error_msg]
    assert_response :redirect
  end
end
