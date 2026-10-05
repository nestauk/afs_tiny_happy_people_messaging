require "test_helper"

class Admin::AnswersControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @admin = create(:admin)
    sign_in @admin
  end

  test "index returns success" do
    survey = create(:survey)
    section = create(:survey_section, survey: survey)
    question = create(:question, survey_section: section)
    create(:answer, question: question)

    get admin_survey_answers_path(survey)

    assert_response :success
  end

  test "index lists questions in section order, then question order within a section" do
    survey = create(:survey)
    section_a = create(:survey_section, survey: survey, position: 1)
    section_b = create(:survey_section, survey: survey, position: 2)

    create(:question, survey_section: section_b, text_en: "B1", position: 1)
    create(:question, survey_section: section_a, text_en: "A1", position: 1)
    create(:question, survey_section: section_a, text_en: "A2", position: 2)
    create(:question, survey_section: section_b, text_en: "B2", position: 2)

    get admin_survey_answers_path(survey)

    question_titles = Nokogiri::HTML(response.body).css("h2").map(&:text)
    assert_equal ["A1", "A2", "B1", "B2"], question_titles
  end
end
