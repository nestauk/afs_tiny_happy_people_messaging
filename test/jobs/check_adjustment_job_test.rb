require "test_helper"

class CheckAdjustmentJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  include Rails.application.routes.url_helpers

  test "#perform sends message" do
    user = create(:user)

    stub_successful_twilio_call("You adjusted the content you receive from us a few weeks ago. How is it going? If it's good, no need to do anything. If you'd like to change it, text back 'ADJUST' to start the process again.", user)

    assert_enqueued_jobs 1, only: SendCustomMessageJob do
      CheckAdjustmentJob.new.perform(user)
    end

    assert_equal 1, Message.count
  end
end
