require "test_helper"

class Client < ActiveSupport::TestCase
  include Rails.application.routes.url_helpers

  setup do
    ENV["SMS_ENABLED"] = "true"
  end

  test "#send_message" do
    message = create(:message)

    stub_successful_twilio_call(message.body, message.user)

    Twilio::Client.new.send_message(message)

    assert_equal "accepted", message.reload.status
    assert_equal "123", message.message_sid
  end

  test "#send_message returns Twilio error" do
    message = create(:message)

    stub_unsuccessful_twilio_call(message.body, message.user)

    Twilio::Client.new.send_message(message)

    assert_equal "failed", message.reload.status
  end

  test "#send_message does not send message when SMS is disabled" do
    message = create(:message)

    ENV["SMS_ENABLED"] = "false"

    Twilio::Client.new.send_message(message)

    assert_nil message.reload.status
  end
end
