require "test_helper"
require "rake"

class SchedulerTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    ENV["WEEKLY_NUDGE_DAY"] = "1"
    ENV["SET_WEEKLY"] = "true"

    AfsTinyHappyPeople::Application.load_tasks if Rake::Task.tasks.empty?
  end

  test "restart_users" do
    user = create(:user, contactable: false, restart_at: Time.now - 1.day)
    user2 = create(:user, contactable: false, restart_at: Time.now + 1.day)
    user3 = create(:user, contactable: true)

    assert_enqueued_with(job: RestartMessagesJob) do
      Rake::Task["scheduler:restart_users"].execute
    end

    user.reload
    assert user.contactable
    assert_nil user.restart_at

    user2.reload
    refute user2.contactable
    refute_nil user2.restart_at

    user3.reload
    assert user3.contactable
    assert_nil user3.restart_at
  end
end
