require "test_helper"

class SendBulkMessageJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "#perform creates jobs to send messages to users" do
    users = create_list(:user, 3, child_birthday: 7.months.ago)
    group = create(:group)
    create(:content, group:)

    assert_enqueued_jobs 3 do
      SendBulkMessageJob.perform_now(users)
    end
  end
end
