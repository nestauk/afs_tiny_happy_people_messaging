require "test_helper"
require "rake"

class SchedulerTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    AfsTinyHappyPeople::Application.load_tasks if Rake::Task.tasks.empty?
  end

  test "send_morning_message" do
    group = create(:group, age_in_months: 18)
    create(:content, group:)
    create(:user, timing: "morning")

    assert_enqueued_with(job: SendMessageJob) do
      Rake::Task["scheduler:send_morning_message"].execute
    end
  end

  test "send_afternoon_message" do
    group = create(:group, age_in_months: 18)
    create(:content, group:)
    create(:user, timing: "afternoon")

    assert_enqueued_with(job: SendMessageJob) do
      Rake::Task["scheduler:send_afternoon_message"].execute
    end
  end

  test "send_evening_message" do
    group = create(:group, age_in_months: 18)
    create(:content, group:)
    create(:user, timing: "evening")

    assert_enqueued_with(job: SendMessageJob) do
      Rake::Task["scheduler:send_evening_message"].execute
    end
  end

  test "send_no_timing_preference_message" do
    group = create(:group, age_in_months: 18)
    create(:content, group:)
    create(:user, timing: "no_preference")

    assert_enqueued_with(job: SendMessageJob) do
      Rake::Task["scheduler:send_no_timing_preference_message"].execute
    end
  end

  test "send_no_timing_preference_message for users with no timing set" do
    group = create(:group, age_in_months: 18)
    create(:content, group:)
    create(:user, timing: nil)

    assert_enqueued_with(job: SendMessageJob) do
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
end
