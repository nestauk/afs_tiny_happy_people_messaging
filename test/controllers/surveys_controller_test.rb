require "test_helper"

class SurveysControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @admin = create(:admin)
    sign_in @admin

    @survey = create(:survey)
    @survey_section = create(:survey_section, survey: @survey)
    @user = create(:user)
    @token = @user.survey_link_token
    @question = create(:question, survey_section: @survey_section)
  end

  test "edit renders survey with valid token" do
    get edit_survey_path(@survey, token: @token)
    assert_response :success
  end

  test "edit renders survey with a valid old-format signed token" do
    get edit_survey_path(@survey, token: @user.generate_token_for(:survey_token))
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

  test "edit redirects to thank you when the survey is full" do
    @survey.update!(max_responses: 1)
    create(:survey_send, survey: @survey, completed_at: Time.zone.now)

    get edit_survey_path(@survey, token: @token)

    assert_redirected_to thank_you_survey_path(@survey, token: @token, closed: true)
  end

  test "edit does not close the survey when one user completed it more than once" do
    @survey.update!(max_responses: 2)
    other_user = create(:user)
    create_list(:survey_send, 2, survey: @survey, user: other_user, completed_at: Time.zone.now)

    get edit_survey_path(@survey, token: @token)

    assert_response :success
  end

  test "edit does not redirect a user who already completed the full survey" do
    @survey.update!(max_responses: 1)
    create(:survey_send, survey: @survey, user: @user, completed_at: Time.zone.now)

    get edit_survey_path(@survey, token: @token)

    assert_response :success
  end

  test "thank you shows the closed message when redirected from a full survey" do
    @survey.update!(max_responses: 1)
    create(:survey_send, survey: @survey, completed_at: Time.zone.now)

    get thank_you_survey_path(@survey, token: @token, closed: true)

    assert_includes response.body, I18n.t("pages.surveys.thank_you.closed_title")
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

  test "update saves the answer for the token's user even if another user_id is submitted" do
    other_user = create(:user)

    submit_answers("0" => {user_id: other_user.id, response: "My answer"})

    assert_equal "My answer", Answer.find_by(question: @question, user: @user).response
    assert_nil Answer.find_by(question: @question, user: other_user)
  end

  test "update saves to the token's user even if another user's answer id is submitted" do
    other_users_answer = create(:answer, question: @question, user: create(:user), response: "Other user's answer")

    submit_answers("0" => {id: other_users_answer.id, response: "My answer"})

    assert_equal "Other user's answer", other_users_answer.reload.response
    assert_equal "My answer", Answer.find_by(question: @question, user: @user).response
  end

  test "update creates an answer for the user on their first submission" do
    submit_answers("0" => {response: "First answer"})

    assert_equal ["First answer"], Answer.where(question: @question, user: @user).pluck(:response)
  end

  test "update replaces the user's existing answer without being sent its id" do
    create(:answer, question: @question, user: @user, response: "Old answer")

    submit_answers("0" => {response: "New answer"})

    assert_equal ["New answer"], Answer.where(question: @question, user: @user).pluck(:response)
  end

  test "update saves only one answer per question" do
    submit_answers("0" => {response: "First"}, "1" => {response: "Second"})

    assert_equal ["First"], Answer.where(question: @question, user: @user).pluck(:response)
  end

  private

  def submit_answers(answers_attributes)
    patch survey_path(@survey, token: @token), params: {
      survey: {questions_attributes: {"0" => {id: @question.id, answers_attributes:}}},
    }
  end
end
