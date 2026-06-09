require "test_helper"

class Admin::DashboardsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @local_authority = create(:local_authority)
    sign_in create(:admin)
  end

  test "can see data dashboard" do
    get admin_dashboard_path
    assert_response :success

    assert_see "Data dashboard"
  end

  test "cannot fetch data without signing in" do
    sign_out :admin

    get admin_dashboard_path, params: {q: @local_authority.name, timeframe: "year"}

    assert_response :redirect
    assert_redirected_to new_admin_session_path
  end
end
