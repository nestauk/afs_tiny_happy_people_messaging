require "test_helper"

class Admin::SurveySectionsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @admin = create(:admin)
    sign_in @admin
    @survey = create(:survey)
    @survey_section = create(:survey_section, survey: @survey)
  end

  test "create creates a survey section and redirects" do
    assert_difference "SurveySection.count", 1 do
      post admin_survey_survey_sections_path(@survey, @survey_section), params: {survey_section: {title_en: "New Section", title_cy: "Arolwg Newydd", position: 1}}
    end
    assert_redirected_to admin_survey_path(@survey)
  end

  test "create re-renders new with invalid params" do
    assert_no_difference "SurveySection.count" do
      post admin_survey_survey_sections_path(@survey, @survey_section), params: {survey_section: {title_en: "", title_cy: ""}}
    end
    assert_response :unprocessable_entity
  end

  test "update updates survey section and redirects" do
    patch admin_survey_survey_section_path(@survey, @survey_section), params: {survey_section: {title_en: "Updated Title"}}
    assert_redirected_to admin_survey_path(@survey)
    assert_equal "Updated Title", @survey_section.reload.title_en
  end

  test "destroy deletes survey section and redirects" do
    assert_difference "SurveySection.count", -1 do
      delete admin_survey_survey_section_path(@survey, @survey_section)
    end
    assert_redirected_to admin_survey_path(@survey)
  end
end
