require "test_helper"

class MessagesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  include ActiveJob::TestHelper

  setup do
    @user = create(:user)
    ENV["TWILIO_AUTH_TOKEN"] = "test_token"
  end

  test "#status should queue job if message failed" do
    message = create(:message)

    MessagesController.any_instance.stubs(:valid_twilio_request?).returns(true)

    post messages_status_url, params: {MessageSid: message.message_sid, MessageStatus: "failed"}

    assert_response :success
    assert_enqueued_jobs 1, only: UpdateMessageStatusJob
  end

  test "#status shouldn't queue job if message is successful" do
    message = create(:message)

    MessagesController.any_instance.stubs(:valid_twilio_request?).returns(true)

    post messages_status_url, params: {MessageSid: message.message_sid, MessageStatus: "delivered"}

    assert_response :success
    assert_enqueued_jobs 0
  end

  test "#status should queue job if message has failed" do
    message = create(:message)

    MessagesController.any_instance.stubs(:valid_twilio_request?).returns(true)

    post messages_status_url, params: {MessageSid: message.message_sid, MessageStatus: "failed"}

    assert_response :success
    assert_enqueued_jobs 1, only: UpdateMessageStatusJob
  end

  test "#status returns 403 and logs when twilio signature is invalid" do
    message = create(:message)

    MessagesController.any_instance.stubs(:valid_twilio_request?).returns(false)

    post messages_status_url, params: {MessageSid: message.message_sid, MessageStatus: "delivered"}

    assert_response :forbidden
    assert_enqueued_jobs 0
  end

  test "#status returns 403 and reports to Appsignal when TWILIO_AUTH_TOKEN is blank" do
    ENV["TWILIO_AUTH_TOKEN"] = nil
    Appsignal.expects(:report_error).with do |error|
      error.message.include?("TWILIO_AUTH_TOKEN is not configured")
    end

    post messages_status_url, params: {MessageSid: "sid", MessageStatus: "delivered"}

    assert_response :forbidden
    assert_enqueued_jobs 0
  end

  test "#incoming returns 403 when twilio signature is invalid and does not create a message" do
    MessagesController.any_instance.stubs(:valid_twilio_request?).returns(false)

    assert_no_difference "Message.count" do
      post messages_incoming_url, params: {From: @user.phone_number, Body: "spoofed", MessageSid: "sid"}
    end
    assert_response :forbidden
  end

  test "#incoming returns 403 when TWILIO_AUTH_TOKEN is blank and does not create a message" do
    ENV["TWILIO_AUTH_TOKEN"] = nil
    Appsignal.expects(:report_error)

    assert_no_difference "Message.count" do
      post messages_incoming_url, params: {From: @user.phone_number, Body: "spoofed", MessageSid: "sid"}
    end
    assert_response :forbidden
  end

  test "#incoming should handle incoming message" do
    travel_to Time.current.beginning_of_week
    MessagesController.any_instance.stubs(:valid_twilio_request?).returns(true)

    post messages_incoming_url, params: {From: @user.phone_number, Body: "Hi", MessageSid: "new_sid"}
    assert_response :success

    assert_equal "Hi", @user.messages.last.body
  end

  test "#incoming should send out of office on weekends" do
    travel_to Time.current.end_of_week
    MessagesController.any_instance.stubs(:valid_twilio_request?).returns(true)

    post messages_incoming_url, params: {From: @user.phone_number, Body: "Hi", MessageSid: "new_sid"}
    assert_response :success
    perform_enqueued_jobs

    assert_equal "The team's working hours are 9am - 6pm, Monday to Friday. We'll get back to you as soon as we can.", @user.messages.last.body
  end

  test "#incoming should handle incoming message with stop" do
    create(:auto_response, trigger_phrase: "stop", update_user: "{\"contactable\": false}")
    MessagesController.any_instance.stubs(:valid_twilio_request?).returns(true)

    post messages_incoming_url, params: {From: @user.phone_number, Body: "STOP", MessageSid: "new_sid"}
    assert_response :success
    perform_enqueued_jobs
    @user.reload
    assert_equal @user.contactable, false
  end

  test "#next should redirect to message link if exists" do
    message = create(:message, link: "http://bbc.co.uk/test")
    get track_link_url(token: message.token)
    assert_redirected_to message.link
    message.reload
    assert_not_nil message.clicked_at
  end

  test "#next only redirects if message content link comes from approved list" do
    message = create(:message, link: "http://example.com/test")
    get track_link_url(token: message.token)
    assert_redirected_to "https://www.bbc.co.uk/tiny-happy-people"
  end

  test "#next should redirect to CBeebies Parenting homepage if system can't find the message" do
    get track_link_url(token: "123")
    assert_redirected_to "https://www.bbc.co.uk/tiny-happy-people"
  end
end
