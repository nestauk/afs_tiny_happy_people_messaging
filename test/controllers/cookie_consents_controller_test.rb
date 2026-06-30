require "test_helper"

class CookieConsentsControllerTest < ActionDispatch::IntegrationTest
  test "returns no_content for valid analytics accepted" do
    post cookie_consent_path, params: {page: "home", category: "analytics", decision: "accepted"}, as: :json
    assert_response :no_content
  end

  test "returns no_content for valid analytics declined" do
    post cookie_consent_path, params: {page: "home", category: "analytics", decision: "declined"}, as: :json
    assert_response :no_content
  end

  test "returns no_content for valid marketing accepted" do
    post cookie_consent_path, params: {page: "home", category: "marketing", decision: "accepted"}, as: :json
    assert_response :no_content
  end

  test "returns no_content for valid marketing declined" do
    post cookie_consent_path, params: {page: "home", category: "marketing", decision: "declined"}, as: :json
    assert_response :no_content
  end

  test "tracks a cookie_consent event in ahoy for valid params" do
    Ahoy::Tracker.any_instance.expects(:track).with("cookie_consent", page: "home", category: "analytics", decision: "accepted")
    post cookie_consent_path, params: {page: "home", category: "analytics", decision: "accepted"}, as: :json
  end

  test "does not track an event for an unknown category" do
    Ahoy::Tracker.any_instance.expects(:track).never
    post cookie_consent_path, params: {page: "home", category: "unknown", decision: "accepted"}, as: :json
    assert_response :no_content
  end

  test "does not track an event for an unknown decision" do
    Ahoy::Tracker.any_instance.expects(:track).never
    post cookie_consent_path, params: {page: "home", category: "analytics", decision: "maybe"}, as: :json
    assert_response :no_content
  end

  test "does not track an event when params are missing" do
    Ahoy::Tracker.any_instance.expects(:track).never
    post cookie_consent_path, as: :json
    assert_response :no_content
  end
end
