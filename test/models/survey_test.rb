require "test_helper"

class SurveyTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  def setup
    @survey = create(:survey)
  end

  test "should be valid" do
    assert @survey.valid?
  end

  test "title_en must be present" do
    @survey.title_en = ""
    assert_not @survey.valid?
    assert_error(:title_en, "can't be blank", subject: @survey)
  end

  test "title_cy must be present" do
    @survey.title_cy = ""
    assert_not @survey.valid?
    assert_error(:title_cy, "can't be blank", subject: @survey)
  end

  test "destroying survey destroys associated questions" do
    create(:question, survey_section: create(:survey_section, survey: @survey))
    assert_difference "Question.count", -1 do
      @survey.destroy
    end
  end

  test "#completed_by? is true when the user has a completed survey_send" do
    user = create(:user)
    create(:survey_send, survey: @survey, user: user, completed_at: Time.zone.now)

    assert @survey.completed_by?(user)
  end

  test "#completed_by? is false when the user has not completed the survey" do
    user = create(:user)
    create(:survey_send, survey: @survey, user: user, completed_at: nil)

    assert_not @survey.completed_by?(user)
  end

  test "#full? is false when max_responses is not set" do
    @survey.update!(max_responses: nil)
    create_list(:survey_send, 3, survey: @survey, completed_at: Time.zone.now)

    assert_not @survey.full?
  end

  test "#full? is false when completed responses are below max_responses" do
    @survey.update!(max_responses: 3)
    create_list(:survey_send, 2, survey: @survey, completed_at: Time.zone.now)

    assert_not @survey.full?
  end

  test "#full? is true when completed responses reach max_responses" do
    @survey.update!(max_responses: 3)
    create_list(:survey_send, 3, survey: @survey, completed_at: Time.zone.now)

    assert @survey.full?
  end

  test "#full? does not count survey_sends that were never completed" do
    @survey.update!(max_responses: 2)
    create_list(:survey_send, 2, survey: @survey, completed_at: nil)

    assert_not @survey.full?
  end

  test "#full? counts a user with multiple completed survey_sends once" do
    @survey.update!(max_responses: 2)
    user = create(:user)
    create_list(:survey_send, 2, survey: @survey, user: user, completed_at: Time.zone.now)

    assert_not @survey.full?
  end

  test "#completed_respondent_count counts distinct users with a completed survey_send" do
    user = create(:user)
    create_list(:survey_send, 2, survey: @survey, user: user, completed_at: Time.zone.now)
    create(:survey_send, survey: @survey, completed_at: Time.zone.now)
    create(:survey_send, survey: @survey, completed_at: nil)

    assert_equal 2, @survey.completed_respondent_count
  end
end
