require "test_helper"

class Admin::MessagesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = create(:user)
    sign_in create(:admin)
  end

  test "#index local authority admins can't access" do
    admin = create(:admin, role: "local_authority", email: "local_authority@email.com")
    sign_in admin
    get admin_user_messages_path(@user)
    assert_response :redirect
  end

  test "#create should create message" do
    assert_difference("Message.count", 1) do
      post admin_user_messages_path(@user), params: {message: {body: "Test message", user_id: @user.id}}
    end

    assert_enqueued_jobs 1

    assert_redirected_to admin_user_path(@user)
  end
end
