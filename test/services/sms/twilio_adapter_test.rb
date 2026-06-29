require "test_helper"

module Sms
  class TwilioAdapterTest < ActiveSupport::TestCase
    test "#deliver sends the message and records the Twilio status and sid" do
      message = create(:message)
      stub_successful_twilio_call(message.body, message.user)

      Sms::TwilioAdapter.new(message).deliver

      assert_equal "accepted", message.reload.status
      assert_equal "123", message.message_sid
    end

    test "#deliver marks the message as failed and reports the error when Twilio rejects" do
      message = create(:message)
      stub_unsuccessful_twilio_call(message.body, message.user)
      Appsignal.expects(:report_error).with(instance_of(Twilio::REST::RestError))

      Sms::TwilioAdapter.new(message).deliver

      assert_equal "failed", message.reload.status
    end
  end
end
