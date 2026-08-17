require "test_helper"

class Admin::BroadcastsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @admin = create(:admin)
    sign_in @admin
  end

  test "index returns success" do
    get admin_broadcasts_path
    assert_response :success
  end

  test "new returns success" do
    get new_admin_broadcast_path
    assert_response :success
  end

  test "show returns success" do
    broadcast = create(:broadcast)
    get admin_broadcast_path(broadcast)
    assert_response :success
  end

  test "create creates a broadcast and redirects to the index" do
    SendBroadcastJob.expects(:perform_later)

    assert_difference "Broadcast.count", 1 do
      post admin_broadcasts_path, params: {
        broadcast: {body_en: "New broadcast", body_cy: "New broadcast in Welsh", user_groups: ["welsh_pilot"]},
      }
    end
    assert_redirected_to admin_broadcasts_path
    assert_equal "Broadcast sent successfully.", flash[:notice]
  end

  test "create re-renders new with invalid params" do
    assert_no_difference "Broadcast.count" do
      post admin_broadcasts_path, params: {
        broadcast: {body_en: "", body_cy: "", user_groups: []},
      }
    end
    assert_response :unprocessable_entity
  end
end
