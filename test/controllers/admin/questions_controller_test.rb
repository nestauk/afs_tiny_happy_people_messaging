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
        question: {text_en: "New question?", text_cy: "Cwestiwn newydd?", question_type: "text", options_text_en: "", options_text_cy: "", position: 2},
      }
    end
    assert_redirected_to admin_survey_path(@survey)
  end

  test "create parses options_text_en and options_text_cy into arrays" do
    post admin_survey_questions_path(@survey), params: {
      question: {text_en: "Pick one", text_cy: "Dewis un", question_type: "check_boxes", options_text_en: "Option A\nOption B\nOption C", options_text_cy: "Opsiwn A\nOpsiwn B\nOpsiwn C", position: 2},
    }
    assert_equal ["Option A", "Option B", "Option C"], Question.last.options_en
    assert_equal ["Opsiwn A", "Opsiwn B", "Opsiwn C"], Question.last.options_cy
  end

  test "create re-renders new with invalid params" do
    assert_no_difference "Question.count" do
      post admin_survey_questions_path(@survey), params: {
        question: {text_en: "", text_cy: "", question_type: "text", options_text_en: "", options_text_cy: "", position: 2},
      }
    end
    assert_response :unprocessable_entity
  end

  test "update updates question and redirects to survey" do
    patch admin_survey_question_path(@survey, @question), params: {
      question: {text_en: "Updated?", text_cy: "Diweddarwyd?", question_type: "text", options_text_en: "", options_text_cy: "", position: 2},
    }
    assert_redirected_to admin_survey_path(@survey)
    assert_equal "Updated?", @question.reload.text_en
    assert_equal "Diweddarwyd?", @question.reload.text_cy
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
