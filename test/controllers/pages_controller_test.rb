require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  test "terms returns success" do
    get terms_path
    assert_response :success
  end

  test "privacy returns success" do
    get privacy_policy_path
    assert_response :success
  end

  test "about_us returns success" do
    get about_us_path
    assert_response :success
  end

  test "resources returns success" do
    get resources_path
    assert_response :success
  end

  test "cookies returns success" do
    get cookie_policy_path
    assert_response :success
  end

  test "accessibility returns success" do
    get accessibility_path
    assert_response :success
  end
end
