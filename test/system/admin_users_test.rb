require "application_system_test_case"

class AdminUsersTest < ApplicationSystemTestCase
  test "can see all users" do
    create(:user, first_name: "Jo", last_name: "Smith", contactable: true)
    create(:user, first_name: "Paul", last_name: "Fish", contactable: true)
    create(:user, first_name: "Jane", last_name: "Doe", contactable: false)

    @admin = create(:admin)
    sign_in

    visit users_path

    assert_text "Jo Smith"
    assert_text "Paul Fish"
    refute_text "Jane Doe"

    click_on "> Users who have stopped the service (1)"
    assert_text "Jane Doe"

    click_link "F"

    refute_text "Jo Smith"
    assert_text "Paul Fish"

    click_link "All"

    assert_text "Jo Smith"
    assert_text "Paul Fish"
  end
end
