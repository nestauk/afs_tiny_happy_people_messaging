require "test_helper"

class SurveysControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @admin = create(:admin)
    sign_in @admin

    @survey = create(:survey)
    @survey_section = create(:survey_section, survey: @survey)
    @user = create(:user)
    @token = @user.generate_token_for(:survey_token)
    @question = create(:question, survey_section: @survey_section)
  end

  test "edit renders survey with valid token" do
    get edit_survey_path(@survey, token: @token)
    assert_response :success
  end

  test "edit redirects to root with invalid token" do
    get edit_survey_path(@survey, token: "invalid")
    assert_redirected_to root_path
  end

  test "edit only shows questions matching the user's language" do
    @user.update!(language: "en")
    en_question = create(:question, survey_section: @survey_section, language: "en", text_en: "English only question")
    cy_question = create(:question, survey_section: @survey_section, language: "cy", text_en: "Welsh only question")

    get edit_survey_path(@survey, token: @token)

    assert_includes response.body, en_question.text_en
    assert_not_includes response.body, cy_question.text_en
  end

  test "edit hides a survey section entirely if none of its questions match the user's language" do
    @user.update!(language: "en")
    cy_section = create(:survey_section, survey: @survey, title_en: "Welsh only section")
    create(:question, survey_section: cy_section, language: "cy")

    get edit_survey_path(@survey, token: @token)

    assert_not_includes response.body, cy_section.title_en
  end

  test "update saves answer and redirects" do
    create(:survey_send, survey: @survey, user: @user)
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

    assert_redirected_to thank_you_survey_path(@survey, token: @token)
    assert_not_nil @survey.survey_sends.find_by(user: @user).completed_at
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
