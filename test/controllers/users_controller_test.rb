require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    create(:group, language: "en")
    geocode_payload = Geokit::GeoLoc.new(country_code: "Wales")
    LocationGeocoder.any_instance.stubs(:geocode).returns(geocode_payload)
  end

  test "create is rate limited" do
    ip = "1.2.3.4"

    # Make 5 requests from the same IP
    5.times do |i|
      post users_path, params: {user: {phone_number: "0712345678#{i}", terms_agreed: "1", child_birthday: 1.year.ago, postcode: "ABC 123", language: "en"}}, headers: {"REMOTE_ADDR" => ip}
      assert_response :redirect
    end

    # 6th request should be blocked
    post users_path, params: {user: {phone_number: "07123456789", terms_agreed: "1", child_birthday: 1.year.ago, postcode: "ABC 123", language: "en"}}, headers: {"REMOTE_ADDR" => ip}
    assert_response :unprocessable_content
    assert_equal "Too many attempts. Try again later.", flash[:notice]

    # Request from a different IP should work
    post users_path, params: {user: {phone_number: "07123456799", terms_agreed: "1", child_birthday: 1.year.ago, postcode: "ABC 123", language: "en"}}, headers: {"REMOTE_ADDR" => "5.6.7.8"}
    assert_response :redirect

    # After 5 minutes, the original IP should be able to make requests again
    travel 6.minutes do
      post users_path, params: {user: {phone_number: "07123456700", terms_agreed: "1", child_birthday: 1.year.ago, postcode: "ABC 123", language: "en"}}, headers: {"REMOTE_ADDR" => ip}
      assert_response :redirect
    end
  end

  test "create with valid params creates a user and redirects" do
    stub_successful_twilio_call("Hi! Thanks for joining the waitlist for our programme of weekly texts with fun activities for your child's development. We'll be in touch when it's time to get started. In the meantime, why not save this number as 'CBeebies Parenting' so you can easily see when it's us texting you?", build(:user, phone_number: "+447123456700"))

    post users_path, params: {user: {phone_number: "07123456700", terms_agreed: "1", child_birthday: 1.year.ago, postcode: "ABC 123", language: "en"}}
    assert_response :redirect
    assert User.exists?(phone_number: "+447123456700")
  end

  test "puts user on waitlist if child is under 9 months" do
    create(:group, language: "cy")

    stub_successful_twilio_call("Helo! Diolch am ymuno â'r rhestr aros ar gyfer ein rhaglen o negeseuon wythnosol gyda gweithgareddau hwyliog ar gyfer datblygiad eich plentyn. Byddwn mewn cysylltiad pan ddaw'r amser i ddechrau. Yn y cyfamser, beth am gadw'r rhif hwn fel 'CBeebies Parenting' fel eich bod yn gwybod mai ni sy'n anfon negeseuon atoch?", build(:user, phone_number: "+447123456700"))

    post users_path, params: {user: {phone_number: "07123456700", terms_agreed: "1", child_birthday: 6.months.ago, postcode: "ABC 123", language: "cy", skip_age_validation: "1"}}
    assert_response :redirect

    user = User.find_by(phone_number: "+447123456700")
    assert_not user.contactable
    assert_equal (user.child_birthday + 9.months), user.restart_at
  end
end
