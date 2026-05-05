require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @admin = create(:admin, email: "admin@example.com")
  end

  test "new renders the sign-in form" do
    get new_admin_session_path
    assert_response :success
  end

  test "create is rate limited per IP after 3 attempts in 5 minutes" do
    ip = "1.2.3.4"

    3.times do
      post admin_session_path,
        params: {admin: {email: @admin.email}},
        headers: {"REMOTE_ADDR" => ip}
    end

    # 4th request should hit the rate limiter
    post admin_session_path,
      params: {admin: {email: @admin.email}},
      headers: {"REMOTE_ADDR" => ip}
    assert_redirected_to root_path
    assert_equal "Too many attempts. Try again later.", flash[:notice]
  end

  test "create allows requests from a different IP even when one IP is rate limited" do
    blocked_ip = "1.2.3.4"

    4.times do
      post admin_session_path,
        params: {admin: {email: @admin.email}},
        headers: {"REMOTE_ADDR" => blocked_ip}
    end

    post admin_session_path,
      params: {admin: {email: @admin.email}},
      headers: {"REMOTE_ADDR" => "5.6.7.8"}
    assert_not_equal root_path, response.location
  end

  test "create allows the original IP again after the rate-limit window expires" do
    ip = "1.2.3.4"

    3.times do
      post admin_session_path,
        params: {admin: {email: @admin.email}},
        headers: {"REMOTE_ADDR" => ip}
      assert_not_equal root_path, response.location
    end

    post admin_session_path,
      params: {admin: {email: @admin.email}},
      headers: {"REMOTE_ADDR" => ip}
    assert_redirected_to root_path

    travel 6.minutes do
      post admin_session_path,
        params: {admin: {email: @admin.email}},
        headers: {"REMOTE_ADDR" => ip}
      assert_not_equal root_path, response.location
    end
  end
end
