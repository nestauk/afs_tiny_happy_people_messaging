require "test_helper"

class Admin::UsersControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @admin = create(:admin)
    sign_in(@admin)
    content = create(:content)
    create(:user, first_name: "Jo", last_name: "Smith", contactable: true, last_content_id: content.id)
    create(:user, first_name: "Paul", last_name: "Fish", contactable: true)
    create(:user, first_name: "Jane", last_name: "Doe", contactable: false)
  end

  test "index shows all users" do
    get admin_users_path
    assert_response :success
    assert_see "Jo Smith"
    assert_see "Paul Fish"
    assert_see "Jane Doe"
  end

  test "index filters users by name" do
    get admin_users_path(name: "Paul")
    assert_response :success
    assert_see "Paul Fish"
    assert_dont_see "Jo Smith"
    assert_dont_see "Jane Doe"

    get admin_users_path(name: "Smith")
    assert_response :success
    assert_see "Jo Smith"
    assert_dont_see "Paul Fish"
    assert_dont_see "Jane Doe"

    get admin_users_path(name: "Jo Smith")
    assert_response :success
    assert_see "Jo Smith"
    assert_dont_see "Paul Fish"
    assert_dont_see "Jane Doe"
  end

  test "index filters users by contactable status" do
    get admin_users_path(opted_out: true)
    assert_response :success
    assert_see "Jane Doe"
    assert_dont_see "Jo Smith"
    assert_dont_see "Paul Fish"
  end

  test "index filters users by finished status" do
    get admin_users_path(finished: true)
    assert_response :success
    assert_see "Jo Smith"
    assert_dont_see "Paul Fish"
    assert_dont_see "Jane Doe"
  end
end
