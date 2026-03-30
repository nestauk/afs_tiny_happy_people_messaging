require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "create is rate limited" do
    ip = "1.2.3.4"

    group = create(:group)

    geocode_payload = Geokit::GeoLoc.new(country_code: "Wales")
    LocationGeocoder.any_instance.stubs(:geocode).returns(geocode_payload)

    # Make 5 requests from the same IP
    5.times do |i|
      post users_path, params: {user: {phone_number: "0712345678#{i}", terms_agreed_at: Time.zone.now, first_name: "Test", child_birthday: 1.year.ago, postcode: "ABC 123", group_id: group.id}}, headers: {"REMOTE_ADDR" => ip}
      assert_response :redirect
    end

    # 6th request should be blocked
    post users_path, params: {user: {phone_number: "07123456789", terms_agreed_at: Time.zone.now, first_name: "Test", child_birthday: 1.year.ago, postcode: "ABC 123", group_id: group.id}}, headers: {"REMOTE_ADDR" => ip}
    assert_response :unprocessable_content
    assert_equal "Too many attempts. Try again later.", flash[:notice]

    # Request from a different IP should work
    post users_path, params: {user: {phone_number: "07123456799", terms_agreed_at: Time.zone.now, first_name: "Test", child_birthday: 1.year.ago, postcode: "ABC 123", group_id: group.id}}, headers: {"REMOTE_ADDR" => "5.6.7.8"}
    assert_response :redirect

    # After 5 minutes, the original IP should be able to make requests again
    travel 6.minutes do
      post users_path, params: {user: {phone_number: "07123456700", terms_agreed_at: Time.zone.now, first_name: "Test", child_birthday: 1.year.ago, postcode: "ABC 123", group_id: group.id}}, headers: {"REMOTE_ADDR" => ip}
      assert_response :redirect
    end
  end
end
