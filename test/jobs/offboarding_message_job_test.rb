require "test_helper"

class OffboardingMessageJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "#perform sends offboarding message in user's preferred language" do
    create(:group, language: "cy")
    survey = create(:survey, title_en: "Offboarding")
    user = create(:user, language: "cy")

    Survey.any_instance.stubs(:generate_token).with(:survey_token).returns("ABC")

    stub_successful_twilio_call("Diolch yn fawr iawn am gymryd rhan yn ein rhaglen negeseuon testun gyda gweithgareddau wythnosol hwyliog i’ch plentyn! Dywedwch wrthym sut rydych chi wedi cael y rhaglen yma: http://localhost:3000/surveys/#{survey.id}/edit?survey_token=ABC", user)

    assert_enqueued_jobs 1, only: SendCustomMessageJob do
      OffboardingMessageJob.new.perform(user)
    end

    assert_equal 1, Message.count
  end

  test "#perform does not send message if survey already sent to user" do
    survey = create(:survey, title_en: "Offboarding")
    user = create(:user)
    create(:survey_send, user: user, survey: survey)

    assert_no_enqueued_jobs only: SendCustomMessageJob do
      OffboardingMessageJob.new.perform(user)
    end

    assert_equal 0, Message.count
  end

  test "#perform does not send message if survey is missing" do
    user = create(:user)

    assert_no_enqueued_jobs only: SendCustomMessageJob do
      OffboardingMessageJob.new.perform(user)
    end

    assert_equal 0, Message.count
  end

  test "#perform reports an error to Appsignal if message fails to save" do
    create(:survey, title_en: "Offboarding")
    user = create(:user)

    Message.any_instance.stubs(:save).returns(false)
    Appsignal.expects(:report_error).once.with do |error|
      error.message == "Failed to send offboarding message"
    end

    OffboardingMessageJob.new.perform(user)
  end
end
