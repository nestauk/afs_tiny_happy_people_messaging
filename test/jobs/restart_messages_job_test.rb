require "test_helper"

class RestartMessagesJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  include Rails.application.routes.url_helpers

  test "#perform updates user and sends message" do
    user = create(:user, contactable: false)

    stub_successful_twilio_call("Welcome back to Tiny Happy People! Text 'stop' to unsubscribe at any time.", user)

    RestartMessagesJob.new.perform(user)

    assert_equal 1, Message.count
    assert_equal true, user.contactable
  end
end
