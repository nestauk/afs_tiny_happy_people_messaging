require "test_helper"

class Admin::MessagesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = create(:user)
    sign_in create(:admin)
  end

  test "#create should create message" do
    assert_difference("Message.count", 1) do
      post admin_user_messages_path(@user), params: {message: {body: "Test message", user_id: @user.id}}
    end

    assert_enqueued_jobs 1

    assert_redirected_to admin_user_path(@user)
  end
end
