require "test_helper"

class SurveyTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  def setup
    @survey = create(:survey)
  end

  test "should be valid" do
    assert @survey.valid?
  end

  test "title must be present" do
    @survey.title = ""
    assert_not @survey.valid?
    assert_error(:title, "can't be blank", subject: @survey)
  end

  test "destroying survey destroys associated questions" do
    create(:question, survey: @survey)
    assert_difference "Question.count", -1 do
      @survey.destroy
    end
  end

  test ".trigger_for enqueues SendSurveyJob when message count matches send_after_message_count" do
    survey = create(:survey, send_after_message_count: 3)
    user = create(:user)

    assert_enqueued_with(job: SendSurveyJob, args: [user, survey]) do
      Survey.trigger_for(user, message_count: 3)
    end
  end

  test ".trigger_for enqueues SendSurveyJob when last_message is true and send_on_last_message is set" do
    survey = create(:survey, send_on_last_message: true)
    user = create(:user)

    assert_enqueued_with(job: SendSurveyJob, args: [user, survey]) do
      Survey.trigger_for(user, message_count: 99, last_message: true)
    end
  end

  test ".trigger_for enqueues multiple matching surveys" do
    create(:survey, send_after_message_count: 5)
    create(:survey, send_on_last_message: true)
    user = create(:user)

    assert_enqueued_jobs 2, only: SendSurveyJob do
      Survey.trigger_for(user, message_count: 5, last_message: true)
    end
  end

  test ".trigger_for does not enqueue if message count does not match" do
    create(:survey, send_after_message_count: 10)
    user = create(:user)

    assert_no_enqueued_jobs only: SendSurveyJob do
      Survey.trigger_for(user, message_count: 5)
    end
  end

  test ".trigger_for does not enqueue send_on_last_message survey when last_message is false" do
    create(:survey, send_on_last_message: true)
    user = create(:user)

    assert_no_enqueued_jobs only: SendSurveyJob do
      Survey.trigger_for(user, message_count: 0, last_message: false)
    end
  end

  test ".trigger_for does not enqueue if survey already sent to user" do
    survey = create(:survey, send_after_message_count: 3)
    user = create(:user)
    create(:survey_send, user: user, survey: survey)

    assert_no_enqueued_jobs only: SendSurveyJob do
      Survey.trigger_for(user, message_count: 3)
    end
  end

  test ".trigger_for does not enqueue surveys with no trigger configured" do
    create(:survey, send_after_message_count: nil, send_on_last_message: false)
    user = create(:user)

    assert_no_enqueued_jobs only: SendSurveyJob do
      Survey.trigger_for(user, message_count: 0, last_message: true)
    end
  end
end
