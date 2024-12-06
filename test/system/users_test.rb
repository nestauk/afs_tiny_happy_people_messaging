require "application_system_test_case"

class UsersTest < ApplicationSystemTestCase
  test "user can sign up" do
    visit new_user_path

    fill_in "First name", with: "Jo"
    fill_in "Last name", with: "Smith"
    fill_in "Phone number", with: "07444930200"
    fill_in "Postcode", with: "ABC123"
    select "November"
    select "2022"
    select "Morning"
    check "Do you have family support in bringing up your child(ren)?"
    check "Would you like to be added to a Slack channel with other parents to discuss the programme?"
    check "I accept the terms of service and privacy policy"

    stub_successful_twilio_call(Content::WELCOME_MESSAGE, User.new(phone_number: "+447444930200"))

    within("#sign-up-form") do
      click_on "Sign up"
    end

    assert_text "Thank you for signing up!"

    assert_equal 1, Message.count

    @admin = create(:admin)
    sign_in

    visit users_path
    click_on "Jo Smith"
    assert_text "+447444930200"
    assert_text "ABC123"
    assert_text "Does have family support"
    assert_text "On Slack"
    assert_text Content::WELCOME_MESSAGE
  end

  test "form shows errors" do
    visit new_user_path

    within("#sign-up-form") do
      click_on "Sign up"
    end

    assert_field_has_errors("First name")
    assert_field_has_errors("Last name")
    assert_field_has_errors("Phone number")
    assert_field_has_errors("I accept the terms of service and privacy policy")
  end

  test "can see all users" do
    create(:user, first_name: "Jo", last_name: "Smith", contactable: true)
    create(:user, first_name: "Jane", last_name: "Doe", contactable: false)

    @admin = create(:admin)
    sign_in

    visit users_path

    assert_text "Jo Smith"
    refute_text "Jane Doe"

    click_on "> Users who have stopped the service (1)"
    assert_text "Jane Doe"
  end
end
