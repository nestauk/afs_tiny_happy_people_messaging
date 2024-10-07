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

    Message.any_instance.stubs(:generate_token).returns("123")
    message = "Hi Jo, welcome to Tiny Happy People. Here's a video to get you started: http://localhost:3000/m/123"
    stub_successful_twilio_call(message, User.new(phone_number: "+447444930200"))

    click_on "Sign up"

    assert_text "You have signed up. Your first text will be sent soon."

    assert_equal 1, Message.count

    @admin = create(:admin)
    sign_in

    visit users_path
    click_on "Jo Smith"
    assert_text "+447444930200"
    assert_text "ABC123"
    assert_text "Does have family support"
    assert_text "On Slack"
    assert_text "Hi Jo, welcome to Tiny Happy People."
  end

  test "form shows errors" do
    visit new_user_path

    click_on "Sign up"

    assert_field_has_errors("First name")
    assert_field_has_errors("Last name")
    assert_field_has_errors("Phone number")
    assert_field_has_errors("I accept the terms of service and privacy policy")
  end
end
