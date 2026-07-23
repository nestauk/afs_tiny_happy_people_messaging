require "test_helper"

class CookieConsentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    Ahoy::Tracker.any_instance.stubs(:visit).returns(Ahoy::Visit.new)
  end

  test "accept_all sets the cookie_consent cookie with all categories granted" do
    post cookie_consent_path, params: {decision: "accept_all", return_to: "/"}
    consent = JSON.parse(cookies[:cookie_consent])
    assert consent["analytics"]
    assert consent["marketing"]
    assert consent["statistical"]
  end

  test "reject_all sets the cookie_consent cookie with all categories denied" do
    post cookie_consent_path, params: {decision: "reject_all", return_to: "/"}
    consent = JSON.parse(cookies[:cookie_consent])
    assert_not consent["analytics"]
    assert_not consent["marketing"]
    assert_not consent["statistical"]
  end

  test "saving granular preferences only grants the checked categories" do
    post cookie_consent_path, params: {analytics: "1", marketing: "0", statistical: "1", return_to: "/cookie_policy"}
    consent = JSON.parse(cookies[:cookie_consent])
    assert consent["analytics"]
    assert_not consent["marketing"]
    assert consent["statistical"]
  end

  test "unchecked checkboxes (absent params) are treated as declined" do
    post cookie_consent_path, params: {return_to: "/"}
    consent = JSON.parse(cookies[:cookie_consent])
    assert_not consent["analytics"]
    assert_not consent["marketing"]
    assert_not consent["statistical"]
  end

  test "redirects to the return_to path when it is a relative path" do
    post cookie_consent_path, params: {decision: "accept_all", return_to: "/cookie_policy"}
    assert_redirected_to "/cookie_policy"
  end

  test "falls back to root when no return_to is given and there is no referer" do
    post cookie_consent_path, params: {decision: "accept_all"}
    assert_redirected_to root_path
  end

  test "sets a result flash so the next page shows a confirmation message" do
    post cookie_consent_path, params: {decision: "accept_all", return_to: "/"}
    assert_equal "accepted", flash[:cookie_consent_result]
  end

  test "clears ahoy_dnt when statistical consent is granted" do
    cookies[:ahoy_dnt] = "1"
    post cookie_consent_path, params: {decision: "accept_all", return_to: "/"}
    assert_nil cookies[:ahoy_dnt]
  end

  test "sets ahoy_dnt when statistical consent is declined" do
    post cookie_consent_path, params: {decision: "reject_all", return_to: "/"}
    assert_equal "1", cookies[:ahoy_dnt]
  end

  test "tracks an ahoy cookie_consent event per category" do
    Ahoy::Tracker.any_instance.expects(:track).with("cookie_consent", page: "/", category: "analytics", decision: "accepted")
    Ahoy::Tracker.any_instance.expects(:track).with("cookie_consent", page: "/", category: "marketing", decision: "accepted")
    Ahoy::Tracker.any_instance.expects(:track).with("cookie_consent", page: "/", category: "statistical", decision: "accepted")
    post cookie_consent_path, params: {decision: "accept_all", return_to: "/"}
  end

  test "does not track when there is no ahoy visit" do
    Ahoy::Tracker.any_instance.stubs(:visit).returns(nil)
    Ahoy::Tracker.any_instance.expects(:track).never
    post cookie_consent_path, params: {decision: "accept_all", return_to: "/"}
  end

  test "rejects a request without a valid CSRF token when forgery protection is enabled" do
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true
    assert_raises(ActionController::InvalidAuthenticityToken) do
      post cookie_consent_path, params: {decision: "accept_all", return_to: "/"}
    end
  ensure
    ActionController::Base.allow_forgery_protection = original
  end
end
