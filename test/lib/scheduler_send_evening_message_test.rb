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

  test "send_evening_message" do
    create(:content)
    create(:user, hour_preference: "evening", day_preference: 1)

    assert_enqueued_with(job: SendBulkMessageJob) do
      Rake::Task["scheduler:send_evening_message"].execute
    end
  end

  test "no evening job enqueued if user is not contactable" do
    create(:user, contactable: false, hour_preference: "morning", day_preference: 1)

    assert_no_enqueued_jobs do
      Rake::Task["scheduler:send_morning_message"].execute
    end
  end

  test "no evening job enqueued if user's day_preference doesn't match today" do
    create(:user, contactable: true, hour_preference: "evening", day_preference: 2)

    assert_no_enqueued_jobs do
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
end
