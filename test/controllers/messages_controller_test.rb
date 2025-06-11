require "test_helper"

class MessagesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = create(:user)
    sign_in create(:admin)
  end

  test "#index local authority admins can't access" do
    admin = create(:admin, role: "local_authority", email: "local_authority@email.com")
    sign_in admin
    get user_messages_path(@user)
    assert_response :redirect
  end

  test "#create should create message" do
    assert_difference("Message.count", 1) do
      post user_messages_path(@user), params: {message: {body: "Test message", user_id: @user.id}}
    end

    assert_enqueued_jobs 1

    assert_redirected_to user_path(@user)
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

  test "#status does not queue job if twilio request isn't valid" do
    message = create(:message)

    MessagesController.any_instance.stubs(:valid_twilio_request?).returns(false)

    post messages_status_url, params: {MessageSid: message.message_sid, MessageStatus: "delivered"}

    assert_response :success
    assert_enqueued_jobs 0
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

    assert_equal "The team's working hours are 9am - 6pm, Monday to Friday. We'll get back to you as soon as we can.", @user.messages.last.body
  end

  test "#incoming should handle incoming message with stop" do
    create(:auto_response, trigger_phrase: "stop", update_user: "{\"contactable\": false}")
    MessagesController.any_instance.stubs(:valid_twilio_request?).returns(true)

    post messages_incoming_url, params: {From: @user.phone_number, Body: "STOP", MessageSid: "new_sid"}
    assert_response :success
    @user.reload
    assert_equal @user.contactable, false
  end

  test "#incoming should handle incoming message with pause" do
    create(:auto_response, trigger_phrase: "pause", response: "Thanks, you've paused for 4 weeks.", update_user: '{"contactable": false, "restart_at": "4.weeks.from_now.noon"}')
    MessagesController.any_instance.stubs(:valid_twilio_request?).returns(true)

    post messages_incoming_url, params: {From: @user.phone_number, Body: "Pause ", MessageSid: "new_sid"}
    assert_response :success
    @user.reload
    refute @user.contactable
    refute_nil @user.restart_at
  end

  test "#incoming should handle incoming message with start" do
    create(:auto_response, trigger_phrase: "start", update_user: "{\"contactable\": true}")
    @user.update(contactable: false)
    MessagesController.any_instance.stubs(:valid_twilio_request?).returns(true)

    post messages_incoming_url, params: {From: @user.phone_number, Body: "start  ", MessageSid: "new_sid"}
    assert_response :success
    @user.reload
    assert_equal @user.contactable, true
  end

  test "#next should redirect to message link if exists" do
    message = create(:message, link: "http://example.com")
    get track_link_url(token: message.token)
    assert_redirected_to message.link
    message.reload
    assert_not_nil message.clicked_at
  end

  test "#next should redirect to Tiny Happy People homepage if system can't find the message" do
    get track_link_url(token: "123")
    assert_redirected_to "https://www.bbc.co.uk/tiny-happy-people"
  end
end
