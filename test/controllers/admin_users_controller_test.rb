require "test_helper"

class Admin::UsersControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @admin = create(:admin)
    sign_in(@admin)
    content = create(:content)
    create(:user, first_name: "Jo", contactable: true, last_content_id: content.id, phone_number: "+447444930200")
    create(:user, first_name: "Paul", contactable: true, phone_number: "+447444930201")
    create(:user, first_name: "Jane", contactable: false, phone_number: "+447444930202")
  end

  test "index shows all users" do
    get admin_users_path
    assert_response :success
    assert_see "Jo"
    assert_see "Paul"
    assert_see "Jane"
  end

  test "index filters users by phone number" do
    get admin_users_path(phone_number: "+447444930200")
    assert_response :success
    assert_see "Jo"
    assert_dont_see "Paul"
    assert_dont_see "Jane"
  end

  test "index filters users by contactable status" do
    get admin_users_path(opted_out: true)
    assert_response :success
    assert_see "Jane"
    assert_dont_see "Jo"
    assert_dont_see "Paul"
  end

  test "index filters users by finished status" do
    get admin_users_path(finished: true)
    assert_response :success
    assert_see "Jo"
    assert_dont_see "Paul"
    assert_dont_see "Jane"
  end
end
