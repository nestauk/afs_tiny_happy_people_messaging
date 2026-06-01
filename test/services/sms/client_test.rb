require "test_helper"

module Sms
  class ClientTest < ActiveSupport::TestCase
    setup do
      ENV["SMS_ENABLED"] = "true"
    end

    test "#send_message dispatches to the Twilio adapter when sms_provider is twilio" do
      user = create(:user, sms_provider: "twilio")
      message = create(:message, user: user)
      adapter = mock
      adapter.expects(:deliver)
      Sms::TwilioAdapter.expects(:new).with(message).returns(adapter)

      Sms::Client.new(message).send_message
    end

    test "#send_message dispatches to the AWS adapter when sms_provider is aws" do
      user = create(:user, sms_provider: "aws")
      message = create(:message, user: user)
      adapter = mock
      adapter.expects(:deliver)
      Sms::AwsAdapter.expects(:new).with(message).returns(adapter)

      Sms::Client.new(message).send_message
    end

    test "#send_message does nothing when SMS is disabled" do
      ENV["SMS_ENABLED"] = "false"
      message = create(:message, user: create(:user, sms_provider: "aws"))
      Sms::AwsAdapter.expects(:new).never
      Sms::TwilioAdapter.expects(:new).never

      Sms::Client.new(message).send_message
    end

    test "#send_message reports to Appsignal when sms_provider is not recognised" do
      message = create(:message, user: create(:user, sms_provider: "aws"))
      message.user.update_column(:sms_provider, "carrier_pigeon")
      Appsignal.expects(:report_error).with do |error|
        error.message.include?("Unsupported SMS provider")
      end

      assert_raises(NoMethodError) do
        Sms::Client.new(message).send_message
      end
    end
  end
end
