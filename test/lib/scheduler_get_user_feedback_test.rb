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
