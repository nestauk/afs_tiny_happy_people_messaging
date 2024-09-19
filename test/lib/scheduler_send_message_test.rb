require "test_helper"

class SchedulerNotifyTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @user = create(:user)
    @group = create(:group, age_in_months: @user.child_age_in_months_today)
    @content = create(:content, group: @group)

    AfsTinyHappyPeople::Application.load_tasks
    Rake::Task["scheduler:send_message"].execute
  end

  test "message sent to user" do
    assert_enqueued_jobs 1

    stub_successful_twilio_call(@content.body, @user)

    perform_enqueued_jobs
    assert_equal @user.messages.last.body, @content.body
  end
end
