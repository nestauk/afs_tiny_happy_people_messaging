require "test_helper"

module Sms
  class AwsAdapterTest < ActiveSupport::TestCase
    test "#deliver sends the message via AWS and records the AWS message id" do
      message = create(:message)
      stub_successful_aws_call(message.body, message.user, aws_message_id: "aws-1")

      Sms::AwsAdapter.new(message).deliver

      message.reload
      assert_equal "sent", message.status
      assert_equal "aws-1", message.message_sid
    end

    test "#deliver counts a successful send_attempt" do
      message = create(:message)
      stub_successful_aws_call(message.body, message.user)

      Sms::AwsAdapter.new(message).deliver

      assert_equal 1, message.reload.send_attempts
    end

    test "#deliver counts a failed send_attempt" do
      message = create(:message)
      stub_unsuccessful_aws_call(message.body, message.user)

      Sms::AwsAdapter.new(message).deliver

      assert_equal 1, message.reload.send_attempts
    end

    test "#deliver marks the message as failed and reports the error when AWS rejects" do
      message = create(:message)
      stub_unsuccessful_aws_call(message.body, message.user)
      Appsignal.expects(:report_error).with(kind_of(Aws::PinpointSMSVoiceV2::Errors::ServiceError))

      Sms::AwsAdapter.new(message).deliver

      assert_equal "failed", message.reload.status
    end

    test "#deliver counts when a failed message being retried" do
      message = create(:message)
      stub_unsuccessful_aws_call(message.body, message.user)
      Sms::AwsAdapter.new(message).deliver
      stub_successful_aws_call(message.body, message.user, aws_message_id: "aws-2")

      Sms::AwsAdapter.new(message.reload).deliver

      message.reload
      assert_equal 2, message.send_attempts
      assert_equal "sent", message.status
    end
  end
end
