require "test_helper"

class Admin::QuestionsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @admin = create(:admin)
    sign_in @admin
    @survey = create(:survey)
    @question = create(:question, survey: @survey)
  end

  test "create creates a question and redirects to survey" do
    assert_difference "Question.count", 1 do
      post admin_survey_questions_path(@survey), params: {
        question: {text: "New question?", question_type: "text", options_text: "", position: 2},
      }
    end
    assert_redirected_to admin_survey_path(@survey)
  end

  test "create parses options_text into array" do
    post admin_survey_questions_path(@survey), params: {
      question: {text: "Pick one", question_type: "check_boxes", options_text: "Option A\nOption B\nOption C", position: 2},
    }
    assert_equal ["Option A", "Option B", "Option C"], Question.last.options
  end

  test "create re-renders new with invalid params" do
    assert_no_difference "Question.count" do
      post admin_survey_questions_path(@survey), params: {
        question: {text: "", question_type: "text", options_text: "", position: 2},
      }
    end
    assert_response :unprocessable_entity
  end

  test "update updates question and redirects to survey" do
    patch admin_survey_question_path(@survey, @question), params: {
      question: {text: "Updated?", question_type: "text", options_text: "", position: 2},
    }
    assert_redirected_to admin_survey_path(@survey)
    assert_equal "Updated?", @question.reload.text
  end

  test "update_position updates question position" do
    second = create(:question, survey: @survey)
    assert_equal 2, second.reload.position

    patch update_position_admin_survey_question_path(@survey, second), params: {position: 1}
    assert_response :no_content
    assert_equal 1, second.reload.position
  end

  test "destroy deletes question and redirects to survey" do
    assert_difference "Question.count", -1 do
      delete admin_survey_question_path(@survey, @question)
    end
    assert_redirected_to admin_survey_path(@survey)
  end
end
