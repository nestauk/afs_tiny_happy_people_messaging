require "test_helper"

class SendBulkMessageJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "#perform creates jobs to send messages to users" do
    users = create_list(:user, 3, child_birthday: 3.months.ago)
    group = create(:group, age_in_months: 3)
    create(:content, group:)

    assert_enqueued_jobs 3 do
      SendBulkMessageJob.perform_now(users, group)
    end
  end

  test "#perform does not create jobs if group is not present" do
    users = create_list(:user, 3, child_birthday: 3.months.ago)
    group = nil

    assert_no_enqueued_jobs do
      SendBulkMessageJob.perform_now(users, group)
    end
  end
end
