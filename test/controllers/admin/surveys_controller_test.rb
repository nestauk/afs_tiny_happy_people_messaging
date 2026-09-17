require "test_helper"

class Admin::SurveysControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @admin = create(:admin)
    sign_in @admin
    @survey = create(:survey)
  end

  test "index lists all surveys" do
    get admin_surveys_path
    assert_response :success
    assert_see @survey.title_en
  end

  test "create creates a survey and redirects" do
    assert_difference "Survey.count", 1 do
      post admin_surveys_path, params: {survey: {title_en: "New Survey", title_cy: "Arolwg Newydd"}}
    end
    assert_redirected_to admin_surveys_path
  end

  test "create re-renders new with invalid params" do
    assert_no_difference "Survey.count" do
      post admin_surveys_path, params: {survey: {title_en: "", title_cy: ""}}
    end
    assert_response :unprocessable_entity
  end

  test "update updates survey and redirects" do
    patch admin_survey_path(@survey), params: {survey: {title_en: "Updated Title"}}
    assert_redirected_to admin_survey_path(@survey)
    assert_equal "Updated Title", @survey.reload.title_en
  end

  test "destroy deletes survey and redirects" do
    assert_difference "Survey.count", -1 do
      delete admin_survey_path(@survey)
    end
    assert_redirected_to admin_surveys_path
  end

  test "show links to previewing the survey in either language" do
    get admin_survey_path(@survey)

    assert_response :success
    assert_select "a[href=?]", preview_admin_survey_path(@survey, locale: "en")
    assert_select "a[href=?]", preview_admin_survey_path(@survey, locale: "cy")
  end

  test "preview shows a blank form, not other users' answers" do
    section = create(:survey_section, survey: @survey)
    question = create(:question, survey_section: section, text_en: "How are you feeling?")
    create(:answer, question:, response: "Someone else's private answer")
    create(:answer, question:, response: "Another respondent's answer")

    get preview_admin_survey_path(@survey)

    assert_response :success
    assert_see "How are you feeling?"
    assert_dont_see "Someone else's private answer"
    assert_dont_see "Another respondent's answer"
  end

  test "preview only shows questions matching the previewed language" do
    section = create(:survey_section, survey: @survey)
    create(:question, survey_section: section, language: "en", text_en: "English only question")
    create(:question, survey_section: section, language: "cy", text_en: "Welsh only question")

    get preview_admin_survey_path(@survey, locale: "en")

    assert_see "English only question"
    assert_dont_see "Welsh only question"
  end
end
