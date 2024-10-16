require "test_helper"
require "rake"

class SchedulerTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    ENV["WEEKLY_MESSAGE_DAY"] = "1"
    ENV["WEEKLY_NUDGE_DAY"] = "1"
    ENV["SET_WEEKLY"] = "true"

    travel_to_monday
    AfsTinyHappyPeople::Application.load_tasks if Rake::Task.tasks.empty?
  end

  test "send_morning_message" do
    group = create(:group, age_in_months: 18)
    create(:content, group:)
    create(:user, timing: "morning")

    assert_enqueued_with(job: SendBulkMessageJob) do
      Rake::Task["scheduler:send_morning_message"].execute
    end
  end

  test "send_afternoon_message" do
    group = create(:group, age_in_months: 18)
    create(:content, group:)
    create(:user, timing: "afternoon")

    assert_enqueued_with(job: SendBulkMessageJob) do
      Rake::Task["scheduler:send_afternoon_message"].execute
    end
  end

  test "send_evening_message" do
    group = create(:group, age_in_months: 18)
    create(:content, group:)
    create(:user, timing: "evening")

    assert_enqueued_with(job: SendBulkMessageJob) do
      Rake::Task["scheduler:send_evening_message"].execute
    end
  end

  test "send_no_timing_preference_message" do
    group = create(:group, age_in_months: 18)
    create(:content, group:)
    create(:user, timing: "no_preference")

    assert_enqueued_with(job: SendBulkMessageJob) do
      Rake::Task["scheduler:send_no_timing_preference_message"].execute
    end
  end

  test "send_no_timing_preference_message for users with no timing set" do
    group = create(:group, age_in_months: 18)
    create(:content, group:)
    create(:user, timing: nil)

    assert_enqueued_with(job: SendBulkMessageJob) do
      Rake::Task["scheduler:send_no_timing_preference_message"].execute
    end
  end

  test "no job enqueued if user is not contactable" do
    create(:user, contactable: false, timing: "morning")

    assert_no_enqueued_jobs do
      Rake::Task["scheduler:send_morning_message"].execute
    end
  end

  test "no job enqueued if there is no appropriate group" do
    create(:user, timing: "morning")
    create(:user, timing: "afternoon")
    create(:user, timing: "evening")
    create(:user, timing: "no_preference")
    create(:user, timing: nil)

    assert_no_enqueued_jobs do
      Rake::Task["scheduler:send_morning_message"].execute
      Rake::Task["scheduler:send_afternoon_message"].execute
      Rake::Task["scheduler:send_evening_message"].execute
      Rake::Task["scheduler:send_no_timing_preference_message"].execute
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

    assert_equal 1, Message.where(body: "You've not interacted with any videos lately. Want to continue receiving them? You can text 'PAUSE' for a break, 'ADJUST' for different content, or 'STOP' to stop them entirely.").count
  end

  test "doesn't run unless it's the right day" do
    travel_to_tuesday

    group = create(:group, age_in_months: 18)
    create(:content, group:)
    create(:user, timing: "morning")

    assert_no_enqueued_jobs do
      Rake::Task["scheduler:send_morning_message"].execute
    end
  end

  test "does run on the wrong day if set_weekly isn't set" do
    ENV["SET_WEEKLY"] = "false"
    travel_to_tuesday

    group = create(:group, age_in_months: 18)
    create(:content, group:)
    create(:user, timing: "morning")

    assert_enqueued_with(job: SendBulkMessageJob) do
      Rake::Task["scheduler:send_morning_message"].execute
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

  def travel_to_tuesday
    current_day = Time.current.wday

    # Calculate how many days until the nearest Tuesday (2 = Tuesday)
    days_until_tuesday = (2 - current_day) % 7
    days_until_tuesday = 7 if days_until_tuesday.zero?

    travel_to Time.current + days_until_tuesday.days
  end
end
