require "test_helper"

class ApplicationControllerTest < ActionDispatch::IntegrationTest
  setup do
    Ahoy::Tracker.any_instance.stubs(:visit).returns(Ahoy::Visit.new)
  end

  test "does not record a Skadi view when statistical consent has not been decided" do
    assert_no_difference "Skadi::View.count" do
      get "/privacy_policy"
    end
  end

  test "does not record a Skadi view when statistical consent is declined" do
    post cookie_consent_path, params: {decision: "reject_all", return_to: "/privacy_policy"}

    assert_no_difference "Skadi::View.count" do
      get "/privacy_policy"
    end
  end

  test "records a Skadi view when statistical consent is accepted" do
    post cookie_consent_path, params: {decision: "accept_all", return_to: "/privacy_policy"}

    assert_difference "Skadi::View.count", 1 do
      get "/privacy_policy"
    end
  end
end
