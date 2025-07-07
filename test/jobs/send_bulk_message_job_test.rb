require "test_helper"

class SendBulkMessageJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    travel_to Time.zone.now
  end

  test "#perform creates jobs to send messages based on their timing preferences to users" do
    travel_to_monday
    create_list(:user, 3, hour_preference: "morning", day_preference: 1)
    create_list(:user, 2, hour_preference: "afternoon", day_preference: 1)
    create_list(:user, 3, hour_preference: "evening", day_preference: 1)
    create_list(:user, 2, hour_preference: "no_preference", day_preference: 1)
    create(:user, hour_preference: nil, day_preference: 1)

    assert_enqueued_jobs 3, only: SendMessageJob do
      SendBulkMessageJob.perform_now("weekly_message", "morning")
    end

    assert_enqueued_jobs 2, only: SendMessageJob do
      SendBulkMessageJob.perform_now("weekly_message", "afternoon")
    end

    assert_enqueued_jobs 3, only: SendMessageJob do
      SendBulkMessageJob.perform_now("weekly_message", "evening")
    end

    assert_enqueued_jobs 3, only: SendMessageJob do
      SendBulkMessageJob.perform_now("weekly_message", "no_preference")
    end
  end

  test "no job enqueued if user is not contactable" do
    travel_to_monday
    create(:user, contactable: false, hour_preference: "morning", day_preference: 1)

    assert_no_enqueued_jobs do
      SendBulkMessageJob.perform_now("weekly_message", "morning")
    end
  end

  test "no morning job enqueued if user's day_preference doesn't match today" do
    travel_to_monday
    create(:user, contactable: true, hour_preference: "morning", day_preference: 2)

    assert_no_enqueued_jobs do
      SendBulkMessageJob.perform_now("weekly_message", "morning")
    end
  end

  test "no morning job enqueued if user has finished all the content" do
    travel_to_monday
    content = create(:content)
    create(:user, hour_preference: "morning", day_preference: 1, last_content_id: content.id)

    assert_no_enqueued_jobs do
      SendBulkMessageJob.perform_now("weekly_message", "morning")
    end
  end

  test "#perform creates jobs to send feedback to users" do
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

    assert_enqueued_jobs 1, only: SendFeedbackMessageJob do
      SendBulkMessageJob.perform_now("feedback")
    end
  end

  test "#perform creates jobs to nudge users" do
    content = create(:content)
    users = create_list(:user, 3)
    create(:message, user: users[0], body: "https://thp-text.uk/m", content:)
    create(:message, user: users[0], body: "https://thp-text.uk/m", content:)
    create(:message, user: users[0], body: "https://thp-text.uk/m", content:)

    create(:message, user: users[1], body: "https://thp-text.uk/m", content:)
    create(:message, user: users[1], body: "https://thp-text.uk/m", content:)

    create(:message, user: users[2], body: "https://thp-text.uk/m", content:)
    create(:message, user: users[2], clicked_at: Time.now, body: "https://thp-text.uk/m", content:)

    assert_enqueued_jobs 1, only: NudgeUsersJob do
      SendBulkMessageJob.perform_now("nudge")
    end
  end

  test "#perform creates jobs to restart messages for opted-out users" do
    user = create(:user, contactable: false, restart_at: Time.now - 1.day)
    create(:user, contactable: false, restart_at: Time.now + 1.day)
    create(:user, contactable: true)

    assert_enqueued_with(job: RestartMessagesJob, args: [user]) do
      SendBulkMessageJob.perform_now("restart")
    end
  end

  test "#perform creates jobs to check with users about their content adjustment" do
    user = create(:user, contactable: true)
    create(:content_adjustment, user:, adjusted_at: 17.days.ago)
    user2 = create(:user, contactable: true)
    create(:content_adjustment, user: user2, adjusted_at: nil)

    assert_enqueued_with(job: CheckAdjustmentJob, args: [user]) do
      SendBulkMessageJob.perform_now("check_adjustment")
    end
  end

  test "#perform creates jobs to ask users to finish their content adjustment" do
    user = create(:user, contactable: true)
    create(:content_adjustment, user:, adjusted_at: nil, created_at: 8.days.ago)
    user2 = create(:user, contactable: true)
    create(:content_adjustment, user: user2, adjusted_at: 1.week.ago, created_at: 8.days.ago)
    user3 = create(:user, contactable: true)
    create(:content_adjustment, user: user3, needs_adjustment: false, created_at: 8.days.ago)

    assert_enqueued_with(job: ChaseAdjustmentJob, args: [user]) do
      SendBulkMessageJob.perform_now("chase_adjustment")
    end
  end

  test "#perform does not create jobs if not passed a valid message type" do
    create_list(:user, 3, child_birthday: 7.months.ago)

    assert_no_enqueued_jobs do
      SendBulkMessageJob.perform_now("invalid_type")
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
