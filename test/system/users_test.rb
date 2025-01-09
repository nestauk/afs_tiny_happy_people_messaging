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
    check "I accept the terms of service and privacy policy"
    stub_successful_twilio_call(Content::WELCOME_MESSAGE, User.new(phone_number: "+447444930200"))
    click_button "Sign up"

    assert_text "Thanks for signing up!"
    fill_in "Your child's name, or nickname", with: "Jack"
    select "Tuesday"
    select "Morning"
    click_button "Next"

    assert_text "You're almost done"
    select "Social media"
    check "I want to share special moments with my child"

    click_button "Next"

    assert_text "Thank you for signing up!"
    assert_no_text "We will be in touch within 3 working days to explain more about the diary study and get you started."
    assert_equal 1, Message.count

    @admin = create(:admin)
    sign_in

    visit users_path
    click_on "Jo Smith"
    assert_text "+447444930200"
    assert_text "ABC123"
    assert_text Content::WELCOME_MESSAGE
    assert_equal "Jack", User.last.child_name
    assert_equal 2, User.last.day_preference
    assert_equal "morning", User.last.hour_preference
  end

  test "user can sign up and take part in the diary study" do
    visit new_user_path

    fill_in "First name", with: "Jo"
    fill_in "Last name", with: "Smith"
    fill_in "Phone number", with: "07444930200"
    fill_in "Postcode", with: "ABC123"
    select "November"
    select "2022"
    check "I accept the terms of service and privacy policy"
    stub_successful_twilio_call(Content::WELCOME_MESSAGE, User.new(phone_number: "+447444930200"))
    click_button "Sign up"

    assert_text "Thanks for signing up!"
    fill_in "Your child's name, or nickname", with: "Jack"
    select "No preference", from: "What day would you like to get the texts?"
    select "Morning"
    check "I'm interested in participating in a diary study (you'll keep a simple log of your experience, and receive compensation for your time)"
    click_button "Next"

    assert_text "You're almost done"
    select "Social media"
    check "I want to share special moments with my child"

    click_button "Next"

    assert_text "Thanks for expressing interest in our diary study!"
    select "Email"
    fill_in "Email", with: "email@example.com"
    click_button "Save"

    assert_text "Thank you for signing up!"
    assert_text "We will be in touch within 3 working days to explain more about the diary study and get you started."

    assert_equal 1, Message.count

    @admin = create(:admin)
    sign_in

    visit users_path
    click_on "Jo Smith"
    assert_text "+447444930200"
    assert_text "ABC123"
    assert_text Content::WELCOME_MESSAGE
    assert_equal "Jack", User.last.child_name
    assert_equal 2, User.last.day_preference
    assert_equal "morning", User.last.hour_preference
    assert_equal true, User.last.diary_study
    assert_equal "Email", User.last.diary_study_contact_method
    assert_equal "email@example.com", User.last.email
  end

  test "user can sign up and decide not to take part in the diary study" do
    visit new_user_path

    fill_in "First name", with: "Jo"
    fill_in "Last name", with: "Smith"
    fill_in "Phone number", with: "07444930200"
    fill_in "Postcode", with: "ABC123"
    select "November"
    select "2022"
    check "I accept the terms of service and privacy policy"
    stub_successful_twilio_call(Content::WELCOME_MESSAGE, User.new(phone_number: "+447444930200"))
    click_button "Sign up"

    assert_text "Thanks for signing up!"
    check "I'm interested in participating in a diary study (you'll keep a simple log of your experience, and receive compensation for your time)"
    click_button "Next"

    assert_text "You're almost done"
    click_button "Next"

    assert_text "Thanks for expressing interest in our diary study!"
    click_button "I'm not interested"

    assert_text "Thank you for signing up!"
    assert_no_text "We will be in touch within 3 working days to explain more about the diary study and get you started."

    assert_equal 1, Message.count
    assert_equal true, User.last.diary_study
    assert_equal "", User.last.diary_study_contact_method
  end

  test "user can sign up and skip non essential form fields" do
    visit new_user_path

    fill_in "First name", with: "Jo"
    fill_in "Last name", with: "Smith"
    fill_in "Phone number", with: "07444930200"
    fill_in "Postcode", with: "ABC123"
    select "November"
    select "2022"
    check "I accept the terms of service and privacy policy"
    stub_successful_twilio_call(Content::WELCOME_MESSAGE, User.new(phone_number: "+447444930200"))
    click_button "Sign up"

    assert_text "Thanks for signing up!"
    click_button "Skip"

    assert_text "You're almost done"
    click_button "Skip"

    assert_text "Thank you for signing up!"

    assert_equal 1, Message.count

    @admin = create(:admin)
    sign_in

    visit users_path
    click_on "Jo Smith"
    assert_text "+447444930200"
    assert_text "ABC123"
    assert_text Content::WELCOME_MESSAGE
    assert_equal "", User.last.child_name
    assert_equal 2, User.last.day_preference
    assert_equal "no_preference", User.last.hour_preference
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
