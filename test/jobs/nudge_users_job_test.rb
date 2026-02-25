require "test_helper"

class NudgeUsersJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  include Rails.application.routes.url_helpers

  test "#perform updates user and sends message" do
    user = create(:user)

    stub_successful_twilio_call("Welcome back to Tiny Happy People! Text 'END' to unsubscribe at any time.", user)

    assert_enqueued_jobs 1, only: SendCustomMessageJob do
      NudgeUsersJob.new.perform(user)
    end

    assert_equal 1, Message.count
    assert_not_nil user.reload.nudged_at
  end
end
