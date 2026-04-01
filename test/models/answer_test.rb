require "test_helper"

class AnswerTest < ActiveSupport::TestCase
  def setup
    @answer = create(:answer)
  end

  test "should be valid" do
    assert @answer.valid?
  end

  test "response must be present" do
    @answer.response = ""
    assert_not @answer.valid?
    assert_error(:response, "can't be blank", subject: @answer)
  end

  test "response= stores plain string as-is" do
    @answer.response = "My text answer"
    assert_equal "My text answer", @answer.response
  end

  test "response= joins array values with comma for checkboxes" do
    @answer.response = ["Option A", "Option C"]
    assert_equal "Option A, Option C", @answer.response
  end

  test "response= ignores blank array entries" do
    @answer.response = ["Option A", "", "Option C"]
    assert_equal "Option A, Option C", @answer.response
  end
end
