require "test_helper"

class SendSurveyMessageJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "#perform sends message with default content" do
    user = create(:user)

    stub_successful_twilio_call("Hi Ali, got 10 minutes? We’d love to hear your thoughts on the programme so far! It will help us make the service better for your family and give you a chance to win a £20 One4All gift voucher. Simply take this quick survey: https://survey.alchemer.com/s3/8240837/Tiny-Happy-People-Text-Messaging-Programme-Feedback-Survey", user)

    SendSurveyMessageJob.new.perform(user)

    assert_equal 1, Message.count
    assert_not_nil user.sent_survey_at
  end
end
