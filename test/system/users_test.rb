require "application_system_test_case"

class UsersTest < ApplicationSystemTestCase
  test "user can sign up" do
    visit new_user_path

    fill_in "First name", with: "Jo"
    fill_in "Last name", with: "Smith"
    fill_in "Phone number", with: "07444930200"
    select "November"
    select "2022"

    click_on "Sign up"

    assert_text "You have signed up. Your first text will be sent soon."
  end
end
