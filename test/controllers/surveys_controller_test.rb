require "test_helper"

class SurveysControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @admin = create(:admin)
    sign_in @admin

    @survey = create(:survey)
    @user = create(:user)
    @token = @user.generate_token_for(:survey_token)
    @question = create(:question, survey: @survey)
  end

  test "edit renders survey with valid token" do
    get edit_survey_path(@survey, token: @token)
    assert_response :success
  end

  test "edit redirects to root with invalid token" do
    get edit_survey_path(@survey, token: "invalid")
    assert_redirected_to root_path
  end

  test "update saves answer and redirects" do
    answer = create(:answer, question: @question, user: @user, response: "Old answer")

    patch survey_path(@survey, token: @token), params: {
      survey: {
        questions_attributes: {
          "0" => {
            id: @question.id,
            answers_attributes: {
              "0" => {id: answer.id, user_id: @user.id, question_id: @question.id, response: "New answer"},
            },
          },
        },
      },
    }

    assert_redirected_to thank_you_users_path
    assert_equal "New answer", answer.reload.response
  end

  test "update joins checkbox array response into string" do
    answer = create(:answer, question: @question, user: @user, response: "Old answer")

    patch survey_path(@survey, token: @token), params: {
      survey: {
        questions_attributes: {
          "0" => {
            id: @question.id,
            answers_attributes: {
              "0" => {id: answer.id, user_id: @user.id, question_id: @question.id, response: ["Option A", "Option C"]},
            },
          },
        },
      },
    }

    assert_equal "Option A, Option C", answer.reload.response
  end
end
