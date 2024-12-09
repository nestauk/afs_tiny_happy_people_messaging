require "test_helper"

class SendWelcomeMessageJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  include Rails.application.routes.url_helpers

  test "#perform sends message with default content" do
    user = create(:user, child_birthday: 18.months.ago)

    stub_successful_twilio_call(Content::WELCOME_MESSAGE, user)

    SendWelcomeMessageJob.new.perform(user)

    assert_equal 1, Message.count
    assert_match(Content::WELCOME_MESSAGE, Message.last.body)
  end
end
