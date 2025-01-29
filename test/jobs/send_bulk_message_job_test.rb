require "test_helper"

class SendBulkMessageJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "#perform creates jobs to send messages to users" do
    users = create_list(:user, 3, child_birthday: 7.months.ago)

    assert_enqueued_jobs 3, only: SendMessageJob do
      SendBulkMessageJob.perform_now(users, :weekly_message)
    end
  end

  test "#perform creates jobs to send feedback to users" do
    users = create_list(:user, 3, child_birthday: 7.months.ago)

    assert_enqueued_jobs 3, only: SendFeedbackMessageJob do
      SendBulkMessageJob.perform_now(users, :feedback)
    end
  end

  test "#perform does not create jobs if not passed a valid message type" do
    users = create_list(:user, 3, child_birthday: 7.months.ago)

    assert_no_enqueued_jobs do
      SendBulkMessageJob.perform_now(users, :invalid_type)
    end
  end
end
