require "test_helper"
require "rake"

class SchedulerTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    ENV["WEEKLY_NUDGE_DAY"] = "1"
    ENV["SET_WEEKLY"] = "true"

    travel_to_monday
    AfsTinyHappyPeople::Application.load_tasks if Rake::Task.tasks.empty?
  end

  test "send_morning_message" do
    create(:content)
    create(:user, hour_preference: "morning", day_preference: 1)

    assert_enqueued_with(job: SendBulkMessageJob) do
      Rake::Task["scheduler:send_morning_message"].execute
    end
  end

  test "send_afternoon_message" do
    create(:content)
    create(:user, hour_preference: "afternoon", day_preference: 1)

    assert_enqueued_with(job: SendBulkMessageJob) do
      Rake::Task["scheduler:send_afternoon_message"].execute
    end
  end

  test "send_evening_message" do
    create(:content)
    create(:user, hour_preference: "evening", day_preference: 1)

    assert_enqueued_with(job: SendBulkMessageJob) do
      Rake::Task["scheduler:send_evening_message"].execute
    end
  end

  test "send_no_timing_preference_message" do
    create(:content)
    create(:user, hour_preference: "no_preference", day_preference: 1)

    assert_enqueued_with(job: SendBulkMessageJob) do
      Rake::Task["scheduler:send_no_timing_preference_message"].execute
    end
  end

  test "send_no_timing_preference_message for users with no timing set" do
    create(:content)
    create(:user, hour_preference: nil, day_preference: 1)

    assert_enqueued_with(job: SendBulkMessageJob) do
      Rake::Task["scheduler:send_no_timing_preference_message"].execute
    end
  end

  test "no job enqueued if user is not contactable" do
    create(:user, contactable: false, hour_preference: "morning", day_preference: 1)

    assert_no_enqueued_jobs do
      Rake::Task["scheduler:send_morning_message"].execute
    end
  end

  test "no job enqueued if user's day_preference doesn't match today" do
    create(:user, contactable: true, hour_preference: "morning", day_preference: 2)

    assert_no_enqueued_jobs do
      Rake::Task["scheduler:send_morning_message"].execute
    end
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

    assert_equal 1, Message.where(body: "You've not interacted with any videos lately. You can text 'PAUSE' for a break or 'STOP' to stop them entirely.").count
  end

  test "get_user_feedback" do
    content = create(:content)
    user1 = create(:user)
    create(:message, user: user1, content:)
    create(:message, user: user1, content:)

    user2 = create(:user)
    create(:message, user: user2, content:)
    create(:message, user: user2)

    user3 = create(:user, contactable: false)
    create(:message, user: user3, content:)
    create(:message, user: user3, content:)

    assert_enqueued_with(job: SendBulkMessageJob) do
      Rake::Task["scheduler:get_user_feedback"].execute
    end
  end

  private

  def travel_to_monday
    current_day = Time.current.wday

    # Calculate how many days until the nearest Tuesday (2 = Tuesday)
    days_until_monday = (1 - current_day) % 7
    days_until_monday = 7 if days_until_monday.zero?

    travel_to Time.current + days_until_monday.days
  end
end
