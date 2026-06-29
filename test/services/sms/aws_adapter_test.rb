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

    test "#deliver marks the message as failed and reports the error when AWS rejects" do
      message = create(:message)
      stub_unsuccessful_aws_call(message.body, message.user)
      Appsignal.expects(:report_error).with(kind_of(Aws::PinpointSMSVoiceV2::Errors::ServiceError))

      Sms::AwsAdapter.new(message).deliver

      assert_equal "failed", message.reload.status
    end
  end
end
