require "test_helper"

class SendWelcomeMessageJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  include Rails.application.routes.url_helpers

  test "#perform sends message with default content" do
    user = create(:user, child_birthday: 18.months.ago)

    stub_successful_twilio_call("Hi Ali, welcome to our programme of weekly texts with fun activities for your child's development. Congrats on starting this amazing journey with your little one!", user)

    SendWelcomeMessageJob.new.perform(user)

    assert_equal 1, Message.count
    assert_match("Hi Ali, welcome to our programme of weekly texts with fun activities for your child's development. Congrats on starting this amazing journey with your little one!", Message.last.body)
  end

  test "#perform does not send message if message is not valid" do
    user = create(:user, child_birthday: 18.months.ago)

    Message.any_instance.stubs(:save).returns(false)

    SendWelcomeMessageJob.new.perform(user)

    assert_equal 0, Message.count
  end
end
