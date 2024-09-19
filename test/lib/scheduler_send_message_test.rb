require 'test_helper'

class SchedulerNotifyTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @user = create(:user)
    @content = create(:content, lower_age: @user.child_age_in_months_today)

    AfsTinyHappyPeople::Application.load_tasks
    Rake::Task['scheduler:send_message'].execute
  end

  test 'message sent to user' do
    assert_enqueued_jobs 1

    stub_successful_twilio_call(@content.body, @user)

    perform_enqueued_jobs
    assert_equal @user.messages.last.body, @content.body
  end
end
