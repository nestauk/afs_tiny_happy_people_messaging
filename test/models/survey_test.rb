require "test_helper"

class SurveyTest < ActiveSupport::TestCase
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
end
