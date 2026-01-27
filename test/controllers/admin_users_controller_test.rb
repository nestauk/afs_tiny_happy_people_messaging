require "test_helper"

class Admin::UsersControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "index shows contactable users" do
    admin = create(:admin)
    sign_in(admin)

    create(:user, first_name: "Jo", last_name: "Smith", contactable: true)
    create(:user, first_name: "Paul", last_name: "Fish", contactable: true)
    create(:user, first_name: "Jane", last_name: "Doe", contactable: false)

    get admin_users_path
    assert_response :success
    assert_see "Jo Smith"
    assert_see "Paul Fish"

    get admin_users_path(letter: "F")
    assert_response :success
    assert_see "Paul Fish"
    assert_dont_see "Jo Smith"
  end

  test "index shows opted out users when opted_out param is set" do
    admin = create(:admin)
    sign_in(admin)

    create(:user, first_name: "Jo", last_name: "Smith", contactable: true)
    create(:user, first_name: "Paul", last_name: "Fish", contactable: true)
    create(:user, first_name: "Jane", last_name: "Doe", contactable: false)

    get admin_users_path(opted_out: true)
    assert_response :success
    assert_see "Jane Doe"
    assert_dont_see "Jo Smith"
    assert_dont_see "Paul Fish"

    get admin_users_path(letter: "D", opted_out: true)
    assert_response :success
    assert_see "Jane Doe"
    assert_dont_see "Jo Smith"
    assert_dont_see "Paul Fish"
  end
end
