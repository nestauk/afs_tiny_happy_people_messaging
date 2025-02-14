require "application_system_test_case"

class UsersTest < ApplicationSystemTestCase
  test "user can sign up" do
    visit new_user_path

    sign_up

    assert_text "Thanks for signing up!"
    fill_in "Your child's name, or nickname", with: "Jack"
    select "Tuesday"
    select "Morning"
    click_button "Next"

    assert_text "You're almost done"
    select "Social media"
    check "Building a better routine with my child"
    fill_in "We're currently available in English, with more languages on the horizon! Let us know your preferred language to help shape our future offerings", with: "Polish"

    stub_successful_twilio_call("Hi Jo, welcome to our programme of weekly texts with fun activities for Jack's development. Congrats on starting this amazing journey with your little one!", User.new(phone_number: "+447444930200"))

    click_button "Next"

    assert_text "Thank you for signing up!"
    assert_no_text "We will be in touch within 5 working days to explain more about the diary study and get you started."
    assert_equal 1, Message.count

    @admin = create(:admin)
    sign_in

    visit users_path
    click_on "Jo Smith"
    assert_text "+447444930200"
    assert_text "ABC123"
    assert_text "Hi Jo, welcome to our programme of weekly texts with fun activities for Jack's development."
    assert_equal "Jack", User.last.child_name
    assert_equal 2, User.last.day_preference
    assert_equal "morning", User.last.hour_preference
    assert_equal "Islington", User.last.local_authority.name
    assert_equal "Polish", User.last.new_language_preference
  end

  test "user can sign up and take part in the diary study" do
    visit new_user_path

    sign_up

    assert_text "Thanks for signing up!"
    fill_in "Your child's name, or nickname", with: "Jack"
    select "No preference", from: "What day would you like to get the texts each week?"
    select "Morning"
    check "Yes, I'm interested in joining the diary study and earning a £100 voucher!"
    click_button "Next"

    assert_text "You're almost done"
    select "Social media"
    check "Building a better routine with my child"

    click_button "Next"

    assert_text "Thank you for your interest in our diary study"
    fill_in "Email", with: "email@example.com"
    check "Option 1: Receive my £100 voucher at the end of the study, after I have submitted all 4 weeks of reflections."

    click_button "I'd like to take part"
    
    assert_text "Diary study consent"
    
    check "I agree to the above statements and to taking part in the diary study"
    
    stub_successful_twilio_call("Hi Jo, welcome to our programme of weekly texts with fun activities for Jack's development. Congrats on starting this amazing journey with your little one!", User.last)

    click_button "Submit"

    assert_text "Thank you for signing up!"
    assert_text "We'll be in touch within 5 working days to get you started with the diary study."

    assert_equal 1, Message.count

    @admin = create(:admin)
    sign_in

    visit users_path
    click_on "Jo Smith"
    assert_text "+447444930200"
    assert_text "ABC123"
    assert_text "Hi Jo, welcome to our programme of weekly texts with fun activities for Jack's development."
    assert_equal "Jack", User.last.child_name
    assert_equal 2, User.last.day_preference
    assert_equal "morning", User.last.hour_preference
    assert_equal true, User.last.diary_study
    assert_equal "email@example.com", User.last.email
    assert_equal "Option 1: Receive my £100 voucher at the end of the study, after I have submitted all 4 weeks of reflections.", User.last.incentive_receipt_method
    refute_nil User.last.consent_given_at
  end

  test "user can sign up and decide not to take part in the diary study after seeing information" do
    visit new_user_path

    sign_up

    assert_text "Thanks for signing up!"
    check "Yes, I'm interested in joining the diary study and earning a £100 voucher!"
    click_button "Next"

    assert_text "You're almost done"
    click_button "Next"

    assert_text "Thank you for your interest in our diary study"

    stub_successful_twilio_call("Hi Jo, welcome to our programme of weekly texts with fun activities for your child's development. Congrats on starting this amazing journey with your little one!", User.last)

    click_button "I'm not interested"

    assert_text "Thank you for signing up!"
    assert_no_text "We'll be in touch within 5 working days to get you started with the diary study."

    assert_equal 1, Message.count
    assert_equal true, User.last.diary_study
    assert_nil User.last.consent_given_at
  end

  test "user can sign up and decide not to take part in the diary study by refusing consent" do
    visit new_user_path

    sign_up

    assert_text "Thanks for signing up!"
    check "Yes, I'm interested in joining the diary study and earning a £100 voucher!"
    click_button "Next"

    assert_text "You're almost done"
    click_button "Next"

    assert_text "Thank you for your interest in our diary study"

    stub_successful_twilio_call("Hi Jo, welcome to our programme of weekly texts with fun activities for your child's development. Congrats on starting this amazing journey with your little one!", User.last)

    fill_in "Email", with: "email@example.com"
    check "Option 1: Receive my £100 voucher at the end of the study, after I have submitted all 4 weeks of reflections."

    click_button "I'd like to take part"

    assert_text "Diary study consent"

    click_button "I'm not interested"

    assert_text "Thank you for signing up!"
    assert_no_text "We'll be in touch within 5 working days to get you started with the diary study."

    assert_equal 1, Message.count
    assert_equal true, User.last.diary_study
    assert_nil User.last.consent_given_at
  end

  test "user can skip non-essential form fields" do
    visit new_user_path

    sign_up

    assert_text "Thanks for signing up!"

    click_button "Skip this section"

    assert_text "You're almost done"

    stub_successful_twilio_call("Hi Jo, welcome to our programme of weekly texts with fun activities for your child's development. Congrats on starting this amazing journey with your little one!", User.last)

    click_button "Skip this section"

    assert_text "Thank you for signing up!"

    assert_equal 1, Message.count

    @admin = create(:admin)
    sign_in

    visit users_path
    click_on "Jo Smith"
    assert_text "+447444930200"
    assert_text "ABC123"
    assert_text "Hi Jo, welcome to our programme of weekly texts with fun activities for your child's development."
    assert_equal "", User.last.child_name
    assert_equal 2, User.last.day_preference
    assert_equal "no_preference", User.last.hour_preference
  end

  test "user can skip second page and still get directed to the diary study if they've signed up" do
    visit new_user_path

    sign_up

    assert_text "Thanks for signing up!"
    fill_in "Your child's name, or nickname", with: "Jack"
    check "Yes, I'm interested in joining the diary study and earning a £100 voucher!"
    click_button "Next"

    assert_text "You're almost done"

    click_button "Skip this section"

    assert_text "Thank you for your interest in our diary study"

    fill_in "Email", with: "email@example.com"
    check "Option 1: Receive my £100 voucher at the end of the study, after I have submitted all 4 weeks of reflections."

    click_button "I'd like to take part"
    
    assert_text "Diary study consent"
    
    check "I agree to the above statements and to taking part in the diary study"
    
    stub_successful_twilio_call("Hi Jo, welcome to our programme of weekly texts with fun activities for Jack's development. Congrats on starting this amazing journey with your little one!", User.last)

    click_button "Submit"

    assert_text "Thank you for signing up!"
    assert_text "We'll be in touch within 5 working days to get you started with the diary study."

    @admin = create(:admin)
    sign_in

    assert_equal 1, Message.count

    visit users_path
    click_on "Jo Smith"
    assert_text "+447444930200"
    assert_text "ABC123"
    assert_text "Hi Jo, welcome to our programme of weekly texts with fun activities for Jack's development."
    assert_equal "Jack", User.last.child_name
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
    assert_field_has_errors("Your child's birthday")
    assert_field_has_errors("I accept the terms of service and privacy policy")

    sign_up

    check "Yes, I'm interested in joining the diary study and earning a £100 voucher!"

    click_button "Next"
    click_button "Skip this section"

    assert_text "Thank you for your interest in our diary study"

    click_button "I'd like to take part"

    assert_field_has_errors("Email")
    assert_text "Choose one option"

    fill_in "Email", with: "email@example.com"
    check "Option 1: Receive my £100 voucher at the end of the study, after I have submitted all 4 weeks of reflections."

    click_button "I'd like to take part"

    assert_text "Diary study consent"

    click_button "Submit"

    assert_field_has_errors("I agree to the above statements and to taking part in the diary study")
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

  private

  def sign_up
    month = 7.months.ago.strftime("%B")
    year = 7.months.ago.strftime("%Y")
    fill_in "First name", with: "Jo"
    fill_in "Last name", with: "Smith"
    fill_in "Phone number", with: "07444930200"
    fill_in "Postcode", with: "ABC123"
    select month
    select year
    check "I accept the terms of service and privacy policy"

    geocode_payload = Geokit::GeoLoc.new(state: "Islington")
    LocationGeocoder.any_instance.stubs(:geocode).returns(geocode_payload)

    click_button "Sign up"
  end
end
