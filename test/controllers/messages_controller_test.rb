require "test_helper"
# require 'minitest/stub_any_instance'

class MessagesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = create(:user)
    sign_in create(:admin)
  end

  test "should create message" do
    assert_difference("Message.count", 1) do
      post user_messages_path(@user), params: {message: {body: "Test message", user_id: @user.id}}
    end

    assert_enqueued_jobs 1

    assert_redirected_to user_path(@user)
  end

  test "should update message status" do
    message = create(:message)

    MessagesController.any_instance.stubs(:valid_twilio_request?).returns(true)

    post messages_status_url, params: {MessageSid: message.message_sid, MessageStatus: "delivered"}

    assert_response :success
    message.reload
    assert_equal "delivered", message.status
  end

  test "should handle incoming message" do
    MessagesController.any_instance.stubs(:valid_twilio_request?).returns(true)

    post messages_incoming_url, params: {From: @user.phone_number, Body: "Hi", MessageSid: "new_sid"}
    assert_response :success

    assert_equal "Hi", @user.messages.last.body
  end

  test "should handle incoming message with stop" do
    MessagesController.any_instance.stubs(:valid_twilio_request?).returns(true)

    post messages_incoming_url, params: {From: @user.phone_number, Body: "Stop", MessageSid: "new_sid"}
    assert_response :success
    @user.reload
    assert_equal @user.contactable, false
  end

  test "should handle incoming message with pause" do
    MessagesController.any_instance.stubs(:valid_twilio_request?).returns(true)

    post messages_incoming_url, params: {From: @user.phone_number, Body: "pause", MessageSid: "new_sid"}
    assert_response :success
    @user.reload
    assert_equal @user.contactable, false
    refute_nil @user.restart_at
  end

  test "should handle incoming message with start" do
    @user.update(contactable: false)
    MessagesController.any_instance.stubs(:valid_twilio_request?).returns(true)

    post messages_incoming_url, params: {From: @user.phone_number, Body: "start", MessageSid: "new_sid"}
    assert_response :success
    @user.reload
    assert_equal @user.contactable, true
  end

  test "should handle next message" do
    message = create(:message, link: "http://example.com")
    get track_link_url(token: message.token)
    assert_redirected_to message.link
    message.reload
    assert_not_nil message.clicked_at
  end
end
