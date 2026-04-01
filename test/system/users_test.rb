require "application_system_test_case"

class UsersTest < ApplicationSystemTestCase
  setup do
    create(:group)
  end

  test "user can sign up" do
    visit new_user_path

    assert_page_is_accessible

    sign_up

    assert_text "Thanks for signing up!"

    assert_page_is_accessible

    fill_in "What’s your name?", with: "Jo"
    fill_in "What’s your child called?", with: "Jack"
    select "Tuesday"
    select "Morning"
    select "I don't want to say"
    click_button "Next"

    assert_text "You're almost done"

    assert_page_is_accessible

    check "Instagram"

    stub_successful_twilio_call("Hi Jo, welcome to our programme of weekly texts with fun activities for Jack's development. Congrats on starting this amazing journey with your little one! To get started, why not save this number as 'CBeebies Parenting' so you can easily see when it's us texting you?", User.new(phone_number: "+447444930200"))

    click_button "Next"

    assert_text "Thank you for signing up!"

    assert_page_is_accessible

    assert_equal 1, Message.count

    @admin = create(:admin)
    sign_in

    user = User.last

    visit admin_users_path
    click_on "+447444930200"
    assert_text "ABC123"
    assert_text "Hi Jo, welcome to our programme of weekly texts with fun activities for Jack's development."
    assert_equal "Jack", user.child_name
    assert_equal 2, user.day_preference
    assert_equal "morning", user.hour_preference
    assert_equal "Islington", user.local_authority.name
    assert_equal "prefer_not_to_say", user.education_status
  end

  test "User can't sign up if max capacity reached" do
    create_list(:user, 3000)

    visit new_user_path

    sign_up

    assert_text "Thank you for your interest. Due to overwhelming demand, we've reached our maximum signup capacity for now. Please check back in in a few months"
  end

  test "user can skip non-essential form fields" do
    visit new_user_path

    sign_up

    assert_text "Thanks for signing up!"

    click_button "Skip this section"

    assert_text "You're almost done"

    stub_successful_twilio_call("Hi , welcome to our programme of weekly texts with fun activities for your child's development. Congrats on starting this amazing journey with your little one! To get started, why not save this number as 'CBeebies Parenting' so you can easily see when it's us texting you?", User.last)

    click_button "Skip this section"

    assert_text "Thank you for signing up!"

    assert_equal 1, Message.count

    @admin = create(:admin)
    sign_in

    visit admin_users_path
    click_on "+447444930200"
    assert_text "ABC123"
    assert_text "Hi , welcome to our programme of weekly texts with fun activities for your child's development."
    assert_equal "", User.last.child_name
    assert_equal 1, User.last.day_preference
    assert_equal "morning", User.last.hour_preference
  end

  test "form shows errors" do
    visit new_user_path

    select DateTime.current.strftime("%B")
    select DateTime.current.strftime("%Y")

    within("#sign-up-form") do
      click_on "Sign up"
    end

    assert_field_has_errors("Phone number")
    assert_field_has_errors("Postcode")
    assert_text "Your child must be between 9 and 18 months old to sign up for the service."
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
    month = 10.months.ago.strftime("%B")
    year = 10.months.ago.strftime("%Y")
    fill_in "Phone number", with: "07444930200"
    fill_in "Postcode", with: "ABC123"
    select month
    select year
    check "I accept the terms of service and privacy policy"

    geocode_payload = Geokit::GeoLoc.new(country_code: "Wales", state: "Islington")
    LocationGeocoder.any_instance.stubs(:geocode).returns(geocode_payload)

    click_button "Sign up"
  end
end
