require "test_helper"

class QuestionTest < ActiveSupport::TestCase
  def setup
    @question = create(:question)
  end

  test "should be valid" do
    assert @question.valid?
  end

  test "text must be present" do
    @question.text = ""
    assert_not @question.valid?
    assert_error(:text, "can't be blank", subject: @question)
  end

  test "question_type must be present" do
    @question.question_type = ""
    assert_not @question.valid?
    assert_error(:question_type, "can't be blank", subject: @question)
  end

  test "options defaults to empty array" do
    question = create(:question)
    assert_equal [], question.reload.options
  end

  test "options stores array values" do
    question = create(:question, :check_boxes)
    assert_equal ["Option A", "Option B", "Option C"], question.reload.options
  end

  test "destroying question destroys associated answers" do
    create(:answer, question: @question)
    assert_difference "Answer.count", -1 do
      @question.destroy
    end
  end

  test "position updates when question is dragged" do
    survey = create(:survey)
    first = create(:question, survey: survey)
    second = create(:question, survey: survey)

    assert_equal 1, first.reload.position
    assert_equal 2, second.reload.position

    second.update!(position: 1)

    assert_equal 2, first.reload.position
    assert_equal 1, second.reload.position
  end
end
