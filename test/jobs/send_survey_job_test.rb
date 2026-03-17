require "test_helper"

class SendSurveyJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  include Rails.application.routes.url_helpers

  test "#perform enqueues SendCustomMessageJob and creates SurveySend" do
    user = create(:user)
    survey = create(:survey)

    assert_enqueued_jobs 1, only: SendCustomMessageJob do
      SendSurveyJob.new.perform(user, survey)
    end

    assert_equal 1, Message.count
    assert_match("survey", Message.last.body)
    assert SurveySend.exists?(user: user, survey: survey)
  end

  test "#perform includes survey link in message body" do
    user = create(:user)
    survey = create(:survey)

    User.any_instance.stubs(:generate_token_for).with(:survey_token).returns("abc123")

    SendSurveyJob.new.perform(user, survey)

    assert_match edit_survey_url(survey, token: "abc123"), Message.last.body
  end

  test "#perform does not send if survey already sent to user" do
    user = create(:user)
    survey = create(:survey)
    create(:survey_send, user: user, survey: survey)

    assert_no_enqueued_jobs only: SendCustomMessageJob do
      SendSurveyJob.new.perform(user, survey)
    end

    assert_equal 0, Message.count
  end

  test "#perform does not create SurveySend if message fails to save" do
    user = create(:user)
    survey = create(:survey)

    Message.any_instance.stubs(:save).returns(false)

    assert_no_enqueued_jobs only: SendCustomMessageJob do
      SendSurveyJob.new.perform(user, survey)
    end

    assert_equal 0, SurveySend.count
  end
end
