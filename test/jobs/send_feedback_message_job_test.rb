require "test_helper"

class SendFeedbackMessageJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  include Rails.application.routes.url_helpers

  test "#perform sends message with default content" do
    user = create(:user, child_birthday: 18.months.ago)

    stub_successful_twilio_call("Are the activities we send you suitable for your child? Respond Yes or No to let us know.", user)

    SendFeedbackMessageJob.new.perform(user)

    assert_equal 1, Message.count
    assert_match("Are the activities we send you suitable for your child? Respond Yes or No to let us know.", Message.last.body)
  end

  test "#perform does not send message if message is not valid" do
    user = create(:user, child_birthday: 18.months.ago)

    Message.any_instance.stubs(:save).returns(false)

    SendFeedbackMessageJob.new.perform(user)

    assert_equal 0, Message.count
  end
end
