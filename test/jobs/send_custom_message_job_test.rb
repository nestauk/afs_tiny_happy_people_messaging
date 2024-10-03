require "test_helper"

class SendCustomMessageJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "#perform sends messages" do
    message = create(:message)

    stub_successful_twilio_call(message.body, message.user)

    SendCustomMessageJob.perform_now(message)

    assert_equal "accepted", message.reload.status
  end
end
