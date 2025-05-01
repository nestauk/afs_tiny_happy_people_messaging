require "test_helper"

class SendFeedbackMessageJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  include Rails.application.routes.url_helpers

  test "#perform sends message with default content" do
    user = create(:user, child_birthday: 18.months.ago)

    assert_enqueued_jobs 1, only: SendCustomMessageJob do
      SendFeedbackMessageJob.new.perform(user)
    end

    assert_equal 1, Message.count
    assert_match("Are the activities we send you suitable for your child? Respond Yes or No to let us know.", Message.last.body)
    assert user.asked_for_feedback
  end

  test "#perform does not send message if message is not valid" do
    user = create(:user, child_birthday: 18.months.ago)

    Message.any_instance.stubs(:save).returns(false)

    assert_no_enqueued_jobs do
      SendFeedbackMessageJob.new.perform(user)
    end

    assert_equal 0, Message.count
  end
end
