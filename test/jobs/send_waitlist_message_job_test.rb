require "test_helper"

class SendWaitlistMessageJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  include Rails.application.routes.url_helpers

  test "#perform sends message with default content" do
    user = create(:user, child_birthday: 18.months.ago)

    stub_successful_twilio_call("Hi Ali! Thank you for signing up to the Tiny Happy People text messaging programme. We’re currently receiving a large volume of sign ups, and as a result we unfortunately will have to place you on a waiting list to receive this service. We expect that we will be able to provide the service for you starting in September provided your child is still under 24 months. Please respond STOP if you would like to opt out, otherwise we will send your first text messages in September. We hope that you will join us in the autumn!", user)

    SendWaitlistMessageJob.new.perform(user)

    assert_equal 1, Message.count
    assert_match("Hi Ali! Thank you for signing up to the Tiny Happy People text messaging programme. We’re currently receiving a large volume of sign ups, and as a result we unfortunately will have to place you on a waiting list to receive this service. We expect that we will be able to provide the service for you starting in September provided your child is still under 24 months. Please respond STOP if you would like to opt out, otherwise we will send your first text messages in September. We hope that you will join us in the autumn!", Message.last.body)
  end

  test "#perform does not send message if message is not valid" do
    user = create(:user, child_birthday: 18.months.ago)

    Message.any_instance.stubs(:save).returns(false)

    SendWaitlistMessageJob.new.perform(user)

    assert_equal 0, Message.count
  end
end
