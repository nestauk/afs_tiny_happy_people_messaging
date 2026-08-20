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

  test "edit shows the age in months of the user's current content" do
    group = create(:group)
    content = create(:content, group:, age_in_months: 14)
    user = create(:user)
    user.update!(group:, last_content_id: content.id)

    get edit_admin_user_path(user)

    assert_response :success
    assert_select "input#user_content_in_months[value='14']"
  end

  test "edit does not error for a user who has not received any content yet" do
    user = create(:user, last_content_id: nil)

    get edit_admin_user_path(user)

    assert_response :success
  end

  test "update sets next_content_override_id to the lowest-positioned content for the submitted age" do
    group = create(:group)
    content1 = create(:content, group:, position: 1, age_in_months: 12)
    create(:content, group:, position: 2, age_in_months: 12)
    user = create(:user)
    user.update!(group:, last_content_id: nil)

    patch admin_user_path(user), params: {user: {content_in_months: 12}}

    assert_redirected_to admin_user_path(user)
    assert_equal content1.id, user.reload.next_content_override_id
  end

  test "update re-renders the edit form with an error for an age with no matching content" do
    group = create(:group)
    create(:content, group:, age_in_months: 12)
    user = create(:user)
    user.update!(group:, last_content_id: nil)

    patch admin_user_path(user), params: {user: {content_in_months: 99}}

    assert_response :unprocessable_content
    assert_see "There is no existing content for this age group"
    assert_nil user.reload.last_content_id
  end
end
