require "test_helper"
require "rake"

class SchedulerTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    ENV["WEEKLY_NUDGE_DAY"] = "1"
    ENV["SET_WEEKLY"] = "true"

    AfsTinyHappyPeople::Application.load_tasks if Rake::Task.tasks.empty?
  end

  test "check_for_disengaged_users" do
    user1 = create(:user)
    content = create(:content)
    create(:message, user: user1, clicked_at: nil, content:)
    create(:message, user: user1, clicked_at: nil, content:)

    user2 = create(:user)
    create(:message, user: user2, clicked_at: nil, content:)
    create(:message, user: user2, clicked_at: Time.now, content:)

    user3 = create(:user, nudged_at: Time.now)
    create(:message, user: user3, clicked_at: nil, content:)
    create(:message, user: user3, clicked_at: nil, content:)

    assert_enqueued_with(job: SendCustomMessageJob) do
      Rake::Task["scheduler:check_for_disengaged_users"].execute
    end

    assert_equal 1, Message.where(body: "You've not interacted with any videos lately. You can text 'PAUSE' for a break or 'END' to stop them entirely.").count
  end
end
