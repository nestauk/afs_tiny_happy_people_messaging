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

    test "#deliver, when AWS rejects, marks message as failed and reports the error and its details" do
      message = create(:message)
      stub_unsuccessful_aws_call(message.body, message.user)
      Appsignal.expects(:report_error).with(kind_of(Aws::PinpointSMSVoiceV2::Errors::ServiceError)).yields
      Appsignal.expects(:add_tags).with(
        message_id: message.id,
        user_id: message.user.id,
        aws_event_type: "ValidationException",
        aws_status_description: "Invalid phone number",
      )

      Sms::AwsAdapter.new(message).deliver

      assert_equal "failed", message.reload.status
    end

    test "#deliver, when AWS rejects, truncates a long AWS error message in the Appsignal tag" do
      message = create(:message)
      error = Aws::PinpointSMSVoiceV2::Errors::ValidationException.new(nil, "x" * 400)
      Aws::PinpointSMSVoiceV2::Client.any_instance.stubs(:send_text_message).raises(error)
      Appsignal.stubs(:report_error).yields
      Appsignal.expects(:add_tags).with { |tags| tags[:aws_status_description].length == 255 }

      Sms::AwsAdapter.new(message).deliver

      assert_equal "failed", message.reload.status
    end
  end
end
