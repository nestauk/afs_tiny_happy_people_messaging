require "test_helper"

# Drives the whole cookie consent flow with plain get/post requests - no
# Capybara, no JS driver - to prove it works even when a visitor's browser
# never executes any JavaScript.
class CookieConsentFlowTest < ActionDispatch::IntegrationTest
  setup do
    Rails.env.stubs(:production?).returns(true)
    Ahoy::Tracker.any_instance.stubs(:visit).returns(Ahoy::Visit.new)
  end

  test "ask banner shows on first visit, accepting all persists consent and shows a confirmation, then the banner is gone" do
    get "/privacy_policy"
    assert_response :success
    assert_see I18n.t("pages.cookie_banner.message")

    post cookie_consent_path, params: {decision: "accept_all", return_to: "/privacy_policy"}
    assert_redirected_to "/privacy_policy"

    follow_redirect!
    assert_response :success
    assert_see I18n.t("pages.cookie_banner.accepted_message")
    assert_dont_see I18n.t("pages.cookie_banner.message")

    get "/privacy_policy"
    assert_response :success
    assert_dont_see I18n.t("pages.cookie_banner.message")
    assert_dont_see I18n.t("pages.cookie_banner.accepted_message")
  end

  test "rejecting all cookies is honoured on the next page load" do
    post cookie_consent_path, params: {decision: "reject_all", return_to: "/privacy_policy"}
    follow_redirect!
    assert_see I18n.t("pages.cookie_banner.rejected_message")

    get "/privacy_policy"
    consent = JSON.parse(cookies[:cookie_consent])
    assert_not consent["analytics"]
    assert_not consent["marketing"]
    assert_not consent["statistical"]
  end

  test "granular preferences can be reviewed and saved from the cookie policy page" do
    get "/cookie_policy"
    assert_response :success
    assert_see I18n.t("pages.cookie_policy.preferences_heading")

    post cookie_consent_path, params: {analytics: "1", marketing: "0", statistical: "1", return_to: "/cookie_policy"}
    follow_redirect!

    assert_response :success
    assert_see I18n.t("pages.cookie_banner.saved_message")
    consent = JSON.parse(cookies[:cookie_consent])
    assert consent["analytics"]
    assert_not consent["marketing"]
    assert consent["statistical"]
  end

  test "the banner does not render outside production" do
    Rails.env.stubs(:production?).returns(false)
    get "/privacy_policy"
    assert_dont_see I18n.t("pages.cookie_banner.message")
  end
end
