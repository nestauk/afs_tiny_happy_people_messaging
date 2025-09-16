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

    stub_successful_twilio_call("Hi Jo, welcome to our programme of weekly texts with fun activities for Jack's development. Congrats on starting this amazing journey with your little one! To get started, why not save this number as 'Tiny Happy People' so you can easily see when it's us texting you?", User.new(phone_number: "+447444930200"))

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

  test "User can't sign up if max capacity reached" do
    create_list(:user, 2001)

    visit new_user_path

    sign_up

    assert_text "Thank you for your interest. Due to overwhelming demand, we've reached our maximum signup capacity for now. Please check back in in a few months"
  end

  test "User put on waitlist if they're part of Sheffield study" do
    create(:research_study_user, postcode: "abc123", last_four_digits_phone_number: "0200")
    visit new_user_path

    sign_up

    assert_text "Thanks for signing up!"

    click_button "Skip this section"

    assert_text "You're almost done"

    stub_successful_twilio_call("Hi Jo! Thank you for signing up to the Tiny Happy People text messaging programme. We’re currently receiving a large volume of sign ups, and as a result we unfortunately will have to place you on a waiting list to receive this service. We expect that we will be able to provide the service for you starting in September provided your child is still under 24 months. Please respond STOP if you would like to opt out, otherwise we will send your first text messages in September. We hope that you will join us in the autumn!", User.last)

    click_button "Skip this section"

    assert_text "Thank you for signing up!"

    refute User.last.contactable
    refute_nil User.last.restart_at
  end

  test "user can skip non-essential form fields" do
    visit new_user_path

    sign_up

    assert_text "Thanks for signing up!"

    click_button "Skip this section"

    assert_text "You're almost done"

    stub_successful_twilio_call("Hi Jo, welcome to our programme of weekly texts with fun activities for your child's development. Congrats on starting this amazing journey with your little one! To get started, why not save this number as 'Tiny Happy People' so you can easily see when it's us texting you?", User.last)

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

  test "form shows errors" do
    visit new_user_path

    within("#sign-up-form") do
      click_on "Sign up"
    end

    assert_field_has_errors("First name")
    assert_field_has_errors("Last name")
    assert_field_has_errors("Phone number")
    assert_text "Your child must be between 3 and 24 months old, but we're working to expand our content"
    assert_field_has_errors("I accept the terms of service and privacy policy")
  end

  test "users can't edit without token" do
    user = create(:user)
    visit edit_user_path(user)

    assert_current_path root_path
    assert_text "Your session has expired"
  end

  test "users can't edit without valid token" do
    user = create(:user)
    visit edit_user_path(user, token: "invalid_token")

    assert_current_path root_path
    assert_text "Your session has expired"
  end

  test "users can't edit after token has expired" do
    visit new_user_path

    sign_up

    assert_text "Thanks for signing up!"

    travel_to 16.minutes.from_now do
      click_button "Next"

      assert_current_path root_path
      assert_text "Your session has expired"
    end
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
